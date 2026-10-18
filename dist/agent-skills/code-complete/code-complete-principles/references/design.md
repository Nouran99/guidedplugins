# Code Complete plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md` (27 of them; the five `###` entries under `Forbidden Patterns` are cited by the components that own them).

## Design decisions

1. **The upstream rule set is short and dense, so components are separated by role and by situation, not by paraphrase.** Each cluster has a rules skill (loaded by Claude from its description), usually one read-only reviewer with its own report shape, and, where the book teaches a distinct activity, a manual workflow or an implementer.
2. **Routine, data, control flow and defensive code are split where a reader meets them in a diff.** Routine body versus routine signature, variable lifetime versus data meaning, branch shape versus loops and statement order, external input versus internal assumptions versus the failure path. Each split has a discriminating clause in at least one description, and in both for the closest pairs (see "Confusable pairs").
3. **Rule provenance is labelled.** A rule with no label is stated in `references/full.md`. `Compact rule` marks guidance found only in `mini.md` or `nano.md` (for example "set a target, change one thing, remeasure"). `Added judgment` marks this plugin's own heuristics, thresholds and techniques (nesting or parameter counts used as search aids, "write the contract as a table", and so on). The source gives no numeric thresholds; every number in this plugin is Added judgment.
4. **The book's own brake is kept in every editing component.** The source asks for low-defect construction and also warns against the opposite excess: clarity over cleverness, simple over fashionable, no speculative code, tuning only with evidence, refactoring kept apart from behavior change when that improves reviewability. Implementers and `fix` change the smallest thing that resolves a finding, run the project's tests and never commit.
5. **Model-invocable skills are capped at 20.** There are 20: the hub plus 19 topical skills. Everything that is a procedure with arguments is manual (10 skills).
6. **Review Rules and Forbidden Patterns have owners.** The ten "look for" items of `Review Rules` and the five `Forbidden Patterns` each have exactly one owning skill (tables below). `review` and `code-complete-final-gate` check them all; they are not restated in the skills that do not own them.
7. **Agents own one concern and have their own output shape.** A routine reviewer reports a routine ledger, a trust-boundary reviewer reports a boundary inventory, a contract reviewer reports an assumption ledger, a table reviewer reports a mapping inventory. No two reviewers share a report.

## Ownership of the "Review Rules" look-fors

| Look for | Owner skill | Reviewer |
| --- | --- | --- |
| unclear names | `variables` (variable names), `code-complete-routine-design` (routine names), `code-complete-data-types` (constants, types) | `code-complete-data-reviewer`, `code-complete-routine-reviewer` |
| weak routine boundaries | `code-complete-routine-design` | `code-complete-routine-reviewer` |
| long parameter lists | `code-complete-routine-interface` | `code-complete-interface-reviewer` |
| unnecessary nesting | `code-complete-control-flow` | `code-complete-control-flow-reviewer` |
| hidden side effects | `code-complete-routine-design` | `code-complete-routine-reviewer` |
| poor defensive checks at trust boundaries | `code-complete-trust-boundaries` | `code-complete-trust-boundary-reviewer` |
| duplicated logic | `code-complete-complexity-management` | `code-complete-complexity-reviewer` |
| confusing control flow | `code-complete-control-flow`, `code-complete-statements-and-loops` | `code-complete-control-flow-reviewer` |
| god classes or mixed responsibilities | `code-complete-class-design` | `code-complete-class-design-reviewer` |
| comments compensating for poor structure | `comments` | `code-complete-comment-reviewer` |

## Ownership of the Forbidden Patterns

| Forbidden pattern | Owner skill | Also checked by |
| --- | --- | --- |
| Cleverness over Clarity | `code-complete-complexity-management` | `code-complete-complexity-reviewer`, `code-complete-final-gate` |
| Routine Bloat | `code-complete-routine-design` (body), `code-complete-routine-interface` (signature) | `code-complete-routine-reviewer`, `code-complete-interface-reviewer`, `code-complete-final-gate` |
| Defensive Vacuum | `code-complete-trust-boundaries`, `code-complete-assertions-and-contracts`, `code-complete-error-handling` | the three matching reviewers, `code-complete-final-gate` |
| Comment-as-Crutch | `comments` | `code-complete-comment-reviewer`, `code-complete-final-gate` |
| Consistency Neglect | `code-complete-coding-standards` | `code-complete-consistency-reviewer`, `code-complete-final-gate` |

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, labels, modal convention, tie-breaker, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Foundational Construction Rules; Code Generation Rules; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules. |
| `code-complete-construction-process` | Prerequisites and decisions before a non-trivial change, slice-first under uncertainty, small increments, early integration | Construction Prerequisites and Decisions; Incremental Construction Rules; Performance, Integration, Tools, and Craftsmanship (integration) | It holds the rules for what must be settled and how to order the work; `code-complete-plan` is the manual workflow that writes the plan, and `code-complete-routine-design` is about one routine. |
| `code-complete-routine-design` | Routine purpose, name, phase separation, hidden effects, routine bloat | Routine Design Rules; Forbidden Patterns; Review Rules | `code-complete-routine-interface` judges the signature; this judges the body and the name. |
| `code-complete-routine-interface` | Parameter lists, flag arguments, unrelated parameters, return values that are hard to misuse | Routine Design Rules; Forbidden Patterns | It never judges the body; `code-complete-routine-design` never counts parameters. |
| `variables` | Variable names, scope, initialization, reuse, mutable locals | Variable and Data Rules; Review Rules | `code-complete-data-types` decides what a value is and means; this decides how long and where it lives. |
| `code-complete-data-types` | Types that resist invalid values, named constants, units, sentinels, booleans versus states, closed sets, container shapes | Data Type Rules; Variable and Data Rules | It owns value meaning and representation; `variables` owns lifetime. |
| `code-complete-control-flow` | Branch shape: nesting, compound conditions, guard clauses, switch use, dead branches, surprising exits | Control Flow Rules; Routine Design Rules (guard clauses only); Forbidden Patterns; Review Rules | `code-complete-statements-and-loops` covers loops and straight-line order; `code-complete-table-driven` replaces repeated mappings with data. |
| `code-complete-statements-and-loops` | Statement order and dependencies, positive conditions, normal-path placement, loop initialization, termination and update, loop bodies | Statement, Conditional, and Loop Rules; Control Flow Rules | It never discusses nesting depth or compound conditions (that is `code-complete-control-flow`). |
| `code-complete-table-driven` | Replace stable repeated branching with validated tables or maps; validate and test the table | Table-Driven and Data-Driven Rules; Statement, Conditional, and Loop Rules; Testing Rules | It applies only once a mapping is stable and repeated; `code-complete-control-flow` handles every other branch. |
| `code-complete-trust-boundaries` | What is validated, rejected, recovered from, asserted and kept diagnosable when input crosses a boundary | Defensive Programming Rules; Error Handling Rules; Forbidden Patterns; Testing Rules | It covers input from outside the code you control; `code-complete-assertions-and-contracts` covers assumptions between your own routines. |
| `code-complete-assertions-and-contracts` | Preconditions, postconditions, invariants; assertion versus validation versus domain error | Construction with Preconditions and Postconditions; Defensive Programming Rules; Testing Rules | It never validates external input; it decides how internal assumptions are stated and enforced. |
| `code-complete-error-handling` | Failure path: right abstraction level, context, consistency, normal path stays readable, no silent continue | Error Handling Rules; Defensive Programming Rules; Forbidden Patterns | It designs how an error travels and is reported; `code-complete-trust-boundaries` decides what counts as invalid on entry. |
| `code-complete-class-design` | Focused responsibility, cohesion, interface versus implementation, hidden representation, limited coupling | Class and Module Design Rules; Review Rules; Forbidden Patterns | It judges a class or module; `code-complete-routine-design` judges one routine. |
| `code-complete-complexity-management` | Complexity as defect risk: tangles, duplicated knowledge, cleverness, working-memory load, special-case growth | Complexity Management Rules; Foundational Construction Rules; Primary Directive; Forbidden Patterns; Review Rules | It is a smell-and-symptom skill across scopes; the other skills own the specific branch, routine, class or data fix. |
| `comments` | What a comment may say, deleting noise, keeping comments accurate, comments left after pseudocode | Comment Rules; Pseudocode Programming Process; Forbidden Patterns; Performance, Integration, Tools, and Craftsmanship (documentation) | It decides the text; `code-complete-coding-standards` decides the form. |
| `code-complete-coding-standards` | Consistency with the codebase, shared idioms, layout, no local dialects, formatter first | Coding Standards Rules; Foundational Construction Rules; Forbidden Patterns; Performance, Integration, Tools, and Craftsmanship (layout) | It compares new code with its neighbors; `comments` judges what the text says. |
| `debugging` | Reproduce, isolate, explain, fix the root cause, verify, add the regression test | Quality, Collaboration, Debugging, and Refactoring; Performance, Integration, Tools, and Craftsmanship (tools); Testing Rules | It starts from a failure with unknown cause; `code-complete-routine-testing` starts from a routine with no known failure. |
| `code-complete-routine-testing` | Normal, boundary and invalid cases, defensive-check tests, contract alignment, table-driven cases | Testing Rules; Defensive Programming Rules; Quality, Collaboration, Debugging, and Refactoring | It designs and judges tests; it never diagnoses a failure. |
| `code-complete-refactoring-judgment` | When structure justifies refactoring, tests or analysis first, refactoring kept apart from behavior change | Quality, Collaboration, Debugging, and Refactoring; Incremental Construction Rules; Complexity Management Rules; Consistency Neglect (arbitrary changes only) | It decides whether and how to restructure; `code-complete-complexity-management` detects the symptoms. |
| `code-complete-performance-tuning` | The gate for tuning: requirement and evidence first, measure before and after, clarity kept unless the trade-off is explicit | Performance, Integration, Tools, and Craftsmanship; Forbidden Patterns | It decides whether to tune and what counts as proof; `code-complete-tune` is the loop that does it. |

## Skills: manual workflows (10)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Review Checklist; Forbidden Patterns | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Repository or directory health scan across the clusters, ranked hot spots, at most 40 lines | Review Rules; Forbidden Patterns; Review Checklist; Testing Rules (normal, boundary and invalid inputs only) | `code-complete-trust-boundary-scan` inventories only boundaries; `audit` rates every cluster. |
| `plan` | no | no | Pre-construction plan: restated requirement, decision table, risks, increments, tests | Construction Prerequisites and Decisions; Incremental Construction Rules; Primary Directive; Testing Rules | `pseudocode` designs one routine; `plan` plans a whole change and never edits. |
| `code-complete-explain-rule` | no | no | Explain one rule: modal strength, reason, check, original example, exception | Purpose; Primary Directive; Final Instruction | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the ten review-checklist questions plus evidence items with yes, no or n/a and a next action | Review Checklist; Final Instruction | `code-complete-final-gate` is the isolated PASS or FAIL; `checklist` is the interactive walk with next actions. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Quality, Collaboration, Debugging, and Refactoring; Incremental Construction Rules; Code Generation Rules | The implementer agents take one cluster each; `fix` takes any finding list and routes to the owning skill. |
| `pseudocode` | no | yes | Pseudocode Programming Process for one complex routine: sketch, refine, convert, prune comments | Pseudocode Programming Process; Comment Rules; Code Generation Rules | `plan` plans the change; this designs one routine at a consistent abstraction level. |
| `code-complete-trust-boundary-scan` | yes | no | Inventory trust boundaries and how each handles validate, reject, recover, assert, diagnose; at most 40 lines | Defensive Programming Rules; Error Handling Rules; Forbidden Patterns | `code-complete-trust-boundary-reviewer` reviews boundaries in a diff; this finds them in a tree. |
| `code-complete-test-matrix` | no | no | Derive the normal, boundary, invalid and defensive-check cases for one routine from its contract as a table | Testing Rules; Construction with Preconditions and Postconditions; Table-Driven and Data-Driven Rules | `code-complete-test-writer` writes tests and `code-complete-test-case-reviewer` judges existing ones; this produces the case list before either. |
| `tune` | no | yes | Measured tuning loop: target, baseline, one change, remeasure, keep or revert, record the trade-off | Performance, Integration, Tools, and Craftsmanship | `code-complete-performance-tuning` decides whether to tune; this performs the loop and keeps the log. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, with `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `code-complete-lead` | opus | Routes a task or diff to specialists and skills; does not review | principles | Construction Prerequisites and Decisions; Review Checklist | Only agent that does not read code for defects. |
| `code-complete-final-gate` | sonnet | Runs the ten checklist questions and the five forbidden patterns on the working diff, PASS or FAIL | principles | Review Checklist; Forbidden Patterns; Final Instruction | Binary gate with evidence; reviewers return ranked findings. |
| `code-complete-increment-reviewer` | sonnet | Shape of the change: verifiable increment, refactoring mixed with behavior, partial work that is stranded or orphaned | construction-process, refactoring-judgment | Incremental Construction Rules; Quality, Collaboration, Debugging, and Refactoring | Output is a change-shape ledger; it is the only reviewer that compares hunks with each other. |
| `code-complete-routine-reviewer` | sonnet | Routine purpose, name, phases, hidden effects | routine-design | Routine Design Rules; Routine Bloat | Output is a routine ledger; `code-complete-interface-reviewer` owns signatures. |
| `code-complete-interface-reviewer` | sonnet | Parameter lists, flag arguments, return values | routine-interface | Routine Design Rules; Routine Bloat | Output is a signature ledger; never reads a routine body for structure. |
| `code-complete-data-reviewer` | sonnet | Variable lifetime and value meaning: scope, initialization, reuse, magic values, sentinels, units, flags | variables, data-types | Variable and Data Rules; Data Type Rules | Output is a decode list; it judges data, not control flow. |
| `code-complete-control-flow-reviewer` | sonnet | Nesting, conditions, exits, dead branches, loops, statement order | control-flow, statements-and-loops | Control Flow Rules; Statement, Conditional, and Loop Rules | Output is a branch-and-loop map; `code-complete-table-reviewer` takes repeated mappings. |
| `code-complete-table-reviewer` | sonnet | Repeated branching that is a table in disguise, and existing tables that are not validated | table-driven | Table-Driven and Data-Driven Rules | Output is a mapping inventory; it ignores branches that are not mappings. |
| `code-complete-trust-boundary-reviewer` | sonnet | Inputs crossing a boundary in the diff and how each is handled | trust-boundaries | Defensive Programming Rules; Defensive Vacuum; Testing Rules (test the defensive checks only) | Output is a boundary inventory; `code-complete-contract-reviewer` owns internal assumptions. |
| `code-complete-contract-reviewer` | sonnet | Preconditions, postconditions, invariants, and the assertion versus validation versus domain-error choice | assertions-and-contracts | Construction with Preconditions and Postconditions; Defensive Programming Rules | Output is an assumption ledger; never treats external input. |
| `code-complete-error-flow-reviewer` | sonnet | Failure paths: level, context, consistency, silent continuation | error-handling | Error Handling Rules; Defensive Vacuum | Output is a failure-path map; it does not decide what is valid input. |
| `code-complete-class-design-reviewer` | sonnet | Responsibility, cohesion, exposed representation, mixed concerns | class-design | Class and Module Design Rules | Output is a responsibility statement per class; `code-complete-routine-reviewer` stays inside routines. |
| `code-complete-complexity-reviewer` | sonnet | Tangles, duplicated knowledge, cleverness, special-case growth | complexity-management | Complexity Management Rules; Cleverness over Clarity | Output is a hot list ranked by what a reader must hold in mind. |
| `code-complete-comment-reviewer` | sonnet | Every comment gets a disposition: keep, rewrite, delete, replace with code | comments | Comment Rules; Comment-as-Crutch | Output is a comment ledger; form and layout are `code-complete-consistency-reviewer`'s. |
| `code-complete-consistency-reviewer` | sonnet | New code compared with its neighbors: naming, idioms, layout, file structure | coding-standards | Coding Standards Rules; Consistency Neglect | Output cites a neighboring file as evidence for every deviation. |
| `code-complete-test-case-reviewer` | sonnet | Existing tests mapped to the routine contract: normal, boundary, invalid, defensive | routine-testing | Testing Rules; Quality, Collaboration, Debugging, and Refactoring (risk-matched practices and tests around defects only) | Judges tests that exist; `code-complete-test-writer` creates them. |
| `code-complete-tuning-reviewer` | sonnet | Evidence behind a performance change: target, baseline, single change, remeasure, trade-off | performance-tuning | Performance, Integration, Tools, and Craftsmanship | Output is an evidence table; the only reviewer that asks for numbers. |
| `code-complete-construction-scanner` | haiku | Mechanical census: routine lengths, parameter counts, nesting, boolean parameters, literals, empty handlers, commented-out code | none | Review Rules | Reports numbers and locations only; makes no judgments. |
| `code-complete-refactorer` | sonnet | Behavior-preserving structural change in small steps against named findings | refactoring-judgment | Quality, Collaboration, Debugging, and Refactoring; Incremental Construction Rules | Structure only; `code-complete-bug-fixer` changes behavior to fix a defect. |
| `code-complete-test-writer` | sonnet | Writes tests from the contract: normal, boundary, invalid, defensive; edits test files only | routine-testing | Testing Rules; Quality, Collaboration, Debugging, and Refactoring (risk-matched practices and tests around defects only) | Writes tests only and never touches production code. |
| `code-complete-bug-fixer` | sonnet | Reproduce, isolate, explain, fix the root cause, add the regression test, verify | debugging | Quality, Collaboration, Debugging, and Refactoring | Only implementer that changes behavior to remove a reproduced failure; `code-complete-boundary-hardener` adds rejections only as findings require. |
| `code-complete-boundary-hardener` | sonnet | Adds boundary validation and assertions where review found a defensive gap | trust-boundaries, assertions-and-contracts | Defensive Programming Rules; Construction with Preconditions and Postconditions; Testing Rules (test the defensive checks only) | Adds checks only; it does not restructure or change business rules. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Primary Directive; Final Instruction | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Forbidden Patterns | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Incremental Construction Rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Primary Directive | Brevity rules. |
| `assumptions-first` | Before writing or changing code, lists inputs, boundaries and assumptions; afterwards shows how each is validated, asserted or tested | Defensive Programming Rules; Construction with Preconditions and Postconditions; Testing Rules | Defensive ledger precedes every change. |
| `evidence-first` | No cause, fix or speedup is claimed without an evidence line: reproduction, measurement or test output | Quality, Collaboration, Debugging, and Refactoring; Performance, Integration, Tools, and Craftsmanship | Reports are shaped by proof rather than by diagnosis of smells. |

## Confusable pairs

Model-invocable skills whose triggers could fire on the same request, and the clause that separates them. The clause is written into at least one of the two descriptions; the column says where. Pairs where one side's subject never overlaps the other's wording (a class versus one routine) carry it on the broader side only.

| Pair | Separated by | Clause in |
| --- | --- | --- |
| `code-complete-control-flow` / `code-complete-statements-and-loops` | Branch structure (nesting, compound conditions, exits) versus loops and the order of straight-line statements. | both |
| `code-complete-control-flow` / `code-complete-table-driven` | A branch problem in general versus a stable, repeated mapping that should become data. | both |
| `code-complete-routine-design` / `code-complete-routine-interface` | The body and the name versus the signature and the return value. | both |
| `code-complete-routine-interface` / `code-complete-data-types` | A boolean or primitive parameter (signature) versus a flag field, sentinel or unit inside data. | both |
| `variables` / `code-complete-data-types` | How long and where a value lives versus what the value is and means. | both |
| `code-complete-routine-design` / `code-complete-complexity-management` | One routine with mixed phases or hidden effects versus tangles, duplication and cleverness anywhere. | both |
| `code-complete-control-flow` / `code-complete-complexity-management` | A specific branch or exit problem versus general density, duplicated knowledge and clever expressions. | `code-complete-complexity-management` |
| `code-complete-trust-boundaries` / `code-complete-assertions-and-contracts` | Input from outside what you control versus assumptions between your own routines. | both |
| `code-complete-trust-boundaries` / `code-complete-error-handling` | What counts as invalid on entry versus how a failure is propagated and reported. | both |
| `code-complete-assertions-and-contracts` / `code-complete-error-handling` | Programmer errors (fail fast) versus failures the program is expected to handle. | both |
| `debugging` / `code-complete-error-handling` | A failure whose cause is unknown (reproduce, isolate, explain) versus how a known failure is propagated, wrapped and reported. "This throws an exception, why?" is `debugging`; "how should this catch block report it?" is `code-complete-error-handling`. | both |
| `code-complete-class-design` / `code-complete-routine-design` | A class or module versus one routine. | `code-complete-class-design` |
| `comments` / `code-complete-coding-standards` | What a comment says versus how code is formatted, named and arranged. | both |
| `debugging` / `code-complete-routine-testing` | A failure with unknown cause versus designing tests for a routine with no known failure. | both |
| `code-complete-refactoring-judgment` / `code-complete-complexity-management` | Whether and how to change structure safely versus detecting what is too complex. | both |
| `code-complete-refactoring-judgment` / `code-complete-performance-tuning` | A structure motive with no speed goal versus a speed motive with measurements. | both |
| `code-complete-performance-tuning` / `code-complete-complexity-management` | A speed motive with measurements versus a readability motive. | `code-complete-performance-tuning` |
| `code-complete-construction-process` / `principles` | Ordering the work for a large change versus the always-relevant hub, which defers to a matching topical skill. | `principles` |

Manual pairs: `review` / `audit` (a change versus a tree), `checklist` / `code-complete-final-gate` (interactive walk with next actions versus isolated PASS or FAIL with evidence), `plan` / `pseudocode` (a change versus one routine), `plan` / `code-complete-construction-process` (the manual planning workflow that produces a written plan versus the model-invocable rules for what must be settled and how to order the work; `code-complete-construction-process` names `code-complete-plan` in its description), `code-complete-test-matrix` / `code-complete-test-writer` (case list versus written tests), `tune` / `code-complete-tuning-reviewer` (does the loop versus audits the evidence), `fix` / the four implementers (any finding list versus one cluster each).

Maintenance: two skill and agent pairs restate one procedure on purpose, because an agent must be self-contained and cannot rely on its preloaded skill being present: `debugging` / `code-complete-bug-fixer` (reproduce, isolate, explain, fix, verify) and `code-complete-routine-testing` / `code-complete-test-writer` (contract, case classes, boundary set). Change both copies in the same edit. `code-complete-performance-tuning` / `tune` / `code-complete-tuning-reviewer` share the measurement loop in the same way.

## Coverage check against the upstream sections

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | principles, explain-rule |
| Primary Directive | principles, construction-process, complexity-management, plan, explain-rule, mentor, terse |
| Foundational Construction Rules | principles, complexity-management, coding-standards |
| Construction Prerequisites and Decisions | construction-process, plan, lead |
| Pseudocode Programming Process | pseudocode, comments |
| Routine Design Rules | routine-design, routine-interface, code-complete-routine-reviewer, code-complete-interface-reviewer |
| Variable and Data Rules | variables, data-types, code-complete-data-reviewer |
| Data Type Rules | data-types, code-complete-data-reviewer |
| Control Flow Rules | control-flow, statements-and-loops, code-complete-control-flow-reviewer |
| Statement, Conditional, and Loop Rules | statements-and-loops, table-driven, code-complete-control-flow-reviewer |
| Defensive Programming Rules | trust-boundaries, assertions-and-contracts, error-handling, trust-boundary-scan, code-complete-trust-boundary-reviewer, code-complete-contract-reviewer, code-complete-boundary-hardener, assumptions-first |
| Error Handling Rules | error-handling, trust-boundaries, trust-boundary-scan, code-complete-error-flow-reviewer |
| Table-Driven and Data-Driven Rules | table-driven, code-complete-table-reviewer, test-matrix |
| Class and Module Design Rules | class-design, code-complete-class-design-reviewer |
| Complexity Management Rules | complexity-management, refactoring-judgment, code-complete-complexity-reviewer |
| Construction with Preconditions and Postconditions | assertions-and-contracts, code-complete-contract-reviewer, test-matrix, code-complete-boundary-hardener, assumptions-first |
| Comment Rules | comments, pseudocode, code-complete-comment-reviewer |
| Coding Standards Rules | coding-standards, code-complete-consistency-reviewer |
| Incremental Construction Rules | construction-process, refactoring-judgment, plan, fix, code-complete-increment-reviewer, refactorer, pair |
| Quality, Collaboration, Debugging, and Refactoring | debugging, routine-testing, refactoring-judgment, fix, code-complete-increment-reviewer, refactorer, code-complete-bug-fixer, code-complete-test-writer, code-complete-test-case-reviewer, evidence-first |
| Performance, Integration, Tools, and Craftsmanship | performance-tuning, tune, code-complete-tuning-reviewer, construction-process, comments, coding-standards, debugging, evidence-first |
| Review Rules | review, audit, strict-reviewer, code-complete-construction-scanner, routine-design, variables, control-flow, class-design, complexity-management |
| Forbidden Patterns | review, audit, code-complete-final-gate, strict-reviewer, trust-boundary-scan, and the owner skills in the table above |
| Code Generation Rules | principles, pseudocode, fix |
| Testing Rules | routine-testing, test-matrix, code-complete-test-case-reviewer, code-complete-test-writer, table-driven, trust-boundaries, assertions-and-contracts, debugging, audit, code-complete-trust-boundary-reviewer, code-complete-boundary-hardener, assumptions-first |
| Review Checklist | principles, review, audit, checklist, code-complete-final-gate, lead |
| Final Instruction | principles, explain-rule, checklist, code-complete-final-gate, mentor |

## Overlap review

Pairs that were close and how they were separated:

- `code-complete-routine-design` and `code-complete-routine-interface`: the first never counts parameters or inspects return types; the second never talks about phases, length or hidden effects in the body. Boolean parameters are owned by `code-complete-routine-interface`; boolean fields and status flags by `code-complete-data-types`.
- `variables` and `code-complete-data-types`: lifetime and scope versus meaning and representation. Magic numbers and sentinels belong to `code-complete-data-types` only; `variables` points there.
- `code-complete-control-flow` and `code-complete-statements-and-loops`: compound conditions, nesting, exits and guard clauses versus loops, statement order and condition polarity. A negated single condition belongs to `code-complete-statements-and-loops`; a compound condition to `code-complete-control-flow`.
- `code-complete-trust-boundaries`, `code-complete-assertions-and-contracts` and `code-complete-error-handling`: the first decides what is acceptable on entry, the second how assumptions inside your code are written and enforced, the third how a failure travels. A validation failure is raised by `code-complete-trust-boundaries` and reported by `code-complete-error-handling`.
- `debugging` and `code-complete-bug-fixer`: the skill holds the rules, the agent performs the sequence and edits. The agent restates the sequence because it must be self-contained and adds implementer steps (test command, baseline, cleanup); when you change the steps in one, change the other.
- `code-complete-performance-tuning`, `tune` and `code-complete-tuning-reviewer`: policy, loop and audit of the evidence. The skill's Procedure keeps the gate steps and states the loop once; the model cannot invoke the manual `tune` itself, so the loop stays in the skill's rules.
- `review`, `code-complete-lead`, `code-complete-final-gate`: `review` produces findings, `code-complete-lead` only decides who should, `code-complete-final-gate` returns a verdict.
- `code-complete-refactorer` and `fix`: `fix` takes any finding list and uses the owning skill's procedure; `code-complete-refactorer` is the delegated agent that only restructures.
- `code-complete-test-matrix`, `code-complete-test-writer`, `code-complete-test-case-reviewer`: case list, written tests, and review of existing tests. `code-complete-routine-testing` holds the rules; `code-complete-test-writer` repeats its case classes inside a self-contained process, so keep the two in step.

Upstream sections without a dedicated skill: `Review Checklist`, `Final Instruction`, `Purpose` and `Code Generation Rules` govern how work is judged and started rather than how one kind of code is shaped; they are applied by the hub, the checklist, the gate and the styles.
