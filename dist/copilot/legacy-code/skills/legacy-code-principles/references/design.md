# Working Effectively with Legacy Code plugin: component map

This file is the plan the components were built from, kept in step with what was built. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`; `###` headings are cited where a component owns exactly one subsection. A `Source` bullet with a note means only that part of the section applies.

## Design decisions

1. **The rule set is a loop plus a catalog of obstacles, so the split follows the obstacle a developer meets.** The upstream full file has 18 `##` sections. Six of them (`Purpose`, `Primary Directive`, `Non-Negotiable Rules`, `Default Workflow for Legacy Changes`, `Review Checklist`, `Final Instruction`) state the loop and its brakes; the rest are tests, seams, a taxonomy of barriers (hidden inputs, hard outputs, construction), a technique index, risky areas, review rules and forbidden patterns. Clusters follow what blocks the work: no protection, no seam, an ambient value, an outgoing effect, a constructor, a static, a concrete type, a long method, logic trapped in a framework, a request to rewrite, a patch that mixes intents.
2. **The 15-line technique index is distributed by barrier, never kept in one skill.** Every technique in the upstream index has exactly one owning skill (table below). `legacy-code-find-seam` picks the technique from the barrier; the owner skill holds the rule and the check.
3. **Sensing and separation are first-class.** The source asks that every seam be classified as observing, substituting, or both. The seam register in `legacy-code-seam-reviewer`, the `legacy-code-find-seam` proposal and the `seams` skill all carry that column.
4. **Temporary structure is a debt with an owner.** The source marks several seams as acceptable only when forced (extract-and-override call, subclass and override, link and preprocessing seams, sensing variables). `legacy-code-last-resort-seams` states when each is allowed, `legacy-code-seam-reviewer` and `legacy-code-seam-ledger` find them, and `legacy-code-seam-cleaner` retires them. The cleanup obligation itself is partly compact-checklist phrasing and is labelled that way.
5. **Rule provenance is marked inline.** Every numbered rule in a topical skill carries a tag right after its statement: `[MUST]`, `[SHOULD]` or `[MUST NOT]` (the source's modal strength, with its qualifiers such as "where possible" kept attached), `[Added judgment]` (this plugin's heuristic or mechanic, including every language-specific caveat and the step-by-step mechanics of techniques that the source only names), or `[Compact checklist]` (phrasing found only in `mini.md` or `nano.md`). The source gives no thresholds; any number in a component is an example or is labelled `[Added judgment]`.
6. **Model-invocable skills are capped at 20.** There are 18: the hub plus 17 topical skills. Everything that is a procedure with arguments is manual (11 manual skills, 3 of them forked).
7. **Rules skills and workflows are different roles, never rewordings.** `legacy-code-characterization-tests` holds rules, `legacy-code-characterize` writes the tests with a stop at the first barrier. `seams` holds rules, `legacy-code-find-seam` produces a seam proposal for one target. `legacy-code-test-points` holds rules, `legacy-code-effect-sketch` produces a sketch in a fork. The pairs are listed below.
8. **Reviewers own one concern and report a different artifact.** A protection reviewer reports a protection map, a seam reviewer a seam register, a hidden-input reviewer an input inventory, a construction reviewer a construction-site table, a change-intent reviewer a hunk ledger. No two reviewers share a report shape.
9. **Implementers are separated by the barrier they remove**, not by the technique list: a value or effect from the environment (`legacy-code-boundary-wrapper`), a hard-coded collaborator (`legacy-code-collaborator-injector`), the project's own statics and globals (`legacy-code-global-encapsulator`), new behavior in fragile code (`legacy-code-sprouter`), a long method or a handler holding decisions (`legacy-code-method-extractor`), leftover test-only structure (`legacy-code-seam-cleaner`), and the pins themselves (`legacy-code-characterization-writer`).
10. **The book's own brake is built in.** The source forbids rewrite-first work, cosmetic-only cleanup and no-safety edits. `legacy-code-rewrite-pressure`, `legacy-code-change-separation`, every implementer, `legacy-code-final-gate` and the `pair`, `characterize-first` and `terse` styles carry a proportionality rule: the smallest change that makes today's request safer, then stop.
11. **The compatibility docs set the sequencing rule.** Across all thirteen pairings the verdict is complementary with the same tension: refactoring and design pressure must wait until characterization or a safe seam exists. `legacy-code-legacy-loop`, `plan` and `legacy-code-lead` put that order first.
12. **Language neutrality.** The source is language-agnostic and lists seam kinds that exist only in some languages (link, preprocessing, import, template and text redefinition). Skills state the barrier first and the mechanics second, and label every language-specific mechanic `[Added judgment]`.

## Technique index ownership

Every technique in the upstream `Dependency-Breaking Technique Index` and `Preferred Legacy Techniques` is owned by exactly one skill. Other skills may mention it and point to the owner.

| Technique (source wording) | Barrier | Owner skill |
| --- | --- | --- |
| Adapt Parameter | hard-to-create parameter, narrow need | `legacy-code-substitution-seams` |
| Break Out Method Object | large method with local state | `legacy-code-large-methods` |
| Definition Completion | missing definitions in test builds (grouped with the last-resort kinds as Added judgment; the source does not restrict it with "only when") | `legacy-code-last-resort-seams` |
| Encapsulate Global References | globals or singletons | `legacy-code-static-and-global` |
| Expose Static Method | logic trapped behind instance setup | `legacy-code-construction-barriers` |
| Extract and Override Factory Method | construction must vary under test | `legacy-code-construction-barriers` |
| Extract and Override Call | language leaves few better options | `legacy-code-last-resort-seams` |
| Extract Implementer / Extract Interface | concrete dependency blocks compilation or substitution | `legacy-code-substitution-seams` |
| Introduce Instance Delegator | static behavior needs an instance seam | `legacy-code-static-and-global` |
| Parameterize Constructor | hidden collaborator in a constructor | `legacy-code-construction-barriers` |
| Parameterize Method | hidden collaborator in a method | `legacy-code-substitution-seams` |
| Primitivize Parameter | real type too costly for the harness | `legacy-code-substitution-seams` |
| Pull Up Feature / Push Down Dependency | behavior or dependency at the wrong level of a hierarchy | `legacy-code-policy-vs-mechanism` |
| Replace Global Reference with Getter | direct global access needs a seam | `legacy-code-static-and-global` |
| Subclass and Override Method | safer composition seams unavailable | `legacy-code-last-resort-seams` |
| Supersede Instance Variable | test must replace a dependency held in a field | `legacy-code-construction-barriers` |
| Template Redefinition / Text Redefinition / link seams / preprocessing seams | language or build constraints | `legacy-code-last-resort-seams` |
| Sprout Method / Sprout Class / Wrap Method / Wrap Class | new behavior in fragile code | `legacy-code-sprout-and-wrap` |

Hidden inputs and hard outputs are not techniques but dependency types: `legacy-code-hidden-inputs` owns time, randomness, environment, thread-local state and the implicit current user or request; `legacy-code-hard-outputs` owns files, network, process exits, database writes, messages and logging used as control flow; `legacy-code-static-and-global` owns static singletons and global configuration (listed under hidden inputs upstream).

## Skills: model-invocable (18)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Non-Negotiable Rules; Default Workflow for Legacy Changes; Review Checklist; Final Instruction | It decides which component to use; it holds no cluster rules. |
| `legacy-code-legacy-loop` | The order of work for a change in untested code: treat as legacy, state delta and preserve set, check protection, characterize, seam, break one dependency, change, refactor locally | Primary Directive; Default Workflow for Legacy Changes; Non-Negotiable Rules; Purpose; Characterization Tests | `legacy-code-characterization-tests` is how to pin behavior; `legacy-code-change-separation` is the shape of the patch. This is the sequence and its entry criteria. |
| `legacy-code-characterization-tests` | Capture what code does today: externally visible first, narrow, ugly behavior consumers rely on, suspicious results marked, probes removed | Characterization Tests; Testing Strategy Rules; Non-Negotiable Rules; No-Safety Change; Testing Rules | `legacy-code-focused-tests` is about tests for the requested change and test level; this is about code whose current behavior is unknown. |
| `legacy-code-focused-tests` | Fast focused tests at the highest level that still isolates the change, test through the seam, old versus new behavior tests, integration tests at real boundaries | New Behavior Tests; Testing Rules; Testing Strategy Rules; Code Generation Rules; Test Selection and Understanding Rules | It never decides what current behavior is; `legacy-code-characterization-tests` does. |
| `seams` | What a seam is for, the smallest seam, explicit over magical, sensing versus separation, seams that outlive the task | Seam Rules; What Counts as a Useful Seam; Required Behavior; Non-Negotiable Rules | It chooses and classifies; the barrier skills and `legacy-code-substitution-seams` carry the specific techniques. |
| `legacy-code-test-points` | Effect sketches, tracing outward, test points, interception points, pinch points, broad test as a first step | Test Selection and Understanding Rules; Legacy Refactoring Heuristics | `legacy-code-scratch-refactoring` is about understanding by restructuring; this is about where to observe. |
| `legacy-code-scratch-refactoring` | Throwaway restructuring to understand, marking and grouping responsibilities, discard unless backed by tests and review | Test Selection and Understanding Rules; Legacy Refactoring Heuristics | It produces knowledge, never a patch; `legacy-code-large-methods` produces a real extraction under tests. |
| `legacy-code-hidden-inputs` | Clock, randomness, environment, thread-local state, implicit user or request: inject or pass them | Hidden Inputs; Dependency Breaking Rules; Required Moves; Non-Negotiable Rules; Hidden Dependency Expansion; Default Workflow for Legacy Changes | Values that come in from the environment; `legacy-code-hard-outputs` is what goes out, `legacy-code-static-and-global` is the project's own statics. |
| `legacy-code-hard-outputs` | Files, network, process exit, database writes, messages, logging as control flow: put behind collaborators and sense them | Hard Outputs; Dependency Breaking Rules; Required Moves; Database-Heavy Code; Hidden Dependency Expansion; Code Generation Rules | Effects that leave the code; `legacy-code-hidden-inputs` is what enters. |
| `legacy-code-construction-barriers` | Constructors that work, buried allocation, hidden factory calls, graphs built mid-logic; parameterize constructor, factory method, supersede variable, expose static method | Construction Problems; Constructors Doing Too Much; Testability Improvements; Dependency-Breaking Technique Index; Required Moves; Hidden Dependency Expansion; Code Generation Rules; Default Workflow for Legacy Changes; Handling Risky Areas; Dependency Breaking Rules; Seam Rules | About creating objects; `legacy-code-substitution-seams` is about the types and parameters that methods receive. |
| `legacy-code-static-and-global` | Wrapper or façade around statics, singletons and global configuration; encapsulate, delegate, getter; migrate callers incrementally | Static and Global Dependencies; Hidden Inputs; Dependency-Breaking Technique Index; Hidden Dependency Expansion; Required Moves; Testability Improvements; Code Generation Rules; Handling Risky Areas; Dependency Breaking Rules | The project's own static and global access paths; `legacy-code-hidden-inputs` is the clock, randomness and environment. |
| `legacy-code-substitution-seams` | Narrow interfaces, extracted implementers, adapters for framework objects, parameterized methods, primitive parameters | Dependency-Breaking Technique Index; Testability Improvements; Seam Rules; Code Generation Rules | Makes a concrete or oversized type replaceable; `legacy-code-construction-barriers` is where objects are created. |
| `legacy-code-last-resort-seams` | Subclass and override, extract and override call, link, preprocessing, import, template and text redefinition seams: when allowed and the cleanup debt | Extract and Override Call; Seam Rules; Dependency-Breaking Technique Index; Preferred Legacy Techniques; Characterization Tests | The only skill whose job is to say "not unless"; every other seam skill prefers composition. |
| `legacy-code-sprout-and-wrap` | Add behavior beside fragile code: sprout method, sprout class, wrap method, wrap class, insert and redirect | Sprout Method; Sprout Class; Wrap Method; Wrap Class; Preferred Legacy Techniques; Legacy Refactoring Heuristics; Code Generation Rules | It adds behavior without reshaping old code; `legacy-code-large-methods` reshapes old code. |
| `legacy-code-large-methods` | Pure computation first, side effects second, tests around extracted parts, never many branches at once, method object | Large Methods; Dependency-Breaking Technique Index; Legacy Refactoring Heuristics; Code Generation Rules; Test Selection and Understanding Rules; Handling Risky Areas | Works inside one big method or class; `legacy-code-policy-vs-mechanism` separates layers. |
| `legacy-code-policy-vs-mechanism` | Decisions out of handlers, callbacks, framework entry points and database-heavy code; thin adapters; hierarchy placement | Database-Heavy Code; UI or Framework Code; Legacy Refactoring Heuristics; Testability Improvements; Dependency-Breaking Technique Index; Review Rules; Testing Rules; Code Generation Rules; Handling Risky Areas | Works across layers and entry points; `legacy-code-large-methods` is within one body. |
| `legacy-code-rewrite-pressure` | Decide against rewrite, wholesale replacement, large architecture, cosmetic-only cleanup; choose the next smaller verified move | Rewrite as the First Move; Cosmetic Refactoring Only; Non-Negotiable Rules; Primary Directive; Code Generation Rules; Final Instruction; Forbidden Patterns | The decision whether to go big; `legacy-code-change-separation` judges the shape of a patch that is already small. |
| `legacy-code-change-separation` | One intent per step: behavior, dependency break, structure, cleanup; stay at the change point; no exploratory restructuring checked in | Review Rules; Legacy Refactoring Heuristics; Review Checklist; Hidden Dependency Expansion; Forbidden Patterns; Test Selection and Understanding Rules | It looks at a patch; `legacy-code-legacy-loop` sequences the work before the patch exists. |

## Skills: manual workflows (11)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Forbidden Patterns; Review Checklist | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Legacy-risk health scan by cluster, ranked hot spots, at most 40 lines | Review Rules; Dependency Breaking Rules; Handling Risky Areas; Forbidden Patterns | `legacy-code-seam-ledger` lists temporary structure; `audit` rates every barrier cluster. |
| `plan` | no | no | Plan a legacy change as the loop: delta, protection, test points, barrier, seam, steps in order, cleanup | Default Workflow for Legacy Changes; Primary Directive; Code Generation Rules | `legacy-code-find-seam` handles one barrier; `plan` sequences the whole change. |
| `legacy-code-explain-rule` | no | no | Explain one rule: strength, reason, check, example, exceptions | Purpose; Non-Negotiable Rules; Dependency-Breaking Technique Index | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the nine review questions with yes, no or not applicable and a next action for each no | Review Checklist; Final Instruction | `legacy-code-final-gate` is the isolated PASS or FAIL; `checklist` is the interactive walk. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Code Generation Rules; Review Rules; Forbidden Patterns; Default Workflow for Legacy Changes | It resolves findings given to it; it never looks for work. |
| `characterize` | no | tests only | Pin the current behavior of one target with characterization tests; stop at the first barrier | Characterization Tests; Testing Strategy Rules; Non-Negotiable Rules; No-Safety Change | `legacy-code-characterization-writer` is the unattended batch version; this one stops to ask about suspicious results. |
| `legacy-code-find-seam` | no | no | For one target and the test you want, name the first barrier, candidate seams, the smallest, its technique and its owner | Seam Rules; Dependency Breaking Rules; Dependency-Breaking Technique Index; Legacy Refactoring Heuristics; Default Workflow for Legacy Changes | `seams` holds the rules; this produces a proposal for a concrete target and never edits. |
| `legacy-code-effect-sketch` | yes | no | Trace effects outward from a change point; name test points, interception points and pinch points | Test Selection and Understanding Rules; Default Workflow for Legacy Changes | `legacy-code-find-seam` starts after a test point is chosen; this chooses it. |
| `legacy-code-seam-ledger` | yes | no | Inventory existing test-only structure and mark each as keep, fold or remove | Seam Rules; Extract and Override Call; Dependency-Breaking Technique Index; Characterization Tests | `legacy-code-seam-reviewer` judges the seams in a diff; this lists what is already in a tree. |
| `legacy-code-split-patch` | no | no | Classify the hunks of a mixed patch and propose an ordered split: pins, dependency breaks, behavior, cleanup | Review Rules; Review Checklist; Legacy Refactoring Heuristics; Test Selection and Understanding Rules; Default Workflow for Legacy Changes | `legacy-code-change-intent-reviewer` reports findings; this produces the ordered split and never stages anything. |

## Subagents (20)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `legacy-code-lead` | opus | Routes a task or diff to specialists and skills in at most five steps; does not review | principles | Default Workflow for Legacy Changes; Review Rules; Review Checklist; Final Instruction | Only agent that does not read code for defects. |
| `legacy-code-final-gate` | sonnet | Runs the nine review questions on the working diff and returns PASS or FAIL | principles | Review Checklist; Final Instruction | Binary gate with evidence; reviewers return ranked findings. |
| `legacy-code-protection-reviewer` | sonnet | Whether the modified logic has trustworthy tests and whether characterization tests are honest | characterization-tests, legacy-loop | Characterization Tests; No-Safety Change; Review Rules | Output is a protection map; `legacy-code-test-level-reviewer` judges level and speed of tests that exist. |
| `legacy-code-test-level-reviewer` | sonnet | Level, speed, focus, use of the seam, legacy versus new tests, broad tests as scaffolding | focused-tests, test-points | Testing Rules; New Behavior Tests; Test Selection and Understanding Rules; Code Generation Rules | Output is a test ledger; it assumes protection exists. |
| `legacy-code-seam-reviewer` | sonnet | Seams in the diff: kind, sensing or separation, size, explicit or magical, tier, cleanup path | seams, last-resort-seams | Seam Rules; Extract and Override Call; Dependency-Breaking Technique Index | Output is a seam register; it judges seams, not the barrier they remove. |
| `legacy-code-hidden-input-reviewer` | sonnet | Clock, randomness, environment, thread-local state, implicit user or request reached from logic | hidden-inputs | Hidden Inputs; Dependency Breaking Rules; Hidden Dependency Expansion | Inventory of values coming in; `legacy-code-hard-output-reviewer` covers going out. |
| `legacy-code-hard-output-reviewer` | sonnet | Files, network, exits, database writes, messages, logging as control flow | hard-outputs | Hard Outputs; Dependency Breaking Rules; Required Moves; Hidden Dependency Expansion; Testing Rules | Inventory of effects going out. |
| `legacy-code-construction-reviewer` | sonnet | Constructors with real work, buried allocation, hidden factory calls, graphs mid-logic | construction-barriers | Construction Problems; Constructors Doing Too Much; Testability Improvements; Handling Risky Areas; Dependency Breaking Rules; Hidden Dependency Expansion | Output is a construction-site table; `legacy-code-static-global-reviewer` covers statics. |
| `legacy-code-static-global-reviewer` | sonnet | Static calls, singletons and global configuration reached from logic, and new reach-through in the diff | static-and-global | Static and Global Dependencies; Hidden Dependency Expansion; Dependency-Breaking Technique Index; Handling Risky Areas | Census of access paths; `legacy-code-hidden-input-reviewer` covers environment values. |
| `legacy-code-large-method-reviewer` | sonnet | Large methods and classes touched by the diff: responsibilities, branches edited, pure versus effect code | large-methods | Large Methods; Review Rules; Dependency-Breaking Technique Index; Handling Risky Areas; Legacy Refactoring Heuristics; Code Generation Rules | Method map inside bodies; `legacy-code-policy-mechanism-reviewer` covers layers. |
| `legacy-code-policy-mechanism-reviewer` | sonnet | Decisions trapped in handlers, callbacks, framework entry points and database-heavy code | policy-vs-mechanism | Database-Heavy Code; UI or Framework Code; Review Rules; Handling Risky Areas | Layer split table across entry points. |
| `legacy-code-change-intent-reviewer` | sonnet | Hunk ledger: behavior, dependency break, structure, cleanup, test; mixed intent, broad edits, rewrites, cosmetic-only | change-separation, rewrite-pressure | Review Rules; Forbidden Patterns; Legacy Refactoring Heuristics; Non-Negotiable Rules; Test Selection and Understanding Rules; Review Checklist | The only reviewer that compares the diff to the request and to itself. |
| `legacy-code-sprout-opportunity-reviewer` | sonnet | Deep edits to fragile code where sprout or wrap would lower the risk, and sprouts and wraps done badly | sprout-and-wrap | Preferred Legacy Techniques; Review Rules; Sprout Method; Sprout Class; No-Safety Change | Insertion ledger; `legacy-code-change-intent-reviewer` classifies intent, not depth of edit. |
| `legacy-code-characterization-writer` | sonnet | Unattended batch of characterization tests for named targets; never edits production code | characterization-tests | Characterization Tests; Testing Strategy Rules; No-Safety Change | `legacy-code-characterize` is interactive; this one marks suspicious behavior instead of asking. |
| `legacy-code-boundary-wrapper` | sonnet | Puts a clock, random source, environment read, file, network, exit, database write or message behind a small collaborator | hidden-inputs, hard-outputs | Hidden Inputs; Hard Outputs; Required Moves; Hidden Dependency Expansion; Testing Rules; Default Workflow for Legacy Changes | Owns values and effects of the environment; `legacy-code-global-encapsulator` owns the project's own statics. |
| `legacy-code-collaborator-injector` | sonnet | Turns a hard-coded collaborator into an explicit input: parameterize constructor or method, extract interface, factory method | construction-barriers, substitution-seams | Construction Problems; Constructors Doing Too Much; Dependency-Breaking Technique Index; Seam Rules; Required Moves; Hidden Dependency Expansion; Testability Improvements; Default Workflow for Legacy Changes; Handling Risky Areas | Changes how an object receives a collaborator. |
| `legacy-code-global-encapsulator` | sonnet | Wraps statics, singletons and global configuration, then migrates callers incrementally | static-and-global | Static and Global Dependencies; Dependency-Breaking Technique Index; Hidden Dependency Expansion; Default Workflow for Legacy Changes; Handling Risky Areas | Migrates many callers over steps; `legacy-code-boundary-wrapper` builds one new port. |
| `legacy-code-sprouter` | sonnet | Adds the requested behavior as a sprouted method or class or a wrap, with tests for the new unit | sprout-and-wrap | Sprout Method; Sprout Class; Wrap Method; Wrap Class; New Behavior Tests; Default Workflow for Legacy Changes; Preferred Legacy Techniques | Adds behavior; the other implementers remove barriers. |
| `legacy-code-method-extractor` | sonnet | Carves pure computation out of a large method or a handler, then isolates effects, under tests | large-methods, policy-vs-mechanism | Large Methods; UI or Framework Code; Database-Heavy Code; Dependency-Breaking Technique Index; Default Workflow for Legacy Changes; Handling Risky Areas; Legacy Refactoring Heuristics; Code Generation Rules | Reshapes existing code; `legacy-code-sprouter` leaves it alone. |
| `legacy-code-seam-cleaner` | sonnet | Retires or folds test-only seams, probes and sensing variables once safer structure exists | seams, last-resort-seams | Seam Rules; Extract and Override Call; Characterization Tests | Removes structure; every other implementer adds it. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule, its strength and the loop step behind each choice; ends non-trivial answers with one check question | Purpose; Non-Negotiable Rules; Primary Directive | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Review Checklist; Forbidden Patterns | Never changes code. |
| `pair` | Small steps, narrates the loop step, asks before anything larger than a few lines or touching public API | Default Workflow for Legacy Changes; Final Instruction; Primary Directive | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Final Instruction; Review Checklist | Brevity rules. |
| `characterize-first` | Before the first edit to code without trustworthy tests prints a safety preamble (change point, delta, preserve set, protection, first pin) and writes the pin before the change | Primary Directive; Characterization Tests; No-Safety Change; Default Workflow for Legacy Changes; New Behavior Tests; Review Checklist | A pre-edit gate on protection. |
| `explorer` | Read-only understanding mode: effect sketch, responsibility groups, open questions, candidate test points and seams, one next safe move | Test Selection and Understanding Rules; Legacy Refactoring Heuristics | Produces understanding and never a patch. It is the conversational, whole-session form: it asks and answers in chat and neither forks nor edits. `legacy-code-effect-sketch` is a bounded forked report of at most 40 lines for one named change point, and `legacy-code-scratch-refactoring` holds the rules for throwaway restructuring. |

## Confusable pairs

Model-invocable skills whose triggers could fire on the same request, and the clause that separates them. Each pair below names the other skill, in backticks, in both descriptions. The one exception, `legacy-code-construction-barriers` / `legacy-code-last-resort-seams`, is separated by the trigger itself (an object that cannot be built cheaply versus a restriction that applies only when ordinary seams are impractical) and by the opening paragraph of each body.

| Pair | Separation |
| --- | --- |
| `legacy-code-characterization-tests` / `legacy-code-focused-tests` | Pinning behavior nobody has confirmed versus choosing the level of tests for behavior the request defines. |
| `legacy-code-characterization-tests` / `legacy-code-legacy-loop` | How to pin behavior versus the order in which pinning, seam and change happen. |
| `principles` / `legacy-code-legacy-loop` | The hub: modal convention, routing to every component, final checklist, versus the order of work for one change. Both fire on "change this untested function"; the hub's description ends by pointing to `legacy-code-legacy-loop` for the order, and `legacy-code-legacy-loop`'s points back to `principles` for routing. |
| `legacy-code-legacy-loop` / `legacy-code-change-separation` | The sequence of work before a patch exists versus the intent of each hunk in the patch. |
| `legacy-code-legacy-loop` / `legacy-code-rewrite-pressure` | Doing the loop versus resisting the pull to skip it by starting over. |
| `legacy-code-rewrite-pressure` / `legacy-code-change-separation` | Whether to go big at all versus whether a small patch mixes intents. |
| `seams` / `legacy-code-substitution-seams` | Choosing and classifying any seam versus the specific techniques that make a concrete type replaceable. |
| `seams` / `legacy-code-last-resort-seams` | The default preference for explicit seams versus the conditions under which subclass and build seams are tolerated. |
| `seams` / `legacy-code-test-points` | Where to put a seam and what it is for (substitution versus sensing) versus where to observe an effect (test, interception and pinch points). |
| `legacy-code-hidden-inputs` / `legacy-code-static-and-global` | Values from the environment (clock, randomness, environment variables, thread-local state, current user) versus the project's own static singletons and global configuration. |
| `legacy-code-hidden-inputs` / `legacy-code-hard-outputs` | Things the code reads from outside versus things it does to the outside. |
| `legacy-code-hard-outputs` / `legacy-code-policy-vs-mechanism` | Putting an effect behind a collaborator versus moving a decision out of a handler or a query layer. |
| `legacy-code-construction-barriers` / `legacy-code-substitution-seams` | Where objects are created and constructed versus the types and parameters that methods receive. |
| `legacy-code-construction-barriers` / `legacy-code-static-and-global` | Instances created in the wrong place versus static access paths. |
| `legacy-code-construction-barriers` / `legacy-code-last-resort-seams` | `Extract and Override Factory Method` and `Supersede Instance Variable` are owned by the first; the subclass and test-door cautions are in the second. |
| `legacy-code-large-methods` / `legacy-code-policy-vs-mechanism` | The inside of one long body versus layers and entry points. |
| `legacy-code-large-methods` / `legacy-code-scratch-refactoring` | A real extraction kept under tests versus throwaway restructuring that produces notes. |
| `legacy-code-large-methods` / `legacy-code-sprout-and-wrap` | Reshaping old code versus adding beside it. |
| `legacy-code-test-points` / `legacy-code-scratch-refactoring` | Where to observe an effect versus understanding the code by restructuring it. |
| `legacy-code-test-points` / `legacy-code-characterization-tests` | Choosing the place to test versus writing the test that captures behavior there. |
| `legacy-code-test-points` / `legacy-code-focused-tests` | Finding the point where effects are visible versus choosing a fast, narrow test once the point is known. |

Rules skills and their workflows (different roles, not rewordings; only the rules skill is model-invocable):

| Rules skill | Workflow | What the workflow adds |
| --- | --- | --- |
| `legacy-code-characterization-tests` | `characterize` | A concrete target, an observed-results table and a stop at the first barrier. |
| `seams` | `legacy-code-find-seam` | A seam proposal for one target and one wanted test, with technique and owner. |
| `legacy-code-test-points` | `legacy-code-effect-sketch` | A sketch of effects from a given change point, in a fork. |
| `seams`, `legacy-code-last-resort-seams` | `legacy-code-seam-ledger` | A keep, fold or remove inventory of existing test-only structure, in a fork. |
| `legacy-code-change-separation` | `legacy-code-split-patch` | An ordered split of a mixed patch. |
| `legacy-code-legacy-loop` | `plan` | A written plan for one requested change. |

Reviewers and the workflows that produce a similar artifact. Each reviewer judges a change; the workflow covers a tree or a plan, and the two report different tables:

| Reviewer | Workflow | Separation |
| --- | --- | --- |
| `legacy-code-seam-reviewer` | `legacy-code-seam-ledger` | Seam register for the seams a diff adds, with findings, versus an inventory of structure already in a tree, whether or not anything changed. |
| `legacy-code-change-intent-reviewer` | `legacy-code-split-patch` | Hunk ledger with findings versus the ordered split that resolves a mixed patch. |
| `legacy-code-protection-reviewer` | `characterize` | Map of what is protected and how honestly versus the tests that close the gap for one target. |

Output style and the components that produce a similar artifact:

| Style | Component | Separation |
| --- | --- | --- |
| `explorer` | `legacy-code-effect-sketch`, `legacy-code-scratch-refactoring` | A session-long conversational mode that answers questions about unfamiliar code in chat, versus a bounded forked report for one change point, versus rules for throwaway restructuring. |

Agent pairs that share a theme and how their reports differ:

| Pair | Separation |
| --- | --- |
| `legacy-code-hidden-input-reviewer` / `legacy-code-hard-output-reviewer` | Input inventory versus effect inventory. |
| `legacy-code-hidden-input-reviewer` / `legacy-code-static-global-reviewer` | Environment values versus the project's own access paths. |
| `legacy-code-construction-reviewer` / `legacy-code-static-global-reviewer` | Construction-site table versus reach-through census. |
| `legacy-code-large-method-reviewer` / `legacy-code-policy-mechanism-reviewer` | Method map versus layer split. |
| `legacy-code-protection-reviewer` / `legacy-code-test-level-reviewer` | Whether behavior is protected versus whether the tests are the right size. |
| `legacy-code-boundary-wrapper` / `legacy-code-global-encapsulator` | One new port for an environment value or effect versus an incremental caller migration off an existing global. |
| `legacy-code-collaborator-injector` / `legacy-code-boundary-wrapper` | A class receives a collaborator it used to create versus a value or effect is moved behind a new small collaborator. |
| `legacy-code-method-extractor` / `legacy-code-sprouter` | Reshape existing code versus leave it and add beside it. |
| `legacy-code-characterization-writer` / `legacy-code-seam-cleaner` | Adds pins versus removes scaffolding. |
| `legacy-code-lead` / `legacy-code-change-intent-reviewer` | Routing versus judging a diff. |

## Coverage check against the upstream sections

Generated from the `## Source` sections of the components by reading them once the plugin was built; `docs/TRACEABILITY.md` is the validator's own view and lists direct citations of `##` headings only.

| Upstream section | Components that apply it (directly or through a subsection) |
| --- | --- |
| Purpose | explain-rule, legacy-loop, principles, mentor |
| Primary Directive | legacy-loop, plan, principles, rewrite-pressure, characterize-first, mentor, pair |
| Non-Negotiable Rules | characterization-tests, characterize, explain-rule, hidden-inputs, legacy-loop, principles, rewrite-pressure, seams, legacy-code-change-intent-reviewer, mentor |
| Default Workflow for Legacy Changes | construction-barriers, effect-sketch, find-seam, fix, hidden-inputs, legacy-loop, plan, principles, split-patch, legacy-code-boundary-wrapper, legacy-code-collaborator-injector, legacy-code-global-encapsulator, lead, legacy-code-method-extractor, sprouter, characterize-first, pair |
| Testing Strategy Rules | characterization-tests, characterize, construction-barriers, focused-tests, last-resort-seams, legacy-loop, policy-vs-mechanism, seam-ledger, static-and-global, substitution-seams, legacy-code-characterization-writer, legacy-code-construction-reviewer, legacy-code-protection-reviewer, legacy-code-seam-cleaner, sprouter, legacy-code-test-level-reviewer, characterize-first |
| Seam Rules | construction-barriers, find-seam, last-resort-seams, seam-ledger, seams, substitution-seams, legacy-code-collaborator-injector, legacy-code-seam-cleaner, legacy-code-seam-reviewer |
| Dependency Breaking Rules | audit, construction-barriers, find-seam, hard-outputs, hidden-inputs, static-and-global, legacy-code-boundary-wrapper, legacy-code-collaborator-injector, legacy-code-construction-reviewer, legacy-code-hard-output-reviewer, legacy-code-hidden-input-reviewer |
| Test Selection and Understanding Rules | change-separation, effect-sketch, focused-tests, large-methods, scratch-refactoring, split-patch, test-points, legacy-code-change-intent-reviewer, legacy-code-test-level-reviewer, explorer |
| Preferred Legacy Techniques | last-resort-seams, seam-ledger, sprout-and-wrap, legacy-code-seam-cleaner, legacy-code-seam-reviewer, legacy-code-sprout-opportunity-reviewer, sprouter |
| Dependency-Breaking Technique Index | construction-barriers, explain-rule, find-seam, large-methods, last-resort-seams, policy-vs-mechanism, seam-ledger, static-and-global, substitution-seams, legacy-code-collaborator-injector, legacy-code-global-encapsulator, legacy-code-large-method-reviewer, legacy-code-method-extractor, legacy-code-seam-reviewer, legacy-code-static-global-reviewer |
| Legacy Refactoring Heuristics | change-separation, find-seam, large-methods, policy-vs-mechanism, scratch-refactoring, split-patch, sprout-and-wrap, test-points, legacy-code-change-intent-reviewer, legacy-code-large-method-reviewer, legacy-code-method-extractor, explorer |
| Handling Risky Areas | audit, construction-barriers, hard-outputs, large-methods, policy-vs-mechanism, static-and-global, legacy-code-collaborator-injector, legacy-code-construction-reviewer, legacy-code-global-encapsulator, legacy-code-large-method-reviewer, legacy-code-method-extractor, legacy-code-policy-mechanism-reviewer, legacy-code-static-global-reviewer |
| Review Rules | audit, change-separation, fix, policy-vs-mechanism, review, split-patch, legacy-code-change-intent-reviewer, legacy-code-large-method-reviewer, lead, legacy-code-policy-mechanism-reviewer, legacy-code-protection-reviewer, legacy-code-sprout-opportunity-reviewer, strict-reviewer |
| Forbidden Patterns | audit, change-separation, characterization-tests, characterize, construction-barriers, fix, hard-outputs, hidden-inputs, review, rewrite-pressure, static-and-global, legacy-code-change-intent-reviewer, legacy-code-characterization-writer, legacy-code-global-encapsulator, legacy-code-hidden-input-reviewer, legacy-code-protection-reviewer, legacy-code-static-global-reviewer, characterize-first, strict-reviewer |
| Code Generation Rules | construction-barriers, fix, focused-tests, hard-outputs, large-methods, plan, policy-vs-mechanism, rewrite-pressure, sprout-and-wrap, static-and-global, substitution-seams, legacy-code-large-method-reviewer, legacy-code-method-extractor, legacy-code-test-level-reviewer |
| Testing Rules | characterization-tests, focused-tests, policy-vs-mechanism, legacy-code-boundary-wrapper, legacy-code-hard-output-reviewer, legacy-code-test-level-reviewer |
| Review Checklist | change-separation, checklist, principles, review, split-patch, legacy-code-change-intent-reviewer, legacy-code-final-gate, lead, characterize-first, strict-reviewer, terse |
| Final Instruction | checklist, principles, rewrite-pressure, legacy-code-final-gate, lead, pair, terse |

### Subsections

| Subsection (`###`) | Parent section | Components that cite it |
| --- | --- | --- |
| Characterization Tests | Testing Strategy Rules | characterization-tests, characterize, last-resort-seams, legacy-loop, seam-ledger, legacy-code-characterization-writer, legacy-code-protection-reviewer, legacy-code-seam-cleaner, characterize-first |
| New Behavior Tests | Testing Strategy Rules | focused-tests, sprouter, legacy-code-test-level-reviewer, characterize-first |
| Testability Improvements | Testing Strategy Rules | construction-barriers, policy-vs-mechanism, static-and-global, substitution-seams, legacy-code-collaborator-injector, legacy-code-construction-reviewer |
| What Counts as a Useful Seam | Seam Rules | seams |
| Required Behavior | Seam Rules | seams |
| Hidden Inputs | Dependency Breaking Rules | hidden-inputs, static-and-global, legacy-code-boundary-wrapper, legacy-code-hidden-input-reviewer |
| Hard Outputs | Dependency Breaking Rules | hard-outputs, legacy-code-boundary-wrapper, legacy-code-hard-output-reviewer |
| Construction Problems | Dependency Breaking Rules | construction-barriers, legacy-code-collaborator-injector, legacy-code-construction-reviewer |
| Required Moves | Dependency Breaking Rules | construction-barriers, hard-outputs, hidden-inputs, static-and-global, legacy-code-boundary-wrapper, legacy-code-collaborator-injector, legacy-code-hard-output-reviewer |
| Sprout Method | Preferred Legacy Techniques | sprout-and-wrap, legacy-code-sprout-opportunity-reviewer, sprouter |
| Sprout Class | Preferred Legacy Techniques | sprout-and-wrap, legacy-code-sprout-opportunity-reviewer, sprouter |
| Wrap Method | Preferred Legacy Techniques | sprout-and-wrap, sprouter |
| Wrap Class | Preferred Legacy Techniques | sprout-and-wrap, sprouter |
| Extract and Override Call | Preferred Legacy Techniques | last-resort-seams, seam-ledger, legacy-code-seam-cleaner, legacy-code-seam-reviewer |
| Large Methods | Handling Risky Areas | large-methods, legacy-code-large-method-reviewer, legacy-code-method-extractor |
| Static and Global Dependencies | Handling Risky Areas | static-and-global, legacy-code-global-encapsulator, legacy-code-static-global-reviewer |
| Database-Heavy Code | Handling Risky Areas | hard-outputs, policy-vs-mechanism, legacy-code-method-extractor, legacy-code-policy-mechanism-reviewer |
| UI or Framework Code | Handling Risky Areas | policy-vs-mechanism, legacy-code-method-extractor, legacy-code-policy-mechanism-reviewer |
| Constructors Doing Too Much | Handling Risky Areas | construction-barriers, legacy-code-collaborator-injector, legacy-code-construction-reviewer |
| Rewrite as the First Move | Forbidden Patterns | rewrite-pressure |
| No-Safety Change | Forbidden Patterns | characterization-tests, characterize, legacy-code-characterization-writer, legacy-code-protection-reviewer, legacy-code-sprout-opportunity-reviewer, characterize-first |
| Hidden Dependency Expansion | Forbidden Patterns | change-separation, construction-barriers, hard-outputs, hidden-inputs, static-and-global, legacy-code-boundary-wrapper, legacy-code-collaborator-injector, legacy-code-construction-reviewer, legacy-code-global-encapsulator, legacy-code-hard-output-reviewer, legacy-code-hidden-input-reviewer, legacy-code-static-global-reviewer |
| Cosmetic Refactoring Only | Forbidden Patterns | rewrite-pressure |

## Overlap review

Pairs that were close and how they were separated:

- `legacy-code-hidden-inputs` and `legacy-code-static-and-global`: the upstream hidden-input list contains both ambient values (clock, randomness, environment, thread-local state, current user) and the project's own static singletons and global configuration. The first skill keeps the values; the second keeps the access paths and their incremental migration. A static call such as a wrapper over a clock belongs to `legacy-code-hidden-inputs` because the fix is to inject the value source, not to migrate callers.
- `legacy-code-boundary-wrapper` and `legacy-code-global-encapsulator`: both create a small abstraction. The first builds one port for something that comes from or goes to the environment and wires it at the edge. The second starts from a global that already exists in many callers and moves them over in steps.
- `characterize` (skill) and `legacy-code-characterization-writer` (agent): the skill is interactive and stops at a suspicious result to ask; the agent runs unattended on a list of targets, marks suspicious results instead of asking and returns a table.
- `legacy-code-rewrite-pressure` and `legacy-code-legacy-loop`: both begin from "do not start with a rewrite". The loop skill owns the order of work; the other owns the decision when someone proposes going big and the test for "clearly safer".
- `legacy-code-last-resort-seams` and `legacy-code-construction-barriers`: `Extract and Override Factory Method` is a construction technique and is owned by `legacy-code-construction-barriers`; the cautions that apply to every subclass seam (whether an override reached from a constructor is safe in the language, which the factory-method technique itself depends on; test-only visibility; the exit) are owned by `legacy-code-last-resort-seams`.
- `legacy-code-large-methods` and `legacy-code-policy-vs-mechanism`: a long HTTP handler matches both. `legacy-code-large-methods` is about carving inside one body; `legacy-code-policy-vs-mechanism` is about where the decision lives relative to the framework entry point, the database layer and the hierarchy. `legacy-code-method-extractor` uses both because the carving step is the same.
- `legacy-code-seam-reviewer`, `legacy-code-seam-ledger` and `legacy-code-seam-cleaner`: judge new seams in a diff, inventory existing ones, retire them.

Upstream sections with no dedicated skill are covered as follows: `Purpose`, `Final Instruction` and `Review Checklist` are carried by the hub, the gate, the checklist workflow and the styles because they govern how work is reported and bounded, not how code is shaped. `Code Generation Rules` is distributed: each preferred first move lives in the barrier skill that performs it, and the preferred avoidances live in `legacy-code-rewrite-pressure` and `legacy-code-substitution-seams`.
