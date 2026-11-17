---
name: "legacy-code-principles"
description: "Applies the Working Effectively with Legacy Code rules to changes in code that is untested, poorly understood or hard to instantiate. Use first on any such change: it states the modal convention and routes to every specialist; the order of work itself is `legacy-code-legacy-loop`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Working Effectively with Legacy Code principles

Gain control before improving design. Understand what the code does now, protect what must stay, make the smallest seam that lets you observe or isolate it, break the one dependency that blocks feedback, make the requested change, and leave the area easier to change than you found it.

## When the rules apply

- You change code that has no trustworthy tests, whose behavior nobody can state with confidence, or that cannot be instantiated or run without a database, a framework, a clock or a network.
- You review a diff or a pull request that touches such code and want to know whether it was changed safely.
- You are asked to add a feature to a module that is too fragile to reshape first, or to "clean up" a module that has no tests.
- Someone proposes a rewrite, a wholesale replacement or a module-wide cleanup of code you cannot yet observe.
- A user asks why a rule exists, how strong it is, or which technique fits a given obstacle.
- Not for: behavior-preserving restructuring once tests already protect the code (use the `refactoring` or `refactoring-guru` plugin), local readability and naming (the `clean-code` plugin), dependency direction between layers (the `clean-architecture` plugin), production failure behavior such as timeouts and bulkheads (the `release-it` plugin), or domain modeling (a `ddd` plugin). Those apply inside the area this plugin has first made safe to change.

## The bias this rule set corrects

An agent asked to change old code reads it, forms a theory, edits, and trusts the theory. When the code is hard to run, it either guesses, or it reaches for the opposite comfort: rewrite it cleanly, rename everything, or reshape the module "so it can be tested" in one large step that nobody can verify. Both failures skip the same thing, control. This rule set asks the agent to earn control first: state what must stay the same, pin what is uncertain, find the smallest place where behavior can be observed or replaced, remove only the dependency that blocks that, and then change behavior in a separate, small step. The cleanup that follows is local and is allowed to stay only where it still pays for itself.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/legacy-code/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention: the source says `MUST` is binding, `SHOULD` is a strong default and `MUST NOT` is forbidden. An unqualified imperative is a MUST, `Prefer` is a SHOULD, `Do not`, `Avoid`, `Never` and the forbidden-pattern lists are MUST NOT (one exception: the items under the "Preferred avoidance" heading of `Code Generation Rules` are a SHOULD, because the heading says preferred), and qualifiers such as "where possible", "when useful" or "only when" stay attached: a qualifier narrows when the rule applies and never lowers its strength. The technique index writes entries as "USE X when Y"; this plugin reads such an entry as a SHOULD that applies when Y holds, and reads "only when" entries as restrictions. Rules in this plugin's skills carry a tag: `[MUST]`, `[SHOULD]`, `[MUST NOT]` follow the source; `[Added judgment]` is this plugin's own heuristic, mechanic or language caveat (the source names most techniques but does not describe their mechanics and gives no thresholds); `[Compact checklist]` is phrasing found only in `mini.md` or `nano.md`. The Procedure, Example and Anti-patterns sections of a skill are working method and illustration unless a rule number is cited.

Terms used across the plugin: the **change point** is where the requested edit goes; a **test point** is where an effect can be observed with useful precision; a **seam** is a place where behavior can be changed without editing the surrounding code directly; a seam serves **sensing** (observe what the code computes or does), **separation** (get the code into a test at all) or both; a **barrier** is the first real obstacle between you and a test; **protection** means a trusted test would fail if the behavior broke.

## Subagent roles

Names such as `legacy-code-lead`, `legacy-code-final-gate` and the `...-reviewer` roles in the routing table are subagents. The OpenCode, Gemini CLI, Cursor and Copilot builds ship them as subagents, the MCP server serves them with get_guide, and in Codex they are installed separately; the plain Agent Skills build does not include them. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `legacy-code-lead` (delegate) |
| Review the working diff or named paths | `/legacy-code:review` |
| Rate legacy risk across a directory or repository | `/legacy-code:audit` |
| Plan a change in untested code before editing | `/legacy-code:plan`, `legacy-code-legacy-loop` |
| Resolve specific findings | `/legacy-code:fix` |
| Understand one rule or its strength | `/legacy-code:explain-rule` |
| Walk the nine review questions while working | `/legacy-code:checklist` |
| Strict pass or fail before commit or pull request | `legacy-code-final-gate` (delegate) |
| Current behavior is uncertain and must be pinned | `legacy-code-characterization-tests`, `/legacy-code:characterize`, `legacy-code-characterization-writer`, `legacy-code-protection-reviewer` |
| Choosing test level, writing tests for the requested change, testing through a seam | `legacy-code-focused-tests`, `legacy-code-test-level-reviewer` |
| Where a seam should go and what it is for | `legacy-code-seams`, `/legacy-code:find-seam`, `legacy-code-seam-reviewer` |
| Impact of a change is unclear, choose what to test | `legacy-code-test-points`, `/legacy-code:effect-sketch` |
| Code is too tangled to understand | `legacy-code-scratch-refactoring`, `/legacy-code:mode-explorer` |
| Clock, randomness, environment variables, thread-local state, current user or request | `legacy-code-hidden-inputs`, `legacy-code-hidden-input-reviewer`, `legacy-code-boundary-wrapper` |
| File writes, network calls, process exits, database writes, messages, logging as control flow | `legacy-code-hard-outputs`, `legacy-code-hard-output-reviewer`, `legacy-code-boundary-wrapper` |
| Constructor does real work, collaborators created inside methods, class cannot be built in a test | `legacy-code-construction-barriers`, `legacy-code-construction-reviewer`, `legacy-code-collaborator-injector` |
| Static calls, singletons, global configuration | `legacy-code-static-and-global`, `legacy-code-static-global-reviewer`, `legacy-code-global-encapsulator` |
| Concrete or oversized dependency blocks substitution | `legacy-code-substitution-seams`, `legacy-code-collaborator-injector` |
| Considering subclass-and-override, link, preprocessing, import, template or text redefinition seams | `legacy-code-last-resort-seams`, `legacy-code-seam-reviewer` |
| Test-only structure is already in the tree | `/legacy-code:seam-ledger`, `legacy-code-seam-cleaner` |
| New behavior must go into fragile code | `legacy-code-sprout-and-wrap`, `legacy-code-sprouter`, `legacy-code-sprout-opportunity-reviewer` |
| Long method, large class, tangled branches | `legacy-code-large-methods`, `legacy-code-large-method-reviewer`, `legacy-code-method-extractor` |
| Decisions trapped in handlers, callbacks, framework entry points or database-heavy code | `legacy-code-policy-vs-mechanism`, `legacy-code-policy-mechanism-reviewer`, `legacy-code-method-extractor` |
| A rewrite, wholesale replacement or cosmetic cleanup is proposed | `legacy-code-rewrite-pressure` |
| A patch mixes behavior change, structure and cleanup | `legacy-code-change-separation`, `legacy-code-change-intent-reviewer`, `/legacy-code:split-patch` |
| Session-long behavior: teach the reasoning | `/legacy-code:mode-mentor` |
| Session-long behavior: ranked findings only | `/legacy-code:mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `/legacy-code:mode-pair` |
| Session-long behavior: result first, few lines | `/legacy-code:mode-terse` |
| Session-long behavior: pin before every change | `/legacy-code:mode-characterize-first` |
| Session-long behavior: read-only understanding, no patch | `/legacy-code:mode-explorer` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with. The source allows a rewrite that is explicitly requested or clearly safer than continued change (`legacy-code-rewrite-pressure` tests that claim); Added judgment: the loop then still applies to how it is verified, by pinning what consumers rely on first.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep the work proportionate: do not widen scope to satisfy the rules, and do not clean the whole module before the requested change is safe.

## Final checklist

- [ ] Was untested or weakly tested code treated as legacy risk?
- [ ] Was current behavior captured where it was unclear?
- [ ] Was a seam created or exploited?
- [ ] Was at least one hard dependency reduced, without adding hidden ones?
- [ ] Is the changed area easier to test than before?
- [ ] Was a rewrite avoided as the first move?
- [ ] Do the edits stay local to the requested change?
- [ ] Are structural changes separate from behavior changes where practical?
- [ ] Was the code left more changeable than it was found?

If any answer is no, revise before handing the work over. When you report: say what changed, which tests ran, what is still unprotected, and which temporary seams have a cleanup path.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Working Effectively with Legacy Code is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Working Effectively with Legacy Code would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Purpose`
- `Primary Directive`
- `Non-Negotiable Rules`
- `Default Workflow for Legacy Changes`
- `Review Checklist`
- `Final Instruction`
