# Using the toolkits with other coding agents

The 14 book toolkits are written once, as Claude Code plugins in `plugins/`. A generator turns the same content into builds for other
coding agents under `dist/`, and `scripts/validate-targets.mjs` checks every build against what that agent accepts. This page says what
you get on each agent, how to install it, what is different, and what was verified.

The names Claude Code, Codex, OpenCode, Gemini CLI, Cursor, GitHub Copilot and the other agents mentioned here belong to their owners. This project is independent
and is not affiliated with or endorsed by any of them, or by the authors of the books (see [NOTICE.md](../NOTICE.md)).

Contents: [Support matrix](#support-matrix) · [What maps to what](#what-maps-to-what) · [Codex](#codex-cli) · [OpenCode](#opencode) ·
[Gemini CLI](#gemini-cli) · [Copilot and Cursor](#github-copilot-and-cursor-experimental) · [Any other agent](#any-other-agent-agent-skills-agentsmd-mcp) ·
[Cost and limits](#cost-and-limits) · [Differences to expect](#differences-to-expect) · [What was verified](#what-was-verified) · [For maintainers](#for-maintainers)

## Support matrix

The scripts in `scripts/` run on Node 20 or later and are run from a clone of this repository.

| Agent | What you get | Install | Status |
| --- | --- | --- | --- |
| **Claude Code** | Everything: skills, subagents, output styles, opt-in rules hook | `/plugin marketplace add Nouran99/guidedplugins` | Reference implementation |
| **Codex CLI** | Plugins with all skills (`$plugin:skill`), subagent roles, mode skills | `codex plugin marketplace add /path/to/guidedplugins` (or `Nouran99/guidedplugins` once published), then `codex plugin add <plugin>@guided-plugins`; roles with `node scripts/install-codex-agents.mjs <plugin>` from a clone | Verified with codex-cli 0.162 (local-path marketplace) |
| **OpenCode** | Skills, subagents whose edit tools are denied and whose shell is limited to a read-only allowlist, modes as primary agents | `node scripts/install-opencode.mjs <plugin> [--global]` | Verified with OpenCode 1.19 and 2.0 (see [What was verified](#what-was-verified)) |
| **Gemini CLI** | One extension per plugin: skills (also slash commands) and subagents | `gemini extensions install ./dist/gemini/<plugin>` | Verified with gemini-cli 0.64 (install and load; no live model session) |
| **GitHub Copilot** | Reads the Claude plugin as-is; a rewritten Copilot build is also provided | `copilot plugin install Nouran99/guidedplugins:dist/copilot/<plugin>` (once published) | **Experimental**, not run here |
| **Cursor** | Plugin with skills, subagents and an on-demand rules file | Teams or Enterprise plan: an admin imports the repository as a team marketplace. Otherwise copy `dist/cursor/<plugin>` to `~/.cursor/plugins/local/` | **Experimental**, not run here |
| **Any agent that reads Agent Skills** (about 75, including Amp, Goose, Junie, Kiro, Warp, Zed, Antigravity, Qwen Code, Droid) | The skills and modes (no subagent roles) | `npx skills add ./dist/agent-skills/<plugin>` from a clone (or `Nouran99/guidedplugins/dist/agent-skills/<plugin>` once published) | Installer and format verified; the individual agents were not run |
| **Any agent that reads `AGENTS.md`** | The book's compact rules, always on | `node scripts/compose-rules.mjs <plugin>... --size nano --out AGENTS.md` | Verified (file generation, size checks) |
| **Any agent that speaks MCP** | Search and fetch every guide, subagent roles included; prompts become slash commands where the client supports them | `node scripts/mcp-server.mjs --plugins <plugin>` | Verified with the MCP Inspector, Claude Code and Codex |

The GitHub paths (`Nouran99/guidedplugins`) work once the repository is published there; at the time of writing it has no remote. Until then use a local clone and the local forms shown.
Only the local forms were tested: `codex plugin marketplace add <clone>` and `npx skills add <clone>/dist/agent-skills/<plugin>`. The Copilot install form was not tried.

## What maps to what

| Claude Code concept | Other agents |
| --- | --- |
| **Skill** (`/plugin:name`) | A skill folder in the open Agent Skills format. In flat-namespace agents it is named `<plugin>-<name>` (for example `clean-code-review`) because 7 skill names (the `principles` hub and six workflows) repeat in all 14 plugins and a flat list would silently lose 116 of 433 skills. Codex and Gemini namespace for you: `$clean-code:review` and `/clean-code:clean-code-review`. |
| **Manual workflow** (`disable-model-invocation`) | Hidden from the model's catalog in Codex (`agents/openai.yaml` policy). Other agents list it, so its description ends with "Run only when the user asks for it by name." Cursor documents a field that hides a skill from the model; this build does not emit it, because the skill folders are shared byte for byte between agents and keep to the Agent Skills keys. |
| **`context: fork`** (a skill that runs in its own context) | No equivalent is used. 38 skills (the `audit` of every plugin and 24 others) run in the current conversation, and their output lands in it. The build removes the sentences that claim a forked or isolated context and says "work in the current session". If you want the isolation, ask your agent to run the scan in a subagent or a fresh session. |
| **`allowed-tools`** (a tool guard on a skill) | Not emitted. Those skills still say "do not edit any file", but no tool is blocked. |
| **Arguments** (`$ARGUMENTS`) | There is no argument syntax outside Claude Code. The text you type after the skill name is read as the argument ("the argument text" in the skill). |
| **Subagent** | Codex role (TOML), OpenCode subagent (Markdown, permission map), Gemini subagent (Markdown, tool list), Copilot and Cursor agents. Model names, colors, turn limits and skill preloading do not carry over; the agent is told which skills to load. Skills name roles such as `<plugin>-lead` and `<plugin>-final-gate`; where a build ships no roles (plain Agent Skills), the hub skill tells the agent to do that step itself. |
| **Output style** (`/output-style plugin:mode`) | A persona: a mode skill (`$clean-code:mode-mentor`, `clean-code-mode-mentor`) you invoke and that holds for the session (in Cursor see the note under [Cursor](#github-copilot-and-cursor-experimental)), or in OpenCode a primary agent you switch to with Tab, or in Copilot an agent you pick with `/agent`. No agent has a literal output-style feature other than Claude Code. |
| **Opt-in SessionStart hook** | Plain `AGENTS.md` rules (`dist/rules`), which every agent reads on its own. Hooks are not shipped for other agents. |
| **`${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` paths** | Rewritten to relative paths between sibling skill folders, so install a whole plugin together. |
| **Output templates** (`/clean-code:<skill>`, `clean-code:<agent>`) | Rewritten to the target's own syntax with the placeholder kept (`clean-code-<skill>`, Codex `$clean-code:<skill>`). |
| **Source traceability** | Unchanged: each skill still ends with its `## Source` section, and the upstream rule files (`full`, `mini`, `nano`) sit in the `principles` skill's `references/` folder. The maintainers' component map (`docs/DESIGN.md`) is shipped only for `refactoring-guru`, whose `explain-rule` skill points at it, with a note that it describes the Claude Code build. |

## Codex CLI

Codex reads this repository's `.agents/plugins/marketplace.json` in preference to the Claude marketplace file, so you get the Codex build.

```bash
codex plugin marketplace add /path/to/guidedplugins      # a local clone: this form was tested
codex plugin marketplace add Nouran99/guidedplugins      # works once the repository is published there; not tested
codex plugin add clean-code@guided-plugins
```

- **Use a skill:** type `$clean-code:review` (or pick it from `/skills`), followed by your arguments as plain text. Describe your task and Codex also loads the matching `clean-code:*` skills on its own.
- **Modes:** `$clean-code:mode-mentor` and the other `mode-*` skills.
- **Subagents:** Codex plugins cannot bundle subagents. The installed plugin (in `$CODEX_HOME/plugins/cache/`) holds only the skills, so the roles and the installer come from a clone of this repository. Install the roles, then ask for one by name ("have `clean-code-naming-reviewer` check `src/`"):

  ```bash
  cd ~/work/app
  node /path/to/guidedplugins/scripts/install-codex-agents.mjs clean-code               # ~/.codex/agents (or $CODEX_HOME/agents)
  node /path/to/guidedplugins/scripts/install-codex-agents.mjs clean-code --project .   # ./.codex/agents of the current directory (trusted projects only)
  node /path/to/guidedplugins/scripts/install-codex-agents.mjs clean-code --uninstall
  ```

  `--dry-run` changes nothing and reports what it would do; `--force` overwrites a role file this project did not generate (otherwise it is skipped); `--dest <dir>` picks any folder.
  Roles are selected by the plugin that owns them, so `ddd` installs the 22 roles of `ddd` and not those of `ddd-distilled` or `ddd-implementing`, and `--uninstall` removes only that plugin's roles.
- **Delegation:** Codex does not spawn a role unless you ask or something tells it to. In these builds the hub's routing table marks `lead` and `final-gate` as "delegate" rows and some `review`, `checklist` and `fix` skills say to delegate (63 skills use the word in all, 14 of them the hubs); most other skills only name a role. Ask for a role by name.
  The role descriptions in the Codex build do not say "use proactively", because Codex would not.
- **Skills that ran in a fork in Claude Code** (the `audit` workflows and others) run in your session, as described under [What maps to what](#what-maps-to-what).
- **Always-on rules:** put `dist/rules/clean-code/AGENTS.nano.md` (or the output of `compose-rules.mjs`) in your `AGENTS.md`. Codex caps the combined chain at 32 KiB. The "Companion skills" section at the end of each rules file names skills as `clean-code-review` and as `$clean-code:review`; use the second form in Codex.
- **Cost:** see [Cost and limits](#cost-and-limits). Install only the plugins you use.

## OpenCode

OpenCode has no plugin marketplace, so the installer copies (or, with `--link`, symlinks) the skills and agents into OpenCode's folders. Run it from a clone of this repository; without a flag it installs into `./.opencode` of the **current directory**.

```bash
cd ~/work/app                                                                          # the project you want the toolkits in
node /path/to/guidedplugins/scripts/install-opencode.mjs clean-code refactoring        # ~/work/app/.opencode
node /path/to/guidedplugins/scripts/install-opencode.mjs clean-code --project ~/work/app   # the same, from any directory
node /path/to/guidedplugins/scripts/install-opencode.mjs clean-code --global           # ~/.config/opencode
node /path/to/guidedplugins/scripts/install-opencode.mjs clean-code --link             # symlink; follows git pull
node /path/to/guidedplugins/scripts/install-opencode.mjs clean-code --uninstall
```

`--dry-run` changes nothing; `--no-skills` and `--no-agents` install one half. Each plugin's `LICENSE` and `NOTICE.md` (the MIT notice of the vendored rule text and the book credits) are copied to `.opencode/guided-plugins/<plugin>/`. Uninstalling removes only what the installer created and the folders it leaves empty.
You can also skip the copy for skills and point OpenCode at `dist/opencode/<plugin>/skills` (`skills.paths` in 1.x, the `skills` array in 2.x); `dist/agent-skills/<plugin>` holds the same skill folders.

- **Skills:** the model loads them with the skill tool. In OpenCode 1.x each skill is also a slash command (`/clean-code-review`); in 2.x use `@clean-code-review`.
- **Subagents:** `@clean-code-naming-reviewer check src/`. Read-only roles get a permission map: OpenCode itself denies the edit tools and web fetch, and limits the shell to an allowlist of commands (`git diff|log|show|status|blame|ls-files`, `ls`, `grep`, `rg`, `find`, `wc`, `head`, `tail`, `git branch --show-current`) with deny rules after it for output redirection (`>`) and for flags that write or run something (`--output`, `--ext-diff`, `rg --pre`, `find -exec`, `-delete`). OpenCode takes the last matching rule.
  **This is a guard rail, not a sandbox.** It matches the text of a command, so a command or flag the list did not foresee may still write. `validate-targets.mjs` checks the rules against 17 commands that must pass and 20 that must be refused (including `git diff --output=f`, `ls > f` and `rg --pre`); that check uses a re-implementation of OpenCode's wildcard matcher, and no model session ran shell commands. Run an untrusted review in a read-only sandbox.
- **Modes:** each output style is a primary agent (`clean-code-mode-mentor`); switch to it with Tab. A mode name exists twice: as that agent and as a skill of the same name, so `/clean-code-mode-mentor` (OpenCode 1.x) loads the skill. Caveat: in OpenCode a primary agent's prompt is reported to replace the provider's default system prompt (from OpenCode's source code, not tested with a model), so a mode agent may not get OpenCode's built-in coding guidance. The generated text asks the model to keep its normal conventions; the skill form adds the persona without replacing anything, and is the lighter choice.
- **Always-on rules:** `AGENTS.md`, or add a rules file to the `instructions` array in `opencode.json`.

## Gemini CLI

Gemini installs one extension per GitHub repository, so the 14 extensions install from a local path of a checkout (they cannot come from this repository's URL).

```bash
git clone https://github.com/Nouran99/guidedplugins && cd guidedplugins      # once published; or use your own checkout
gemini extensions install ./dist/gemini/clean-code
gemini extensions link ./dist/gemini/clean-code     # alternative while developing: symlink
```

Installing asks for confirmation (trust and consent prompts in gemini-cli 0.64; `--consent` answers the consent one).

- **Skills:** the model activates them with `activate_skill`; Gemini's documentation says each is also a slash command, `/clean-code:clean-code-review src/`. The `activate_skill` behavior and the slash commands were not exercised in a live session. A Gemini subagent cannot activate skills, so the roles in this build name every skill by its `SKILL.md` path under `${extensionPath}`.
- **Subagents:** `@clean-code-naming-reviewer check src/`. Each role lists the tools it may use, and read-only roles list no `replace` or `write_file`, so they cannot edit files with Gemini's own tools (Gemini applies the list; not tested with a live session). They do hold `run_shell_command` to read the diff, and Gemini cannot restrict which commands that runs, so keeping the shell read-only rests on the role's instructions.
- **Always-on rules:** Gemini reads `GEMINI.md`, not `AGENTS.md`, unless you set `context.fileName` to include `AGENTS.md`. These builds do not set `contextFileName`, because that would load the rules into every session.
- **Antigravity:** Google replaced consumer Gemini CLI with Antigravity CLI on 2026-06-18 (Gemini CLI still works with paid API keys). Antigravity reads Agent Skills, so use the universal route below; its own plugin format was not checked.

## GitHub Copilot and Cursor (experimental)

These two builds follow the vendors' documented plugin formats but could not be run where they were generated, so treat them as unverified.

- **Copilot** reads this repository's Claude marketplace as-is (`copilot plugin marketplace add Nouran99/guidedplugins`), which gives you the skills with their Claude-specific text. The rewritten build is `dist/copilot/<plugin>/`: `copilot plugin install Nouran99/guidedplugins:dist/copilot/clean-code`. Modes are agents you select with `/agent`; they are marked so that Copilot does not pick them for delegation by themselves.
- **Cursor.** Per Cursor's plugin documentation, team marketplaces need a Teams or Enterprise plan and an admin adds them (`.cursor-plugin/marketplace.json` is the file they read). Individuals copy `dist/cursor/<plugin>` to `~/.cursor/plugins/local/<plugin>` and reload the window; an admin can switch local imports off ("Allow Local Plugin Imports", off by default on Enterprise). If a marketplace plugin of the same name is installed, it takes precedence over the local copy.
  Each plugin also carries `rules/<plugin>-rules.mdc`, a rule the model applies when relevant (not always on).
  In Cursor a skill invoked with `/` attaches to one message; to keep a mode for the whole session, use it as a Custom Mode (Option or Alt+Enter), per Cursor's skills documentation. Cursor lists the manual workflows too; their descriptions end with "Run only when the user asks for it by name."

If you try either, an issue with the result is welcome.

## Any other agent: Agent Skills, AGENTS.md, MCP

**Agent Skills** (the open format read by about 75 agents). The installer discovers every skill, copies a plugin's folders, and keeps the `references/` files:

```bash
npx skills add ./dist/agent-skills/clean-code --list                                  # from a clone; shows what it found
npx skills add ./dist/agent-skills/clean-code -a codex -a amp -y                      # from a clone, for two agents
npx skills add Nouran99/guidedplugins/dist/agent-skills/clean-code                    # once published; choose agents interactively
```

Install a whole plugin: its skills point at each other and at the `principles` skill by relative path.
The names carry the plugin prefix. Without it the installer finds only 317 of the 433 skills, because it silently drops repeated names.
**This build has no subagents.** Skills name roles such as `clean-code-lead`, `clean-code-final-gate` and the `...-reviewer` roles; they come from the OpenCode, Codex, Gemini CLI, Cursor and Copilot builds.
When your agent has no role of that name it should do that step itself, following the skill named beside it; each `principles` skill says so. Skills load into every request as a name and a description, so install one plugin at a time and only the ones you use (Zed, for example, is reported to budget its skill catalog; that figure was not checked here).

**`AGENTS.md` rules.** Most agents read it. Copy one file, or compose several books with a primary:

```bash
node scripts/compose-rules.mjs clean-code refactoring --size nano --out AGENTS.md
```

The first book is marked, in visible text, as the primary rule set that decides conflicts; the others are marked secondary. Naming a book twice includes it once.

**MCP.** For an agent with no skill support, or to search every guide from one place. The server exposes four read-only tools (`search_guides`, `get_guide`, `list_guides`, `get_rules`), the guides as resources, and the workflows, modes and subagent roles as prompts (slash commands where the client shows MCP prompts). `get_guide` also returns the subagent role prompts, so an agent without subagents can read a role and follow it. Always limit it to the books you use:

```bash
claude mcp add -s user guided-plugins -- node /path/to/guidedplugins/scripts/mcp-server.mjs --plugins clean-code,refactoring
codex mcp add guided-plugins -- node /path/to/guidedplugins/scripts/mcp-server.mjs --plugins clean-code,refactoring
npx -y github:Nouran99/guidedplugins --plugins clean-code      # once published; same server, no checkout
```

`claude mcp add` registers the server for the current project only unless you pass `-s user` (all your projects) or `-s project` (a shared `.mcp.json`).
For other MCP clients, register a stdio server whose command is `node /path/to/guidedplugins/scripts/mcp-server.mjs --plugins <list>` in that client's MCP settings (`mcpServers` in a JSON file for most; a `[mcp_servers.<name>]` table for Codex). `GUIDED_PLUGINS=a,b` is the environment-variable form of `--plugins`, and `--plugins=a,b` also works.
A mistyped option, an option without a value or an unknown `--kinds` value stops the server with a message instead of serving every book. `get_rules` with size `design` works only for plugins whose skills refer to the component map (today `refactoring-guru`).

## Cost and limits

Every agent puts something about each installed skill or role into every request. The numbers below are measured unless marked.

| Agent | What it costs | What to do |
| --- | --- | --- |
| Claude Code | About 3,100 to 3,900 tokens per plugin, by Claude Code's own estimate | Install two or three plugins |
| Codex, skills | The skill catalog gets a share of the context window and drops descriptions, then whole skills, when it is full. Measured with codex-cli 0.162.1 (`codex debug prompt-input`, default model catalog, throwaway `CODEX_HOME`): 5 plugins listed all 98 skills with descriptions; 12 plugins (237 skills) still kept every description; 13 kept only some; with all 14 the 275 model-invocable skills appeared as names only, and 254 were listed: `release-it` was cut to 1 of 20 and `refactoring` lost its last 2. The limit moves with the model's context window and the length of the Codex home path, so treat these as indicative. The manual workflows and modes are already hidden from the catalog | Install the books you use, not all fourteen; or raise `skills.max_context_tokens` (cap 10,000) |
| Codex, roles | Every installed role is listed in the spawn tool. All 300 added about 96 KB to the request; one plugin's roles (about 22) are about 7 KB | Install roles only for the plugins you use |
| OpenCode | Lists every installed skill's name and description in every request (517 skills: about 34,000 tokens by a character count, characters / 4), and OpenCode's task tool is reported to list every subagent's name and description (300 roles: about 22,000 tokens by the same count, about 1,500 per plugin; from OpenCode's source code, not measured in a session). Tab also cycles through the mode agents (84 for all 14 plugins) and `build`/`plan`. No budget or cap found | Install what you use; deny skills per agent with `permission.skill` globs if needed |
| Gemini CLI | Lists every enabled skill and puts every skill name into the `activate_skill` schema. A character count of the 517 names and descriptions gives about 34,000 tokens for all 14 extensions, before the schema. Whether the API accepts that many names was **not** tested | One extension per book you use |
| MCP | Almost nothing idle (four tool definitions); a guide costs tokens only when fetched | Use `--plugins` to limit prompts and resources |

## Differences to expect

- **Read-only is enforced differently by each agent.** Claude Code applies each reviewer's tool list. OpenCode denies the edit tools and limits the shell to an allowlist, which is a guard rail and not a sandbox (see above). Gemini applies a role's tool list but cannot restrict its shell. Codex cannot restrict a subagent's tools or shell, so the reviewer's instructions say "read-only" and the agent is trusted to keep to it. Run an untrusted review in a read-only sandbox if that matters.
- **No argument syntax.** `$clean-code:review src/` passes `src/` as prose. The skills handle an empty argument by reviewing the current diff.
- **Skills are text instructions.** An agent may not follow them, as with any prompt. Output styles in particular are persona instructions, not a system-prompt switch.
- **Subagents differ in how they start.** Codex only spawns roles when asked; Claude Code, OpenCode and Gemini delegate by description.
- **Forked skills are not forked.** See [What maps to what](#what-maps-to-what).
- **Cross-references are names.** Where a skill said "run `/clean-code:fix`", the build says "`clean-code-fix`" (Codex: `$clean-code:fix`); invoke it the way your agent does.
- **Install whole plugins.** The skills in a plugin read each other and the rule files by relative path.

## What was verified

Builds were first generated and checked with the real tools on 2026-10-17, each in an isolated home directory so no personal configuration was touched. A review pass on 2026-10-18 changed the generator (see the [CHANGELOG](../CHANGELOG.md)); the table says what was re-run afterwards.

| Check | Result |
| --- | --- |
| Agent Skills reference validator (`skills-ref`) on every skill in `dist/agent-skills` | 517 of 517 valid (2026-10-17; not re-run after the review pass, which changed skill text but not frontmatter keys) |
| `npx skills` (1.7.2) `--list` on `dist/agent-skills` | Found 517 skills; installing `clean-code` copied 37 folders with their references (2026-10-17) |
| Codex 0.162: `codex plugin marketplace add <clone>`, `plugin list`, `plugin add`, `debug prompt-input` | Re-run on the current build: marketplace read from `.agents/plugins/marketplace.json`; all 14 plugins installed; with `clean-code` alone the catalog holds exactly its 19 model-invocable skills, and the manual workflows and modes are hidden. The cost measurements above come from the same runs |
| Codex roles | All 300 TOML files parse with Python's `tomllib` and have only `name`, `description` and `developer_instructions` (re-run). They loaded in Codex with no warnings and each appeared in the spawn tool (2026-10-17) |
| Role installer | `install-codex-agents.mjs ddd` installs 22 roles, `refactoring` 22, `all` 300, and `--uninstall ddd` leaves the sibling plugins' roles alone (re-run into throwaway folders). `install-opencode.mjs` install, uninstall (including with other skills present) and dry run (re-run into throwaway folders) |
| OpenCode 1.19 (V1) and 2.0 (V2) | On 2026-10-17: all 517 skills and 384 agents loaded with no config errors, reviewers resolved to the permission map of that build, modes loaded as primary agents. **Not re-run:** the permission map changed afterwards (exact commands plus deny rules, same `permission.bash` keys); its current form was checked by `validate-targets.mjs` only, and OpenCode was not available for a re-run |
| Gemini CLI 0.64 | On 2026-10-17: all 14 extensions validated and installed, `gemini skills list` showed 517 enabled skills and 14 extensions loaded, no agent schema errors. **Not re-run** after the review pass (the roles now name skills by path) |
| MCP server | The MCP Inspector, Claude Code (connected) and Codex (namespace with four tools) all connect (2026-10-17). `scripts/mcp-selftest.mjs` passes 36 checks, including a response larger than the pipe buffer, malformed JSON-RPC input and option handling |
| `scripts/validate-targets.mjs` | Passes, and catches deliberately broken files (a forbidden key in a Codex role, a leftover Claude variable, an invalid Gemini tool, an unrewritten placeholder, a changed permission rule, and others) |

**Not verified:** live model sessions in any agent (they need accounts or keys), the OpenCode and Gemini behaviors marked above, Gemini's `activate_skill` limit with every extension enabled, the GitHub-published install forms, and the Cursor, Copilot and Antigravity builds.

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
