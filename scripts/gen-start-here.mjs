#!/usr/bin/env node
// Writes the "Start here" table at the top of every plugin README, from scripts/core.json and the skills' own descriptions.
//   node scripts/gen-start-here.mjs [--check] [--dir <plugins dir>]
import fs from 'node:fs';
import path from 'node:path';
import { PLUGINS_DIR, REGISTRY, ROOT, parseFrontmatter } from './lib.mjs';

const START = '<!-- START-HERE:START -->';
const END = '<!-- START-HERE:END -->';
const check = process.argv.includes('--check');
const di = process.argv.indexOf('--dir');
const DIR = di >= 0 ? path.resolve(process.argv[di + 1]) : PLUGINS_DIR;
const core = JSON.parse(fs.readFileSync(path.join(ROOT, 'scripts', 'core.json'), 'utf8'));
const WORKFLOW = { review: 'Review your current change', plan: 'Plan a non-trivial change before you edit', checklist: 'Walk the book\'s final checklist against your change', fix: 'Act on review findings, one at a time' };

// "Use when X: details." -> "When X"; any other first sentence is kept, trimmed to a clause of at most `max` characters
const first = (text, max = 130) => {
  const t = String(text).replace(/\s+/g, ' ').trim();
  let s = t.match(/^.+?[.!?](?=\s|$)/)?.[0] ?? t;
  s = s.replace(/^Use (when|before|after|first)\b/i, (m, w) => w[0].toUpperCase() + w.slice(1)).replace(/^Use /, '');
  const colon = s.indexOf(': ');
  if (colon > 25) s = s.slice(0, colon);
  s = s.replace(/[.;,:]+$/, '');
  if (s.length > max) { // cut at a clause boundary when there is one, never in the middle of a word
    const cut = s.slice(0, max);
    const at = Math.max(cut.lastIndexOf(', '), cut.lastIndexOf('; '), cut.lastIndexOf(' and '), cut.lastIndexOf(' or '));
    s = at > 40 ? cut.slice(0, at) : `${cut.replace(/[\s,;]+\S*$/, '')}…`;
  }
  return s[0].toUpperCase() + s.slice(1);
};
const describe = (slug, kind, name) => {
  const file = path.join(DIR, slug, kind === 'skill' ? `skills/${name}/SKILL.md` : `agents/${name}.md`);
  return first(parseFrontmatter(fs.readFileSync(file, 'utf8')).data?.description ?? name);
};

let stale = 0;
for (const b of REGISTRY.books) {
  const c = core[b.slug];
  const rows = [
    ...c.workflows.map((w) => `| ${WORKFLOW[w]} | \`/${b.slug}:${w}\` |`),
    ...c.skills.map((s) => `| ${describe(b.slug, 'skill', s)} | \`/${b.slug}:${s}\` |`),
    ...c.agents.map((a) => `| ${a === 'lead' ? 'Not sure which specialist applies? Route the task' : 'Strict pass or fail before you commit or open a pull request'} | ask Claude to use \`${b.slug}:${a}\` |`),
  ];
  const block = `${START}
## Start here

${c.workflows.length + c.skills.length + c.agents.length} components cover most uses; everything else is reachable from the \`${b.slug}:principles\` skill's routing table.

| To | Run |
| --- | --- |
${rows.join('\n')}

Using this book next to others? \`/plugin install guided-<preset>@guided-plugins\` installs a primary book with complementary ones, and \`/guided:review\` reviews with all of them at once. Project settings (ignored paths, strictness, the primary book): [\`.guided-plugins.json\`](https://github.com/${REGISTRY.marketplace.githubRepo}/blob/main/docs/PROJECT_CONFIG.md).
${END}`;
  const file = path.join(DIR, b.slug, 'README.md');
  const text = fs.readFileSync(file, 'utf8');
  let next;
  if (text.includes(START) !== text.includes(END)) throw new Error(`${b.slug}: README has one of the START-HERE markers but not the other; fix the file by hand`);
  if (text.includes(START)) next = `${text.slice(0, text.indexOf(START))}${block}${text.slice(text.indexOf(END) + END.length)}`;
  else { const at = text.indexOf('\n## Overview'); if (at === -1) throw new Error(`${b.slug}: README has no "## Overview" to put the block before`); next = `${text.slice(0, at + 1)}${block}\n${text.slice(at)}`; }
  if (next !== text) { stale++; if (!check) fs.writeFileSync(file, next); }
}
if (check) { if (stale) { console.error(`${stale} plugin README(s) lack a current "Start here" block; run: node scripts/gen-start-here.mjs`); process.exit(1); } console.log('Start here blocks are current'); }
else console.log(`${stale} README(s) updated`);
