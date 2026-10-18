# Using the Guided Plugins

This guide is for people who want to install the plugins and use them. It covers installing, updating and removing them, turning on the optional always-on rules, how to invoke each kind of component, how to choose plugins, ten recipes with real commands, how to combine plugins, how to keep context cost down, troubleshooting, and a short FAQ. For how the plugins are built and checked, see [ARCHITECTURE.md](ARCHITECTURE.md).

The plugins are unofficial. They are not affiliated with or endorsed by the authors or publishers of the books they are named after. They apply each book's rules consistently and traceably; this project does not claim they improve code quality, and the upstream rule sets they are built on say their effect is not measured.

Claude Code commands in this guide come from the official documentation at code.claude.com/docs, checked on 2026-10-16, and from running Claude Code 2.1.286. Where a command needs a newer version, the version is noted. Run `claude plugin --help` to see what yours supports.

## Contents

1. [Install, update, uninstall](#1-install-update-uninstall)
2. [Turn on the always-on rules (inject_rules)](#2-turn-on-the-always-on-rules-inject_rules)
3. [Invoke skills, agents and output styles](#3-invoke-skills-agents-and-output-styles)
4. [Choose plugins](#4-choose-plugins)
5. [Ten recipes](#5-ten-recipes)
6. [Combine plugins safely](#6-combine-plugins-safely)
7. [Context cost and how to keep it small](#7-context-cost-and-how-to-keep-it-small)
8. [Troubleshooting](#8-troubleshooting)
9. [FAQ](#9-faq)

## 1. Install, update, uninstall

There are three ways to get a plugin: from the GitHub marketplace (once it is published), straight from a local folder for one session, or from a local folder registered as a marketplace.

The second and third ways need a clone of this repository. Clone it once and work from its root; the URL works once the repository is published at github.com/Nouran99/guidedplugins, and until then you can use any copy of the folder you already have:

```bash
git clone https://github.com/Nouran99/guidedplugins
cd guidedplugins
```

A plugin loaded with `--plugin-dir` is read from that folder for one session. A marketplace added from a local folder is read from that folder in place, so moving or deleting the clone breaks the plugins you installed from it.

### From GitHub

Once the repository is published, the marketplace path is `Nouran99/guidedplugins`. The marketplace is named `guided-plugins`.

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install clean-code@guided-plugins
```

The first command registers the marketplace. The second does not install immediately: inside a session it opens the plugin's details so you can see what it adds and choose a scope. After you choose, Claude Code prints an install summary that says whether the plugin is active or needs `/reload-plugins`. To confirm, type `/` and look for `/clean-code:review`, or run `claude plugin list` in a shell.

The same steps from a shell, with no session:

```bash
claude plugin marketplace add Nouran99/guidedplugins
claude plugin install clean-code@guided-plugins
claude plugin install release-it@guided-plugins --scope project
```

Plugins installed from a shell load the next time you start Claude Code, or when you run `/reload-plugins` in an open session. Once the plugin is loaded, run `/clean-code:review` from a session inside your own project. If the plugin's output styles are not listed by `/output-style`, see section 3.

On Claude Code 2.1.286 the shell install ended with a line saying that 1 userConfig option is not yet set and naming `/plugin configure clean-code@guided-plugins`. That option is `inject_rules`. It defaults to off and you can ignore the message unless you want the always-on rules (section 2).

To add the marketplace and install in one command (the shell form needs Claude Code 2.1.292 or later, the in-session form 2.1.275 or later):

```bash
claude plugin install clean-code --marketplace Nouran99/guidedplugins
```

You can pin a branch or tag by appending `#ref` to the marketplace source, as in `Nouran99/guidedplugins#<ref>`.

The scope decides where the plugin is enabled:

| Scope | Flag | Enabled | Recorded in |
| --- | --- | --- | --- |
| User (default) | `--scope user` | Every project on this machine | `~/.claude/settings.json` |
| Project | `--scope project` | Everyone who works in this repository | `.claude/settings.json` (you commit it) |
| Local | `--scope local` | You, in this repository only | `.claude/settings.local.json` |

Committing a project-scope entry turns the plugin on for your collaborators but does not download it for them; each collaborator runs the install command once.

### Try a plugin for one session with `--plugin-dir`

From a checkout of this repository:

```bash
cd "/path/to/guidedplugins"
claude --plugin-dir ./plugins/clean-code
```

The flag loads that plugin for the session only; nothing is installed. It is repeatable, so you can load two:

```bash
claude --plugin-dir ./plugins/legacy-code --plugin-dir ./plugins/refactoring
```

Point the flag at a plugin folder, the one that contains `.claude-plugin/plugin.json`. If you point it at `./plugins`, the parent, Claude Code loads every child folder that has a manifest, which is all 14 plugins at once (section 7 explains why that is rarely what you want). A plugin loaded this way is listed as `<name>@inline` by `claude --plugin-dir ./plugins/clean-code plugin list` (the flag must come before `plugin`); plain `claude plugin list` does not show it. When it shares a name with an installed plugin, the session copy wins for that session.

### Add a local checkout as a marketplace

This installs from your own copy of the repository, for example before it is published or while you test changes.

```bash
cd "/path/to/guidedplugins"
claude plugin marketplace add ./
claude plugin install clean-code@guided-plugins
```

Inside a session, `/plugin marketplace add /absolute/path/to/guidedplugins` does the same; if the path contains spaces, use the shell form with the path in quotes. A relative path must start with `./` or `../`: a bare `.` is rejected as an invalid source. The marketplace is read from the folder in place.

### Update

```bash
claude plugin marketplace update guided-plugins
claude plugin update clean-code@guided-plugins
```

The first refreshes the marketplace listing; the second updates one plugin and prints `already at the latest version` when nothing is newer. The new version loads in your next session, or after `/reload-plugins` in an open one. There is no command that updates every plugin at once. In the `/plugin` panel, open the **Marketplaces** tab, select `guided-plugins` and choose **Update marketplace** to update every plugin you installed from it in one step.

Auto-update is off by default for marketplaces that are not Anthropic's. To turn it on for this one, go to **Marketplaces** in `/plugin`, select the marketplace and choose **Enable auto-update**.

Each plugin's version is in its `.claude-plugin/plugin.json` and what changed is in its `CHANGELOG.md`. Claude Code keeps you on the version a plugin's manifest declares, so a fix reaches you when the maintainers bump that version.

### Uninstall

```bash
claude plugin uninstall clean-code@guided-plugins
claude plugin marketplace remove guided-plugins
```

Uninstall acts on user scope unless you pass `--scope project` or `--scope local`. Removing the marketplace also uninstalls every plugin you installed from it. To keep a plugin installed but switch it off, use `claude plugin disable clean-code@guided-plugins` (and `enable` to bring it back). If you selected one of the plugin's output styles, run `/output-style default` first.

## 2. Turn on the always-on rules (inject_rules)

Each plugin declares one option, `inject_rules`. It is a boolean and defaults to false. When true, a `SessionStart` hook adds the plugin's compact rule set (`skills/principles/references/nano.md`, between 1.2 and 2.8 KB depending on the book) to the session context at startup, after `/clear` and after compaction. Everything else the plugin does is unchanged.

Leave it off for most plugins. The upstream project recommends one primary rule set with the others loaded on demand, and the books disagree with each other on purpose. Turn it on for at most one plugin: the book you want present before your first message. The hook injects `nano` rather than `mini` to keep the always-on cost small; `mini` is read on demand by the skills.

Three ways to set it. All of them need the plugin to be installed (or loaded) first.

In a session:

```text
/plugin configure clean-code@guided-plugins
```

This opens the plugin's options dialog. You can reach the same dialog from `/plugin`: open the **Installed** tab, select the plugin, press Enter and choose **Configure options**. Each option of an enabled plugin also appears as a row in `/config` (Claude Code 2.1.269 or later).

From a shell, at install time or later (the second form needs Claude Code 2.1.285 or later):

```bash
claude plugin install clean-code@guided-plugins --config inject_rules=true
echo '{"inject_rules": "true"}' | claude plugin configure clean-code@guided-plugins --values-stdin
```

Values are passed as strings and checked against the declared type; `true`, `false`, `1`, `0`, `yes`, `no`, `on` and `off` are accepted, and anything else is refused without saving. `claude plugin configure clean-code@guided-plugins` with no flags lists the options and whether each is set. To turn the option off, set it to `false`.

Claude Code saves the answer under `pluginConfigs` in your user settings (`~/.claude/settings.json`):

```json
{
  "pluginConfigs": {
    "clean-code@guided-plugins": {
      "options": {
        "inject_rules": true
      }
    }
  }
}
```

Two consequences. The setting is read only from user (and managed) settings, so a repository cannot switch it on for a team through its own `.claude/settings.json`; the Claude Code docs say project and local entries are ignored. And the change applies to new sessions: the command prints `Restart Claude Code to apply it.`

To see what the hook would add without starting Claude Code, run the script yourself:

```bash
CLAUDE_PLUGIN_OPTION_INJECT_RULES=true "/path/to/guidedplugins/plugins/clean-code/scripts/session-context.sh"
```

With the variable unset or `false` it prints nothing. The script needs `bash`.

## 3. Invoke skills, agents and output styles

Always include the plugin prefix. All 14 plugins have a `review`, `audit`, `plan`, `fix`, `checklist`, `explain-rule` and `principles` skill, a `lead` and a `final-gate` agent, and `mentor`, `strict-reviewer`, `pair` and `terse` output styles. The prefix is what tells them apart.

| What | You write | Example |
| --- | --- | --- |
| Skill, either kind | `/<plugin>:<skill> [arguments]` | `/clean-code:review src/billing` |
| Subagent | `@agent-<plugin>:<agent>`, or ask for it by name | `@agent-release-it:timeout-reviewer` |
| Output style | `/output-style <plugin>:<style>` | `/output-style clean-code:mentor` |

### Skills

Type `/` and the plugin name to see its skills with their argument hints. There are two kinds, and which is which is listed in each plugin's `docs/COMPONENTS.md` and README:

- **Skills Claude can load on its own.** These hold rule clusters, such as `/clean-code:naming`. Claude loads one when your task matches its description, and you can also type it. Their descriptions are in context on every turn.
- **Skills you run by name.** These are workflows, such as `/clean-code:review` and `/legacy-code:find-seam`. Claude does not start them by itself, and their descriptions are not in context. They take an argument. With an empty argument, most review skills use the current git diff, some scans use the repository root, and some workflows ask what to work on (for example `/pragmatic-programmer:tracer-plan`, or `/refactoring-guru:reachability-check`, which asks for a target). The Scope section of each skill says which, and the argument hint in the `/` menu shows the forms it accepts.

Some workflows run in a forked context (`audit`, and scans such as `/release-it:failure-mode-scan` and `/clean-architecture:layer-map`). The skill text becomes the whole prompt of a separate subagent that cannot see your conversation, so put everything it needs in the argument. Per the Claude Code docs the subagent runs in the background by default: you keep working, and its result, at most 40 lines, arrives in your conversation when it finishes.

When you do not know which component to use, ask the hub, `/<plugin>:principles`, which has a routing table from situation to component, or delegate to the plugin's `lead` agent.

### Subagents

An agent runs in its own context, with its own tools, and returns a result to your conversation. It does not see your conversation, so give it paths or a clear scope; if you give none, the agents look at `git diff`, and ask if there is none. There are three ways to start one.

```text
@agent-clean-code:scope-guard compare my diff with the request "add a refund window"
Use the clean-code:final-gate agent on my working diff.
```

- **By mention:** type `@` and pick the agent from the list, or write `@agent-<plugin>:<agent>`.
- **By name in a sentence:** as in the second line above.
- **Automatically:** Claude may delegate when the task matches an agent's description. Many descriptions say "Use proactively after ...". This is Claude's choice, not a guarantee; ask by name when you want a specific reviewer.

The "Access" column in each plugin's `docs/COMPONENTS.md` says whether an agent is read-only or can edit files. Reviewers, scanners, `lead` and `final-gate` are read-only. Implementers (names such as `refactorer`, `test-writer`, `call-hardener`) edit files, run the project's tests and do not commit.

### Output styles

```text
/output-style
/output-style clean-code:mentor
/output-style default
```

With no argument the command lists the styles you can pick, including each plugin's, and marks the current one. A style applies from your next message and stays on until you change it: Claude Code saves the choice to `.claude/settings.local.json` for the project. Only one style is active at a time, so you cannot stack styles from two plugins. Styles change how the main conversation responds; they do not change how subagents respond, because a subagent runs its own system prompt. Every style in these plugins keeps destructive-action confirmations, failing test output and security warnings unchanged.

If a plugin's styles are not listed right after an in-session install or `/reload-plugins`, restart Claude Code. The output styles docs say the terminal reads style files when Claude Code starts. Whether an in-session reload makes a plugin's styles appear was not tested; with `--plugin-dir`, `/output-style` listed all six `clean-code` styles as `clean-code:<name>`.

## 4. Choose plugins

Start with one plugin for the kind of work you do most, and bring in others for single tasks. Each plugin's idle cost is real (section 7), and the books disagree with each other: where you load two, say which one decides.

[COMPATIBILITY.md](COMPATIBILITY.md) is the guide to this choice. It rates every pair of the 14 books (91 pairs) as complementary, overlapping or conflicting, using the upstream project's pairwise notes; names the groups of plugins that compete for the same decisions; and proposes seven bundles built only from complementary pairs. The ratings are about competing instructions, not about results: nothing there says a bundle produces better code. The bundles, each with one primary and companions you bring in per task:

| You are... | Primary | Bring in on demand |
| --- | --- | --- |
| Writing and reviewing everyday code | `clean-code` | `refactoring`, `legacy-code` |
| Rescuing weakly tested code | `legacy-code` | `refactoring`, `clean-architecture` |
| Designing modules, APIs and architecture | `philosophy-of-design` or `clean-architecture`, not both | `refactoring`, and the other design plugin as a check |
| Modeling part of a business domain | `ddd-distilled` | `data-intensive-apps`, `refactoring`, `legacy-code` |
| Running services and data pipelines | `release-it`, or `data-intensive-apps` if consistency and replay are the hard part | the other of the two, `legacy-code` |
| Choosing enterprise application patterns | `enterprise-patterns` | `data-intensive-apps`, `refactoring` |
| Wanting general engineering habits | `pragmatic-programmer` | `refactoring`, `legacy-code`, optionally `release-it` |

Each bundle has one primary, and only that plugin gets `inject_rules`. The [README](../README.md#recommended-bundles) table also names, for each row, what not to add as an equal, and [COMPATIBILITY.md](COMPATIBILITY.md#6-recommended-bundles) explains each bundle pair by pair.

Four plugins appear in no bundle because each is an alternative to a primary: `code-complete` for `clean-code`, and `ddd` and `ddd-implementing` for `ddd-distilled`. `refactoring-guru` is an alternative to `refactoring` (the two overlap heavily). `data-intensive-apps`, `release-it` and `legacy-code` are rated complementary with all 13 other plugins, which makes them the lowest-risk additions to any setup.

## 5. Ten recipes

Each recipe uses commands and agents that exist in the named plugin; the names come from its `docs/COMPONENTS.md`. Replace the example paths and descriptions with your own. Skills that edit files say so, run the project's tests and never commit.

### 1. Review and tidy uncommitted work (`clean-code`)

You have edited several files and want a second opinion before you stage anything.

```text
/clean-code:review
/clean-code:fix last review
@agent-clean-code:scope-guard compare my diff with the request "add a 30-day refund window"
@agent-clean-code:final-gate
```

- `/clean-code:review` (manual skill, main conversation) reads `git status` and `git diff` when given no argument, decides which rule clusters the change touches from the hub's routing table, reads only those skills, and prints findings ranked blocker, major, minor and nit, each with `file:line`, the rule, the consequence and the smallest fix. It prints `No findings` when clean and never edits. On a large diff it can ask `clean-code:lead` for a routing plan.
- `/clean-code:fix last review` (manual skill, edits files) takes the findings from that review in this conversation, resolves them one at a time in severity order, records a test baseline and runs the tests after each change, reverts an edit that breaks tests for an unclear reason, and stops to ask if a finding needs a behavior change. It works only in the conversation that holds the review.
- `scope-guard` (read-only agent) labels each hunk of the diff as required, enabling cleanup, opportunistic cleanup or out of scope, so you can see whether the diff outgrew the request.
- `final-gate` (read-only agent) runs the final checklist against the working diff and returns PASS or FAIL with evidence.

For a session that always answers as a ranked findings table, add `/output-style clean-code:strict-reviewer`.

### 2. Change a function that has no tests (`legacy-code`)

You must add a late-fee waiver to a billing function nobody dares touch.

```text
/legacy-code:plan add a late-fee waiver to invoices closed by support
/legacy-code:characterize src/billing/close.py:close_invoice
/legacy-code:find-seam src/billing/close.py:close_invoice "assert the fee total without a real database"
@agent-legacy-code:collaborator-injector make the seam chosen above
/legacy-code:split-patch
@agent-legacy-code:final-gate
```

- `plan` plans only: the change, the protection needed, test points, the first barrier, the seam, ordered steps and cleanup obligations.
- `characterize` writes tests only and never touches production code. It picks inputs from the code, records what the code actually returns as the expected value, marks surprising results `CHARACTERIZATION: unclear if intended` with a question for the owner, and runs the tests against unchanged code. If the target cannot be called (a clock, a database, a constructor that does real work) it stops at the first barrier and hands it to `find-seam`.
- `find-seam` proposes and does not edit. It names the first barrier, lists candidate seams, picks the smallest, and names the technique, the owning skill and the implementer agent. Its table maps barrier kinds to `boundary-wrapper`, `collaborator-injector`, `global-encapsulator`, `method-extractor` and `sprouter`; use the one it names, not necessarily the one shown above.
- The implementer edits production code in small steps with tests. When the break was what stopped every pin, `find-seam` says to pin straight afterwards: run `characterize` again, then make the real change.
- `split-patch` classifies the hunks of the finished patch (behavior, dependency break, structure, cleanup, test) and proposes an order of separately verifiable steps. It never stages or commits.

For the whole session, `/output-style legacy-code:characterize-first` prints a safety preamble and writes the pin before any edit.

### 3. Harden one request path before launch (`release-it`)

You are about to ship a service whose `POST /orders` calls an inventory service.

```text
/release-it:failure-mode-scan POST /orders
/release-it:call-chain-budget POST /orders
@agent-release-it:call-hardener apply the single retry owner proposed above to the inventory client
/release-it:launch-check services/orders
```

- `failure-mode-scan` (forked, read-only, at most 40 lines) walks each boundary on the flow through the book's six stability assumptions and returns a table of what happens when each dependency is slow, down or wrong, the gaps, and the skill that closes each. It writes `unknown` where it cannot tell and does not infer protection from a library name.
- `call-chain-budget` reads time limits, attempts and who retries at each layer, multiplies them, and flags nested retries and mismatched deadlines. Every number it proposes is marked `proposed, needs confirmation`.
- `call-hardener` (edits files) gives the named call sites explicit time limits and one bounded retry owner, with tests.
- `launch-check` (forked) looks for evidence of rollback, startup validation, health checks, limits, signals, security and rehearsal, and returns go or no-go with the missing items.

`/release-it:game-day-plan` and `/release-it:incident-review` are the next tools for rehearsing failure and learning from it.

### 4. Start a feature in a business area you do not know (`ddd-distilled`)

```text
/ddd-distilled:classify-subdomains src
/ddd-distilled:event-storm customer returns and partial refunds
/ddd-distilled:model-first handle a partial refund for a returned order
/output-style ddd-distilled:earned-pattern
```

- `classify-subdomains` (forked) inventories the business capabilities in the code, proposes core, supporting or generic with evidence, flags where modeling effort does not match importance, and lists the questions you must answer.
- `event-storm` is a conversation, so it is not forked. It runs a timeboxed, text-based event storming session with you, one round at a time, and ends with a timeline, glossary entries, candidate boundaries, scenarios and a list of spikes. If no business expert is available, it marks every business statement `assumed`.
- `model-first` produces a short model brief before you write behavior: capability, subdomain, context, local terms, the smallest patterns and the scenarios.
- The `earned-pattern` style tags each tactical pattern it introduces with the reason it earns its cost and defaults to plain code.

After you build, `@agent-ddd-distilled:ceremony-reviewer` checks tactical patterns in both directions: too much ceremony, and complex rules left in plain data.

### 5. Find and enforce dependency direction (`clean-architecture`)

```text
/clean-architecture:layer-map src
/clean-architecture:introduce-port src/orders/domain/order.ts:3
/clean-architecture:enforce-boundaries
```

- `layer-map` (forked) infers the layers from what each directory imports rather than from its name, prints an import matrix and lists the outward edges (an inner layer importing an outer one), at most eight, worst first.
- `introduce-port` edits files, one dependency per run. It first checks that a port is worth its cost, then declares a port in the core in the use case's words, writes the adapter in the outer layer, replaces the direct use with a constructor parameter, wires it in the composition root, and adds a fake for tests, with the tests run after each step.
- `enforce-boundaries` makes the layer rules fail a test or a build. It detects the tooling the project already declares, agrees a mechanism with you before writing, freezes known violations as a baseline that should only shrink, and proves the check can fail by adding a violation temporarily and removing it.

For several dependencies at once use `@agent-clean-architecture:port-introducer`; for a raw import census use `@agent-clean-architecture:import-scanner`.

### 6. Pick the smallest enterprise pattern for each decision (`enterprise-patterns`)

```text
/enterprise-patterns:choose-pattern a nightly read-only report joining orders, refunds and shipments
/enterprise-patterns:plan add the nightly report
/enterprise-patterns:build-feature the nightly report
```

- `choose-pattern` writes the forces as observations, then prints a table with one row per open decision (business logic, data access, transactions, presentation, remote boundary, session state): the choice, the force that selects it, the alternative rejected and the observation that would make you escalate. It asks at most three questions, only about forces it cannot read from the code, and it does not edit.
- `plan` turns the choice into a plan in the book's generation order, with an explicit transaction owner, a test plan and a list of patterns you will not add. It edits nothing.
- `build-feature` implements the use case slice by slice with tests at each responsibility.

During a working session, `/output-style enterprise-patterns:force-first` puts the same forces-first header on every design answer.

### 7. Check read freshness and concurrent writes (`data-intensive-apps`)

```text
/data-intensive-apps:consistency-check orders
@agent-data-intensive-apps:consistency-reviewer review my diff that moves GET /profile off the replica
```

- `consistency-check` (forked, at most 40 lines) maps every read path of the entity to who reads it, what freshness they need (own writes, bounded stale, any), where it is served from and what guarantee it really gives, then lists concurrent writers and whether conflicts are detected. It does not decide the product's freshness need: where nobody wrote it down it reports `unstated` and asks. Where replica routing is configured outside the repository it reports `unknown`. Each gap names the skill that owns it, such as `/data-intensive-apps:consistency-contract`.
- `consistency-reviewer` (read-only) reviews the diff that fixes a gap: freshness needs per read path, read-your-writes expectations, staleness tolerance and conflict handling.

### 8. Compare two designs before building (`philosophy-of-design`)

```text
/philosophy-of-design:design-twice an interface for scheduling retries of failed webhook deliveries
/philosophy-of-design:plan build the chosen design
@agent-philosophy-of-design:depth-reviewer
```

- `design-twice` writes two or more designs as call sites with a contract of at most three sentences and the list of what each hides, scores them on the book's four criteria (interface simplicity, information hiding, special-case reduction, future cognitive load), chooses one and records the price and what new fact would change the choice. It does not edit, and it says so when it cannot find a second plausible design.
- `plan` plans the build of the winner. After the code exists, `depth-reviewer` (read-only) looks for pass-through layers, thin wrappers and rename-only helpers.

For code that already exists, `/philosophy-of-design:depth-map src` ranks shallow modules and `/philosophy-of-design:collapse-layer` removes a forwarding layer in small steps.

### 9. Plan a new capability as a thin end-to-end slice (`pragmatic-programmer`)

```text
/pragmatic-programmer:tracer-plan import customers from the partner CSV feed
/output-style pragmatic-programmer:tracer-first
@agent-pragmatic-programmer:slice-reviewer
```

- `tracer-plan` plans only: the assumptions to test (riskiest first), one input traveling to one output across every boundary, which parts are real and which trivial, the single command that proves the slice, and the increments after it ordered by risk. If a boundary cannot be crossed for real, the plan marks the assumption unproven and schedules the first real call early.
- The `tracer-first` style makes the session state the thinnest real path and its proving command, build and run that first, then widen in steps.
- `slice-reviewer` (read-only) checks a plan or pull request that adds a capability across several layers for a real end-to-end path with a proving command, as opposed to layer-by-layer work.

### 10. Diagnose a smell and delete dead code safely (`refactoring-guru`)

```text
/refactoring-guru:smell-to-treatment src/orders
/refactoring-guru:reachability-check legacyOrderCode delete
@agent-refactoring-guru:dead-code-remover remove legacyOrderCode
@agent-refactoring-guru:final-gate
```

- `smell-to-treatment` turns up to three confirmed smells into cards: diagnose, treat (preferred, fallback and risky treatments), verify and stop. It does not edit; `/refactoring-guru:fix` acts on a card. For a card before every edit in a session, use `/output-style refactoring-guru:treatment-card`.
- `reachability-check` (forked) searches every way other code can reach a symbol and returns a verdict on whether the stated change is safe.
- `dead-code-remover` (edits files) deletes or inlines unused code only after reachability evidence exists, and refuses candidates without it.
- `final-gate` runs the ten review questions against the working diff.

## 6. Combine plugins safely

Plugins do not call each other. A plugin names other books in backticks and never invokes their components, because the other plugin may not be installed. So the hand-off between plugins is done by you: run the first plugin's command, then pass its output to the next one as the scope.

Rules that keep a combination coherent:

1. **One primary, the rest on demand.** At most one plugin should have `inject_rules` on. Bring the others in by running their workflows for a single task.
2. **One arbiter per question.** When two books answer the same question differently, say which decides: "`philosophy-of-design` decides module boundaries; `clean-code` decides local naming and readability of the code I touch." Every plugin's hub already ranks your explicit instruction first, then the repository's conventions, then the book.
3. **One router.** Use one plugin's `lead` per task. Several leads give several plans.
4. **One output style at a time.** Styles cannot be stacked.
5. **Know which pairs overlap or conflict.** [COMPATIBILITY.md](COMPATIBILITY.md) has the verdict for every pair. In short: the three DDD plugins are substitutes for each other, and `ddd` and `ddd-implementing` are rated conflicting with `enterprise-patterns`; `clean-code`, `philosophy-of-design`, `code-complete` and `pragmatic-programmer` compete on everyday code; `refactoring` and `refactoring-guru` give largely the same advice. Some names repeat across plugins with similar jobs, for example `characterize` exists in `legacy-code` and in `refactoring`. Pick one for the task and stay with it.
6. **Mind the cost.** Every installed plugin adds its idle cost (section 7).

Worked example: changing weakly tested code with three books, one step each.

```text
/legacy-code:characterize src/billing/close.py:close_invoice
/refactoring:prepare add a late-fee waiver to close_invoice
/clean-code:review
```

`legacy-code` pins the current behavior. `refactoring:prepare` does at most five verified behavior-preserving steps that make the change straightforward, then hands back before the behavior change. After you make the change, `clean-code` reviews the diff. Nothing here needs `inject_rules` on in any of the three.

## 7. Context cost and how to keep it small

What a plugin costs while it sits idle:

| Component | Idle cost |
| --- | --- |
| Skills Claude can load on its own | Name and description, every turn |
| Skills you run by name | None, according to the Claude Code skills docs |
| Subagents | Name and description, every turn (the sub-agents docs say they take up context) |
| Output style | None until selected; then its whole text on every request |
| `inject_rules` hook | Nothing when off; the compact rules, once at session start, when on |

Claude Code can estimate it. In a shell:

```bash
claude plugin details clean-code
claude --plugin-dir ./plugins/clean-code plugin details clean-code
```

The first needs the plugin installed; the second loads it from disk in the same command. The "Always-on" line is the estimate, and the table beneath it shows which components contribute most. On Claude Code 2.1.286 the estimates were about 3,100 tokens for `clean-code` up to about 3,900 for `enterprise-patterns`, and about 48,400 for all 14 together. The estimator also counts the manual skills, which the skills docs say cost nothing, so treat the figure as an upper bound. These are estimates and they will change with versions; run the command for your own numbers.

What running a component costs is separate from the idle cost. The per-component table in the same command has an on-invoke column: the body that loads when a skill or agent fires. On Claude Code 2.1.286 it ranged from about 680 tokens (`checklist`) to about 2,100 (`naming`) across the `clean-code` skills, with `review` at about 850 and `smells-surprise` at about 1,900; the `clean-code` agents were about 760 to 1,100. Using a component adds that much to the context at least. Agents and forked skills also read files in their own contexts and spend tokens there, which the on-invoke figure does not include. The 14 `lead` agents use `opus`, so if model cost or limits matter on your plan, ask for a specific reviewer instead of `lead`. All of these figures are estimates.

Ways to keep it small:

1. **Install what you use.** Fourteen plugins together are a lot of idle context. The sub-agents docs mention a startup warning when the combined descriptions of non-built-in subagents pass 15,000 tokens, and by the estimator the agents of all 14 plugins together are above that.
2. **Scope installs.** A plugin installed with `--scope project` or `--scope local` is enabled only in that repository.
3. **Switch off what you are not using.** `claude plugin disable <plugin>@guided-plugins`, or press Space on the plugin in the **Installed** tab of `/plugin`. You cannot turn off one skill of a plugin: the skills docs say per-skill overrides do not apply to plugin skills.
4. **Use `--plugin-dir` for a one-off session** instead of installing.
5. **Keep `inject_rules` off,** except for at most one plugin.
6. **Let forked skills and agents do the big reads.** They read many files in their own context and return a short report.
7. **Find what you never use.** `/skill-doctor` reports what each skill costs and how often it runs, and flags skills that have never been invoked, including skills from plugins. The **Installed** tab in `/plugin` can move unused plugins under a **Not used recently** header, but the Claude Code docs say that header never appears for a plugin that includes an output style, or for a plugin loaded with `--plugin-dir`. All 14 of these plugins ship six output styles, so do not expect it for them. The docs also say `/doctor` lists installed plugins and recommends disabling the ones that were not used; this was not tested with these plugins. To see what is installed, use `claude plugin list` and `claude plugin details <plugin>`.

## 8. Troubleshooting

### A skill does not trigger

- If it is a skill you run by name, Claude never starts it; type `/<plugin>:<skill>`. Check `docs/COMPONENTS.md` to see which kind it is.
- If it is a skill Claude can load on its own, it loads when your request matches its description. Say what you are doing in plain terms ("I am renaming variables in the billing module") or name it: "use the naming skill from clean-code".
- Check that the plugin is installed and enabled: `claude plugin list`, or the **Installed** tab in `/plugin`. Open the **Errors** tab for load problems.
- If you installed during this session, run `/reload-plugins`. It prints `Reloaded:` with counts of plugins, skills, agents, hooks and servers.
- Claude chooses among every description in context, so with several books installed it may pick a different book's skill than you expected. Name the one you want, or disable a plugin you are not using.

### A command is not found

- You need the prefix: `/clean-code:review`, not `/review`.
- The plugin must be loaded. With `--plugin-dir`, the path must be the plugin folder (`./plugins/clean-code`), the one with `.claude-plugin/plugin.json`, not its `skills` folder.
- A shell install loads the next time Claude Code starts, or after `/reload-plugins`.
- Check the spelling in the plugin's `docs/COMPONENTS.md`. For an agent, type `@` and pick it from the list; it shows the scoped `plugin:agent` name.
- To check that a plugin on disk is well formed, run `claude plugin validate ./plugins/clean-code`. This works offline.

### The hook does not inject the rules

1. Is the option on? `claude plugin configure clean-code@guided-plugins` shows `set` or `not set`; remember that the default is false, and that an option set to `false` injects nothing.
2. Did you restart? The setting applies to new sessions.
3. Does the script print anything? Run it by hand as in section 2. If it prints nothing with the variable set to `true`, the reference file `skills/principles/references/nano.md` is missing or unreadable; if it prints the rules, the script is fine and the problem is the option or the session.
4. The hook is registered for `startup`, `clear` and `compact`. It is not registered for `resume` or `fork`, which the Claude Code docs list as separate matcher values. What a resumed session does was not tested.
5. Open the **Errors** tab in `/plugin`, and look for `hook error` notices in the transcript. The script needs `bash` and must keep its executable bit; if you copied the plugin in a way that drops it, run `chmod +x plugins/<slug>/scripts/session-context.sh`.

### Validator errors (for contributors)

Run `node scripts/validate-plugin.mjs plugins/<slug> --no-cli` and `node scripts/validate-all.mjs --no-cli`. The usual messages:

| Message | Fix |
| --- | --- |
| `frontmatter: line N: unquoted value needs double quotes` | Put the value in double quotes. Block scalars (`\|`, `>`) are not allowed. |
| `Source cites "X" which is not a heading in references/full.md` | Copy the heading from `references/full.md` exactly (case does not matter). |
| `traceability: N/M upstream sections are not cited by any component` | Cite the listed sections in the `## Source` of the component that applies them, or add that component. |
| `body is N chars, need at least M (filler guard)` | Add decision content; do not pad. |
| `duplicates: near-duplicate components: a ~ b` | Merge the two, or make their purpose and content different. |
| `references unknown components: <slug>:<name>` | Fix the spelling, or add the component. |
| `... is stale; run: node scripts/gen-catalog.mjs plugins/<slug>` | Run that command and commit the result. |
| `N model-invocable skills, max 20` | Set `disable-model-invocation: true` on workflow skills. |
| `manual skills need an argument-hint` | Add `argument-hint` to the frontmatter. |
| `references missing path ${CLAUDE_PLUGIN_ROOT}/...` | The path in the text does not exist; fix it or add the file. |
| `scripts/session-context.sh: is not executable (chmod +x)` | `chmod +x plugins/<slug>/scripts/session-context.sh` |
| `marketplace/marketplace.json is stale` | `node scripts/gen-catalog.mjs --root` |
| `docs/<file>: reference <slug>:<name> does not exist` | A repo-level document names a component that is not there; fix the name. |
| `claude plugin validate: ...` | Run `claude plugin validate plugins/<slug>` for the full message. |

The complete list of checks is in [ARCHITECTURE.md](ARCHITECTURE.md#7-validation-and-ci), and the contract is in [PLUGIN_SPEC.md](PLUGIN_SPEC.md).

## 9. FAQ

**Can I use these in Codex, OpenCode, Gemini CLI or another agent?** Yes: see [AGENTS_SUPPORT.md](AGENTS_SUPPORT.md) for installs, differences and costs.

**Do the plugins make my code better?** Nobody has measured it, and this project does not claim it. The plugins apply a book's rules consistently and every piece of advice cites the upstream section it comes from, so you can check it. Treat the findings as informed review comments.

**Are they official?** No. They are not affiliated with or endorsed by the books' authors or publishers, or by the upstream rule-set maintainer. See [NOTICE.md](../NOTICE.md).

**Do the plugins send my code anywhere?** The plugins are Markdown plus one short bash script each. The script reads a bundled file and prints it; it makes no network calls and does nothing unless you turn `inject_rules` on. Claude Code itself works as usual. Read the script before you enable it: it is short.

**Will an implementer commit or push my code?** The components are written never to commit, push, reset, clean or delete recursively, and implementers run your tests and stop when a fix needs a behavior change. These are instructions; the permission settings of Claude Code are the real guard. Read the diff.

**Why so many components per plugin?** Each covers one cluster of the book's rules, one workflow, one reviewer, one implementer or one working mode. Only the skills Claude can load on its own and the agents cost context while idle; section 7 has the numbers. If a component feels redundant, open an issue with the "Rule accuracy" template or send a pull request that merges it.

**Which model do the agents use?** The model is set in each agent's frontmatter. The 14 `lead` agents use `opus`, four mechanical scanners use `haiku`, and the other 282 agents use `sonnet`.

**Can I change a component?** Do not rely on edits made inside an installed plugin's folder surviving an update. To keep changes, fork the repository and add your fork as the marketplace, or load your edited copy with `--plugin-dir`.

**Can I use these without Claude Code?** The plugin format is Claude Code's. The rule sets inside are the upstream project's (`full`, `mini` and `nano` in each plugin's `skills/principles/references/`), and upstream explains other ways to load them.

**What if two books disagree?** Your explicit instruction wins, then your repository's conventions, then the book. When two books conflict, say which one decides (section 6).

**Does `/plugin` work in `claude -p`?** No; the Claude Code docs say `/plugin` is not available in non-interactive runs. Plugins you already installed do load, and you manage them with the `claude plugin` commands.

**Where do I report a rule that is wrong?** Open an issue with the "Rule accuracy" template: the plugin and component, the upstream section, what the component says and what the source says.
