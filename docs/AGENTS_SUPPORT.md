# Using the toolkits with other coding agents

The 14 book toolkits are written once, as Claude Code plugins in `plugins/`. A generator turns the same content into builds for other
coding agents under `dist/`, and `scripts/validate-targets.mjs` checks every build against what that agent accepts. This page says what
you get on each agent, how to install it, what is different, and what was verified.

Contents: [Support matrix](#support-matrix) · [What maps to what](#what-maps-to-what) · [Codex](#codex-cli) · [OpenCode](#opencode) ·
[Gemini CLI](#gemini-cli) · [Copilot and Cursor](#github-copilot-and-cursor-experimental) · [Any other agent](#any-other-agent-agent-skills-agentsmd-mcp) ·
[Cost and limits](#cost-and-limits) · [Differences to expect](#differences-to-expect) · [What was verified](#what-was-verified) · [For maintainers](#for-maintainers)

## Support matrix

| Agent | What you get | Install (from a checkout of this repository unless noted) | Status |
| --- | --- | --- | --- |
| **Claude Code** | Everything: skills, subagents, output styles, opt-in rules hook | `/plugin marketplace add Nouran99/guidedplugins` | Reference implementation |
| **Codex CLI** | Plugins with all skills (`$plugin:skill`), subagent roles, mode skills | `codex plugin marketplace add Nouran99/guidedplugins`, then `codex plugin add <plugin>@guided-plugins`; roles with `node scripts/install-codex-agents.mjs <plugin>` | Verified with codex-cli 0.162 |
| **OpenCode** | Skills, subagents with enforced read-only permissions, modes as primary agents | `node scripts/install-opencode.mjs <plugin> [--global]` | Verified with OpenCode 1.19 and 2.0 |
| **Gemini CLI** | One extension per plugin: skills (also slash commands) and subagents | `gemini extensions install ./dist/gemini/<plugin>` | Verified with gemini-cli 0.64 (install and load; no live model session) |
| **GitHub Copilot** | Reads the Claude plugin as-is; a rewritten Copilot build is also provided | `copilot plugin install Nouran99/guidedplugins:dist/copilot/<plugin>` | **Experimental**, not run here |
| **Cursor** | Plugin with skills, subagents and an on-demand rules file | Import the repository as a Cursor team marketplace, or copy `dist/cursor/<plugin>` to `~/.cursor/plugins/local/` | **Experimental**, not run here |
| **Any agent that reads Agent Skills** (about 75, including Amp, Goose, Junie, Kiro, Warp, Zed, Antigravity, Qwen Code, Droid) | The skills and modes | `npx skills add Nouran99/guidedplugins/dist/agent-skills/<plugin>` | Installer and format verified; the individual agents were not run |
| **Any agent that reads `AGENTS.md`** | The book's compact rules, always on | `node scripts/compose-rules.mjs <plugin>... --size nano --out AGENTS.md` | Verified (file generation, size checks) |
| **Any agent that speaks MCP** | Search and fetch every guide; prompts become slash commands where the client supports them | `node scripts/mcp-server.mjs --plugins <plugin>` | Verified with the MCP Inspector, Claude Code and Codex |

The GitHub paths (`Nouran99/guidedplugins`) work once the repository is published there. Until then use a local checkout and the paths shown.

## What maps to what

| Claude Code concept | Other agents |
| --- | --- |
| **Skill** (`/plugin:name`) | A skill folder in the open Agent Skills format. In flat-namespace agents it is named `<plugin>-<name>` (for example `clean-code-review`) because 7 workflow names repeat in all 14 plugins and a flat list would silently lose 116 of 433 skills. Codex and Gemini namespace for you: `$clean-code:review` and `/clean-code:clean-code-review`. |
| **Manual workflow** (`disable-model-invocation`) | Hidden from the model's catalog in Codex (`agents/openai.yaml` policy). Other agents list it, so its description ends with "Run only when the user asks for it by name." |
| **Arguments** (`$ARGUMENTS`) | There is no argument syntax outside Claude Code. The text you type after the skill name is read as the argument ("the argument text" in the skill). |
| **Subagent** | Codex role (TOML), OpenCode subagent (Markdown, enforced permissions), Gemini subagent (Markdown, tool list), Copilot and Cursor agents. Model names, colors, turn limits and skill preloading do not carry over; the agent is told which skills to load. |
| **Output style** (`/output-style plugin:mode`) | A persona: a mode skill (`$clean-code:mode-mentor`, `clean-code-mode-mentor`) you invoke and that holds for the session, or in OpenCode a primary agent you switch to with Tab, or in Copilot an agent you pick with `/agent`. No agent has a literal output-style feature other than Claude Code. |
| **Opt-in SessionStart hook** | Plain `AGENTS.md` rules (`dist/rules`), which every agent reads on its own. Hooks are not shipped for other agents. |
| **`${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` paths** | Rewritten to relative paths between sibling skill folders, so install a whole plugin together. |
| **Source traceability** | Unchanged: each skill still ends with its `## Source` section, and the upstream rule files (`full`, `mini`, `nano`) sit in the `principles` skill's `references/` folder. |

## Codex CLI

Codex reads this repository's `.agents/plugins/marketplace.json` in preference to the Claude marketplace file, so you get the Codex build.

```bash
codex plugin marketplace add Nouran99/guidedplugins
codex plugin add clean-code@guided-plugins
```

- **Use a skill:** type `$clean-code:review` (or pick it from `/skills`), followed by your arguments as plain text. Describe your task and Codex also loads the matching `clean-code:*` skills on its own.
- **Modes:** `$clean-code:mode-mentor` and the other `mode-*` skills.
- **Subagents:** Codex plugins cannot bundle subagents, so install the roles separately, then ask for one by name ("have `clean-code-naming-reviewer` check `src/`"):

  ```bash
  node scripts/install-codex-agents.mjs clean-code            # ~/.codex/agents
  node scripts/install-codex-agents.mjs clean-code --project .  # this project's .codex/agents (trusted projects only)
  node scripts/install-codex-agents.mjs clean-code --uninstall
  ```

  Codex does not delegate on its own unless a skill or `AGENTS.md` tells it to; the skills in these builds do say when to delegate.
- **Always-on rules:** put `dist/rules/clean-code/AGENTS.nano.md` (or `compose-rules.mjs`) in your `AGENTS.md`. Codex caps the combined chain at 32 KiB.
- **Cost:** see [Cost and limits](#cost-and-limits). Install two or three plugins, not all fourteen.

## OpenCode

OpenCode has no plugin marketplace, so the installer copies (or, with `--link`, symlinks) the skills and agents into OpenCode's folders.

```bash
node scripts/install-opencode.mjs clean-code refactoring               # this project's .opencode
node scripts/install-opencode.mjs clean-code --global                  # ~/.config/opencode
node scripts/install-opencode.mjs clean-code --link                    # symlink; follows git pull
node scripts/install-opencode.mjs clean-code --uninstall
```

You can also skip the copy for skills and point OpenCode at the folder (`skills.paths` in 1.x, the `skills` array in 2.x), or use the universal route below.

- **Skills:** the model loads them with the skill tool. In OpenCode 1.x each skill is also a slash command (`/clean-code-review`); in 2.x use `@clean-code-review`.
- **Subagents:** `@clean-code-naming-reviewer check src/`. Reviewers carry an **enforced** permission map: edit denied, web fetch denied, and the shell limited to `git diff|log|show|status|blame|ls-files`, `ls`, `grep`, `rg`, `wc`, `head`, `tail`. OpenCode resolves this itself, so a reviewer cannot modify your files even if it tried.
- **Modes:** each output style is a primary agent (`clean-code-mode-mentor`); switch to it with Tab.
- **Always-on rules:** `AGENTS.md`, or add a rules file to the `instructions` array in `opencode.json`.

## Gemini CLI

Gemini installs one extension per GitHub repository, so the 14 extensions install from a local path of a checkout (they cannot come from this repository's URL).

```bash
git clone https://github.com/Nouran99/guidedplugins && cd guidedplugins
gemini extensions install ./dist/gemini/clean-code
gemini extensions link ./dist/gemini/clean-code     # alternative while developing: symlink
```

- **Skills:** the model activates them with `activate_skill`; each is also a slash command, `/clean-code:clean-code-review src/`.
- **Subagents:** `@clean-code-naming-reviewer check src/`. Gemini's agent format has no deny list, so a reviewer holds a shell tool (`run_shell_command`) to read the diff and relies on its instructions to stay read-only. Roles without edit tools cannot write files directly.
- **Always-on rules:** Gemini reads `GEMINI.md`, not `AGENTS.md`, unless you set `context.fileName` to include `AGENTS.md`. These builds do not set `contextFileName`, because that would load the rules into every session.
- **Antigravity:** Google replaced consumer Gemini CLI with Antigravity CLI on 2026-06-18 (Gemini CLI still works with paid API keys). Antigravity reads Agent Skills, so use the universal route below; its own plugin format was not checked.

## GitHub Copilot and Cursor (experimental)

These two builds follow the vendors' documented plugin formats but could not be run where they were generated, so treat them as unverified.

- **Copilot** reads this repository's Claude marketplace as-is (`copilot plugin marketplace add Nouran99/guidedplugins`), which gives you the skills with their Claude-specific text. The rewritten build is `dist/copilot/<plugin>/`: `copilot plugin install Nouran99/guidedplugins:dist/copilot/clean-code`. Modes are agents you select with `/agent`.
- **Cursor** lists `.cursor-plugin/marketplace.json` for team marketplaces; locally, copy `dist/cursor/<plugin>` to `~/.cursor/plugins/local/<plugin>` and reload the window. Each plugin also carries `rules/<plugin>-rules.mdc`, a rule the model applies when relevant (not always on).

If you try either, an issue with the result is welcome.

## Any other agent: Agent Skills, AGENTS.md, MCP

**Agent Skills** (the open format read by about 75 agents). The installer discovers every skill, copies a plugin's folders, and keeps the `references/` files:

```bash
npx skills add Nouran99/guidedplugins/dist/agent-skills/clean-code                    # choose agents interactively
npx skills add Nouran99/guidedplugins/dist/agent-skills/clean-code -a codex -a amp -y
npx skills add ./dist/agent-skills/clean-code --list                                  # from a checkout; shows what it found
```

Install a whole plugin: its skills point at each other and at the `principles` skill by relative path.
The names carry the plugin prefix. Without it the installer finds only 317 of the 433 skills, because it silently drops repeated names.

**`AGENTS.md` rules.** Most agents read it. Copy one file, or compose several books with a primary:

```bash
node scripts/compose-rules.mjs clean-code refactoring --size nano --out AGENTS.md
```

**MCP.** For an agent with no skill support, or to search every guide from one place. The server exposes four tools (`search_guides`, `get_guide`, `list_guides`, `get_rules`), the guides as resources, and the workflows, modes and subagent roles as prompts (slash commands where the client shows MCP prompts). Always limit it to the books you use:

```bash
claude mcp add guided-plugins -- node /path/to/guidedplugins/scripts/mcp-server.mjs --plugins clean-code,refactoring
codex mcp add guided-plugins -- node /path/to/guidedplugins/scripts/mcp-server.mjs --plugins clean-code,refactoring
npx -y github:Nouran99/guidedplugins --plugins clean-code      # once published; same server, no checkout
```

For other MCP clients, register a stdio server whose command is `node /path/to/guidedplugins/scripts/mcp-server.mjs --plugins <list>` in that client's MCP settings (`mcpServers` in a JSON file for most; a `[mcp_servers.<name>]` table for Codex). `GUIDED_PLUGINS=a,b` is the environment-variable form of `--plugins`.

## Cost and limits

Every agent puts something about each installed skill or role into every request. The numbers below are measured unless marked.

| Agent | What it costs | What to do |
| --- | --- | --- |
| Claude Code | About 3,100 to 3,900 tokens per plugin, by Claude Code's own estimate | Install two or three plugins |
| Codex, skills | The skill catalog gets 2% of the context window (about 270 name-only lines). With all 14 plugins installed it dropped every description and hid five whole plugins. One plugin shows all its skills with descriptions. The manual workflows and modes are already hidden from the catalog | Two or three plugins; or raise `skills.max_context_tokens` (cap 10,000) |
| Codex, roles | Every installed role is listed in the spawn tool. All 300 added about 96 KB to the request; one plugin's roles are about 7 KB | Install roles only for the plugins you use |
| OpenCode | Lists every installed skill's name and description in every request; no budget or cap found | Install what you use; deny skills per agent with `permission.skill` globs if needed |
| Gemini CLI | Lists every enabled skill and puts every skill name into the `activate_skill` schema. Estimated 30,000 to 45,000 tokens for all 14 extensions. Whether the API accepts that many names was **not** tested | One extension per book you use |
| MCP | Almost nothing idle (four tool definitions); a guide costs tokens only when fetched | Use `--plugins` to limit prompts and resources |

## Differences to expect

- **Read-only is enforced only in OpenCode.** Claude Code applies each reviewer's tool list. OpenCode enforces the permission map above. Codex and Gemini cannot restrict a subagent's tools or shell, so the reviewer's instructions say "read-only" and the agent is trusted to keep to it. Run an untrusted review in a read-only sandbox if that matters.
- **No argument syntax.** `$clean-code:review src/` passes `src/` as prose. The skills handle an empty argument by reviewing the current diff.
- **Skills are text instructions.** An agent may not follow them, as with any prompt. Output styles in particular are persona instructions, not a system-prompt switch.
- **Subagents differ in how they start.** Codex only spawns roles when asked; Claude Code, OpenCode and Gemini delegate by description.
- **Cross-references are names.** Where a skill said "run `/clean-code:fix`", the build says "`clean-code-fix`" (Codex: `$clean-code:fix`); invoke it the way your agent does.
- **Install whole plugins.** The skills in a plugin read each other and the rule files by relative path.

## What was verified

Builds were generated on 2026-10-17 and checked with the real tools, each in an isolated home directory so no personal configuration was touched.

| Check | Result |
| --- | --- |
| Agent Skills reference validator (`skills-ref`) on every skill in `dist/agent-skills` | 517 of 517 valid |
| `npx skills` (1.7.2) `--list` on `dist/agent-skills` | Found 517 skills; installing `clean-code` copied 37 folders with their references |
| Codex 0.162: `codex plugin marketplace add`, `plugin list`, `plugin add` | Marketplace read from `.agents/plugins/marketplace.json`; installed |
| Codex model catalog (`codex debug prompt-input`) | Exactly the 19 model-invocable `clean-code` skills; the manual workflows and modes hidden |
| Codex roles | All 300 TOML files parse and load with no warnings; each appears in the spawn tool |
| OpenCode 1.19 (V1) and 2.0 (V2) | All 517 skills and 384 agents load with no config errors; reviewers resolve to the enforced permission map; modes load as primary agents |
| Gemini CLI 0.64 | All 14 extensions validate and install; 519 skills enabled (ours plus two built in); no agent schema errors |
| MCP server | The MCP Inspector, Claude Code (connected) and Codex (namespace with four tools) all connect; `scripts/mcp-selftest.mjs` passes 18 checks |
| `scripts/validate-targets.mjs` | Passes, and catches five deliberately broken files (a forbidden key in a Codex role, a leftover Claude variable, an invalid Gemini tool, and others) |

**Not verified:** live model sessions in any agent (they need accounts or keys), Gemini's `activate_skill` limit with every extension enabled, and the Cursor, Copilot and Antigravity builds.

## For maintainers

`plugins/` stays the single source of truth. Never edit `dist/` by hand.

```bash
node scripts/build-targets.mjs                # regenerate dist/ and the marketplace files for Codex and Cursor
node scripts/build-targets.mjs --target codex # one target
node scripts/validate-targets.mjs             # check dist/ against each agent's constraints
node scripts/mcp-selftest.mjs                 # MCP protocol checks
```

CI rebuilds `dist/` and fails if the result differs from what is committed. The flat targets (OpenCode, Gemini, Cursor, Copilot) reuse the
universal skill folders byte for byte, which the validator enforces, so git stores one copy of each. To add an agent, add a module under
`scripts/targets/`, register it in `scripts/build-targets.mjs`, add its constraints to `scripts/validate-targets.mjs`, and test it against the real tool.
