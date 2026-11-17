// Findings (docs/findings.schema.json): validation, and conversion to SARIF, GitHub pull request review comments and Markdown.
// Zero dependencies. Used by scripts/findings-convert.mjs and scripts/guided-review-ci.mjs.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { REGISTRY, ROOT, VERSION } from './lib.mjs';

export const SCHEMA = JSON.parse(fs.readFileSync(path.join(ROOT, 'docs', 'findings.schema.json'), 'utf8'));
export const SEVERITIES = ['blocker', 'major', 'minor', 'nit'];
const RANK = { blocker: 3, major: 2, minor: 1, nit: 0 };

// ------------------------------------------------------------------ validation (the subset of JSON Schema that the findings schema uses)
export function validate(value, schema = SCHEMA, where = '$') {
  const errors = [];
  const type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : Number.isInteger(v) ? 'integer' : typeof v);
  const ok = (t, v) => (t === 'number' ? typeof v === 'number' : t === 'integer' ? Number.isInteger(v) : type(v) === t);
  if (schema.type && !ok(schema.type, value)) return [`${where}: expected ${schema.type}, got ${type(value)}`];
  if (schema.enum && !schema.enum.includes(value)) errors.push(`${where}: ${JSON.stringify(value)} is not one of ${schema.enum.join(', ')}`);
  if (schema.minimum !== undefined && typeof value === 'number' && value < schema.minimum) errors.push(`${where}: ${value} is below ${schema.minimum}`);
  if (schema.type === 'object') {
    for (const k of schema.required ?? []) if (!(k in value)) errors.push(`${where}: missing "${k}"`);
    for (const [k, sub] of Object.entries(schema.properties ?? {})) if (k in value) errors.push(...validate(value[k], sub, `${where}.${k}`));
  }
  if (schema.type === 'array' && schema.items) value.forEach((v, i) => errors.push(...validate(v, schema.items, `${where}[${i}]`)));
  return errors;
}

// Fills in what a reviewer may leave out and sorts the findings (blocker first, then by path and line).
export function normalize(report) {
  const out = { schemaVersion: 1, books: [], checked: [], notChecked: [], ...report };
  out.findings = (report.findings ?? []).map((f) => ({
    ...f,
    path: String(f.path).replace(/\\/g, '/').replace(/^\.\//, ''),
    book: f.book ?? (report.tool !== 'guided' ? report.tool : undefined),
  })).sort((a, b) => RANK[b.severity] - RANK[a.severity] || a.path.localeCompare(b.path) || (a.line ?? 0) - (b.line ?? 0));
  return out;
}

// A fingerprint says "this is the same finding as before". It must not depend on the model's wording or on the line number: it hashes the book,
// the rule, the path and the text of the cited line (the runner adds it as `anchor`); only a finding without a line falls back to its wording.
const squash = (t) => String(t).toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
export function fingerprint(f) {
  const anchor = f.anchor ? squash(f.anchor) : (f.line ? '' : squash(f.why));
  return crypto.createHash('sha256').update([f.book ?? '', squash(f.rule), f.path, anchor].join('|')).digest('hex').slice(0, 16);
}

// ------------------------------------------------------------------ gate
// failOn: blocker | major | minor | nit | never. Returns true when the report has a finding at or above that severity.
export function gate(report, failOn = 'major') {
  if (failOn === 'never') return false;
  if (!(failOn in RANK)) throw new Error(`failOn must be blocker, major, minor, nit or never (got ${failOn})`);
  return report.findings.some((f) => RANK[f.severity] >= RANK[failOn]);
}

// ------------------------------------------------------------------ SARIF 2.1.0 (GitHub code scanning)
const LEVEL = { blocker: 'error', major: 'warning', minor: 'note', nit: 'note' };
const slug = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 80) || 'finding';
export function toSarif(report) {
  const rules = new Map();
  const results = report.findings.map((f) => {
    const id = `${f.book ?? report.tool}/${slug(f.rule)}`;
    if (!rules.has(id)) rules.set(id, { id, name: f.rule, shortDescription: { text: f.rule }, properties: { book: f.book ?? report.tool } });
    return {
      ruleId: id,
      level: LEVEL[f.severity],
      message: { text: `${f.why} Fix: ${f.fix}` },
      locations: [{ physicalLocation: { artifactLocation: { uri: f.path, uriBaseId: '%SRCROOT%' }, region: { startLine: f.line ?? 1, ...(f.endLine ? { endLine: f.endLine } : {}) } } }],
      partialFingerprints: { 'guidedFinding/v1': fingerprint(f) },
      properties: { severity: f.severity, confidence: f.confidence ?? 'sure', fix: f.fix },
    };
  });
  const repo = `https://github.com/${REGISTRY.marketplace.githubRepo}`;
  return {
    $schema: 'https://json.schemastore.org/sarif-2.1.0.json',
    version: '2.1.0',
    runs: [{
      tool: { driver: { name: 'Guided Plugins', semanticVersion: VERSION, informationUri: repo, rules: [...rules.values()] } },
      results,
      invocations: [{ executionSuccessful: true }],
      properties: { scope: report.scope, books: report.books },
    }],
  };
}

// ------------------------------------------------------------------ Markdown
const ICON = { blocker: 'BLOCKER', major: 'MAJOR', minor: 'minor', nit: 'nit' };
export function toMarkdown(report, { max = 50 } = {}) {
  const lines = [];
  const counts = SEVERITIES.map((s) => [s, report.findings.filter((f) => f.severity === s).length]).filter(([, n]) => n);
  lines.push(`## Guided review: ${report.findings.length} finding${report.findings.length === 1 ? '' : 's'}${counts.length ? ` (${counts.map(([s, n]) => `${n} ${s}`).join(', ')})` : ''}`);
  lines.push('', `Scope: ${report.scope}${report.books?.length ? ` · books: ${report.books.join(', ')}` : ''}`, '');
  if (!report.findings.length) lines.push('No findings.', '');
  report.findings.slice(0, max).forEach((f) => {
    const loc = f.line ? `${f.path}:${f.line}` : f.path;
    lines.push(`- **${ICON[f.severity]}** \`${loc}\` ${f.rule}${f.book && f.book !== report.tool ? ` (${f.book})` : ''}${f.confidence === 'unsure' ? ' _(unsure)_' : ''}`, `  - Why: ${f.why}`, `  - Fix: ${f.fix}`);
  });
  if (report.findings.length > max) lines.push(`- … and ${report.findings.length - max} more`);
  if (report.disagreements?.length) {
    lines.push('', '### Where the books disagree', '');
    for (const d of report.disagreements) {
      const said = (book, rule) => (rule ? `${book}: ${rule}` : book);
      lines.push(`- \`${d.path}${d.line ? `:${d.line}` : ''}\` ${said(d.primary, d.primaryRule)}; ${said(d.secondary, d.secondaryRule)}. ${d.resolution}`);
    }
  }
  if (report.skippedByConfig) lines.push('', `${report.skippedByConfig} file(s) skipped by the ignore list in .guided-plugins.json.`);
  if (report.truncated) lines.push('', `${report.truncated} more finding(s) left out by maxFindings.`);
  lines.push('', report.summary ? `**Summary.** ${report.summary}` : '');
  if (report.doFirst) lines.push(`**Do first.** ${report.doFirst}`);
  if (report.checked?.length || report.notChecked?.length) lines.push('', `Checked: ${report.checked?.join(', ') || 'n/a'}. Not checked: ${report.notChecked?.join(', ') || 'n/a'}.`);
  return `${lines.join('\n').replace(/\n{3,}/g, '\n\n')}\n`;
}

// ------------------------------------------------------------------ GitHub pull request review
// Lines of the new side that a pull request diff can carry comments on: { "path": Set(lines) } from `git diff -U0 <base>...<head>`.
export function addedLines(diffText) {
  const map = new Map(); let file = null; let next = 0; let oldLeft = 0; let newLeft = 0;
  for (const line of diffText.replace(/\r\n/g, '\n').split('\n')) {
    if (oldLeft > 0 || newLeft > 0) { // inside a hunk: a leading + or - is content, never a header (an added line "++i;" starts with ++)
      if (line.startsWith('\\')) continue; // "\ No newline at end of file"
      if (line.startsWith('+')) { if (file) map.get(file).add(next); next++; newLeft--; }
      else if (line.startsWith('-')) oldLeft--;
      else { next++; oldLeft--; newLeft--; }
      continue;
    }
    const f = line.match(/^\+\+\+ b\/(.+?)(?:\t.*)?$/); // git appends a TAB after a name that contains a space
    if (f) { file = f[1]; if (!map.has(file)) map.set(file, new Set()); continue; }
    if (line.startsWith('+++ ')) { file = null; continue; }
    const h = line.match(/^@@ -\d+(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/);
    if (h) { oldLeft = h[1] === undefined ? 1 : Number(h[1]); next = Number(h[2]); newLeft = h[3] === undefined ? 1 : Number(h[3]); }
  }
  return map;
}
export const MARKER = (f) => `<!-- guided-plugins:${fingerprint(f)} -->`;
export function toGithubReview(report, diffText = null, { max = 25 } = {}) {
  const valid = diffText == null ? null : addedLines(diffText);
  const inline = []; const rest = [];
  for (const f of report.findings) {
    const onDiff = f.line && (valid == null || valid.get(f.path)?.has(f.line));
    if (onDiff && inline.length < max) {
      inline.push({ path: f.path, line: f.line, side: 'RIGHT', body: `**${ICON[f.severity]}** ${f.rule}${f.book ? ` · ${f.book}` : ''}${f.confidence === 'unsure' ? ' _(unsure)_' : ''}\n\n${f.why}\n\n**Fix:** ${f.fix}\n\n${MARKER(f)}` });
    } else rest.push({ fp: fingerprint(f), text: `- **${ICON[f.severity]}** \`${f.path}${f.line ? `:${f.line}` : ''}\` ${f.rule}: ${f.why} Fix: ${f.fix} ${MARKER(f)}` });
  }
  const head = `**Guided review:** ${report.findings.length} finding${report.findings.length === 1 ? '' : 's'} (${inline.length} inline). ${report.summary ?? ''}`.trim();
  const tail = report.doFirst ? `**Do first:** ${report.doFirst}` : '';
  // `body` is the whole text; github-post-review.mjs rebuilds it from head, the not-yet-posted `rest` bullets and tail, so a re-run with a
  // different summary does not repost findings that were already posted
  const body = `${head}${rest.length ? `\n\nNot on a changed line:\n${rest.map((r) => r.text).join('\n')}` : ''}${tail ? `\n\n${tail}` : ''}`;
  return { event: 'COMMENT', body, comments: inline, head, rest, tail };
}
