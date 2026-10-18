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

// Runs the server on raw input lines and returns its parsed output lines. `slowRead` lets the stdout pipe fill up first.
async function raw(lines, args = [], { slowRead = false, env = {} } = {}) {
  const child = spawn(process.execPath, [server, ...args], { stdio: ['pipe', 'pipe', 'pipe'], env: { ...process.env, ...env } });
  child.stdin.end(lines.map((l) => (typeof l === 'string' ? l : JSON.stringify(l))).join('\n') + '\n');
  if (slowRead) await new Promise((r) => setTimeout(r, 400));
  let out = ''; for await (const c of child.stdout) out += c;
  const code = await new Promise((r) => (child.exitCode !== null ? r(child.exitCode) : child.on('close', r)));
  return { replies: out.split('\n').filter(Boolean).map((l) => JSON.parse(l)), code, bytes: Buffer.byteLength(out) };
}
// Runs the server with arguments and no input; returns the exit code and what it wrote to stderr.
async function startup(args, env = {}) {
  const child = spawn(process.execPath, [server, ...args], { stdio: ['ignore', 'ignore', 'pipe'], env: { ...process.env, ...env } });
  let err = ''; child.stderr.on('data', (d) => { err += d; });
  return { code: await new Promise((r) => child.on('close', r)), err };
}

const bad = await startup(['--plugins', 'no-such-book']);
check(bad.code === 1 && /unknown plugin/.test(bad.err), 'an unknown --plugins value fails fast with a clear message');

// --- robustness: the cases that used to crash, truncate or stay silent
const big = await raw([{ jsonrpc: '2.0', id: 1, method: 'resources/list' }], [], { slowRead: true });
check(big.replies.length === 1 && big.replies[0].result?.resources?.length > 800 && big.bytes > 65536, `a response larger than the pipe buffer arrives whole when stdin closes (${big.bytes} bytes)`);

const edge = await raw([
  { jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name: 'get_rules', arguments: { plugin: 'clean-code', size: 'constructor' } } },
  { jsonrpc: '2.0', id: 2, method: 'tools/call', params: null },
  { jsonrpc: '2.0', id: 3, method: 'tools/call', params: { name: 'get_guide', arguments: null } },
  { jsonrpc: '2.0', id: 4, method: 'tools/call', params: { name: 'no_such_tool', arguments: {} } },
  '[]', '42', '"str"', 'null', '[1]',
  { jsonrpc: '2.0', id: 9, result: {} },
  { jsonrpc: '2.0', id: 10, method: 'resources/read' },
  { jsonrpc: '2.0', id: 11, method: 'initialize', params: { protocolVersion: '1999-01-01' } },
  { jsonrpc: '2.0', id: 12, method: 'prompts/get', params: null },
  { jsonrpc: '2.0', id: 13, method: 'tools/call', params: { name: 'get_rules', arguments: { plugin: 'clean-code', size: 'design' } } },
  { jsonrpc: '2.0', id: 14, method: 'tools/call', params: { name: 'get_rules', arguments: { plugin: 'refactoring-guru', size: 'design' } } },
  { jsonrpc: '2.0', id: 15, method: 'tools/list' },
  { jsonrpc: '2.0', id: 16, method: 'ping' },
]);
const by = (id) => edge.replies.find((r) => r.id === id);
check(by(1)?.result?.isError === true, 'get_rules with size "constructor" is a tool error, not an internal error');
check(by(2)?.error?.code === -32602 && by(3)?.result?.isError === true, 'null params and null arguments are handled (no -32603)');
check(by(4)?.error?.code === -32602, 'an unknown tool is a -32602 protocol error');
const nullIds = edge.replies.filter((r) => r.id === null);
const batchOfJunk = edge.replies.find((r) => Array.isArray(r));
check(nullIds.length === 4 && nullIds.every((r) => r.error?.code === -32600) && batchOfJunk?.length === 1 && batchOfJunk[0].error?.code === -32600,
  'an empty batch and non-object messages each get a -32600 reply with id null');
check(by(9) === undefined, 'a stray response message from the client is ignored');
check(by(10)?.error?.code === -32602, 'resources/read without a uri is -32602');
check(by(11)?.result?.protocolVersion === '2025-11-25', 'an unsupported client protocol version gets the newest supported one');
check(by(12)?.error?.code === -32602, 'prompts/get with null params is -32602');
check(by(13)?.result?.isError === true && by(14)?.result?.content?.[0]?.text.includes('component map'), 'get_rules design exists only for plugins whose skills refer to it');
check(by(15)?.result?.tools?.length === 4 && by(15).result.tools.every((t) => t.annotations?.readOnlyHint === true), 'every tool is annotated readOnlyHint');
check(by(16) && Object.keys(by(16).result).length === 0, 'the server keeps answering after the malformed input');

// --- options
const eq = await raw([{ jsonrpc: '2.0', id: 1, method: 'prompts/list' }], ['--plugins=clean-code']);
check(eq.replies[0]?.result?.prompts?.length > 0 && eq.replies[0].result.prompts.every((p) => p.name.startsWith('clean-code-')), '--plugins=name works like --plugins name');
const noValue = await startup(['--plugins']);
check(noValue.code === 1 && /needs a value/.test(noValue.err), '--plugins without a value fails fast');
const emptyValue = await startup(['--plugins=']);
check(emptyValue.code === 1, '--plugins= with an empty value fails fast');
const badKind = await startup(['--kinds', 'agnt']);
check(badKind.code === 1 && /unknown kind/.test(badKind.err), 'an unknown --kinds value fails fast');
const typo = await startup(['--plugin', 'clean-code']);
check(typo.code === 1 && /unknown argument/.test(typo.err), 'a mistyped option fails instead of serving every book');
const envList = await raw([{ jsonrpc: '2.0', id: 1, method: 'prompts/list' }], [], { env: { GUIDED_PLUGINS: 'ddd' } });
check(envList.replies[0].result.prompts.every((p) => /^ddd-/.test(p.name) && !/^ddd-(distilled|implementing)-/.test(p.name)), 'GUIDED_PLUGINS limits the surface to exactly that book');

console.log(failures ? `\n${failures} FAILED` : '\nall passed');
process.exit(failures ? 1 : 0);
