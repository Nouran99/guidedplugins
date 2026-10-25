# Using the toolkits with other coding agents

The 14 book toolkits are written once, as Claude Code plugins in `plugins/`. A generator turns the same content into builds for other
coding agents under `dist/`, and `scripts/validate-targets.mjs` checks every build against what that agent accepts. This page says what
you get on each agent, how to install it, what is different, and what was verified.

The names Claude Code, Codex, OpenCode, Gemini CLI, Cursor, GitHub Copilot and the other agents mentioned here belong to their owners. This project is independent
and is not affiliated with or endorsed by any of them, or by the authors of the books (see [NOTICE.md](../NOTICE.md)).

Contents: [Support matrix](#support-matrix) · [What maps to what](#what-maps-to-what) · [Codex](#codex-cli) · [OpenCode](#opencode) ·
[Gemini CLI](#gemini-cli) · [Copilot and Cursor](#github-copilot-and-cursor) · [Any other agent](#any-other-agent-agent-skills-agentsmd-mcp) ·
[Cost and limits](#cost-and-limits) · [Differences to expect](#differences-to-expect) · [What was verified](#what-was-verified) · [For maintainers](#for-maintainers)

## Support matrix

The scripts in `scripts/` run on Node 20 or later. They live in a clone of this repository; the installers write into the folder you run them from (or the one you name), so run them from your project, not from inside the clone.

| Agent | What you get | Install | Status |
| --- | --- | --- | --- |
| **Claude Code** | Everything: skills, subagents, output styles, opt-in rules hook | `/plugin marketplace add Nouran99/guidedplugins` | Reference implementation |
| **Codex CLI** | Plugins with all skills (`$plugin:skill`) and mode skills; the subagent roles through a hidden `$plugin:install-roles` skill | `codex plugin marketplace add /path/to/guidedplugins`, `codex plugin add <plugin>@guided-plugins`, then `$<plugin>:install-roles` | Verified with codex-cli 0.162.1, including 7 live model runs on one plugin |
| **OpenCode** | Skills, subagents whose edit tools are denied and whose shell is limited to a read-only allowlist, modes as primary agents | from your project's folder: `node /path/to/guidedplugins/scripts/install-opencode.mjs <plugin> [--global]` | Verified with OpenCode 1.19 and 2.0; requests measured with a mock model |
| **Gemini CLI** | One extension per plugin: rule skills, the workflows and modes as slash commands, subagents, and a policy that denies writes to the read-only roles | `gemini extensions install ./dist/gemini/<plugin>` | Verified with gemini-cli 0.64: install, load, the request the model would receive, and Gemini's own policy engine; no real model session |
| **GitHub Copilot** | Plugin with skills and agents | `copilot plugin marketplace add /path/to/guidedplugins`, then `copilot plugin install <plugin>@guided-plugins` | Verified with Copilot CLI 1.0.101: marketplace, install and the skill list; no model session |
| **Cursor** | Plugin with skills, subagents and an on-demand rules file | Teams or Enterprise plan: an admin imports the repository as a team marketplace. Otherwise copy `dist/cursor/<plugin>` to `~/.cursor/plugins/local/` | **Experimental**, not run here |
| **Any agent that reads Agent Skills** (about 75, including Amp, Goose, Junie, Kiro, Warp, Zed, Antigravity, Qwen Code, Droid) | The skills and modes (no subagent roles) | `npx skills add ./dist/agent-skills/<plugin>` from a clone (or `Nouran99/guidedplugins/dist/agent-skills/<plugin>` once published) | Installer and format verified; the individual agents were not run |
| **Any agent that reads `AGENTS.md`** | The book's compact rules, always on | `node scripts/compose-rules.mjs <plugin>... --size nano --out AGENTS.md` | Verified (file generation, size checks) |
| **Any agent that speaks MCP** | Search and fetch every guide, subagent roles included; prompts become slash commands where the client supports them | `node scripts/mcp-server.mjs --plugins <plugin>` | Verified with the MCP Inspector, Claude Code and Codex; the `npm exec` form from a git URL ran |

The GitHub paths (`Nouran99/guidedplugins`) work once the repository is published there; at the time of writing it has no remote. Until then use a local clone and the local forms shown.
The local forms were run: `codex plugin marketplace add <clone>`, `copilot plugin marketplace add <clone>`, `gemini extensions install <path>`, `npx skills add <clone>/dist/agent-skills`, and `npm exec --package=git+file://<clone> -- guided-plugins-mcp` (the same mechanism as `npx github:Nouran99/guidedplugins`, with a local git repository instead of GitHub).

## What maps to what

| Claude Code concept | Other agents |
| --- | --- |
| **Skill** (`/plugin:name`) | A skill folder in the open Agent Skills format. In flat-namespace agents it is named `<plugin>-<name>` (for example `clean-code-review`) because 7 skill names (the `principles` hub and six workflows) repeat in all 14 plugins and a flat list would silently lose 116 of 433 skills. Codex namespaces for you (`$clean-code:review`). In Gemini the rule skills are `clean-code-naming` and the workflows are commands (`/clean-code:review`). |
| **Manual workflow** (`disable-model-invocation`) | Hidden from the model's catalog in Codex (`agents/openai.yaml` policy). In Gemini a workflow is a slash command, not a skill, so it costs nothing in a request until you run it. Other agents list it, so its description ends with "Run only when the user asks for it by name." Cursor documents a field that hides a skill from the model; this build does not emit it, because the skill folders are shared byte for byte between agents and keep to the Agent Skills keys. |
| **`context: fork`** (a skill that runs in its own context) | No equivalent is used. 38 skills (the `audit` of every plugin and 24 others) run in the current conversation, and their output lands in it. The build removes the sentences that claim a forked or isolated context and says "work in the current session". If you want the isolation, ask your agent to run the scan in a subagent or a fresh session. |
| **`allowed-tools`** (a tool guard on a skill) | Not emitted. Those skills still say "do not edit any file", but no tool is blocked. |
| **Arguments** (`$ARGUMENTS`) | Gemini commands take them (`/clean-code:review src/`, filled in through `{{args}}`; checked in the request the model receives). Everywhere else the text you type after the skill name is read as the argument ("the argument text" in the skill). |
| **Subagent** | Codex role (TOML), OpenCode subagent (Markdown, permission map), Gemini subagent (Markdown, tool list, policy), Copilot and Cursor agents. Turn limits carry over to OpenCode (`steps`) and Gemini (`max_turns`) but not to Codex, Copilot or Cursor. Model names, colors and skill preloading do not carry over; the agent is told which skills to load. Skills name roles such as `<plugin>-lead` and `<plugin>-final-gate`; where a build ships no roles (plain Agent Skills), the hub skill tells the agent to do that step itself. |
| **Output style** (`/output-style plugin:mode`) | A persona: a mode skill (`$clean-code:mode-mentor`, `clean-code-mode-mentor`) you invoke and that holds for the session (in Cursor see the note under [Cursor](#github-copilot-and-cursor)); in Gemini the slash command `/clean-code:mode-mentor`; in OpenCode a primary agent you switch to with Tab; in Copilot an agent you pick with `/agent`. No agent has a literal output-style feature other than Claude Code. |
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
- **Subagents:** a Codex plugin cannot activate subagent roles, so each plugin carries its roles as files and a hidden skill that copies them to where Codex reads custom roles. In Codex, once per plugin:

  ```text
  $clean-code:install-roles
  ```

  The skill asks whether you want the roles for all projects (`$CODEX_HOME/agents`, default `~/.codex/agents`) or this project (`.codex/agents`, trusted projects only), copies the files without overwriting any that exist, and says what it installed. Codex reads roles when a session starts, so ask for a role by name in the next session ("have `clean-code-naming-reviewer` check `src/`").
  **The copy needs your approval.** Codex's sandbox keeps `.codex` read-only even inside the project and the folder in your home is outside the workspace, so the skill asks to run the command and does not work around the sandbox. Where nobody can approve (`codex exec`), it prints the exact command for you to run (measured; see [What was verified](#what-was-verified)).
  From a clone you can do the same without a model: `node scripts/install-codex-agents.mjs clean-code` (`--project .` for `./.codex/agents`, `--uninstall`, `--dry-run`, `--force` to overwrite a file this project did not generate, `--dest <dir>`). Roles are selected by the plugin that owns them, so `ddd` installs the 22 roles of `ddd` and not those of `ddd-distilled` or `ddd-implementing`.
- **Delegation:** Codex does not spawn a role unless you ask or something tells it to. In these builds the hub's routing table marks `lead` and `final-gate` as "delegate" rows and some `review`, `checklist` and `fix` skills say to delegate (63 skills use the word in all, 14 of them the hubs); most other skills only name a role. Ask for a role by name.
  The role descriptions in the Codex build do not say "use proactively", because Codex would not.
- **Read-only reviews that are enforced:** a role file cannot restrict tools in Codex (a role may not set `sandbox_mode`; Codex strips it), so the read-only roles keep to their instructions only. The sandbox of the session is what enforces it, and a subagent inherits it:

  ```bash
  codex --sandbox read-only            # one session
  ```

  or a profile, `~/.codex/review.config.toml` with `sandbox_mode = "read-only"` and `approval_policy = "on-request"`, used as `codex --profile review`. Checked live: with `--sandbox read-only` a request to a `clean-code-refactorer` subagent to create a file ended with no file and the subagent reporting a read-only filesystem. That the profile file switches the sandbox was checked in the prompt Codex builds (`sandbox_mode` is `read-only`), not with a model run.
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
- **Subagents:** `@clean-code-naming-reviewer check src/`. Read-only roles get a permission map: OpenCode itself denies the edit tools and web fetch, and limits the shell to an allowlist of commands (`git diff|log|show|status|blame|ls-files`, `ls`, `grep`, `rg`, `find`, `wc`, `head`, `tail`, `git branch --show-current`) with deny rules after it for output redirection (`>`) and for flags that write or run something (`--output`, `--ext-diff`, `--textconv`, `rg --pre|--hostname-bin|--search-zip`, `find -exec|-ok|-delete|-fprint|-fls`). OpenCode takes the last matching rule. In a real OpenCode 1.19 server the request of such a role carries only `bash`, `glob`, `grep`, `read`, `skill`, `task` and `todowrite`: no `edit`, `write` or `webfetch`.
  **This is a guard rail, not a sandbox.** It matches the text of a command, so a command or flag the list did not foresee may still write. The flag lists are examples, not a closed set, and a wildcard cannot see through quoting (a flag split by quotes or an empty variable gets past it). `validate-targets.mjs` checks the rules against 17 commands that must pass and 23 that must be refused (including `git diff --output=f`, `ls > f`, `rg --pre` and `rg --hostname-bin`); that check uses a re-implementation of OpenCode's wildcard matcher, and no model session ran shell commands. Run an untrusted review in a read-only sandbox.
- **Modes:** each output style is a primary agent (`clean-code-mode-mentor`); switch to it with Tab. A mode name exists twice: as that agent and as a skill of the same name, so `/clean-code-mode-mentor` (OpenCode 1.x) loads the skill.
  OpenCode **replaces its provider system prompt** with the prompt of a primary agent. Measured with a mock model server: the built-in `build` agent's request carried a 29.8 KB system prompt and a mode agent's 23.7 KB, the difference being the provider prompt (about 8.6 KB) minus the mode's own text. So each mode agent starts with a short paragraph, in this project's own words, that restores the essentials (answer concisely, read before editing, follow the project's conventions, run its tests, do not commit unasked, ask before destructive steps); after that change the request is 24.5 KB. A mode agent also lacked OpenCode's `question` tool, which the `build` agent has; the modes now allow it (`permission: question: allow`), and the tool list of a mode agent equals the `build` agent's. The skill form of the same mode adds the persona without replacing anything and is the lighter choice. Both OpenCode 1.19 and 2.0 loaded the changed agents.
- **Always-on rules:** `AGENTS.md`, or add a rules file to the `instructions` array in `opencode.json`.

## Gemini CLI

Gemini installs one extension per GitHub repository, so the 14 extensions install from a local path of a checkout (they cannot come from this repository's URL).

```bash
git clone https://github.com/Nouran99/guidedplugins && cd guidedplugins      # once published; or use your own checkout
gemini extensions install ./dist/gemini/clean-code
gemini extensions link ./dist/gemini/clean-code     # alternative while developing: symlink
```

Installing asks for confirmation (trust and consent prompts in gemini-cli 0.64; `--consent` answers the consent one).

- **Rule skills:** the model activates the 18 to 20 rule skills of a plugin with `activate_skill` (`clean-code-naming`). A Gemini subagent cannot activate skills, so the roles in this build name every skill by its `SKILL.md` path under `${extensionPath}`, or, for a workflow that is a command, by the command's `.toml` file (the workflow text is its `prompt`).
- **Workflows and modes are slash commands**, not skills: `/clean-code:review src/`, `/clean-code:mode-mentor`. Gemini lists every skill in every request and puts every skill name into the `activate_skill` schema, and 242 of the 517 skills and modes are things you run on purpose, so as commands they cost nothing until used. The text after the command replaces `{{args}}` (checked in the request the model receives: `Arguments: src/ foo` arrived intact). A command prompt is not hydrated, so it names a skill to activate rather than a path. **Gemini loads extension commands only in a trusted folder.** It asks the first time you start it in a folder; if you answered "Don't trust" (the footer shows `untrusted`), `/clean-code:review` and the modes are missing while the rule skills and the `@` subagents still work. Run `/permissions trust` and restart.
- **Subagents:** `@clean-code-naming-reviewer check src/`. Each role lists the tools it may use, and read-only roles list no `replace` or `write_file`. Each extension also ships `policies/read-only-roles.toml`: three deny rules per read-only role, scoped to that role. They deny `write_file` and `replace`; they deny every shell command that does not start with `git diff|log|show|status|blame|ls-files`, `git branch --show-current`, `ls`, `grep`, `rg`, `wc`, `head`, `tail` or `find`; and they deny a command that carries a redirection, a pipe, `;`, `&`, a backtick, `$(`, a newline, a flag that writes or runs a program (`--output`, `--ext-diff`, `--textconv`, `--pre`, `--hostname-bin`, `--search-zip`, `-exec`, `-ok`, `-delete`, `-fprint`, `-fls`), or a long option name followed by a quote, a backslash, `$` or `{` (the way `--out""put` would be put back together by the shell).
  Gemini's policy engine honours these (extension policies can deny but never allow). `scripts/verify-gemini-policy.mjs <gemini-cli bundle>` loads the generated files with Gemini's own TOML loader and asks its `PolicyEngine` for 16,543 decisions across the 233 read-only roles (what a reviewer may run, what it may not, that nothing leaks to the main agent or other subagents): all as expected on 2026-10-25. **What the rules are not:**
  - They match the text of the command. A `|`, `<` or `>` inside a quoted pattern is refused too (`grep -E "a|b" src`): use `grep -e a -e b` or Gemini's own `grep_search`. The flag lists are examples of what is known to write or run something, not a closed set, and a determined model can find a spelling the text match does not see. They guard against a role that slips, not against one that tries to get around them. For an untrusted review use a real sandbox.
  - **A click can switch them off.** Answering a shell prompt with "Allow for this session" (or "always", where `security.enablePermanentToolApproval` is on) makes Gemini add an allow rule for the whole command word (`git`, `rg`) that applies to every agent and subagent and outranks the extension's deny rules; after one approved `git blame`, a read-only role's `git push` is no longer denied. `git blame`, `git ls-files` and `rg` are not on Gemini's built-in safe list, so they do prompt: answer "Allow once", or set `security.disableAlwaysAllow: true` in your Gemini settings (checked with Gemini's own engine: the option is then hidden and such rules are ignored). `git status` is not strictly read-only either: it may refresh the index.
  - What was not exercised is a live session, so that Gemini passes the subagent's name when the role calls a tool, and how the rules behave in YOLO mode, is taken from its source.
- **Always-on rules:** Gemini reads `GEMINI.md`, not `AGENTS.md`, unless you set `context.fileName` to include `AGENTS.md`. These builds do not set `contextFileName`, because that would load the rules into every session.
- **Antigravity:** Google replaced consumer Gemini CLI with Antigravity CLI on 2026-06-18 (Gemini CLI still works with paid API keys). Antigravity reads Agent Skills, so use the universal route below; its own plugin format was not checked.

## GitHub Copilot and Cursor

- **Copilot.** Copilot looks for a marketplace file in this order: `marketplace.json`, `.plugin/marketplace.json`, `.github/plugin/marketplace.json`, `.claude-plugin/marketplace.json`. This repository's `.github/plugin/marketplace.json` therefore wins over the Claude one and points at `dist/copilot/<plugin>`, the build with rewritten text and Copilot agents.

  ```bash
  copilot plugin marketplace add /path/to/guidedplugins       # or Nouran99/guidedplugins once published
  copilot plugin install clean-code@guided-plugins
  copilot plugin enable ddd@guided-plugins                    # installed plugins from a local marketplace are listed and can be switched on
  copilot skill list                                          # shows what Copilot found
  ```

  Copilot CLI 1.0.101 accepted the marketplace (14 plugins), installed `clean-code` ("Installed 37 skills") and `ddd`, loaded them live from `dist/copilot/` for a local marketplace, and with all 14 enabled `copilot skill list` showed 519 distinct skills. Skills are invoked as `/<plugin>:<skill>` (for example `/clean-code:clean-code-review src/`; the flat `/clean-code-review` also resolves). `/agent` in an interactive session lists the plugin's agents and modes without a login, as reported by a reviewer who ran it (this was not re-run); there is no non-interactive agent listing. Not checked: that a model uses the skills and agents (that needs a Copilot login). Copilot lists every enabled skill to the model, so enable the books you use. Modes are agents you select with `/agent`; they are marked so that Copilot does not pick them for delegation by themselves. **Read-only roles in Copilot** list `read`, `search` and `execute` and no `edit`, so Copilot gives them no edit tool, but their shell has no allowlist: keeping it read-only rests on the role's instructions and Copilot's approval prompts. **Cursor** roles set `readonly: true`, Cursor's own switch (unverified). Copilot prints that installs from a local path are deprecated in favour of `plugin@marketplace`, which is the form above.
- **Cursor (experimental, not run).** Per Cursor's plugin documentation, team marketplaces need a Teams or Enterprise plan and an admin adds them (`.cursor-plugin/marketplace.json` is the file they read). Individuals copy `dist/cursor/<plugin>` to `~/.cursor/plugins/local/<plugin>` and reload the window; an admin can switch local imports off ("Allow Local Plugin Imports", off by default on Enterprise). If a marketplace plugin of the same name is installed, it takes precedence over the local copy.
  Each plugin also carries `rules/<plugin>-rules.mdc`, a rule the model applies when relevant (not always on).
  In Cursor a skill invoked with `/` attaches to one message; to keep a mode for the whole session, use it as a Custom Mode (Option or Alt+Enter), per Cursor's skills documentation. Cursor lists the manual workflows too; their descriptions end with "Run only when the user asks for it by name."
  There is no safe way to try Cursor without touching a real profile, so this stays unverified. An issue with the result is welcome.

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

The first book is marked, in visible text, as the primary rule set that decides conflicts; the others are marked secondary. Naming a book twice includes it once. The script refuses to overwrite an existing `--out` file (an `AGENTS.md` usually holds your own rules); add `--force` to replace it, or write to a new name and merge.

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
| Codex, skills | The skill catalog gets a share of the context window and drops descriptions, then whole skills, when it is full. Measured with codex-cli 0.162.1 (`codex debug prompt-input`, default model catalog, throwaway `CODEX_HOME`): 5 plugins listed all 98 skills with descriptions; 12 plugins (237 skills) still kept every description; 13 kept only some; with all 14 the 275 model-invocable skills appeared as names only, and about 250 were listed (251 on the last run, 254 on an earlier one): the last plugins were cut. The limit moves with the model's context window and the length of the Codex home path, so treat these as indicative. The manual workflows, modes and `install-roles` are hidden from the catalog | Install the books you use, not all fourteen; or raise `skills.max_context_tokens` (cap 10,000) |
| Codex, roles | Every installed role is listed in the spawn tool with its name and a description of at most about 150 characters. Descriptions are whole sentences: about 160 characters on average, at most 240. Measured the same way in a real request with all 300 roles installed (a mock model server captured it): the role list is **65.8 KB** (105 KB for the whole request), down from **89.2 KB** (129 KB) with the original descriptions. One plugin's roles (about 22) are about 5 KB | Install roles only for the plugins you use |
| OpenCode | Lists every installed skill's name and description in every request (517 skills: about 34,000 tokens by a character count, characters / 4), and OpenCode's task tool is reported to list every subagent's name and description (300 roles: about 22,000 tokens by the same count, about 1,500 per plugin; from OpenCode's source code, not measured in a session). Tab also cycles through the mode agents (84 for all 14 plugins) and `build`/`plan`. No budget or cap found | Install what you use; deny skills per agent with `permission.skill` globs if needed |
| Gemini CLI | Lists every enabled skill, puts every skill name into the `activate_skill` schema and lists every subagent. Measured from the request a mock model server captured, all 14 extensions installed: **297 KB (about 74,000 tokens)**, of which the skill list is 173 KB (277 skills: our 275 and Gemini's 2 built-in) and the subagent list 82 KB (303 entries: 300 roles and 3 built-in). Before the workflows and modes became commands and the role descriptions were shortened it was 461 KB (519 skills, 308 KB; subagents, 109 KB). Whether the Gemini API accepts a schema with 277 skill names was **not** tested (no key) | One extension per book you use; the cost is per installed extension |
| Copilot | Lists every enabled skill (519 with all 14); the listing budget of the CLI is not documented and was not measured | Enable the books you use |
| MCP | Almost nothing idle (four tool definitions); a guide costs tokens only when fetched | Use `--plugins` to limit prompts and resources |

## Differences to expect

- **Read-only is enforced differently by each agent.** Claude Code applies each reviewer's tool list. OpenCode denies the edit tools and limits the shell to an allowlist. Gemini lists only read tools for the role and ships deny rules for writes and for shell commands outside an allowlist (and one "Allow for this session" click overrides them; see the Gemini section). Copilot gives a read-only role no edit tool but no shell allowlist. OpenCode's and Gemini's are guard rails that match command text, not sandboxes. Codex cannot restrict a subagent's tools or shell from a role file, so the reviewer's instructions say "read-only" and the agent is trusted to keep to it, unless you start Codex with `--sandbox read-only` (or a profile), which a subagent inherits and which was checked live. Run an untrusted review in a read-only sandbox if that matters.
- **No argument syntax** except Gemini commands. `$clean-code:review src/` passes `src/` as prose. The skills handle an empty argument by reviewing the current diff.
- **Skills are text instructions.** An agent may not follow them, as with any prompt. Output styles in particular are persona instructions, not a system-prompt switch.
- **Subagents differ in how they start.** Codex only spawns roles when asked; Claude Code, OpenCode and Gemini delegate by description.
- **Forked skills are not forked.** See [What maps to what](#what-maps-to-what).
- **Cross-references are names.** Where a skill said "run `/clean-code:fix`", the build says "`clean-code-fix`" (Codex: `$clean-code:fix`; Gemini: `/clean-code:fix`); invoke it the way your agent does.
- **Install whole plugins.** The skills in a plugin read each other and the rule files by relative path.

## What was verified

Builds were first generated and checked with the real tools on 2026-10-17 and re-run on 2026-10-20, 2026-10-21 and 2026-10-25 (after an independent review of the changes in [CHANGELOG](../CHANGELOG.md) 1.2.0), each in an isolated home directory so no personal configuration was touched.

| Check | Result |
| --- | --- |
| Agent Skills reference validator (`skills-ref`) on every skill in `dist/agent-skills` | 517 of 517 valid (2026-10-21) |
| `npx skills` (1.7.2) `--list` on `dist/agent-skills` | Found 517 skills (2026-10-21); installing `clean-code` copied 37 folders with their references (2026-10-17) |
| Codex 0.162.1: marketplace add, `plugin add` for all 14, `debug prompt-input` | 2026-10-21: all 14 plugins installed; the catalog hides the manual workflows, modes and `install-roles`; with `clean-code` alone it holds exactly its 19 model-invocable skills. The cost figures above come from the same runs |
| Codex roles | All 300 TOML files parse with Python's `tomllib` and have only `name`, `description` and `developer_instructions`. All 300 loaded in a real request with no warnings, and the request was measured against the committed 1.1.0 roles (2026-10-25) |
| Codex live model runs (a throwaway repository, an isolated `CODEX_HOME` with a copy of the author's login, deleted afterwards; model `gpt-6.1-sol`, low reasoning; one plugin, `clean-code`) | 7 runs on 2026-10-20, see below |
| Role installers | `install-codex-agents.mjs ddd` installs 22 roles, `refactoring` 22, `all` 300, and `--uninstall ddd` leaves the sibling plugins' roles alone. The shell loop of the `install-roles` skill leaves an existing file untouched (checked). `install-opencode.mjs` install, uninstall (including with other skills present) and dry run (all into throwaway folders) |
| OpenCode 1.19 (V1) and 2.0 (V2) | 2026-10-21, with all 14 plugins installed: V1 loaded 518 skills and 391 agents (302 subagents), V2 519 skills and 391 agents, no config errors; the read-only reviewer's request carries no `edit`, `write` or `webfetch` tool; a mode agent's request was captured with a mock model (system prompt, tool list as described above) and V2 shows `question: allow` on the mode agents |
| Gemini CLI 0.64 | 2026-10-21: all 14 extensions validated and installed with no errors, 277 skills enabled, the request captured with a mock model server (figures above) and the `/clean-code:review src/ foo` command expanded with its argument. Gemini's real `PolicyEngine` gave the expected answer for all 16,543 checks of `verify-gemini-policy.mjs` (re-run 2026-10-25 with the figures above: 297 KB request, 277 skills). No real model session |
| Copilot CLI 1.0.101 | 2026-10-21: marketplace add and browse (14 plugins), install of `clean-code` and `ddd`, `copilot skill list` showed 519 distinct skills with all 14 enabled. No model session |
| MCP server | The MCP Inspector, Claude Code (connected) and Codex (namespace with four tools) connect (2026-10-17). `scripts/mcp-selftest.mjs` passes 36 checks. `npm exec --package=git+file://<clone> -- guided-plugins-mcp` answered `initialize` and `tools/list` (2026-10-21) |
| `scripts/validate-targets.mjs` | Passes, and catches deliberately broken files (a forbidden key in a Codex role, a leftover Claude variable, an invalid Gemini tool, a policy that allows `git diff --output=f`, a `!{` inside a Gemini command, an unrewritten placeholder, a changed permission rule, and others) |

**The 7 live Codex runs** (details and prompts in [docs/verification/codex-live-2026-10-20.md](verification/codex-live-2026-10-20.md)):

| Run | What was asked | Outcome |
| --- | --- | --- |
| 1 | A naming review, no skill named | The model loaded `skills/naming/SKILL.md` on its own and answered with three naming findings |
| 2 | `$clean-code:review src/calc.py` | The workflow ran; it read `references/mini.md` and four sibling skills through the relative paths; three ranked findings in the template's format |
| 3 | `$clean-code:install-roles` in a workspace-write sandbox | The copy was refused by the sandbox (`.codex` is read-only); the model reported it and did nothing else |
| 3b | The same after the skill was changed to cover this | The model said it cannot ask for approval and printed the exact command with the real paths; running it installed the 22 roles |
| 4 | Use `clean-code-naming-reviewer` as a subagent | Codex called `spawn_agent` with `agent_type` `clean-code-naming-reviewer`; the subagent's thread carries that role; its verdict came back |
| 5 | The same with `clean-code-refactorer`, asked to create a file, under `--sandbox read-only` | No file was created; the subagent reported a read-only filesystem |
| 6 | `$clean-code:mode-mentor` and a rename | The function was renamed; the answer had the mode's **Why** block and pointed at `$clean-code:naming` |

**Not verified:** a live model session in any agent other than Codex (they need accounts or keys), whether the Gemini API accepts the `activate_skill` schema with every extension enabled, that Gemini passes the subagent name to its policy engine in a live session, the Gemini policy in YOLO mode, Copilot's use of the skills and agents, the GitHub-published install forms, and the Cursor and Antigravity builds.

## For maintainers

`plugins/` stays the single source of truth. Never edit `dist/` by hand.

```bash
node scripts/build-targets.mjs                # regenerate dist/ and the marketplace files for Codex, Cursor and Copilot
node scripts/build-targets.mjs --target codex # one target
node scripts/validate-targets.mjs             # check dist/ against each agent's constraints
node scripts/mcp-selftest.mjs                 # MCP protocol checks
node scripts/verify-gemini-policy.mjs <dir of an installed gemini-cli bundle>   # the Gemini read-only policy against Gemini's own engine
```

CI rebuilds `dist/` and fails if the result differs from what is committed (a generated file nobody committed counts as a difference). The flat targets (OpenCode, Cursor, Copilot) reuse the
universal skill folders byte for byte, which the validator enforces, so git stores one copy of each; Gemini keeps only the rule skills there
and turns the manual workflows and modes into commands. To add an agent, add a module under
`scripts/targets/`, register it in `scripts/build-targets.mjs`, add its constraints to `scripts/validate-targets.mjs`, and test it against the real tool.
