#!/usr/bin/env node
// Rebuilds evals/summary/<slug>.json from the full results that scripts/run-evals.mjs left in evals/results/ (git-ignored), without calling a
// model. Use it after a change to the way a summary is computed. A plugin whose results contain failed runs is skipped and says so.
//   node scripts/rebuild-eval-summaries.mjs [slug ...]
import fs from 'node:fs';
import path from 'node:path';
import { REGISTRY, ROOT } from './lib.mjs';
import { compact, failedRunErrors } from './evals-summary-lib.mjs';

const want = process.argv.slice(2);
const slugs = want.length ? want : REGISTRY.books.map((b) => b.slug);
for (const slug of slugs) {
  const passes = [];
  for (const [id, ablation] of [['compare', 'with-without'], ['slash', 'none']]) {
    const file = path.join(ROOT, 'evals', 'results', `${slug}.${id}.json`);
    if (!fs.existsSync(file)) continue;
    const res = JSON.parse(fs.readFileSync(file, 'utf8'));
    const errors = failedRunErrors(res);
    if (errors.length) { console.log(`${slug} (${id}): ${errors.length} failed run(s), skipped: ${errors[0].slice(0, 80)}`); passes.length = 0; break; }
    const old = path.join(ROOT, 'evals', 'summary', `${slug}.json`);
    const prev = fs.existsSync(old) ? JSON.parse(fs.readFileSync(old, 'utf8')).passes.find((p) => p.id === id) : null;
    const c = compact(id, ablation, res, prev?.model ?? 'default of the Claude Code session', prev?.runsPerCase ?? 1);
    // runs made before the format check read the label from each plugin's template looked for "Why:" and philosophy-of-design's template says "Cost:"
    if (slug === 'philosophy-of-design') for (const k of c.cases) k.formatOk = null;
    passes.push(c);
  }
  if (passes.length < 2) continue;
  const old = path.join(ROOT, 'evals', 'summary', `${slug}.json`);
  const date = fs.existsSync(old) ? JSON.parse(fs.readFileSync(old, 'utf8')).date : new Date().toISOString().slice(0, 10);
  fs.mkdirSync(path.dirname(old), { recursive: true });
  fs.writeFileSync(old, `${JSON.stringify({ plugin: slug, date, passes }, null, 2)}\n`);
  console.log(`${slug}: rebuilt`);
}
