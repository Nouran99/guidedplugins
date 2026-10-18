#!/usr/bin/env node
// Spawns scripts/mcp-server.mjs and exercises the protocol the way a client does. Exit code 1 on any failed expectation.
//   node scripts/mcp-selftest.mjs
import { spawn } from 'node:child_process';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const server = path.join(path.dirname(fileURLToPath(import.meta.url)), 'mcp-server.mjs');

function session(extraArgs = []) {
  const child = spawn(process.execPath, [server, ...extraArgs], { stdio: ['pipe', 'pipe', 'pipe'] });
  const pending = new Map();
  let nextId = 1;
  readline.createInterface({ input: child.stdout }).on('line', (l) => {
    const m = JSON.parse(l);
    const arr = Array.isArray(m) ? m : [m];
    for (const x of arr) pending.get(x.id)?.(x);
  });
  const call = (method, params) => new Promise((resolve) => {
    const id = nextId++;
    pending.set(id, resolve);
    child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', id, method, params })}\n`);
  });
  const notify = (method, params) => child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', method, params })}\n`);
  return { call, notify, close: () => child.kill(), child };
}

let failures = 0;
const check = (ok, what) => { if (!ok) { failures++; console.log(`FAIL ${what}`); } else console.log(`ok   ${what}`); };

const s = session();
const init = await s.call('initialize', { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'selftest', version: '0' } });
check(init.result?.protocolVersion === '2025-06-18' && init.result.capabilities.tools && init.result.capabilities.prompts && init.result.capabilities.resources, 'initialize negotiates the protocol and declares tools, resources, prompts');
s.notify('notifications/initialized', {});
check(Object.keys((await s.call('ping', {})).result ?? { x: 1 }).length === 0, 'ping');

const tools = (await s.call('tools/list', {})).result.tools;
check(['search_guides', 'get_guide', 'list_guides', 'get_rules'].every((n) => tools.some((t) => t.name === n && t.inputSchema.type === 'object')), 'tools/list exposes the four tools with input schemas');

const search = await s.call('tools/call', { name: 'search_guides', arguments: { query: 'review naming in a diff', plugin: 'clean-code' } });
check(/clean-code-naming|clean-code-review/.test(search.result.content[0].text), 'search_guides finds the Clean Code naming and review guides');

const guide = await s.call('tools/call', { name: 'get_guide', arguments: { id: 'clean-code-review' } });
const gtext = guide.result.content[0].text;
check(gtext.includes('# clean-code-review') && !gtext.startsWith('---') && !gtext.includes('${CLAUDE_'), 'get_guide returns the guide text without frontmatter or Claude variables');

const missing = await s.call('tools/call', { name: 'get_guide', arguments: { id: 'nope' } });
check(missing.result.isError === true, 'unknown guide id is a tool error, not a crash');

const rules = await s.call('tools/call', { name: 'get_rules', arguments: { plugin: 'ddd', size: 'nano' } });
check(rules.result.content[0].text.length > 500, 'get_rules returns the nano rule set');
const list = await s.call('tools/call', { name: 'list_guides', arguments: { plugin: 'refactoring', manual: true } });
check(/refactoring-review/.test(list.result.content[0].text), 'list_guides filters by plugin and manual');

const prompts = (await s.call('prompts/list', {})).result.prompts;
check(prompts.length > 500 && prompts.every((p) => p.name && Array.isArray(p.arguments)), `prompts/list exposes ${prompts.length} prompts (workflows, modes, subagent roles)`);
const pr = await s.call('prompts/get', { name: 'clean-code-review', arguments: { arguments: 'src/' } });
check(pr.result.messages[0].content.text.includes('Arguments: src/'), 'prompts/get substitutes the arguments');
const pa = await s.call('prompts/get', { name: 'clean-code-naming-reviewer', arguments: { task: 'review billing.ts' } });
check(pa.result.messages[0].content.text.includes('Task: review billing.ts'), 'prompts/get serves a subagent role with its task');

const res = (await s.call('resources/list', {})).result.resources;
check(res.length > 800 && res.every((r) => r.uri.startsWith('guided://')), `resources/list exposes ${res.length} resources`);
const rr = await s.call('resources/read', { uri: 'guided://rules/legacy-code/mini' });
check(rr.result.contents[0].text.length > 500, 'resources/read returns a rule file');
check((await s.call('resources/read', { uri: 'guided://guide/nope' })).error?.code === -32002, 'resources/read reports a missing resource');
check((await s.call('no/such/method', {})).error?.code === -32601, 'unknown method returns -32601');
s.close();

const filtered = session(['--plugins', 'clean-code,refactoring']);
await filtered.call('initialize', { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'selftest', version: '0' } });
const fp = (await filtered.call('prompts/list', {})).result.prompts;
check(fp.length > 0 && fp.length < 120 && fp.every((p) => /^(clean-code|refactoring)-/.test(p.name)), `--plugins limits the surface (${fp.length} prompts)`);
const fl = await filtered.call('tools/call', { name: 'get_guide', arguments: { id: 'ddd-review' } });
check(fl.result.isError === true, 'a filtered-out plugin is not served');
filtered.close();

const bad = spawn(process.execPath, [server, '--plugins', 'no-such-book'], { stdio: ['ignore', 'ignore', 'pipe'] });
let err = ''; bad.stderr.on('data', (d) => { err += d; });
const code = await new Promise((r) => bad.on('close', r));
check(code === 1 && /unknown plugin/.test(err), 'an unknown --plugins value fails fast with a clear message');

console.log(failures ? `\n${failures} FAILED` : '\nall passed');
process.exit(failures ? 1 : 0);
