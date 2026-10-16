#!/usr/bin/env node
// Validates every plugin plus the marketplace file. Used locally and in CI.
//   node scripts/validate-all.mjs [--no-cli] [--quiet]
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { ROOT, REGISTRY, listDir, listPluginDirs, loadPlugin, readIf } from './lib.mjs';
import { buildMarketplace } from './catalog-lib.mjs';
import { validatePlugin } from './validate-plugin.mjs';

const args = process.argv.slice(2);
const noCli = args.includes('--no-cli');
const quiet = args.includes('--quiet');
let failed = 0;
const rows = [];

for (const dir of listPluginDirs()) {
  const { plugin, errors, warnings, stats } = validatePlugin(dir, { noCli });
  rows.push([plugin.slug, stats.skills, stats.agents, stats.styles, stats.total, errors.length, warnings.length]);
  for (const e of errors) console.log(`ERROR ${plugin.slug}/${e}`);
  if (!quiet) for (const w of warnings) console.log(`WARN  ${plugin.slug}/${w}`);
  if (errors.length) failed++;
}

// repo-level docs: every <slug>:<name> reference and relative link must resolve
const docErrors = [];
{
  const slugs = REGISTRY.books.map((b) => b.slug).sort((a, b) => b.length - a.length);
  const names = new Map();
  for (const dir of listPluginDirs()) {
    const pl = loadPlugin(dir);
    names.set(pl.slug, new Set([...pl.skills, ...pl.agents, ...pl.styles].map((c) => c.data?.name ?? c.id)));
  }
  const refRe = new RegExp(`(?<![\\w-])(?:/|@agent-)?(${slugs.map((x) => x.replace(/-/g, '\\-')).join('|')}):([a-z][a-z0-9]*(?:-[a-z0-9]+)*)`, 'g');
  const files = ['README.md', 'CONTRIBUTING.md', 'CHANGELOG.md', ...listDir(path.join(ROOT, 'docs')).filter((e) => e.isFile() && e.name.endsWith('.md')).map((e) => `docs/${e.name}`)];
  for (const f of files) {
    const text = readIf(path.join(ROOT, f));
    if (text == null) continue;
    for (const m of text.matchAll(refRe)) {
      const set = names.get(m[1]);
      if (set && !set.has(m[2])) docErrors.push(`${f}: reference ${m[1]}:${m[2]} does not exist`);
    }
    for (const m of text.matchAll(/\]\(((?!https?:|mailto:|#)[^)\s#]+)(?:#[^)]*)?\)/g)) {
      if (!fs.existsSync(path.resolve(ROOT, path.dirname(f), m[1]))) docErrors.push(`${f}: broken relative link ${m[1]}`);
    }
  }
}
for (const e of [...new Set(docErrors)]) console.log(`ERROR docs/${e}`);
if (docErrors.length) failed++;

// marketplace file
const mpErrors = [];
const mpText = readIf(path.join(ROOT, '.claude-plugin', 'marketplace.json'));
if (mpText == null) mpErrors.push('.claude-plugin/marketplace.json is missing');
else {
  try {
    const have = JSON.parse(mpText);
    const want = buildMarketplace();
    if (JSON.stringify(have) !== JSON.stringify(want)) mpErrors.push('marketplace.json is stale; run: node scripts/gen-catalog.mjs --root');
    for (const p of want.plugins) if (!fs.existsSync(path.join(ROOT, p.source))) mpErrors.push(`source ${p.source} does not exist`);
  } catch (e) { mpErrors.push(`invalid JSON: ${e.message}`); }
}
if (!noCli && mpText != null) {
  const r = spawnSync('claude', ['plugin', 'validate', ROOT], { encoding: 'utf8', timeout: 180000 });
  if (!(r.error && r.error.code === 'ENOENT') && r.status !== 0) mpErrors.push(`claude plugin validate: ${`${r.stdout}${r.stderr}`.trim().split('\n').slice(0, 10).join(' | ')}`);
}
for (const e of mpErrors) console.log(`ERROR marketplace/${e}`);
if (mpErrors.length) failed++;

console.log('\nplugin'.padEnd(28) + 'skills agents styles total errors warns');
for (const r of rows) console.log(`${String(r[0]).padEnd(27)}${String(r[1]).padStart(6)}${String(r[2]).padStart(7)}${String(r[3]).padStart(7)}${String(r[4]).padStart(6)}${String(r[5]).padStart(7)}${String(r[6]).padStart(6)}`);
console.log(`\n${rows.length}/${REGISTRY.books.length} plugins present; ${failed ? `${failed} FAILED` : 'all passed'}`);
process.exit(failed ? 1 : 0);
