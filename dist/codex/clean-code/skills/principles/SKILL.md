---
name: "principles"
description: "Applies the Clean Code rule set to everyday coding and review. Use for any task that writes, reviews or changes code where readability, names, function shape, side effects, comments, error handling, tests or cleanup of touched code matter."
---

# Clean Code principles

Working code is not automatically clean code. Deliver the behavior, and leave the code you touched easier for the next reader to change, without turning the task into a rewrite.

## When the rules apply

- You write or change application code and the main risk is that the next person cannot follow it locally.
- You review a diff, a pull request or a single file for readability, naming, function shape, comments, error handling or test quality.
- You are about to clean up code you touched and need to decide how much is proportionate.
- A user asks why a rule exists, whether a smell is real, or how to sequence a refactor.
- Not for: dependency direction between layers (use a Clean Architecture plugin), deep module and API design trade-offs (use a software-design plugin), or reshaping legacy code that has no tests (characterize behavior first with a legacy-code plugin, then come back).

## The bias this rule set corrects

An agent asked to add behavior tends to stop when the test passes. The names it chose while exploring stay, the new branch lands inside a function that already did three things, the flag parameter that "just works" gets one more caller, and a comment is added to explain what a rename would have made obvious. The opposite failure also happens: asked to "clean up", the agent reformats and restructures half a module. This rule set asks for the middle path. Cleanliness is part of delivery, the touched code ends up better than it started, and the amount of cleanup is capped by what the requested change makes safe and readable.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/clean-code/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention: an unqualified rule is a MUST, `Prefer` is a SHOULD, `Do not`, `Avoid` and `Never` are MUST NOT, unless the user explicitly overrides it. Skills in this plugin keep that strength: where a rule says "Prefer", the skill says "Prefer". Text marked "Added judgment" is this plugin's own heuristic, not a rule of the source. Text marked "compact checklist" comes from `mini.md` only and is not in `full.md`. Examples are splitting a function by phase (`$clean-code:function-shape`), modelling a grab-bag argument list as a concept (`$clean-code:function-contracts`), enforcing call order through types (`$clean-code:class-design`) and the ranking rule: when touching code, remove the smell that most increases the cost of the next change. `$clean-code:boy-scout`, `$clean-code:smell-hunt`, `$clean-code:audit` and `$clean-code:mode-smell-first` use the ranking rule to choose and order work.

## Subagent roles

Names such as `clean-code-lead`, `clean-code-final-gate` and the `...-reviewer` roles in the routing table are subagents. In Codex they are custom roles, which a plugin cannot switch on by itself: run `$clean-code:install-roles` once, restart Codex, then ask for one by name. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `clean-code-lead` (delegate) |
| Review the working diff or named paths | `$clean-code:review` |
| Health picture of a directory or repository | `$clean-code:audit` |
| Find smells and map each to its treatment | `$clean-code:smell-hunt`, `clean-code-smell-scanner` for raw metrics |
| Plan a non-trivial change before editing | `$clean-code:plan` |
| Resolve specific findings | `$clean-code:fix` |
| Clean only the code you touched | `$clean-code:boy-scout`, audited by `clean-code-scope-guard` |
| Understand one rule or its exceptions | `$clean-code:explain-rule` |
| Walk the final checklist while working | `$clean-code:checklist` |
| Strict pass or fail before commit or pull request | `clean-code-final-gate` (delegate) |
| Choosing or fixing identifiers | `$clean-code:naming`, `clean-code-naming-reviewer`, `$clean-code:vocabulary-audit` for synonym drift across a tree |
| A function is long, nested or mixes levels | `$clean-code:function-shape`, `clean-code-function-reviewer`, `$clean-code:extract-till-you-drop`, `clean-code-function-extractor` |
| Parameters, flags, side effects, query that mutates | `$clean-code:function-contracts`, `clean-code-contract-reviewer` |
| Comments that narrate, lie or substitute for names | `$clean-code:comments`, `clean-code-comment-reviewer` |
| File layout, ordering, line length, alignment | `$clean-code:formatting`, `clean-code-layout-reviewer` |
| Getter chains, exposed fields, data carrier versus object | `$clean-code:data-and-objects`, `clean-code-object-design-reviewer` |
| A class does too much or changes for many reasons | `$clean-code:class-design`, `clean-code-class-design-reviewer` |
| Exceptions, null returns, cleanup paths | `$clean-code:error-handling`, `clean-code-error-handling-reviewer` |
| Third-party library or service used directly | `$clean-code:boundaries`, `clean-code-boundary-reviewer`, `$clean-code:learning-tests`, `clean-code-adapter-builder` |
| Objects created inside business code, wiring, cross-cutting clutter | `$clean-code:system-construction`, `clean-code-construction-reviewer` |
| Writing or judging a test | `$clean-code:clean-tests`, `clean-code-test-quality-reviewer`, `clean-code-test-writer` |
| Changed behavior without a test, bug fix, skipped tests | `$clean-code:tdd-discipline`, `clean-code-test-gap-reviewer` |
| Threads, async tasks, locks, shutdown, flaky timing | `$clean-code:concurrency`, `clean-code-concurrency-reviewer` |
| Restructuring existing code safely | `$clean-code:refactoring-steps`, `clean-code-refactorer` |
| Rough draft that works and needs shaping | `$clean-code:successive-refinement` |
| Choosing between designs, deciding whether an abstraction earns its place | `$clean-code:emergent-design`, `clean-code-simplicity-reviewer` |
| Duplication, dead code, wrappers that only delegate | `$clean-code:smells-redundancy` |
| One change that touches many files, base class that knows its subclasses, repeated type switches | `$clean-code:smells-coupling` |
| Code that does not do the obvious thing, wrong edge behavior, disabled checks | `$clean-code:smells-surprise` |
| Session-long behavior: teach the reasoning | `$clean-code:mode-mentor` |
| Session-long behavior: ranked findings only | `$clean-code:mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `$clean-code:mode-pair` |
| Session-long behavior: result first, few lines | `$clean-code:mode-terse` |
| Session-long behavior: name the smell before every edit | `$clean-code:mode-smell-first` |
| Session-long behavior: report what was left cleaner and what was not touched | `$clean-code:mode-campsite` |

## Priority

The source says to follow the user and mention the conflict, and to reuse project conventions unless they conflict with its rules or the user asks otherwise. Placing conventions above the book's rules is Added judgment on top of that, which is why item 2 carries an exception.

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep cleanup proportionate to the task. Do not widen scope to satisfy the rules, and do not leave touched code less readable than you found it.

## Final checklist

- [ ] Names reveal intent and one term is used per concept.
- [ ] Functions are small, focused and at one level of abstraction.
- [ ] Classes and modules have clear responsibilities.
- [ ] Comments are necessary and accurate; none compensates for a weak name.
- [ ] Error handling is explicit and useful, and the happy path still reads cleanly.
- [ ] Duplication was removed where reasonable.
- [ ] Tests cover the changed behavior appropriately, and you ran them.
- [ ] The code reads cleanly from top to bottom.
- [ ] The design is simpler, or at least not more complex, than before.
- [ ] The change follows existing project conventions and did not silently broaden scope.

When you report the work: say briefly what changed, which tests or checks ran, and any unresolved risk, assumption or trade-off.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Clean Code is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Clean Code would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Priority and behavior`
- `Core clean code principles`
- `Change Process`
- `Review checklist`
- `Output Expectations`
- `Hard rules`
