#!/usr/bin/env node
// Exercises the review plumbing end to end with stand-ins for `claude` and `gh` (tests/fakes): the findings converters, the CI runner, the
// project settings it applies, the pre-push hook and the pull request poster. No network, no model. Exit code 1 on any failed expectation.
//   node scripts/selftest-ci.mjs
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ROOT } from './lib.mjs';
import { SCHEMA, addedLines, fingerprint, normalize, toGithubReview, toMarkdown, toSarif, validate } from './findings-lib.mjs';
import { isIgnored, validateConfig } from './guided-config-lib.mjs';

let failures = 0;
const check = (ok, what) => { if (!ok) { failures++; console.log(`FAIL ${what}`); } else console.log(`ok   ${what}`); };
const FAKES = path.join(ROOT, 'tests', 'fakes');
const FIXTURE = path.join(ROOT, 'tests', 'findings', 'report.json');
const report = JSON.parse(fs.readFileSync(FIXTURE, 'utf8'));
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'guided-selftest-'));
const sh = (cmd, args, opts = {}) => spawnSync(cmd, args, { encoding: 'utf8', ...opts, env: { ...process.env, GIT_AUTHOR_NAME: 't', GIT_AUTHOR_EMAIL: 't@t', GIT_COMMITTER_NAME: 't', GIT_COMMITTER_EMAIL: 't@t', GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1', ...(opts.env ?? {}) } }); // hermetic: the developer's own git config must not change the result

// ---------------------------------------------------------------- the schema and the converters
check(validate(report, SCHEMA).length === 0, 'the sample report satisfies docs/findings.schema.json');
check(validate({ ...report, findings: [{ severity: 'huge', path: 'a', rule: 'r', why: 'w', fix: 'f' }] }).length > 0, 'an unknown severity is rejected');
check(validate({ schemaVersion: 1, tool: 'x', scope: 's', summary: 's' }).some((e) => e.includes('findings')), 'a report without findings is rejected');
const norm = normalize(report);
check(norm.findings[0].severity === 'blocker' && norm.findings.at(-1).severity === 'nit', 'findings are sorted blocker first');
const sarif = toSarif(norm);
check(sarif.version === '2.1.0' && sarif.runs[0].results.length === 4 && sarif.runs[0].tool.driver.rules.length === 4, 'SARIF has a result and a rule per finding');
check(sarif.runs[0].results.every((r) => r.locations[0].physicalLocation.region.startLine >= 1 && r.partialFingerprints['guidedFinding/v1']), 'every SARIF result has a start line and a fingerprint');
check(sarif.runs[0].results.find((r) => r.ruleId.includes('swallowed')).level === 'error' && sarif.runs[0].results.find((r) => r.ruleId.includes('narrating')).level === 'note', 'SARIF levels follow severity');
check(fingerprint(norm.findings[0]) === fingerprint({ ...norm.findings[0], line: 99 }), 'a fingerprint survives a line shift');
const diff = fs.readFileSync(path.join(ROOT, 'tests', 'findings', 'pr.diff'), 'utf8');
const lines = addedLines(diff);
check(lines.get('src/order-manager.ts').has(6) && !lines.get('src/order-manager.ts').has(31) && lines.get('src/a.ts').has(12), 'added line numbers come from the diff hunks');
const gh = toGithubReview(norm, diff);
check(gh.comments.length === 2 && gh.comments.every((c) => c.side === 'RIGHT' && c.body.includes('guided-plugins:')) && gh.body.includes('Not on a changed line'), 'findings on changed lines become inline comments, the rest go in the body');
check(toMarkdown(norm).includes('## Guided review: 4 findings') && toMarkdown({ ...norm, findings: [] }).includes('No findings.'), 'the Markdown summary counts findings');

// fingerprints depend on the book, rule, path and the text of the cited line, not on the model's wording or the line number
const base1 = { severity: 'major', path: 'a.ts', line: 10, rule: 'Boolean flag parameter', book: 'clean-code', why: 'first wording', fix: 'x', anchor: 'function f(a, flag) {' };
check(fingerprint(base1) === fingerprint({ ...base1, line: 42, why: 'a completely different explanation', fix: 'y' }), 'a fingerprint survives a shifted line and different wording');
check(fingerprint(base1) !== fingerprint({ ...base1, anchor: 'function g(a, flag) {' }) && fingerprint(base1) !== fingerprint({ ...base1, rule: 'Magic number' }), 'a different line text or rule is a different finding');
const spaced = addedLines(['diff --git a/dir with space/my file.ts b/dir with space/my file.ts', '--- a/dir with space/my file.ts\t', '+++ b/dir with space/my file.ts\t', '@@ -1,0 +2,1 @@', '+const x = 1;', 'diff --git a/c.c b/c.c', '--- a/c.c', '+++ b/c.c', '@@ -4,0 +5,3 @@', '+++i;', '+--j;', '+k();'].join('\n'));
check(spaced.get('dir with space/my file.ts')?.has(2) && [5, 6, 7].every((n) => spaced.get('c.c')?.has(n)), 'added lines: names with spaces, and added lines that start with ++ or --');
check(toMarkdown({ ...norm, disagreements: [{ path: 'a.ts', line: 3, primary: 'clean-code', secondary: 'refactoring', primaryRule: 'split it', secondaryRule: 'keep it', resolution: 'the primary book decides: split it' }] }).includes('clean-code: split it; refactoring: keep it'), 'disagreements show what each book says');
check(validate({ ...report, disagreements: [{ path: 'a', primary: 'x', secondary: 'y', resolution: 'z', primaryRule: 'p', secondaryRule: 'q' }] }, SCHEMA).length === 0, 'the schema accepts the disagreement fields the combined review writes');
// the ignore matcher
check(isIgnored('vendor/a.js', ['vendor/']) && isIgnored('x/vendor/a.js', ['vendor/']) && isIgnored('a/b.min.js', ['*.min.js']) && isIgnored('vendor/a.js', ['/vendor/']) && !isIgnored('x/vendor/a.js', ['/vendor/']) && !isIgnored('src/a.js', ['vendor/']), 'ignore globs: any-depth names, folders, leading-slash anchoring');
check(validateConfig({ primary: 'clean-code', ignore: ['!keep.js', 'a[0-9].js'] }).problems.length === 2, 'ignore patterns that the matcher does not support are rejected, not silently ignored');

// ---------------------------------------------------------------- a repository to review
const repo = path.join(tmp, 'repo');
fs.mkdirSync(path.join(repo, 'src'), { recursive: true });
const g = (...a) => sh('git', a, { cwd: repo });
g('init', '-q', '-b', 'main');
fs.writeFileSync(path.join(repo, 'src', 'order-manager.ts'), 'export {}\n');
fs.writeFileSync(path.join(repo, 'src', 'a.ts'), 'const d = 1;\n');
g('add', '.'); g('commit', '-q', '-m', 'init');
g('checkout', '-q', '-b', 'feature');
fs.writeFileSync(path.join(repo, 'src', 'order-manager.ts'), `${'// line\n'.repeat(5)}export class OrderManager {}\n`);
fs.writeFileSync(path.join(repo, 'src', 'a.ts'), 'const d = 2;\n');
g('commit', '-q', '-am', 'change');
const RUNNER = path.join(ROOT, 'scripts', 'guided-review-ci.mjs');
const run = (extra, env = {}, cwd = repo) => sh('node', [RUNNER, '--claude', path.join(FAKES, 'claude'), ...extra], { cwd, env: { FAKE_CLAUDE_LOG: path.join(tmp, 'claude.log'), ...env } });
const config = (obj) => fs.writeFileSync(path.join(repo, '.guided-plugins.json'), JSON.stringify(obj));
const out = () => JSON.parse(fs.readFileSync(path.join(repo, '.guided-review', 'report.json'), 'utf8'));

config({ version: 1, primary: 'clean-code', failOn: 'major' });
let r = run(['--base', 'main']);
check(r.status === 1 && out().findings.length === 3, 'a blocker fails the gate (exit 1); the default strictness leaves the nit out');
for (const f of ['report.json', 'report.sarif', 'summary.md', 'review.json', 'diff.patch', 'claude.json']) check(fs.existsSync(path.join(repo, '.guided-review', f)), `${f} is written`);
check(JSON.parse(fs.readFileSync(path.join(repo, '.guided-review', 'review.json'), 'utf8')).comments.length >= 1, 'review.json carries inline comments');
const logged = fs.readFileSync(path.join(tmp, 'claude.log'), 'utf8').trim().split('\n').map((l) => JSON.parse(l)).at(-1);
check(logged[0] === '-p' && logged[1] === '/clean-code:review main...HEAD --json' && logged.includes('--json-schema') && logged.includes('--max-budget-usd'), 'one book runs that book\'s review with --json and a schema and a budget');
check(!JSON.parse(logged[logged.indexOf('--json-schema') + 1]).$schema, 'the schema given to claude has no "$schema" keyword (claude rejects the 2020-12 URI)');
check(!logged.join(' ').includes('Write') && !logged.join(' ').includes('Edit'), 'the review is allowed no write tool');

r = run(['--base', 'main', '--fail-on', 'never']); check(r.status === 0, '--fail-on never reports without failing');
r = run(['--base', 'main', '--fail-on', 'blocker']); check(r.status === 1, 'a blocker fails --fail-on blocker');
config({ version: 1, primary: 'clean-code', failOn: 'major', ignore: ['src/order-manager.ts'] });
r = run(['--base', 'main']); check(r.status === 0 && out().findings.every((f) => f.path !== 'src/order-manager.ts') && out().skippedByConfig >= 2, 'the ignore list removes findings and the file from the review');
config({ version: 1, primary: 'clean-code', strictness: 'relaxed', failOn: 'never' });
r = run(['--base', 'main']); check(out().findings.every((f) => ['blocker', 'major'].includes(f.severity)) && out().findings.length === 2, 'strictness relaxed keeps blockers and majors');
config({ version: 1, primary: 'clean-code', strictness: 'strict', maxFindings: 2, failOn: 'never' });
r = run(['--base', 'main']); check(out().findings.length === 2 && out().truncated === 2, 'maxFindings truncates and says how many');
config({ version: 1, primary: 'clean-code', secondary: ['refactoring'], failOn: 'never' });
r = run(['--base', 'main']);
check(fs.readFileSync(path.join(tmp, 'claude.log'), 'utf8').trim().split('\n').at(-1).includes('/guided:review main...HEAD --json'), 'two books run the combined /guided:review');
config({ version: 1, primary: 'clean-code', failOn: 'major', surprise: true });
r = run(['--base', 'main']); check(r.status === 2 && r.stderr.includes('unknown setting'), 'an invalid settings file stops the run (exit 2)');
config({ version: 1, primary: 'clean-code', failOn: 'major' });
for (const [mode, label] of [['error', 'a budget error'], ['nostructure', 'no structured output'], ['invalid', 'an invalid report'], ['text', 'text instead of JSON']]) {
  r = run(['--base', 'main'], { FAKE_CLAUDE_MODE: mode }); check(r.status === 2, `${label} exits 2, not 0`);
}
r = run(['--base', 'main'], { FAKE_CLAUDE_MODE: 'result-only', FAKE_CLAUDE_REPORT: FIXTURE }); check(r.status === 1, 'a report in the result text is accepted');
r = run(['--base', 'main', '--dry']); check(r.status === 0 && r.stdout.includes('/clean-code:review') && !fs.readFileSync(path.join(tmp, 'claude.log'), 'utf8').includes('"--dry"'), '--dry prints the command and runs nothing');
r = run(['--base', '--json']); check(r.status === 2, 'a flag-looking ref is refused');
r = run(['--base', 'main; rm -rf /']); check(r.status === 2 && r.stderr.includes('not a plain git ref'), 'a ref with shell characters is refused');
r = run(['--base', 'no-such-branch']); check(r.status === 2 && r.stderr.includes('does not name a commit'), 'a ref that does not resolve is refused with a hint about fetch-depth');
r = run(['--base', 'feature']); check(r.status === 0 && out().summary.includes('No changes'), 'an empty diff passes without calling the model');
r = run(['--books', 'not-a-book', '--base', 'main']); check(r.status === 2 && r.stderr.includes('unknown book'), 'an unknown book is a usage error');

// the diff must be read independently of the user's git configuration and of unusual file names
g('checkout', '-q', '-b', 'unicode', 'main');
fs.writeFileSync(path.join(repo, 'src', 'caf\u00e9.ts'), 'export const a = 1;\n'); g('add', 'src'); g('commit', '-q', '-m', 'unicode name'); // only this file: the branch must change nothing else
config({ version: 1, primary: 'clean-code', failOn: 'major' });
r = run(['--base', 'main']); check(r.status === 1 && out().findings.length >= 1, 'a branch that only adds a non-ASCII file name is reviewed, not reported as "no changes"');
g('config', 'diff.noprefix', 'true'); r = run(['--base', 'main']); check(r.status === 1, 'diff.noprefix in the user\'s git config does not hide the changes'); g('config', '--unset', 'diff.noprefix');
g('config', 'diff.mnemonicPrefix', 'true'); r = run(['--staged']); g('config', '--unset', 'diff.mnemonicPrefix'); check(r.status === 0 || r.status === 1, 'diff.mnemonicPrefix does not break the staged review');
g('config', 'color.diff', 'always'); r = run(['--base', 'main']); g('config', '--unset', 'color.diff'); check(r.status === 1, 'color.diff=always does not hide the changes');
g('checkout', '-q', 'feature');
config({ version: 1, failOn: 'major' });
r = run(['--books', 'clean-code,refactoring', '--base', 'main']);
check(fs.readFileSync(path.join(tmp, 'claude.log'), 'utf8').trim().split('\n').at(-1).includes('/guided:review main...HEAD --json --books clean-code,refactoring'), 'a --books override reaches /guided:review');
r = run(['--dry-run', '--books', 'clean-code', '--base', 'main']); check(r.status === 2 && r.stderr.includes('unknown option'), 'an unknown flag is refused instead of starting a paid review');
fs.mkdirSync(path.join(repo, 'sub'), { recursive: true });
r = sh('node', [RUNNER, '--claude', path.join(FAKES, 'claude'), '--books', 'clean-code', '--base', 'main', '--out', 'results-here'], { cwd: path.join(repo, 'sub'), env: { FAKE_CLAUDE_LOG: path.join(tmp, 'claude.log') } });
check(fs.existsSync(path.join(repo, 'sub', 'results-here', 'report.json')), 'a relative --out is relative to where the command was run');
const outside = path.join(tmp, 'outside.json'); fs.writeFileSync(outside, JSON.stringify({ schemaVersion: 1, tool: 'clean-code', scope: 'x', findings: [{ severity: 'blocker', path: '../../etc/passwd', line: 1, rule: 'r', why: 'w', fix: 'f' }, { severity: 'major', path: 'src/a.ts', line: 1, rule: 'r', why: 'w', fix: 'f' }], summary: 's' }));
config({ version: 1, primary: 'clean-code', failOn: 'major' });
r = run(['--base', 'main'], { FAKE_CLAUDE_REPORT: outside }); check(out().findings.length === 1 && out().findings[0].anchor === fs.readFileSync(path.join(repo, 'src', 'a.ts'), 'utf8').split('\n')[0].trim() && out().notChecked.some((x) => x.includes('outside the repository')), 'a finding outside the repository is dropped; the line text of a finding is recorded as its anchor');

// ---------------------------------------------------------------- the pre-push hook
const bare = path.join(tmp, 'remote.git'); sh('git', ['init', '-q', '--bare', '-b', 'main', bare]);
g('remote', 'add', 'origin', bare); g('push', '-q', 'origin', 'main'); g('config', 'core.hooksPath', '.git/hooks');
let inst = sh('node', [path.join(ROOT, 'scripts', 'install-git-hook.mjs')], { cwd: repo });
check(inst.status === 0 && fs.existsSync(path.join(repo, '.git', 'hooks', 'pre-push')), 'the hook installer writes pre-push');
fs.mkdirSync(path.join(tmp, 'bin'), { recursive: true });
try { fs.symlinkSync(path.join(FAKES, 'claude'), path.join(tmp, 'bin', 'claude')); } catch { /* exists */ }
const pushEnv = (extra = {}) => ({ PATH: `${path.join(tmp, 'bin')}:${process.env.PATH}`, ...extra });
config({ version: 1, primary: 'clean-code', failOn: 'major' });
r = sh('git', ['push', 'origin', 'feature'], { cwd: repo, env: pushEnv() });
check(r.status !== 0 && r.stderr.includes('push blocked'), 'a blocker blocks the push');
r = sh('git', ['push', 'origin', 'feature'], { cwd: repo, env: pushEnv({ GUIDED_SKIP: '1' }) });
check(r.status === 0, 'GUIDED_SKIP=1 lets the push through');
g('checkout', '-q', '-b', 'feature2');
fs.writeFileSync(path.join(repo, 'src', 'a.ts'), 'const d = 3;\n'); g('commit', '-q', '-am', 'more');
r = sh('git', ['push', 'origin', 'feature2'], { cwd: repo, env: pushEnv({ FAKE_CLAUDE_MODE: 'error' }) });
check(r.status === 0 && r.stderr.includes('could not run'), 'when the review cannot run, the push goes through with a warning');
const clean = path.join(tmp, 'clean.json'); fs.writeFileSync(clean, JSON.stringify({ schemaVersion: 1, tool: 'clean-code', scope: 'x', findings: [], summary: 'Nothing to report.' }));
g('checkout', '-q', '-b', 'feature3'); fs.writeFileSync(path.join(repo, 'src', 'a.ts'), 'const d = 4;\n'); g('commit', '-q', '-am', 'again');
r = sh('git', ['push', 'origin', 'feature3'], { cwd: repo, env: pushEnv({ FAKE_CLAUDE_REPORT: clean }) });
check(r.status === 0, 'a clean review lets the push through');
g('checkout', '-q', '-b', 'feature4'); fs.writeFileSync(path.join(repo, 'src', 'a.ts'), 'const d = 5;\n'); g('commit', '-q', '-am', 'typo');
r = sh('git', ['push', 'origin', 'feature4'], { cwd: repo, env: pushEnv({ GUIDED_FAIL_ON: 'banana' }) });
check(r.status !== 0 && r.stderr.includes('using blocker'), 'a mistyped GUIDED_FAIL_ON falls back to blocker instead of disabling the hook');
inst = sh('node', [path.join(ROOT, 'scripts', 'install-git-hook.mjs'), '--uninstall'], { cwd: repo });
fs.mkdirSync(path.join(repo, 'src', 'deep'), { recursive: true });
inst = sh('node', [path.join(ROOT, 'scripts', 'install-git-hook.mjs')], { cwd: path.join(repo, 'src', 'deep') });
check(inst.status === 0 && fs.existsSync(path.join(repo, '.git', 'hooks', 'pre-push')) && !fs.existsSync(path.join(repo, 'src', '.git')), 'the hook installer run from a subfolder writes into the repository\'s hooks folder');
inst = sh('node', [path.join(ROOT, 'scripts', 'install-git-hook.mjs'), '--uninstall'], { cwd: repo });
check(inst.status === 0 && !fs.existsSync(path.join(repo, '.git', 'hooks', 'pre-push')), 'the hook uninstalls');
fs.writeFileSync(path.join(repo, '.git', 'hooks', 'pre-push'), '#!/bin/sh\necho mine\n');
check(sh('node', [path.join(ROOT, 'scripts', 'install-git-hook.mjs')], { cwd: repo }).status === 2 && fs.readFileSync(path.join(repo, '.git', 'hooks', 'pre-push'), 'utf8').includes('mine'), 'the installer does not overwrite someone else\'s hook');

// ---------------------------------------------------------------- posting to a pull request
const POST = path.join(ROOT, 'scripts', 'github-post-review.mjs');
const posted = path.join(tmp, 'posted.json');
const review = toGithubReview(norm, diff); const reviewFile = path.join(tmp, 'review.json'); fs.writeFileSync(reviewFile, JSON.stringify(review));
const post = (env = {}) => sh('node', [POST, '--gh', path.join(FAKES, 'gh'), '--repo', 'o/r', '--pr', '7', '--review', reviewFile, '--commit', 'abc123'], { env: { FAKE_GH_POSTED: posted, ...env } });
r = post(); const body = fs.existsSync(posted) ? JSON.parse(fs.readFileSync(posted, 'utf8')) : null;
check(r.status === 0 && body && body.comments.length === 2 && body.commit_id === 'abc123' && body.event === 'COMMENT', 'the first run posts one review with the inline comments');
fs.rmSync(posted);
const markers = review.comments.map((c) => ({ body: c.body }));
r = post({ FAKE_GH_COMMENTS: JSON.stringify(markers), FAKE_GH_REVIEWS: JSON.stringify([{ body: `${review.body}\n\n<!-- guided-plugins:${(await import('node:crypto')).createHash('sha256').update(review.body).digest('hex').slice(0, 16)} -->` }]) });
check(r.status === 0 && r.stdout.includes('nothing new') && !fs.existsSync(posted), 'a re-run with the same findings posts nothing');
r = post({ FAKE_GH_COMMENTS: JSON.stringify([markers[0]]) });
check(r.status === 0 && JSON.parse(fs.readFileSync(posted, 'utf8')).comments.length === 1, 'only comments not posted before are posted');
const reworded = { ...review, head: `${review.head} and now a different summary sentence`, body: `${review.body} different` };
fs.writeFileSync(reviewFile, JSON.stringify(reworded));
const postedMarkers = [...review.comments.map((c) => ({ body: c.body })), { body: review.rest.map((x) => x.text).join('\n') }];
fs.rmSync(posted, { force: true });
r = post({ FAKE_GH_COMMENTS: JSON.stringify(postedMarkers) });
check(r.status === 0 && r.stdout.includes('nothing new') && !fs.existsSync(posted), 'a re-run whose summary was reworded posts nothing when every finding was posted before');
check(sh('node', [POST, '--repo', 'bad repo', '--pr', 'x', '--review', reviewFile]).status === 2, 'bad arguments are a usage error');

// ---------------------------------------------------------------- the GitHub Action: its shell steps, run against the same repository
const yq = sh('python3', ['-c', 'import sys, json, yaml; print(json.dumps(yaml.safe_load(open(sys.argv[1]))))', path.join(ROOT, '.github', 'actions', 'guided-review', 'action.yml')]);
if (yq.status !== 0 && process.env.CI) check(false, 'PyYAML is required in CI to test the Action');
else if (yq.status !== 0) console.log('skip the Action checks: python3 with PyYAML is not available');
else {
  const action = JSON.parse(yq.stdout);
  const step = (name) => action.runs.steps.find((x) => x.name === name);
  const ifs = action.runs.steps.map((x) => x.if ?? '').join('\n');
  check(!/hashFiles\([^)]*runner\.temp/.test(ifs), 'no step condition uses hashFiles() on a file under runner.temp (hashFiles ignores files outside the workspace)');
  check(/has_sarif/.test(ifs) && /has_review/.test(ifs), 'the SARIF and review steps are gated on outputs of the Review step');
  check(action.inputs.marketplace.default === '' && /^\d+\.\d+\.\d+$/.test(action.inputs['claude-code-version'].default), 'the action installs the plugins from its own checkout and pins the Claude Code version');
  check(action.runs.using === 'composite' && ['anthropic-api-key', 'books', 'fail-on', 'max-budget-usd', 'post-review', 'upload-sarif'].every((k) => k in action.inputs), 'the action is a composite action with the documented inputs');
  const bash = (script, env, cwd = repo) => sh('bash', ['-c', script], { cwd, env: { RUNNER_TEMP: tmp, ...env } });
  const outFile = path.join(tmp, 'gh-output'); const summaryFile = path.join(tmp, 'gh-summary');
  const ghEnv = { GITHUB_OUTPUT: outFile, GITHUB_STEP_SUMMARY: summaryFile };
  fs.writeFileSync(outFile, ''); fs.writeFileSync(summaryFile, '');
  bash(step('Check for an API key').run, { ...ghEnv, KEY: '' });
  check(fs.readFileSync(outFile, 'utf8').includes('present=false'), 'without an API key the action reports it and skips');
  fs.writeFileSync(outFile, '');
  const reviewEnv = { ...ghEnv, BOOKS: '', BASE: 'main', FAIL_ON: '', BUDGET: '1', MODEL: '', PR_BASE: '', ACTION_ROOT: ROOT, ANTHROPIC_API_KEY: 'x', PATH: `${path.join(tmp, 'bin')}:${process.env.PATH}` };
  config({ version: 1, primary: 'clean-code', failOn: 'major' });
  r = bash(step('Review').run, reviewEnv);
  const o = fs.readFileSync(outFile, 'utf8');
  check(r.status === 0 && /gate=fail/.test(o) && /findings=3/.test(o) && /exit=1/.test(o), 'the Review step records gate=fail, the finding count and the exit code, and does not stop the job itself');
  check(/has_sarif=true/.test(o) && /has_review=true/.test(o), 'the Review step reports that the SARIF file and the review exist');
  fs.writeFileSync(outFile, ''); bash(step('Check for an API key').run, { ...ghEnv, KEY: 'sk-test' });
  check(fs.readFileSync(outFile, 'utf8').includes('present=true'), 'with an API key the action goes on');
  fs.writeFileSync(outFile, o);
  check(fs.readFileSync(summaryFile, 'utf8').includes('## Guided review: 3 findings') && fs.existsSync(path.join(tmp, 'guided-review', 'report.sarif')), 'the Review step writes the job summary and the SARIF file');
  check(bash(step('Gate').run, { CODE: '1' }).status === 1 && bash(step('Gate').run, { CODE: '0' }).status === 0 && bash(step('Gate').run, { CODE: '2' }).status === 1, 'the Gate step fails on exit 1 and 2 and passes on 0');
  fs.writeFileSync(outFile, '');
  r = bash(step('Review').run, { ...reviewEnv, FAKE_CLAUDE_REPORT: clean });
  check(/gate=pass/.test(fs.readFileSync(outFile, 'utf8')), 'a clean review gives gate=pass');
  r = sh('node', [RUNNER, '--print-books'], { cwd: repo });
  check(r.stdout.trim() === 'clean-code', 'the install step asks the runner which plugins to install');
}

fs.rmSync(tmp, { recursive: true, force: true });
console.log(failures ? `\n${failures} FAILED` : '\nall passed');
process.exit(failures ? 1 : 0);
