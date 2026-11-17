#!/usr/bin/env node
// Creates, checks and explains the project settings file .guided-plugins.json (docs/PROJECT_CONFIG.md).
//   node scripts/guided-config.mjs init --preset everyday-code          # writes ./.guided-plugins.json
//   node scripts/guided-config.mjs init --primary clean-code --secondary refactoring --strictness relaxed --ignore 'vendor/' --ignore '*.generated.*'
//   node scripts/guided-config.mjs validate [path]                      # exit 1 on a problem; verdicts for the chosen books are notes
//   node scripts/guided-config.mjs explain                              # the effective settings in plain words
//   node scripts/guided-config.mjs check-path src/legacy/a.js           # is this file ignored?
import fs from 'node:fs';
import path from 'node:path';
import { CONFIG_FILE, DEFAULTS, FAIL_ON, STRICTNESS, isIgnored, loadConfig, validateConfig } from './guided-config-lib.mjs';
import { ROOT } from './lib.mjs';

const PRESETS = JSON.parse(fs.readFileSync(path.join(ROOT, 'scripts', 'presets.json'), 'utf8')).presets;
const [cmd, ...rest] = process.argv.slice(2);
const flags = {}; const positional = [];
for (let i = 0; i < rest.length; i++) {
  const a = rest[i];
  if (!a.startsWith('--')) { positional.push(a); continue; }
  const k = a.slice(2);
  if (k === 'force') flags.force = true;
  else if (k === 'ignore') (flags.ignore ??= []).push(rest[++i]);
  else flags[k] = rest[++i];
}
const root = process.cwd();
const die = (msg, code = 2) => { console.error(msg); process.exit(code); };

if (cmd === 'init') {
  const target = path.join(root, CONFIG_FILE);
  if (fs.existsSync(target) && !flags.force) die(`${CONFIG_FILE} already exists; use --force to replace it`);
  let cfg = { version: 1 };
  if (flags.preset) {
    const p = PRESETS.find((x) => x.name === flags.preset);
    if (!p) die(`unknown preset "${flags.preset}". presets: ${PRESETS.map((x) => x.name).join(', ')}`);
    cfg.primary = p.primary; cfg.secondary = p.secondary;
  }
  if (flags.primary) cfg.primary = flags.primary;
  if (flags.secondary !== undefined) cfg.secondary = flags.secondary.split(',').map((s) => s.trim()).filter(Boolean);
  cfg.strictness = flags.strictness ?? DEFAULTS.strictness;
  cfg.ignore = flags.ignore ?? [];
  cfg.maxFindings = flags.maxFindings ? Number(flags.maxFindings) : DEFAULTS.maxFindings;
  cfg.failOn = flags['fail-on'] ?? DEFAULTS.failOn;
  const { problems, notes } = validateConfig(cfg);
  if (problems.length) die(`not written:\n  ${problems.join('\n  ')}`);
  const out = { $schema: 'https://raw.githubusercontent.com/Nouran99/guidedplugins/main/docs/guided-plugins.schema.json', ...cfg };
  fs.writeFileSync(target, `${JSON.stringify(out, null, 2)}\n`);
  console.log(`wrote ${CONFIG_FILE}`);
  for (const n of notes) console.log(`note: ${n}`);
} else if (cmd === 'validate') {
  const file = positional[0] ? path.resolve(positional[0]) : path.join(root, CONFIG_FILE);
  if (!fs.existsSync(file)) die(`${path.relative(root, file) || file} does not exist`);
  let raw;
  try { raw = JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { die(`not valid JSON: ${e.message}`, 1); }
  const { problems, notes } = validateConfig(raw);
  for (const n of notes) console.log(`note: ${n}`);
  if (problems.length) { for (const p of problems) console.error(`problem: ${p}`); process.exit(1); }
  console.log('ok');
} else if (cmd === 'explain') {
  const { config, file, problems, notes } = loadConfig(root);
  if (problems.length) { for (const p of problems) console.error(`problem: ${p}`); process.exit(1); }
  console.log(file ? `Settings from ${CONFIG_FILE}:` : `No ${CONFIG_FILE} here; the defaults apply:`);
  console.log(`- Primary book: ${config.primary ?? 'none chosen (each book acts alone)'}`);
  console.log(`- Secondary books: ${config.secondary.length ? config.secondary.join(', ') : 'none'}`);
  console.log(`- Strictness ${config.strictness}: ${{ relaxed: 'blockers and majors only', normal: 'blockers, majors and minors; nits are left out', strict: 'everything, nits included' }[config.strictness]}`);
  console.log(`- Ignored: ${config.ignore.length ? config.ignore.join(', ') : 'nothing'}`);
  console.log(`- At most ${config.maxFindings} findings per report`);
  console.log(`- CI fails on (the pre-push hook uses GUIDED_FAIL_ON, default blocker): ${config.failOn === 'never' ? 'nothing (report only)' : `${config.failOn} or worse`}`);
  for (const n of notes) console.log(`note: ${n}`);
} else if (cmd === 'check-path') {
  if (!positional[0]) die('usage: guided-config.mjs check-path <file>');
  const { config, problems } = loadConfig(root);
  if (problems.length) die(problems.join('\n'), 1);
  const ignored = isIgnored(positional[0], config.ignore);
  console.log(ignored ? 'ignored' : 'reviewed');
  process.exit(ignored ? 3 : 0);
} else {
  die(`usage: guided-config.mjs init|validate|explain|check-path [options]\n  init [--preset ${PRESETS.map((x) => x.name).join('|')}] [--primary SLUG] [--secondary a,b] [--strictness ${STRICTNESS.join('|')}] [--ignore GLOB]... [--maxFindings N] [--fail-on ${FAIL_ON.join('|')}] [--force]`);
}
