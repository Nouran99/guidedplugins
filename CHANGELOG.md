# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
each plugin also keeps its own `CHANGELOG.md` and is versioned independently with [Semantic Versioning](https://semver.org/).

## [1.1.0] - 2026-10-18

The 14 toolkits now also work in other coding agents. The Claude Code plugins are unchanged.

### Added

- **`dist/` builds generated from `plugins/`** by `scripts/build-targets.mjs`, with a shared rewrite engine and one module per agent:
  - `agent-skills`: 517 skills and modes in the open Agent Skills format, named `<plugin>-<name>` so flat-namespace agents do not collide (the `skills` installer found only 317 of 433 before). All 517 pass the `skills-ref` validator.
  - `codex`: a Codex plugin per book (served from `.agents/plugins/marketplace.json`, which Codex prefers), manual workflows hidden from the model catalog, and 300 subagent roles as TOML with `scripts/install-codex-agents.mjs`.
  - `opencode`: skills, 300 subagents with an enforced read-only permission map, and each output style as a primary agent; `scripts/install-opencode.mjs`.
  - `gemini`: one extension per book with skills and subagents that match Gemini's strict agent schema.
  - `cursor` and `copilot` (experimental, not run), `rules` (`AGENTS.md` snippets and `scripts/compose-rules.mjs`).
  - `mcp`: a catalog of all 817 guides and a dependency-free MCP server (`scripts/mcp-server.mjs`, also `npx github:Nouran99/guidedplugins`) with four tools, resources and 542 prompts.
- **`docs/AGENTS_SUPPORT.md`**: install steps, what maps to what, costs, differences and exactly what was verified, per agent.
- **`scripts/validate-targets.mjs`**, run by `validate-all.mjs`, plus CI steps that rebuild `dist/`, parse the Codex roles as TOML and run the MCP self-test.

### Verified with the real tools (isolated homes, no live model session)

Codex 0.162, OpenCode 1.19 and 2.0, Gemini CLI 0.64, `npx skills` 1.7.2, `skills-ref`, the MCP Inspector, Claude Code and Codex as MCP clients.

## [1.0.0] - 2026-10-16

First release of the `guided-plugins` marketplace: 14 plugins, each at version 1.0.0, with 817 components in total (433 skills, 300 subagents, 84 output styles).

### Added

- **Fourteen plugins**, one for each of 13 books and one for the Refactoring.Guru website, each built on the matching rule set from [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books). Component counts:

  | Plugin | Source | Skills | Agents | Styles | Total |
  | --- | --- | ---: | ---: | ---: | ---: |
  | `clean-code` | Clean Code | 31 | 22 | 6 | 59 |
  | `philosophy-of-design` | A Philosophy of Software Design | 30 | 22 | 6 | 58 |
  | `clean-architecture` | Clean Architecture | 32 | 22 | 6 | 60 |
  | `code-complete` | Code Complete | 30 | 22 | 6 | 58 |
  | `data-intensive-apps` | Designing Data-Intensive Applications | 32 | 22 | 6 | 60 |
  | `ddd` | Domain-Driven Design | 32 | 22 | 6 | 60 |
  | `ddd-distilled` | Domain-Driven Design Distilled | 32 | 21 | 6 | 59 |
  | `ddd-implementing` | Implementing Domain-Driven Design | 30 | 21 | 6 | 57 |
  | `enterprise-patterns` | Patterns of Enterprise Application Architecture | 32 | 21 | 6 | 59 |
  | `refactoring` | Refactoring | 30 | 22 | 6 | 58 |
  | `refactoring-guru` | Refactoring.Guru | 30 | 22 | 6 | 58 |
  | `release-it` | Release It! | 31 | 21 | 6 | 58 |
  | `pragmatic-programmer` | The Pragmatic Programmer | 32 | 20 | 6 | 58 |
  | `legacy-code` | Working Effectively with Legacy Code | 29 | 20 | 6 | 55 |
  | **Total** | | **433** | **300** | **84** | **817** |

  Every plugin has the same skeleton: a `principles` hub skill, 18 to 20 skills that Claude can load on its own, the workflows `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix` plus book-specific ones, a `lead` router and a `final-gate`, and the output styles `mentor`, `strict-reviewer`, `pair` and `terse` plus book-specific modes.
- **Marketplace** `guided-plugins` in `.claude-plugin/marketplace.json`, generated from `scripts/books.json` and the plugin manifests.
- **Shared tooling**:
  - `docs/PLUGIN_SPEC.md`, the contract every plugin is built and validated against, and `docs/templates/`, annotated skeletons for each component type.
  - `scripts/validate-plugin.mjs` and `scripts/validate-all.mjs`, which check each plugin, the repo-level documents and the marketplace file.
  - `scripts/gen-catalog.mjs`, which regenerates each plugin's `docs/COMPONENTS.md` and `docs/TRACEABILITY.md`, the generated blocks in the READMEs, and the marketplace file.
  - `scripts/new-plugin.mjs`, which scaffolds the mechanical parts of a plugin, and `scripts/books.json`, the registry of books.
  - A GitHub Actions workflow with a blocking structure job and a non-blocking job that runs the official `claude plugin validate`, plus issue and pull request templates.
- **Documentation**: `docs/USAGE.md` (install, use, recipes, troubleshooting), `docs/COMPATIBILITY.md` (verdicts for all 91 pairs of plugins and seven recommended bundles), `docs/ARCHITECTURE.md` (design, cost model, validation, limitations), and an updated `README.md` with the bundles, a compatibility summary, a documentation index and an FAQ. Per plugin: `README.md`, `docs/DESIGN.md`, `docs/COMPONENTS.md`, `docs/TRACEABILITY.md`, `CHANGELOG.md`.
- **Opt-in hook**: each plugin ships one `SessionStart` hook that adds the book's compact rules (`nano.md`) to the session. It is controlled by the `inject_rules` plugin option, which is off by default; the validator requires the default to be `false`. The spec allows no other hook.
- **Traceability**: every component ends with a `## Source` section naming the upstream headings it applies. The validator fails on a citation that is not a heading in the plugin's `full.md` and on any upstream `##` section that no component cites. All 318 sections across the 14 plugins are covered, and each plugin's `docs/TRACEABILITY.md` maps sections to components.
- **Validation**: counts and per-type floors, strict frontmatter, allowed keys per component type, body size floors, near-duplicate rejection, resolution of `<slug>:<name>` references and relative links in plugins and repo-level documents, freshness of generated files, hook checks, and the official `claude plugin validate` unless skipped with `--no-cli`.
- **Vendored upstream rule sets**: the `full`, `mini` and `nano` files for each book are included unmodified under `skills/principles/references/`, and each plugin's `NOTICE.md` records the upstream commit (`893a88a6fce3a80c565bf39ac65021b43a8b2990`).
- **Context and safety limits**: the validator allows at most 20 skills per plugin that Claude can load on its own, and requires output styles to keep Claude Code's coding instructions and not to be forced on. In the current files, 233 of the 300 agents (reviewers, scanners, each `lead` and each `final-gate`) disallow the `Write` and `Edit` tools; the other 67 are implementers.

### Notes

- The plugins are unofficial and are not affiliated with or endorsed by the books' authors or publishers.
- No effect on code quality has been measured, and this release makes no such claim; the upstream project says the same about its rule sets. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#11-known-limitations).
- The install path `Nouran99/guidedplugins` is valid once the repository is published there.
- The `lead` agent of `clean-code` does not state the five-step cap that rule 15 of the plugin spec sets, because that plugin was built before the rule was added. The other 13 leads state it, and the validator does not check it. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#3-the-four-component-types).
