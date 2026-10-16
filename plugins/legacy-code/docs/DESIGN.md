# Working Effectively with Legacy Code plugin: component map

This file is the plan the components were built from, kept in step with what was built. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`; `###` headings are cited where a component owns exactly one subsection. A `Source` bullet with a note means only that part of the section applies.

## Design decisions

1. **The rule set is a loop plus a catalog of obstacles, so the split follows the obstacle a developer meets.** The upstream full file has 18 `##` sections. Six of them (`Purpose`, `Primary Directive`, `Non-Negotiable Rules`, `Default Workflow for Legacy Changes`, `Review Checklist`, `Final Instruction`) state the loop and its brakes; the rest are tests, seams, a taxonomy of barriers (hidden inputs, hard outputs, construction), a technique index, risky areas, review rules and forbidden patterns. Clusters follow what blocks the work: no protection, no seam, an ambient value, an outgoing effect, a constructor, a static, a concrete type, a long method, logic trapped in a framework, a request to rewrite, a patch that mixes intents.
2. **The 15-line technique index is distributed by barrier, never kept in one skill.** Every technique in the upstream index has exactly one owning skill (table below). `/legacy-code:find-seam` picks the technique from the barrier; the owner skill holds the rule and the check.
3. **Sensing and separation are first-class.** The source asks that every seam be classified as observing, substituting, or both. The seam register in `seam-reviewer`, the `find-seam` proposal and the `seams` skill all carry that column.
4. **Temporary structure is a debt with an owner.** The source marks several seams as acceptable only when forced (extract-and-override call, subclass and override, link and preprocessing seams, sensing variables). `last-resort-seams` states when each is allowed, `seam-reviewer` and `/legacy-code:seam-ledger` find them, and `seam-cleaner` retires them. The cleanup obligation itself is partly compact-checklist phrasing and is labelled that way.
5. **Rule provenance is marked inline.** Every numbered rule in a topical skill carries a tag right after its statement: `[MUST]`, `[SHOULD]` or `[MUST NOT]` (the source's modal strength, with its qualifiers such as "where possible" kept attached), `[Added judgment]` (this plugin's heuristic or mechanic, including every language-specific caveat and the step-by-step mechanics of techniques that the source only names), or `[Compact checklist]` (phrasing found only in `mini.md` or `nano.md`). The source gives no thresholds; any number in a component is an example or is labelled `[Added judgment]`.
6. **Model-invocable skills are capped at 20.** There are 18: the hub plus 17 topical skills. Everything that is a procedure with arguments is manual (11 manual skills, 3 of them forked).
7. **Rules skills and workflows are different roles, never rewordings.** `characterization-tests` holds rules, `/legacy-code:characterize` writes the tests with a stop at the first barrier. `seams` holds rules, `/legacy-code:find-seam` produces a seam proposal for one target. `test-points` holds rules, `/legacy-code:effect-sketch` produces a sketch in a fork. The pairs are listed below.
8. **Reviewers own one concern and report a different artifact.** A protection reviewer reports a protection map, a seam reviewer a seam register, a hidden-input reviewer an input inventory, a construction reviewer a construction-site table, a change-intent reviewer a hunk ledger. No two reviewers share a report shape.
9. **Implementers are separated by the barrier they remove**, not by the technique list: a value or effect from the environment (`boundary-wrapper`), a hard-coded collaborator (`collaborator-injector`), the project's own statics and globals (`global-encapsulator`), new behavior in fragile code (`sprouter`), a long method or a handler holding decisions (`method-extractor`), leftover test-only structure (`seam-cleaner`), and the pins themselves (`characterization-writer`).
10. **The book's own brake is built in.** The source forbids rewrite-first work, cosmetic-only cleanup and no-safety edits. `rewrite-pressure`, `change-separation`, every implementer, `final-gate` and the `pair`, `characterize-first` and `terse` styles carry a proportionality rule: the smallest change that makes today's request safer, then stop.
11. **The compatibility docs set the sequencing rule.** Across all thirteen pairings the verdict is complementary with the same tension: refactoring and design pressure must wait until characterization or a safe seam exists. `legacy-loop`, `plan` and `lead` put that order first.
12. **Language neutrality.** The source is language-agnostic and lists seam kinds that exist only in some languages (link, preprocessing, import, template and text redefinition). Skills state the barrier first and the mechanics second, and label every language-specific mechanic `[Added judgment]`.

## Technique index ownership

Every technique in the upstream `Dependency-Breaking Technique Index` and `Preferred Legacy Techniques` is owned by exactly one skill. Other skills may mention it and point to the owner.

| Technique (source wording) | Barrier | Owner skill |
| --- | --- | --- |
| Adapt Parameter | hard-to-create parameter, narrow need | `substitution-seams` |
| Break Out Method Object | large method with local state | `large-methods` |
| Definition Completion | missing definitions in test builds (grouped with the last-resort kinds as Added judgment; the source does not restrict it with "only when") | `last-resort-seams` |
| Encapsulate Global References | globals or singletons | `static-and-global` |
| Expose Static Method | logic trapped behind instance setup | `construction-barriers` |
| Extract and Override Factory Method | construction must vary under test | `construction-barriers` |
| Extract and Override Call | language leaves few better options | `last-resort-seams` |
| Extract Implementer / Extract Interface | concrete dependency blocks compilation or substitution | `substitution-seams` |
| Introduce Instance Delegator | static behavior needs an instance seam | `static-and-global` |
| Parameterize Constructor | hidden collaborator in a constructor | `construction-barriers` |
| Parameterize Method | hidden collaborator in a method | `substitution-seams` |
| Primitivize Parameter | real type too costly for the harness | `substitution-seams` |
| Pull Up Feature / Push Down Dependency | behavior or dependency at the wrong level of a hierarchy | `policy-vs-mechanism` |
| Replace Global Reference with Getter | direct global access needs a seam | `static-and-global` |
| Subclass and Override Method | safer composition seams unavailable | `last-resort-seams` |
| Supersede Instance Variable | test must replace a dependency held in a field | `construction-barriers` |
| Template Redefinition / Text Redefinition / link seams / preprocessing seams | language or build constraints | `last-resort-seams` |
| Sprout Method / Sprout Class / Wrap Method / Wrap Class | new behavior in fragile code | `sprout-and-wrap` |

Hidden inputs and hard outputs are not techniques but dependency types: `hidden-inputs` owns time, randomness, environment, thread-local state and the implicit current user or request; `hard-outputs` owns files, network, process exits, database writes, messages and logging used as control flow; `static-and-global` owns static singletons and global configuration (listed under hidden inputs upstream).

## Skills: model-invocable (18)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Non-Negotiable Rules; Default Workflow for Legacy Changes; Review Checklist; Final Instruction | It decides which component to use; it holds no cluster rules. |
| `legacy-loop` | The order of work for a change in untested code: treat as legacy, state delta and preserve set, check protection, characterize, seam, break one dependency, change, refactor locally | Primary Directive; Default Workflow for Legacy Changes; Non-Negotiable Rules; Purpose; Characterization Tests | `characterization-tests` is how to pin behavior; `change-separation` is the shape of the patch. This is the sequence and its entry criteria. |
| `characterization-tests` | Capture what code does today: externally visible first, narrow, ugly behavior consumers rely on, suspicious results marked, probes removed | Characterization Tests; Testing Strategy Rules; Non-Negotiable Rules; No-Safety Change; Testing Rules | `focused-tests` is about tests for the requested change and test level; this is about code whose current behavior is unknown. |
| `focused-tests` | Fast focused tests at the highest level that still isolates the change, test through the seam, old versus new behavior tests, integration tests at real boundaries | New Behavior Tests; Testing Rules; Testing Strategy Rules; Code Generation Rules; Test Selection and Understanding Rules | It never decides what current behavior is; `characterization-tests` does. |
| `seams` | What a seam is for, the smallest seam, explicit over magical, sensing versus separation, seams that outlive the task | Seam Rules; What Counts as a Useful Seam; Required Behavior; Non-Negotiable Rules | It chooses and classifies; the barrier skills and `substitution-seams` carry the specific techniques. |
| `test-points` | Effect sketches, tracing outward, test points, interception points, pinch points, broad test as a first step | Test Selection and Understanding Rules; Legacy Refactoring Heuristics | `scratch-refactoring` is about understanding by restructuring; this is about where to observe. |
| `scratch-refactoring` | Throwaway restructuring to understand, marking and grouping responsibilities, discard unless backed by tests and review | Test Selection and Understanding Rules; Legacy Refactoring Heuristics | It produces knowledge, never a patch; `large-methods` produces a real extraction under tests. |
| `hidden-inputs` | Clock, randomness, environment, thread-local state, implicit user or request: inject or pass them | Hidden Inputs; Dependency Breaking Rules; Required Moves; Non-Negotiable Rules; Hidden Dependency Expansion; Default Workflow for Legacy Changes | Values that come in from the environment; `hard-outputs` is what goes out, `static-and-global` is the project's own statics. |
| `hard-outputs` | Files, network, process exit, database writes, messages, logging as control flow: put behind collaborators and sense them | Hard Outputs; Dependency Breaking Rules; Required Moves; Database-Heavy Code; Hidden Dependency Expansion; Code Generation Rules | Effects that leave the code; `hidden-inputs` is what enters. |
| `construction-barriers` | Constructors that work, buried allocation, hidden factory calls, graphs built mid-logic; parameterize constructor, factory method, supersede variable, expose static method | Construction Problems; Constructors Doing Too Much; Testability Improvements; Dependency-Breaking Technique Index; Required Moves; Hidden Dependency Expansion; Code Generation Rules; Default Workflow for Legacy Changes; Handling Risky Areas; Dependency Breaking Rules; Seam Rules | About creating objects; `substitution-seams` is about the types and parameters that methods receive. |
| `static-and-global` | Wrapper or façade around statics, singletons and global configuration; encapsulate, delegate, getter; migrate callers incrementally | Static and Global Dependencies; Hidden Inputs; Dependency-Breaking Technique Index; Hidden Dependency Expansion; Required Moves; Testability Improvements; Code Generation Rules; Handling Risky Areas; Dependency Breaking Rules | The project's own static and global access paths; `hidden-inputs` is the clock, randomness and environment. |
| `substitution-seams` | Narrow interfaces, extracted implementers, adapters for framework objects, parameterized methods, primitive parameters | Dependency-Breaking Technique Index; Testability Improvements; Seam Rules; Code Generation Rules | Makes a concrete or oversized type replaceable; `construction-barriers` is where objects are created. |
| `last-resort-seams` | Subclass and override, extract and override call, link, preprocessing, import, template and text redefinition seams: when allowed and the cleanup debt | Extract and Override Call; Seam Rules; Dependency-Breaking Technique Index; Preferred Legacy Techniques; Characterization Tests | The only skill whose job is to say "not unless"; every other seam skill prefers composition. |
| `sprout-and-wrap` | Add behavior beside fragile code: sprout method, sprout class, wrap method, wrap class, insert and redirect | Sprout Method; Sprout Class; Wrap Method; Wrap Class; Preferred Legacy Techniques; Legacy Refactoring Heuristics; Code Generation Rules | It adds behavior without reshaping old code; `large-methods` reshapes old code. |
| `large-methods` | Pure computation first, side effects second, tests around extracted parts, never many branches at once, method object | Large Methods; Dependency-Breaking Technique Index; Legacy Refactoring Heuristics; Code Generation Rules; Test Selection and Understanding Rules; Handling Risky Areas | Works inside one big method or class; `policy-vs-mechanism` separates layers. |
| `policy-vs-mechanism` | Decisions out of handlers, callbacks, framework entry points and database-heavy code; thin adapters; hierarchy placement | Database-Heavy Code; UI or Framework Code; Legacy Refactoring Heuristics; Testability Improvements; Dependency-Breaking Technique Index; Review Rules; Testing Rules; Code Generation Rules; Handling Risky Areas | Works across layers and entry points; `large-methods` is within one body. |
| `rewrite-pressure` | Decide against rewrite, wholesale replacement, large architecture, cosmetic-only cleanup; choose the next smaller verified move | Rewrite as the First Move; Cosmetic Refactoring Only; Non-Negotiable Rules; Primary Directive; Code Generation Rules; Final Instruction; Forbidden Patterns | The decision whether to go big; `change-separation` judges the shape of a patch that is already small. |
| `change-separation` | One intent per step: behavior, dependency break, structure, cleanup; stay at the change point; no exploratory restructuring checked in | Review Rules; Legacy Refactoring Heuristics; Review Checklist; Hidden Dependency Expansion; Forbidden Patterns; Test Selection and Understanding Rules | It looks at a patch; `legacy-loop` sequences the work before the patch exists. |

## Skills: manual workflows (11)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Forbidden Patterns; Review Checklist | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Legacy-risk health scan by cluster, ranked hot spots, at most 40 lines | Review Rules; Dependency Breaking Rules; Handling Risky Areas; Forbidden Patterns | `seam-ledger` lists temporary structure; `audit` rates every barrier cluster. |
| `plan` | no | no | Plan a legacy change as the loop: delta, protection, test points, barrier, seam, steps in order, cleanup | Default Workflow for Legacy Changes; Primary Directive; Code Generation Rules | `find-seam` handles one barrier; `plan` sequences the whole change. |
| `explain-rule` | no | no | Explain one rule: strength, reason, check, example, exceptions | Purpose; Non-Negotiable Rules; Dependency-Breaking Technique Index | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the nine review questions with yes, no or not applicable and a next action for each no | Review Checklist; Final Instruction | `final-gate` is the isolated PASS or FAIL; `checklist` is the interactive walk. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Code Generation Rules; Review Rules; Forbidden Patterns; Default Workflow for Legacy Changes | It resolves findings given to it; it never looks for work. |
| `characterize` | no | tests only | Pin the current behavior of one target with characterization tests; stop at the first barrier | Characterization Tests; Testing Strategy Rules; Non-Negotiable Rules; No-Safety Change | `characterization-writer` is the unattended batch version; this one stops to ask about suspicious results. |
| `find-seam` | no | no | For one target and the test you want, name the first barrier, candidate seams, the smallest, its technique and its owner | Seam Rules; Dependency Breaking Rules; Dependency-Breaking Technique Index; Legacy Refactoring Heuristics; Default Workflow for Legacy Changes | `seams` holds the rules; this produces a proposal for a concrete target and never edits. |
| `effect-sketch` | yes | no | Trace effects outward from a change point; name test points, interception points and pinch points | Test Selection and Understanding Rules; Default Workflow for Legacy Changes | `find-seam` starts after a test point is chosen; this chooses it. |
| `seam-ledger` | yes | no | Inventory existing test-only structure and mark each as keep, fold or remove | Seam Rules; Extract and Override Call; Dependency-Breaking Technique Index; Characterization Tests | `seam-reviewer` judges the seams in a diff; this lists what is already in a tree. |
| `split-patch` | no | no | Classify the hunks of a mixed patch and propose an ordered split: pins, dependency breaks, behavior, cleanup | Review Rules; Review Checklist; Legacy Refactoring Heuristics; Test Selection and Understanding Rules; Default Workflow for Legacy Changes | `change-intent-reviewer` reports findings; this produces the ordered split and never stages anything. |

## Subagents (20)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to specialists and skills in at most five steps; does not review | principles | Default Workflow for Legacy Changes; Review Rules; Review Checklist; Final Instruction | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the nine review questions on the working diff and returns PASS or FAIL | principles | Review Checklist; Final Instruction | Binary gate with evidence; reviewers return ranked findings. |
| `protection-reviewer` | sonnet | Whether the modified logic has trustworthy tests and whether characterization tests are honest | characterization-tests, legacy-loop | Characterization Tests; No-Safety Change; Review Rules | Output is a protection map; `test-level-reviewer` judges level and speed of tests that exist. |
| `test-level-reviewer` | sonnet | Level, speed, focus, use of the seam, legacy versus new tests, broad tests as scaffolding | focused-tests, test-points | Testing Rules; New Behavior Tests; Test Selection and Understanding Rules; Code Generation Rules | Output is a test ledger; it assumes protection exists. |
| `seam-reviewer` | sonnet | Seams in the diff: kind, sensing or separation, size, explicit or magical, tier, cleanup path | seams, last-resort-seams | Seam Rules; Extract and Override Call; Dependency-Breaking Technique Index | Output is a seam register; it judges seams, not the barrier they remove. |
| `hidden-input-reviewer` | sonnet | Clock, randomness, environment, thread-local state, implicit user or request reached from logic | hidden-inputs | Hidden Inputs; Dependency Breaking Rules; Hidden Dependency Expansion | Inventory of values coming in; `hard-output-reviewer` covers going out. |
| `hard-output-reviewer` | sonnet | Files, network, exits, database writes, messages, logging as control flow | hard-outputs | Hard Outputs; Dependency Breaking Rules; Required Moves; Hidden Dependency Expansion; Testing Rules | Inventory of effects going out. |
| `construction-reviewer` | sonnet | Constructors with real work, buried allocation, hidden factory calls, graphs mid-logic | construction-barriers | Construction Problems; Constructors Doing Too Much; Testability Improvements; Handling Risky Areas; Dependency Breaking Rules; Hidden Dependency Expansion | Output is a construction-site table; `static-global-reviewer` covers statics. |
| `static-global-reviewer` | sonnet | Static calls, singletons and global configuration reached from logic, and new reach-through in the diff | static-and-global | Static and Global Dependencies; Hidden Dependency Expansion; Dependency-Breaking Technique Index; Handling Risky Areas | Census of access paths; `hidden-input-reviewer` covers environment values. |
| `large-method-reviewer` | sonnet | Large methods and classes touched by the diff: responsibilities, branches edited, pure versus effect code | large-methods | Large Methods; Review Rules; Dependency-Breaking Technique Index; Handling Risky Areas; Legacy Refactoring Heuristics; Code Generation Rules | Method map inside bodies; `policy-mechanism-reviewer` covers layers. |
| `policy-mechanism-reviewer` | sonnet | Decisions trapped in handlers, callbacks, framework entry points and database-heavy code | policy-vs-mechanism | Database-Heavy Code; UI or Framework Code; Review Rules; Handling Risky Areas | Layer split table across entry points. |
| `change-intent-reviewer` | sonnet | Hunk ledger: behavior, dependency break, structure, cleanup, test; mixed intent, broad edits, rewrites, cosmetic-only | change-separation, rewrite-pressure | Review Rules; Forbidden Patterns; Legacy Refactoring Heuristics; Non-Negotiable Rules; Test Selection and Understanding Rules; Review Checklist | The only reviewer that compares the diff to the request and to itself. |
| `sprout-opportunity-reviewer` | sonnet | Deep edits to fragile code where sprout or wrap would lower the risk, and sprouts and wraps done badly | sprout-and-wrap | Preferred Legacy Techniques; Review Rules; Sprout Method; Sprout Class; No-Safety Change | Insertion ledger; `change-intent-reviewer` classifies intent, not depth of edit. |
| `characterization-writer` | sonnet | Unattended batch of characterization tests for named targets; never edits production code | characterization-tests | Characterization Tests; Testing Strategy Rules; No-Safety Change | `/legacy-code:characterize` is interactive; this one marks suspicious behavior instead of asking. |
| `boundary-wrapper` | sonnet | Puts a clock, random source, environment read, file, network, exit, database write or message behind a small collaborator | hidden-inputs, hard-outputs | Hidden Inputs; Hard Outputs; Required Moves; Hidden Dependency Expansion; Testing Rules; Default Workflow for Legacy Changes | Owns values and effects of the environment; `global-encapsulator` owns the project's own statics. |
| `collaborator-injector` | sonnet | Turns a hard-coded collaborator into an explicit input: parameterize constructor or method, extract interface, factory method | construction-barriers, substitution-seams | Construction Problems; Constructors Doing Too Much; Dependency-Breaking Technique Index; Seam Rules; Required Moves; Hidden Dependency Expansion; Testability Improvements; Default Workflow for Legacy Changes; Handling Risky Areas | Changes how an object receives a collaborator. |
| `global-encapsulator` | sonnet | Wraps statics, singletons and global configuration, then migrates callers incrementally | static-and-global | Static and Global Dependencies; Dependency-Breaking Technique Index; Hidden Dependency Expansion; Default Workflow for Legacy Changes; Handling Risky Areas | Migrates many callers over steps; `boundary-wrapper` builds one new port. |
| `sprouter` | sonnet | Adds the requested behavior as a sprouted method or class or a wrap, with tests for the new unit | sprout-and-wrap | Sprout Method; Sprout Class; Wrap Method; Wrap Class; New Behavior Tests; Default Workflow for Legacy Changes; Preferred Legacy Techniques | Adds behavior; the other implementers remove barriers. |
| `method-extractor` | sonnet | Carves pure computation out of a large method or a handler, then isolates effects, under tests | large-methods, policy-vs-mechanism | Large Methods; UI or Framework Code; Database-Heavy Code; Dependency-Breaking Technique Index; Default Workflow for Legacy Changes; Handling Risky Areas; Legacy Refactoring Heuristics; Code Generation Rules | Reshapes existing code; `sprouter` leaves it alone. |
| `seam-cleaner` | sonnet | Retires or folds test-only seams, probes and sensing variables once safer structure exists | seams, last-resort-seams | Seam Rules; Extract and Override Call; Characterization Tests | Removes structure; every other implementer adds it. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule, its strength and the loop step behind each choice; ends non-trivial answers with one check question | Purpose; Non-Negotiable Rules; Primary Directive | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Review Checklist; Forbidden Patterns | Never changes code. |
| `pair` | Small steps, narrates the loop step, asks before anything larger than a few lines or touching public API | Default Workflow for Legacy Changes; Final Instruction; Primary Directive | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Final Instruction; Review Checklist | Brevity rules. |
| `characterize-first` | Before the first edit to code without trustworthy tests prints a safety preamble (change point, delta, preserve set, protection, first pin) and writes the pin before the change | Primary Directive; Characterization Tests; No-Safety Change; Default Workflow for Legacy Changes; New Behavior Tests; Review Checklist | A pre-edit gate on protection. |
| `explorer` | Read-only understanding mode: effect sketch, responsibility groups, open questions, candidate test points and seams, one next safe move | Test Selection and Understanding Rules; Legacy Refactoring Heuristics | Produces understanding and never a patch. It is the conversational, whole-session form: it asks and answers in chat and neither forks nor edits. `/legacy-code:effect-sketch` is a bounded forked report of at most 40 lines for one named change point, and `/legacy-code:scratch-refactoring` holds the rules for throwaway restructuring. |

## Confusable pairs

Model-invocable skills whose triggers could fire on the same request, and the clause that separates them. Each pair below names the other skill, in backticks, in both descriptions. The one exception, `construction-barriers` / `last-resort-seams`, is separated by the trigger itself (an object that cannot be built cheaply versus a restriction that applies only when ordinary seams are impractical) and by the opening paragraph of each body.

| Pair | Separation |
| --- | --- |
| `characterization-tests` / `focused-tests` | Pinning behavior nobody has confirmed versus choosing the level of tests for behavior the request defines. |
| `characterization-tests` / `legacy-loop` | How to pin behavior versus the order in which pinning, seam and change happen. |
| `principles` / `legacy-loop` | The hub: modal convention, routing to every component, final checklist, versus the order of work for one change. Both fire on "change this untested function"; the hub's description ends by pointing to `legacy-loop` for the order, and `legacy-loop`'s points back to `principles` for routing. |
| `legacy-loop` / `change-separation` | The sequence of work before a patch exists versus the intent of each hunk in the patch. |
| `legacy-loop` / `rewrite-pressure` | Doing the loop versus resisting the pull to skip it by starting over. |
| `rewrite-pressure` / `change-separation` | Whether to go big at all versus whether a small patch mixes intents. |
| `seams` / `substitution-seams` | Choosing and classifying any seam versus the specific techniques that make a concrete type replaceable. |
| `seams` / `last-resort-seams` | The default preference for explicit seams versus the conditions under which subclass and build seams are tolerated. |
| `seams` / `test-points` | Where to put a seam and what it is for (substitution versus sensing) versus where to observe an effect (test, interception and pinch points). |
| `hidden-inputs` / `static-and-global` | Values from the environment (clock, randomness, environment variables, thread-local state, current user) versus the project's own static singletons and global configuration. |
| `hidden-inputs` / `hard-outputs` | Things the code reads from outside versus things it does to the outside. |
| `hard-outputs` / `policy-vs-mechanism` | Putting an effect behind a collaborator versus moving a decision out of a handler or a query layer. |
| `construction-barriers` / `substitution-seams` | Where objects are created and constructed versus the types and parameters that methods receive. |
| `construction-barriers` / `static-and-global` | Instances created in the wrong place versus static access paths. |
| `construction-barriers` / `last-resort-seams` | `Extract and Override Factory Method` and `Supersede Instance Variable` are owned by the first; the subclass and test-door cautions are in the second. |
| `large-methods` / `policy-vs-mechanism` | The inside of one long body versus layers and entry points. |
| `large-methods` / `scratch-refactoring` | A real extraction kept under tests versus throwaway restructuring that produces notes. |
| `large-methods` / `sprout-and-wrap` | Reshaping old code versus adding beside it. |
| `test-points` / `scratch-refactoring` | Where to observe an effect versus understanding the code by restructuring it. |
| `test-points` / `characterization-tests` | Choosing the place to test versus writing the test that captures behavior there. |
| `test-points` / `focused-tests` | Finding the point where effects are visible versus choosing a fast, narrow test once the point is known. |

Rules skills and their workflows (different roles, not rewordings; only the rules skill is model-invocable):

| Rules skill | Workflow | What the workflow adds |
| --- | --- | --- |
| `characterization-tests` | `characterize` | A concrete target, an observed-results table and a stop at the first barrier. |
| `seams` | `find-seam` | A seam proposal for one target and one wanted test, with technique and owner. |
| `test-points` | `effect-sketch` | A sketch of effects from a given change point, in a fork. |
| `seams`, `last-resort-seams` | `seam-ledger` | A keep, fold or remove inventory of existing test-only structure, in a fork. |
| `change-separation` | `split-patch` | An ordered split of a mixed patch. |
| `legacy-loop` | `plan` | A written plan for one requested change. |

Reviewers and the workflows that produce a similar artifact. Each reviewer judges a change; the workflow covers a tree or a plan, and the two report different tables:

| Reviewer | Workflow | Separation |
| --- | --- | --- |
| `seam-reviewer` | `seam-ledger` | Seam register for the seams a diff adds, with findings, versus an inventory of structure already in a tree, whether or not anything changed. |
| `change-intent-reviewer` | `split-patch` | Hunk ledger with findings versus the ordered split that resolves a mixed patch. |
| `protection-reviewer` | `characterize` | Map of what is protected and how honestly versus the tests that close the gap for one target. |

Output style and the components that produce a similar artifact:

| Style | Component | Separation |
| --- | --- | --- |
| `explorer` | `effect-sketch`, `scratch-refactoring` | A session-long conversational mode that answers questions about unfamiliar code in chat, versus a bounded forked report for one change point, versus rules for throwaway restructuring. |

Agent pairs that share a theme and how their reports differ:

| Pair | Separation |
| --- | --- |
| `hidden-input-reviewer` / `hard-output-reviewer` | Input inventory versus effect inventory. |
| `hidden-input-reviewer` / `static-global-reviewer` | Environment values versus the project's own access paths. |
| `construction-reviewer` / `static-global-reviewer` | Construction-site table versus reach-through census. |
| `large-method-reviewer` / `policy-mechanism-reviewer` | Method map versus layer split. |
| `protection-reviewer` / `test-level-reviewer` | Whether behavior is protected versus whether the tests are the right size. |
| `boundary-wrapper` / `global-encapsulator` | One new port for an environment value or effect versus an incremental caller migration off an existing global. |
| `collaborator-injector` / `boundary-wrapper` | A class receives a collaborator it used to create versus a value or effect is moved behind a new small collaborator. |
| `method-extractor` / `sprouter` | Reshape existing code versus leave it and add beside it. |
| `characterization-writer` / `seam-cleaner` | Adds pins versus removes scaffolding. |
| `lead` / `change-intent-reviewer` | Routing versus judging a diff. |

## Coverage check against the upstream sections

Generated from the `## Source` sections of the components by reading them once the plugin was built; `docs/TRACEABILITY.md` is the validator's own view and lists direct citations of `##` headings only.

| Upstream section | Components that apply it (directly or through a subsection) |
| --- | --- |
| Purpose | explain-rule, legacy-loop, principles, mentor |
| Primary Directive | legacy-loop, plan, principles, rewrite-pressure, characterize-first, mentor, pair |
| Non-Negotiable Rules | characterization-tests, characterize, explain-rule, hidden-inputs, legacy-loop, principles, rewrite-pressure, seams, change-intent-reviewer, mentor |
| Default Workflow for Legacy Changes | construction-barriers, effect-sketch, find-seam, fix, hidden-inputs, legacy-loop, plan, principles, split-patch, boundary-wrapper, collaborator-injector, global-encapsulator, lead, method-extractor, sprouter, characterize-first, pair |
| Testing Strategy Rules | characterization-tests, characterize, construction-barriers, focused-tests, last-resort-seams, legacy-loop, policy-vs-mechanism, seam-ledger, static-and-global, substitution-seams, characterization-writer, construction-reviewer, protection-reviewer, seam-cleaner, sprouter, test-level-reviewer, characterize-first |
| Seam Rules | construction-barriers, find-seam, last-resort-seams, seam-ledger, seams, substitution-seams, collaborator-injector, seam-cleaner, seam-reviewer |
| Dependency Breaking Rules | audit, construction-barriers, find-seam, hard-outputs, hidden-inputs, static-and-global, boundary-wrapper, collaborator-injector, construction-reviewer, hard-output-reviewer, hidden-input-reviewer |
| Test Selection and Understanding Rules | change-separation, effect-sketch, focused-tests, large-methods, scratch-refactoring, split-patch, test-points, change-intent-reviewer, test-level-reviewer, explorer |
| Preferred Legacy Techniques | last-resort-seams, seam-ledger, sprout-and-wrap, seam-cleaner, seam-reviewer, sprout-opportunity-reviewer, sprouter |
| Dependency-Breaking Technique Index | construction-barriers, explain-rule, find-seam, large-methods, last-resort-seams, policy-vs-mechanism, seam-ledger, static-and-global, substitution-seams, collaborator-injector, global-encapsulator, large-method-reviewer, method-extractor, seam-reviewer, static-global-reviewer |
| Legacy Refactoring Heuristics | change-separation, find-seam, large-methods, policy-vs-mechanism, scratch-refactoring, split-patch, sprout-and-wrap, test-points, change-intent-reviewer, large-method-reviewer, method-extractor, explorer |
| Handling Risky Areas | audit, construction-barriers, hard-outputs, large-methods, policy-vs-mechanism, static-and-global, collaborator-injector, construction-reviewer, global-encapsulator, large-method-reviewer, method-extractor, policy-mechanism-reviewer, static-global-reviewer |
| Review Rules | audit, change-separation, fix, policy-vs-mechanism, review, split-patch, change-intent-reviewer, large-method-reviewer, lead, policy-mechanism-reviewer, protection-reviewer, sprout-opportunity-reviewer, strict-reviewer |
| Forbidden Patterns | audit, change-separation, characterization-tests, characterize, construction-barriers, fix, hard-outputs, hidden-inputs, review, rewrite-pressure, static-and-global, change-intent-reviewer, characterization-writer, global-encapsulator, hidden-input-reviewer, protection-reviewer, static-global-reviewer, characterize-first, strict-reviewer |
| Code Generation Rules | construction-barriers, fix, focused-tests, hard-outputs, large-methods, plan, policy-vs-mechanism, rewrite-pressure, sprout-and-wrap, static-and-global, substitution-seams, large-method-reviewer, method-extractor, test-level-reviewer |
| Testing Rules | characterization-tests, focused-tests, policy-vs-mechanism, boundary-wrapper, hard-output-reviewer, test-level-reviewer |
| Review Checklist | change-separation, checklist, principles, review, split-patch, change-intent-reviewer, final-gate, lead, characterize-first, strict-reviewer, terse |
| Final Instruction | checklist, principles, rewrite-pressure, final-gate, lead, pair, terse |

### Subsections

| Subsection (`###`) | Parent section | Components that cite it |
| --- | --- | --- |
| Characterization Tests | Testing Strategy Rules | characterization-tests, characterize, last-resort-seams, legacy-loop, seam-ledger, characterization-writer, protection-reviewer, seam-cleaner, characterize-first |
| New Behavior Tests | Testing Strategy Rules | focused-tests, sprouter, test-level-reviewer, characterize-first |
| Testability Improvements | Testing Strategy Rules | construction-barriers, policy-vs-mechanism, static-and-global, substitution-seams, collaborator-injector, construction-reviewer |
| What Counts as a Useful Seam | Seam Rules | seams |
| Required Behavior | Seam Rules | seams |
| Hidden Inputs | Dependency Breaking Rules | hidden-inputs, static-and-global, boundary-wrapper, hidden-input-reviewer |
| Hard Outputs | Dependency Breaking Rules | hard-outputs, boundary-wrapper, hard-output-reviewer |
| Construction Problems | Dependency Breaking Rules | construction-barriers, collaborator-injector, construction-reviewer |
| Required Moves | Dependency Breaking Rules | construction-barriers, hard-outputs, hidden-inputs, static-and-global, boundary-wrapper, collaborator-injector, hard-output-reviewer |
| Sprout Method | Preferred Legacy Techniques | sprout-and-wrap, sprout-opportunity-reviewer, sprouter |
| Sprout Class | Preferred Legacy Techniques | sprout-and-wrap, sprout-opportunity-reviewer, sprouter |
| Wrap Method | Preferred Legacy Techniques | sprout-and-wrap, sprouter |
| Wrap Class | Preferred Legacy Techniques | sprout-and-wrap, sprouter |
| Extract and Override Call | Preferred Legacy Techniques | last-resort-seams, seam-ledger, seam-cleaner, seam-reviewer |
| Large Methods | Handling Risky Areas | large-methods, large-method-reviewer, method-extractor |
| Static and Global Dependencies | Handling Risky Areas | static-and-global, global-encapsulator, static-global-reviewer |
| Database-Heavy Code | Handling Risky Areas | hard-outputs, policy-vs-mechanism, method-extractor, policy-mechanism-reviewer |
| UI or Framework Code | Handling Risky Areas | policy-vs-mechanism, method-extractor, policy-mechanism-reviewer |
| Constructors Doing Too Much | Handling Risky Areas | construction-barriers, collaborator-injector, construction-reviewer |
| Rewrite as the First Move | Forbidden Patterns | rewrite-pressure |
| No-Safety Change | Forbidden Patterns | characterization-tests, characterize, characterization-writer, protection-reviewer, sprout-opportunity-reviewer, characterize-first |
| Hidden Dependency Expansion | Forbidden Patterns | change-separation, construction-barriers, hard-outputs, hidden-inputs, static-and-global, boundary-wrapper, collaborator-injector, construction-reviewer, global-encapsulator, hard-output-reviewer, hidden-input-reviewer, static-global-reviewer |
| Cosmetic Refactoring Only | Forbidden Patterns | rewrite-pressure |

## Overlap review

Pairs that were close and how they were separated:

- `hidden-inputs` and `static-and-global`: the upstream hidden-input list contains both ambient values (clock, randomness, environment, thread-local state, current user) and the project's own static singletons and global configuration. The first skill keeps the values; the second keeps the access paths and their incremental migration. A static call such as a wrapper over a clock belongs to `hidden-inputs` because the fix is to inject the value source, not to migrate callers.
- `boundary-wrapper` and `global-encapsulator`: both create a small abstraction. The first builds one port for something that comes from or goes to the environment and wires it at the edge. The second starts from a global that already exists in many callers and moves them over in steps.
- `characterize` (skill) and `characterization-writer` (agent): the skill is interactive and stops at a suspicious result to ask; the agent runs unattended on a list of targets, marks suspicious results instead of asking and returns a table.
- `rewrite-pressure` and `legacy-loop`: both begin from "do not start with a rewrite". The loop skill owns the order of work; the other owns the decision when someone proposes going big and the test for "clearly safer".
- `last-resort-seams` and `construction-barriers`: `Extract and Override Factory Method` is a construction technique and is owned by `construction-barriers`; the cautions that apply to every subclass seam (whether an override reached from a constructor is safe in the language, which the factory-method technique itself depends on; test-only visibility; the exit) are owned by `last-resort-seams`.
- `large-methods` and `policy-vs-mechanism`: a long HTTP handler matches both. `large-methods` is about carving inside one body; `policy-vs-mechanism` is about where the decision lives relative to the framework entry point, the database layer and the hierarchy. `method-extractor` uses both because the carving step is the same.
- `seam-reviewer`, `/legacy-code:seam-ledger` and `seam-cleaner`: judge new seams in a diff, inventory existing ones, retire them.

Upstream sections with no dedicated skill are covered as follows: `Purpose`, `Final Instruction` and `Review Checklist` are carried by the hub, the gate, the checklist workflow and the styles because they govern how work is reported and bounded, not how code is shaped. `Code Generation Rules` is distributed: each preferred first move lives in the barrier skill that performs it, and the preferred avoidances live in `rewrite-pressure` and `substitution-seams`.
