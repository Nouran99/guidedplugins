#!/usr/bin/env node
// Adds the shared "project settings" and "JSON output" text to every book plugin (docs/PROJECT_CONFIG.md, docs/findings.schema.json):
//   hub skill (principles)            a "Project settings" section before "## Source"
//   review, audit, checklist, fix, plan   one line after the Arguments line that points at that section
//   review                            a "JSON output" section before "## Stop conditions" (the findings format, inline)
//   lead, final-gate agents           a short "Project settings" paragraph before "## Source"
// Idempotent: every inserted text carries a marker and is replaced, not duplicated, when this script runs again.
//   node scripts/apply-project-settings.mjs            write
//   node scripts/apply-project-settings.mjs --check    fail when a plugin lacks the current text (used by validate-plugin)
//   node scripts/apply-project-settings.mjs --bump     also bump each plugin to 1.1.0 and add a changelog entry (once)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { PLUGINS_DIR, REGISTRY } from './lib.mjs';

const WORKFLOWS = ['review', 'audit', 'checklist', 'fix', 'plan'];
const AGENTS = ['lead', 'final-gate'];
export const HUB_START = '<!-- project-settings:start -->';
export const HUB_END = '<!-- project-settings:end -->';
export const LINE_MARK = '<!-- project-settings -->';
export const AGENT_MARK = '<!-- project-settings:agent:start -->';
export const AGENT_END = '<!-- project-settings:agent:end -->';
export const JSON_START = '<!-- json-output:start -->';
export const JSON_END = '<!-- json-output:end -->';

export const hubBlock = (book) => `${HUB_START}
## Project settings

If the repository has a \`.guided-plugins.json\` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- \`ignore\` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- \`strictness\`: \`relaxed\` reports blockers and majors only; \`normal\` (the default) adds minors; \`strict\` adds nits.
- \`maxFindings\` (default 15): report at most this many, most serious first, and say how many were left out.
- \`primary\` and \`secondary\`: if ${book.title} is not the \`primary\` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("${book.title} would ..., the primary book decides: ..."), not as a finding.
- \`failOn\` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
${HUB_END}`;

export const workflowLine = () => `Project settings: if \`.guided-plugins.json\` exists at the repository root, apply it first, as the *Project settings* section of \`\${CLAUDE_PLUGIN_ROOT}/skills/principles/SKILL.md\` describes: skip ignored files, report at the set strictness, cap the report at \`maxFindings\`, and treat a secondary book's disagreement with the primary book as a note. ${LINE_MARK}`;

export const agentBlock = () => `${AGENT_MARK}
## Project settings

Read \`.guided-plugins.json\` at the repository root if it exists, and apply it as the *Project settings* section of \`\${CLAUDE_PLUGIN_ROOT}/skills/principles/SKILL.md\` describes (Read that section if it is not already in your context): leave ignored files out, report at the set strictness and cap the report at \`maxFindings\`.
${AGENT_END}`;

export const jsonBlock = (slug) => `${JSON_START}
## JSON output

If \`$ARGUMENTS\` contains \`--json\`, or the caller supplied a JSON schema, return exactly one JSON object and nothing else, and ignore the \`--json\` flag when you read the scope. Same ranking, same limits, same rules about what to report; only the shape changes:

\`\`\`json
{"schemaVersion": 1, "tool": "${slug}", "books": ["${slug}"], "scope": "<what was reviewed>",
 "findings": [{"severity": "blocker|major|minor|nit", "path": "<repository-relative path>", "line": 42, "rule": "<rule name>", "book": "${slug}",
               "why": "<consequence, one or two sentences>", "fix": "<smallest change>", "confidence": "sure|unsure"}],
 "checked": ["<clusters>"], "notChecked": ["<clusters or files out of scope>"],
 "summary": "<two sentences>", "doFirst": "<the one finding to fix first>"}
\`\`\`

With no findings, return an empty \`findings\` array. \`line\` is a whole number of at least 1 and may be left out for a finding about a whole file.
${JSON_END}`;

// ---------------------------------------------------------------- editing helpers
function replaceBlock(text, start, end, block, before) {
  const s = text.indexOf(start);
  if (s !== -1) {
    const e = text.indexOf(end, s);
    if (e === -1) throw new Error(`unterminated block ${start}`);
    return `${text.slice(0, s)}${block}${text.slice(e + end.length)}`;
  }
  const at = text.indexOf(before);
  if (at === -1) throw new Error(`cannot find "${before.trim()}" to insert before`);
  return `${text.slice(0, at)}${block}\n\n${text.slice(at)}`;
}
function setLine(text) {
  const lines = text.split('\n');
  const i = lines.findIndex((l) => l.startsWith('Arguments: '));
  if (i === -1) throw new Error('no Arguments line');
  const j = lines.findIndex((l) => l.includes(LINE_MARK));
  if (j !== -1) { lines[j] = workflowLine(); return lines.join('\n'); }
  lines.splice(i + 1, 0, '', workflowLine());
  return lines.join('\n');
}

export function expected(slug, kind, name, text) {
  const book = REGISTRY.books.find((b) => b.slug === slug);
  if (kind === 'hub') return replaceBlock(text, HUB_START, HUB_END, hubBlock(book), '## Source');
  if (kind === 'agent') return replaceBlock(text, AGENT_MARK, AGENT_END, agentBlock(), '## Source');
  let out = setLine(text);
  if (name === 'review') out = replaceBlock(out, JSON_START, JSON_END, jsonBlock(slug), '## Stop conditions');
  return out;
}

export function targets(slug, dir = PLUGINS_DIR) {
  const base = path.join(dir, slug);
  return [
    { file: path.join(base, 'skills', 'principles', 'SKILL.md'), kind: 'hub', name: 'principles' },
    ...WORKFLOWS.map((n) => ({ file: path.join(base, 'skills', n, 'SKILL.md'), kind: 'workflow', name: n })),
    ...AGENTS.map((n) => ({ file: path.join(base, 'agents', `${n}.md`), kind: 'agent', name: n })),
  ];
}

// ---------------------------------------------------------------- main
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const di = process.argv.indexOf('--dir');
  const DIR = di >= 0 ? path.resolve(process.argv[di + 1]) : PLUGINS_DIR;
  const check = process.argv.includes('--check');
  const bump = process.argv.includes('--bump');
  let changed = 0; const stale = [];
  for (const b of REGISTRY.books) {
    for (const t of targets(b.slug, DIR)) {
      const text = fs.readFileSync(t.file, 'utf8');
      const next = expected(b.slug, t.kind, t.name, text);
      if (next !== text) { if (check) stale.push(path.relative(DIR, t.file)); else { fs.writeFileSync(t.file, next); changed++; } }
    }
    if (bump && !check) {
      const man = path.join(DIR, b.slug, '.claude-plugin', 'plugin.json');
      const j = JSON.parse(fs.readFileSync(man, 'utf8'));
      if (j.version === '1.0.0') {
        j.version = '1.1.0';
        fs.writeFileSync(man, `${JSON.stringify(j, null, 2)}\n`);
        const log = path.join(DIR, b.slug, 'CHANGELOG.md');
        const t = fs.readFileSync(log, 'utf8');
        const entry = `## [1.1.0]

### Added
- Project settings: the \`principles\` skill, the \`review\`, \`audit\`, \`checklist\`, \`fix\` and \`plan\` workflows and the \`lead\` and \`final-gate\` agents read an optional \`.guided-plugins.json\` (ignored paths, strictness, report size, primary and secondary books).
- \`/${b.slug}:review --json\` returns the findings format used by the CI runner and the \`guided\` companion plugin.

`;
        fs.writeFileSync(log, t.replace('## [1.0.0]', `${entry}## [1.0.0]`));
      }
    }
  }
  if (check) {
    if (stale.length) { console.error(`project-settings text is missing or stale in:\n  ${stale.join('\n  ')}\nrun: node scripts/apply-project-settings.mjs`); process.exit(1); }
    console.log('project settings text is current in all plugins');
  } else console.log(`${changed} file(s) changed`);
}
