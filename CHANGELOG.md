# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
each plugin also keeps its own `CHANGELOG.md` and is versioned independently with [Semantic Versioning](https://semver.org/).

## [1.3.0] - 2026-11-17

Makes the toolkits measurable, easier to pick, adjustable per project and usable without a person at the keyboard. The 14 book plugins move to 1.1.0; what they say about their books is unchanged.

### Added

- **Evals.** An eval suite for every plugin in `evals/<slug>/` (69 cases: planted-violation fixtures with one judge-graded criterion per violation, and a clean control), a runner (`scripts/run-evals.mjs`, built on `claude plugin eval`) that compares the model with and without the plugin and runs the plugin's own `/<plugin>:review` on the same fixtures, a validator (`scripts/validate-evals.mjs`) and a generated results page, [docs/EVALS.md](docs/EVALS.md). **Results exist for 5 of 14 plugins** (one run per case): the plugin's workflow found 13 to 68 points more of the planted problems than the model alone (scored on the same graders; 2 of the 5 differences are within the noise of one run); on a natural prompt the plugin's skills were never called. The other nine suites have not been run: the `claude` login expired during the run, and the runner records nothing for failed runs.
- **Presets and the `guided` companion plugin** (`meta/`). Five presets (`everyday-code`, `legacy-rescue`, `backend-service`, `domain-model`, `system-design`), each one primary book plus up to two books rated Complementary, installable in one step in Claude Code (`/plugin install guided-<preset>@guided-plugins`: a bundle plugin whose dependencies are the books; checked with the real CLI). `guided` has six skills: `start`, `which-book`, `config`, `review` (across books), `conflicts` and `ci-setup`. `scripts/install-preset.mjs` prints the equivalent commands for the other agents. A core set of nine components per book (`scripts/core.json`) and a *Start here* table at the top of every plugin README.
- **Project settings.** `.guided-plugins.json` (primary and secondary books, strictness, ignored paths, report size, CI failure level): schema, `scripts/guided-config.mjs`, [docs/PROJECT_CONFIG.md](docs/PROJECT_CONFIG.md). Every book's hub, `review`, `audit`, `checklist`, `fix` and `plan` workflows and `lead` and `final-gate` agents read it (text inserted by `scripts/apply-project-settings.mjs`).
- **`/guided:review`.** One review across the chosen books: each book's lead routes, read-only reviewers run in parallel, duplicates merge, and where a secondary book contradicts the primary one it is reported as a disagreement. A live run (`clean-code` + `refactoring`, a small diff) cost about $1.1 and returned a schema-valid report.
- **Review in CI.** `--json` output from every `review` workflow ([docs/findings.schema.json](docs/findings.schema.json)); converters to SARIF 2.1.0, GitHub pull request review comments (inline on changed lines only; a finding with the same book, rule, path and cited line text is not posted twice) and Markdown; `scripts/guided-review-ci.mjs` (read-only tools and a budget ceiling; exit 0 pass, 1 gate, 2 could not run); a pre-push hook (`scripts/install-git-hook.mjs`); a composite GitHub Action (`.github/actions/guided-review`) and an example workflow. [docs/CI.md](docs/CI.md). All of it is tested with stand-ins for `claude` and `gh` (`scripts/selftest-ci.mjs`) and the runner was exercised once against the real CLI; **the Action itself has not run on GitHub** (the repository has no remote).
- **Validation.** `scripts/validate-meta.mjs` (guided plugin, bundles, settings text, core sets, CI files, generated references) and the eval validator run in `validate-all`; CI runs the plumbing self-test.

### Fixed in the independent review of 1.3.0

Three reviewers (the scripts, the plugin text, the documentation and evals) and a skeptical second look at each finding. 32 were confirmed; what changed:

- **The Action could not upload SARIF or post the review** on GitHub: the steps were gated on `hashFiles()` of files outside the workspace, which it ignores. They are gated on step outputs now; the Action reviews the pull request head (not the merge commit), installs the plugins from its own checkout and a pinned Claude Code version. It still has not run on GitHub.
- **The runner could pass silently:** it parsed git's patch text, so a quoted (non-ASCII) file name or `diff.noprefix`, `diff.mnemonicPrefix` or `color.diff` made it report "no changes". It now pins git's output format, takes the file list from NUL-separated names and fails loudly when it sees a diff but no names. Also: unknown flags are refused, paths are relative to where you ran it, findings outside the repository are dropped, ref arguments are validated.
- **Re-runs repeated findings:** a fingerprint hashed the model's wording and the review body was reposted whenever the summary changed. It now hashes the book, rule, path and the text of the cited line; each body bullet carries its own marker.
- **`--books` was ignored** by `/guided:review` in CI; the lead-plan parsing, the paths scope and the disagreement fields of that skill were underspecified. Fixed, with `primaryRule` and `secondaryRule` added to the schema.
- **Pre-push hook:** a mistyped `GUIDED_FAIL_ON` silently disabled it, a later "could not run" hid an earlier "blocked", its budget default was half the runner's, and `failOn` of the settings file was documented as applying to it (it does not; docs corrected). The installer wrote into the parent folder when run from a subfolder.
- **`ignore` globs** claimed `.gitignore` semantics but a leading slash and several other constructs differed; the supported syntax is now stated and `validate` rejects the rest.
- **Evals were not like for like:** the slash variants carry extra format graders that counted in the score. Scores are now defect-only (the format check is a separate column), the format check reads each plugin's own template (philosophy-of-design says `Cost:`, not `Why:`), and the "control" wording no longer calls a debatable fixture a false alarm. The numbers above are the corrected ones.
- **Documentation:** the claims that the reviewer has "nothing that writes" (git `--output` can write), the cost figures, the contradictory "nobody has measured it" lines, the one-router rule (with the `/guided:review` exception), counts and several smaller ones.

### Found while building it

- `claude --json-schema` rejects the draft 2020-12 `$schema` keyword (a schema must omit it); a failed eval run scores 0 and must never be recorded as a result (the first full run recorded 13 plugins as zero because of a usage limit); one obvious planted defect does not separate the model from the model with the plugin, so fixtures plant five to seven violations from different rule clusters; a control file must be clean by the book's own rules or an honest correctness remark counts as a false alarm.

## [1.2.0] - 2026-10-21

Fixes for the limitations reported after 1.1.0, each re-checked with the real tool. The Claude Code plugins are unchanged.

### Changed

- **Codex: roles ship with the plugin.** Each plugin carries its roles in `skills/install-roles/roles/` and a hidden skill, `$<plugin>:install-roles`, that copies them to `~/.codex/agents` or the project's `.codex/agents` without overwriting a file (the central `dist/codex/agents/` is gone). The skill says what to do under Codex's sandbox, which keeps `.codex` read-only: ask for approval, or print the command (found by a live run, then fixed and run again). `scripts/install-codex-agents.mjs` reads the same files.
- **Codex: shorter role descriptions.** Roles keep whole sentences (the first, plus the second when the first is very short): about 160 characters on average, 240 at most. Measured the same way with a mock model server, the role list of all 300 in a real request fell from 89.2 KB to 65.8 KB (one plugin: about 5 KB).
- **Codex: enforced read-only is documented, and was run.** A role file cannot set a sandbox; `codex --sandbox read-only` (or a `review.config.toml` profile) is what enforces it, and a subagent inherits it. Seven live runs on `clean-code` (docs/verification/codex-live-2026-10-20.md): implicit and explicit skill use, role install under a sandbox, a spawned role, a blocked write by a subagent, a mode.
- **Gemini: workflows and modes are slash commands.** The 242 manual workflows and modes moved from skills to `commands/<plugin>/<name>.toml` (`/clean-code:review src/`, arguments through `{{args}}`); only the 275 rule skills remain skills. With all 14 extensions installed the request a mock model received fell from 461 KB to 297 KB (about 74,000 tokens); the `activate_skill` schema lists 277 names (our 275 and Gemini's 2 built-in skills) instead of 519.
- **Gemini: shorter subagent descriptions** (303 entries, 109 KB to 82 KB).
- **Gemini: read-only roles are constrained.** Each extension ships `policies/read-only-roles.toml`: deny rules, scoped to the role, for `write_file` and `replace`, for any shell command outside `git diff|log|show|status|blame|ls-files`, `ls`, `grep`, `rg`, `wc`, `head`, `tail`, and for shell operators and write flags. Gemini's own policy engine answered as expected for all 16,543 checks of the new `scripts/verify-gemini-policy.mjs`. While writing it a pattern that Gemini's ReDoS heuristic would have dropped without a message was found and rewritten.
- **OpenCode: mode agents.** OpenCode replaces its provider system prompt (about 8.6 KB, measured) with a primary agent's prompt, so each mode now restates a short baseline of everyday conventions, and allows the `question` tool that a custom primary agent otherwise loses (measured: the tool lists of `build` and a mode agent are now equal).
- **Copilot: a marketplace file that wins.** `.github/plugin/marketplace.json` points at `dist/copilot`; Copilot reads it before the Claude one. Verified with Copilot CLI 1.0.101: 14 plugins browsed, two installed, 519 skills listed with all 14 enabled. Copilot is no longer marked experimental; Cursor still is.
- **`leftovers()`** accepts the Gemini command spelling `/<plugin>:<name>` only where such a command exists.
- **`validate-targets.mjs`** covers all of the above (Codex role files per plugin, Gemini commands and policy, OpenCode mode baseline, the Copilot marketplace); the checks were run against deliberately broken files. CI parses Codex roles, Gemini commands and policies as TOML.

### Fixed in the independent review of 1.2.0 (2026-10-25)

Five reviewers (code, generated output, documentation claims, read-only bypasses, a first-time-user walkthrough) each had their findings checked by a skeptical second reviewer. What held up:

- **Gemini subagents pointed at files that no longer existed.** `place-code` and `layer-map` of `clean-architecture` became commands, but three roles still told the model to read their `SKILL.md`. Roles now name the command's `.toml` for a manual workflow, and the validator fails any `${extensionPath}/...` path that is not in the extension.
- **Validator checks that could never fail.** The OpenCode mode checks (baseline, `question: allow`) and the existing subagent `webfetch: deny` check sat behind a condition that was never true, so the claims about them were false. Fixed; each check was shown to fail on a deliberately broken file.
- **Role descriptions cut in the middle of a phrase** ("to decide which specialist reviewers.", a half-open parenthesis, the Refactoring.Guru gate losing its first words at the dot in the name). `briefDescription` now keeps whole sentences only, and the validator rejects a description that does not end a sentence or has unbalanced brackets or backticks.
- **Gemini read-only policy.** It denied `find` and `git branch --show-current`, which the role texts tell roles to use; both are allowed now (with `-ok`/`-fls` denied). It missed `rg --hostname-bin` and `--search-zip`, and a flag whose name is split by quotes, a backslash or `$` (`--out""put`) got through; those are denied, as is a tab after `--pre`. The deny regex is now written to the policy file as a TOML basic string. OpenCode's list gained `--textconv` and the two `rg` flags. The probe batteries grew from 42 to 66 commands for Gemini and run for every read-only role. The limits are documented: matching is on text, so quoted `|` is refused too and a determined spelling can still get past; and one "Allow for this session" click in Gemini adds an allow rule that outranks the deny rules.
- **Other.** `compose-rules.mjs --out` no longer overwrites an existing file without `--force`; the Gemini README and docs say extension commands load only in a trusted folder; the release-it `allowed-tools` sentence ("pre-approved") no longer survives outside Claude Code; the package description no longer calls Copilot experimental; CI now fails on a generated file nobody committed.
- **Documentation.** Counts corrected (275 rule skills of ours, 18 to 20 per plugin, 517 skills and modes; Gemini's own 2 built-in skills are counted separately), the Codex baseline restated from a same-method measurement (89.2 KB, not an estimate), "turn limits do not carry over" corrected for OpenCode and Gemini, the README FAQ no longer says no live session was run, the OpenCode install command shows where to run it, read-only enforcement for Copilot and Cursor is stated, and the Copilot section says how to invoke skills and that `/agent` lists the agents.

### Verified (2026-10-20, 2026-10-21 and 2026-10-25)

`skills-ref` 517 of 517; `npx skills --list` 517; Codex 0.162.1 with all 14 plugins installed and seven live runs; OpenCode 1.19 and 2.0 with all 14 installed (no config errors); Gemini CLI 0.64 with all 14 installed; Copilot CLI 1.0.101; the MCP self-test (36 checks) and `npm exec --package=git+file://<clone>`. Still not verified: a live model session in any agent but Codex, the Gemini API with 277 skill names, Cursor, and the GitHub-hosted install forms (the repository has no remote).

## [1.1.0] - 2026-10-18

The 14 toolkits now also work in other coding agents. The Claude Code plugins are unchanged since 1.0.0, except for a wording pass on `clean-code` made on 2026-10-17, after the 1.0.0 date: its output style `boy-scout` was renamed `campsite` (the skill `boy-scout` keeps its name) and its `lead` now states the five-step cap. The repository has no remote yet, so nothing had been published when that was done and the plugin stays at 1.0.0. CONTRIBUTING.md asks for a major bump and a plugin changelog line for a rename once anyone depends on the name; that line is in `plugins/clean-code/CHANGELOG.md`.

### Added

- **`dist/` builds generated from `plugins/`** by `scripts/build-targets.mjs`, with a shared rewrite engine and one module per agent:
  - `agent-skills`: 517 skills and modes in the open Agent Skills format, named `<plugin>-<name>` so flat-namespace agents do not collide (the `skills` installer found only 317 of 433 before). All 517 pass the `skills-ref` validator.
  - `codex`: a Codex plugin per book (served from `.agents/plugins/marketplace.json`, which Codex prefers), manual workflows hidden from the model catalog, and 300 subagent roles as TOML with `scripts/install-codex-agents.mjs`.
  - `opencode`: skills, 300 subagents (read-only roles get the edit tools and web fetch denied and a shell allowlist with deny rules for redirection and write flags; a guard rail, not a sandbox) and each output style as a primary agent; `scripts/install-opencode.mjs`.
  - `gemini`: one extension per book with skills and subagents that match Gemini's strict agent schema.
  - `cursor` and `copilot` (experimental, not run), `rules` (`AGENTS.md` snippets and `scripts/compose-rules.mjs`).
  - `mcp`: a catalog of all 817 guides and a dependency-free MCP server (`scripts/mcp-server.mjs`, also `npx github:Nouran99/guidedplugins` once the repository is published) with four tools, resources and 542 prompts.
- **`docs/AGENTS_SUPPORT.md`**: install steps, what maps to what, costs, differences and exactly what was verified, per agent.
- **`scripts/validate-targets.mjs`**, run by `validate-all.mjs`, plus CI steps that rebuild `dist/`, parse the Codex roles as TOML and run the MCP self-test.

### Fixed in the review of the builds (also 2026-10-18, before publication)

- **Role installer.** `install-codex-agents.mjs` chose roles by name prefix, so `ddd` installed 64 roles (22 of `ddd` plus the roles of `ddd-distilled` and `ddd-implementing`), `refactoring` installed 44, `all` reported 364 for 300 files, and `--uninstall ddd` deleted the sibling plugins' roles. Roles are now selected by the plugin named in each file; `validate-targets.mjs` checks it.
- **Output templates.** `/clean-code:<skill>` and `clean-code:<agent>` inside output templates were left in Claude syntax in 353 generated files. They are rewritten to each target's syntax and the validator fails on any that survive.
- **Claims that were false outside Claude Code.** "in a forked context" and "You are running in an isolated context" (38 skills), the SessionStart hook sentence in every hub, "the default style" in every mode, `Claude Code toolkit` in the Codex, Gemini, Cursor and Copilot manifests and marketplaces, and "use proactively" in the Codex role descriptions.
- **Mis-rewrites.** The directory name `use-cases` in `clean-architecture`'s `layer-map` was rewritten as a skill; one-word sibling skills in descriptions, skill lists and "Skill" table columns were left unprefixed; "Load the skill" was capitalised after a comma in about 300 files. The maintainers' component map is shipped only for `refactoring-guru`, the one plugin whose skill points at it.
- **OpenCode.** The shell allowlist used prefix globs (`git diff*`, `ls*`, `rg*`), so `git diff --output=f`, `ls > f` and `rg --pre cmd` matched. The rules are now exact commands with deny rules after them, and `find` and `git branch --show-current`, which the role texts promise, are allowed. Mode agents carry a line saying they change style only.
- **Gemini.** Roles now name every skill by its `SKILL.md` path (a Gemini subagent cannot activate skills). **MCP:** agent prompts point at `get_rules` instead of a file. **Copilot:** mode agents are hidden from model delegation. **Cursor:** the rule description says when to apply it, and the marketplace version follows `package.json`.
- **MCP server.** A response larger than the pipe buffer was cut off when stdin closed; `get_rules` with a size such as `constructor`, null `params` or `arguments`, and a missing `uri` returned an internal error; an unknown tool was not a `-32602` error; malformed JSON-RPC (an empty batch, a non-object message) got no `-32600` reply; an unsupported protocol version was answered with an older one; tools had no `readOnlyHint`. `--plugins=x` was ignored, and a missing value, an unknown `--kinds` value or a mistyped option served every book without a word. All fixed and covered by `mcp-selftest.mjs`.
- **Installers and rules.** `install-opencode.mjs` counts only what it removes, deletes the folders it leaves empty and copies each plugin's `LICENSE` and `NOTICE.md`. `compose-rules.mjs` states the precedence in visible text, includes a repeated book once and rejects `--out` without a value.
- **Documentation.** The OpenCode "enforced" and "cannot modify your files" claims, the Codex catalog numbers (re-measured), the delegation claim, the install examples (which installed into the checkout), the Cursor plan requirement, the role-less Agent Skills build, the Gemini estimates and the sizes in `docs/ARCHITECTURE.md`.

### Verified with the real tools (isolated homes, no live model session)

Codex 0.162, OpenCode 1.19 and 2.0, Gemini CLI 0.64, `npx skills` 1.7.2, `skills-ref`, the MCP Inspector, Claude Code and Codex as MCP clients (2026-10-17). After the fixes above, Codex 0.162.1 (install, catalog, role files), the installers and the MCP self-test were re-run; the others were not. Details are in `docs/AGENTS_SUPPORT.md`.

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
- The `lead` agent of `clean-code` did not state the five-step cap that rule 15 of the plugin spec sets when 1.0.0 was dated, because that plugin was built before the rule was added; the wording pass of 2026-10-17 added it, and the validator now checks it for all 14 leads. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#3-the-four-component-types).
