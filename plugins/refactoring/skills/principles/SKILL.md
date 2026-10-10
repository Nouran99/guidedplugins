---
name: principles
description: "Applies the Refactoring rule set (behavior-preserving structural change in small, tested steps) to any task that changes existing code. Use first for feature work, bug fixes, cleanup and review of existing code; it routes to the specific skill, agent or mode."
---

# Refactoring principles

Change the structure of code without changing what it does, in steps small enough to verify, and do it at the moment it makes the next change easier. Structure work and behavior work are different jobs; do them one at a time.

## When the rules apply

- You are about to change existing code (feature, bug fix, performance work) and its current shape makes the change awkward or risky.
- You are cleaning up code, or reviewing a change that calls itself cleanup, a rename, a move or a refactoring.
- You must decide how much to restructure, in what order, and when to stop.
- Someone asks why a smell matters, which named move treats it, or whether a proposed abstraction is justified.
- Not for: choosing a target architecture or domain model (use an architecture or domain-driven design plugin such as `clean-architecture` or `ddd`), taking untested legacy code under control with seams and dependency-breaking techniques (use `legacy-code`; this plugin's `/refactoring:characterize` is the light version), or production failure behavior such as timeouts and overload.

## The bias this rule set corrects

Without it, an agent fails in one of two directions. Asked to add a feature to awkward code, it bolts the feature on and leaves the structure worse; asked to improve code, it rewrites a module, renames half the tree, adds an interface "for later", and ships one patch in which nobody can tell which lines changed behavior. This rule set asks for the narrow path between them: establish a safety net, make the smallest structural change that makes the requested change easy, make that change separately, clean up what it introduced, and stop. Restraint is part of the discipline, not a softening of it: the source forbids abstracting coincidental similarity, replacing an honest conditional with indirection, and adding interfaces before a second real need.

## Loading the rules

1. For every design or code decision, Read `${CLAUDE_SKILL_DIR}/references/mini.md` first.
2. Read `${CLAUDE_SKILL_DIR}/references/full.md` only when the mini rules do not settle a trade-off. Name the section you need (for example `Refactoring Catalog Index`).
3. `${CLAUDE_SKILL_DIR}/references/nano.md` is the compact always-on form; the optional SessionStart hook injects it.

Modal convention: an unqualified rule is a MUST, `Prefer` is a SHOULD, `Do not`, `Avoid` and `Never` are MUST NOT, unless the user explicitly overrides it. Skills here keep that strength. Text marked "Added judgment" is this plugin's own heuristic or mechanic, not a rule of the source; text marked "compact checklist" appears only in the short rule files. The catalog index in the source gives a trigger per move, not the mechanics; its names are mostly first-edition names, and the second edition renames some (Extract Method became Extract Function, for example).

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialists apply to a task or diff | `refactoring:lead` (delegate) |
| Review the working diff or named paths | `/refactoring:review` |
| Where is change expensive in this tree, and is it safe to touch | `/refactoring:audit` |
| Map confirmed smells to the smallest named move | `/refactoring:smell-to-refactoring` |
| Plan a change in the book's order (friction, net, prep, change, follow-up, stop) | `/refactoring:plan` |
| Do only the preparatory refactoring for a stated change | `/refactoring:prepare` |
| Resolve specific findings | `/refactoring:fix`, or `refactoring:refactorer` for a long list |
| Pin unclear behavior with tests before touching it | `/refactoring:characterize` |
| A diff mixes intents; split it into single-intent patches | `/refactoring:split-patch` |
| Understand one rule, smell or catalog move | `/refactoring:explain-rule` |
| Walk the final checklist while working | `/refactoring:checklist` |
| Strict PASS or FAIL before commit or pull request | `refactoring:final-gate` (delegate) |
| Is this really a refactoring; did behavior change | `/refactoring:behavior-preservation`, `refactoring:behavior-preservation-reviewer` |
| Step size, rewrite urge, runnable states | `/refactoring:small-steps` |
| Tests absent or weak; tests edited during a refactoring | `/refactoring:safety-net`, `refactoring:safety-net-reviewer`, `refactoring:test-change-reviewer` |
| A feature is awkward to add in the current structure | `/refactoring:preparatory-steps` |
| One patch carries several intents | `/refactoring:patch-hygiene`, `refactoring:patch-intent-reviewer` |
| Should cleanup continue; did it remove real friction | `/refactoring:stopping-rules`, `refactoring:friction-reviewer` |
| Same logic in several places; a proposed utils module | `/refactoring:duplication`, `refactoring:duplication-reviewer` |
| Long function, mixed phases, temporaries and expressions | `/refactoring:function-bodies`, `refactoring:function-reviewer` |
| Many parameters, boolean flags, argument order | `/refactoring:call-signatures`, `refactoring:signature-reviewer` |
| Globals, singletons, clock, config, hidden side effects | `/refactoring:hidden-dependencies`, `refactoring:dependency-reviewer` |
| Misplaced behavior, many reasons to change, ripple edits | `/refactoring:ownership`, `refactoring:ownership-reviewer`, `refactoring:class-splitter` |
| Primitive bundles and loaded primitives | `/refactoring:primitive-obsession`, `refactoring:primitive-reviewer`, `refactoring:value-type-introducer` |
| Public state, setters, exposed collections | `/refactoring:mutation-control`, `refactoring:mutation-reviewer` |
| Hard-to-read branching in one function | `/refactoring:conditionals` |
| Same type code switched on in many places; weird lifecycles | `/refactoring:variation-and-state`, `refactoring:conditional-reviewer`, `refactoring:conditional-refactorer` |
| Forwarding layers, one-implementation interfaces, just-in-case code | `/refactoring:needless-abstraction`, `refactoring:abstraction-reviewer` |
| Hierarchies that need reshaping | `/refactoring:inheritance-moves`, `refactoring:hierarchy-reviewer` |
| Error handling hides the main path | `/refactoring:error-paths`, `refactoring:error-path-reviewer` |
| Bad names block understanding | `/refactoring:renaming` |
| Session-long: explain the rule behind each choice | `/output-style refactoring:mentor` |
| Session-long: ranked findings only | `/output-style refactoring:strict-reviewer` |
| Session-long: small narrated steps, ask before bigger ones | `/output-style refactoring:pair` |
| Session-long: result first, few lines | `/output-style refactoring:terse` |
| Session-long: label every edit as structure or behavior | `/output-style refactoring:two-hats` |
| Session-long: friction, net, prep, change, follow-up, stop on every task | `/output-style refactoring:prep-first` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule (a rewrite the user really wants), follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep cleanup within the scope of the change that justifies it: refactor the smell that blocks the current change, not every smell in sight (compact checklist). Do not widen scope to satisfy the rules.

## Final checklist

- [ ] Observable behavior is preserved by every structural step.
- [ ] Structural change, behavior change and test updates are separated where practical.
- [ ] At least one real source of friction was removed.
- [ ] The code is easier to read, and easier to test or change.
- [ ] Duplication or accidental complexity went down, and no speculative abstraction was added.
- [ ] The patch is not a giant mixed one, and it is still reviewable and runnable.
- [ ] Names, control flow and responsibilities are clearer.
- [ ] The safety net, characterization or verification gap is stated (compact checklist).
- [ ] Cleanup stopped when the change became easy.

If any answer is no, revise before shipping. When you report: say what changed, which tests ran, what you left alone, and any unverified risk.

## Source

- `Purpose`
- `Primary Directive`
- `What Counts as Refactoring`
- `Non-Negotiable Rules`
- `Code Generation Rules`
- `Stopping Rules`
- `Review Checklist`
- `Final Instruction`
