---
name: "principles"
description: "Applies the Code Complete rules to everyday construction work: any task that writes, changes, reviews, debugs or tunes code where defect risk, readability, data meaning, control flow or tests matter. A matching topical skill wins; sequencing a large change: $code-complete:construction-process."
---

# Code Complete principles

Construction quality is not accidental. Deliver the behavior, and make the code you write easy to inspect, hard to misuse and cheap to verify, without turning the task into a redesign.

## When the rules apply

- You write or change application code and the main risk is a defect that review or a test would catch late: wrong boundary, unchecked input, reused variable, tangled branch.
- You review a diff or a file for routine design, data meaning, control flow, defensive checks, comments, style consistency or tests.
- You debug a failure, refactor risky code, or are asked to make something faster.
- You start a non-trivial change from a proposed solution and the requirements, error policy or data shape are not yet settled.
- A user asks why a construction rule exists or how far it bends.
- Not for: dependency direction between layers (use a `clean-architecture` plugin), module depth and interface trade-offs (use a `philosophy-of-design` plugin), reshaping legacy code that has no tests (characterize first with a `legacy-code` plugin), or production failure behavior such as timeouts and overload (use a `release-it` plugin).

## The bias this rule set corrects

An agent asked for a feature tends to stop at the first thing that works. It starts from the first solution that comes to mind, writes the happy path, trusts every caller, adds a boolean when one case differs, leaves a `-1` that means "none", nests one more `if`, and reports success because the single scenario it tried passed. This rule set asks for the opposite order of attention: know what you are building, shape each routine, datum and branch so a reader can verify it, decide explicitly what happens at the edges, and let evidence rather than a guess drive fixes, refactors and tuning. It also pushes back on the opposite vice: cleverness, fashionable idioms and speculative code that make the code harder to inspect.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/code-complete/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention. The source declares that `MUST` is binding, `SHOULD` is a strong default and `MUST NOT` is forbidden. This plugin reads the rule lists as follows: an imperative with no qualifier is binding; `should`, `prefer`, `favor` and the qualifiers "as practical", "when possible" and "where appropriate" make a strong default; `avoid`, `do not` and every entry under "Anti-patterns (MUST NOT)" and "Forbidden Patterns" are prohibitions. Skills in this plugin keep that strength and keep the source's own escape clauses ("unless they are clearer", "when the mapping is stable").

Labels used in this plugin. A rule with no label is stated in `references/full.md`. **Compact rule** marks guidance found only in `mini.md` or `nano.md`. **Added judgment** marks this plugin's own heuristic, threshold or technique; it is not a rule of the source. The source gives no numeric limits, so every number in this plugin is Added judgment and is a search aid, not a verdict.

Tie-breaker. When two options both satisfy the request and you are uncertain, choose the one that, in this order, lowers defect probability, is easier to inspect and reason about, reduces control-flow complexity, uses data and routines clearly, and protects the program against invalid states and misuse.

## Subagent roles

Names such as `code-complete-lead`, `code-complete-final-gate` and the `...-reviewer` roles in the routing table are subagents. In Codex they are custom roles that a plugin cannot bundle: install them with `node scripts/install-codex-agents.mjs code-complete` from a clone of the repository, then ask for one by name. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `code-complete-lead` (delegate) |
| Review the working diff or named paths | `$code-complete:review` |
| Health picture of a directory or repository | `$code-complete:audit`; raw numbers only: `code-complete-construction-scanner` |
| Plan a non-trivial change before editing | `$code-complete:plan`, rules in `$code-complete:construction-process` |
| Is this change one verifiable increment, or mixed with a refactor or half-done work | `code-complete-increment-reviewer` |
| Understand one rule or its exceptions | `$code-complete:explain-rule` |
| Walk the review checklist while working | `$code-complete:checklist` |
| Strict pass or fail before commit or pull request | `code-complete-final-gate` (delegate) |
| Resolve specific findings | `$code-complete:fix` |
| A complex routine is about to be written | `$code-complete:pseudocode` |
| A routine mixes phases, has a vague name or hidden effects | `$code-complete:routine-design`, `code-complete-routine-reviewer` |
| Long parameter lists, boolean mode flags, return values that are easy to misuse | `$code-complete:routine-interface`, `code-complete-interface-reviewer` |
| A variable is vague, wide in scope, reused or uninitialized | `$code-complete:variables`, `code-complete-data-reviewer` |
| Magic numbers, sentinels, units, flag fields, status strings | `$code-complete:data-types`, `code-complete-data-reviewer` |
| Nested or compound conditions, switch, multiple exits, dead branches | `$code-complete:control-flow`, `code-complete-control-flow-reviewer` |
| Loops, statement order, negated conditions, normal-path placement | `$code-complete:statements-and-loops`, `code-complete-control-flow-reviewer` |
| Repeated branching that maps categories or ranges to results | `$code-complete:table-driven`, `code-complete-table-reviewer` |
| Input from users, files, networks or other services | `$code-complete:trust-boundaries`, `code-complete-trust-boundary-reviewer`, scan a tree with `$code-complete:trust-boundary-scan`, add checks with `code-complete-boundary-hardener` |
| Preconditions, postconditions, invariants, assertion versus validation | `$code-complete:assertions-and-contracts`, `code-complete-contract-reviewer` |
| Exceptions, error codes, catch blocks, messages, fallbacks | `$code-complete:error-handling`, `code-complete-error-flow-reviewer` |
| A class or module does too much or exposes its internals | `$code-complete:class-design`, `code-complete-class-design-reviewer` |
| Tangled code, duplicated rules, clever expressions | `$code-complete:complexity-management`, `code-complete-complexity-reviewer` |
| Comments that narrate, lie or prop up unclear code | `$code-complete:comments`, `code-complete-comment-reviewer` |
| New code does not match the codebase's style or idioms | `$code-complete:coding-standards`, `code-complete-consistency-reviewer` |
| Something fails and the cause is unknown | `$code-complete:debugging`, `code-complete-bug-fixer` |
| Writing or judging tests for a routine | `$code-complete:routine-testing`, `$code-complete:test-matrix`, `code-complete-test-case-reviewer`, `code-complete-test-writer` |
| Restructuring existing code | `$code-complete:refactoring-judgment`, `code-complete-refactorer` |
| Asked to make something faster | `$code-complete:performance-tuning`, then `$code-complete:tune`, audited by `code-complete-tuning-reviewer` |
| Session-long behavior: teach the reasoning | `$code-complete:mode-mentor` |
| Session-long behavior: ranked findings only | `$code-complete:mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `$code-complete:mode-pair` |
| Session-long behavior: result first, few lines | `$code-complete:mode-terse` |
| Session-long behavior: assumptions listed before every change | `$code-complete:mode-assumptions-first` |
| Session-long behavior: no cause, fix or speedup without evidence | `$code-complete:mode-evidence-first` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed (see `$code-complete:coding-standards`).
3. This book's rules.

Keep cleanup proportionate to the task. Do not widen scope to satisfy the rules, and do not leave touched code harder to inspect than you found it.

## Code generation defaults

When you write new code, default to clear names, focused routines, explicit data meaning, simple control flow, defensive checks at boundaries, cohesive classes and modules, and consistent style. Avoid by default dense clever code, broad god objects, fragile hidden assumptions, needless complexity in loops and conditionals, and comments where a better name or a smaller routine would do.

## Final checklist

- [ ] Names are clear and intention-revealing.
- [ ] Routines are focused and reasonably small.
- [ ] Control flow is straightforward.
- [ ] Trust boundaries are defended.
- [ ] Contracts and invariants are explicit enough.
- [ ] Complexity was reduced, or at least not increased.
- [ ] Classes and modules are cohesive.
- [ ] No cleverness harms inspection.
- [ ] Comments exist only where they add value.
- [ ] Style is consistent with the rest of the codebase.
- [ ] Compact rule: tests, reviews, debugging, refactoring and tuning in this change rest on evidence, not on a guess.

If any answer is no, revise before shipping. When you report the work, say briefly what changed, which tests or checks ran, and any unresolved risk, assumption or trade-off.

## Source

- `Purpose`
- `Primary Directive`
- `Foundational Construction Rules`
- `Code Generation Rules`
- `Review Checklist`
- `Final Instruction`
