#!/usr/bin/env node
// guided-plugins MCP server: serves the 14 book toolkits (skills, modes, subagent prompts, rule files) to ANY MCP-capable agent.
// Zero dependencies, stdio transport (newline-delimited JSON-RPC 2.0).
//
//   node scripts/mcp-server.mjs                          # everything
//   node scripts/mcp-server.mjs --plugins clean-code,refactoring     # only these books (also GUIDED_PLUGINS=clean-code,refactoring)
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
const SERVER = { name: 'guided-plugins', version: '1.1.0' };
const PROTOCOLS = ['2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05'];

// ----------------------------------------------------------------------------------------------- catalog
const args = process.argv.slice(2);
const opt = (name, env) => {
  const i = args.indexOf(`--${name}`);
  const v = i >= 0 ? args[i + 1] : process.env[env];
  return v ? v.split(',').map((s) => s.trim()).filter(Boolean) : null;
};
const onlyPlugins = opt('plugins', 'GUIDED_PLUGINS');
const onlyKinds = opt('kinds', 'GUIDED_KINDS');

let catalog;
try { catalog = JSON.parse(fs.readFileSync(path.join(DIST, 'mcp', 'catalog.json'), 'utf8')); } catch (e) {
  process.stderr.write(`guided-plugins: cannot read dist/mcp/catalog.json (${e.message}). Run: node scripts/build-targets.mjs\n`);
  process.exit(1);
}
if (onlyPlugins) {
  const known = new Set(catalog.books.map((b) => b.slug));
  const unknown = onlyPlugins.filter((p) => !known.has(p));
  if (unknown.length) { process.stderr.write(`guided-plugins: unknown plugin(s): ${unknown.join(', ')}. Known: ${[...known].join(', ')}\n`); process.exit(1); }
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
  const rel = b.rules[size];
  if (!rel) throw new RpcError(-32602, `Unknown size "${size}". Use nano, mini, full or design.`);
  return read(rel);
}

// ----------------------------------------------------------------------------------------------- tools
class RpcError extends Error { constructor(code, message) { super(message); this.code = code; } }

const kindEnum = ['skill', 'mode', 'agent'];
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
  },
  {
    name: 'get_guide',
    description: 'Return the full text of one guide by id (a skill, mode or subagent prompt), e.g. "clean-code-review". Follow it as instructions for the task at hand.',
    inputSchema: { type: 'object', properties: { id: { type: 'string', description: 'Guide id from search_guides or list_guides.' } }, required: ['id'] },
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
  },
  {
    name: 'get_rules',
    description: 'Return a book\'s rule set as plain text: nano (smallest, always-on), mini (recommended working set), full (complete reference) or design (the plugin component map).',
    inputSchema: {
      type: 'object',
      properties: {
        plugin: { type: 'string', description: 'Book plugin slug, e.g. clean-code.' },
        size: { type: 'string', enum: ['nano', 'mini', 'full', 'design'], description: 'Default mini.' },
      },
      required: ['plugin'],
    },
  },
];

const tokens = (s) => (s.toLowerCase().match(/[a-z0-9]+/g) || []).filter((w) => w.length > 2 && !STOP.has(w));
const STOP = new Set(['the', 'and', 'for', 'with', 'that', 'this', 'when', 'use', 'how', 'into', 'from', 'are', 'you', 'your', 'can', 'what', 'need', 'want', 'make', 'have', 'has', 'not']);

function search({ query, plugin, kind, limit = 8 }) {
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

function callTool(name, a = {}) {
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
    default: throw new RpcError(-32602, `Unknown tool "${name}"`);
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

function getPrompt(name, a = {}) {
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
function handle(req) {
  const { method, params = {} } = req;
  switch (method) {
    case 'initialize': {
      const wanted = params.protocolVersion;
      return {
        protocolVersion: PROTOCOLS.includes(wanted) ? wanted : PROTOCOLS[1],
        capabilities: { tools: {}, resources: {}, prompts: {} },
        serverInfo: SERVER,
        instructions: `Guides from classic software-engineering books (${books.map((b) => b.title).join('; ')}). For a task, call search_guides, then get_guide and follow the guide. get_rules returns a book's rule set.`,
      };
    }
    case 'ping': return {};
    case 'logging/setLevel': return {};
    case 'tools/list': return { tools: TOOLS };
    case 'tools/call': {
      try { return { content: [{ type: 'text', text: callTool(params.name, params.arguments) }] }; } catch (e) {
        if (e instanceof RpcError) return { content: [{ type: 'text', text: e.message }], isError: true };
        throw e;
      }
    }
    case 'resources/list': return { resources: resourceList() };
    case 'resources/templates/list': return { resourceTemplates: [] };
    case 'resources/read': return { contents: [readResource(params.uri)] };
    case 'prompts/list': return { prompts: promptEntries.map((e) => ({ name: e.id, description: short(e.description, 200), arguments: promptArgs(e) })) };
    case 'prompts/get': return getPrompt(params.name, params.arguments);
    default: throw new RpcError(-32601, `Method not found: ${method}`);
  }
}

function respond(msg) { process.stdout.write(`${JSON.stringify(msg)}\n`); }

function process_(req) {
  if (req === null || typeof req !== 'object' || req.jsonrpc !== '2.0' || typeof req.method !== 'string') {
    return req && req.id !== undefined ? { jsonrpc: '2.0', id: req.id, error: { code: -32600, message: 'Invalid Request' } } : null;
  }
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
  try { msg = JSON.parse(text); } catch { respond({ jsonrpc: '2.0', id: null, error: { code: -32700, message: 'Parse error' } }); return; }
  if (Array.isArray(msg)) {
    const out = msg.map(process_).filter(Boolean);
    if (out.length) respond(out);
  } else {
    const out = process_(msg);
    if (out) respond(out);
  }
});
rl.on('close', () => process.exit(0));
process.stderr.write(`guided-plugins MCP server ready: ${entries.length} guides from ${books.length} book(s), ${promptEntries.length} prompts\n`);
