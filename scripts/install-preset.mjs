#!/usr/bin/env node
// Prints the commands that install a preset (scripts/presets.json) for each coding agent, using this checkout.
//   node scripts/install-preset.mjs everyday-code                 # every agent
//   node scripts/install-preset.mjs legacy-rescue --agent codex   # one agent: claude | codex | opencode | gemini | copilot | skills
//   node scripts/install-preset.mjs --list
// It only prints. Claude Code installs a whole preset with one command because the bundle plugin lists its books as dependencies;
// the other agents have no bundles, so the commands are one per book. Run them from your project's folder where they write into it.
import fs from 'node:fs';
import path from 'node:path';
import { REGISTRY, ROOT } from './lib.mjs';

const presets = JSON.parse(fs.readFileSync(path.join(ROOT, 'scripts', 'presets.json'), 'utf8')).presets;
const args = process.argv.slice(2);
if (args.includes('--list') || !args.find((a) => !a.startsWith('--'))) {
  console.log(presets.map((p) => `${p.name.padEnd(16)} ${p.title}: ${[p.primary, ...p.secondary].join(' + ')}`).join('\n'));
  process.exit(args.includes('--list') ? 0 : 2);
}
const name = args.find((a) => !a.startsWith('--'));
const preset = presets.find((p) => p.name === name);
if (!preset) { console.error(`unknown preset "${name}". presets: ${presets.map((p) => p.name).join(', ')}`); process.exit(2); }
const ai = args.indexOf('--agent');
const only = ai >= 0 ? args[ai + 1] : null;
const AGENTS = ['claude', 'codex', 'opencode', 'gemini', 'copilot', 'skills'];
if (only && !AGENTS.includes(only)) { console.error(`--agent must be one of ${AGENTS.join(', ')}`); process.exit(2); }
const books = [preset.primary, ...preset.secondary];
const mp = REGISTRY.marketplace.name;
const q = (s) => (/^[\w@%+=:,./-]+$/.test(s) ? s : `'${s.replace(/'/g, "'\\''")}'`); // POSIX single quotes: no expansion of $ or backticks in a path
const clone = q(ROOT);
const out = [];
const section = (agent, title, lines) => { if (!only || only === agent) out.push(`# ${title}`, ...lines, ''); };

section('claude', 'Claude Code (one command: the bundle installs the books and the guided plugin)', [
  `/plugin marketplace add ${REGISTRY.marketplace.githubRepo}        # or: /plugin marketplace add ${clone}`,
  `/plugin install guided-${preset.name}@${mp}`,
]);
section('codex', 'Codex CLI (a plugin per book; then, in Codex, $<book>:install-roles for the subagents)', [
  `codex plugin marketplace add ${clone}`,
  ...books.map((b) => `codex plugin add ${b}@${mp}`),
]);
section('opencode', 'OpenCode (run from your project folder; copies skills and agents into ./.opencode)', [
  `node ${q(path.join(ROOT, 'scripts', 'install-opencode.mjs'))} ${books.join(' ')}`,
]);
section('gemini', 'Gemini CLI (one extension per book)', books.map((b) => `gemini extensions install ${q(path.join(ROOT, 'dist', 'gemini', b))}`));
section('copilot', 'GitHub Copilot CLI', [
  `copilot plugin marketplace add ${clone}`,
  ...books.map((b) => `copilot plugin install ${b}@${mp}`),
]);
section('skills', 'Any Agent Skills agent (skills and modes only, no subagents)', books.map((b) => `npx skills add ${q(path.join(ROOT, 'dist', 'agent-skills', b))}`));
if (!only) out.push('# Project settings (any agent): the primary book decides when the books disagree', `node ${q(path.join(ROOT, 'scripts', 'guided-config.mjs'))} init --preset ${preset.name}`, '');
console.log(`Preset ${preset.name}: ${preset.title}. Primary ${preset.primary}; secondary ${preset.secondary.join(', ')}.\n${preset.why}\n`);
console.log(out.join('\n').trimEnd());
