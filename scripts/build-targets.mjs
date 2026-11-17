#!/usr/bin/env node
// Builds the per-agent distributions under dist/ from the canonical Claude plugins in plugins/.
//   node scripts/build-targets.mjs                 # all targets
//   node scripts/build-targets.mjs --target codex  # one target (repeatable)
// The output is committed; CI fails when it is stale (see scripts/validate-targets.mjs).
import { loadModel } from './targets/core.mjs';
import { buildAgentSkills } from './targets/agent-skills.mjs';

const TARGETS = {
  'agent-skills': { build: buildAgentSkills },
};
// Optional targets register themselves as their modules exist.
for (const [id, mod, fn] of [
  ['codex', './targets/codex.mjs', 'buildCodex'],
  ['opencode', './targets/opencode.mjs', 'buildOpenCode'],
  ['gemini', './targets/gemini.mjs', 'buildGemini'],
  ['cursor', './targets/cursor.mjs', 'buildCursor'],
  ['copilot', './targets/copilot.mjs', 'buildCopilot'],
  ['rules', './targets/rules.mjs', 'buildRules'],
  ['mcp', './targets/mcp.mjs', 'buildMcp'],
]) {
  try { TARGETS[id] = { build: (await import(mod))[fn] }; } catch (e) { if (e.code !== 'ERR_MODULE_NOT_FOUND') throw e; }
}

const args = process.argv.slice(2);
const only = [];
for (let i = 0; i < args.length; i++) if (args[i] === '--target') only.push(args[++i]);
const ids = only.length ? only : Object.keys(TARGETS);
for (const id of ids) if (!TARGETS[id]) { console.error(`unknown or unavailable target "${id}"; have: ${Object.keys(TARGETS).join(', ')}`); process.exit(2); }

const model = loadModel();
for (const id of ids) {
  const r = TARGETS[id].build(model);
  console.log(`built ${id}${Array.isArray(r) ? ` (${r.length} plugins)` : ''}`);
}
