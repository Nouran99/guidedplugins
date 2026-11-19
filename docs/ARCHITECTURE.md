# Architecture

This document explains how the repository and the plugins in it are put together, why they have that shape, and how they are checked. It is written for maintainers and for users who want to know what they are installing. How to install and use the plugins is in [USAGE.md](USAGE.md). The contract every plugin is built to is [PLUGIN_SPEC.md](PLUGIN_SPEC.md); this file explains the reasoning around that contract and does not replace it.

The project is unofficial. It is not affiliated with or endorsed by the authors or publishers of the books it is named after, or by the maintainer of the upstream rule sets (see [NOTICE.md](../NOTICE.md)). It does not claim that the plugins improve code quality: the upstream project itself says the effect of such rules on code quality is not measured, and nothing here changes that. The claim is narrower. Each plugin applies one book's upstream rules consistently, and every piece of advice can be traced to the upstream section it comes from.

Statements about Claude Code come from the official documentation at code.claude.com/docs and from running Claude Code 2.1.286 locally on 2026-10-16. Claude Code changes often, so wherever a figure matters the command that produces it is shown.

## Contents

1. [Repository anatomy](#1-repository-anatomy)
2. [Plugin anatomy](#2-plugin-anatomy)
3. [The four component types](#3-the-four-component-types)
4. [Progressive disclosure](#4-progressive-disclosure)
5. [Traceability](#5-traceability)
6. [The opt-in hook](#6-the-opt-in-hook)
7. [Validation and CI](#7-validation-and-ci)
8. [How the plugins were built and reviewed](#8-how-the-plugins-were-built-and-reviewed)
9. [Design decisions and trade-offs](#9-design-decisions-and-trade-offs)
10. [Adding a book and updating the upstream rule sets](#10-adding-a-book-and-updating-the-upstream-rule-sets)
11. [Known limitations](#11-known-limitations)
12. [Builds for other coding agents](#12-builds-for-other-coding-agents)
13. [The layer around the books: evals, presets, project settings, review in CI](#13-the-layer-around-the-books-evals-presets-project-settings-review-in-ci)

## 1. Repository anatomy

```text
guidedplugins/
├── .claude-plugin/marketplace.json   generated: marketplace "guided-plugins", one entry per plugin
├── .agents/plugins/marketplace.json  generated: the same plugins for Codex (section 12)
├── .cursor-plugin/marketplace.json   generated: the same plugins for Cursor team marketplaces
├── .github/plugin/marketplace.json   generated: the same plugins for Copilot (points at dist/copilot, section 12)
├── plugins/<slug>/                   one plugin per book (14 today); anatomy in section 2
├── dist/                             generated builds for the other agents (section 12): agent-skills, codex, opencode, gemini, cursor, copilot, rules, mcp
├── docs/
│   ├── PLUGIN_SPEC.md                the contract each plugin is built and validated against
│   ├── ARCHITECTURE.md               this file
│   ├── USAGE.md                      installing and using the plugins
│   ├── AGENTS_SUPPORT.md             installing and using the builds for other agents, with costs and what was verified
│   ├── COMPATIBILITY.md              verdicts for every pair of plugins
│   └── templates/                    annotated skeletons for each component type
├── scripts/
│   ├── books.json                    registry: slug, upstream folder, title, author, category, keywords
│   ├── lib.mjs                       limits, allowed frontmatter keys, frontmatter parser, plugin loader
│   ├── catalog-lib.mjs               renderers shared by the generator and the validator
│   ├── gen-catalog.mjs               regenerates every derived file
│   ├── new-plugin.mjs                scaffolds the mechanical parts of a plugin
│   ├── validate-plugin.mjs           validates one plugin
│   ├── validate-all.mjs              validates every plugin, dist/, the repo-level docs and marketplace.json
│   ├── build-targets.mjs             generates dist/ for the other agents (section 12)
│   ├── targets/                      core rewrite engine and one module per target agent
│   ├── validate-targets.mjs          checks dist/ against each agent's constraints
│   ├── mcp-server.mjs, mcp-selftest.mjs   the MCP server and its protocol checks
│   └── install-*.mjs, compose-rules.mjs   installers for Codex roles and OpenCode, rules composer
├── .github/                          workflows/validate.yml (CI), issue templates, pull request template
├── .upstream/                        gitignored local clone of ciembor/agent-rules-books (read-only input)
└── package.json README.md CONTRIBUTING.md CHANGELOG.md NOTICE.md LICENSE SECURITY.md CODE_OF_CONDUCT.md
```

The scripts have no dependencies. `scripts/lib.mjs` says so on purpose: the repository must validate with a bare Node install. The README asks for Node 20 or later; CI uses Node 22.

`scripts/books.json` is the registry of books. A plugin whose slug is not in it fails validation. The marketplace file is not edited by hand: `gen-catalog.mjs --root` builds it from the registry plus each plugin's `plugin.json` (name, description, version, keywords become the entry's tags), and `validate-all.mjs` fails when the committed file differs from what the generator would write.

Every file in the repository falls into one of three groups:

| Group | Files | Who edits them |
| --- | --- | --- |
| Generated | `dist/` and the Codex, Cursor and Copilot marketplace files (`.agents/plugins/marketplace.json`, `.cursor-plugin/marketplace.json`, `.github/plugin/marketplace.json`) via `node scripts/build-targets.mjs`; `.claude-plugin/marketplace.json`; the plugin table in the root `README.md` (between the `CATALOG` markers); in each plugin `docs/COMPONENTS.md`, `docs/TRACEABILITY.md` and the `COMPONENTS` block of `README.md` | `node scripts/gen-catalog.mjs`. Do not edit by hand. |
| Scaffolded once | in each plugin `.claude-plugin/plugin.json`, `LICENSE`, `NOTICE.md`, `CHANGELOG.md`, `hooks/hooks.json`, `scripts/session-context.sh`, `skills/principles/references/{full,mini,nano}.md`, and a README stub | `node scripts/new-plugin.mjs`. After that, only `description` and `keywords` in `plugin.json`, `version`, and `CHANGELOG.md` are edited by hand, plus the commit hash in `NOTICE.md` when the vendored rules are refreshed (section 10). The vendored rule files stay byte-for-byte upstream. |
| Hand-written | skills, agents, output styles, the README prose, `docs/DESIGN.md`, everything in `scripts/` and `docs/` at the repository root | Maintainers, within the rules in the spec. |

## 2. Plugin anatomy

Every plugin has the same layout. This is `clean-code`; the other 13 differ only in the names of their components.

```text
plugins/clean-code/
├── .claude-plugin/plugin.json        manifest: name, displayName, version, description, author,
│                                     homepage, repository, license, keywords, userConfig.inject_rules
├── README.md                         hand-written, except the generated COMPONENTS block
├── LICENSE  NOTICE.md  CHANGELOG.md  NOTICE.md records the upstream commit the rule files came from
├── hooks/hooks.json                  one SessionStart hook
├── scripts/session-context.sh        what the hook runs; prints the compact rules only if opted in
├── docs/
│   ├── DESIGN.md                     the component map and the reasons components are distinct
│   ├── COMPONENTS.md                 generated catalog of every component and how to invoke it
│   └── TRACEABILITY.md               generated: upstream section -> components that apply it
├── skills/
│   ├── principles/SKILL.md           the hub: routing table to every other component
│   ├── principles/references/        full.md, mini.md, nano.md: unmodified upstream rule sets
│   └── <name>/SKILL.md ...           topical skills and manual workflow skills
├── agents/<name>.md ...              subagents
└── output-styles/<name>.md ...       output styles
```

Claude Code prefixes every component with the plugin name, so a skill `review` in `clean-code` is `/clean-code:review`. Component names therefore do not repeat the plugin name. The forms used throughout these docs, which `scripts/lib.mjs` also uses when it generates the catalogs, are:

| Component | Form |
| --- | --- |
| Skill | `/<slug>:<name>` |
| Subagent | `@agent-<slug>:<name>` (the Claude Code docs describe `@agent-` followed by the scoped name for plugin subagents) |
| Output style | `/output-style <slug>:<name>` |

At the time of writing there are 14 plugins with 817 components: 433 skills, 300 subagents and 84 output styles. Each plugin has between 55 and 60. Run `node scripts/validate-all.mjs --no-cli` for the current table.

## 3. The four component types

A plugin has four kinds of component. They exist because they answer four different questions, and they differ in what they cost.

| Type | Files | Started by | In context on every turn | Runs where |
| --- | --- | --- | --- | --- |
| Model-invocable skill | `skills/<name>/SKILL.md` | Claude, matching your task against the description; or you, by typing the command | Name and description. The body loads only when the skill is used. | The main conversation |
| Manual skill | `skills/<name>/SKILL.md` with `disable-model-invocation: true` | You, by typing the command | Nothing. The skills docs say the description of such a skill is not in context. | The main conversation, or a separate subagent when the skill sets `context: fork` |
| Subagent | `agents/<name>.md` | Claude, matching the task against the description; or you, by name or `@agent-` mention | Name and description. The prompt body loads only when the agent runs. | Its own context window; a summary comes back |
| Output style | `output-styles/<name>.md` | You, with `/output-style <slug>:<name>` | Nothing until selected; then the whole body, on every request | The main conversation. Subagents run their own system prompt, so a style does not change how they respond. |

### Model-invocable skills: the rules

These hold one rule cluster each, usually one upstream section or a coherent slice of a large one (a smell catalog, a pattern family). The `description` is a trigger: "Use when ..." followed by concrete signals. Claude sees the description on every turn and loads the body when the task matches, so the description is where the cost is. The validator caps each plugin at 20 model-invocable skills and fails a description over 500 characters (it warns above 300). Today every plugin has 18 to 20. The body has fixed sections: when to use, numbered rules (each with what to do, why, and how to check), a procedure, an original example, anti-patterns, trade-offs and exceptions, verification questions, related components and a `Source` section.

The hub, `principles`, is also model-invocable. It states when the book applies, the bias it corrects, how to load the rules, the modal convention, and a routing table from situation to the exact skill, agent or output style that handles it. The routing table covers every component in the plugin, which makes the hub the one place to start when you do not know which component to use.

### Manual skills: the workflows

A workflow is something you decide to run: review this diff, audit this directory, plan this change, fix these findings. Letting Claude start one on its own would be wrong for the ones that edit files, and wasteful for the rest, because an always-visible description would cost context for something that is rarely wanted unprompted. So these set `disable-model-invocation: true`, and the validator requires at least 8 per plugin and an `argument-hint` on each. Every plugin has `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`, plus book-specific workflows named for what the book teaches (`find-seam` in `legacy-code`, `failure-mode-scan` in `release-it`, `choose-pattern` in `enterprise-patterns`).

The spec has each manual skill treat `$ARGUMENTS` explicitly, including the empty case, which defaults to the current git diff. Skills that scan a whole directory or flow set `context: fork`. Per the skills docs, Claude Code then starts a new subagent and gives it the skill body as its prompt; the subagent does not see your conversation, and the docs say it runs in the background by default and returns a summary to the conversation. That is why a fork skill must be self-contained and why the spec caps its result at 40 lines: a repository-wide scan reads many files, and forking keeps that reading out of the main conversation. Every plugin has at least two (the minimum today is 2, the maximum 4, in `ddd-distilled` and `data-intensive-apps`).

### Subagents: isolated specialists

A subagent has its own context window, its own tool list and its own system prompt. The plugins use them for three reasons: a reviewer reads many files and should not fill the main conversation with them; a reviewer should not edit files, and `disallowedTools: Write, Edit` removes those two tools from it, whereas a skill can only ask (a reviewer still has `Bash`, which its instructions limit to read-only commands such as `git diff`; that limit is an instruction, not a permission); and one concern per reviewer gives each its own output format (a naming reviewer reports a vocabulary table, a concurrency reviewer a shared-state inventory).

Each plugin has the same roles:

- `lead`: the router, on `opus`, read-only. It reads a task or diff and names which specialists and skills to run, in what order. The spec caps its run list at five steps (quality bar, rule 15), and the validator fails a plugin whose `lead` does not state that cap. It does not review.
- About a dozen specialist reviewers, read-only (`disallowedTools: Write, Edit`), each paired with the topical skill of the same cluster.
- A few implementers, with `Edit` and `Write`, that make the smallest behavior-preserving change, run the project's tests and never commit or push.
- `final-gate`: runs the book's final checklist against the working diff and returns PASS or FAIL with evidence.

Across the 14 plugins the models are 14 `opus` (the leads), 4 `haiku` (mechanical scanners) and 282 `sonnet`. An agent preloads its cluster's model-invocable skill through the `skills` field (the spec allows one to three; today 227 agents preload one, 66 preload two, 4 preload three and 3 preload none). The Claude Code docs say the full content of each listed skill is injected into the subagent at startup, and that a skill with `disable-model-invocation: true` cannot be preloaded; the validator enforces that every listed skill exists in the plugin and is model-invocable. The agent body adds a fallback line telling it to read the skill file if the rules are not in its context.

Agents are not free. The Claude Code docs say the description of every subagent takes up context in the main conversation, and they describe a startup warning when the combined descriptions of non-built-in subagents exceed 15,000 tokens. See the cost model below.

### Output styles: session-wide behavior

A style changes how the whole session behaves, not what a single task does. Claude Code sends the active style's instructions with every request. Each plugin has `mentor`, `strict-reviewer`, `pair` and `terse` plus at least one book-specific mode (`smell-first`, `failure-first`, `tracer-first`, `architect`, and so on). The spec requires each to change observable behavior and not only tone: `strict-reviewer` answers as a ranked findings table and says "No findings" explicitly; `pair` asks before any change larger than a few lines. Each style also states what it leaves unchanged: destructive-action confirmations, failing test output and security warnings.

Two frontmatter rules are enforced. `keep-coding-instructions: true` is required, because a custom style otherwise drops Claude Code's built-in software engineering instructions (per the output styles docs), and these styles change how Claude communicates, not how it codes. `force-for-plugin` must not be true, because it would apply a style whenever the plugin is enabled and override the user's choice; with 14 plugins installed that would be several styles fighting.

### Cost model

| Component | Cost while idle | Cost when used |
| --- | --- | --- |
| Model-invocable skill | name and description, every turn | body, when loaded |
| Manual skill | none, per the skills docs | body, when you run it |
| Subagent | name and description, every turn | its own context window; only a summary returns |
| Output style | none until selected | whole body, every request while selected |
| Hook | none; it runs a script, and the script prints nothing unless opted in | the compact rules, once per session start, when opted in |

Claude Code can estimate the idle cost of an installed plugin: `claude plugin details <name>` prints an "Always-on" figure and a per-component table, and `claude --plugin-dir ./plugins/<slug> plugin details <slug>` does the same for a plugin loaded from disk. The figures below are those estimates from Claude Code 2.1.286, rounded; treat them as estimates.

- One plugin: 3,127 tokens (`clean-code`) to 3,860 (`enterprise-patterns`).
- All 14 together: about 48,400 tokens. Of that, about 20,300 are agents and about 20,700 are model-invocable skills (the per-component figures are rounded, so the parts do not sum exactly to the total).
- The estimator also attributes about 8,000 of the 48,400 to manual skills (roughly 450 to 750 per plugin), although the skills docs say their descriptions are not in context. So the estimate is probably high by about that much. The difference was not measured in a live session.
- Agents and model-invocable skills contribute about equally, roughly 1,300 to 1,600 tokens per plugin each. By the estimator, the agents of all 14 plugins together are above the 15,000-token threshold the sub-agents docs mention. Whether the warning appears was not tested.

This is why the repository tells people to install a few plugins, not all of them. The caps (20 model-invocable skills, short descriptions) make one plugin affordable; they do not make 14 plugins cheap.

## 4. Progressive disclosure

A plugin holds far more text than should ever be in context at once, so it is layered. Each layer is read only if the layer above did not settle the question.

```text
Always in context (idle cost)
    description of each model-invocable skill and each subagent
        |  a task matches, or you type a command
        v
skills/<name>/SKILL.md               rules, procedure, example, Source (at most 500 lines)
        |  the hub and most workflows: "Read references/mini.md first"
        v
skills/principles/references/mini.md    3.8 to 8.1 KB   compact rule set, with its own priorities
        |  only when mini does not settle a trade-off; read by section name
        v
skills/principles/references/full.md    11 to 63 KB     the complete upstream rule set

skills/principles/references/nano.md    1.2 to 2.8 KB   smallest form; injected only if opted in (section 6)
```

The sizes are the vendored files' sizes in bytes across the 14 plugins (`wc -c`). The three files are unmodified copies of the upstream `full`, `mini` and `nano` rule sets. The upstream usage guide recommends a similar shape: `mini` as the default working layer, `nano` only where context is very tight, `full` for audits and reference. The skills follow it. The one exception is the opt-in hook, which injects `nano` rather than `mini` to keep its always-on cost small (section 6).

Where each layer is read from, counted over the current files:

- The hub reads `${CLAUDE_SKILL_DIR}/references/mini.md` first and `full.md` only when mini does not settle a trade-off, naming the section it needs. Workflows read `${CLAUDE_PLUGIN_ROOT}/skills/principles/references/mini.md`: 96 of the 158 manual skills do. A few workflows also point at a named `full.md` section when they need a table that only the full file has (`smell-to-treatment` in `refactoring-guru` reads its priority map). The validator checks that every `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` path in a component exists.
- A workflow reads the topical skills it needs when it needs them, not all of them up front. `review` classifies which clusters a diff touches, using the hub's routing table, and reads only those skills.
- Topical skills are self-contained cluster bodies; only 4 of them mention the reference files. Agents do not read the reference files: their rules come from the preloaded cluster skill, or from that skill's file as a fallback.

Large scans avoid loading anything into the main conversation: a fork skill or an agent reads many files in its own context and returns at most a short report.

## 5. Traceability

Every component ends with a `## Source` section. It is a bullet list with one upstream heading per bullet, first on the line and in backticks, spelled as it appears in `references/full.md` (case-insensitive). A note may follow the heading when only part of the section applies:

```text
## Source

- `Naming rules`
- `Smells to detect and eliminate`: only the name, trust-by-reading and magic number smells.
```

Three things use these sections.

1. **The validator checks citations.** Each cited heading must exist among the `##` and `###` headings of `full.md` (headings inside code fences are ignored). A citation that does not match fails the plugin, which catches typos and also catches an upstream rename.
2. **The validator enforces coverage.** Every `##` heading of `full.md` must be cited by at least one component. (If a file has fewer than five `##` headings, `###` headings count too.) A section that nothing applies fails the plugin. Today the 14 plugins cover 318 of 318 sections.
3. **`gen-catalog.mjs` writes `docs/TRACEABILITY.md`.** It is a table from each upstream section to the components that cite it, with `NOT COVERED` in bold for a gap and a `Coverage: n/m sections.` line.

What traceability gives a reader: any piece of advice can be followed back to a section of the upstream rules, and from there to the book. What it gives a maintainer: when the upstream rules change, the sections that moved are named by the validator (section 10).

What it does not give: the validator proves that a citation names a real section, not that the cited section supports what the component says. That is a review question (spec section 6, rule 12). Two conventions make the distinction visible in the text. Where a rule exists only in `mini.md` or `nano.md`, or is the plugin's own heuristic, the component labels it ("compact checklist" or "Added judgment"). And the modal strength of the source is kept: an unqualified rule is a MUST, "Prefer" is a SHOULD, "Do not", "Avoid" and "Never" are MUST NOT. A skill that turns a "Prefer" into an absolute is a defect, but not one a tool can find.

## 6. The opt-in hook

Each plugin ships exactly one hook. `hooks/hooks.json` registers a `SessionStart` hook with the matcher `startup|clear|compact` that runs `scripts/session-context.sh`. The script is short bash. It exits silently unless the environment variable `CLAUDE_PLUGIN_OPTION_INJECT_RULES` is `true`, `TRUE`, `True`, `1`, `yes` or `on`. When it is, it prints one header line and then `references/nano.md`. It injects `nano` (1.2 to 2.8 KB) rather than `mini` (3.8 to 8.1 KB) to keep the always-on cost small; the skills read `mini` on demand.

Claude Code exports each plugin option to hook processes as `CLAUDE_PLUGIN_OPTION_<KEY>` with the key in upper case, and the manifest declares the option:

```text
userConfig.inject_rules = { type: boolean, title: "Inject the compact rules at session start",
                            description: "...", default: false }
```

Per the hooks docs, the plain-text output of a `SessionStart` hook is added to Claude's context, capped at 10,000 characters. The largest `nano.md` is 2,823 bytes, so the cap is not a concern. The docs list `resume` and `fork` as separate `SessionStart` matcher values, and this hook does not register for them. What a resumed session does was not tested.

The option is off by default, and the validator makes it a rule that it is: `userConfig.inject_rules` must be a boolean with `default: false`.

Why off:

- **The books disagree.** The upstream project recommends one primary rule set with the others loaded on demand. If the hook defaulted to on, installing three plugins would put three sets of "always apply" rules into every session, and some of them pull against each other (for example on function size and comments). A default has to be safe for someone who installs several plugins.
- **The skills already load the rules on demand.** The hub reads `mini.md` when a decision comes up. The hook is for the one book you want present before the first message.
- **Smallest trust surface.** A plugin hook runs a script on the user's machine at every session start, and the Claude Code docs tell users to review what a plugin adds before installing. With the option off, the script exits before it reads or prints anything. The spec also forbids any other hook, which keeps what a user has to trust down to this one short script.
- **A reminder is not enforcement.** Even when on, the text is an instruction the model may weigh against others. The upstream project lists model non-compliance among its open criticisms.

The validator also checks that `hooks.json` parses, that its `SessionStart` command runs `session-context.sh`, that the script is executable, and that it mentions `CLAUDE_PLUGIN_OPTION_INJECT_RULES`. The script needs `bash`; the rest of a plugin is Markdown.

## 7. Validation and CI

### Commands

```bash
node scripts/validate-plugin.mjs plugins/<slug> [--no-cli] [--quiet]   # one plugin
node scripts/validate-all.mjs [--no-cli] [--quiet]                     # everything
node scripts/gen-catalog.mjs [plugins/<slug>]                          # regenerate derived files
node scripts/build-targets.mjs [--target <id>]                         # regenerate dist/ and the Codex, Cursor and Copilot marketplace files (section 12)
node scripts/validate-targets.mjs                                      # check dist/ against each agent's constraints (also run by validate-all.mjs)
node scripts/mcp-selftest.mjs                                          # protocol checks of the MCP server
```

Errors fail the run (exit code 1). Warnings never do. `--no-cli` skips the call to the official `claude plugin validate`; without the flag the call is made, and it is skipped with a warning if the `claude` binary is not found.

### What `validate-plugin.mjs` enforces

Manifest (`.claude-plugin/plugin.json`):

- The slug is in `scripts/books.json`. `name` equals the directory name, is kebab-case, and is not reserved (`claude-`, `anthropic-`, `anthropics-` and `cc-plugin-` prefixes; `claude`, `anthropic`, `anthropics`, `claude-code`, `claude-mods`).
- `displayName` is present; `version` is semver; `description` is 40 to 300 characters; `author.name` is present; `license` is `MIT`; `homepage` and `repository` are GitHub URLs; there are at least 5 `keywords`.
- `userConfig.inject_rules` is a boolean with `default: false`, a title and a description. Unknown top-level keys produce a warning.

Files:

- These exist and are not empty: `README.md`, `LICENSE`, `NOTICE.md`, `CHANGELOG.md`, `docs/DESIGN.md`, `docs/COMPONENTS.md`, `docs/TRACEABILITY.md`, `hooks/hooks.json`, `scripts/session-context.sh`, `skills/principles/SKILL.md` and the three reference files.
- `LICENSE` is the MIT text and names the repository owner. `NOTICE.md` names the upstream author and repository.
- A scan of the other text files in the plugin for placeholder text (`TBD`, `lorem ipsum`, `<placeholder>`, `[INSERT ...]`, `__UPPER_TOKEN__`).

Counts and names:

- At least 50 components in total, 27 skills, 18 agents and 5 output styles; at most 20 model-invocable skills; at least 8 manual skills.
- The required names exist: skills `principles`, `review`, `audit`, `plan`, `explain-rule`, `checklist`, `fix`; agents `lead`, `final-gate`; styles `mentor`, `strict-reviewer`, `pair`, `terse`.

Every component:

- The frontmatter parses under a deliberately strict YAML subset: values are double-quoted strings, booleans, numbers, bare words, `[a, b]` lists or `- item` lines; block scalars (`|`, `>`), tabs, duplicate keys and unquoted values containing `: ` are rejected. The reason is that Claude Code tolerates frontmatter it cannot parse instead of rejecting the file: for an output style the docs say it still loads under its file name with no fields set, and the parse error is visible only under `claude --debug`. A typo could therefore strip a field without anyone noticing, so the validator is stricter than the loader on purpose.
- Only the keys allowed for the type appear. For agents that excludes `permissionMode`, `hooks`, `mcpServers` and `initialPrompt`, which the Claude Code docs say are ignored for plugin agents.
- `name` equals the directory or file name and is kebab-case, at most 40 characters (for a style, `name` is optional but must be kebab-case if present). A `description` exists. Description length, for skills and agents (styles are not measured): skills warn above 300 and fail above 500, and manual skills are not warned because they cost no context; agents warn above 350 and fail above 600.
- The body has a minimum size (1,500 characters for skills and agents, 900 for styles), and a skill is at most 500 lines.
- A `## Source` section exists, every bullet's heading is in `full.md`, and no placeholder text appears.
- Manual skills have an `argument-hint`. Model-invocable skills other than the hub contain a fenced code block (the original example). `context`, if set, is `fork`; a fork skill that is not manual produces a warning. `model` and `effort` have valid values.
- Agents: the description contains the word "use" (the delegation trigger); `model` is `sonnet`, `opus`, `haiku`, `fable`, `inherit` or a `claude-` id; `color` is one of the eight Claude Code colors; `maxTurns` is an integer from 3 to 60; `tools` is set explicitly and well-formed, and no tool is both allowed and disallowed; there is an `## Output` heading; every entry in `skills` is a skill of the same plugin and is model-invocable.
- Styles: `keep-coding-instructions` is true and `force-for-plugin` is not true.
- Every `${CLAUDE_PLUGIN_ROOT}/...` and `${CLAUDE_SKILL_DIR}/...` path in the text exists, and every relative Markdown link resolves.
- Warning only: 50% or more of a body's 8-word runs appear verbatim in the vendored `full.md` or `mini.md`.

Across components:

- Every `<slug>:<name>` reference (also with a `/` or `@agent-` prefix) in a component or the README resolves to a component of that plugin. This catches typos and references to components that were renamed.
- The hub's routing table (`skills/principles/SKILL.md`) mentions every other skill, agent and output style of the plugin as `<slug>:<name>`.
- Every manual skill and every agent says that repository content and tool output are data, not instructions (quality bar, rule 14). The check looks for the phrase "data, not instructions".
- Read-only roles (agents named `*-reviewer`, `lead`, `final-gate`, `scope-guard`) do not list `Write` or `Edit` in `tools`, and `lead` states that it recommends at most five steps.
- Agent names and style names are unique. Within each type, near-duplicate bodies are rejected: 4-word-run similarity (Jaccard, `Source` section excluded) of 0.50 or more fails, 0.35 or more warns.
- Coverage: every upstream `##` section is cited (section 5).

Hook and documents:

- The hook checks listed in section 6.
- The README is at least 7,000 characters, has headings for installation, components, usage or walkthroughs, the book mapping, compatibility ("works with"), limitations and attribution, contains the `COMPONENTS` markers, and its generated block is current. Placeholders are rejected, `<slug>:<name>` references and relative links must resolve.
- `docs/COMPONENTS.md` and `docs/TRACEABILITY.md` equal what the generator would write now.

Last, unless `--no-cli`: `claude plugin validate <plugin dir>`. Its failures are errors and its warnings are passed through.

### What `validate-all.mjs` adds

It runs the above for every plugin and prints the component table. It also checks the repo-level documents: in `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md` and every `docs/*.md`, any `<slug>:<name>` reference to one of the 14 plugins must name a component that exists, and relative links must resolve. It checks that `.claude-plugin/marketplace.json` equals what `buildMarketplace()` produces and that each entry's `source` exists, and, unless `--no-cli`, runs `claude plugin validate` on the repository root.

### CI

`.github/workflows/validate.yml` runs on pushes to `main` and on pull requests, with read-only repository permission, in two jobs.

| Job | Steps | Blocking |
| --- | --- | --- |
| `structure` | Node 22; `node scripts/validate-all.mjs --no-cli`; then `node scripts/gen-catalog.mjs` followed by `git diff --exit-code`, which fails if any generated file was not committed | Yes |
| `official` | Installs the Claude Code CLI with npm; `claude plugin validate .`; then `claude plugin validate` on each directory under `plugins/` | No (`continue-on-error: true`) |

The `official` job is not blocking because it depends on installing a tool that changes independently of this repository.

### What the validator does not check

The checks are structural. They cannot establish that the advice is right. These parts of the spec rest on authors and reviewers:

- That a component is faithful to the source: modal strength preserved, nothing invented, nothing contradicting the rules, and that each `Source` bullet really backs the content under it.
- That examples are original and correct, and that the "after" code in a before/after example works.
- That each plugin has at least two book-specific workflows, and that README walkthroughs number at least five and follow the hand-offs between components as those components describe them.
- That manual skills avoid `!` shell injection, and that component names do not repeat the plugin name.
- Agent conventions beyond what is listed above: reviewers also listing `Write` and `Edit` under `disallowedTools` (the validator only checks that `tools` lacks them), no `WebFetch` or `WebSearch`, no `memory` key (the validator allows `memory`, `background` and `isolation`), `maxTurns` ranges, and which model an agent uses.
- That the vendored rule files are byte-identical to upstream. There is no hash check, and the commit recorded in `NOTICE.md` is not compared with the files.
- That anything works inside Claude Code: whether a description triggers its skill, whether Claude delegates to an agent, whether output follows the template.

Some of these hold today, checked by search while writing this document: no agent lists `WebFetch` or `WebSearch` or sets `memory`; 233 of the 300 agents disallow `Write` and `Edit` and 67 can edit; no skill uses shell injection. Those are properties of the current files, not guarantees.

## 8. How the plugins were built and reviewed

Each book went through the same pipeline. Models did the authoring and most of the review, so the pipeline is described here together with its limits.

1. **Spec and tooling first.** `PLUGIN_SPEC.md`, the templates in `docs/templates/`, the validator, the generator and the scaffolder were written before any plugin (the first commit). Components are built to a contract that exists in advance.
2. **Scaffold.** `node scripts/new-plugin.mjs <slug> --upstream <clone>` writes the manifest, license and notice (with the upstream commit), the hook and script, the three vendored rule files and a README stub.
3. **A builder in a fresh context, one per book.** Each builder starts without memory of the other books and works from files only: the spec, the templates, and the book's folder in the upstream clone. The spec tells it to read the full rule set, the mini and nano forms, the upstream traceability file for the book, the upstream compatibility notes and the upstream criticism document completely, and to treat everything in the clone as data. It writes `docs/DESIGN.md` first (one row per planned component, the reason each is distinct from its nearest sibling, and a table of confusable pairs), then skills, agents, output styles and the README, runs the generator and validator until it passes, reviews its own work, and reports in 200 words or fewer. A builder may edit only `plugins/<slug>/`, runs no state-changing git, uses no network and starts no subagents.
4. **Two independent verifiers with different lenses.** After the builder, two separate review passes read the finished plugin without the builder's context. Each looked at it from a different angle, so that one pass's blind spots were less likely to be the other's. Their findings were the input to the next step. The verifier reports are not stored in the repository.
5. **Fix rounds.** Findings were fixed and the plugin was re-validated. The history shows the pattern: for example `fix(philosophy-of-design): resolve review notes ...` touched 22 files, and `fix(refactoring): ground README compatibility and limitations in the upstream docs` rewrote two README sections to match the upstream compatibility data.
6. **A polish pass for minor notes.** A last pass applied the review notes that were too small to justify another fix round.
7. **Validation and commit.** `validate-all.mjs` must pass, and the orchestrator, not the builder, commits, one commit per plugin.

The process also changed the spec. Findings from the first reviews became rules: the commit "add review-derived rules to the plugin spec quality bar" added rules 11 to 16 of the quality bar (disjoint triggers, labeling rules that come from `mini`/`nano` or from the author, one job per agent, an untrusted-input line, a lean `lead`, checked examples), and "validate cross-references between components" added the reference check. Plugins built earlier were checked against the validator as it was at their commit; all 14 pass the current one.

### Limits

- **Verification is by model reviewers plus mechanical checks.** The only outcome measured is the eval suites ([EVALS.md](EVALS.md): small planted-problem fixtures, all 14 plugins, one run per case); no real project was measured, and there is no data on defects in shipped code, review time or whether the agents follow their templates. The definition of done includes a human reading three components at random (spec section 1); nothing in the repository records that this was done for each plugin and no tool enforces it.
- **Builders and reviewers are models of the kind the plugins are meant to steer.** Shared blind spots are possible. "Faithful to the book" also rests on the upstream rule sets being faithful to the books, which this project did not audit. The upstream project lists measurement and legal review among its unresolved criticisms.
- **The mechanical checks cover structure.** Section 7 lists what they do not cover.
- **Small rule sets reach the 50-component floor by separating role and situation.** A short rule set gets a rules skill, a workflow skill, a reviewer and an implementer for the same cluster, and components for distinct situations (a plan, a scan, a gate). The spec forbids reaching the floor by rewording one idea (quality bar, rule 13). That is a judgment, and the floor itself invites padding: the size floors and the near-duplicate check are a tripwire, not proof that every component earns its place.
- **A few overlaps remain by design.** Each `DESIGN.md` records how close components were separated, under "Confusable pairs" (model-invocable skills whose descriptions could fire on the same request, with the clause that separates them), "Overlap review", or both. The near-duplicate check only sees textual similarity; two components can overlap in purpose with different words. Report overlaps through the "Rule accuracy" issue template or a pull request that merges the two.

## 9. Design decisions and trade-offs

**One plugin per book, not one plugin.** Cost scales with what is installed, the books disagree with each other on purpose, and people use the book that fits the task. The price is repetition: the same short names (`review`, `lead`, `mentor`) appear in every plugin, so a prefix is always needed, and a user has to know which book to reach for. [COMPATIBILITY.md](COMPATIBILITY.md) is the guide for that choice.

**The same skeleton in every plugin.** Required names make `/<slug>:review` and `@agent-<slug>:final-gate` mean the same kind of thing everywhere, so a user learns the layout once. The price is that a fixed set of workflows fits some books less well. The spec's answer is at least two book-specific workflows and at least one book-specific style per plugin.

**Plugins refer to each other by name, never by command.** A plugin names another book in backticks and never links to its folder or calls its components, because the other plugin may not be installed. The validator only resolves references to a plugin's own slug. The price: hand-offs between plugins are done by the user, not by the components (see [USAGE.md](USAGE.md)).

**Clusters follow the upstream sections.** Where one section is large, it is split along the seams a reader meets in code, not along the order of the bullets. Every smell in a catalog has exactly one owning skill, which keeps two skills from firing on one symptom. The price is a long list of skills; the hub's routing table is the counterweight.

**Specialist agents, with a router and a gate.** Many narrow reviewers give isolation, least-privilege tools and separate output formats. A single large reviewer would give none of that and would load every rule. The price is the idle cost of every agent description, and overlapping reviewers if the lead recommends too many; the spec caps the lead at five steps and the validator enforces that every lead states the cap.

**Reviewers have no edit tools; skills can only be asked not to edit.** For agents, Claude Code applies `tools` and `disallowedTools`: all 233 read-only agents list `Read, Grep, Glob, Bash` and disallow `Write` and `Edit`. For a skill, the docs say `allowed-tools` pre-approves tools and does not restrict the others, so a manual skill that "never edits" is following its own instructions, and the Bash it pre-approves is limited to read-only git commands. The honest summary: the strongest enforcement is the missing `Write` and `Edit` on reviewers. `Bash` is still there, and its read-only limit is an instruction.

**No component commits, pushes, resets, cleans, deletes recursively, publishes or downloads.** Implementers run the project's own tests, report when none can be found, and never invent a passing result. They stop and ask when a fix needs a behavior change. The permission settings of Claude Code are still the real guard; the components only avoid asking for those actions.

**The upstream rules are vendored, not referenced.** Each plugin is self-contained and works offline once installed, and the paths the components read are guaranteed to exist. The price is duplication (the 14 sets of `full`, `mini` and `nano` files total about 396 KB) and drift when upstream changes. `NOTICE.md` records the upstream commit, and the validator turns most upstream changes into errors (section 10).

**A strict frontmatter subset.** See section 7. The cost is that authors cannot use YAML conveniences such as block scalars.

**The hook is opt-in and singular.** See section 6.

**Output styles keep the coding instructions and are never forced.** See section 3.

**Generated files are committed and checked in CI.** `COMPONENTS.md` and `TRACEABILITY.md` can be read on GitHub without running Node, and a stale one fails the build. The price is noisy diffs when a component changes.

**Versions are per plugin and are bumped for every shipped change.** The Claude Code docs say that a `version` set in the manifest keeps users on that version until it changes. A change shipped without a bump does not reach people who already installed the plugin. `CONTRIBUTING.md` sets the rule: patch for wording, minor for new components, major for renamed or removed ones.

## 10. Adding a book and updating the upstream rule sets

### Adding a book

1. Confirm the upstream clone has `<dir>/<dir>.md`, `<dir>.mini.md` and `<dir>.nano.md`. The scaffolder exits if any is missing.
2. Add an entry to `scripts/books.json`: `slug`, `upstream` (the folder name in the clone), `title`, `bookAuthor`, `category`, `usefulWhen` and `keywords`.
3. Scaffold:

   ```bash
   node scripts/new-plugin.mjs <slug> --upstream "<path to agent-rules-books>"
   ```

   The scaffolder refuses to run if `plugins/<slug>/` exists. Do not use `--force` on a finished plugin: it rewrites the manifest, `CHANGELOG.md`, `NOTICE.md`, the hook, the vendored files and the README stub, and would erase hand-written work.
4. Build to the spec, in its order: read the source completely, write `docs/DESIGN.md`, then skills, agents, output styles and the README.
5. Regenerate and validate:

   ```bash
   node scripts/gen-catalog.mjs plugins/<slug>
   node scripts/validate-plugin.mjs plugins/<slug>
   node scripts/gen-catalog.mjs
   node scripts/validate-all.mjs
   ```
6. Update the places that are written by hand and mention the set of books: the table of works in the root `NOTICE.md`, the marketplace `description` in `scripts/books.json` and the root `README.md` (both say how many plugins there are), the counts in these docs, and `CHANGELOG.md`. Then open a pull request; the template has the checklist.

### Updating from a newer upstream

There is no update script. The procedure is manual, and the validator does the detection.

1. Update the local clone of `ciembor/agent-rules-books` and note its new commit hash.
2. For each book, compare the three upstream files with the vendored ones (`diff -u`). The upstream `_rule-workbench/<dir>/traceability.md` shows how its `mini` rules map to `full` sections.
3. Copy the changed files over `plugins/<slug>/skills/principles/references/` unchanged, and put the new commit hash in the plugin's `NOTICE.md`.
4. Run `node scripts/gen-catalog.mjs` and `node scripts/validate-all.mjs`. Upstream changes show up as:
   - a renamed or removed heading: `Source cites "X" which is not a heading in references/full.md`, once per citing component;
   - a new heading: `N/M upstream sections are not cited by any component`, with the names;
   - a changed rule under an unchanged heading: nothing. Only reading the diff finds this, so read it.
5. Update the components that apply the changed sections, their `Source` bullets and `docs/DESIGN.md`. Keep the modal strength of the new text.
6. Bump the plugin `version`, add a line to its `CHANGELOG.md`, regenerate and validate again.

## 11. Known limitations

- **No measured effect on real projects.** The eval suites show that a plugin's review workflow finds more planted problems than the model alone (all 14 plugins measured, one run per case); nothing shows that the plugins improve real code. The upstream project says the same about its rule sets. Treat the output as structured review comments.
- **Context cost is real.** Section 3 has the numbers. A plugin is affordable; several are not cheap. Plugin skills cannot be turned off one at a time: the skills docs say `skillOverrides` does not apply to plugin skills and point to enabling or disabling the whole plugin.
- **Model-written, model-reviewed.** See section 8. A human reading is the strongest check that has not been done systematically.
- **Instructions, not guarantees.** A skill, a style and an agent prompt are instructions the model may not follow. What is enforced is the agent tool lists (reviewers have no `Write` or `Edit`, but they do have `Bash`) and Claude Code's permission system.
- **Output styles do not reach subagents.** A reviewer answers in its own template whatever style is selected.
- **The hook does not register for `resume` and `fork`.** See section 6.
- **No cross-plugin awareness.** Overlapping books (the general-engineering ones, the three DDD books) are not coordinated by the components. The user picks a primary and an arbiter; [USAGE.md](USAGE.md) says how.
- **Validator blind spots.** Section 7. In particular, a wrong paraphrase of a rule passes if it cites a real section.
- **The idle-cost estimate is an estimate.** It comes from `claude plugin details`, which counts manual skills that the skills docs say cost nothing, and the numbers will move with Claude Code versions.
- **Marketplace metadata.** `metadata.version` in `marketplace.json` is a constant (`1.0.0`) in `buildMarketplace()`; only each plugin's own `version` changes.
- **Legal and attribution.** The plugins paraphrase rule sets and use original examples. The vendored upstream files are MIT-licensed and credited in each `NOTICE.md`. The upstream project lists legal review among its unresolved items, and this project has not had one either.

## 12. Builds for other coding agents

`plugins/` is written for Claude Code and stays the only hand-written source. `scripts/build-targets.mjs` turns it into `dist/`, with one module per
target under `scripts/targets/`. The full per-agent guide is [AGENTS_SUPPORT.md](AGENTS_SUPPORT.md); this section explains how the build is put together.

**One rewrite engine, one dialect per target.** Components use a small, regular set of Claude-specific constructs (counted across all 817: about 3,700
`/plugin:skill` references, 1,560 `plugin:agent` references, 517 `${CLAUDE_PLUGIN_ROOT}` and 42 `${CLAUDE_SKILL_DIR}` paths, 322 `$ARGUMENTS`, 104
`/output-style` references). The syntax of each reference decides what it points at: `/output-style p:x` is a mode, `/p:x` a skill, a bare `p:x` an agent
(or, in 38 places, a skill). `core.mjs` rewrites them in one pass per text, so a result is never rescanned, and each target supplies a dialect that says how
that agent spells a skill, an agent, a mode, and a path from a skill or from an agent (an agent has no fixed install folder, so it is told to "load the skill").
After rewriting, the validator fails any file in which a `${CLAUDE_*}` variable, `$ARGUMENTS`, `/output-style`, an unresolved `plugin:name` (placeholders such as `plugin:<skill>` included) or a Claude-only claim (a forked or isolated context, the SessionStart hook, "the default style") survived.

The rewrite also decides which backticked names are references. An agent name always is. A skill name is, when hyphenated, unless it sits in a list of other words (the directory names `application`, `use-cases`, `usecases` stay as written); a one-word skill name is only when it is certain: in a description, in a list with another component, or alone in a table cell under a "Skill" or "Agent" column. Verbs are lower-cased after a comma ("..., load the skill first"). Text that has no meaning outside Claude Code is replaced for every target: skills with `context: fork` are described as running in the current session, the hook sentence in each hub points at `dist/rules`, and "the default style" becomes "your default behavior". The maintainers' component map (`docs/DESIGN.md`) is shipped only where a skill refers to it.

**Names.** Skills keep their meaning but not their namespace: 317 distinct directory names cover 433 skills, and 7 skill names (the `principles` hub and six workflows) repeat in all 14 plugins. Agents
that keep one flat list (the Agent Skills installer, OpenCode, Gemini, Copilot, Cursor) get `<plugin>-<name>`; Codex namespaces plugin skills itself, so its skills keep their
names and its roles, which are global, get the prefix. An output style becomes `<plugin>-mode-<name>` (Codex: `mode-<name>`) so that it can never collide with a skill of the same name; at the time of writing no plugin has such a pair.

**Trees only where a format needs one.** The universal Agent Skills folders are spec-clean (`name`, `description`, `license`, `metadata` only; `skills-ref` accepts all 517).
OpenCode, Cursor and Copilot reuse those folders byte for byte, and the validator enforces that, so git stores one copy of each (at the time of writing `dist/` is about 30 MB of file content, and the committed history packs to about 6 MB).
Codex gets its own tree because it namespaces by plugin, hides manual skills through `agents/openai.yaml`, and ships its roles as TOML inside a hidden `install-roles` skill (a Codex plugin cannot activate roles itself, so that skill copies them to where Codex reads them).
Gemini gets its own tree too, for a cost reason: it lists every skill in every request and puts every skill name into one tool schema, so only the rule skills stay skills and the 242 manual workflows and modes become slash commands (`commands/<plugin>/<name>.toml`, `{{args}}` for the arguments), which cost nothing until run.

**Features without an equivalent.** Output styles become persona skills, Gemini commands, OpenCode primary agents or Copilot agents. An OpenCode primary agent replaces the provider's system prompt (measured at about 8.6 KB), so a mode agent restates a short baseline of everyday conventions and allows the `question` tool it would otherwise lose. The opt-in hook becomes `AGENTS.md` snippets (`dist/rules`),
because only one book should be always on and a file every agent reads needs no hook. Per-agent tool lists, model names, colors and skill preloading are dropped (turn limits survive as OpenCode `steps` and Gemini `max_turns`)
where the target rejects them (Codex rejects a role file with any unknown key; OpenCode 1.x refuses to start on a Claude-style `tools:` line) and replaced by what the target does have: OpenCode permission
maps, Gemini tool lists and a deny-only policy file, and plain instructions elsewhere. Role descriptions are shortened (`briefDescription`) for Codex and Gemini, which list every role in every request.

**MCP.** `dist/mcp/catalog.json` indexes all 817 guides and `scripts/mcp-server.mjs` serves them over stdio with no dependencies: four tools, every guide and rule file as a resource, and the
workflows, modes and subagent roles as prompts. `--plugins` limits what it exposes, since a harness pays for what it lists.

**Checks.** `validate-targets.mjs` enforces each agent's constraints (skill names and sizes, Codex role keys and the roles of each plugin, OpenCode forbidden keys and the read-only shell rules (checked against probe commands, and against the commands each role's text allows), the baseline and `question` permission of mode agents, Gemini's strict agent schema and tool names, its commands (only `description` and `prompt`, no `!{` or `@{`, `{{args}}` wherever a workflow takes arguments) and its policy files (an offline re-implementation of Gemini's decision against 66 probe commands, for every read-only role, plus Gemini's own ReDoS heuristic, because a rule it rejects is dropped silently),
byte-identical flat targets, resolvable relative paths and catalog completeness). CI rebuilds `dist/` and fails on any difference, parses all Codex roles, Gemini commands and policies with a real TOML parser and runs the MCP self-test.
What is not checked in CI: the real agents themselves. They were run by hand (versions and results in [AGENTS_SUPPORT.md](AGENTS_SUPPORT.md#what-was-verified)); a live model session was run in Codex only, seven short runs on one plugin ([the record](verification/codex-live-2026-10-20.md)). `scripts/verify-gemini-policy.mjs` checks the Gemini policy files against Gemini's own policy engine, from an installed copy of the CLI.

**Limits specific to this build.** Read-only roles are only as strong as each agent allows: OpenCode denies the edit tools and limits the shell to an allowlist, and Gemini denies the write tools and any shell command outside an allowlist (both guard rails that match command text, not sandboxes). Codex relies on instructions unless the session itself runs read-only (`codex --sandbox read-only`, which a subagent inherits; checked live). The Cursor build follows the vendor's documents but was not run; the Copilot build was installed and listed by the real CLI but not used with a model.
Gemini loads every skill name into one tool schema (277 names with all 14 extensions after the move to commands), and whether the API accepts that was not tested. Codex's skill catalog and role list have a context budget that makes installing all 14 plugins impractical.

## 13. The layer around the books: evals, presets, project settings, review in CI

The 14 plugins are the content. Four things sit around them so that the content is measurable, easy to pick, adjustable per project and usable without a
person at the keyboard. None of them changes what a book says.

**Evals (`evals/`, `scripts/run-evals.mjs`).** One suite per plugin, outside `plugins/` so it is not shipped. A case is a small fixture with five to seven planted
violations of the book's rules (the scaffold writes the files into the empty workspace of `claude plugin eval`) and one `llm` grader per violation; a control case is
code that follows the book and is graded for false alarms. The runner copies the plugin and its suite into a temporary folder, generates for every case a slash variant
(`/<plugin>:review <path>`, the same graders plus checks on the report format) and runs two passes: the natural prompt with and without the plugin (the harness's
ablation arm), and the slash variants plugin-only. `docs/EVALS.md` is generated from the committed summaries. What the pilot taught, and why the cases look the way
they do: one obvious defect does not separate the arms because a capable model finds it anyway; a control must be clean by the book's own rules or the judge
punishes honest correctness remarks; and a natural review prompt barely makes the model call the plugin's skills, so the suites record whether it did.
Limits: one run per case is noise-prone, the fixtures and graders are written by the same project that wrote the plugins, and a model judges a model.

**Presets and the `guided` companion (`meta/`, `scripts/presets.json`, `scripts/core.json`).** A preset is one primary book plus up to two books rated Complementary
with it and with each other (the validator enforces that from the pair table in `docs/COMPATIBILITY.md`). Claude Code plugins can list `dependencies`, so each preset
is a bundle plugin without components whose manifest depends on its books and on `guided`; installing it installs them all (checked with the real CLI). `guided` holds
six skills: `start`, `which-book`, `config`, `review` (across books), `conflicts` and `ci-setup`. Everything under `meta/` that is derived is generated by
`scripts/gen-guided.mjs` (the book catalog, the 91 pair verdicts, copies of the schemas and guides the skills read, the bundles, the presets table in the README) and
checked in CI, so it cannot drift. `core.json` names the nine components to start with in each book (the four universal workflows, `lead`, `final-gate` and the first
three specialist skills of the book's routing table); it is derived by `scripts/gen-core.mjs` and may be edited by hand. The bundles and `guided` exist for Claude Code
only: the other agents have no plugin dependencies, so `scripts/install-preset.mjs` prints one command per book instead.

**Project settings (`.guided-plugins.json`).** An optional file in the user's repository: `primary`, `secondary`, `strictness`, `ignore`, `maxFindings`, `failOn`. The text that makes the books read it
is inserted by `scripts/apply-project-settings.mjs` into the hub, five workflows and two agents of every book (idempotent, marked, checked by `validate-meta.mjs`), so it is
identical everywhere and flows to every target build. These are instructions to a model; the CI runner applies `ignore`, `strictness` and `maxFindings` a second time in code.
The combined review (`/guided:review`) cannot call a book's own `review` workflow (workflows are manual skills, which a model cannot invoke), so it uses the books' subagents:
one `lead` per book routes, at most three read-only reviewers per book run in parallel, the main thread merges duplicates, moves a secondary book's contradiction of the
primary book into `disagreements` and applies the settings. It costs several single-book reviews.

**Review in CI (`scripts/guided-review-ci.mjs` and friends).** `claude -p` with `--json-schema` returns a validated object (`structured_output`); `docs/findings.schema.json` is
that schema (the runner drops its `$schema` keyword before passing it, because the CLI rejects the draft 2020-12 URI; anyone calling `claude --json-schema` directly must do the same). `findings-lib.mjs` validates, sorts and converts it to SARIF 2.1.0, GitHub review comments (inline
only on changed lines, the rest in the body, a marker per finding, a hash of the book, the rule, the path and the text of the cited line, so a re-run does not repeat a finding that is worded differently but is the same; a finding the model reports for different text or under a different rule name is posted as new) and Markdown. The runner builds the diff, applies the settings, runs
the review with read tools and read-only `git` only and a budget ceiling, writes the files and exits 0, 1 (gate) or 2 (could not run, which a hook treats as "let the
push through" and the Action treats as a failure). The composite action in `.github/actions/guided-review` wraps it; `scripts/git-hooks/pre-push` and `install-git-hook.mjs`
are the local form. `scripts/selftest-ci.mjs` tests all of it with stand-ins for `claude` and `gh`; one real run of the combined review through the runner (2026-10-25,
`clean-code` + `refactoring` on a small diff) returned a schema-valid report for about $1.1. The Action itself has not run on GitHub: the repository has no remote.

