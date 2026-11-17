#!/usr/bin/env node
// Writes docs/EVALS.md from evals/summary/<slug>.json (written by scripts/run-evals.mjs or scripts/rebuild-eval-summaries.mjs).
//   node scripts/summarize-evals.mjs
// Scores are "defect scores": the share, by weight, of the graders about planted problems that passed. The report-format checks that the slash
// variants add are left out of every number here (they are shown as a separate column), so the plugin's workflow and the baseline are scored on
// the same graders.
import fs from 'node:fs';
import path from 'node:path';
import { REGISTRY, ROOT, readIf } from './lib.mjs';

const pct = (x) => (typeof x === 'number' ? `${Math.round(x * 100)}%` : '·');
const sign = (x) => (typeof x === 'number' ? `${x > 0.005 ? '+' : x < -0.005 ? '−' : '±'}${Math.abs(Math.round(x * 100))}` : '·');
const avg = (xs) => { const v = xs.filter((x) => typeof x === 'number'); return v.length ? v.reduce((a, c) => a + c, 0) / v.length : null; };
const rows = []; const detail = []; const have = [];
const runs = new Set(); const versions = new Set(); const dates = new Set(); const models = new Set(); let cost = 0;

for (const b of REGISTRY.books) {
  const text = readIf(path.join(ROOT, 'evals', 'summary', `${b.slug}.json`));
  if (!text) { rows.push(`| ${b.title} | not run | | | | | | |`); continue; }
  const s = JSON.parse(text);
  dates.add(s.date);
  const compare = s.passes.find((p) => p.id === 'compare');
  const slash = s.passes.find((p) => p.id === 'slash');
  for (const p of s.passes) { if (p.claudeVersion) versions.add(p.claudeVersion); if (p.runsPerCase) runs.add(p.runsPerCase); if (p.costUsd) cost += p.costUsd; if (p.model) models.add(p.model); }
  const slashBy = new Map((slash?.cases ?? []).map((c) => [c.name.replace(/--slash$/, ''), c]));
  const isControl = (c) => /control/.test(c.name);
  const det = (compare?.cases ?? []).filter((c) => !isControl(c));
  const ctl = (compare?.cases ?? []).filter(isControl);
  const base = avg(det.map((c) => c.defectWithout));
  const nat = avg(det.map((c) => c.defectWith));
  const sl = avg(det.map((c) => slashBy.get(c.name)?.defectWith));
  const ctlBase = avg(ctl.map((c) => c.defectWithout));
  const ctlNat = avg(ctl.map((c) => c.defectWith));
  const ctlSlash = avg(ctl.map((c) => slashBy.get(c.name)?.defectWith));
  const fired = avg((compare?.cases ?? []).map((c) => c.skillFired));
  const fmt = avg([...slashBy.values()].map((c) => c.formatOk));
  have.push({ title: b.title, base, nat, sl, ctlBase, ctlNat, ctlSlash, fired });
  rows.push(`| ${b.title} | ${pct(base)} | ${pct(nat)} | ${pct(sl)} | ${sign(typeof sl === 'number' && typeof base === 'number' ? sl - base : null)} | ${pct(ctlBase)} / ${pct(ctlNat)} / ${pct(ctlSlash)} | ${pct(fired)} | ${pct(fmt)} |`);
  detail.push(`### ${b.title}\n\n| Fixture | Baseline | Natural prompt + plugin | Plugin workflow | Skill used | Report format ok |\n| --- | --- | --- | --- | --- | --- |\n${(compare?.cases ?? []).map((c) => `| ${c.name} | ${pct(c.defectWithout)} | ${pct(c.defectWith)} | ${pct(slashBy.get(c.name)?.defectWith)} | ${pct(c.skillFired)} | ${pct(slashBy.get(c.name)?.formatOk)} |`).join('\n')}\n`);
}

const lo = (xs) => Math.min(...xs); const hi = (xs) => Math.max(...xs);
const deltas = have.filter((h) => typeof h.sl === 'number' && typeof h.base === 'number').map((h) => Math.round((h.sl - h.base) * 100));
const natDeltas = have.filter((h) => typeof h.nat === 'number' && typeof h.base === 'number').map((h) => Math.round((h.nat - h.base) * 100));
const firedAny = have.filter((h) => (h.fired ?? 0) > 0).length;
const lowerControls = have.filter((h) => typeof h.ctlSlash === 'number' && typeof h.ctlNat === 'number' && h.ctlSlash < h.ctlNat - 0.01).map((h) => h.title);
const lowBaselineControls = have.filter((h) => typeof h.ctlBase === 'number' && h.ctlBase < 0.75).map((h) => h.title);
const noisy = (d) => Math.abs(d) <= 15;
const reading = have.length ? `## Reading the results so far

${have.length} of ${REGISTRY.books.length} plugins have results${have.length < REGISTRY.books.length ? '; the others have suites that have not been run (see "How to run")' : ''}.

- **The plugin's own workflow found more of the planted problems than the model alone in ${deltas.filter((d) => d > 0).length} of ${deltas.length} plugins**, by ${lo(deltas)} to ${hi(deltas)} points on average over the detect fixtures (workflow and baseline are scored on the same graders; the report-format checks are not counted). ${deltas.filter(noisy).length ? `${deltas.filter(noisy).length} of those differences are ${deltas.filter(noisy).length === 1 ? 'a' : ''} 15 points or less, which one run per case cannot distinguish from noise.` : ''}
- **The natural prompt with the plugin installed** scored ${lo(natDeltas)} to ${hi(natDeltas)} points above the baseline, although the model called one of the plugin's skills in ${firedAny} of ${have.length} plugins. So that difference is either noise (one run per case) or the effect of the plugin's descriptions sitting in the context; these runs cannot tell which. Treat the plugin's skills as something you invoke, not something that fires on its own.
- **Clean control** (code that follows the book; the column shows baseline / natural + plugin / workflow). ${lowerControls.length ? `The workflow scored lower than the natural prompt with the plugin for ${lowerControls.join(', ')}.` : 'The workflow never scored lower than the natural prompt with the plugin.'} Read this column as a calibration check, not as a false-alarm rate: the natural prompt says that "nothing needs to change" is an acceptable answer and the slash prompt cannot, the controls are a single fixture each, and a reviewer may legitimately report a real correctness point that the grader reads as a design problem.${lowBaselineControls.length ? ` The baseline itself scored under 75% on the control of ${lowBaselineControls.join(', ')}: for those the grader or the fixture needs work before the number means anything.` : ''}
` : '';

const out = `# Eval results

Generated by \`scripts/summarize-evals.mjs\` from \`evals/summary/*.json\`. Do not edit by hand. How the suites work: [evals/README.md](../evals/README.md).

**What is measured.** Each suite plants several violations of the book's rules in small realistic files and scores a code review by the share of them it finds (one judge-graded criterion per planted violation), plus a clean file where a review should find nothing serious.
Three numbers per fixture: **baseline** (a natural prompt, no plugin), **natural prompt with the plugin installed** (do the plugin's skills fire on their own?) and **the plugin's workflow** (\`/<plugin>:review\`).

**How much to trust it.** ${[...runs].sort().join(' and ') || 'no'} run${runs.size === 1 && runs.has(1) ? '' : 's'} per case; Claude Code ${[...versions].join(', ') || 'n/a'}; model: ${[...models].join(', ') || 'n/a'}; ${[...dates].sort().join(', ') || 'no date'}; about $${cost.toFixed(2)} of model usage in total.
A single run per case is a smoke test: expect a swing of one planted violation either way, and judge-graded criteria are not perfectly stable. The fixtures were written by the same project that wrote the plugins, and the graders encode the plugins' own idea of a violation, so a high score shows that the plugin does what it says, not that its rules are right. No real project was measured. Treat differences of 15 points or less as noise until a suite has run three or more times.

${reading}
## Summary

Averages over the detect fixtures of each suite.

| Plugin | Baseline | Natural + plugin | Plugin workflow | Workflow vs baseline (points) | Clean control: baseline / natural + plugin / workflow | Plugin skill used on the natural prompt | Workflow report in the right format |
| --- | --- | --- | --- | --- | --- | --- | --- |
${rows.join('\n')}

## By fixture

${detail.join('\n') || '_No results yet._'}

## How to run

\`\`\`bash
claude auth login                                   # the runs use your Claude account; a failed login makes every run fail (nothing is recorded then)
node scripts/run-evals.mjs <plugin> --runs 3        # one plugin, three runs per case
node scripts/run-evals.mjs all --max-cost-usd 5     # every plugin, one run per case; the cap applies to each pass of each plugin (about $2.5 per plugin)
node scripts/summarize-evals.mjs                    # rewrite this page
\`\`\`
`;
fs.writeFileSync(path.join(ROOT, 'docs', 'EVALS.md'), out);
console.log(`wrote docs/EVALS.md (${have.length} of ${REGISTRY.books.length} plugins with results)`);
