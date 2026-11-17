#!/usr/bin/env node
// Derives scripts/core.json: the few components of each book to start with. A core set is the four universal workflows (review, plan,
// checklist, fix), the two agents that orchestrate (lead, final-gate) and the first three specialist skills of the book's routing table in
// its principles skill, which is ordered by the book's own priorities. Edit core.json by hand to override a choice; run with --check to see
// whether the file still matches the plugins.
//   node scripts/gen-core.mjs [--check]
import fs from 'node:fs';
import path from 'node:path';
import { REGISTRY, ROOT } from './lib.mjs';

const STANDARD = new Set(['review', 'audit', 'plan', 'checklist', 'fix', 'explain-rule', 'principles']);
const out = {};
for (const b of REGISTRY.books) {
  const hub = fs.readFileSync(path.join(ROOT, 'plugins', b.slug, 'skills', 'principles', 'SKILL.md'), 'utf8');
  const table = hub.slice(hub.indexOf('## Routing table'));
  const end = table.indexOf('\n## ', 5);
  const rows = table.slice(0, end === -1 ? undefined : end).split('\n').filter((l) => l.startsWith('|') && !/^\|\s*(Situation|---)/.test(l));
  const skills = [];
  for (const row of rows) {
    const use = row.split('|').slice(2, -1).join('|');
    for (const m of use.matchAll(new RegExp(`/${b.slug}:([a-z-]+)`, 'g'))) {
      if (!STANDARD.has(m[1]) && !m[1].startsWith('mode-') && !skills.includes(m[1]) && fs.existsSync(path.join(ROOT, 'plugins', b.slug, 'skills', m[1], 'SKILL.md'))) skills.push(m[1]);
    }
  }
  out[b.slug] = { workflows: ['review', 'plan', 'checklist', 'fix'], skills: skills.slice(0, 3), agents: ['lead', 'final-gate'] };
}
const text = `${JSON.stringify(out, null, 2)}\n`;
const file = path.join(ROOT, 'scripts', 'core.json');
if (process.argv.includes('--check')) {
  const have = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  console.log(have === text ? 'core.json matches the derivation' : 'core.json differs from the derivation (hand edits are fine; this is a note)');
} else { fs.writeFileSync(file, text); console.log('wrote scripts/core.json'); }
