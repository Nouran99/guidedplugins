#!/usr/bin/env node
// Validates the eval suites in evals/<slug>/ without calling a model: structure of every case, that the scaffold builds the fixture the prompt
// names, and that the graders are well formed. The suites are run with scripts/run-evals.mjs (which spends model usage).
//   node scripts/validate-evals.mjs                # every suite that exists
//   node scripts/validate-evals.mjs clean-code     # one suite
//   node scripts/validate-evals.mjs --require-all  # also fail when a plugin has no suite
//
// A suite is evals/<slug>/<case>/ with: case.yaml, prompt.md, scaffold.sh and graders/*.md. Cases are tagged "detect" (a fixture with several
// planted violations, one grader per violation) or "control" (clean code, graded for false alarms). The runner derives the slash-command
// variants itself. See evals/README.md.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { REGISTRY, ROOT, listDir, readIf } from './lib.mjs';

const EVALS = path.join(ROOT, 'evals');
const GRADER_TYPES = new Set(['regex', 'llm', 'tool_used', 'tool_order', 'file_exists', 'baseline']);
const ALLOWED_TOOLS = new Set(['Read', 'Glob', 'Grep', 'Skill']);
const MIN_DETECT = 3;
const MIN_DEFECT_GRADERS = 5;
const KEBAB = /^[a-z0-9]+(-[a-z0-9]+)*$/;

// ---------------------------------------------------------------- a small YAML subset (checked against PyYAML when it is installed)
function scalar(v) {
  v = v.trim();
  if (v === '') return '';
  if (v.startsWith('"')) return JSON.parse(v);
  if (v.startsWith("'")) { if (!v.endsWith("'") || v.length < 2) throw new Error(`unterminated single-quoted string: ${v}`); return v.slice(1, -1).replace(/''/g, "'"); }
  if (v.startsWith('[')) return v.slice(1, -1).split(',').map((x) => x.trim()).filter(Boolean).map(scalar);
  if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  if (v === 'true' || v === 'false') return v === 'true';
  if (/: |\s#/.test(v)) throw new Error(`unquoted value contains ": " or " #": ${v}`);
  return v;
}
export function parseYamlSubset(text) {
  const out = {}; let block = null;
  for (const raw of text.replace(/\r\n/g, '\n').split('\n')) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;
    const m = raw.match(/^(\s*)([A-Za-z_][\w-]*):(?:\s+(.*))?$/);
    if (!m) throw new Error(`cannot parse line: ${raw}`);
    const [, indent, key, rest] = m;
    if (indent.length === 0) { if (rest === undefined || rest === '') { out[key] = {}; block = out[key]; } else { out[key] = scalar(rest); block = null; } }
    else { if (!block) throw new Error(`indented line outside a block: ${raw}`); block[key] = scalar(rest ?? ''); }
  }
  return out;
}
function frontmatter(text) {
  const src = text.replace(/\r\n/g, '\n');
  if (!src.startsWith('---\n')) throw new Error('missing opening ---');
  const end = src.indexOf('\n---', 4);
  if (end === -1) throw new Error('missing closing ---');
  return { data: parseYamlSubset(src.slice(4, end)), body: src.slice(end + 4).replace(/^\n/, '') };
}
// Cross-check with PyYAML when available: the same text must give the same data.
function pyYamlAvailable() { return spawnSync('python3', ['-c', 'import yaml'], { encoding: 'utf8' }).status === 0; }
function pyYamlLoad(text) {
  const r = spawnSync('python3', ['-c', 'import sys, json, yaml; print(json.dumps(yaml.safe_load(sys.stdin.read())))'], { input: text, encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`PyYAML: ${r.stderr.trim().split('\n').pop()}`);
  return JSON.parse(r.stdout);
}

// ---------------------------------------------------------------- the checks
export function validateEvals({ slugs = null, requireAll = false } = {}) {
  const errors = []; const warnings = [];
  const err = (where, msg) => errors.push(`${where}: ${msg}`);
  const all = REGISTRY.books.map((b) => b.slug);
  const want = slugs ?? all;
  const useYaml = pyYamlAvailable();
  if (!useYaml) warnings.push('PyYAML is not installed; the YAML files were checked with the built-in subset parser only');
  const rel = (p) => path.relative(ROOT, p);
  let suites = 0; let cases = 0;

  for (const slug of want) {
    const suiteDir = path.join(EVALS, slug);
    if (!fs.existsSync(suiteDir)) { if (requireAll) err(`evals/${slug}`, 'no eval suite'); continue; }
    suites++;
    const caseDirs = listDir(suiteDir).filter((e) => e.isDirectory() && e.name !== 'results');
    const names = new Set(); let detect = 0; let control = 0;
    for (const c of caseDirs) {
      cases++;
      const dir = path.join(suiteDir, c.name);
      const where = rel(dir);
      if (!KEBAB.test(c.name) || c.name.includes('--')) err(where, 'case folder names are kebab-case and must not contain "--" (the runner uses it for the slash variants)');
      const ymlPath = path.join(dir, 'case.yaml');
      const ymlText = readIf(ymlPath);
      if (ymlText == null) { err(where, 'case.yaml is missing'); continue; }
      let yml;
      try { yml = parseYamlSubset(ymlText); } catch (e) { err(rel(ymlPath), e.message); continue; }
      if (useYaml) { try { if (JSON.stringify(pyYamlLoad(ymlText)) !== JSON.stringify(yml)) err(rel(ymlPath), 'PyYAML reads this file differently from the built-in parser; quote strings that contain ":" or "#"'); } catch (e) { err(rel(ymlPath), e.message); continue; } }
      if (yml.schema_version !== '1.1') err(rel(ymlPath), 'schema_version must be "1.1"');
      if (yml.name !== c.name) err(rel(ymlPath), `name "${yml.name}" must equal the folder "${c.name}"`);
      if (names.has(yml.name)) err(rel(ymlPath), 'duplicate case name');
      names.add(yml.name);
      if (typeof yml.description !== 'string' || yml.description.length < 20) err(rel(ymlPath), 'description is required (at least 20 characters)');
      const tags = yml.tags ?? [];
      const kind = tags.length === 1 && ['detect', 'control'].includes(tags[0]) ? tags[0] : null;
      if (!kind) err(rel(ymlPath), `tags must be exactly [detect] or [control], got [${tags.join(', ')}]`);
      if (kind === 'detect') detect++; else if (kind === 'control') control++;
      const ex = yml.execution ?? {};
      if (!(ex.max_turns >= 8 && ex.max_turns <= 30)) err(rel(ymlPath), 'execution.max_turns must be 8 to 30');
      if (!(ex.timeout_seconds >= 120 && ex.timeout_seconds <= 600)) err(rel(ymlPath), 'execution.timeout_seconds must be 120 to 600');
      if (!Array.isArray(ex.allowed_tools) || !ex.allowed_tools.length || ex.allowed_tools.some((t) => !ALLOWED_TOOLS.has(t))) err(rel(ymlPath), `execution.allowed_tools must be a subset of ${[...ALLOWED_TOOLS].join(', ')} (a review never needs a write tool)`);
      if (ex.prompt !== undefined) err(rel(ymlPath), 'the prompt belongs in prompt.md');
      if (yml.context?.scaffold_script !== 'scaffold.sh') err(rel(ymlPath), 'context.scaffold_script must be scaffold.sh');

      // scaffold: syntax, safety, and the fixture it builds
      const scaffold = path.join(dir, 'scaffold.sh');
      let fixtureFiles = [];
      if (!fs.existsSync(scaffold)) err(where, 'scaffold.sh is missing');
      else {
        const sh = fs.readFileSync(scaffold, 'utf8');
        if (!(fs.statSync(scaffold).mode & 0o100)) err(rel(scaffold), 'scaffold.sh must be executable (chmod +x)');
        if (/\b(curl|wget|npm|pip|git\s+clone|ssh|nc)\b/.test(sh)) err(rel(scaffold), 'a scaffold writes files and nothing else: no network or package commands');
        if (spawnSync('bash', ['-n', scaffold]).status !== 0) err(rel(scaffold), 'bash -n reports a syntax error');
        else {
          const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'guided-scaffold-'));
          const r = spawnSync('bash', [scaffold], { cwd: tmp, encoding: 'utf8', env: { PATH: process.env.PATH, HOME: tmp } });
          if (r.status !== 0) err(rel(scaffold), `scaffold.sh failed: ${r.stderr.trim().split('\n').pop()}`);
          fixtureFiles = walk(tmp).map((f) => path.relative(tmp, f));
          if (!fixtureFiles.length) err(rel(scaffold), 'scaffold.sh created no files');
          for (const f of fixtureFiles) {
            const lines = fs.readFileSync(path.join(tmp, f), 'utf8').split('\n').length;
            const tele = fs.readFileSync(path.join(tmp, f), 'utf8').split('\n').find((l) => /(\/\/|#|\/\*|--)\s*.*\b(bad|violat\w*|anti-?pattern|code smell|wrong)\b/i.test(l));
            if (tele) warnings.push(`${rel(scaffold)}: ${f} may telegraph a flaw in a comment: ${tele.trim().slice(0, 80)}`);
            if (lines > 160) err(rel(scaffold), `${f} has ${lines} lines; keep a fixture small enough to read in one pass (160 lines at most)`);
          }
          fs.rmSync(tmp, { recursive: true, force: true });
        }
      }

      // prompt
      const promptText = readIf(path.join(dir, 'prompt.md')) ?? '';
      const target = promptText.match(/^Review (\S+) before I merge it/)?.[1];
      if (!target) err(rel(path.join(dir, 'prompt.md')), 'the prompt must start with "Review <path> before I merge it" (the runner builds the slash variant from it)');
      else {
        const prefix = target.endsWith('/') ? target : `${target}/`;
        if (!fixtureFiles.includes(target) && !fixtureFiles.some((f) => f.startsWith(prefix))) err(rel(path.join(dir, 'prompt.md')), `${target} is not a file or folder created by scaffold.sh (it creates: ${fixtureFiles.join(', ') || 'nothing'})`);
      }
      if (!/Do not edit any file\./.test(promptText)) err(rel(path.join(dir, 'prompt.md')), 'the prompt must say "Do not edit any file."');
      if (/\/[a-z-]+:[a-z-]+|clean-code|plugin|skill/i.test(promptText.replace(/^Review \S+/, '')) && !/refactoring|clean-code/i.test(slug)) warnings.push(`${rel(path.join(dir, 'prompt.md'))}: the natural prompt should not name the plugin or its skills`);

      // graders
      const gdir = path.join(dir, 'graders');
      const graders = fs.existsSync(gdir) ? listDir(gdir).filter((e) => e.isFile() && e.name.endsWith('.md')) : [];
      if (!graders.length) err(where, 'graders/ has no .md files');
      let llm = 0; let weight = 0;
      for (const g of graders) {
        const gp = path.join(gdir, g.name);
        const gt = fs.readFileSync(gp, 'utf8');
        let parsed;
        try { parsed = frontmatter(gt); } catch (e) { err(rel(gp), e.message); continue; }
        if (useYaml) { try { const raw = gt.replace(/\r\n/g, '\n'); if (JSON.stringify(pyYamlLoad(raw.slice(4, raw.indexOf('\n---', 4)))) !== JSON.stringify(parsed.data)) err(rel(gp), 'PyYAML reads the frontmatter differently from the built-in parser'); } catch (e) { err(rel(gp), e.message); } }
        const d = parsed.data;
        if (!GRADER_TYPES.has(d.type)) err(rel(gp), `type "${d.type}" is not one of ${[...GRADER_TYPES].join(', ')}`);
        if (d.weight !== undefined && !(typeof d.weight === 'number' && d.weight > 0)) err(rel(gp), 'weight must be a positive number');
        if (!KEBAB.test(g.name.replace(/\.md$/, ''))) err(rel(gp), 'grader file names are kebab-case');
        if (d.type === 'regex') {
          if (typeof d.pattern !== 'string' || !d.pattern) err(rel(gp), 'regex grader needs a pattern');
          else { try { new RegExp(d.pattern, d.flags ?? ''); } catch (e) { err(rel(gp), `pattern does not compile: ${e.message}`); } }
          if (d.match !== undefined && !['not_contains'].includes(d.match) && !/^count:\d+$/.test(d.match)) err(rel(gp), 'match must be not_contains or count:N');
        }
        if (d.type === 'llm') {
          llm++; weight += d.weight ?? 1;
          if (!/\bPASS\b/.test(parsed.body) || !/\bFAIL\b/.test(parsed.body)) err(rel(gp), 'an llm grader states both what PASSES and what FAILS');
          if (parsed.body.length > 700) err(rel(gp), 'an llm grader is one short criterion (700 characters at most)');
        }
      }
      if (kind === 'detect' && llm < MIN_DEFECT_GRADERS) err(where, `a detect case needs at least ${MIN_DEFECT_GRADERS} llm graders, one per planted violation (found ${llm})`);
      if (kind === 'control' && llm < 1) err(where, 'a control case needs an llm grader for false alarms');
      if (kind === 'detect' && weight > 12) warnings.push(`${where}: total llm weight ${weight} is high; one violation should carry weight 1 (2 for the one the plugin is built around)`);
    }
    if (detect < MIN_DETECT) err(`evals/${slug}`, `needs at least ${MIN_DETECT} detect cases, has ${detect}`);
    if (control < 1) err(`evals/${slug}`, 'needs at least 1 control case');
  }
  return { errors, warnings, suites, cases };
}

function walk(dir) {
  return listDir(dir).flatMap((e) => (e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const requireAll = args.includes('--require-all');
  const slugs = args.filter((a) => !a.startsWith('--'));
  const bad = slugs.filter((s) => !REGISTRY.books.some((b) => b.slug === s));
  if (bad.length) { console.error(`unknown plugin(s): ${bad.join(', ')}`); process.exit(2); }
  const { errors, warnings, suites, cases } = validateEvals({ slugs: slugs.length ? slugs : null, requireAll });
  for (const w of warnings) console.log(`WARN  ${w}`);
  for (const e of errors.slice(0, 60)) console.log(`ERROR ${e}`);
  if (errors.length > 60) console.log(`... and ${errors.length - 60} more`);
  console.log(errors.length ? `FAIL evals: ${errors.length} errors in ${suites} suite(s), ${cases} case(s)` : `PASS evals: ${suites} suite(s), ${cases} case(s)`);
  process.exit(errors.length ? 1 : 0);
}
