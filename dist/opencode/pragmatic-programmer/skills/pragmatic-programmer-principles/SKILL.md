---
name: "pragmatic-programmer-principles"
description: "Applies The Pragmatic Programmer rule set to everyday engineering decisions. Use for any task that writes, reviews, changes or plans code where duplicated knowledge, coupling, feedback speed, automation, contracts or ownership of the result matter. Routes to the specialist components."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# The Pragmatic Programmer principles

A change is finished when the result is something you would stand behind: one place owns each fact, unrelated things stay independent, the feedback is fast, repeated work is a script, assumptions are written in code, and the area you touched is no worse than you found it. Be pragmatic, not dogmatic: the goal is real outcomes, not ritual.

## When the rules apply

- You write, change or plan code and the main risk is a local edit with system-level consequences: a copied rule, a change that has to be repeated in three places, a guess nobody can verify.
- You review a diff or a pull request for duplicated knowledge, hidden coupling, long feedback loops, manual steps, unclear contracts or poor communication.
- You start a new capability, debug a defect, evaluate a prototype, or decide how far to take a cleanup.
- A user asks why a rule exists, whether a practice earns its cost, or how strong a rule is.
- Not for: local readability and function shape (a Clean Code plugin), routine-level construction detail (a Code Complete plugin), safe sequencing of structural change (a refactoring plugin), reshaping untested code before you can change it (a legacy-code plugin), dependency direction between layers (a Clean Architecture plugin), or production failure defenses such as timeouts and bulkheads (a Release It! plugin).

## The bias this rule set corrects

An agent asked for a change optimizes the edit in front of it. It copies the nearest similar block, because that is the quickest route to a passing test. It adds the call where the data happens to live. It accepts a request that names a solution as if it were the requirement. It runs one test file and calls the work done. It leaves a "temporary" workaround without an exit and blames the framework for the shape of the result. Each choice is locally reasonable and the system pays for it later: the same rule lives in four places, one change needs edits in six files, the release has a seven-step ritual nobody has scripted, and the first end-to-end run happens last. This rule set asks for the opposite habit. Own the outcome beyond the edit: keep one authoritative owner for each fact, keep concerns independent, prove assumptions early with a thin working slice, make the cheap early signal cheap, automate what repeats, write assumptions into code, and stop when the result is good enough for its real users and risks.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/pragmatic-programmer/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention: the source says `MUST` is binding, `SHOULD` is a strong default and `MUST NOT` is forbidden. An unqualified imperative is a MUST, `Prefer` and "should" are a SHOULD, `Do not`, `Avoid`, `Never` and the anti-pattern lists are MUST NOT, and qualifiers such as "where practical", "where relevant", "where possible", "where they fit" or "unless justified" stay attached. A qualifier narrows when the rule applies; it never lowers the tag, so an unqualified imperative with a "where ..." clause is a `[MUST]` that keeps the clause. Rules in this plugin's skills carry a tag: `[MUST]`, `[SHOULD]`, `[MUST NOT]` follow the source; `[Added judgment]` is this plugin's own heuristic or threshold (the source gives no numbers); `[Compact checklist]` is phrasing found only in `mini.md` or `nano.md`.

## Subagent roles

Names such as `pragmatic-programmer-lead`, `pragmatic-programmer-final-gate` and the `...-reviewer` roles in the routing table are subagents. The OpenCode, Gemini CLI, Cursor and Copilot builds ship them as subagents, the MCP server serves them with get_guide, and in Codex they are installed separately; the plain Agent Skills build does not include them. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `pragmatic-programmer-lead` (delegate) |
| Review the working diff or named paths | `pragmatic-programmer-review` |
| Rate each concern across a tree | `pragmatic-programmer-audit` |
| Plan a non-trivial change before editing | `pragmatic-programmer-plan` |
| Plan one new capability as a thin end-to-end slice | `pragmatic-programmer-tracer-plan`, `pragmatic-programmer-tracer-bullets`, `pragmatic-programmer-slice-reviewer` |
| Resolve specific findings | `pragmatic-programmer-fix` |
| Understand one rule or its strength | `pragmatic-programmer-explain-rule` |
| Walk the review checklist while working | `pragmatic-programmer-checklist` |
| Strict pass or fail before commit or pull request | `pragmatic-programmer-final-gate` (delegate) |
| How far to take a change, what to report, when to stop | `pragmatic-programmer-ownership` |
| Small decay in the code you touched | `pragmatic-programmer-broken-windows`, `pragmatic-programmer-decay-reviewer`, `pragmatic-programmer-tidy-touched` |
| The same rule, mapping or validation in more than one place | `pragmatic-programmer-dry-knowledge`, `pragmatic-programmer-knowledge-duplication-reviewer`, `pragmatic-programmer-knowledge-consolidator` |
| Map every place each fact lives across a tree | `pragmatic-programmer-knowledge-map` |
| One change needs edits in many places, overlapping responsibilities | `pragmatic-programmer-orthogonality`, `pragmatic-programmer-coupling-reviewer` |
| Reach-through call chains, fixed call order | `pragmatic-programmer-shy-code`, `pragmatic-programmer-coupling-reviewer` |
| Globals, caches, ambient context, threads, async, locks | `pragmatic-programmer-shared-state`, `pragmatic-programmer-shared-state-reviewer` |
| Files, connections, handles, temp state, growth of cost with input size | `pragmatic-programmer-resource-discipline`, `pragmatic-programmer-resource-reviewer` |
| Assumptions in comments, assertions, nonsense return values | `pragmatic-programmer-contracts`, `pragmatic-programmer-contract-reviewer`, `pragmatic-programmer-contract-writer` |
| How failures travel: context, retryable or permanent, containment | `pragmatic-programmer-error-recovery`, `pragmatic-programmer-failure-path-reviewer` |
| Vendor, database, platform, format or policy that may change | `pragmatic-programmer-reversible-choices`, `pragmatic-programmer-reversibility-reviewer` |
| A request that names a solution, a spec that keeps growing | `pragmatic-programmer-requirements` |
| Throwaway experiment, spike, proof of concept | `pragmatic-programmer-prototypes`, `pragmatic-programmer-prototype-charter` |
| Prototype, scaffold or generated code about to become production | `pragmatic-programmer-provenance-reviewer`, `pragmatic-programmer-prototype-charter` |
| Generated code, scaffolds, rule files, metaprogramming | `pragmatic-programmer-generators-and-dsls`, `pragmatic-programmer-provenance-reviewer` |
| Manual steps, release rituals, README step lists | `pragmatic-programmer-automation`, `pragmatic-programmer-automation-reviewer`, `pragmatic-programmer-automation-scripter` |
| Scan docs, scripts and CI for manual rituals | `pragmatic-programmer-manual-step-hunt` |
| Slow, flaky or late checks, failures that are hard to see | `pragmatic-programmer-feedback-loops`, `pragmatic-programmer-feedback-loop-reviewer` |
| Which tests a change needs, a bug found by a person | `pragmatic-programmer-test-portfolio`, `pragmatic-programmer-test-portfolio-reviewer` |
| A defect, intermittent failure or behavior nobody can explain | `pragmatic-programmer-debugging`, `pragmatic-programmer-debug-session`, `pragmatic-programmer-bug-fixer` |
| Names, comments, docs, commit messages, scripts that must carry intent | `pragmatic-programmer-code-communication`, `pragmatic-programmer-communication-reviewer` |
| Session-long behavior: teach the reasoning | `pragmatic-programmer-mode-mentor` |
| Session-long behavior: ranked findings only | `pragmatic-programmer-mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `pragmatic-programmer-mode-pair` |
| Session-long behavior: result first, few lines | `pragmatic-programmer-mode-terse` |
| Session-long behavior: thinnest real path first | `pragmatic-programmer-mode-tracer-first` |
| Session-long behavior: ownership block after every task | `pragmatic-programmer-mode-owner` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep the change proportionate. The source asks for quality that suits the real users and risks, not for perfection; do not widen the scope to satisfy the rules, and do not leave touched code worse than you found it.

## Final checklist

- [ ] Did we reduce duplicated knowledge?
- [ ] Are responsibilities more orthogonal after the change?
- [ ] Did we improve or preserve fast feedback?
- [ ] Did we automate anything repetitive that was hurting reliability?
- [ ] Are contracts and assumptions clearer?
- [ ] Is the code easier to communicate about?
- [ ] Did we avoid prototype shortcuts becoming silent production defaults?
- [ ] Did we fix at least one small broken window if it was in the touched area?
- [ ] [Compact checklist] Are state, concurrency, ordering and coupling visible, and were the relevant automatic tests run before calling the change done?

If any answer is no, revise before shipping. When you report the work, say briefly what changed, which tests or checks ran, and the trade-offs, risks and uncertainty that remain.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if The Pragmatic Programmer is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("The Pragmatic Programmer would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Purpose`
- `Primary Directive`
- `Core Pragmatic Principles`
- `Code Generation Rules`
- `Review Checklist`
- `Final Instruction`
