# Guided Plugins: classic engineering books as Claude Code toolkits

Fourteen [Claude Code](https://code.claude.com) plugins, one per classic software engineering book. Each plugin turns the book's working rules into
**50+ components** (skills, subagents and output styles) that make Claude apply that book's judgment while it reviews, plans, changes, audits and teaches.

They are built on the MIT-licensed rule sets in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz.
The plugins are **unofficial**: not affiliated with or endorsed by the books' authors or publishers. See [NOTICE.md](NOTICE.md).

## Quick start

Add the marketplace once, then install only the books you want:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install clean-code@guided-plugins
```

Then try it on your current changes:

```text
/clean-code:review                     # review the working diff against the book
/output-style clean-code:mentor        # make the session teach the reasoning behind each change
```

Try a plugin without installing it by pointing Claude Code at its folder: `claude --plugin-dir ./plugins/clean-code`.

## The plugins

<!-- CATALOG:START -->

| Plugin | Book | Author | Components | Reach for it when |
| --- | --- | --- | --- | --- |
| [`clean-code`](plugins/clean-code/README.md) | Clean Code | Robert C. Martin | 59 (31 skills, 22 agents, 6 styles) | Doing everyday coding and code review: naming, small functions, tests. |
| [`philosophy-of-design`](plugins/philosophy-of-design/README.md) | A Philosophy of Software Design | John Ousterhout | 58 (30 skills, 22 agents, 6 styles) | Designing APIs or modules, or refactoring shallow abstractions. |
| [`clean-architecture`](plugins/clean-architecture/README.md) | Clean Architecture | Robert C. Martin | 60 (32 skills, 22 agents, 6 styles) | You need code that resists framework, database, and UI churn. |
| [`code-complete`](plugins/code-complete/README.md) | Code Complete | Steve McConnell | 58 (30 skills, 22 agents, 6 styles) | You need disciplined implementation decisions on routines, control flow, and testing. |
| [`data-intensive-apps`](plugins/data-intensive-apps/README.md) | Designing Data-Intensive Applications | Martin Kleppmann | 60 (32 skills, 22 agents, 6 styles) | Data ownership, event flows, or consistency semantics matter. |

<!-- CATALOG:END -->

Each plugin README lists every component with its command, a usage walkthrough, a map from the book's sections to the components, and which other plugins it pairs well with.

## What is in a plugin

| Part | What it is | How you use it |
| --- | --- | --- |
| **Skills Claude loads on its own** | Focused rule clusters from the book, each with a trigger description, rules, a procedure and an example | Claude picks them up when your task matches; you can also run them, e.g. `/clean-code:naming` |
| **Skills you run by name** | Workflows: `review`, `audit`, `plan`, `explain-rule`, `checklist`, `fix`, plus book-specific ones | `/<plugin>:review`, `/<plugin>:plan "add retry to the payment client"` |
| **Subagents** | A `lead` that routes work, about a dozen read-only specialist reviewers, a few implementers, and a `final-gate` | Claude delegates automatically, or ask for `@agent-<plugin>:<name>` |
| **Output styles (modes)** | `mentor`, `strict-reviewer`, `pair`, `terse` and a book-specific mode that change how a whole session behaves | `/output-style <plugin>:<mode>` |
| **Opt-in hook** | Adds the book's compact rules to every session | Turn on the `inject_rules` option for the plugin (off by default) |

Every plugin keeps the three upstream rule files (`full`, `mini`, `nano`) under `skills/principles/references/` and traces every component back to the upstream section it applies
(`docs/TRACEABILITY.md`), so you can check any piece of advice against its source.

## Choosing plugins

Install a few, not all. Every model-invocable skill description costs context on every turn, and the books disagree with each other on purpose (for example how much ceremony to put around a domain model).
The upstream project recommends **one primary rule set, with the rest loaded on demand**; these plugins follow that:

- Keep at most one plugin's `inject_rules` on.
- Use `/<plugin>:review` or an output style to bring another book in for a single task.
- Do not run `lead` agents from several books at once; pick one as the router.

Starting points:

| You are... | Try |
| --- | --- |
| Writing and reviewing everyday code | `clean-code`, then `code-complete` or `philosophy-of-design` for design depth |
| Changing code with weak tests | `legacy-code` with `refactoring` (and `refactoring-guru` to choose treatments) |
| Shaping an architecture | `clean-architecture`, plus `enterprise-patterns` for pattern choices |
| Modeling a business domain | `ddd` for strategy, `ddd-implementing` for tactics, or `ddd-distilled` for the light version |
| Building services and data pipelines | `release-it` and `data-intensive-apps` |
| Wanting general engineering habits | `pragmatic-programmer` |

## Repository layout

```text
.claude-plugin/marketplace.json   generated from the plugin manifests
plugins/<slug>/                   one plugin per book (see docs/PLUGIN_SPEC.md for the anatomy)
docs/                             spec, templates, architecture notes
scripts/                          validator, catalog generator, plugin scaffolder
.github/                          CI and issue/PR templates
```

## Developing

Requires Node 20+. No dependencies to install.

```bash
node scripts/validate-all.mjs          # every plugin: structure, counts, traceability, duplicates, `claude plugin validate`
node scripts/gen-catalog.mjs           # regenerate catalogs, traceability tables and marketplace.json
node scripts/new-plugin.mjs <slug> --upstream <clone of agent-rules-books>   # scaffold a new plugin
```

The contract for a plugin is [docs/PLUGIN_SPEC.md](docs/PLUGIN_SPEC.md). Contributions are welcome; see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT, see [LICENSE](LICENSE). Upstream rule sets are MIT too; their notice is in [NOTICE.md](NOTICE.md).
