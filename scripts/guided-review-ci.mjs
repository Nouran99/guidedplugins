#!/usr/bin/env node
// Runs a Guided Plugins review headlessly (a pull request check, a pre-push hook, a script) and writes machine-readable results.
//   node scripts/guided-review-ci.mjs --base origin/main                     # review origin/main...HEAD with the books from .guided-plugins.json
//   node scripts/guided-review-ci.mjs --books clean-code --fail-on blocker   # one book, fail only on blockers
//   node scripts/guided-review-ci.mjs --staged                               # the staged changes
//   node scripts/guided-review-ci.mjs --dry                                  # print the command and the prompt, run nothing
//   node scripts/guided-review-ci.mjs --print-books                          # the plugins to install for this configuration
// Needs Claude Code (`claude`) signed in or with ANTHROPIC_API_KEY, and the book plugins installed (the GitHub Action installs them).
// The diff is sent to the Anthropic API as part of the review.
// Outputs, in --out (default .guided-review/): report.json (the findings), claude.json (the raw result), report.sarif, summary.md,
// review.json (the body of a GitHub pull request review) and diff.patch. Exit code: 0 pass, 1 findings at or above the gate, 2 the review
// could not run or returned something that is not a findings report.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { gate, normalize, toGithubReview, toMarkdown, toSarif, validate, SCHEMA } from './findings-lib.mjs';
import { CONFIG_FILE, FAIL_ON, SLUGS, isIgnored, loadConfig } from './guided-config-lib.mjs';

const argv = process.argv.slice(2);
const VALUE = new Set(['base', 'head', 'books', 'claude', 'model', 'max-budget-usd', 'fail-on', 'out', 'plugin-dir', 'max-turns']);
const BOOL = new Set(['staged', 'dry', 'print-books']);
const opt = {}; const bools = new Set();
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (!a.startsWith('--')) { console.error(`unexpected argument ${a}`); process.exit(2); }
  const k = a.slice(2);
  if (VALUE.has(k)) { if (argv[i + 1] === undefined) { console.error(`--${k} needs a value`); process.exit(2); } (opt[k] ??= []).push(argv[++i]); }
  else if (BOOL.has(k)) bools.add(k);
  else { console.error(`unknown option --${k} (a typo such as --dry-run would otherwise start a paid review)`); process.exit(2); }
}
const startCwd = process.cwd(); // relative paths on the command line mean "relative to where you ran this", not to the repository root
const one = (k) => opt[k]?.[0];
const git = (...args) => spawnSync('git', args, { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 });
const top = git('rev-parse', '--show-toplevel');
if (top.status !== 0) { console.error('run this inside a git repository'); process.exit(2); }
const root = top.stdout.trim();
process.chdir(root);

// ---------------------------------------------------------------- settings
const { config, problems, notes } = loadConfig(root);
if (problems.length) { for (const p of problems) console.error(`${CONFIG_FILE}: ${p}`); process.exit(2); }
for (const n of notes) console.error(`note: ${n}`);
const books = one('books') ? one('books').split(',').map((s) => s.trim()).filter(Boolean) : [config.primary, ...config.secondary].filter(Boolean);
const unknownBooks = books.filter((b) => !SLUGS.includes(b));
if (unknownBooks.length) { console.error(`unknown book(s): ${unknownBooks.join(', ')}. books: ${SLUGS.join(', ')}`); process.exit(2); }
if (!books.length) { console.error(`no books: pass --books clean-code,refactoring or create ${CONFIG_FILE} (node scripts/guided-config.mjs init --preset everyday-code)`); process.exit(2); }
// the plugins to install: the books, plus the combined-review plugin when there are several
if (bools.has('print-books')) { console.log([...books, ...(books.length > 1 ? ['guided'] : [])].join(' ')); process.exit(0); }
const failOn = one('fail-on') ?? config.failOn;
if (!FAIL_ON.includes(failOn)) { console.error(`--fail-on must be one of ${FAIL_ON.join(', ')}`); process.exit(2); }
const budget = one('max-budget-usd') ?? '2';
const outDir = path.resolve(startCwd, one('out') ?? '.guided-review');

// ---------------------------------------------------------------- what to review
// refs end up in the prompt and in git commands: allow ordinary ref syntax only, and require that they resolve
const REF = /^[\w./@^~+-]+$/;
for (const k of ['base', 'head']) {
  const v = one(k);
  if (v === undefined) continue;
  if (!REF.test(v) || v.startsWith('-')) { console.error(`--${k} "${v}" is not a plain git ref`); process.exit(2); }
  if (git('rev-parse', '--verify', '--quiet', `${v}^{commit}`).status !== 0) { console.error(`--${k} "${v}" does not name a commit in this repository (a pull request check needs fetch-depth: 0)`); process.exit(2); }
}
// git's output format depends on the user's configuration (quoted non-ASCII names, diff.noprefix, diff.mnemonicPrefix, color.diff, external
// diff and textconv drivers): pin every setting that the parsing of the patch relies on, and take the file list from NUL-separated names.
const GIT_DIFF = ['-c', 'core.quotepath=off', '-c', 'color.ui=false', 'diff', '--no-color', '--no-ext-diff', '--no-textconv', '--src-prefix=a/', '--dst-prefix=b/'];
let range; let rangeArgs;
if (bools.has('staged')) { range = '--staged'; rangeArgs = ['--staged']; }
else if (one('base')) { const head = one('head') ?? 'HEAD'; range = `${one('base')}...${head}`; rangeArgs = [range]; }
else { range = 'HEAD'; rangeArgs = ['HEAD']; }
const diff = git(...GIT_DIFF, '-U0', ...rangeArgs);
if (diff.status !== 0) { console.error(`git diff ${rangeArgs.join(' ')} failed: ${diff.stderr.trim()}`); process.exit(2); }
const names = git(...GIT_DIFF, '--name-only', '-z', ...rangeArgs);
if (names.status !== 0) { console.error(`git diff --name-only failed: ${names.stderr.trim()}`); process.exit(2); }
const changed = names.stdout.split('\0').filter(Boolean);
// a patch with content but no file names means the output was not what this script expects: fail loudly, never pass silently
if (diff.stdout.trim() && !changed.length) { console.error('git printed a diff but no file names; refusing to report "no changes"'); process.exit(2); }
const reviewable = changed.filter((f) => !isIgnored(f, config.ignore));
const skipped = changed.length - reviewable.length;

fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'diff.patch'), diff.stdout);

const empty = (why) => ({ schemaVersion: 1, tool: books.length > 1 ? 'guided' : books[0], books, scope: range, findings: [], summary: why, skippedByConfig: skipped });
if (!reviewable.length) {
  const report = normalize(empty(changed.length ? 'Every changed file is on the ignore list.' : 'No changes to review.'));
  finish(report, null);
}

// ---------------------------------------------------------------- the review
// claude validates --json-schema with draft-07 tooling and rejects the draft 2020-12 "$schema" URI, so the keyword is left out
const { $schema: _ignored, ...schemaForClaude } = SCHEMA;
const prompt = books.length > 1 ? `/guided:review ${range} --json --books ${books.join(',')}` : `/${books[0]}:review ${range} --json`;
const allowed = ['Read', 'Grep', 'Glob', 'Skill', 'Agent', 'Bash(git diff *)', 'Bash(git log *)', 'Bash(git show *)', 'Bash(git status *)', 'Bash(git blame *)', 'Bash(git ls-files *)'].join(',');
const args = ['-p', prompt, '--output-format', 'json', '--json-schema', JSON.stringify(schemaForClaude), '--allowedTools', allowed, '--max-budget-usd', budget];
if (one('model')) args.push('--model', one('model'));
if (one('max-turns')) args.push('--max-turns', one('max-turns'));
for (const d of opt['plugin-dir'] ?? []) args.push('--plugin-dir', path.resolve(startCwd, d));
const claudeArg = one('claude') ?? process.env.GUIDED_CLAUDE ?? 'claude';
const claude = claudeArg.includes('/') ? path.resolve(startCwd, claudeArg) : claudeArg;

if (bools.has('dry')) {
  console.log(`books: ${books.join(', ')}   gate: ${failOn}   budget: $${budget}\nreviewing ${reviewable.length} file(s)${skipped ? `, ${skipped} skipped by ${CONFIG_FILE}` : ''}\n${claude} ${args.map((a) => (/[\s{"]/.test(a) ? JSON.stringify(a.length > 80 ? `${a.slice(0, 77)}...` : a) : a)).join(' ')}`);
  process.exit(0);
}

const run = spawnSync(claude, args, { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, input: '', env: { ...process.env, CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: '1' } });
if (run.error) { console.error(`could not run ${claude}: ${run.error.message}. Install Claude Code (npm install -g @anthropic-ai/claude-code).`); process.exit(2); }
fs.writeFileSync(path.join(outDir, 'claude.json'), run.stdout || '');
let result;
try { result = JSON.parse(run.stdout); } catch { console.error(`claude printed no JSON (exit ${run.status}).\n${(run.stderr || run.stdout || '').slice(0, 800)}`); process.exit(2); }
if (result.is_error || result.subtype !== 'success') { console.error(`the review did not finish: ${result.subtype ?? 'error'}${result.result ? ` - ${String(result.result).slice(0, 400)}` : ''}`); process.exit(2); }
let raw = result.structured_output;
if (!raw && typeof result.result === 'string') { try { raw = JSON.parse(result.result); } catch { /* handled below */ } }
if (!raw) { console.error('the review returned no structured findings. The plugin may not be installed, or the book review does not support --json yet.'); process.exit(2); }
const bad = validate(raw, SCHEMA);
if (bad.length) { console.error(`the review is not a valid findings report:\n  ${bad.slice(0, 8).join('\n  ')}`); process.exit(2); }
const report = normalize(raw);
report.books = report.books?.length ? report.books : books;
report.scope = range;

// a finding must point inside the repository; the text of its line (the anchor) keeps its fingerprint stable when the line number moves
const inside = (rel) => { const abs = path.resolve(root, rel); return abs === root || abs.startsWith(root + path.sep) ? abs : null; };
const outside = report.findings.filter((f) => !inside(f.path)).length;
report.findings = report.findings.filter((f) => inside(f.path));
if (outside) report.notChecked = [...(report.notChecked ?? []), `${outside} finding(s) named a path outside the repository and were dropped`];
const fileLines = new Map();
for (const f of report.findings) {
  if (!f.line) continue;
  const abs = inside(f.path);
  if (!fileLines.has(abs)) { try { fileLines.set(abs, fs.readFileSync(abs, 'utf8').split('\n')); } catch { fileLines.set(abs, null); } }
  const text = fileLines.get(abs)?.[f.line - 1];
  if (typeof text === 'string' && text.trim()) f.anchor = text.trim().slice(0, 200);
}

// settings that the model may have missed are applied again here
const before = report.findings.length;
report.findings = report.findings.filter((f) => !isIgnored(f.path, config.ignore));
report.skippedByConfig = Math.max(report.skippedByConfig ?? 0, skipped) + (before - report.findings.length); // the model and the runner both count the ignored files: do not add them
const rank = { blocker: 3, major: 2, minor: 1, nit: 0 };
const floor = { relaxed: 2, normal: 1, strict: 0 }[config.strictness];
report.findings = report.findings.filter((f) => rank[f.severity] >= floor);
if (report.findings.length > config.maxFindings) { report.truncated = (report.truncated ?? 0) + report.findings.length - config.maxFindings; report.findings = report.findings.slice(0, config.maxFindings); }
report.costUsd = result.total_cost_usd;
finish(report, result);

function finish(rep, res) {
  const failed = gate(rep, failOn);
  fs.writeFileSync(path.join(outDir, 'report.json'), `${JSON.stringify(rep, null, 2)}\n`);
  fs.writeFileSync(path.join(outDir, 'report.sarif'), `${JSON.stringify(toSarif(rep), null, 2)}\n`);
  fs.writeFileSync(path.join(outDir, 'summary.md'), toMarkdown(rep));
  fs.writeFileSync(path.join(outDir, 'review.json'), `${JSON.stringify(toGithubReview(rep, diff.stdout), null, 2)}\n`);
  process.stdout.write(toMarkdown(rep));
  if (res) console.error(`cost $${(res.total_cost_usd ?? 0).toFixed(3)}, ${res.num_turns ?? '?'} turns; results in ${path.relative(root, outDir) || '.'}/`);
  if (failed) console.error(`gate: failing because a finding is at ${failOn} or above`);
  process.exit(failed ? 1 : 0);
}
