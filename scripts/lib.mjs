// Shared helpers for the validator, catalog generator and plugin scaffolder.
// Zero dependencies on purpose: this repo must validate with a bare Node install.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const PLUGINS_DIR = path.join(ROOT, 'plugins');
export const REGISTRY = JSON.parse(fs.readFileSync(path.join(ROOT, 'scripts', 'books.json'), 'utf8'));

// Hard floors from docs/PLUGIN_SPEC.md. Change them there and here together.
export const LIMITS = {
  minTotal: 50,
  minSkills: 27,
  minAgents: 18,
  minStyles: 5,
  maxModelInvocableSkills: 20,
  minManualSkills: 8,
  skillDescWarn: 300,
  skillDescMax: 500,
  agentDescWarn: 350,
  agentDescMax: 600,
  skillMinBody: 1500,
  agentMinBody: 1500,
  styleMinBody: 900,
  skillMaxLines: 500,
  readmeMinChars: 7000,
  dupError: 0.5,
  dupWarn: 0.35,
};

export const SKILL_KEYS = new Set([
  'name', 'description', 'when_to_use', 'argument-hint', 'arguments', 'disable-model-invocation',
  'user-invocable', 'allowed-tools', 'disallowed-tools', 'model', 'effort', 'context', 'agent',
  'paths', 'license',
]);
export const AGENT_KEYS = new Set([
  'name', 'description', 'model', 'effort', 'maxTurns', 'tools', 'disallowedTools', 'skills',
  'memory', 'background', 'isolation', 'color',
]);
export const STYLE_KEYS = new Set(['name', 'description', 'keep-coding-instructions', 'force-for-plugin']);
export const COLORS = new Set(['red', 'blue', 'green', 'yellow', 'purple', 'orange', 'pink', 'cyan']);
export const MODELS = new Set(['sonnet', 'opus', 'haiku', 'fable', 'inherit']);
export const EFFORTS = new Set(['low', 'medium', 'high', 'xhigh', 'max']);

// ---------------------------------------------------------------- frontmatter
// A deliberately strict YAML subset so frontmatter can never silently fail to parse in Claude Code:
//   key: "double quoted string" | true | false | 123 | bare words | [a, b] | (key: then "  - item" lines)
// Block scalars (| >) and unquoted values containing ": " or " #" are rejected.
export function parseFrontmatter(text) {
  const problems = [];
  const src = text.replace(/\r\n/g, '\n');
  if (!src.startsWith('---\n')) return { data: null, body: src, problems: ['missing opening --- frontmatter fence on line 1'] };
  const end = src.indexOf('\n---', 4);
  if (end === -1) return { data: null, body: src, problems: ['missing closing --- frontmatter fence'] };
  const raw = src.slice(4, end);
  const body = src.slice(end + 4).replace(/^\n/, '');
  const lines = raw.split('\n');
  const data = {};
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.trim() || line.trim().startsWith('#')) continue;
    if (/\t/.test(line)) { problems.push(`line ${i + 2}: tab character in frontmatter`); continue; }
    const m = line.match(/^([A-Za-z][A-Za-z0-9_-]*):(?:\s+(.*))?$/);
    if (!m) { problems.push(`line ${i + 2}: cannot parse "${line}"`); continue; }
    const key = m[1];
    const val = (m[2] ?? '').trim();
    if (key in data) problems.push(`line ${i + 2}: duplicate key "${key}"`);
    if (val === '') {
      const items = [];
      const map = {};
      let j = i + 1;
      if (j < lines.length && /^\s+[A-Za-z][A-Za-z0-9_-]*:\s+\S/.test(lines[j])) {
        // one level of nested map, e.g. the Agent Skills "metadata:" block
        while (j < lines.length && /^\s+[A-Za-z][A-Za-z0-9_-]*:\s+\S/.test(lines[j])) {
          const mm = lines[j].match(/^\s+([A-Za-z][A-Za-z0-9_-]*):\s+(.*)$/);
          map[mm[1]] = scalar(mm[2].trim(), problems, j + 2);
          j++;
        }
        data[key] = map;
        i = j - 1;
        continue;
      }
      while (j < lines.length && /^\s+-\s+\S/.test(lines[j])) {
        items.push(scalar(lines[j].replace(/^\s+-\s+/, '').trim(), problems, j + 2));
        j++;
      }
      data[key] = items.length ? items : '';
      i = j - 1;
      continue;
    }
    data[key] = scalar(val, problems, i + 2);
  }
  return { data, body, problems };
}

function scalar(val, problems, lineNo) {
  if (val.startsWith('"')) {
    try { return JSON.parse(val); } catch { problems.push(`line ${lineNo}: invalid double-quoted string`); return val; }
  }
  if (val.startsWith('[') && val.endsWith(']')) {
    return val.slice(1, -1).split(',').map((s) => s.trim()).filter(Boolean).map((s) => scalar(s, problems, lineNo));
  }
  if (/^[|>]/.test(val)) { problems.push(`line ${lineNo}: block scalars (| >) are not allowed; use a double-quoted string`); return val; }
  if (/^[\[\]{}&*!'%@`]/.test(val) || /:\s/.test(val) || /\s#/.test(val) || val.endsWith(':')) {
    problems.push(`line ${lineNo}: unquoted value needs double quotes: ${val.slice(0, 50)}`);
    return val;
  }
  if (val === 'true') return true;
  if (val === 'false') return false;
  if (/^-?\d+$/.test(val)) return Number(val);
  return val;
}

// "Read, Grep, Bash(git diff *)" -> ['Read','Grep','Bash(git diff *)']
export function toList(v) {
  if (v == null || v === '') return [];
  if (Array.isArray(v)) return v.map(String);
  const out = []; let depth = 0; let cur = '';
  for (const ch of String(v)) {
    if (ch === '(') depth++;
    if (ch === ')') depth--;
    if (ch === ',' && depth === 0) { out.push(cur.trim()); cur = ''; } else cur += ch;
  }
  if (cur.trim()) out.push(cur.trim());
  return out;
}

// ---------------------------------------------------------------- plugin loading
export function readIf(p) { try { return fs.readFileSync(p, 'utf8'); } catch { return null; } }
export function listDir(p) { try { return fs.readdirSync(p, { withFileTypes: true }); } catch { return []; } }

export function loadPlugin(dir) {
  const abs = path.resolve(dir);
  const plugin = { dir: abs, slug: path.basename(abs), manifest: null, manifestError: null, skills: [], agents: [], styles: [] };
  const mtext = readIf(path.join(abs, '.claude-plugin', 'plugin.json'));
  if (mtext == null) plugin.manifestError = 'missing .claude-plugin/plugin.json';
  else { try { plugin.manifest = JSON.parse(mtext); } catch (e) { plugin.manifestError = `invalid JSON: ${e.message}`; } }

  for (const d of listDir(path.join(abs, 'skills'))) {
    if (!d.isDirectory()) continue;
    const file = path.join(abs, 'skills', d.name, 'SKILL.md');
    const text = readIf(file);
    if (text == null) { plugin.skills.push({ kind: 'skill', id: d.name, file, missing: true }); continue; }
    plugin.skills.push({ kind: 'skill', id: d.name, file, text, ...parseFrontmatter(text) });
  }
  for (const f of listDir(path.join(abs, 'agents'))) {
    if (!f.isFile() || !f.name.endsWith('.md')) continue;
    const file = path.join(abs, 'agents', f.name);
    const text = readIf(file);
    plugin.agents.push({ kind: 'agent', id: f.name.replace(/\.md$/, ''), file, text, ...parseFrontmatter(text) });
  }
  for (const f of listDir(path.join(abs, 'output-styles'))) {
    if (!f.isFile() || !f.name.endsWith('.md')) continue;
    const file = path.join(abs, 'output-styles', f.name);
    const text = readIf(file);
    plugin.styles.push({ kind: 'style', id: f.name.replace(/\.md$/, ''), file, text, ...parseFrontmatter(text) });
  }
  plugin.skills.sort((a, b) => a.id.localeCompare(b.id));
  plugin.agents.sort((a, b) => a.id.localeCompare(b.id));
  plugin.styles.sort((a, b) => a.id.localeCompare(b.id));
  return plugin;
}

export function listPluginDirs() {
  return listDir(PLUGINS_DIR).filter((d) => d.isDirectory()).map((d) => path.join(PLUGINS_DIR, d.name)).sort();
}

// ---------------------------------------------------------------- source traceability
export function norm(s) {
  return String(s).toLowerCase().replace(/[`*_]/g, '').replace(/^\d+(\.\d+)*[.)]?\s+/, '')
    .replace(/[:.]+$/, '').replace(/\s+/g, ' ').trim();
}

// Headings of references/full.md (outside code fences). Returns {all:Set(norm), coverage:[{raw,key}]}.
export function fullHeadings(fullText) {
  const heads = [];
  let fence = false;
  for (const line of fullText.replace(/\r\n/g, '\n').split('\n')) {
    if (/^\s*```/.test(line)) { fence = !fence; continue; }
    if (fence) continue;
    const m = line.match(/^(#{2,3})\s+(.+?)\s*$/);
    if (m) heads.push({ level: m[1].length, raw: m[2], key: norm(m[2]) });
  }
  const l2 = heads.filter((h) => h.level === 2);
  const coverage = l2.length >= 5 ? l2 : heads;
  return { all: new Set(heads.map((h) => h.key)), coverage };
}

// The "## Source" section of a component body -> array of cited heading strings.
// A citation is the first backticked token at the start of a bullet; text after it (notes) may contain anything.
export function sourceCitations(body) {
  const m = body.match(/(?:^|\n)##\s+Source[^\n]*\n([\s\S]*?)(?=\n##\s|\s*$)/i);
  if (!m) return null;
  const out = [];
  for (const line of m[1].split('\n')) {
    const t = line.match(/^\s*[-*]\s+`([^`\n]+)`/);
    if (t) out.push(t[1].trim());
  }
  return out;
}

// ---------------------------------------------------------------- text similarity
export function words(text) { return (text.toLowerCase().match(/[a-z0-9']+/g) || []); }
export function shingles(ws, n) {
  const s = new Set();
  for (let i = 0; i + n <= ws.length; i++) s.add(ws.slice(i, i + n).join(' '));
  return s;
}
export function jaccard(a, b) {
  if (!a.size || !b.size) return 0;
  let inter = 0;
  for (const x of a) if (b.has(x)) inter++;
  return inter / (a.size + b.size - inter);
}

export function componentInvocation(plugin, c) {
  const n = plugin.manifest?.name ?? plugin.slug;
  if (c.kind === 'skill') return `/${n}:${c.data?.name ?? c.id}`;
  if (c.kind === 'agent') return `@agent-${n}:${c.data?.name ?? c.id}`;
  return `/output-style ${n}:${c.data?.name ?? c.id}`;
}

export function oneLine(s, max = 160) {
  const t = String(s ?? '').replace(/\s+/g, ' ').trim();
  if (t.length <= max) return t;
  // cut at a word boundary so a <slug>:<name> reference is never split mid-token
  const cut = t.slice(0, max - 1);
  const at = cut.lastIndexOf(' ');
  return `${(at > max * 0.5 ? cut.slice(0, at) : cut).replace(/[\s,;:(\-]+$/, '')}…`;
}
