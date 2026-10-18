# Guided Plugins: classic engineering books as toolkits for coding agents

Fourteen toolkits, built as [Claude Code](https://code.claude.com) plugins and also generated for Codex, OpenCode, Gemini CLI, Cursor (experimental, not run), Copilot (experimental, not run), any agent that reads Agent Skills or `AGENTS.md`, and any MCP client. One toolkit for each of 13 software engineering books and one for the Refactoring.Guru website.
Each plugin turns its source's working rules into 55 to 60 components (skills, subagents and output styles) that instruct Claude to apply those rules while it reviews, plans, changes, audits and teaches.

They are built on the MIT-licensed rule sets in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz.
The plugins are **unofficial**: not affiliated with or endorsed by the books' authors or publishers. See [NOTICE.md](NOTICE.md).
The names Claude Code, Codex, OpenCode, Gemini CLI, Cursor and GitHub Copilot belong to their owners; this project is independent and is not affiliated with or endorsed by any of them.

What they do and do not claim: each plugin applies one book's upstream rules consistently, and every component cites the upstream section it comes from.
Nobody has measured whether that improves code quality, and the upstream project says the same about its rule sets, so this project does not claim it.

**At a glance:** 14 plugins with 817 components in total: 433 skills (275 that Claude can load on its own and 158 that you run by name), 300 subagents and 84 output styles.
A skill is a Markdown instruction set; a subagent is a specialist that works in its own context window; an output style changes how a whole session behaves.
Each plugin also has one hook, which does nothing unless you turn it on. The totals match the table printed by `node scripts/validate-all.mjs --no-cli`, and each plugin's `docs/COMPONENTS.md` shows which skill is which.

## Quick start

These docs were written against Claude Code 2.1.286 (check yours with `claude --version`). A few commands need a newer version; [docs/USAGE.md](docs/USAGE.md) marks each one with its minimum version.

Add the marketplace once, then install only the books you want. Inside a Claude Code session:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install clean-code@guided-plugins
```

The path `Nouran99/guidedplugins` is valid once the repository is published at github.com/Nouran99/guidedplugins. Until then, add a local checkout instead. Clone the repository (that URL also works only once it is published) or use the folder you already have, and run this from its root:

```bash
git clone https://github.com/Nouran99/guidedplugins
cd guidedplugins
claude plugin marketplace add ./
claude plugin install clean-code@guided-plugins
```

Two things to know about the install:

- In a session, `/plugin install` opens a details dialog instead of installing at once. Choose a scope there to finish. A plugin installed from a shell loads the next time you start Claude Code, or after `/reload-plugins` in an open session.
- A marketplace added from a local folder is read from that folder in place, so moving or deleting the clone breaks the plugins you installed from it.

Then open Claude Code in your own project and try the plugin on your current changes:

```text
/clean-code:review                     # review the working diff against the book
/output-style clean-code:mentor        # make the session teach the reasoning behind each change
/output-style default                  # switch the style off again
```

Try a plugin without installing it by pointing Claude Code at its folder in a clone of this repository, run from the clone's root: `claude --plugin-dir ./plugins/clean-code`.
Installing, updating, the `inject_rules` option and troubleshooting are covered in [docs/USAGE.md](docs/USAGE.md).

## Other coding agents

The Claude Code plugins in `plugins/` are the source. `dist/` holds committed builds for other agents, generated from them and checked against what each agent accepts.
[docs/AGENTS_SUPPORT.md](docs/AGENTS_SUPPORT.md) has the install steps, what changes on each agent, the costs, and exactly what was verified.

| Agent | Install | Status |
| --- | --- | --- |
| Codex CLI | `codex plugin marketplace add /path/to/guidedplugins`, then `codex plugin add clean-code@guided-plugins` (the GitHub form `Nouran99/guidedplugins` works once the repository is published) | Verified with codex-cli 0.162 (local path) |
| OpenCode | `node scripts/install-opencode.mjs clean-code` (run from a clone, installs into the current directory's `.opencode`) | Verified with OpenCode 1.19 and 2.0; see the guide for what was re-checked |
| Gemini CLI | `gemini extensions install ./dist/gemini/clean-code` | Verified: installs and loads (no live session) |
| Any Agent Skills agent (about 75) | `npx skills add ./dist/agent-skills/clean-code` from a clone (`Nouran99/guidedplugins/dist/agent-skills/clean-code` once published) | Format and installer verified |
| Any `AGENTS.md` agent | `node scripts/compose-rules.mjs clean-code --size nano --out AGENTS.md` | Verified |
| Any MCP client | `node scripts/mcp-server.mjs --plugins clean-code` | Verified with the MCP Inspector, Claude Code and Codex |
| GitHub Copilot, Cursor | see the guide (Cursor team marketplaces need a Teams or Enterprise plan) | Experimental, not run |

The `Nouran99/guidedplugins` forms need the repository to be published there; it has no remote yet, so use a clone and the local forms. The scripts need Node 20 or later and are run from the clone.

Codex subagents need a separate step (`node scripts/install-codex-agents.mjs clean-code`). Read-only reviewers are not a guarantee outside Claude Code: OpenCode denies them the edit tools and limits their shell to an allowlist (a guard rail, not a sandbox), Gemini applies a tool list but cannot restrict the shell, and Codex restricts neither; the guide explains.

## The plugins

<!-- CATALOG:START -->

| Plugin | Book | Author | Components | Reach for it when |
| --- | --- | --- | --- | --- |
| [`clean-code`](plugins/clean-code/README.md) | Clean Code | Robert C. Martin | 59 (31 skills, 22 agents, 6 styles) | Doing everyday coding and code review: naming, small functions, tests. |
| [`philosophy-of-design`](plugins/philosophy-of-design/README.md) | A Philosophy of Software Design | John Ousterhout | 58 (30 skills, 22 agents, 6 styles) | Designing APIs or modules, or refactoring shallow abstractions. |
| [`clean-architecture`](plugins/clean-architecture/README.md) | Clean Architecture | Robert C. Martin | 60 (32 skills, 22 agents, 6 styles) | You need code that resists framework, database, and UI churn. |
| [`code-complete`](plugins/code-complete/README.md) | Code Complete | Steve McConnell | 58 (30 skills, 22 agents, 6 styles) | You need disciplined implementation decisions on routines, control flow, and testing. |
| [`data-intensive-apps`](plugins/data-intensive-apps/README.md) | Designing Data-Intensive Applications | Martin Kleppmann | 60 (32 skills, 22 agents, 6 styles) | Data ownership, event flows, or consistency semantics matter. |
| [`ddd`](plugins/ddd/README.md) | Domain-Driven Design | Eric Evans | 60 (32 skills, 22 agents, 6 styles) | You want to model the business domain rather than tables, controllers, or DTOs. |
| [`ddd-distilled`](plugins/ddd-distilled/README.md) | Domain-Driven Design Distilled | Vaughn Vernon | 59 (32 skills, 21 agents, 6 styles) | You want DDD benefits without heavy ceremony. |
| [`ddd-implementing`](plugins/ddd-implementing/README.md) | Implementing Domain-Driven Design | Vaughn Vernon | 57 (30 skills, 21 agents, 6 styles) | You need implementation-level DDD: aggregates, events, and integrations. |
| [`enterprise-patterns`](plugins/enterprise-patterns/README.md) | Patterns of Enterprise Application Architecture | Martin Fowler | 59 (32 skills, 21 agents, 6 styles) | You need to choose an appropriate enterprise pattern instead of mixing responsibilities. |
| [`refactoring`](plugins/refactoring/README.md) | Refactoring | Martin Fowler | 58 (30 skills, 22 agents, 6 styles) | You want small, test-backed structural changes kept separate from feature work. |
| [`refactoring-guru`](plugins/refactoring-guru/README.md) | Refactoring.Guru | Refactoring.Guru (website) | 58 (30 skills, 22 agents, 6 styles) | You need to diagnose smells, pick a safe treatment, and avoid uncontrolled redesign. |
| [`release-it`](plugins/release-it/README.md) | Release It! | Michael T. Nygard | 58 (31 skills, 21 agents, 6 styles) | You are building services, APIs, queues, or critical production paths. |
| [`pragmatic-programmer`](plugins/pragmatic-programmer/README.md) | The Pragmatic Programmer | Andrew Hunt, David Thomas | 58 (32 skills, 20 agents, 6 styles) | You want a general engineering layer: automation, feedback, orthogonality. |
| [`legacy-code`](plugins/legacy-code/README.md) | Working Effectively with Legacy Code | Michael Feathers | 55 (29 skills, 20 agents, 6 styles) | You are changing poorly tested legacy code and need to regain control first. |

<!-- CATALOG:END -->

Each plugin README lists every component with its command, a usage walkthrough, a map from the book's sections to the components, and which other plugins it pairs well with.

## What is in a plugin

| Part | What it is | How you use it | Total |
| --- | --- | --- | ---: |
| **Skills Claude loads on its own** | Focused rule clusters from the book, each with a trigger description, rules, a procedure and an example. 18 to 20 per plugin | Claude picks them up when your task matches; you can also run them, e.g. `/clean-code:naming` | 275 |
| **Skills you run by name** | Workflows: `review`, `audit`, `plan`, `explain-rule`, `checklist`, `fix`, plus book-specific ones | `/<plugin>:review`, `/<plugin>:plan "add retry to the payment client"` | 158 |
| **Subagents** | A `lead` that routes work, about a dozen read-only specialist reviewers, a few implementers, and a `final-gate` | Claude delegates automatically, or ask for `@agent-<plugin>:<name>` | 300 |
| **Output styles (modes)** | `mentor`, `strict-reviewer`, `pair`, `terse` and book-specific modes that change how a whole session behaves | `/output-style <plugin>:<mode>` | 84 |
| **Opt-in hook** | Adds the book's compact rules to the session at startup, after `/clear` and after compaction | Turn on the `inject_rules` option for the plugin (off by default) | 14 |

Every plugin keeps the three upstream rule files (`full`, `mini`, `nano`) under `skills/principles/references/` and traces every component back to the upstream section it applies
(`docs/TRACEABILITY.md`), so you can look up the source of any piece of advice.

## Choosing plugins

Install a few, not all. Every skill that Claude can load on its own and every subagent puts its name and description into the context on every turn, and the books pull in different directions
(for example on how much ceremony to put around a domain model).
By the estimate that `claude plugin details <plugin>` printed on Claude Code 2.1.286, one plugin adds about 3,100 to 3,900 tokens to every session and all 14 together about 48,400.
The estimator also counts the skills you run by name, which the Claude Code skills docs say cost nothing while idle, so it probably overstates. Run the command for your own figures.

### Compatibility in brief

The upstream project rated every pair of its rule sets as complementary, overlapping or conflicting. For these 14 plugins that gives 91 pairs: 78 complementary, 11 overlapping and 2 conflicting.

- The two conflicting pairs are `ddd` and `ddd-implementing`, each against `enterprise-patterns`.
- `data-intensive-apps`, `release-it` and `legacy-code` are rated complementary with all 13 other plugins.
- The other 11 plugins fall into three groups that compete for the same decisions: everyday coding guides (`clean-code`, `philosophy-of-design`, `code-complete`, `pragmatic-programmer`); architecture, domain model and patterns (`clean-architecture`, `ddd`, `ddd-distilled`, `ddd-implementing`, `enterprise-patterns`); and refactoring (`refactoring`, `refactoring-guru`). Choose one primary per group.

**The one-primary rule.** The upstream project recommends one primary rule set, with the rest loaded on demand, and these plugins follow that:

- Keep at most one plugin's `inject_rules` on. That plugin is the primary.
- Use `/<plugin>:review`, an agent or an output style to bring another book in for a single task.
- Do not run `lead` agents from several books at once; pick one as the router.
- When two books answer the same question differently, say which one decides. For example: "Use ddd as the primary rule set for this change. Use enterprise-patterns only to choose the persistence pattern for the order repository."

The ratings are qualitative and come from the upstream notes. They say whether two rule sets are likely to give an agent competing instructions; they do not show that any combination improves code.
The full table of 91 pairs, the reasons behind each overlap and conflict, and the arbiter to name are in [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

### Recommended bundles

Each bundle has one primary (turn [`inject_rules`](docs/USAGE.md#2-turn-on-the-always-on-rules-inject_rules) on for it) and companions that you call per task. Every pair inside a bundle is rated complementary. The ratings cover pairs only, so a bundle is a starting point.

| You are... | Primary | Bring in on demand | Do not add as an equal |
| --- | --- | --- | --- |
| Writing and reviewing everyday code | `clean-code` | `refactoring`, `legacy-code` | `philosophy-of-design`, `code-complete`, `pragmatic-programmer` (all overlap it) |
| Rescuing weakly tested code | `legacy-code` | `refactoring`, `clean-architecture` | `refactoring-guru` next to `refactoring`; `ddd-implementing` or `enterprise-patterns` next to `clean-architecture` |
| Designing modules, APIs and architecture | `philosophy-of-design` or `clean-architecture`, not both | `refactoring`, and the other design plugin as a check | `clean-code` next to `philosophy-of-design`; `enterprise-patterns` or `ddd-implementing` next to `clean-architecture` |
| Modeling part of a business domain | `ddd-distilled` | `data-intensive-apps`, `refactoring`, `legacy-code` | `ddd` or `ddd-implementing` as equals; `enterprise-patterns` side by side |
| Running services and data pipelines | `release-it`, or `data-intensive-apps` if consistency and replay are the hard part | the other of the two, `legacy-code` | structural plugins that add layers before the source of truth is written down |
| Choosing enterprise application patterns | `enterprise-patterns` | `data-intensive-apps`, `refactoring` | `ddd` and `ddd-implementing` (the two conflicting pairs); `ddd-distilled` and `clean-architecture` as equals |
| Wanting general engineering habits | `pragmatic-programmer` | `refactoring`, `legacy-code`, optionally `release-it` | `clean-code` or `code-complete` always on beside it |

Four plugins appear in no bundle because each is an alternative to a primary: `code-complete` for `clean-code`, `ddd` and `ddd-implementing` for `ddd-distilled`, and `refactoring-guru` for `refactoring`.

As a worked setup, the first row (everyday code that is partly untested) is three installs:

```text
/plugin install clean-code@guided-plugins
/plugin install refactoring@guided-plugins
/plugin install legacy-code@guided-plugins
```

Turn `inject_rules` on for `clean-code` only (in a session: `/plugin configure clean-code@guided-plugins`; the other ways are in [docs/USAGE.md](docs/USAGE.md#2-turn-on-the-always-on-rules-inject_rules)), and bring the other two in per task. Each bundle is explained pair by pair in [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md#6-recommended-bundles).

## Documentation

| Document | What it covers |
| --- | --- |
| [docs/AGENTS_SUPPORT.md](docs/AGENTS_SUPPORT.md) | Using the toolkits with Codex, OpenCode, Gemini CLI, Copilot, Cursor, Agent Skills agents, `AGENTS.md` and MCP: install steps, what maps to what, costs, differences, what was verified |
| [docs/USAGE.md](docs/USAGE.md) | Installing, updating and removing plugins; turning on `inject_rules`; invoking skills, agents and styles; ten recipes with real commands; context cost; troubleshooting; FAQ |
| [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) | All 91 pairs with verdicts and scores, the groups that compete, the pairs to be careful with, seven bundles |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the repository and each plugin are put together, the cost model, the opt-in hook, validation and CI, how the plugins were built and reviewed, known limitations |
| [docs/PLUGIN_SPEC.md](docs/PLUGIN_SPEC.md) | The contract every plugin is built and validated against |
| [docs/templates/](docs/templates/README.md) | Annotated skeletons for each component type |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Changing a component, adding a book, reporting an inaccuracy |
| `plugins/<slug>/README.md`, `docs/COMPONENTS.md`, `docs/TRACEABILITY.md`, `docs/DESIGN.md` | Per plugin: overview and walkthroughs, every component and its command, upstream section to components, and the component map |
| [NOTICE.md](NOTICE.md), [LICENSE](LICENSE), [SECURITY.md](SECURITY.md), [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md), [CHANGELOG.md](CHANGELOG.md) | Attribution, license, how to report a security problem, conduct, release history |

## How these plugins were built and checked

Each plugin went through the same steps. Models did the writing and most of the review, so the limits are listed after the steps.

1. **Spec and tooling first.** [docs/PLUGIN_SPEC.md](docs/PLUGIN_SPEC.md), the templates, the validator, the catalog generator and the scaffolder were written in the first commit, before any plugin.
2. **Scaffold.** `scripts/new-plugin.mjs` writes the manifest, license and notice (with the upstream commit), the hook, the three vendored rule files and a README stub.
3. **One builder per book, in a fresh context.** Each builder worked from files only: the spec, the templates and the book's folder in a read-only clone of the upstream repository, which it treated as data. It wrote `docs/DESIGN.md` first (one row per planned component and why it differs from its nearest sibling), then the components and the README, and ran the validator until it passed.
   It edited only its own plugin folder, ran no git command that changes state, used no network and started no subagents.
4. **Two independent verifiers.** Two separate review passes read each finished plugin without the builder's context, each from a different angle. Their reports are not stored in the repository.
5. **Fix rounds and a polish pass.** Findings were fixed and the plugin was validated again. Findings from the first reviews were turned into rules in the spec's quality bar, and the validator gained a check for references between components.
6. **Mechanical validation.** `node scripts/validate-all.mjs` fails on, among other things: counts below the floors, frontmatter outside a strict subset, disallowed keys, too-thin or near-duplicate components, references to components that do not exist, stale generated files, and a hook option that does not default to off.
   CI runs it on every push to `main` and on pull requests. The official `claude plugin validate` runs in a separate job that does not block.
7. **Traceability.** Every component ends with a `## Source` section naming upstream headings. The validator fails when a cited heading is not in the plugin's vendored `full.md`, and when any `##` section of that file is cited by no component. Across the 14 plugins, 318 of 318 sections are covered. `docs/TRACEABILITY.md` in each plugin shows the map.

What this does not show:

- **No effect on code quality was measured.** No task was run with and without a plugin, and there is no data on defects, review time or whether the agents follow their templates. The upstream project lists missing measurement as its strongest open criticism.
- **The builders and reviewers were models** of the kind the plugins are meant to steer, so they can share blind spots. The definition of done includes a person reading three components at random, but the repository does not record that this was done for each plugin.
- **The validator checks structure, not truth.** It proves that a citation names a real section, not that the section supports what the component says. A wrong paraphrase that cites a real heading passes. Nothing in the repository tests that a skill triggers on its description, that Claude delegates to an agent, or that output follows its template.
- **Faithfulness to the books rests on the upstream rule sets,** which this project did not audit. The 42 vendored rule files (three per plugin) were byte-identical to the upstream files at the recorded commit when this README was finalized, but no script in the repository repeats that check.
- **The component floors invite padding.** Short rule sets reach 50 components by separating role and situation (a rules skill, a workflow, a reviewer, an implementer). The floors and the near-duplicate check are tripwires, not proof that every component earns its place. Remaining overlaps are recorded in each plugin's `docs/DESIGN.md`.
- **Components are instructions, not guarantees.** What Claude Code enforces is the agent tool lists (reviewers have no `Write` or `Edit`, but they do have `Bash`, which their instructions limit to read-only commands) and its permission system.

More detail, including the full list of checks and known limitations, is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#8-how-the-plugins-were-built-and-reviewed).

## FAQ

**Do the plugins make my code better?** Nobody has measured it, and this project does not claim it. The plugins apply a book's rules consistently and cite the upstream section behind each component, so you can check the advice against its source. Treat the output as structured review comments.

**What do they cost?** The plugins are free under the MIT license. They use your Claude Code session, so the cost is context and tokens. Skills that Claude loads on its own and subagents put their descriptions in context on every turn. According to the Claude Code docs, skills you run by name cost nothing while idle; an output style costs nothing until you select it, and the hook prints nothing unless you turn it on. A component's full text loads only when it is used.
The idle estimates are in [Choosing plugins](#choosing-plugins). Keep the cost down by installing only what you use, turning `inject_rules` on for at most one plugin, and trying others with `--plugin-dir`. [docs/USAGE.md](docs/USAGE.md#7-context-cost-and-how-to-keep-it-small) lists more ways.

Running a component costs more than having it installed. Using one adds its body to the context: by the `claude plugin details` estimate on Claude Code 2.1.286, the `clean-code` components add roughly 700 to 2,100 tokens each (`review` about 850, `smells-surprise` about 1,900; read the on-invoke column for your own figures). Agents and forked skills read files in their own contexts and spend tokens there as well, which that estimate does not include. The 14 `lead` agents use the `opus` model and 282 of the other agents use `sonnet`; if model cost or limits matter on your plan, ask for a specific reviewer instead of `lead`. All of these figures are estimates.

**What if two books disagree?** Your explicit instruction wins, then your repository's conventions, then the book. Between two books, pick a primary and say which one decides the question, as in [Compatibility in brief](#compatibility-in-brief). [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) has the verdict for every pair.

**Can I use them offline?** Installing from GitHub needs a network connection. After that, the plugins are Markdown files, the vendored rule files and one short bash script per plugin (the hook), which prints a bundled file and makes no network call. No agent is given `WebFetch` or `WebSearch`. Claude Code itself still needs its usual connection to the model. A local checkout can be used as a marketplace, as in the Quick start.

**How do they relate to the upstream project?** They are built on [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books). Each plugin copies that project's `full`, `mini` and `nano` rule files for its book unmodified and records the upstream commit in its `NOTICE.md`. The skills, subagents, output styles, hook and documentation around those files are this project's own work.
This project is not affiliated with or endorsed by the upstream maintainer. If you only want the rule files, for use in other tools, use the upstream project directly.

**Does it work with Codex, OpenCode or my other agent?** Yes, in different degrees; see [Other coding agents](#other-coding-agents) and [docs/AGENTS_SUPPORT.md](docs/AGENTS_SUPPORT.md). Skills travel everywhere. Subagents, modes and always-on rules need a per-agent build, which `dist/` provides, and some features have no equivalent elsewhere (Claude Code's output styles become persona skills). The Codex, OpenCode, Gemini and MCP builds were installed and loaded in the real tools; no live model session was run in any of them.

**Can I use just one plugin?** Yes. Each plugin is self-contained: it carries its own copy of its rule files, and no plugin calls another. Add the marketplace once and install the one you want. Plugins mention other books by name in their text but never invoke their components.

**What is the license?** This repository is MIT-licensed ([LICENSE](LICENSE)). The upstream rule sets are MIT-licensed too; their notice is in [NOTICE.md](NOTICE.md). The books and the Refactoring.Guru website belong to their authors and publishers. The plugins paraphrase working rules and use original examples; they do not reproduce book text and are no substitute for the books. This project has not had a legal review.

## Repository layout

```text
.claude-plugin/marketplace.json   Claude Code marketplace, generated from scripts/books.json and the plugin manifests
.agents/plugins/marketplace.json   Codex marketplace (generated; points at dist/codex)
.cursor-plugin/marketplace.json    Cursor marketplace (generated; experimental)
plugins/<slug>/                   one Claude Code plugin per book: the source of everything (see docs/PLUGIN_SPEC.md)
dist/                             generated builds for other agents (never edit by hand): agent-skills, codex, opencode,
                                  gemini, cursor, copilot, rules, mcp
docs/                             usage, agents support, compatibility, architecture, spec and component templates
scripts/                          validators, generators, installers, the MCP server, plugin scaffolder, book registry
package.json                      lets `npx github:Nouran99/guidedplugins` run the MCP server
.github/                          CI and issue/PR templates
```

## Developing

Requires Node 20+. No dependencies to install.

```bash
node scripts/validate-all.mjs          # every plugin: structure, counts, traceability, duplicates; runs `claude plugin validate` too when the claude CLI is installed
node scripts/validate-all.mjs --no-cli # the same without the official CLI check (what CI's blocking job runs)
node scripts/gen-catalog.mjs           # regenerate catalogs, traceability tables and marketplace.json
node scripts/new-plugin.mjs <slug> --upstream <clone of agent-rules-books>   # scaffold a new plugin
node scripts/build-targets.mjs         # regenerate dist/ for the other agents after any change to plugins/
node scripts/validate-targets.mjs      # check dist/ against each agent's constraints (validate-all runs it too)
node scripts/mcp-selftest.mjs          # MCP server protocol checks
```

The contract for a plugin is [docs/PLUGIN_SPEC.md](docs/PLUGIN_SPEC.md). Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT, see [LICENSE](LICENSE). Upstream rule sets are MIT too; their notice is in [NOTICE.md](NOTICE.md).
