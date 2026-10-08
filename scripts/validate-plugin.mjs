#!/usr/bin/env node
// Validates one plugin against docs/PLUGIN_SPEC.md.
//   node scripts/validate-plugin.mjs plugins/<slug> [--no-cli] [--quiet]
// Exit code 1 when any ERROR is reported. Warnings never fail the run.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import {
  AGENT_KEYS, COLORS, EFFORTS, LIMITS, MODELS, REGISTRY, SKILL_KEYS, STYLE_KEYS,
  fullHeadings, jaccard, listDir, loadPlugin, norm, readIf, shingles, sourceCitations, toList, words,
} from './lib.mjs';
import {
  README_END, README_START, counts, isManual, renderCatalogBlock, renderComponentsDoc,
  renderTraceabilityDoc, replaceReadmeBlock,
} from './catalog-lib.mjs';

const KEBAB = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const SEMVER = /^\d+\.\d+\.\d+$/;
const RESERVED_PREFIX = ['claude-', 'anthropic-', 'anthropics-', 'cc-plugin-'];
const RESERVED_NAME = new Set(['claude', 'anthropic', 'anthropics', 'claude-code', 'claude-mods']);
const PLACEHOLDERS = /\bTBD\b|lorem ipsum|__[A-Z][A-Z0-9_]{2,}__|<placeholder>|\[INSERT[^\]]*\]|\{\{[^}]+\}\}/i;
const REQUIRED = {
  skills: ['principles', 'review', 'audit', 'plan', 'explain-rule', 'checklist', 'fix'],
  agents: ['lead', 'final-gate'],
  styles: ['mentor', 'strict-reviewer', 'pair', 'terse'],
};
const IGNORED_IN_PLUGIN_AGENTS = ['permissionMode', 'hooks', 'mcpServers', 'initialPrompt'];

export function validatePlugin(dir, opts = {}) {
  const errors = [];
  const warnings = [];
  const plugin = loadPlugin(dir);
  const rel = (f) => path.relative(plugin.dir, f) || '.';
  const err = (where, msg) => errors.push(`${where}: ${msg}`);
  const warn = (where, msg) => warnings.push(`${where}: ${msg}`);
  const book = REGISTRY.books.find((b) => b.slug === plugin.slug);
  if (!book) err('plugin', `slug "${plugin.slug}" is not in scripts/books.json`);

  // ------------------------------------------------------------ manifest
  const m = plugin.manifest;
  if (plugin.manifestError) err('.claude-plugin/plugin.json', plugin.manifestError);
  else {
    if (m.name !== plugin.slug) err('plugin.json', `name "${m.name}" must equal the directory name "${plugin.slug}"`);
    if (!KEBAB.test(m.name ?? '')) err('plugin.json', 'name must be kebab-case');
    if (RESERVED_PREFIX.some((p) => (m.name ?? '').startsWith(p)) || RESERVED_NAME.has(m.name)) err('plugin.json', `name "${m.name}" is reserved`);
    if (!m.displayName) err('plugin.json', 'displayName is required');
    if (!SEMVER.test(m.version ?? '')) err('plugin.json', 'version must be semver (x.y.z)');
    if (!m.description || m.description.length < 40 || m.description.length > 300) err('plugin.json', 'description must be 40-300 characters');
    if (!m.author?.name) err('plugin.json', 'author.name is required');
    if (m.license !== 'MIT') err('plugin.json', 'license must be "MIT"');
    for (const k of ['homepage', 'repository']) {
      if (!/^https:\/\/github\.com\/[^/]+\/[^/]+/.test(m[k] ?? '')) err('plugin.json', `${k} must be a https://github.com/... URL`);
    }
    if (!Array.isArray(m.keywords) || m.keywords.length < 5) err('plugin.json', 'keywords needs at least 5 entries');
    const uc = m.userConfig?.inject_rules;
    if (!uc || uc.type !== 'boolean' || uc.default !== false || !uc.title || !uc.description) {
      err('plugin.json', 'userConfig.inject_rules must be {type: "boolean", title, description, default: false}');
    }
    const known = new Set(['$schema', 'name', 'displayName', 'version', 'description', 'author', 'homepage', 'repository', 'license', 'keywords', 'userConfig']);
    for (const k of Object.keys(m)) if (!known.has(k)) warn('plugin.json', `unexpected top-level key "${k}"`);
  }

  // ------------------------------------------------------------ required files
  for (const f of ['README.md', 'LICENSE', 'NOTICE.md', 'CHANGELOG.md', 'docs/DESIGN.md', 'docs/COMPONENTS.md', 'docs/TRACEABILITY.md',
    'hooks/hooks.json', 'scripts/session-context.sh', 'skills/principles/SKILL.md',
    'skills/principles/references/full.md', 'skills/principles/references/mini.md', 'skills/principles/references/nano.md']) {
    const p = path.join(plugin.dir, f);
    if (!fs.existsSync(p) || fs.statSync(p).size === 0) err(f, 'required file is missing or empty');
  }
  const license = readIf(path.join(plugin.dir, 'LICENSE')) ?? '';
  if (license && !/MIT License/.test(license)) err('LICENSE', 'must be the MIT license text');
  if (license && !license.includes(REGISTRY.marketplace.owner)) err('LICENSE', `must name ${REGISTRY.marketplace.owner}`);
  const notice = readIf(path.join(plugin.dir, 'NOTICE.md')) ?? '';
  if (notice && !(notice.includes(REGISTRY.marketplace.upstreamAuthor) && notice.includes(REGISTRY.marketplace.upstreamRepo))) {
    err('NOTICE.md', 'must credit the upstream author and repository');
  }

  // ------------------------------------------------------------ counts
  const c = counts(plugin);
  if (c.total < LIMITS.minTotal) err('counts', `${c.total} components, need at least ${LIMITS.minTotal} (skills + agents + output styles)`);
  if (c.skills < LIMITS.minSkills) err('counts', `${c.skills} skills, need at least ${LIMITS.minSkills}`);
  if (c.agents < LIMITS.minAgents) err('counts', `${c.agents} agents, need at least ${LIMITS.minAgents}`);
  if (c.styles < LIMITS.minStyles) err('counts', `${c.styles} output styles, need at least ${LIMITS.minStyles}`);
  if (c.auto > LIMITS.maxModelInvocableSkills) err('counts', `${c.auto} model-invocable skills, max ${LIMITS.maxModelInvocableSkills} (descriptions cost context every turn); set disable-model-invocation: true on workflow skills`);
  if (c.manual < LIMITS.minManualSkills) err('counts', `${c.manual} manual skills (disable-model-invocation: true), need at least ${LIMITS.minManualSkills}`);

  // fixed names so every book plugin feels the same to use
  const have = (list) => new Set(list.map((x) => x.data?.name ?? x.id));
  for (const n of REQUIRED.skills) if (!have(plugin.skills).has(n)) err('skills', `required skill "${n}" is missing`);
  for (const n of REQUIRED.agents) if (!have(plugin.agents).has(n)) err('agents', `required agent "${n}" is missing`);
  for (const n of REQUIRED.styles) if (!have(plugin.styles).has(n)) err('output-styles', `required output style "${n}" is missing`);

  // ------------------------------------------------------------ upstream rule files
  const refDir = path.join(plugin.dir, 'skills', 'principles', 'references');
  const fullText = readIf(path.join(refDir, 'full.md')) ?? '';
  const miniText = readIf(path.join(refDir, 'mini.md')) ?? '';
  const { all: headingSet, coverage } = fullHeadings(fullText);
  if (fullText && coverage.length < 3) warn('references/full.md', 'fewer than 3 headings found; traceability will be weak');
  const refGrams = shingles(words(`${fullText}\n${miniText}`), 8);

  // ------------------------------------------------------------ per-component checks
  const all = [...plugin.skills, ...plugin.agents, ...plugin.styles];
  const cited = new Set();
  const skillIndex = new Map(plugin.skills.map((s) => [s.data?.name ?? s.id, s]));

  for (const comp of all) {
    const where = rel(comp.file);
    if (comp.missing) { err(where, 'SKILL.md is missing'); continue; }
    for (const p of comp.problems ?? []) err(where, `frontmatter: ${p}`);
    if (!comp.data) continue;
    const d = comp.data;
    const body = comp.body ?? '';
    const allowed = comp.kind === 'skill' ? SKILL_KEYS : comp.kind === 'agent' ? AGENT_KEYS : STYLE_KEYS;
    for (const k of Object.keys(d)) {
      if (!allowed.has(k)) {
        err(where, IGNORED_IN_PLUGIN_AGENTS.includes(k) && comp.kind === 'agent'
          ? `"${k}" is ignored in plugin agents; remove it`
          : `unknown frontmatter key "${k}"`);
      }
    }
    if (typeof d.description !== 'string' || !d.description.trim()) { err(where, 'description is required'); continue; }

    // name rules
    if (comp.kind !== 'style') {
      if (d.name !== comp.id) err(where, `name "${d.name ?? ''}" must equal "${comp.id}"`);
      if (!KEBAB.test(comp.id) || comp.id.length > 40) err(where, 'name must be kebab-case and at most 40 characters');
    } else if (d.name && !KEBAB.test(d.name)) err(where, 'style name must be kebab-case');

    // description budget
    const dlen = d.description.length + (d.when_to_use ? String(d.when_to_use).length : 0);
    const [warnAt, maxAt] = comp.kind === 'agent' ? [LIMITS.agentDescWarn, LIMITS.agentDescMax] : [LIMITS.skillDescWarn, LIMITS.skillDescMax];
    if (comp.kind !== 'style') {
      const manualSkill = comp.kind === 'skill' && isManual(comp);
      if (dlen > maxAt) err(where, `description is ${dlen} chars, max ${maxAt}`);
      else if (dlen > warnAt && !manualSkill) warn(where, `description is ${dlen} chars; aim for <= ${warnAt}`);
    }

    // body size and Source section
    const minBody = comp.kind === 'skill' ? LIMITS.skillMinBody : comp.kind === 'agent' ? LIMITS.agentMinBody : LIMITS.styleMinBody;
    if (body.trim().length < minBody) err(where, `body is ${body.trim().length} chars, need at least ${minBody} (filler guard)`);
    if (comp.kind === 'skill' && comp.text.split('\n').length > LIMITS.skillMaxLines) err(where, `more than ${LIMITS.skillMaxLines} lines; move detail to a reference file`);
    const cites = sourceCitations(body);
    if (!cites || cites.length === 0) err(where, 'needs a "## Source" section citing upstream sections in backticks');
    else {
      for (const cite of cites) {
        const k = norm(cite);
        if (headingSet.size && !headingSet.has(k)) err(where, `Source cites "${cite}" which is not a heading in references/full.md`);
        else cited.add(k);
      }
    }
    if (PLACEHOLDERS.test(comp.text)) err(where, 'contains placeholder text');

    // type-specific
    if (comp.kind === 'skill') {
      const manual = isManual(comp);
      for (const k of ['disable-model-invocation', 'user-invocable']) {
        if (k in d && typeof d[k] !== 'boolean') err(where, `${k} must be true or false`);
      }
      if (manual && !d['argument-hint']) err(where, 'manual skills need an argument-hint');
      if (!manual && comp.id !== 'principles' && !/```/.test(body)) err(where, 'model-invocable topical skills need a fenced original example');
      if (d.context && d.context !== 'fork') err(where, 'context may only be "fork"');
      if (d.context === 'fork' && !manual) warn(where, 'context: fork skills should set disable-model-invocation: true');
      if (d.effort && !EFFORTS.has(d.effort)) err(where, `invalid effort "${d.effort}"`);
      if (d.model && !MODELS.has(d.model) && !/^claude-/.test(d.model)) err(where, `invalid model "${d.model}"`);
    }
    if (comp.kind === 'agent') {
      if (!/\buse\b/i.test(d.description)) err(where, 'description must say when to delegate ("Use when/after/before/proactively ...")');
      if (!MODELS.has(d.model) && !/^claude-/.test(d.model ?? '')) err(where, `model must be one of ${[...MODELS].join(', ')}`);
      if (!COLORS.has(d.color)) err(where, `color must be one of ${[...COLORS].join(', ')}`);
      if (!Number.isInteger(d.maxTurns) || d.maxTurns < 3 || d.maxTurns > 60) err(where, 'maxTurns must be an integer 3-60');
      if (d.effort && !EFFORTS.has(d.effort)) err(where, `invalid effort "${d.effort}"`);
      const tools = toList(d.tools);
      if (tools.length === 0) err(where, 'tools must be set explicitly (least privilege)');
      for (const t of tools) if (!/^([A-Z][A-Za-z]+(\(.*\))?|mcp__[\w*-]+)$/.test(t)) err(where, `malformed tool "${t}"`);
      const denied = toList(d.disallowedTools);
      for (const t of denied) if (tools.includes(t)) err(where, `tool "${t}" is both allowed and disallowed`);
      if (!/^##\s+.*output/im.test(body)) err(where, 'needs a "## Output ..." section defining the report format');
      for (const sk of toList(d.skills)) {
        const target = skillIndex.get(sk);
        if (!target) err(where, `skills: "${sk}" is not a skill in this plugin`);
        else if (isManual(target)) err(where, `skills: "${sk}" sets disable-model-invocation and cannot be preloaded`);
      }
    }
    if (comp.kind === 'style') {
      if (d['force-for-plugin'] === true) err(where, 'force-for-plugin must not be true');
      if (d['keep-coding-instructions'] !== true) err(where, 'keep-coding-instructions must be true');
    }

    // paths mentioned in the body must exist
    const skillDir = path.dirname(comp.file);
    for (const t of comp.text.matchAll(/\$\{CLAUDE_PLUGIN_ROOT\}\/([A-Za-z0-9_./-]+)/g)) {
      const p = t[1].replace(/[.,;:]+$/, '');
      if (!fs.existsSync(path.join(plugin.dir, p))) err(where, `references missing path \${CLAUDE_PLUGIN_ROOT}/${p}`);
    }
    for (const t of comp.text.matchAll(/\$\{CLAUDE_SKILL_DIR\}\/([A-Za-z0-9_./-]+)/g)) {
      const p = t[1].replace(/[.,;:]+$/, '');
      if (!fs.existsSync(path.join(skillDir, p))) err(where, `references missing path \${CLAUDE_SKILL_DIR}/${p}`);
    }
    for (const t of comp.text.matchAll(/\]\(([^)\s#]+)(?:#[^)]*)?\)/g)) {
      if (/^(https?:|mailto:)/.test(t[1])) continue;
      if (!fs.existsSync(path.resolve(skillDir, t[1]))) err(where, `broken relative link ${t[1]}`);
    }

    // reliance on copied rule text (informational)
    const grams = shingles(words(body), 8);
    if (grams.size > 40 && refGrams.size) {
      let hit = 0;
      for (const g of grams) if (refGrams.has(g)) hit++;
      if (hit / grams.size >= 0.5) warn(where, `${Math.round((100 * hit) / grams.size)}% of its 8-word runs appear verbatim in the upstream rules; add original guidance`);
    }
  }

  // unique names within type
  for (const group of [plugin.agents, plugin.styles]) {
    const seen = new Map();
    for (const comp of group) {
      const n = comp.data?.name ?? comp.id;
      if (seen.has(n)) err(rel(comp.file), `duplicate name "${n}" (also ${rel(seen.get(n).file)})`);
      seen.set(n, comp);
    }
  }

  // near-duplicate bodies within each type
  for (const group of [plugin.skills, plugin.agents, plugin.styles]) {
    const prepared = group.filter((x) => x.body).map((x) => ({ x, g: shingles(words(x.body.replace(/\n##\s+Source[\s\S]*$/i, '')), 4) }));
    for (let i = 0; i < prepared.length; i++) {
      for (let j = i + 1; j < prepared.length; j++) {
        const sim = jaccard(prepared[i].g, prepared[j].g);
        const label = `${rel(prepared[i].x.file)} ~ ${rel(prepared[j].x.file)} (${sim.toFixed(2)})`;
        if (sim >= LIMITS.dupError) err('duplicates', `near-duplicate components: ${label}`);
        else if (sim >= LIMITS.dupWarn) warn('duplicates', `very similar components: ${label}`);
      }
    }
  }

  // coverage of upstream sections
  const uncovered = coverage.filter((h) => !cited.has(h.key));
  if (uncovered.length) {
    const sample = uncovered.slice(0, 12).map((h) => `"${h.raw}"`).join(', ');
    err('traceability', `${uncovered.length}/${coverage.length} upstream sections are not cited by any component: ${sample}${uncovered.length > 12 ? ', ...' : ''}`);
  }

  // ------------------------------------------------------------ hooks
  const hookPath = path.join(plugin.dir, 'hooks', 'hooks.json');
  const hookText = readIf(hookPath);
  if (hookText) {
    try {
      const h = JSON.parse(hookText);
      const cmd = h?.hooks?.SessionStart?.[0]?.hooks?.[0]?.command ?? '';
      if (!cmd.includes('session-context.sh')) err('hooks/hooks.json', 'SessionStart must run scripts/session-context.sh');
      const script = path.join(plugin.dir, 'scripts', 'session-context.sh');
      if (fs.existsSync(script)) {
        try { fs.accessSync(script, fs.constants.X_OK); } catch { err('scripts/session-context.sh', 'is not executable (chmod +x)'); }
        const s = readIf(script) ?? '';
        if (!s.includes('CLAUDE_PLUGIN_OPTION_INJECT_RULES')) err('scripts/session-context.sh', 'must honor CLAUDE_PLUGIN_OPTION_INJECT_RULES');
      }
    } catch (e) { err('hooks/hooks.json', `invalid JSON: ${e.message}`); }
  }

  // ------------------------------------------------------------ README and generated docs
  const readme = readIf(path.join(plugin.dir, 'README.md')) ?? '';
  if (readme) {
    if (readme.length < LIMITS.readmeMinChars) err('README.md', `${readme.length} chars, need at least ${LIMITS.readmeMinChars}`);
    const need = [['install', /^#{1,3}\s+.*install/im], ['components', /^#{1,3}\s+.*components/im], ['usage', /^#{1,3}\s+.*(usage|walkthrough|example)/im],
      ['book mapping', /^#{1,3}\s+.*(how it maps|maps to|mapping|the book)/im], ['compatibility', /^#{1,3}\s+.*(works with|compatib|pairs well)/im],
      ['limitations', /^#{1,3}\s+.*(limitation|criticism|caveat)/im], ['attribution', /^#{1,3}\s+.*(attribution|license|credits)/im]];
    for (const [label, re] of need) if (!re.test(readme)) err('README.md', `missing a section on ${label}`);
    if (PLACEHOLDERS.test(readme)) err('README.md', 'contains placeholder text');
    if (!readme.includes(README_START) || !readme.includes(README_END)) err('README.md', `needs ${README_START} ... ${README_END} markers`);
    else {
      const fresh = replaceReadmeBlock(readme, renderCatalogBlock(plugin));
      if (fresh !== readme) err('README.md', 'component block is stale; run: node scripts/gen-catalog.mjs plugins/' + plugin.slug);
    }
    for (const t of readme.matchAll(/\]\(((?!https?:|mailto:|#)[^)\s#]+)(?:#[^)]*)?\)/g)) {
      if (!fs.existsSync(path.resolve(plugin.dir, t[1]))) err('README.md', `broken relative link ${t[1]}`);
    }
  }
  for (const [file, render] of [['docs/COMPONENTS.md', renderComponentsDoc], ['docs/TRACEABILITY.md', renderTraceabilityDoc]]) {
    const have = readIf(path.join(plugin.dir, file));
    if (have != null && have.trim() !== render(plugin).trim()) err(file, 'is stale; run: node scripts/gen-catalog.mjs plugins/' + plugin.slug);
  }

  // placeholder scan over remaining text files (not the vendored upstream rules)
  const scan = (d) => {
    for (const e of listDir(d)) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) { if (!['references', 'node_modules', 'skills', 'agents', 'output-styles'].includes(e.name)) scan(p); } else if (/\.(md|json|sh)$/.test(e.name)) {
        const t = readIf(p) ?? '';
        if (PLACEHOLDERS.test(t) && !/^README\.md$/.test(e.name)) err(rel(p), 'contains placeholder text');
      }
    }
  };
  scan(plugin.dir);

  // ------------------------------------------------------------ official CLI
  if (!opts.noCli) {
    const r = spawnSync('claude', ['plugin', 'validate', plugin.dir], { encoding: 'utf8', timeout: 120000 });
    if (r.error && r.error.code === 'ENOENT') warn('claude plugin validate', 'claude CLI not found; skipped');
    else {
      const out = `${r.stdout ?? ''}${r.stderr ?? ''}`.trim();
      if (r.status !== 0) err('claude plugin validate', out.split('\n').slice(0, 12).join(' | '));
      else if (/warning/i.test(out)) for (const line of out.split('\n').filter((l) => /warn|⚠/i.test(l)).slice(0, 8)) warn('claude plugin validate', line.trim());
    }
  }

  return { plugin, errors, warnings, stats: c };
}

function main() {
  const args = process.argv.slice(2);
  const dir = args.find((a) => !a.startsWith('--'));
  if (!dir) { console.error('usage: validate-plugin.mjs plugins/<slug> [--no-cli] [--quiet]'); process.exit(2); }
  const { errors, warnings, stats, plugin } = validatePlugin(dir, { noCli: args.includes('--no-cli') });
  const quiet = args.includes('--quiet');
  for (const e of errors) console.log(`ERROR ${e}`);
  if (!quiet) for (const w of warnings) console.log(`WARN  ${w}`);
  console.log(`${errors.length ? 'FAIL' : 'PASS'} ${plugin.slug}: ${stats.skills} skills, ${stats.agents} agents, ${stats.styles} styles = ${stats.total} components; ${errors.length} errors, ${warnings.length} warnings`);
  process.exit(errors.length ? 1 : 0);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
