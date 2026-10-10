# Refactoring plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` and `###` headings of `skills/principles/references/full.md`; the validator checks coverage against the twenty `##` headings.

## Design decisions

1. **The upstream rule set is small but catalog-heavy.** Its policy sections (Non-Negotiable Rules, Safety Rules, Forbidden Patterns, Stopping Rules) fit a handful of skills. Its bulk is the eleven-smell policy and the five-group Refactoring Catalog Index with roughly seventy named moves. The plugin therefore separates **process** skills (behavior, step size, safety net, preparation, patch shape, stopping) from **smell-and-move** skills (one per smell family, each owning the catalog entries that treat it).
2. **Every smell and every catalog entry has exactly one owning skill** (tables below). Other skills point to the owner instead of restating it.
3. **Restraint is part of the rule set, not an add-on.** The source says "do not abstract coincidental similarity", "never introduce polymorphism merely to avoid a small local conditional", "do not introduce interfaces before a second real need". Each smell skill therefore carries a "leave it alone" branch, and `friction-reviewer` and `stopping-rules` exist to apply it.
4. **Model-invocable skills are at the cap of 20.** All of them are rule clusters with disjoint triggers (see Confusable pairs). Everything that is a procedure with arguments is a manual skill.
5. **Reviewers own one concern and have their own output shape**: a behavior-delta ledger, an intent ledger, a coverage map, a duplication cluster table, a placement ledger, a branch inventory, an abstraction evidence table, and so on. No two reviewers print the same table.
6. **Rules that are not in `references/full.md` are labelled.** Rules that exist only in `mini.md` or `nano.md` carry "compact checklist". Mechanics, thresholds and traps that this plugin adds carry "Added judgment". The catalog index gives only a trigger per move ("USE X when Y"); the step-by-step mechanics in the skills are Added judgment.
7. **The two-hats habit is used as a mode, with its provenance stated.** The hat metaphor is the book's; the upstream file expresses only the separation ("separate structural edits from behavior changes"). The `two-hats` output style makes it observable, and its `[STRUCTURE]` and `[BEHAVIOR]` tags are Added judgment. Writing the test first for a behavior step is also Added judgment: the upstream order says only "implement the behavioral change".

## Smell ownership

Every item of `Code Smell Policy` has one owning skill.

| Smell (upstream heading) | Owner skill | Also touches |
| --- | --- | --- |
| Duplicated Code | `duplication` | `needless-abstraction` (when the shared code is unclear) |
| Long Functions | `function-bodies` | `hidden-dependencies` (side effects) |
| Long Parameter Lists | `call-signatures` | `primitive-obsession` (clumps that deserve a type) |
| Global Data and Hidden Dependencies | `hidden-dependencies` | `mutation-control` (who writes shared state) |
| Divergent Change | `ownership` | |
| Shotgun Surgery | `ownership` | `duplication` (the same edit repeated) |
| Feature Envy | `ownership` | |
| Data Clumps and Primitive Obsession | `primitive-obsession` | `call-signatures` |
| Switch Statements and Conditionals | `conditionals` (local branching), `variation-and-state` (branching repeated by type) | |
| Temporary Fields and Weird Lifecycles | `variation-and-state` | |
| Middle Man and Speculative Generality | `needless-abstraction` | `inheritance-moves` (unused hierarchy) |

## Catalog ownership

Every entry of `Refactoring Catalog Index` has one owning skill.

| Catalog group | Entries | Owner |
| --- | --- | --- |
| Composing Methods | Extract Method, Inline Method, Inline Temp, Replace Temp with Query, Introduce Explaining Variable, Split Temporary Variable, Remove Assignments to Parameters, Replace Method with Method Object, Substitute Algorithm | `function-bodies` |
| Moving Features | Move Method or Field, Extract Class, Hide Delegate, Introduce Foreign Method, Introduce Local Extension | `ownership` |
| Moving Features | Inline Class, Remove Middle Man | `needless-abstraction` |
| Organizing Data | Replace Data Value with Object, Change Value to Reference, Change Reference to Value, Replace Array with Object, Replace Record with Data Class | `primitive-obsession` |
| Organizing Data | Self Encapsulate Field, Encapsulate Collection, Duplicate Observed Data, both association-direction changes | `mutation-control` |
| Organizing Data | Replace Type Code with Class, Subclasses, or State/Strategy; Replace Subclass with Fields | `variation-and-state` |
| Simplifying Calls and Conditionals | Decompose Conditional, Consolidate Conditional Expression, Consolidate Duplicate Conditional Fragments, Remove Control Flag, Replace Nested Conditional with Guard Clauses, Introduce Assertion | `conditionals` |
| Simplifying Calls and Conditionals | Replace Conditional with Polymorphism, Introduce Null Object, Replace Constructor with Factory Method, Encapsulate Downcast | `variation-and-state` |
| Simplifying Calls and Conditionals | Add Parameter, Remove Parameter, Parameterize Method, Replace Parameter with Explicit Methods, Preserve Whole Object, Replace Parameter with Method | `call-signatures` |
| Simplifying Calls and Conditionals | Rename Method | `renaming` |
| Simplifying Calls and Conditionals | Remove Setting Method, Hide Method | `mutation-control` |
| Simplifying Calls and Conditionals | Replace Error Code with Exception, Replace Exception with Test | `error-paths` |
| Generalization and Big Refactorings | Pull Up, Push Down, Extract Subclass, Extract Superclass, Extract Interface, Collapse Hierarchy, Form Template Method, both inheritance/delegation replacements, Tease Apart Inheritance, Extract Hierarchy | `inheritance-moves` |
| Generalization and Big Refactorings | Convert Procedural Design to Objects, Separate Domain from Presentation | `ownership` |

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; What Counts as Refactoring; Non-Negotiable Rules; Code Generation Rules; Stopping Rules; Review Checklist; Final Instruction; the other sections appear only as routing-table pointers | It decides which component to use; it holds no cluster rules itself. |
| `behavior-preservation` | Decide whether a change is a refactoring: what counts as observable, how to isolate behavior change, equivalence traps | What Counts as Refactoring; Non-Negotiable Rules; Purpose | `small-steps` sizes and orders steps; this one classifies a change and polices its meaning. |
| `small-steps` | Step size, reversibility, runnable states, the default order of work, recovering control from a rewrite urge | Primary Directive; Non-Negotiable Rules; Big-Bang Rewrite; Code Generation Rules; Final Instruction | `preparatory-steps` is the one moment before a feature; this is the general discipline and the rewrite brake. |
| `safety-net` | Get a safety net, characterize unclear behavior, keep tests honest while refactoring | Tests and Verification; Testing Rules; Untested Structural Surgery | `behavior-preservation` is about meaning; this is about the tests that prove it. |
| `preparatory-steps` | Ask what makes a change awkward, reshape locally first, make the change, clean up what it introduced | Preparatory Refactoring; Primary Directive; Non-Negotiable Rules; Code Generation Rules | It is bound to a feature or bug fix about to be written; `small-steps` is not. |
| `patch-hygiene` | Shape the diff or commit series: one intent per patch, moves separate from edits | Commit and Patch Discipline; Mixed-Intent Patches | `behavior-preservation` judges semantics; this judges how the change is packaged for review. |
| `stopping-rules` | When to stop, and how to spot refactoring theater | Stopping Rules; Refactoring Theater; Non-Negotiable Rules; Review Checklist | `needless-abstraction` removes existing layers; this decides whether to keep working at all. |
| `duplication` | Remove duplicated knowledge by ownership, refuse coincidental similarity and `utils` dumping grounds | Duplicated Code; Class and Module Rules; Abstracting Too Early | It merges copies; `needless-abstraction` removes layers. They pull in opposite directions and share the evidence test. |
| `function-bodies` | Where to cut a long function; moves inside a body (temporaries, expressions, method object, algorithm) | Long Functions; Function-Level Rules; Composing Methods; Extraction Refactorings | `call-signatures` judges the boundary; this judges the inside. |
| `call-signatures` | Parameter lists, flags, argument order, signature moves | Long Parameter Lists; Simplifying Calls and Conditionals; Data Refactorings | It changes how a call looks; `primitive-obsession` changes what types exist. |
| `hidden-dependencies` | Globals, singletons, ambient context, hidden inputs and side effects made explicit | Global Data and Hidden Dependencies; Function-Level Rules; Review Rules | It is about what code reads; `mutation-control` is about what code lets others write. |
| `ownership` | Divergent change, shotgun surgery, feature envy, moves between classes and modules, policy versus presentation | Divergent Change; Shotgun Surgery; Feature Envy; Movement Refactorings; Moving Features; Class and Module Rules; Generalization and Big Refactorings | It places behavior among peers; `inheritance-moves` restructures a hierarchy. |
| `primitive-obsession` | Replace clumps and loaded primitives with named, validated types; value versus reference | Data Clumps and Primitive Obsession; Data Refactorings; Organizing Data | It introduces types; `call-signatures` only reshapes calls. |
| `mutation-control` | Encapsulate state, narrow write access, collections, setters, association direction | Data and Mutation Rules; Data Refactorings; Organizing Data; Simplifying Calls and Conditionals | It controls writes and exposure; `hidden-dependencies` controls reads of ambient state. |
| `conditionals` | Guard clauses, decomposition, consolidation, lookup tables, restraint | Rules for Working with Conditionals; Switch Statements and Conditionals; Simplification Refactorings; Simplifying Calls and Conditionals | Local branching structure; `variation-and-state` handles branching repeated by kind. |
| `variation-and-state` | Type codes, state and strategy, null objects, factories, temporary fields and half-initialized objects | Switch Statements and Conditionals; Temporary Fields and Weird Lifecycles; Organizing Data; Simplifying Calls and Conditionals | It is about variation across the code base and across an object's life. |
| `needless-abstraction` | Middle men, speculative generality, one-user libraries, dead code, inlining | Middle Man and Speculative Generality; Abstracting Too Early; Class and Module Rules; Simplification Refactorings; Moving Features | It removes weight that exists; `stopping-rules` stops new weight being added by cleanup itself. |
| `inheritance-moves` | Pull up, push down, delegation versus inheritance, collapse, tease apart | Generalization and Big Refactorings; Class and Module Rules | Hierarchy mechanics only; layers and interfaces are `needless-abstraction`. |
| `error-paths` | Reveal the main path while keeping error semantics | Error Handling Rules; Simplifying Calls and Conditionals | It is the only skill about what failures mean; `conditionals` is about branching in general. |
| `renaming` | Safe renames and how far to take them | Naming Refactorings; Preferred Refactoring Moves; What Counts as Refactoring; Mixed-Intent Patches | It owns names; no other skill rewrites identifiers. |

## Skills: manual workflows (10)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff against the rules and report ranked findings, starting with the intent of the change | Review Rules; Review Checklist; Forbidden Patterns | `audit` scans a tree for friction; `review` judges a change. |
| `audit` | yes | no | Refactoring readiness and friction map of a directory: churn, safety net, review-rule probes, at most 40 lines | Review Rules; Code Smell Policy; Forbidden Patterns; Tests and Verification | `smell-to-refactoring` is symptom to treatment; `audit` is where change is expensive and whether it is safe to touch. |
| `plan` | no | no | Plan a change in the source's default order with prep, change, follow-up and stop condition | Code Generation Rules; Primary Directive; Preparatory Refactoring; Stopping Rules | `prepare` executes the prep part of a plan; `plan` only plans. |
| `explain-rule` | no | no | Explain one rule, smell or catalog move: strength, reason, check, example, exceptions | Purpose; Non-Negotiable Rules; Refactoring Catalog Index | The only manual skill that teaches instead of reporting or editing. |
| `checklist` | no | no | Interactive walk of the final checklist with a next action for each no | Review Checklist; Final Instruction | `final-gate` is the isolated strict gate; `checklist` runs in the session with next actions. |
| `fix` | no | yes | Resolve given findings with the smallest named move, tests after each, never commit | Code Generation Rules; Non-Negotiable Rules; Safety Rules; Stopping Rules | `prepare` picks its own targets from a requested change; `fix` only resolves given findings. |
| `smell-to-refactoring` | yes | no | Map smells in a scope to the smallest named move, its precondition, its safety net and its stop condition, at most 40 lines | Code Smell Policy; Refactoring Catalog Index; Preferred Refactoring Moves | `audit` rates areas; this converts each confirmed smell into a treatment. |
| `characterize` | no | yes (tests only) | Pin the current behavior of unclear code with characterization tests before refactoring | Tests and Verification; Testing Rules; Untested Structural Surgery | `safety-net` is the rule set; this is the procedure that writes the tests. |
| `split-patch` | no | no | Turn a mixed diff into an ordered sequence of single-intent patches the user can apply | Commit and Patch Discipline; Mixed-Intent Patches | `patch-intent-reviewer` returns a verdict on one patch; this returns the plan to split it. |
| `prepare` | no | yes | Do only the preparatory refactoring for a stated change, in at most five verified steps, then hand back | Preparatory Refactoring; Code Generation Rules; Stopping Rules | It stops before the behavior change; `fix` needs findings and `plan` does not edit. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Primary Directive; Code Generation Rules; Stopping Rules | Only agent that never reads code for defects. |
| `final-gate` | sonnet | Runs the final checklist and the five forbidden patterns on the working diff and returns PASS or FAIL | principles | Review Checklist; Final Instruction; Forbidden Patterns | Binary gate with evidence; reviewers return ranked findings. |
| `behavior-preservation-reviewer` | sonnet | Behavior-delta ledger for a change claimed to preserve behavior | behavior-preservation | What Counts as Refactoring; Non-Negotiable Rules | Judges meaning unit by unit; `patch-intent-reviewer` judges packaging. |
| `patch-intent-reviewer` | sonnet | Intent ledger per hunk and a mixed-intent verdict | patch-hygiene | Commit and Patch Discipline; Mixed-Intent Patches | Classifies hunks; does not decide whether behavior changed. |
| `safety-net-reviewer` | sonnet | Coverage map from touched behavior to tests | safety-net | Tests and Verification; Untested Structural Surgery | Looks for tests that are missing; `test-change-reviewer` looks at tests that changed. |
| `test-change-reviewer` | sonnet | Ledger of every added, edited, skipped or deleted test | safety-net | Testing Rules; Tests and Verification | Judges test edits against preserved behavior. |
| `friction-reviewer` | sonnet | Friction ledger and stop-rule verdict: did the change remove a real source of friction | stopping-rules, preparatory-steps | Stopping Rules; Refactoring Theater; Review Checklist | The only reviewer that compares the result with the requested change's cost. |
| `duplication-reviewer` | sonnet | Duplication cluster table: same knowledge or coincidence | duplication | Duplicated Code; Class and Module Rules | Merges copies; `abstraction-reviewer` judges layers. |
| `function-reviewer` | sonnet | Function table with cut points, levels, phases, side effects | function-bodies | Long Functions; Function-Level Rules; Composing Methods | Judges bodies; `signature-reviewer` judges the boundary. |
| `signature-reviewer` | sonnet | Signature ledger: parameters, flags, order, reassignment | call-signatures | Long Parameter Lists; Simplifying Calls and Conditionals | Judges the call shape only. |
| `dependency-reviewer` | sonnet | Inventory of hidden inputs and ambient reads | hidden-dependencies | Global Data and Hidden Dependencies; Function-Level Rules | Reads of ambient state; `mutation-reviewer` covers writes. |
| `ownership-reviewer` | sonnet | Placement ledger: reasons to change, envied owner, ripple count | ownership | Divergent Change; Shotgun Surgery; Feature Envy; Class and Module Rules | Judges where behavior lives; `hierarchy-reviewer` judges inheritance. |
| `primitive-reviewer` | sonnet | Concept table: recurring primitive bundles and the type they imply | primitive-obsession | Data Clumps and Primitive Obsession; Data Refactorings | Finds missing types; `mutation-reviewer` finds exposed state. |
| `mutation-reviewer` | sonnet | Mutation surface list: fields and collections, their writers, how to narrow | mutation-control | Data and Mutation Rules; Organizing Data | Writes and exposure only. |
| `conditional-reviewer` | sonnet | Branch inventory with a proportionate treatment, including leave-as-is | conditionals, variation-and-state | Rules for Working with Conditionals; Switch Statements and Conditionals; Temporary Fields and Weird Lifecycles | The only reviewer that can answer "this conditional is fine". |
| `abstraction-reviewer` | sonnet | Evidence table for each abstraction: what it hides, variants, callers, keep or inline | needless-abstraction | Middle Man and Speculative Generality; Abstracting Too Early | Judges existing abstractions one by one. |
| `error-path-reviewer` | sonnet | Error-semantics equivalence table, before and after | error-paths | Error Handling Rules | Compares failure behavior; no other reviewer does. |
| `hierarchy-reviewer` | sonnet | Hierarchy map with the move each smell suggests | inheritance-moves | Generalization and Big Refactorings | Classes in an inheritance tree only. |
| `refactorer` | sonnet | Applies a list of findings or a plan as named moves, tests between | small-steps, safety-net | Code Generation Rules; Non-Negotiable Rules; Safety Rules | General worker; the three below are specialists for multi-step moves. |
| `class-splitter` | sonnet | Splits one class that changes for several reasons, in verified steps | ownership | Divergent Change; Movement Refactorings; Class and Module Rules | One class in, several cohesive classes out. |
| `conditional-refactorer` | sonnet | Replaces repeated type-based branching with a table, strategy or polymorphism, only when justified | conditionals, variation-and-state | Rules for Working with Conditionals; Switch Statements and Conditionals | It also reverses over-engineering; `refactorer` does not choose between variation mechanisms. |
| `value-type-introducer` | sonnet | Introduces one named, validated type for a primitive clump and threads it inward | primitive-obsession | Data Clumps and Primitive Obsession; Data Refactorings | One concept per run; keeps existing validation behavior. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Purpose; Final Instruction | Teaching is the goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Checklist; Review Rules | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Primary Directive; Non-Negotiable Rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output in full | Final Instruction | Brevity rules. |
| `two-hats` | Tags every edit as structure or behavior, never both in one step, announces each switch | Non-Negotiable Rules; Commit and Patch Discipline | Per-edit labeling; `prep-first` orders whole tasks. |
| `prep-first` | Every change task runs friction, safety net, preparation, change, follow-up, stop reason in that order | Code Generation Rules; Preparatory Refactoring; Stopping Rules | Per-task sequence; `two-hats` labels single edits. |

## Confusable pairs

Model-invocable skills whose triggers could fire on the same request, and the clause that separates them. The clause is written into the description of at least one skill of each pair (both, where the 300-character budget allows) and into the opening paragraph of both.

| Pair | Discriminator |
| --- | --- |
| `behavior-preservation` / `small-steps` | Classifying a change as refactoring and defining observable behavior, versus sizing and ordering steps and braking a rewrite. |
| `behavior-preservation` / `safety-net` | Meaning of the change, versus the tests that prove it. |
| `behavior-preservation` / `patch-hygiene` | Whether behavior changed, versus how the change is packaged. |
| `small-steps` / `preparatory-steps` | General step discipline, versus the moment before implementing a specific feature or bug fix. |
| `small-steps` / `stopping-rules` | How to proceed, versus when to end. |
| `stopping-rules` / `needless-abstraction` | Whether more cleanup is justified, versus which existing layers to remove. |
| `duplication` / `needless-abstraction` | Merging copies into one owner, versus inlining a layer or interface. |
| `function-bodies` / `call-signatures` | Inside the function, versus its parameters and call sites. |
| `function-bodies` / `conditionals` | Where to cut a function, versus the shape of the branching in it. |
| `hidden-dependencies` / `mutation-control` | What code reads from outside its signature, versus what other code may write or reach. |
| `ownership` / `primitive-obsession` | Which class or module owns behavior, versus which types exist. |
| `ownership` / `inheritance-moves` | Placement among collaborators, versus inheritance mechanics. |
| `needless-abstraction` / `inheritance-moves` | Layers, forwarding classes and interfaces, versus hierarchies. |
| `inheritance-moves` / `variation-and-state` | Reshaping a hierarchy that exists (pull up, push down, collapse, delegation, tease apart), versus modeling variation that is not yet modeled, including subclasses that override only constants (Replace Subclass with Fields). |
| `ownership` / `needless-abstraction` | Hide Delegate (clients know too much about a collaborator), versus Remove Middle Man (a forwarder hides nothing); `needless-abstraction` rule 12 only points back to `ownership` for the Hide Delegate side. |
| `duplication` / `function-bodies` | Merging copies of the same knowledge into one owner, versus cutting one long function at its seams; both may end in Extract Method, for different reasons. |
| `conditionals` / `variation-and-state` | One local branch structure, versus the same kind-based branching repeated, or fields that exist only on some paths. |
| `error-paths` / `conditionals` | Failure branches and their meaning, versus branching in general. |
| `primitive-obsession` / `call-signatures` | A type with rules, versus the shape of a call. |

Manual skills and agents that sit close to each other, and how they differ.

| Pair | Discriminator |
| --- | --- |
| `review` / `audit` / `smell-to-refactoring` | A change, versus a tree's readiness and friction, versus smell-to-move conversion. |
| `checklist` / `final-gate` | Interactive walk with next actions, versus isolated strict PASS or FAIL. |
| `review` / `final-gate` / `strict-reviewer` | All three check a diff against the forbidden patterns. `review` is a command that returns ranked findings on demand, each with a fix; `final-gate` is an isolated agent that returns one binary PASS or FAIL with evidence per checklist item; `strict-reviewer` is a session-wide output style that makes every answer a ranked findings table and launches nothing by itself. |
| `fix` / `refactorer` | In-session command that resolves findings, versus delegated worker for a longer list. |
| `plan` / `prepare` | Plan only, versus doing the preparatory steps. |
| `plan` / `lead` | Both name an ordered sequence. `plan` is a command that sequences the work for one change (friction, safety net, preparatory steps, the behavior change, follow-up, stop condition) and edits nothing; `lead` is a read-only agent that chooses which specialists and skills to run, in what order and in at most five steps, and does not plan the work itself. |
| `plan` / `prep-first` | One-shot plan of the sequence (friction, net, preparation, change, follow-up, stop) that edits nothing, versus a session mode that runs that sequence on every change task and reports each stage. |
| `split-patch` / `patch-intent-reviewer` | Plan to split, versus verdict on one patch. |
| `characterize` / `safety-net-reviewer` | Writes tests, versus maps coverage and writes nothing. |
| `conditional-refactorer` / `conditional-reviewer` | Edits, versus read-only inventory. |

## Coverage check against the upstream sections

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | principles, behavior-preservation, explain-rule, mentor |
| Primary Directive | principles, small-steps, preparatory-steps, plan, lead, pair |
| What Counts as Refactoring | behavior-preservation, renaming, behavior-preservation-reviewer |
| Non-Negotiable Rules | behavior-preservation, small-steps, preparatory-steps, stopping-rules, explain-rule, fix, refactorer, pair, two-hats |
| Safety Rules | fix, refactorer; its three `###` subsections are cited directly by safety-net, patch-hygiene, preparatory-steps and their reviewers and workflows |
| Code Smell Policy | audit, smell-to-refactoring, and every smell skill via its subsection |
| Preferred Refactoring Moves | renaming, smell-to-refactoring, conditionals, mutation-control, primitive-obsession |
| Refactoring Catalog Index | explain-rule, smell-to-refactoring, and every move skill |
| Function-Level Rules | function-bodies, hidden-dependencies, function-reviewer, dependency-reviewer |
| Class and Module Rules | ownership, duplication, needless-abstraction, inheritance-moves, class-splitter |
| Rules for Working with Conditionals | conditionals, conditional-reviewer, conditional-refactorer |
| Data and Mutation Rules | mutation-control, mutation-reviewer |
| Error Handling Rules | error-paths, error-path-reviewer |
| Review Rules | review, audit, hidden-dependencies, duplication, dependency-reviewer, strict-reviewer |
| Forbidden Patterns | review, audit, final-gate, strict-reviewer, small-steps (Big-Bang Rewrite), patch-hygiene (Mixed-Intent Patches), duplication and needless-abstraction (Abstracting Too Early), stopping-rules (Refactoring Theater), safety-net (Untested Structural Surgery) |
| Code Generation Rules | small-steps, preparatory-steps, plan, prepare, fix, refactorer, lead, prep-first |
| Testing Rules | safety-net, characterize, test-change-reviewer |
| Stopping Rules | stopping-rules, friction-reviewer, plan, prepare, fix, lead, pair, prep-first |
| Review Checklist | principles, stopping-rules, review, checklist, final-gate, friction-reviewer, strict-reviewer |
| Final Instruction | principles, small-steps, checklist, final-gate, terse, mentor |

## Overlap review

Pairs that were close and how they were separated:

- `behavior-preservation`, `small-steps` and `patch-hygiene` are three views of the same discipline. The first never talks about step size or commits, the second never defines observable behavior, the third never decides whether behavior changed.
- `safety-net` owns the tests; `behavior-preservation` owns the claim. `characterize` is the only procedure that writes tests, and it never touches production code.
- `duplication` and `needless-abstraction` pull in opposite directions on purpose. Both end with an evidence question (do the copies change for the same reason; does the abstraction hide anything and have more than one real variant, where callers are counted only to size the work), and each applies it to a different action (merge versus inline).
- `function-bodies` is deliberately wide (a smell, a rule section and a catalog group). It stays one skill because the cut decision and the in-body moves are made in one sitting; `conditionals` takes over as soon as the question is about branching.
- `conditionals` and `variation-and-state` split the source's one smell heading at the seam the source itself draws: "a single honest conditional" versus "repeated branching on type or mode".
- `fix`, `prepare` and `plan` form a sequence: `plan` plans, `prepare` does the preparatory part, `fix` resolves findings afterwards. `refactorer` is the delegated version of `fix`.
- `friction-reviewer` and `abstraction-reviewer`: the first measures the whole change against the cost of the requested change; the second inspects individual abstractions for evidence of need.
- `final-gate` and `checklist` use the same list on purpose; they differ in isolation and in output (verdict versus next actions).
- `review`, `final-gate` and `strict-reviewer` all apply the forbidden patterns to a diff, so each is bound to a different job. `review` is the on-demand command for ranked, fixable findings; `final-gate` is the isolated verdict that cannot be argued into a pass; `strict-reviewer` is the output format that a whole session answers in. None of them edits files.
- `plan` and `lead` both produce an ordered list. The list from `plan` is the work (what to prepare, change and clean up, and when to stop); the list from `lead` is the team (which reviewers, skills and implementer to run). `lead` adds only a one-line friction and stop condition and never writes the steps of the change; `plan` points at skills for the rules of each step and never schedules reviewers.
- `plan` and `prep-first` describe the same sequence on purpose: `plan` is a one-shot command that prints the sequence for one change and edits nothing; `prep-first` is a session mode that runs and reports the sequence on every change task.
- `ownership` and `needless-abstraction` meet at one trade-off, Hide Delegate (clients know too much about a collaborator) versus Remove Middle Man (the forwarder hides nothing). The catalog table gives Hide Delegate to `ownership` and Remove Middle Man to `needless-abstraction`; rule 12 of `needless-abstraction` only decides when forwarding has stopped paying and points back to `ownership` for Hide Delegate.
- `inheritance-moves` and `variation-and-state` meet at subclasses. Reshaping a hierarchy that exists is `inheritance-moves`; subclasses that override only constants (Replace Subclass with Fields) and the choice among type code, subclasses, state and strategy are `variation-and-state`, and the descriptions of both say so.
- `duplication` and `function-bodies` can both end in Extract Method. The first starts from two or more copies of the same knowledge and merges them under one owner; the second starts from one long function and cuts it at its seams.
