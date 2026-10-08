#!/usr/bin/env node
// Validates every plugin plus the marketplace file. Used locally and in CI.
//   node scripts/validate-all.mjs [--no-cli] [--quiet]
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { ROOT, REGISTRY, listPluginDirs, readIf } from './lib.mjs';
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
