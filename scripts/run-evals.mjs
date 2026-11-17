#!/usr/bin/env node
// Runs the eval suites in evals/<slug>/ against plugins/<slug> with `claude plugin eval` (Claude Code 2.1.269 or later).
//   node scripts/run-evals.mjs clean-code                       # every case, with and without the plugin, 1 run each
//   node scripts/run-evals.mjs clean-code refactoring --runs 3  # several plugins, more runs per case
//   node scripts/run-evals.mjs all --tag detect --max-cost-usd 5
//   node scripts/run-evals.mjs clean-code --case 'naming-*' --keep-temp
// The suites live outside the plugins (so they are not shipped to every user). For each plugin the runner copies plugins/<slug> and
// evals/<slug> into a temporary folder, runs the suite there, and writes the full result to evals/results/<slug>.json (git-ignored) and a
// compact summary to evals/summary/<slug>.json (committed; scripts/summarize-evals.mjs turns them into docs/EVALS.md).
// Two passes per plugin. "compare": the detect and control cases with a natural prompt ("Review src/x before I merge it ...") run with and
// without the plugin and report the difference (does the plugin help on its own?). "slash": for each of those cases the runner generates a
// variant whose prompt is the plugin's own workflow ("/<slug>:review src/x"), with the same defect graders plus checks on the report format,
// and runs it plugin-only (a baseline arm cannot run a slash command). Reading the two passes side by side gives, per fixture: baseline,
// natural prompt with the plugin installed, and the plugin's workflow.
// This spends model usage on your Claude account: each case is (runs x 2) agent runs plus 3 judge calls per llm grader and run.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ROOT, REGISTRY, listDir } from './lib.mjs';
import { compact, failedRunErrors } from './evals-summary-lib.mjs';

const argv = process.argv.slice(2);
const flags = {}; const names = [];
const VALUE = new Set(['runs', 'max-cost-usd', 'concurrency', 'threshold', 'case', 'tag', 'model', 'judge-model', 'ablation']);
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (!a.startsWith('--')) { names.push(a); continue; }
  const k = a.slice(2);
  if (VALUE.has(k)) { (flags[k] ??= []).push(argv[++i]); } else flags[k] = true;
}
const all = REGISTRY.books.map((b) => b.slug);
const slugs = names.includes('all') ? all : names;
if (!slugs.length || slugs.some((s) => !all.includes(s))) {
  console.error(`usage: run-evals.mjs <slug...|all> [--runs N] [--tag T] [--case GLOB] [--max-cost-usd N] [--concurrency N] [--threshold X] [--model M] [--judge-model M] [--keep-temp]\nplugins: ${all.join(', ')}`);
  process.exit(2);
}
const have = spawnSync('claude', ['--version'], { encoding: 'utf8' });
if (have.status !== 0) { console.error('the claude CLI (Claude Code 2.1.269 or later) is needed'); process.exit(2); }

const one = (k) => flags[k]?.[0];
const resultsDir = path.join(ROOT, 'evals', 'results');
const summaryDir = path.join(ROOT, 'evals', 'summary');
fs.mkdirSync(resultsDir, { recursive: true });
fs.mkdirSync(summaryDir, { recursive: true });

// Which arm layout a pass uses: the slash cases are plugin-only. --tag narrows the passes; without it both run.
const asked = flags.tag ?? [];
const PASSES = [
  { id: 'compare', ablation: 'with-without', tags: asked.length ? asked.filter((t) => t !== 'slash') : ['detect', 'control'] },
  { id: 'slash', ablation: 'none', tags: asked.length ? asked.filter((t) => t === 'slash') : ['slash'] },
].filter((p) => p.tags.length);

// Builds the slash variants inside the temporary copy of the suite.
// The review skill's output template: its header ("<Title> review: ...") and the label of the line that explains a finding ("Why:" in most
// plugins, "Cost:" in philosophy-of-design), both read from the template so that the format check matches what that plugin asks for.
function reviewTemplate(pluginDir) {
  const text = fs.readFileSync(path.join(pluginDir, 'skills', 'review', 'SKILL.md'), 'utf8');
  const block = text.slice(text.indexOf('## Output')).split('```')[1] ?? '';
  const first = block.split('\n').find((l) => l.trim());
  const m = first?.match(/^(.+?) review:/);
  if (!m) throw new Error(`cannot find the output header of ${pluginDir}/skills/review/SKILL.md`);
  const label = block.match(/^\s{2}([A-Z][A-Za-z]*):/m)?.[1];
  if (!label) throw new Error(`cannot find the explanation label in the output template of ${pluginDir}/skills/review/SKILL.md`);
  return { title: m[1], label };
}
function addSlashVariants(slug, evalsDir, pluginDir) {
  const { title, label } = reviewTemplate(pluginDir);
  for (const e of listDir(evalsDir).filter((x) => x.isDirectory() && x.name !== 'results')) {
    const dir = path.join(evalsDir, e.name);
    const yml = path.join(dir, 'case.yaml');
    if (!fs.existsSync(yml)) continue;
    const text = fs.readFileSync(yml, 'utf8');
    const tags = text.match(/^tags: \[(.*)\]$/m)?.[1].split(',').map((t) => t.trim()) ?? [];
    if (!tags.includes('detect') && !tags.includes('control')) continue;
    const prompt = fs.readFileSync(path.join(dir, 'prompt.md'), 'utf8');
    const target = prompt.match(/^Review (\S+) before I merge it/)?.[1];
    if (!target) throw new Error(`${slug}/${e.name}: the prompt must start with "Review <path> before I merge it"`);
    // an indicator, not part of the score: did the plugin's skills fire on the natural prompt?
    fs.writeFileSync(path.join(dir, 'graders', 'skill-fired.md'), `---\ntype: tool_used\ntool: Skill\ninput_match: '"skill"\\s*:\\s*"${slug}:[\\w-]+"'\n---\n`);
    const control = tags.includes('control');
    const variant = path.join(evalsDir, `${e.name}--slash`);
    fs.cpSync(dir, variant, { recursive: true });
    fs.rmSync(path.join(variant, 'graders', 'skill-fired.md'), { force: true });
    fs.writeFileSync(path.join(variant, 'case.yaml'), text.replace(/^name: .*$/m, `name: ${e.name}--slash`).replace(/^tags: \[.*\]$/m, 'tags: [slash]'));
    fs.writeFileSync(path.join(variant, 'prompt.md'), `/${slug}:review ${target}\n`);
    const graders = path.join(variant, 'graders');
    const esc = (t) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    fs.writeFileSync(path.join(graders, 'slash-template.md'), `---\ntype: regex\npattern: '${esc(title)} review:${control ? '|No findings' : ''}'\n---\n`);
    if (!control) fs.writeFileSync(path.join(graders, 'slash-why-fix.md'), `---\ntype: regex\npattern: '${label}:[\\s\\S]*Fix:'\n---\n`);
  }
}

let worst = 0;
for (const slug of slugs) {
  const suite = path.join(ROOT, 'evals', slug);
  if (!fs.existsSync(suite)) { console.error(`no suite for ${slug}: ${path.relative(ROOT, suite)} is missing`); worst = Math.max(worst, 2); continue; }
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), `guided-eval-${slug}-`));
  const target = path.join(tmp, slug);
  fs.cpSync(path.join(ROOT, 'plugins', slug), target, { recursive: true });
  fs.cpSync(suite, path.join(target, 'evals'), { recursive: true });
  addSlashVariants(slug, path.join(target, 'evals'), target);
  const summary = { plugin: slug, date: new Date().toISOString().slice(0, 10), passes: [] };
  for (const pass of PASSES) {
    const tags = pass.tags;
    const out = path.join(resultsDir, `${slug}.${pass.id}.json`);
    const args = ['plugin', 'eval', target, '--scaffold', '--trust-plugin', '--no-publish', '--ablation', pass.ablation, '--json', out,
      '--output-dir', path.join(tmp, `out-${pass.id}`)];
    for (const t of tags) args.push('--tag', t);
    if (one('runs')) args.push('--runs', one('runs')); else args.push('--runs', '1');
    for (const k of ['max-cost-usd', 'concurrency', 'threshold', 'case', 'model', 'judge-model']) if (one(k)) args.push(`--${k}`, one(k));
    if (flags['keep-temp']) args.push('--keep-temp');
    console.error(`\n== ${slug} (${pass.id}: ${pass.ablation}, tags ${tags.join(',')}) ==`);
    const r = spawnSync('claude', args, { stdio: ['ignore', 'inherit', 'inherit'], cwd: tmp });
    worst = Math.max(worst, r.status === null ? 1 : (r.status === 0 ? 0 : (r.status === 1 ? 1 : 2)));
    if (!fs.existsSync(out)) { summary.passes.push({ id: pass.id, error: `no result file (exit ${r.status})` }); continue; }
    const res = JSON.parse(fs.readFileSync(out, 'utf8'));
    // runs that errored score 0 and would read as "the plugin is useless": never record them as results
    const errors = failedRunErrors(res);
    if (errors.length) {
      summary.passes.push({ id: pass.id, error: `${errors.length} run(s) failed: ${errors[0].slice(0, 200)}` });
      console.error(`\n!! ${slug} (${pass.id}): ${errors.length} run(s) failed, first error: ${errors[0].slice(0, 200)}`);
      if (/limit/i.test(errors[0])) { console.error('A usage limit was hit; stopping. Nothing was recorded for this plugin. Run it again after the limit resets.'); process.exit(3); }
      continue;
    }
    summary.passes.push(compact(pass.id, pass.ablation, res, one('model') ?? 'default of the Claude Code session', Number(one('runs') ?? '1')));
  }
  if (summary.passes.some((p) => p.error)) { worst = Math.max(worst, 2); console.error(`${slug}: not recorded (a pass had failing runs); the previous summary, if any, is kept`); }
  else fs.writeFileSync(path.join(summaryDir, `${slug}.json`), `${JSON.stringify(summary, null, 2)}\n`);
  if (!flags['keep-temp']) fs.rmSync(tmp, { recursive: true, force: true }); else console.error(`kept ${tmp}`);
}
process.exit(worst);
