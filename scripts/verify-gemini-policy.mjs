#!/usr/bin/env node
// Checks the generated Gemini policy files (dist/gemini/<plugin>/policies/read-only-roles.toml) against Gemini CLI's OWN policy engine.
//   node scripts/verify-gemini-policy.mjs <dir of an installed gemini-cli bundle> [plugin ...]
//   e.g. node scripts/verify-gemini-policy.mjs ~/.npm-global/lib/node_modules/@google/gemini-cli/bundle clean-code ddd
// The engine is imported from the CLI's bundle (the chunk that exports PolicyEngine and loadPoliciesFromToml), the rules are loaded with
// its TOML loader as an extension-tier (2) policy, and every decision comes from PolicyEngine.check(). Tested on gemini-cli 0.64.
// Not part of CI because it needs the CLI installed; scripts/validate-targets.mjs runs an offline re-implementation of the same battery.
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { ROOT, REGISTRY } from './lib.mjs';
import { POLICY_MUST_ALLOW as MUST_NOT_DENY, POLICY_MUST_DENY as MUST_DENY } from './targets/gemini.mjs';

const bundle = process.argv[2];
if (!bundle || !fs.existsSync(bundle)) { console.error('usage: verify-gemini-policy.mjs <gemini-cli bundle dir> [plugin ...]'); process.exit(2); }
const slugs = process.argv.slice(3).length ? process.argv.slice(3) : REGISTRY.books.map((b) => b.slug);

const chunk = fs.readdirSync(bundle).filter((f) => f.endsWith('.js')).find((f) => {
  const t = fs.readFileSync(path.join(bundle, f), 'utf8');
  return /\nvar PolicyEngine = class/.test(t) && /async function loadPoliciesFromToml/.test(t);
});
if (!chunk) { console.error('no chunk in this bundle exports PolicyEngine and loadPoliciesFromToml'); process.exit(2); }
const { PolicyEngine, loadPoliciesFromToml } = await import(pathToFileURL(path.join(bundle, chunk)).href);

let failures = 0; let checked = 0;
const fail = (m) => { failures++; console.log(`FAIL ${m}`); };

for (const slug of slugs) {
  const dir = path.join(ROOT, 'dist', 'gemini', slug, 'policies');
  const { rules, errors } = await loadPoliciesFromToml([dir], () => 2);
  if (errors.length) { fail(`${slug}: policy load errors ${JSON.stringify(errors).slice(0, 300)}`); continue; }
  const engine = new PolicyEngine({ rules, nonInteractive: false });
  const roles = [...new Set(rules.map((r) => r.subagent).filter(Boolean))];
  if (!roles.length) { fail(`${slug}: no per-role rules were loaded`); continue; }
  for (const role of roles) {
    for (const command of MUST_NOT_DENY) {
      const r = await engine.check({ name: 'run_shell_command', args: { command } }, undefined, undefined, role);
      checked++;
      if (r.decision === 'deny') fail(`${role}: wrongly denied "${command}"`);
    }
    for (const command of MUST_DENY) {
      const r = await engine.check({ name: 'run_shell_command', args: { command } }, undefined, undefined, role);
      checked++;
      if (r.decision !== 'deny') fail(`${role}: allowed "${command.replace(/\n/g, '\\n')}" (decision ${r.decision})`);
    }
    for (const name of ['write_file', 'replace']) {
      const r = await engine.check({ name, args: { file_path: 'a.txt', content: 'x' } }, undefined, undefined, role);
      checked++;
      if (r.decision !== 'deny') fail(`${role}: ${name} not denied (${r.decision})`);
    }
    const rd = await engine.check({ name: 'read_file', args: { file_path: 'a.txt' } }, undefined, undefined, role);
    checked++;
    if (rd.decision === 'deny') fail(`${role}: read_file wrongly denied`);
    // the rules must be scoped to the role: the same destructive command from the main agent or from another subagent is untouched by them
    for (const other of [undefined, 'some-other-subagent']) {
      const r = await engine.check({ name: 'run_shell_command', args: { command: 'rm -rf build' } }, undefined, undefined, other);
      checked++;
      if (r.decision === 'deny') fail(`${role}: rule leaks to ${other ?? 'the main agent'}`);
    }
  }
  console.log(`${slug}: ${roles.length} read-only roles checked against ${rules.length} rules`);
}
console.log(failures ? `\n${failures} FAILED of ${checked} decisions` : `\nall ${checked} decisions as expected`);
process.exit(failures ? 1 : 0);
