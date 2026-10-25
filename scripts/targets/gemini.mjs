// Gemini CLI target (verified with gemini-cli 0.64 in an isolated GEMINI_CLI_HOME: `extensions validate|install|list`, the policy
// engine and a captured request; see docs/AGENTS_SUPPORT.md). One extension per plugin:
//   gemini-extension.json
//   skills/<plugin>-<name>/      the model-invocable rule skills (byte-for-byte rewrites of the universal skills except for references to commands)
//   commands/<plugin>/<name>.toml   the manual workflows and the modes, as slash commands `/<plugin>:<name>` with a real {{args}}
//   agents/<plugin>-<name>.md    subagents (Gemini's strict agent schema)
//   policies/read-only-roles.toml   deny rules that keep the read-only roles from writing (extension policies can deny, never allow)
// Why commands: Gemini lists every skill in every request and puts every skill name into the activate_skill schema. Measured with all
// 14 extensions installed, the request was 461 KB (519 skills = 308 KB, 303 subagents = 109 KB). The 242 manual workflows and modes are only
// ever run on request, so they cost nothing as commands.
// Gemini installs one extension per GitHub repository, so these install from a local path of a checkout.
import {
  DIST, agentBodyFor, bt, briefDescription, cleanDir, copyFile, flat, modeName, neutralText, path, rewrite, rewriteDescription,
  tomlMultiline, tomlString, writeFile, yaml,
} from './core.mjs';
import { PERSONA_PREFACE, emitFlatSkills, flatDialect } from './agent-skills.mjs';

const TOOL = { Read: 'read_file', Grep: 'grep_search', Glob: 'glob', Bash: 'run_shell_command', Edit: 'replace', Write: 'write_file' };

const refManual = (p, n) => `/${p.slug}:${n}`;
const refMode = (p, n) => `/${p.slug}:${modeName(n)}`;

// Skills sit in a folder next to their siblings, so paths are relative; manual workflows and modes are commands now.
const skillDialect = () => flatDialect({ refManual, refMode });

// Extension agents are hydrated, so ${extensionPath} resolves to the installed extension folder. A Gemini subagent has no activate_skill
// tool, so every mention of a skill or rule file must be a path it can read. A manual workflow is a command, not a skill: its file is the
// command's TOML (the workflow text is its `prompt`).
const isManualSkill = (p, n) => !!p.skills.find((x) => x.name === n)?.manual;
export const skillFileFor = (p, n) => (isManualSkill(p, n) ? `\${extensionPath}/commands/${p.slug}/${n}.toml` : `\${extensionPath}/skills/${flat(p.slug, n)}/SKILL.md`);
const agentDialect = () => flatDialect({
  refManual,
  refMode,
  agentRead: (p, n) => `Read ${bt(skillFileFor(p, n))}`,
  agentSkill: (p, n) => ({ path: skillFileFor(p, n) }),
  agentSkillsDir: () => ({ path: '${extensionPath}/skills/' }),
  agentRefFile: (p, r) => ({ path: `\${extensionPath}/skills/${flat(p.slug, 'principles')}/references/${r}.md` }),
  agentDesignFile: (p) => ({ path: `\${extensionPath}/skills/${flat(p.slug, 'principles')}/references/design.md` }),
});

// Command prompts are not hydrated (only skills, agents, config and hooks are), so a command names the skill to activate.
const commandDialect = () => flatDialect({
  refManual,
  refMode,
  argsLine: '{{args}}',
  agentRead: (p, n) => `Activate the ${bt(flat(p.slug, n))} skill`,
});

export function geminiTools(tools) {
  const set = new Set(['list_directory']);
  for (const t of tools) if (TOOL[t]) set.add(TOOL[t]);
  if (tools.includes('Read')) set.add('read_file');
  return [...set];
}

// ------------------------------------------------------------------ read-only policy
// Gemini's engine tests `commandRegex` against `"command":"<the command>` inside the JSON of the arguments. Extension policies sit in
// tier 2: a `deny` is honored, an `allow` is ignored, and anything the user allows in their own settings (tier 4) overrides these rules.
// Two deny rules per read-only role: (1) any command that does not start with an allowed read command, (2) any allowed command that
// carries a shell operator, a flag that writes or runs something, or a flag name that quoting, escaping or expansion could hide. A third denies
// the file-writing tools. All three match TEXT: a guard rail against a role that slips, not a sandbox against one that tries to get around it.
export const ALLOWED_COMMANDS = 'git (?:diff|log|show|status|blame|ls-files)|ls|grep|rg|wc|head|tail|find';
export const NOT_ALLOWED_REGEX = String.raw`(?!(?:${ALLOWED_COMMANDS})[ "]|git branch --show-current")`;
// Gemini's loader rejects a pattern as a potential ReDoS when a group that contains `?`, `*`, `+` or `{` (every `(?:` does) is later followed by
// a quantifier, so this one uses capturing groups with no quantifier characters inside. `([^"\\]|\\.)*` walks the JSON string of the command,
// stepping over escaped characters, until one of the dangerous tokens appears. Tokens: shell operators (`< > | ; &`, a backtick, `$(`, a newline),
// flags that write or run a program (git `--output`, `--ext-diff`, `--textconv`; rg `--pre`, `--hostname-bin`, `--search-zip`; find
// `-exec`/`-execdir`, `-ok`/`-okdir`, `-delete`, `-fprint*`, `-fls`), and a long option whose name is followed by a quote, a backslash, `$` or `{`
// (`--out""put`, `--out${x}put`), which a shell would put back together.
export const DANGEROUS_REGEX = String.raw`([^"\\]|\\.)*([<>|;&` + '`' + String.raw`]|\$\(|\\n|\\r|--output|--ext-diff|--textconv|--pre[^a-z]|--hostname-bin|--search-zip|-exec|-delete|-fprint|-fls|-ok|--[a-zA-Z-]*(\\"|'|\\\\|\$|\{))`;

// The battery both verify-gemini-policy.mjs (Gemini's own engine) and validate-targets.mjs (an offline re-implementation) run:
// what a read-only reviewer may run (the engine answers ask_user, the default, which is not a deny) and what it may not.
export const POLICY_MUST_ALLOW = [
  'git diff', 'git diff --stat HEAD~1', 'git log --oneline -n 5', 'git show HEAD:README.md', 'git status --short', 'git blame -L 1,5 a.txt',
  'git ls-files', 'ls', 'ls -la src', 'grep -rn foo src', 'grep -rn "foo" src', 'rg foo', 'wc -l a.txt', 'head -n 20 a.txt', 'tail -n 5 a.txt',
  'find . -name x', 'find src -type f -name "*.ts"', 'git branch --show-current', 'git log --pretty=format:%h -n 3', 'git log --format="%h %s" -n 3',
  'git diff --stat -- src', 'rg --files-with-matches foo src', 'grep -rn -e foo -e bar src',
];
export const POLICY_MUST_DENY = [
  'rm -rf build', 'echo hi > f', 'git diff > out.patch', 'git diff | tee f', 'git diff --output=f', 'ls; rm f', 'ls && rm f', 'grep -r x . | sh',
  'cat file', 'git commit -m x', 'git checkout .', 'git push', 'sed -i s/a/b/ f', 'curl http://x', 'python3 -c "open(\'f\',\'w\')"', 'ls $(rm f)',
  'ls `rm f`', 'ls\nrm f', 'rg --pre cmd foo', 'find . -delete', 'git diff --ext-diff', 'git log "x" > f', 'lsof', 'grepx foo', 'head -n 1 a.txt >> b',
  'git show --textconv HEAD:a', 'wc -l a.txt & rm f',
  'find . -fls f', 'find . -ok rm {} \;', 'find . -exec rm {} +', 'find . -fprint f', 'git branch --show-current -D x', 'git branch -D x', 'rg --hostname-bin x foo',
  'rg --search-zip foo', 'rg --pre\tcmd foo',
  // a flag name that quoting, escaping or expansion puts back together
  'git diff --out""put=f', "git diff --outp'ut'=f", 'git diff --out\\put=f', 'git diff --out${x}put=f', 'git diff --out$x""put=f', 'rg --pr""e cmd foo', 'rg --hostname-b""in x foo',
];

export function policyToml(plugin) {
  const out = ['# Generated by scripts/build-targets.mjs. Do not edit by hand.',
    '# Keeps the read-only roles of this extension from writing files. Extension policies can only deny; a user allow rule overrides them.', ''];
  for (const a of plugin.agents.filter((x) => x.readOnly)) {
    const name = flat(plugin.slug, a.name);
    const msg = `${name} is a read-only role. Allowed shell commands: git diff|log|show|status|blame|ls-files, git branch --show-current, ls, grep, rg, wc, head, tail, find. Redirection, pipes, command chaining, command substitution and flags that write or run a program are refused, and the check reads the command text, so a | < > ; or & inside a quoted pattern is refused too (use grep -e a -e b, or the grep_search tool).`;
    out.push('[[rule]]', 'toolName = ["write_file", "replace"]', `subagent = ${tomlString(name)}`, 'decision = "deny"', 'priority = 900', `denyMessage = ${tomlString(`${name} is a read-only role.`)}`, '');
    out.push('[[rule]]', 'toolName = "run_shell_command"', `subagent = ${tomlString(name)}`, `commandRegex = ${tomlString(NOT_ALLOWED_REGEX)}`, 'decision = "deny"', 'priority = 900', `denyMessage = ${tomlString(msg)}`, '');
    out.push('[[rule]]', 'toolName = "run_shell_command"', `subagent = ${tomlString(name)}`, `commandRegex = ${tomlString(DANGEROUS_REGEX)}`, 'decision = "deny"', 'priority = 900', `denyMessage = ${tomlString(msg)}`, '');
  }
  return out.join('\n');
}

const commandToml = (description, body) => `# Generated by scripts/build-targets.mjs. Do not edit by hand.\ndescription = ${tomlString(description)}\nprompt = ${tomlMultiline(body)}\n`;

export function buildGemini(model) {
  const out = path.join(DIST, 'gemini');
  cleanDir(out);
  const sd = skillDialect();
  const ad = agentDialect();
  const cd = commandDialect();
  for (const plugin of model) {
    const root = path.join(out, plugin.slug);
    emitFlatSkills(plugin, path.join(root, 'skills'), sd, { only: (s) => !s.manual, withModes: false });

    // manual workflows and modes -> /<plugin>:<name>
    for (const s of plugin.skills.filter((x) => x.manual)) {
      const ctx = { from: 'agent' };
      writeFile(path.join(root, 'commands', plugin.slug, `${s.name}.toml`),
        commandToml(rewriteDescription(s.fm.description, plugin, cd, ctx), rewrite(s.body.replace(/^\s+/, ''), plugin, cd, ctx)));
    }
    for (const m of plugin.styles) {
      const ctx = { from: 'agent' };
      writeFile(path.join(root, 'commands', plugin.slug, `${modeName(m.name)}.toml`),
        commandToml(rewriteDescription(m.fm.description, plugin, cd, ctx), PERSONA_PREFACE + rewrite(m.body.replace(/^\s+/, ''), plugin, cd, ctx)));
    }

    const preloadLine = (skills) => `Before you start, read these skills: ${skills.map((n) => bt(skillFileFor(plugin, n))).join(', ')}.`;
    const roNote = 'Operating constraint: this is a read-only role. Never create, edit, move or delete files and never run commands that change the repository or the system; inspect with read-only commands (git diff, git log, git show, git status, ls, grep) and report. The extension also ships policy rules that deny the write tools and any other shell command for this role.';
    for (const a of plugin.agents) {
      const body = agentBodyFor(plugin, a, ad, { preloadLine, readOnlyNote: roNote });
      const fm = ['---', 'kind: local', `name: ${flat(plugin.slug, a.name)}`, `description: ${yaml(briefDescription(rewriteDescription(a.fm.description, plugin, ad, { from: 'agent' })))}`,
        'tools:', ...geminiTools(a.tools).map((t) => `  - ${t}`), `max_turns: ${a.fm.maxTurns}`, '---', ''].join('\n');
      writeFile(path.join(root, 'agents', `${flat(plugin.slug, a.name)}.md`), fm + body);
    }
    writeFile(path.join(root, 'policies', 'read-only-roles.toml'), `${policyToml(plugin)}\n`);
    writeFile(path.join(root, 'gemini-extension.json'), JSON.stringify({
      name: plugin.slug,
      version: plugin.manifest.version,
      description: neutralText(plugin.manifest.description),
    }, null, 2));
    copyFile(path.join(plugin.dir, 'LICENSE'), path.join(root, 'LICENSE'));
    writeFile(path.join(root, 'NOTICE.md'), plugin.notice ?? '');
    const autos = plugin.skills.filter((x) => !x.manual).length;
    const manuals = plugin.skills.length - autos;
    writeFile(path.join(root, 'README.md'), `# ${plugin.book.title} for Gemini CLI

Generated by scripts/build-targets.mjs from plugins/${plugin.slug}/ in the guided-plugins repository.

Install from a checkout of the repository (Gemini installs one extension per repository from GitHub, so use the local path):

\`\`\`bash
gemini extensions install ./dist/gemini/${plugin.slug}
\`\`\`

Gemini asks you to confirm before it installs (trust and consent prompts).

- ${autos} rule skills the model activates on its own (\`${plugin.slug}-<name>\`).
- ${manuals} workflows and ${plugin.styles.length} modes as slash commands: \`/${plugin.slug}:review src/\`, \`/${plugin.slug}:mode-mentor\`. They are commands, not skills, so they add nothing to every request.
- ${plugin.agents.length} subagents, started with \`@${plugin.slug}-<name> <task>\`. The read-only ones are constrained by \`policies/read-only-roles.toml\` (deny rules on the text of a shell command: a guard rail, not a sandbox).

Gemini loads extension commands only in a trusted folder; if \`/${plugin.slug}:review\` is missing and the footer says \`untrusted\`, run \`/permissions trust\`. Answering a shell prompt with "Allow for this session" creates an allow rule that outranks the policy's deny rules for that command word; see docs/AGENTS_SUPPORT.md.
`);
  }
  return model;
}
