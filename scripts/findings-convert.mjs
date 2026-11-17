#!/usr/bin/env node
// Converts a findings report (docs/findings.schema.json) to another format. Reads a file, or stdin with "-".
//   node scripts/findings-convert.mjs report.json --to validate
//   node scripts/findings-convert.mjs report.json --to sarif --out guided.sarif
//   node scripts/findings-convert.mjs report.json --to markdown >> "$GITHUB_STEP_SUMMARY"
//   node scripts/findings-convert.mjs report.json --to github-review --diff pr.diff --out review.json
//   node scripts/findings-convert.mjs claude-output.json --from-claude --to sarif    # the JSON printed by `claude -p --output-format json`
//   node scripts/findings-convert.mjs report.json --to gate --fail-on major          # exit 1 when a finding is at or above the level
import fs from 'node:fs';
import { SCHEMA, gate, normalize, toGithubReview, toMarkdown, toSarif, validate } from './findings-lib.mjs';

const args = process.argv.slice(2);
const opt = (k) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : undefined; };
const flag = (k) => args.includes(`--${k}`);
const input = args.find((a) => !a.startsWith('--') && a !== opt('to') && a !== opt('out') && a !== opt('diff') && a !== opt('fail-on'));
const to = opt('to');
if (!input || !['validate', 'sarif', 'markdown', 'github-review', 'gate'].includes(to)) {
  console.error('usage: findings-convert.mjs <report.json|-> --to validate|sarif|markdown|github-review|gate [--from-claude] [--diff file] [--fail-on blocker|major|minor|nit|never] [--out file]');
  process.exit(2);
}
let raw = JSON.parse(fs.readFileSync(input === '-' ? 0 : input, 'utf8'));
if (flag('from-claude')) {
  // `claude -p --output-format json --json-schema ...` puts the validated object in structured_output and its text in result
  raw = raw.structured_output ?? (typeof raw.result === 'string' ? JSON.parse(raw.result) : raw.result);
  if (!raw) { console.error('the claude output has neither structured_output nor a JSON result'); process.exit(2); }
}
const problems = validate(raw, SCHEMA);
if (problems.length) { console.error(`not a valid findings report:\n  ${problems.slice(0, 12).join('\n  ')}`); process.exit(2); }
const report = normalize(raw);
let out;
if (to === 'validate') out = `ok: ${report.findings.length} finding(s)\n`;
else if (to === 'sarif') out = `${JSON.stringify(toSarif(report), null, 2)}\n`;
else if (to === 'markdown') out = toMarkdown(report);
else if (to === 'github-review') out = `${JSON.stringify(toGithubReview(report, opt('diff') ? fs.readFileSync(opt('diff'), 'utf8') : null), null, 2)}\n`;
else if (to === 'gate') { const failed = gate(report, opt('fail-on') ?? 'major'); out = failed ? `fail: a finding at ${opt('fail-on') ?? 'major'} or above\n` : 'pass\n'; if (failed) { process.stderr.write(out); process.exit(1); } }
if (opt('out')) fs.writeFileSync(opt('out'), out); else process.stdout.write(out);
