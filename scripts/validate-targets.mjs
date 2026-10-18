#!/usr/bin/env node
// Validates the generated per-agent builds under dist/ against what each agent actually accepts (constraints verified in
// docs/AGENTS_SUPPORT.md). Fast and dependency-free; the real-tool checks live in the CI workflow.
//   node scripts/validate-targets.mjs
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { REGISTRY, ROOT, listDir, parseFrontmatter, readIf } from './lib.mjs';
import { loadModel, leftovers } from './targets/core.mjs';

const DIST = path.join(ROOT, 'dist');

export function validateTargets() {
  const errors = [];
  const err = (where, msg) => errors.push(`${where}: ${msg}`);
  const model = loadModel();
  const slugs = model.map((p) => p.slug);
  const kebab = /^[a-z0-9]+(-[a-z0-9]+)*$/;
  const exists = (p) => fs.existsSync(p);
  const rel = (p) => path.relative(ROOT, p);
  const sha = (p) => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
  const totalSkills = model.reduce((n, p) => n + p.skills.length + p.styles.length, 0);
  const totalAgents = model.reduce((n, p) => n + p.agents.length, 0);

  for (const t of ['agent-skills', 'codex', 'opencode', 'gemini', 'cursor', 'copilot', 'rules', 'mcp']) {
    if (!exists(path.join(DIST, t))) { err(`dist/${t}`, 'missing; run: node scripts/build-targets.mjs'); }
  }
  if (errors.length) return errors;

  const noLeftovers = (file, text, opts) => { for (const l of leftovers(text, slugs, opts)) err(rel(file), `Claude-specific construct survived: ${l}`); };
  const SPEC_KEYS = new Set(['name', 'description', 'license', 'compatibility', 'metadata', 'allowed-tools']);

  // ---------------------------------------------------------------- universal Agent Skills
  const universalHash = new Map(); // "<plugin>/<skill>" -> sha of SKILL.md
  const allNames = new Set();
  let universalCount = 0;
  for (const slug of slugs) {
    const root = path.join(DIST, 'agent-skills', slug);
    for (const e of listDir(root).filter((x) => x.isDirectory())) {
      const file = path.join(root, e.name, 'SKILL.md');
      universalCount++;
      const text = readIf(file);
      if (text == null) { err(rel(path.join(root, e.name)), 'SKILL.md missing'); continue; }
      const { data, problems } = parseFrontmatter(text);
      for (const p of problems) err(rel(file), `frontmatter: ${p}`);
      if (!data) continue;
      if (data.name !== e.name) err(rel(file), `name "${data.name}" must equal the folder "${e.name}"`);
      if (!kebab.test(e.name) || e.name.length > 64) err(rel(file), 'name must be lowercase kebab-case, at most 64 characters');
      if (!e.name.startsWith(`${slug}-`)) err(rel(file), `name must start with the plugin slug "${slug}-"`);
      if (allNames.has(e.name)) err(rel(file), `duplicate skill name ${e.name} across plugins`);
      allNames.add(e.name);
      if (!data.description || data.description.length > 1024) err(rel(file), 'description must be 1-1024 characters');
      for (const k of Object.keys(data)) if (!SPEC_KEYS.has(k)) err(rel(file), `frontmatter key "${k}" is not part of the Agent Skills spec`);
      noLeftovers(file, text);
      universalHash.set(`${slug}/${e.name}`, sha(file));
      // relative links to sibling skills and reference files must resolve
      for (const m of text.matchAll(/(?:\.\.\/[a-z0-9-]+\/SKILL\.md|(?:\.\.\/[a-z0-9-]+\/)?references\/(?:full|mini|nano|design)\.md)/g)) {
        if (!exists(path.resolve(root, e.name, m[0]))) err(rel(file), `relative path does not resolve: ${m[0]}`);
      }
    }
    for (const f of ['full', 'mini', 'nano']) {
      const src = path.join(DIST, 'agent-skills', slug, `${slug}-principles`, 'references', `${f}.md`);
      const orig = path.join(ROOT, 'plugins', slug, 'skills', 'principles', 'references', `${f}.md`);
      if (!exists(src) || sha(src) !== sha(orig)) err(rel(src), 'vendored upstream rule file is missing or differs from plugins/');
    }
  }
  if (universalCount !== totalSkills) err('dist/agent-skills', `${universalCount} skill folders, expected ${totalSkills}`);

  // ---------------------------------------------------------------- flat targets reuse the universal skills byte for byte
  for (const t of ['opencode', 'gemini', 'cursor', 'copilot']) {
    for (const slug of slugs) {
      const root = path.join(DIST, t, slug, 'skills');
      const dirs = listDir(root).filter((x) => x.isDirectory());
      if (dirs.length !== model.find((p) => p.slug === slug).skills.length + model.find((p) => p.slug === slug).styles.length) err(rel(root), `expected the same skill folders as agent-skills, found ${dirs.length}`);
      for (const e of dirs) {
        const h = universalHash.get(`${slug}/${e.name}`);
        const file = path.join(root, e.name, 'SKILL.md');
        if (!exists(file) || sha(file) !== h) err(rel(file), 'differs from dist/agent-skills (flat targets must be byte-identical)');
      }
    }
  }

  // ---------------------------------------------------------------- Codex
  const codexRoles = new Set();
  for (const slug of slugs) {
    const root = path.join(DIST, 'codex', slug);
    let man;
    try { man = JSON.parse(readIf(path.join(root, '.codex-plugin', 'plugin.json'))); } catch (e) { err(rel(root), `.codex-plugin/plugin.json: ${e.message}`); continue; }
    if (man.name !== slug || man.skills !== './skills/') err(rel(root), 'plugin.json name/skills wrong');
    for (const d of man.interface?.defaultPrompt ?? []) if (d.length > 128) err(rel(root), `defaultPrompt over 128 chars: ${d}`);
    if ((man.interface?.defaultPrompt ?? []).length > 3) err(rel(root), 'more than 3 defaultPrompt entries');
    const model1 = model.find((p) => p.slug === slug);
    const skillDirs = listDir(path.join(root, 'skills')).filter((x) => x.isDirectory());
    if (skillDirs.length !== model1.skills.length + model1.styles.length) err(rel(root), `expected ${model1.skills.length + model1.styles.length} skills, found ${skillDirs.length}`);
    for (const e of skillDirs) {
      const file = path.join(root, 'skills', e.name, 'SKILL.md');
      const text = readIf(file) ?? '';
      const { data, problems } = parseFrontmatter(text);
      for (const p of problems) err(rel(file), `frontmatter: ${p}`);
      if (!data || data.name !== e.name || e.name.length > 64) err(rel(file), 'name must equal the folder and be at most 64 characters');
      if (!data?.description) err(rel(file), 'description required');
      noLeftovers(file, text, { mentions: true });
      const manual = /Run only when the user asks for it by name\.\s*$/.test(data?.description ?? '');
      const yamlFile = path.join(root, 'skills', e.name, 'agents', 'openai.yaml');
      if (manual && !(readIf(yamlFile) ?? '').includes('allow_implicit_invocation: false')) err(rel(file), 'manual skill needs agents/openai.yaml with allow_implicit_invocation: false');
      for (const m of text.matchAll(/\.\.\/([a-z0-9-]+)\/SKILL\.md|(?:\.\.\/principles\/)?references\/(?:full|mini|nano|design)\.md/g)) {
        if (!exists(path.resolve(root, 'skills', e.name, m[0]))) err(rel(file), `relative path does not resolve: ${m[0]}`);
      }
    }
  }
  const agentDir = path.join(DIST, 'codex', 'agents');
  const tomls = listDir(agentDir).filter((e) => e.name.endsWith('.toml'));
  if (tomls.length !== totalAgents) err(rel(agentDir), `${tomls.length} role files, expected ${totalAgents}`);
  for (const e of tomls) {
    const text = readIf(path.join(agentDir, e.name));
    const base = e.name.replace(/\.toml$/, '');
    const name = text.match(/^name = "([^"]+)"$/m)?.[1];
    if (name !== base) err(rel(path.join(agentDir, e.name)), `name "${name}" must equal the file name`);
    if (codexRoles.has(name)) err(rel(path.join(agentDir, e.name)), 'duplicate role name');
    codexRoles.add(name);
    if (!/^description = "/m.test(text) || !/^developer_instructions = ('''|""")\n[\s\S]+\n\1$/m.test(text)) err(rel(path.join(agentDir, e.name)), 'needs description and a multi-line developer_instructions');
    const keys = [...text.matchAll(/^([a-z_]+) = /gm)].map((m) => m[1]);
    for (const k of keys) if (!['name', 'description', 'developer_instructions'].includes(k)) err(rel(path.join(agentDir, e.name)), `key "${k}" would make Codex reject the file`);
    noLeftovers(path.join(agentDir, e.name), text, { mentions: true });
  }
  const cm = readIf(path.join(ROOT, '.agents', 'plugins', 'marketplace.json'));
  try {
    const m = JSON.parse(cm);
    if (m.name !== REGISTRY.marketplace.name) err('.agents/plugins/marketplace.json', 'name must match the Claude marketplace');
    if (m.plugins.length !== slugs.length) err('.agents/plugins/marketplace.json', 'plugin count mismatch');
    for (const p of m.plugins) if (!exists(path.join(ROOT, p.source.path))) err('.agents/plugins/marketplace.json', `missing source ${p.source.path}`);
  } catch (e) { err('.agents/plugins/marketplace.json', e.message); }

  // ---------------------------------------------------------------- OpenCode
  const FORBIDDEN_OC = ['tools', 'color', 'model', 'maxTurns', 'disallowedTools', 'skills', 'hooks', 'mcpServers', 'permissionMode'];
  for (const slug of slugs) {
    const dir = path.join(DIST, 'opencode', slug, 'agents');
    const m1 = model.find((p) => p.slug === slug);
    const files = listDir(dir).filter((e) => e.name.endsWith('.md'));
    if (files.length !== m1.agents.length + m1.styles.length) err(rel(dir), `expected ${m1.agents.length + m1.styles.length} agent files, found ${files.length}`);
    for (const e of files) {
      const file = path.join(dir, e.name);
      const text = readIf(file);
      // OpenCode's permission map nests deeper than the shared parser reads, so check the top-level keys directly
      const block = text.match(/^---\n([\s\S]*?)\n---\n/)?.[1];
      if (!block) { err(rel(file), 'missing frontmatter'); continue; }
      const keys = [...block.matchAll(/^([A-Za-z][\w-]*):/gm)].map((m) => m[1]);
      const mode = block.match(/^mode: (\w+)\s*$/m)?.[1];
      const data = { mode, ...Object.fromEntries(keys.map((k) => [k, true])) };
      if (!keys.includes('description') || !['subagent', 'primary'].includes(mode)) err(rel(file), 'needs description and mode subagent|primary');
      for (const k of FORBIDDEN_OC) if (keys.includes(k)) err(rel(file), `"${k}" breaks OpenCode V1 config validation`);
      if (!/^[a-z0-9]+(-[a-z0-9]+)*\.md$/.test(e.name)) err(rel(file), 'agent id (file name) must be kebab-case');
      if (!e.name.startsWith(`${slug}-`)) err(rel(file), 'agent id must start with the plugin slug');
      noLeftovers(file, text);
      const m = m1.agents.find((a) => `${slug}-${a.name}.md` === e.name);
      if (m?.readOnly && !/edit: deny/.test(text)) err(rel(file), 'read-only role must deny edit');
      if (data.mode === 'subagent' && !/webfetch: deny/.test(text)) err(rel(file), 'must deny webfetch');
    }
  }

  // ---------------------------------------------------------------- Gemini CLI
  const GEM_AGENT_KEYS = new Set(['kind', 'name', 'description', 'display_name', 'tools', 'mcp_servers', 'model', 'temperature', 'max_turns', 'timeout_mins']);
  const GEM_TOOLS = new Set(['read_file', 'read_many_files', 'list_directory', 'glob', 'grep_search', 'run_shell_command', 'write_file', 'replace', 'google_web_search', 'web_fetch', 'write_todos', 'activate_skill', 'ask_user']);
  const geminiNames = new Set();
  for (const slug of slugs) {
    const root = path.join(DIST, 'gemini', slug);
    let man;
    try { man = JSON.parse(readIf(path.join(root, 'gemini-extension.json'))); } catch (e) { err(rel(root), `gemini-extension.json: ${e.message}`); continue; }
    if (!/^[a-zA-Z0-9-]+$/.test(man.name) || !man.version) err(rel(root), 'extension name/version invalid');
    for (const e of listDir(path.join(root, 'agents')).filter((x) => x.name.endsWith('.md'))) {
      const file = path.join(root, 'agents', e.name);
      const text = readIf(file);
      const { data, problems } = parseFrontmatter(text);
      for (const p of problems) err(rel(file), `frontmatter: ${p}`);
      if (!data) continue;
      for (const k of Object.keys(data)) if (!GEM_AGENT_KEYS.has(k)) err(rel(file), `key "${k}" is rejected by Gemini's strict agent schema`);
      if (!/^[a-z0-9_-]+$/.test(data.name ?? '') || `${data.name}.md` !== e.name) err(rel(file), 'agent name must be [a-z0-9_-]+ and equal the file name');
      if (geminiNames.has(data.name)) err(rel(file), 'duplicate agent name');
      geminiNames.add(data.name);
      if (!Array.isArray(data.tools) || !data.tools.every((t) => GEM_TOOLS.has(t))) err(rel(file), `tools must be a YAML array of valid Gemini tool names (got ${JSON.stringify(data.tools)})`);
      const m1 = model.find((p) => p.slug === slug).agents.find((a) => `${slug}-${a.name}` === data.name);
      if (m1?.readOnly && data.tools?.some((t) => ['write_file', 'replace'].includes(t))) err(rel(file), 'read-only role must not list write tools');
      noLeftovers(file, text.replace(/\$\{extensionPath\}/g, ''));
    }
  }

  // ---------------------------------------------------------------- Cursor and Copilot (experimental, structural checks)
  for (const slug of slugs) {
    for (const [t, manifest] of [['cursor', '.cursor-plugin/plugin.json'], ['copilot', 'plugin.json']]) {
      const root = path.join(DIST, t, slug);
      try { const m = JSON.parse(readIf(path.join(root, manifest))); if (m.name !== slug) err(rel(root), `${manifest} name wrong`); } catch (e) { err(rel(root), `${manifest}: ${e.message}`); }
      for (const e of listDir(path.join(root, 'agents')).filter((x) => x.isFile())) {
        const file = path.join(root, 'agents', e.name);
        const text = readIf(file);
        const { data, problems } = parseFrontmatter(text);
        for (const p of problems) err(rel(file), `frontmatter: ${p}`);
        if (!data?.description) err(rel(file), 'description required');
        for (const k of ['maxTurns', 'color', 'disallowedTools', 'skills']) if (data && k in data) err(rel(file), `"${k}" is Claude-only`);
        noLeftovers(file, text);
      }
    }
  }
  for (const f of ['.cursor-plugin/marketplace.json']) {
    try { const m = JSON.parse(readIf(path.join(ROOT, f))); for (const p of m.plugins) if (!exists(path.join(ROOT, p.source))) err(f, `missing source ${p.source}`); } catch (e) { err(f, e.message); }
  }

  // ---------------------------------------------------------------- rules and MCP catalog
  for (const slug of slugs) {
    for (const size of ['nano', 'mini']) {
      const file = path.join(DIST, 'rules', slug, `AGENTS.${size}.md`);
      const text = readIf(file);
      if (!text) { err(rel(file), 'missing'); continue; }
      if (Buffer.byteLength(text) > 16 * 1024) err(rel(file), 'over 16 KiB; too large for an always-on rules file');
      noLeftovers(file, text);
    }
  }
  try {
    const cat = JSON.parse(readIf(path.join(DIST, 'mcp', 'catalog.json')));
    const ids = new Set();
    for (const e of cat.entries) {
      if (ids.has(e.id)) err('dist/mcp/catalog.json', `duplicate id ${e.id}`);
      ids.add(e.id);
      if (!exists(path.join(DIST, e.file))) err('dist/mcp/catalog.json', `missing file for ${e.id}: ${e.file}`);
    }
    if (cat.entries.length !== totalSkills + totalAgents) err('dist/mcp/catalog.json', `${cat.entries.length} entries, expected ${totalSkills + totalAgents}`);
    for (const b of cat.books) for (const f of Object.values(b.rules)) if (!exists(path.join(DIST, f))) err('dist/mcp/catalog.json', `missing rules file ${f}`);
  } catch (e) { err('dist/mcp/catalog.json', e.message); }
  for (const e of listDir(path.join(DIST, 'mcp', 'agents')).filter((x) => x.name.endsWith('.md'))) noLeftovers(path.join(DIST, 'mcp', 'agents', e.name), readIf(path.join(DIST, 'mcp', 'agents', e.name)) ?? '');

  return errors;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const errors = validateTargets();
  for (const e of errors.slice(0, 60)) console.log(`ERROR ${e}`);
  if (errors.length > 60) console.log(`... and ${errors.length - 60} more`);
  console.log(errors.length ? `FAIL targets: ${errors.length} errors` : 'PASS targets: all generated builds satisfy their agents\' constraints');
  process.exit(errors.length ? 1 : 0);
}
