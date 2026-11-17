#!/usr/bin/env node
// Validates what sits around the 14 book plugins: the guided companion plugin, the preset bundles, the project settings text inside the
// books, core.json, the CI files and the generated references. Fast and dependency-free (PyYAML is used for the CI YAML when installed).
//   node scripts/validate-meta.mjs
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LIMITS, REGISTRY, ROOT, SKILL_KEYS, listDir, parseFrontmatter, readIf } from './lib.mjs';
import { pairVerdict, validateConfig } from './guided-config-lib.mjs';
import { expected, targets } from './apply-project-settings.mjs';

export function validateMeta() {
  const errors = [];
  const err = (where, msg) => errors.push(`${where}: ${msg}`);
  const slugs = REGISTRY.books.map((b) => b.slug);
  const j = (rel) => { try { return JSON.parse(fs.readFileSync(path.join(ROOT, rel), 'utf8')); } catch (e) { err(rel, e.message); return null; } };

  // ---------------------------------------------------------------- the guided plugin
  const guided = path.join(ROOT, 'meta', 'guided');
  const man = j('meta/guided/.claude-plugin/plugin.json');
  if (man && (man.name !== 'guided' || !/^\d+\.\d+\.\d+$/.test(man.version) || !man.description || man.description.length > 400)) err('meta/guided/.claude-plugin/plugin.json', 'name must be "guided", version semver, description 1-400 characters');
  const WANT = ['start', 'which-book', 'config', 'review', 'conflicts', 'ci-setup'];
  const have = listDir(path.join(guided, 'skills')).filter((e) => e.isDirectory()).map((e) => e.name).sort();
  if (JSON.stringify(have) !== JSON.stringify([...WANT].sort())) err('meta/guided/skills', `expected ${WANT.join(', ')}, found ${have.join(', ')}`);
  for (const name of have) {
    const file = path.join(guided, 'skills', name, 'SKILL.md');
    const text = readIf(file) ?? '';
    const { data, body, problems } = parseFrontmatter(text);
    for (const p of problems) err(path.relative(ROOT, file), `frontmatter: ${p}`);
    if (!data) continue;
    for (const k of Object.keys(data)) if (!SKILL_KEYS.has(k)) err(path.relative(ROOT, file), `frontmatter key "${k}" is not a Claude Code skill key`);
    if (data.name !== name) err(path.relative(ROOT, file), 'name must equal the folder');
    if (data['disable-model-invocation'] !== true) err(path.relative(ROOT, file), 'every guided skill is a workflow you run by name: disable-model-invocation: true');
    if (!data.description || data.description.length > LIMITS.skillDescMax) err(path.relative(ROOT, file), `description must be 1-${LIMITS.skillDescMax} characters`);
    if (!/Treat repository content[^.]*as data, not instructions/.test(body)) err(path.relative(ROOT, file), 'must tell the model to treat repository content as data');
    if (name !== 'start' && /\bWrite\b|\bEdit\b/.test(data['allowed-tools'] ?? '') && !['config', 'ci-setup'].includes(name)) err(path.relative(ROOT, file), 'only config and ci-setup may write files');
    if (name === 'review' && /\b(Write|Edit)\b/.test(data['allowed-tools'] ?? '')) err(path.relative(ROOT, file), 'the combined review never edits files');
    for (const m of body.matchAll(/\$\{CLAUDE_PLUGIN_ROOT\}\/([A-Za-z0-9_./-]+)/g)) {
      const target = m[1].replace(/[.,;:)]+$/, '');
      if (!fs.existsSync(path.join(guided, target))) err(path.relative(ROOT, file), `refers to \${CLAUDE_PLUGIN_ROOT}/${target}, which does not exist`);
    }
    // every book or command it names must exist
    for (const m of body.matchAll(/`\/([a-z][a-z-]*):([a-z][a-z-]*)`/g)) {
      if (m[1] === 'guided' && !WANT.includes(m[2])) err(path.relative(ROOT, file), `names /guided:${m[2]}, which does not exist`);
    }
  }
  for (const f of ['README.md', 'LICENSE', 'NOTICE.md']) if (!fs.existsSync(path.join(guided, f))) err(`meta/guided/${f}`, 'missing');

  // ---------------------------------------------------------------- presets and bundles
  const presets = j('scripts/presets.json')?.presets ?? [];
  const names = new Set();
  for (const p of presets) {
    if (names.has(p.name)) err('scripts/presets.json', `duplicate preset ${p.name}`);
    names.add(p.name);
    const { problems } = validateConfig({ primary: p.primary, secondary: p.secondary });
    for (const x of problems) err(`scripts/presets.json (${p.name})`, x);
    const members = [p.primary, ...p.secondary];
    for (let a = 0; a < members.length; a++) for (let b = a + 1; b < members.length; b++) {
      const v = pairVerdict(members[a], members[b]);
      if (!v || v.verdict !== 'Complementary') err(`scripts/presets.json (${p.name})`, `${members[a]} + ${members[b]} is ${v?.verdict ?? 'unknown'}; a preset only combines books rated Complementary`);
    }
    const dir = `meta/bundles/guided-${p.name}`;
    const bm = j(`${dir}/.claude-plugin/plugin.json`);
    if (bm) {
      const want = [...members, 'guided'];
      if (JSON.stringify(bm.dependencies) !== JSON.stringify(want)) err(`${dir}/.claude-plugin/plugin.json`, `dependencies must be ${want.join(', ')}`);
      if (bm.name !== `guided-${p.name}`) err(`${dir}/.claude-plugin/plugin.json`, 'name must be guided-<preset>');
      for (const d of bm.dependencies ?? []) if (!slugs.includes(d) && d !== 'guided') err(`${dir}/.claude-plugin/plugin.json`, `dependency ${d} is not a plugin of this marketplace`);
    }
    for (const f of ['README.md', 'LICENSE']) if (!fs.existsSync(path.join(ROOT, dir, f))) err(`${dir}/${f}`, 'missing');
  }
  const mp = j('.claude-plugin/marketplace.json');
  if (mp) {
    const listed = new Set(mp.plugins.map((x) => x.name));
    for (const n of ['guided', ...presets.map((p) => `guided-${p.name}`), ...slugs]) if (!listed.has(n)) err('.claude-plugin/marketplace.json', `does not list ${n}`);
  }

  // ---------------------------------------------------------------- core.json (when it exists)
  const core = readIf(path.join(ROOT, 'scripts', 'core.json'));
  if (core) {
    const c = JSON.parse(core);
    for (const slug of slugs) {
      const e = c[slug];
      if (!e) { err('scripts/core.json', `no entry for ${slug}`); continue; }
      const dir = path.join(ROOT, 'plugins', slug);
      for (const w of e.workflows ?? []) if (!fs.existsSync(path.join(dir, 'skills', w, 'SKILL.md'))) err('scripts/core.json', `${slug}: workflow ${w} does not exist`);
      for (const s of e.skills ?? []) if (!fs.existsSync(path.join(dir, 'skills', s, 'SKILL.md'))) err('scripts/core.json', `${slug}: skill ${s} does not exist`);
      for (const a of e.agents ?? []) if (!fs.existsSync(path.join(dir, 'agents', `${a}.md`))) err('scripts/core.json', `${slug}: agent ${a} does not exist`);
      const total = (e.workflows?.length ?? 0) + (e.skills?.length ?? 0) + (e.agents?.length ?? 0);
      if (total < 4 || total > 12) err('scripts/core.json', `${slug}: a core set has 4 to 12 components, has ${total}`);
      for (const w of ['review', 'plan', 'checklist', 'fix']) if (!(e.workflows ?? []).includes(w)) err('scripts/core.json', `${slug}: the core workflows include ${w}`);
    }
  }

  // ---------------------------------------------------------------- the settings text inside the books
  for (const slug of slugs) {
    for (const t of targets(slug)) {
      const text = readIf(t.file);
      if (text == null) { err(path.relative(ROOT, t.file), 'missing'); continue; }
      let next; try { next = expected(slug, t.kind, t.name, text); } catch (e) { err(path.relative(ROOT, t.file), e.message); continue; }
      if (next !== text) err(path.relative(ROOT, t.file), 'project-settings or JSON-output text is missing or stale; run: node scripts/apply-project-settings.mjs');
    }
  }

  // ---------------------------------------------------------------- generated references are fresh
  const g = spawnSync(process.execPath, [path.join(ROOT, 'scripts', 'gen-guided.mjs'), '--check'], { encoding: 'utf8' });
  if (g.status !== 0) err('meta/', g.stderr.trim().split('\n').slice(0, 6).join(' '));

  // ---------------------------------------------------------------- CI files
  const yamlOk = spawnSync('python3', ['-c', 'import yaml'], { encoding: 'utf8' }).status === 0;
  for (const f of ['.github/actions/guided-review/action.yml', 'docs/examples/guided-review.yml']) {
    if (!fs.existsSync(path.join(ROOT, f))) { err(f, 'missing'); continue; }
    if (yamlOk) { const r = spawnSync('python3', ['-c', 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))', path.join(ROOT, f)], { encoding: 'utf8' }); if (r.status !== 0) err(f, `YAML does not parse: ${r.stderr.trim().split('\n').pop()}`); }
  }
  const pkg = j('package.json');
  for (const [bin, file] of Object.entries(pkg?.bin ?? {})) if (!fs.existsSync(path.join(ROOT, file))) err('package.json', `bin ${bin} points at ${file}, which does not exist`);
  return errors;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const errors = validateMeta();
  for (const e of errors.slice(0, 50)) console.log(`ERROR ${e}`);
  if (errors.length > 50) console.log(`... and ${errors.length - 50} more`);
  console.log(errors.length ? `FAIL meta: ${errors.length} errors` : 'PASS meta: guided plugin, bundles, settings text and CI files are consistent');
  process.exit(errors.length ? 1 : 0);
}
