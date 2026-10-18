#!/usr/bin/env node
// Validates the generated per-agent builds under dist/ against what each agent actually accepts (constraints verified in
// docs/AGENTS_SUPPORT.md). Fast and dependency-free; the real-tool checks live in the CI workflow.
//   node scripts/validate-targets.mjs
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { REGISTRY, ROOT, VERSION, listDir, parseFrontmatter, readIf } from './lib.mjs';
import { loadModel, leftovers, flat, modeName, referencesDesign, READ_ONLY_ALLOW, READ_ONLY_DENY } from './targets/core.mjs';
import { codexRolesOf } from './install-lib.mjs';

// OpenCode's wildcard: "*" matches anything; a trailing " *" also matches the bare command; the LAST matching rule wins.
function opencodeDecision(rules, command) {
  let verdict = 'ask';
  for (const [pattern, action] of rules) {
    let re = pattern.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\?/g, '.');
    if (re.endsWith(' .*')) re = `${re.slice(0, -3)}( .*)?`;
    if (new RegExp(`^${re}$`, 's').test(command)) verdict = action;
  }
  return verdict;
}
// "Bash only for `git diff|log|show|status`, `ls` and `grep`." -> ["git diff", "git log", "git show", "git status", "ls", "grep"]
function commandsNamedIn(text) {
  const line = text.split('\n').find((l) => /Bash only for/.test(l));
  if (!line) return [];
  const sentence = line.slice(line.indexOf('Bash only for')).split(/\.(?:\s|$)/)[0];
  const out = [];
  for (const [, tok] of sentence.matchAll(/`([^`]+)`/g)) {
    const m = tok.match(/^(git) ([a-z-]+(?:\|[a-z-]+)+)$/);
    if (m) out.push(...m[2].split('|').map((a) => `git ${a}`)); else out.push(tok);
  }
  return out;
}

const DIST = path.join(ROOT, 'dist');
const CAPITALISED_VERB = /[,;] (?:Read|Load|Fetch) (?:the |`)/;

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
  const expectedSkillNames = (slug) => {
    const m = model.find((p) => p.slug === slug);
    return new Set([...m.skills.map((x) => flat(slug, x.name)), ...m.styles.map((x) => flat(slug, modeName(x.name)))]);
  };
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
      if (!expectedSkillNames(slug).has(e.name)) err(rel(file), `"${e.name}" is not a skill or mode of the plugin "${slug}"`);
      if (allNames.has(e.name)) err(rel(file), `duplicate skill name ${e.name} across plugins`);
      allNames.add(e.name);
      if (!data.description || data.description.length > 1024) err(rel(file), 'description must be 1-1024 characters');
      for (const k of Object.keys(data)) if (!SPEC_KEYS.has(k)) err(rel(file), `frontmatter key "${k}" is not part of the Agent Skills spec`);
      noLeftovers(file, text);
      if (CAPITALISED_VERB.test(text)) err(rel(file), `capitalised verb in mid-sentence: "${text.match(CAPITALISED_VERB)[0]}"`);
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
  // A plugin's roles are selected by the plugin named in each file, never by a name prefix ("ddd" prefixes "ddd-distilled").
  const claimed = new Set();
  for (const m of model) {
    const want = m.agents.map((a) => `${flat(m.slug, a.name)}.toml`).sort();
    const got = codexRolesOf(m.slug).sort();
    if (JSON.stringify(want) !== JSON.stringify(got)) err('scripts/install-codex-agents.mjs', `selects ${got.length} role files for "${m.slug}", expected exactly its ${want.length}`);
    got.forEach((f) => claimed.add(f));
  }
  if (claimed.size !== tomls.length) err(rel(agentDir), `${claimed.size} of ${tomls.length} role files belong to exactly one plugin`);
  for (const e of tomls) if (/^description = ".*\bUse proactively\b/m.test(readIf(path.join(agentDir, e.name)) ?? '')) err(rel(path.join(agentDir, e.name)), 'description promises proactive use, which Codex does not do');
  for (const slug of slugs) {
    const man = readIf(path.join(DIST, 'codex', slug, '.codex-plugin', 'plugin.json')) ?? '';
    if (/Claude Code/.test(man)) err(`dist/codex/${slug}/.codex-plugin/plugin.json`, 'describes the plugin as a Claude Code toolkit');
    for (const e of listDir(path.join(DIST, 'codex', slug, 'skills')).filter((x) => x.isDirectory())) {
      const y = readIf(path.join(DIST, 'codex', slug, 'skills', e.name, 'agents', 'openai.yaml'));
      const prompt = y?.match(/^  default_prompt: (".*")$/m)?.[1];
      if (prompt && !/^"Use \$[a-z0-9-]+:[a-z0-9-]+\.?"$/.test(prompt)) err(`dist/codex/${slug}/skills/${e.name}/agents/openai.yaml`, `default_prompt should be "Use $plugin:skill.", got ${prompt}`);
    }
  }
  const cm = readIf(path.join(ROOT, '.agents', 'plugins', 'marketplace.json'));
  try {
    const m = JSON.parse(cm);
    if (m.name !== REGISTRY.marketplace.name) err('.agents/plugins/marketplace.json', 'name must match the Claude marketplace');
    if (m.plugins.length !== slugs.length) err('.agents/plugins/marketplace.json', 'plugin count mismatch');
    for (const p of m.plugins) if (!exists(path.join(ROOT, p.source.path))) err('.agents/plugins/marketplace.json', `missing source ${p.source.path}`);
  } catch (e) { err('.agents/plugins/marketplace.json', e.message); }

  // ---------------------------------------------------------------- OpenCode
  // The read-only roles get a shell allowlist. It is a guard rail, not a sandbox, but it must at least refuse the obvious ways of writing.
  const expectedRules = [['*', 'deny'], ...READ_ONLY_ALLOW.map((c) => [c, 'allow']), ...READ_ONLY_DENY.map((c) => [c, 'deny'])];
  const SHOULD_ALLOW = ['git diff', 'git diff --stat', 'git diff HEAD~1 -- src', 'git log -n 5', 'git show HEAD', 'git status', 'git branch --show-current', 'git ls-files', 'ls', 'ls -la src',
    'grep -rn foo src', 'rg foo', 'wc -l a.txt', 'head -n 5 a.txt', 'tail -n 5 a.txt', 'find . -name "*.ts"', 'git blame a.txt'];
  const SHOULD_DENY = ['git diff --output=victim.txt', 'git diff --output victim.txt', 'git log -p --output=v.txt', 'git diff --ext-diff', 'ls > notes.txt', 'ls >> notes.txt', 'grep foo > f', 'git diff > src/app.ts',
    'rg --pre ./evil.sh x', 'find . -delete', 'find . -exec rm {} ;', 'find . -fprint out.txt', 'lsblk', 'git push', 'git branch -D x', 'git checkout .', 'git -c core.pager=sh log', 'rm -rf x', 'cat a.txt', 'sed -i s/a/b/ f'];
  for (const c of SHOULD_ALLOW) if (opencodeDecision(expectedRules, c) !== 'allow') err('scripts/targets/core.mjs', `read-only shell rules must allow "${c}"`);
  for (const c of SHOULD_DENY) if (opencodeDecision(expectedRules, c) !== 'deny') err('scripts/targets/core.mjs', `read-only shell rules must deny "${c}"`);
  const FORBIDDEN_OC = ['tools', 'color', 'model', 'maxTurns', 'disallowedTools', 'skills', 'hooks', 'mcpServers', 'permissionMode'];
  for (const slug of slugs) {
    const dir = path.join(DIST, 'opencode', slug, 'agents');
    const m1 = model.find((p) => p.slug === slug);
    const files = listDir(dir).filter((e) => e.name.endsWith('.md'));
    const expectedAgentIds = new Set([...m1.agents.map((a) => `${flat(slug, a.name)}.md`), ...m1.styles.map((x) => `${flat(slug, modeName(x.name))}.md`)]);
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
      if (!expectedAgentIds.has(e.name)) err(rel(file), `"${e.name}" is not an agent or mode of the plugin "${slug}"`);
      noLeftovers(file, text);
      const m = m1.agents.find((a) => `${slug}-${a.name}.md` === e.name);
      if (m?.readOnly && !/edit: deny/.test(text)) err(rel(file), 'read-only role must deny edit');
      if (m?.readOnly) {
        const rules = [...text.matchAll(/^    "((?:[^"\\]|\\.)*)": (allow|deny)$/gm)].map((x) => [JSON.parse(`"${x[1]}"`), x[2]]);
        if (JSON.stringify(rules) !== JSON.stringify(expectedRules)) err(rel(file), 'bash permission rules differ from the generated read-only rules');
        for (const c of commandsNamedIn(text)) if (opencodeDecision(rules, `${c} x`) !== 'allow') err(rel(file), `the text lets the role use \`${c}\` but its permission map denies it`);
      }
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
      if (/the `[a-z0-9-]+` skill\b/.test(text)) err(rel(file), 'names a skill without a path; a Gemini subagent cannot activate skills, so it needs the SKILL.md path');
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
        if (t === 'copilot' && /-mode-[a-z0-9-]+\.agent\.md$/.test(e.name) && !(data?.['user-invocable'] === true && data?.['disable-model-invocation'] === true)) err(rel(file), 'a mode agent must be user-invocable and hidden from model delegation');
        noLeftovers(file, text);
      }
      if (/Claude Code/.test(readIf(path.join(root, manifest)) ?? '')) err(rel(path.join(root, manifest)), 'describes the plugin as a Claude Code toolkit');
    }
    const rule = readIf(path.join(DIST, 'cursor', slug, 'rules', `${slug}-rules.mdc`)) ?? '';
    if (!/^description: ".*Apply them when /m.test(rule)) err(`dist/cursor/${slug}/rules/${slug}-rules.mdc`, 'the rule description must say when to apply the rule');
  }
  for (const f of ['.cursor-plugin/marketplace.json']) {
    try {
      const m = JSON.parse(readIf(path.join(ROOT, f)));
      for (const p of m.plugins) if (!exists(path.join(ROOT, p.source))) err(f, `missing source ${p.source}`);
      if (/Claude Code/.test(JSON.stringify(m))) err(f, 'describes the plugins as Claude Code plugins');
      if (m.metadata?.version !== VERSION) err(f, `metadata.version ${m.metadata?.version} must equal the repository version ${VERSION}`);
    } catch (e) { err(f, e.message); }
  }

  // ---------------------------------------------------------------- rules and MCP catalog
  for (const slug of slugs) {
    for (const size of ['nano', 'mini']) {
      const file = path.join(DIST, 'rules', slug, `AGENTS.${size}.md`);
      const text = readIf(file);
      if (!text) { err(rel(file), 'missing'); continue; }
      if (Buffer.byteLength(text) > 16 * 1024) err(rel(file), 'over 16 KiB; too large for an always-on rules file');
      noLeftovers(file, text, { mentions: true }); // the companion section names skills in both the flat and the Codex ("$plugin:skill") syntax
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
    for (const b of cat.books) if (('design' in b.rules) !== referencesDesign(model.find((p) => p.slug === b.slug))) err('dist/mcp/catalog.json', `${b.slug}: the design map is listed only for plugins whose skills refer to it`);
    if (cat.version !== VERSION) err('dist/mcp/catalog.json', `version ${cat.version} must equal the repository version ${VERSION}`);
  } catch (e) { err('dist/mcp/catalog.json', e.message); }
  for (const e of listDir(path.join(DIST, 'mcp', 'agents')).filter((x) => x.name.endsWith('.md'))) noLeftovers(path.join(DIST, 'mcp', 'agents', e.name), readIf(path.join(DIST, 'mcp', 'agents', e.name)) ?? '');

  // ---------------------------------------------------------------- cross-target rules that each cost a reviewer round
  // The maintainers' component map is shipped only where a skill sends the reader to it.
  for (const m of model) {
    const want = referencesDesign(m);
    for (const f of [path.join(DIST, 'agent-skills', m.slug, flat(m.slug, 'principles'), 'references', 'design.md'), path.join(DIST, 'codex', m.slug, 'skills', 'principles', 'references', 'design.md')]) {
      if (exists(f) !== want) err(rel(f), want ? 'a skill refers to the component map but it is not shipped' : 'the maintainers\' component map is shipped although no skill refers to it');
    }
  }
  // Fixed rewrites that must not come back.
  const mustInclude = [
    ['dist/agent-skills/clean-architecture/clean-architecture-layer-map/SKILL.md', '`use-cases`, `usecases`', 'a list of directory names was rewritten as a skill reference'],
    ['dist/codex/clean-architecture/skills/layer-map/SKILL.md', '`use-cases`, `usecases`', 'a list of directory names was rewritten as a skill reference'],
    ['dist/agent-skills/release-it/release-it-timeouts/SKILL.md', '`release-it-retries`', 'a one-word sibling named in a description was not prefixed'],
    ['dist/codex/release-it/skills/timeouts/SKILL.md', '`$release-it:retries`', 'a one-word sibling named in a description was not rewritten'],
    ['dist/agent-skills/refactoring-guru/refactoring-guru-review/SKILL.md', '`refactoring-guru-hierarchies`', 'a one-word skill in a list of skills was not prefixed'],
    ['dist/agent-skills/refactoring/refactoring-smell-to-refactoring/SKILL.md', '`refactoring-duplication`', 'a one-word skill in a "Skill" table column was not prefixed'],
    ['dist/codex/clean-code/skills/audit/SKILL.md', '$clean-code:<skill>', 'the placeholder reference in an output template lost its Codex syntax'],
    ['dist/agent-skills/clean-code/clean-code-audit/SKILL.md', 'clean-code-<skill>', 'the placeholder reference in an output template was not rewritten'],
  ];
  for (const [f, needle, why] of mustInclude) if (!(readIf(path.join(ROOT, f)) ?? '').includes(needle)) err(f, `expected ${needle}: ${why}`);
  // "Load", "Fetch" and "Read" start a sentence; after a comma or semicolon they are lower case.
  const allAgentFiles = [
    ...listDir(path.join(DIST, 'codex', 'agents')).map((e) => path.join(DIST, 'codex', 'agents', e.name)),
    ...['opencode', 'gemini', 'cursor', 'copilot'].flatMap((t) => slugs.flatMap((slug) => listDir(path.join(DIST, t, slug, 'agents')).map((e) => path.join(DIST, t, slug, 'agents', e.name)))),
    ...listDir(path.join(DIST, 'mcp', 'agents')).map((e) => path.join(DIST, 'mcp', 'agents', e.name)),
  ];
  for (const f of allAgentFiles) {
    const text = readIf(f) ?? '';
    const bad = text.match(CAPITALISED_VERB);
    if (bad) err(rel(f), `capitalised verb in mid-sentence: "${bad[0]}"`);
  }

  // The MCP client has no files: an agent prompt must point at get_rules, not at a references/ path.
  for (const e of listDir(path.join(DIST, 'mcp', 'agents')).filter((x) => x.name.endsWith('.md'))) {
    if (/`references\/(?:full|mini|nano|design)\.md`/.test(readIf(path.join(DIST, 'mcp', 'agents', e.name)) ?? '')) err(`dist/mcp/agents/${e.name}`, 'points at a rule file path; an MCP client can only call get_rules');
  }
  // Each hub says what to do when a named subagent role does not exist.
  for (const m of model) {
    for (const f of [path.join(DIST, 'agent-skills', m.slug, flat(m.slug, 'principles'), 'SKILL.md'), path.join(DIST, 'codex', m.slug, 'skills', 'principles', 'SKILL.md')]) {
      if (!/^## Subagent roles$/m.test(readIf(f) ?? '')) err(rel(f), 'the hub must explain that subagent roles are optional');
    }
  }

  // ---------------------------------------------------------------- installers and the rules composer, run into a throwaway folder
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'guided-validate-'));
  try {
    const run = (script, args) => spawnSync(process.execPath, [path.join(ROOT, 'scripts', script), ...args], { encoding: 'utf8' });
    const dir = (n) => path.join(tmp, n);
    const count = (d) => (fs.existsSync(d) ? fs.readdirSync(d).length : 0);
    const ddd = model.find((p) => p.slug === 'ddd');
    // Codex roles: the plugin "ddd" must not drag in "ddd-distilled" and "ddd-implementing"
    let r = run('install-codex-agents.mjs', ['ddd', '--dest', dir('roles')]);
    if (count(dir('roles')) !== ddd.agents.length || !r.stdout.includes(`installed ${ddd.agents.length} role`)) err('scripts/install-codex-agents.mjs', `installing "ddd" must copy exactly its ${ddd.agents.length} roles (got ${count(dir('roles'))})`);
    run('install-codex-agents.mjs', ['ddd-distilled', '--dest', dir('roles')]);
    run('install-codex-agents.mjs', ['ddd', '--uninstall', '--dest', dir('roles')]);
    if (count(dir('roles')) !== model.find((p) => p.slug === 'ddd-distilled').agents.length) err('scripts/install-codex-agents.mjs', 'uninstalling "ddd" must leave the roles of "ddd-distilled"');
    r = run('install-codex-agents.mjs', ['all', '--dest', dir('all-roles')]);
    if (count(dir('all-roles')) !== totalAgents || !r.stdout.includes(`installed ${totalAgents} role`)) err('scripts/install-codex-agents.mjs', `"all" must install exactly ${totalAgents} roles`);
    // OpenCode: install, leave a user's own files alone, uninstall counts only what exists and leaves nothing behind
    fs.mkdirSync(path.join(dir('oc'), 'agents'), { recursive: true });
    fs.writeFileSync(path.join(dir('oc'), 'agents', 'mine.md'), 'mine');
    run('install-opencode.mjs', ['clean-code', '--dest', dir('oc')]);
    for (const f of ['LICENSE', 'NOTICE.md']) if (!fs.existsSync(path.join(dir('oc'), 'guided-plugins', 'clean-code', f))) err('scripts/install-opencode.mjs', `${f} of the plugin must be copied`);
    r = run('install-opencode.mjs', ['clean-code', '--uninstall', '--dest', dir('oc')]);
    const cc = model.find((p) => p.slug === 'clean-code');
    if (!r.stdout.includes(`removed ${cc.skills.length + cc.styles.length} skill folder(s) and ${cc.agents.length + cc.styles.length} agent file(s)`)) err('scripts/install-opencode.mjs', `uninstall must report what it removed: ${r.stdout.trim()}`);
    if (fs.readdirSync(dir('oc')).join() !== 'agents' || fs.readdirSync(path.join(dir('oc'), 'agents')).join() !== 'mine.md') err('scripts/install-opencode.mjs', 'uninstall must leave the user\'s own files and no empty folders');
    r = run('install-opencode.mjs', ['clean-code', '--uninstall', '--dest', dir('nothing')]);
    if (!r.stdout.includes('removed 0 skill folder(s) and 0 agent file(s)')) err('scripts/install-opencode.mjs', 'uninstalling what was never installed must report 0');
    // rules composer
    r = run('compose-rules.mjs', ['clean-code', 'clean-code', 'refactoring']);
    if ((r.stdout.match(/OBEY Clean Code/g) ?? []).length !== 1 || !/Precedence: this is the PRIMARY rule set/.test(r.stdout)) err('scripts/compose-rules.mjs', 'a repeated book must appear once and the precedence must be visible text');
    if (run('compose-rules.mjs', ['clean-code', '--out']).status !== 2) err('scripts/compose-rules.mjs', '--out without a file name must be a usage error');
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }

  return errors;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const errors = validateTargets();
  for (const e of errors.slice(0, 60)) console.log(`ERROR ${e}`);
  if (errors.length > 60) console.log(`... and ${errors.length - 60} more`);
  console.log(errors.length ? `FAIL targets: ${errors.length} errors` : 'PASS targets: all generated builds satisfy their agents\' constraints');
  process.exit(errors.length ? 1 : 0);
}
