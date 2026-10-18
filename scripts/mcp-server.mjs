#!/usr/bin/env node
// guided-plugins MCP server: serves the 14 book toolkits (skills, modes, subagent prompts, rule files) to ANY MCP-capable agent.
// Zero dependencies, stdio transport (newline-delimited JSON-RPC 2.0).
//
//   node scripts/mcp-server.mjs                          # everything
//   node scripts/mcp-server.mjs --plugins clean-code,refactoring     # only these books (also --plugins=a,b and GUIDED_PLUGINS=a,b)
//   node scripts/mcp-server.mjs --kinds skill,agent                  # only these kinds (also GUIDED_KINDS)
//
// Tools work in every MCP client. Prompts (manual workflows, modes, subagent roles) show up as slash commands in clients that expose
// MCP prompts. Resources expose every guide and rule file for clients that let you attach them.
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIST = path.resolve(HERE, '..', 'dist');
const PROTOCOLS = ['2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05']; // newest first: the answer to an unsupported request
const KINDS = ['skill', 'mode', 'agent'];

// ----------------------------------------------------------------------------------------------- options
const USAGE = `usage: node scripts/mcp-server.mjs [--plugins a,b] [--kinds skill,mode,agent]
  --plugins a,b          serve only these books (or GUIDED_PLUGINS=a,b); default: all 14
  --kinds skill,agent    serve only these kinds (or GUIDED_KINDS=...); kinds are ${KINDS.join(', ')}
Options also accept the form --plugins=a,b. A mistyped option is an error, not ignored.\n`;
const fail = (msg) => { process.stderr.write(`guided-plugins: ${msg}\n${USAGE}`); process.exit(1); };

const ENV = { plugins: 'GUIDED_PLUGINS', kinds: 'GUIDED_KINDS' };
function parseOptions(argv) {
  const given = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--help' || a === '-h') { process.stdout.write(USAGE); process.exit(0); }
    const m = a.match(/^--([a-z]+)(?:=(.*))?$/);
    if (!m || !(m[1] in ENV)) fail(`unknown argument "${a}"`);
    let v = m[2];
    if (v === undefined) { v = argv[i + 1]; if (v === undefined || v.startsWith('--')) fail(`--${m[1]} needs a value`); i++; }
    given[m[1]] = v;
  }
  const list = (name) => {
    let v = given[name];
    if (v === undefined && process.env[ENV[name]] !== undefined) {
      v = process.env[ENV[name]];
      if (!v.trim()) { process.stderr.write(`guided-plugins: ${ENV[name]} is set but empty; ignoring it\n`); return null; }
    }
    if (v === undefined) return null;
    const items = v.split(',').map((x) => x.trim()).filter(Boolean);
    if (!items.length) fail(`--${name} needs at least one name`);
    return items;
  };
  return { plugins: list('plugins'), kinds: list('kinds') };
}
const { plugins: onlyPlugins, kinds: onlyKinds } = parseOptions(process.argv.slice(2));

// ----------------------------------------------------------------------------------------------- catalog
let catalog;
try { catalog = JSON.parse(fs.readFileSync(path.join(DIST, 'mcp', 'catalog.json'), 'utf8')); } catch (e) {
  process.stderr.write(`guided-plugins: cannot read dist/mcp/catalog.json (${e.message}). Run: node scripts/build-targets.mjs\n`);
  process.exit(1);
}
const SERVER = { name: 'guided-plugins', version: catalog.version ?? '0.0.0' };
if (onlyPlugins) {
  const known = new Set(catalog.books.map((b) => b.slug));
  const unknown = onlyPlugins.filter((p) => !known.has(p));
  if (unknown.length) { process.stderr.write(`guided-plugins: unknown plugin(s): ${unknown.join(', ')}. Known: ${[...known].join(', ')}\n`); process.exit(1); }
}
if (onlyKinds) {
  const unknown = onlyKinds.filter((k) => !KINDS.includes(k));
  if (unknown.length) { process.stderr.write(`guided-plugins: unknown kind(s): ${unknown.join(', ')}. Known: ${KINDS.join(', ')}\n`); process.exit(1); }
}
const entries = catalog.entries.filter((e) => (!onlyPlugins || onlyPlugins.includes(e.plugin)) && (!onlyKinds || onlyKinds.includes(e.kind)));
const books = catalog.books.filter((b) => !onlyPlugins || onlyPlugins.includes(b.slug));
const byId = new Map(entries.map((e) => [e.id, e]));
const bookBySlug = new Map(books.map((b) => [b.slug, b]));

const read = (rel) => fs.readFileSync(path.join(DIST, rel), 'utf8');
const stripFrontmatter = (t) => t.replace(/^---\n[\s\S]*?\n---\n/, '').replace(/^\s+/, '');
const short = (s, n) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);

const PREFACE = 'This guide is served by the guided-plugins MCP server. Relative paths in it refer to other guides: `../<plugin>-<name>/SKILL.md` is the guide `<plugin>-<name>` (fetch it with get_guide), and `references/<size>.md` or `../<plugin>-principles/references/<size>.md` is a rule file (fetch it with get_rules). Slash commands and skill mentions in it are guide ids.';

function guideText(e) {
  const raw = read(e.file);
  const body = e.kind === 'agent' ? raw : stripFrontmatter(raw);
  return `# ${e.id} (${e.kind}${e.manual ? ', run on request' : ''})\n\n_${PREFACE}_\n\n${body}`;
}

function rulesText(slug, size) {
  const b = bookBySlug.get(slug);
  if (!b) throw new RpcError(-32602, `Unknown plugin "${slug}". Known: ${books.map((x) => x.slug).join(', ')}`);
  if (!['nano', 'mini', 'full', 'design'].includes(size)) throw new RpcError(-32602, `Unknown size "${size}". Use nano, mini, full or design.`);
  const rel = Object.hasOwn(b.rules, size) ? b.rules[size] : null;
  if (!rel) throw new RpcError(-32602, `"${slug}" has no ${size} file. The component map exists only for plugins whose skills refer to it.`);
  return read(rel);
}

// ----------------------------------------------------------------------------------------------- tools
class RpcError extends Error { constructor(code, message) { super(message); this.code = code; } }

const kindEnum = KINDS;
const READ_ONLY = { readOnlyHint: true, openWorldHint: false }; // every tool only reads the packaged files
const TOOLS = [
  {
    name: 'search_guides',
    description: 'Find the right guide for a task. Searches the names and descriptions of all skills, modes and subagent prompts across the book toolkits (Clean Code, Refactoring, DDD, Release It!, and others). Returns ranked ids; fetch one with get_guide.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'What you are doing or need, in plain words, e.g. "review naming in this diff" or "split a class with too many responsibilities".' },
        plugin: { type: 'string', description: 'Limit to one book plugin slug, e.g. clean-code.' },
        kind: { type: 'string', enum: kindEnum, description: 'Limit to skills, modes or agents.' },
        limit: { type: 'integer', minimum: 1, maximum: 30, description: 'Maximum results (default 8).' },
      },
      required: ['query'],
    },
    annotations: READ_ONLY,
  },
  {
    name: 'get_guide',
    description: 'Return the full text of one guide by id (a skill, mode or subagent prompt), e.g. "clean-code-review". Follow it as instructions for the task at hand.',
    inputSchema: { type: 'object', properties: { id: { type: 'string', description: 'Guide id from search_guides or list_guides.' } }, required: ['id'] },
    annotations: READ_ONLY,
  },
  {
    name: 'list_guides',
    description: 'List guides, optionally filtered by plugin, kind or whether they are run on request. Use search_guides when you know the task.',
    inputSchema: {
      type: 'object',
      properties: {
        plugin: { type: 'string' },
        kind: { type: 'string', enum: kindEnum },
        manual: { type: 'boolean', description: 'true = only workflows to run on request (review, plan, fix, audit, ...).' },
      },
    },
    annotations: READ_ONLY,
  },
  {
    name: 'get_rules',
    description: 'Return a book\'s rule set as plain text: nano (smallest, always-on), mini (recommended working set), full (complete reference) or design (the component map; only plugins whose skills refer to it have one).',
    inputSchema: {
      type: 'object',
      properties: {
        plugin: { type: 'string', description: 'Book plugin slug, e.g. clean-code.' },
        size: { type: 'string', enum: ['nano', 'mini', 'full', 'design'], description: 'Default mini.' },
      },
      required: ['plugin'],
    },
    annotations: READ_ONLY,
  },
];

const tokens = (s) => (s.toLowerCase().match(/[a-z0-9]+/g) || []).filter((w) => w.length > 2 && !STOP.has(w));
const STOP = new Set(['the', 'and', 'for', 'with', 'that', 'this', 'when', 'use', 'how', 'into', 'from', 'are', 'you', 'your', 'can', 'what', 'need', 'want', 'make', 'have', 'has', 'not']);

function search({ query, plugin, kind, limit }) {
  limit = Number.isInteger(limit) ? Math.min(Math.max(limit, 1), 30) : 8;
  const words = [...new Set(tokens(String(query)))];
  if (!words.length) throw new RpcError(-32602, 'query needs at least one meaningful word');
  const scored = [];
  for (const e of entries) {
    if (plugin && e.plugin !== plugin) continue;
    if (kind && e.kind !== kind) continue;
    const id = e.id.toLowerCase();
    const desc = e.description.toLowerCase();
    let score = 0;
    for (const w of words) {
      if (id.includes(w)) score += 5;
      const hits = desc.split(w).length - 1;
      score += Math.min(hits, 3);
    }
    if (score > 0) scored.push({ e, score });
  }
  scored.sort((a, b) => b.score - a.score || a.e.id.localeCompare(b.e.id));
  return scored.slice(0, limit).map((x) => x.e);
}

const line = (e) => `- ${e.id} [${e.kind}${e.manual ? ', on request' : ''}] ${short(e.description, 150)}`;

function callTool(name, a) {
  switch (name) {
    case 'search_guides': {
      const hits = search(a);
      return hits.length ? `${hits.length} match(es). Fetch one with get_guide.\n${hits.map(line).join('\n')}` : 'No matching guide. Try list_guides, or different words.';
    }
    case 'get_guide': {
      const e = byId.get(String(a.id ?? ''));
      if (!e) throw new RpcError(-32602, `Unknown guide "${a.id}". Use search_guides or list_guides.`);
      return guideText(e);
    }
    case 'list_guides': {
      const rows = entries.filter((e) => (!a.plugin || e.plugin === a.plugin) && (!a.kind || e.kind === a.kind) && (a.manual === undefined || e.manual === a.manual));
      return `${rows.length} guide(s).\n${rows.map(line).join('\n')}`;
    }
    case 'get_rules': return rulesText(String(a.plugin ?? ''), a.size ?? 'mini');
    default: throw new RpcError(-32602, `Unknown tool: ${name}`);
  }
}

// ----------------------------------------------------------------------------------------------- prompts and resources
const promptEntries = entries.filter((e) => e.kind === 'agent' || e.kind === 'mode' || e.manual);
const promptByName = new Map(promptEntries.map((e) => [e.id, e]));

function promptArgs(e) {
  if (e.kind === 'agent') return [{ name: 'task', description: 'What the role should work on (paths, a diff, a question).', required: false }];
  if (e.kind === 'mode') return [];
  return [{ name: 'arguments', description: e.argumentHint ?? 'Optional arguments for the workflow.', required: false }];
}

function getPrompt(name, a) {
  if (typeof name !== 'string') throw new RpcError(-32602, 'prompts/get needs a prompt name');
  const e = promptByName.get(name);
  if (!e) throw new RpcError(-32602, `Unknown prompt "${name}"`);
  let text = guideText(e);
  if (e.kind === 'agent') text += `\n\n---\nTask: ${a.task || '(none given; ask the user what to work on)'}`;
  else if (e.kind === 'skill') text += `\n\n---\nArguments: ${a.arguments || '(empty)'}`;
  return { description: short(e.description, 200), messages: [{ role: 'user', content: { type: 'text', text } }] };
}

const resourceList = () => [
  ...entries.map((e) => ({ uri: `guided://guide/${e.id}`, name: e.id, description: short(e.description, 200), mimeType: 'text/markdown' })),
  ...books.flatMap((b) => ['nano', 'mini', 'full'].map((s) => ({ uri: `guided://rules/${b.slug}/${s}`, name: `${b.slug}-rules-${s}`, description: `${b.title} rules (${s})`, mimeType: 'text/markdown' }))),
];

function readResource(uri) {
  let m = uri.match(/^guided:\/\/guide\/(.+)$/);
  if (m) {
    const e = byId.get(m[1]);
    if (!e) throw new RpcError(-32002, `Resource not found: ${uri}`);
    return { uri, mimeType: 'text/markdown', text: guideText(e) };
  }
  m = uri.match(/^guided:\/\/rules\/([^/]+)\/(nano|mini|full)$/);
  if (m) return { uri, mimeType: 'text/markdown', text: rulesText(m[1], m[2]) };
  throw new RpcError(-32002, `Resource not found: ${uri}`);
}

// ----------------------------------------------------------------------------------------------- JSON-RPC
const isObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
// params and arguments may be absent or null; anything else that is not an object is a client error
const objectOf = (v, what) => {
  if (v === undefined || v === null) return {};
  if (!isObject(v)) throw new RpcError(-32602, `${what} must be an object`);
  return v;
};

function handle(req) {
  const { method } = req;
  const params = objectOf(req.params, 'params');
  switch (method) {
    case 'initialize': {
      const wanted = params.protocolVersion;
      return {
        protocolVersion: PROTOCOLS.includes(wanted) ? wanted : PROTOCOLS[0],
        capabilities: { tools: {}, resources: {}, prompts: {} },
        serverInfo: SERVER,
        instructions: `Guides from classic software-engineering books (${books.map((b) => b.title).join('; ')}). For a task, call search_guides, then get_guide and follow the guide. get_rules returns a book's rule set.`,
      };
    }
    case 'ping': return {};
    case 'logging/setLevel': return {};
    case 'tools/list': return { tools: TOOLS };
    case 'tools/call': {
      // an unknown tool is a protocol error (-32602); a failure inside a known tool is a tool result with isError
      if (typeof params.name !== 'string') throw new RpcError(-32602, 'tools/call needs a tool name');
      if (!TOOLS.some((t) => t.name === params.name)) throw new RpcError(-32602, `Unknown tool: ${params.name}`);
      const args = objectOf(params.arguments, 'arguments');
      try { return { content: [{ type: 'text', text: callTool(params.name, args) }] }; } catch (e) {
        if (e instanceof RpcError) return { content: [{ type: 'text', text: e.message }], isError: true };
        throw e;
      }
    }
    case 'resources/list': return { resources: resourceList() };
    case 'resources/templates/list': return { resourceTemplates: [] };
    case 'resources/read':
      if (typeof params.uri !== 'string') throw new RpcError(-32602, 'resources/read needs a uri');
      return { contents: [readResource(params.uri)] };
    case 'prompts/list': return { prompts: promptEntries.map((e) => ({ name: e.id, description: short(e.description, 200), arguments: promptArgs(e) })) };
    case 'prompts/get': return getPrompt(params.name, objectOf(params.arguments, 'arguments'));
    default: throw new RpcError(-32601, `Method not found: ${method}`);
  }
}

process.stdout.on('error', (e) => { if (e.code === 'EPIPE') process.exit(0); throw e; }); // the client went away
function writeOut(msg) { process.stdout.write(`${JSON.stringify(msg)}\n`); }
const invalid = (id) => ({ jsonrpc: '2.0', id, error: { code: -32600, message: 'Invalid Request' } });

function processOne(req) {
  if (!isObject(req)) return invalid(null);
  if (typeof req.method !== 'string') {
    // a response from the client (this server never sends requests) is ignored; anything else is malformed
    return req.jsonrpc === '2.0' && ('result' in req || 'error' in req) ? null : invalid(req.id ?? null);
  }
  if (req.jsonrpc !== '2.0') return invalid(req.id ?? null);
  const isNotification = req.id === undefined || req.id === null;
  try {
    const result = handle(req);
    return isNotification ? null : { jsonrpc: '2.0', id: req.id, result };
  } catch (e) {
    if (isNotification) return null;
    if (e instanceof RpcError) return { jsonrpc: '2.0', id: req.id, error: { code: e.code, message: e.message } };
    process.stderr.write(`guided-plugins: ${e.stack}\n`);
    return { jsonrpc: '2.0', id: req.id, error: { code: -32603, message: 'Internal error' } };
  }
}

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
rl.on('line', (raw) => {
  const text = raw.trim();
  if (!text) return;
  let msg;
  try { msg = JSON.parse(text); } catch { writeOut({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }); return; }
  if (Array.isArray(msg)) {
    if (!msg.length) { writeOut(invalid(null)); return; } // an empty batch is one error, not an empty array
    const out = msg.map(processOne).filter(Boolean);
    if (out.length) writeOut(out);
  } else {
    const out = processOne(msg);
    if (out) writeOut(out);
  }
});
// No process.exit() here: exiting while stdout is a full pipe would cut the last response. Node leaves once stdout is flushed.
process.stderr.write(`guided-plugins MCP server ready: ${entries.length} guides from ${books.length} book(s), ${promptEntries.length} prompts\n`);
