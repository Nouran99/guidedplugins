# Clean Code plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`.

## Design decisions

1. **Rule clusters follow the upstream sections.** Where one section is large (Function rules, Smells to detect and eliminate), it is split into several skills along the seams a reader meets in code, not along the order of the bullets.
2. **The smell catalog is distributed by family, not kept in one skill.** Every smell in the upstream list has exactly one owning skill, shown in the table below. Each owner carries the smell as a symptom, a detection recipe and a treatment. `smell-hunt` walks all families, and `smell-scanner` produces the mechanical metrics.
3. **Concurrency and boundaries are skills and agents of their own.** They change the shape of the work (tests, lifecycle, adapters) more than any other cluster.
4. **Tests are split into two skills.** `clean-tests` is about what a good test looks like; `tdd-discipline` is about when tests are written, in what order, and whether the change is protected at all.
5. **The book's own bias, "working code is not clean code", is balanced by its own brake.** Every cleanup component (`boy-scout`, `refactorer`, `scope-guard`) carries the proportionality rule: cleanup stays inside the touched code.
6. **Model-invocable skills are capped at 20.** There are 19. Everything that is a procedure with arguments is a manual skill.
7. **Reviewers own one concern and have their own output shape.** A naming reviewer reports a vocabulary table, a concurrency reviewer reports a shared-state inventory, a test-gap reviewer reports a behavior-to-test map.

## Smell catalog ownership

Every item in the upstream list `Smells to detect and eliminate` is owned by exactly one skill. Other skills may mention it and point to the owner.

| Family | Smell | Owner skill |
| --- | --- | --- |
| Names | vague or misleading names | `naming` |
| Names | functions that require understanding an algorithm before the name can be trusted | `naming` |
| Names | magic numbers without named meaning | `naming` |
| Functions | oversized functions | `function-shape` |
| Functions | mixed abstraction levels | `function-shape` |
| Functions | deep nesting | `function-shape` |
| Functions | negative conditionals that obscure intent | `function-shape` |
| Functions | hidden side effects | `function-contracts` |
| Functions | boolean control flags | `function-contracts` |
| Functions | long parameter lists | `function-contracts` |
| Functions | hidden logical dependencies | `function-contracts` |
| Comments | comment-heavy code that should be refactored instead | `comments` |
| Objects | transitive navigation through object internals | `data-and-objects` |
| Objects | oversized classes or modules | `class-design` |
| General design: redundancy | duplicated logic | `smells-redundancy` |
| General design: redundancy | dead code and unused abstractions | `smells-redundancy` |
| General design: redundancy | unnecessary indirection | `smells-redundancy` |
| General design: redundancy | accidental complexity | `smells-redundancy` |
| General design: coupling | coupling that spreads change broadly | `smells-coupling` |
| General design: coupling | artificial coupling between unrelated concepts | `smells-coupling` |
| General design: coupling | base classes depending on derivatives | `smells-coupling` |
| General design: coupling | code at the wrong level of abstraction | `smells-coupling` |
| General design: coupling | excessive conditionals that should be isolated or polymorphic | `smells-coupling` |
| General design: surprise | unimplemented obvious behavior | `smells-surprise` |
| General design: surprise | incorrect boundary behavior | `smells-surprise` |
| General design: surprise | overridden safeties | `smells-surprise` |
| Tests | fragile tests | `clean-tests` |
| Tests | environment-dependent tests without need | `clean-tests` |
| Tests | ignored tests and insufficient boundary tests | `tdd-discipline` |
| Tests | build or tests requiring more than one manual step | `tdd-discipline` |

## Skills: model-invocable (19)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Priority and behavior; Core clean code principles; Review checklist; Hard rules | It decides which other component to use; it holds no cluster rules itself. |
| `naming` | Intention-revealing names, one word per concept, name smells, magic numbers | Naming rules; Smells to detect and eliminate | `comments` removes text that a better name would replace; `naming` is where that better name is made. |
| `function-shape` | Size, one thing, one abstraction level, top-down order, nesting, conditionals | Function rules; Formatting and structure; Smells to detect and eliminate | `function-contracts` is about what crosses the function boundary (arguments, effects); `function-shape` is about the body. |
| `function-contracts` | Parameters, flags, output parameters, hidden side effects, command/query separation, hidden call-order dependencies | Function rules; Hard rules; Smells to detect and eliminate | It judges the signature and effects, never the length or nesting of the body. |
| `comments` | Allowed comment categories, deleting noise, comment-heavy code, TODO policy | Comment rules; Smells to detect and eliminate | `naming` and `function-shape` fix the code; `comments` decides what text may remain after they have. |
| `formatting` | Vertical ordering, proximity, file size, indentation, brittle alignment, formatter first | Formatting and structure | `function-shape` orders statements inside one function; `formatting` orders functions and concepts across a file. |
| `data-and-objects` | Objects versus data carriers, hiding representation, train wrecks, DTOs | Objects, modules, and data structures; Smells to detect and eliminate | `class-design` sizes and splits classes; `data-and-objects` decides what a type exposes. |
| `class-design` | Small classes, single responsibility, cohesion, change locality, composition, constructors | Class and module design; Smells to detect and eliminate | It judges the whole class; `data-and-objects` judges its surface. |
| `error-handling` | Deliberate failure design, happy path, context, error types, null, cleanup | Error handling; Function rules | `boundaries` translates foreign failures at the edge; `error-handling` designs failures inside. |
| `boundaries` | Adapters around third-party code, narrow interfaces, learning tests, not-yet-existing dependencies | Boundaries and external dependencies; Objects, modules, and data structures | `system-construction` is about who creates objects; `boundaries` is about what vendor code the core may see. |
| `system-construction` | Construction versus use, composition root, factories, cross-cutting concerns, executable architecture, DSLs | System construction rules | It never discusses vendor types (that is `boundaries`); it discusses where `new` and wiring live. |
| `clean-tests` | What a good test looks like: one idea, readable, deterministic, isolated, self-checking, fragile and environment-dependent test smells | Tests; TDD and clean test rules; Smells to detect and eliminate | `tdd-discipline` is about whether and when tests exist; `clean-tests` is about the quality of one that does. |
| `tdd-discipline` | Failing test first, no unjustified production behavior, bug-fix tests, coverage as a signal, ignored tests, boundary tests, one-step build | Tests; TDD and clean test rules; Smells to detect and eliminate; Change Process | It never judges test style, only whether behavior is protected. |
| `concurrency` | Whether to add concurrency, shared state, lock scope, lifecycle, execution model, pluggable policy, testing under variation | Concurrency and async work | Isolated cluster; only skill that treats timing as a correctness input. |
| `refactoring-steps` | Small safe steps, behavior preservation, make it work then right, rename, extract, inline, stop conditions | Refactoring rules; Change Process | `emergent-design` decides what shape to aim for; `refactoring-steps` is how to move without breaking. |
| `emergent-design` | Four-criteria tie-breaker, working drafts, no grand redesign, boring solutions, no premature optimization, dependencies | Emergent design and successive refinement; Implementation preferences; Core clean code principles | It chooses between designs; `refactoring-steps` executes the move. |
| `smells-redundancy` | Duplication, dead code, unused abstractions, indirection, accidental complexity | Smells to detect and eliminate; Refactoring rules | It removes things; `smells-coupling` rearranges dependencies. |
| `smells-coupling` | Change that spreads, artificial coupling, base-on-derivative, wrong abstraction level, repeated conditionals | Smells to detect and eliminate; Class and module design; Objects, modules, and data structures | It is about dependency direction and placement; `smells-redundancy` is about waste. |
| `smells-surprise` | Obvious behavior missing, boundary behavior wrong, safeties overridden, implicit magic | Smells to detect and eliminate; Core clean code principles; Implementation preferences | It is about code that does not do what a reader expects; the other two smell skills are about structure. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review checklist; Hard rules; Output Expectations | `audit` scans a whole tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Repository or directory health scan, ranked hot spots, at most 40 lines | Smells to detect and eliminate; Review checklist; Priority and behavior | `smell-hunt` is smell-catalog driven and takes a family; `audit` is cluster driven and gives a health picture. |
| `plan` | no | no | Plan a non-trivial change with the Change Process, including a cleanup budget | Change Process; Priority and behavior; Tests | `successive-refinement` executes a draft-and-refine loop; `plan` only plans. |
| `explain-rule` | no | no | Explain one rule: modal strength, reason, check, example, exception | Priority and behavior; Core clean code principles | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the book's final checklist with yes/no/not-applicable and a next action for each no | Review checklist; Hard rules | `final-gate` is the isolated strict pass/fail gate; `checklist` is the in-session interactive walk with next actions. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Change Process; Output Expectations; Refactoring rules | `boy-scout` finds its own targets; `fix` only resolves given findings. |
| `smell-hunt` | yes | no | Walk the smell families over a scope and map each hit to a treatment skill | Smells to detect and eliminate | `audit` is broad health; `smell-hunt` is symptom to treatment. |
| `boy-scout` | no | yes | Leave touched code cleaner: one worthwhile cleanup per touched area, inside the touched code | Priority and behavior; Emergent design and successive refinement; Hard rules | `fix` and `refactorer` need findings or a target; `boy-scout` chooses the target from the diff and enforces the budget. |
| `extract-till-you-drop` | no | yes | Decompose one long function into single-level functions, step by step, with tests | Function rules; Refactoring rules | `function-extractor` is the delegated agent for big jobs; this is the in-session loop with a stop rule against fragments. |
| `successive-refinement` | no | yes | Draft until it works, then refine in named rounds with tests green | Emergent design and successive refinement; Refactoring rules | `plan` plans; this performs rounds on a working draft. |
| `learning-tests` | no | yes | Pin down the behavior of a dependency already in the project with focused tests, then propose the adapter interface | Boundaries and external dependencies; Tests | `adapter-builder` builds the adapter and reuses these tests; this writes the exploratory tests first and builds nothing else. |
| `vocabulary-audit` | yes | no | Build the concept-to-term table, find synonym drift and overloaded words | Naming rules | `naming-reviewer` reviews names in a diff; this scans a tree for vocabulary conflicts. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to specialists and skills; does not review | principles (on purpose: the hub's routing table is the router's map) | Priority and behavior; Review checklist | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the final checklist on the working diff and returns PASS or FAIL | none (the checklist and hard rules are listed in its own body, so the hub is not paid for on every gate run; it can Read `mini.md` when an item is in doubt) | Review checklist; Hard rules; Output Expectations | Binary gate with evidence; reviewers return ranked findings. |
| `naming-reviewer` | sonnet | Names, vocabulary table, magic numbers | naming | Naming rules | Output is a vocabulary table; `comment-reviewer` owns comments. |
| `function-reviewer` | sonnet | Size, levels, nesting, conditionals in function bodies | function-shape | Function rules | Judges bodies; `contract-reviewer` judges signatures and effects. |
| `contract-reviewer` | sonnet | Parameters, flags, effects, command/query separation, surprises | function-contracts, smells-surprise | Function rules; Hard rules | Output is a signature ledger. |
| `comment-reviewer` | sonnet | Comment ledger: keep, rewrite, delete, replace with code | comments | Comment rules | Every comment gets a disposition. |
| `layout-reviewer` | sonnet | Vertical order, proximity, file size, formatter drift | formatting | Formatting and structure | Looks at arrangement, not at logic. |
| `object-design-reviewer` | sonnet | Object versus data carrier, train wrecks, exposed representation | data-and-objects | Objects, modules, and data structures | Output is a type classification; `class-design-reviewer` judges size and cohesion. |
| `class-design-reviewer` | sonnet | Responsibilities, cohesion, change locality, coupling smells | class-design, smells-coupling | Class and module design; Smells to detect and eliminate | Output is a responsibility statement per class. |
| `error-handling-reviewer` | sonnet | Failure paths, null returns, error types, cleanup | error-handling | Error handling | Output is a failure-path map. |
| `boundary-reviewer` | sonnet | Vendor types leaking into core logic | boundaries | Boundaries and external dependencies | Output is a leak report; `construction-reviewer` looks at wiring. |
| `construction-reviewer` | sonnet | Construction inside use, wiring placement, cross-cutting clutter | system-construction | System construction rules | Output is a construction-site list. |
| `test-quality-reviewer` | sonnet | Quality of existing and new tests | clean-tests | Tests; TDD and clean test rules | Judges tests that exist; `test-gap-reviewer` finds tests that do not. |
| `test-gap-reviewer` | sonnet | Changed behavior without protection, ignored tests, boundary cases | tdd-discipline | Tests; TDD and clean test rules; Change Process | Output is a behavior-to-test map. |
| `concurrency-reviewer` | sonnet | Shared state, lock scope, lifecycle, execution model | concurrency | Concurrency and async work | Output is a shared-state inventory. |
| `simplicity-reviewer` | sonnet | Unearned abstraction, dependencies, duplication, speculation | emergent-design, smells-redundancy | Emergent design and successive refinement; Implementation preferences; Smells to detect and eliminate | Removes weight; `class-design-reviewer` rearranges it. |
| `scope-guard` | sonnet | Classifies every hunk as required, enabling cleanup, opportunistic cleanup or out of scope | refactoring-steps | Priority and behavior; Hard rules; Refactoring rules | Output is a scope ledger; the only reviewer that compares the diff to the request. |
| `smell-scanner` | haiku | Mechanical census: function lengths, parameter counts, nesting, flags, commented-out code, skipped tests | none (the searches are in its body; the family skills are judgment, which it does not do) | Smells to detect and eliminate | Reports numbers and locations only; makes no judgments. |
| `refactorer` | sonnet | Behavior-preserving structural change in small steps | refactoring-steps | Refactoring rules; Change Process | Takes a finding list; `function-extractor` takes one function. |
| `test-writer` | sonnet | Writes failing-first tests for changes and bug fixes | clean-tests, tdd-discipline | Tests; TDD and clean test rules | Writes tests only; never edits production code. |
| `function-extractor` | sonnet | Decomposes one long function with the stop rule against fragments | function-shape | Function rules; Refactoring rules | One function in, a set of single-level functions out. |
| `adapter-builder` | sonnet | Builds a narrow local adapter around a dependency, adopting the interface and tests from `learning-tests` when they exist and adding only the missing tests | boundaries | Boundaries and external dependencies | Edits the boundary and its callers only; reviews nothing; does not redo exploratory tests. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Priority and behavior; Output Expectations | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review checklist; Hard rules | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Change Process; Refactoring rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Output Expectations | Brevity rules. |
| `smell-first` | Before any edit names the smells in the touched code and ties each edit to a named smell | Smells to detect and eliminate; Change Process | Diagnosis ledger precedes every change. |
| `campsite` | Finishes each task with a Campsite block: what was left cleaner, what was deliberately not touched | Priority and behavior; Emergent design and successive refinement; Hard rules | Report is about cleanup budget, not about diagnosis. Named differently from the `boy-scout` skill on purpose: the style only changes the report format, the skill performs a cleanup on demand. |

## Coverage check against the upstream sections

| Upstream section | Components that apply it |
| --- | --- |
| Priority and behavior | principles, plan, audit, explain-rule, boy-scout, scope-guard, lead, mentor, campsite |
| Core clean code principles | principles, explain-rule, emergent-design, smells-surprise |
| Naming rules | naming, vocabulary-audit, naming-reviewer |
| Function rules | function-shape, function-contracts, error-handling, extract-till-you-drop, function-reviewer, contract-reviewer, function-extractor |
| Comment rules | comments, comment-reviewer |
| Formatting and structure | formatting, function-shape, layout-reviewer |
| Objects, modules, and data structures | data-and-objects, boundaries, smells-coupling, object-design-reviewer |
| Class and module design | class-design, smells-coupling, class-design-reviewer |
| Error handling | error-handling, error-handling-reviewer |
| Boundaries and external dependencies | boundaries, learning-tests, boundary-reviewer, adapter-builder |
| System construction rules | system-construction, construction-reviewer |
| Tests | clean-tests, tdd-discipline, plan, learning-tests, test-quality-reviewer, test-gap-reviewer, test-writer |
| TDD and clean test rules | clean-tests, tdd-discipline, test-quality-reviewer, test-gap-reviewer, test-writer |
| Concurrency and async work | concurrency, concurrency-reviewer |
| Refactoring rules | refactoring-steps, smells-redundancy, fix, successive-refinement, extract-till-you-drop, refactorer, function-extractor, scope-guard, pair |
| Emergent design and successive refinement | emergent-design, successive-refinement, boy-scout, simplicity-reviewer, campsite |
| Smells to detect and eliminate | every smell-family skill, smell-hunt, audit, smell-scanner, smell-first |
| Change Process | plan, fix, refactoring-steps, tdd-discipline, refactorer, test-gap-reviewer, pair, smell-first |
| Implementation preferences | emergent-design, smells-surprise, simplicity-reviewer |
| Review checklist | principles, review, audit, checklist, final-gate, lead, strict-reviewer |
| Output Expectations | review, fix, final-gate, terse, mentor |
| Hard rules | principles, review, checklist, function-contracts, boy-scout, scope-guard, final-gate, strict-reviewer |

## Confusable pairs

Model-invocable skills whose descriptions could match the same request. Both descriptions of each pair carry a clause that names the other (`... is /clean-code:<other>`), so Claude can pick by the discriminator instead of loading both.

| Pair | A request that matches both | Discriminator |
| --- | --- | --- |
| `function-contracts` / `smells-surprise` | "This `getUser` also creates a record" or "this name lies" | `function-contracts` judges the signature and the effects it declares (parameters, flags, command/query, order); `smells-surprise` judges observed behavior against what the name and types promise (edge inputs, defaults, disabled checks). |
| `clean-tests` / `tdd-discipline` | "Write a test for this bug" | `tdd-discipline` decides whether and when a test must exist (red first, bug-fix test, skipped tests); `clean-tests` judges how the test is written once it does. |
| `emergent-design` / `smells-redundancy` | "Do we need this layer?" | `smells-redundancy` removes things proven redundant by search (duplicates, dead code, pass-through wrappers); `emergent-design` chooses between two designs or decides whether to add structure. |
| `class-design` / `smells-coupling` / `data-and-objects` | "This class is a mess" | `class-design`: the responsibilities and cohesion of one class; `smells-coupling`: change that spreads across classes and files; `data-and-objects`: what the class exposes. |
| `function-shape` / `comments` | "This function needs a comment to separate its phases" | `function-shape` restructures the body so the comment is unnecessary; `comments` decides which text may stay once the code is as clear as it can be. |
| `function-shape` / `function-contracts` | "This function is long and takes a flag" | Body (size, levels, nesting) versus signature and effects. |
| `naming` / `comments` | "This comment explains what the variable means" | Fix the name first (`naming`); only what survives is judged by `comments`. |
| `boundaries` / `system-construction` | "The service builds its own SDK client" | Which vendor types the core may see (`boundaries`) versus where objects are created and wired (`system-construction`). |
| `data-and-objects` / `class-design` | "This type has getters for everything" | Exposed surface versus size and responsibility. |
| `tdd-discipline` / `refactoring-steps` | "I finished the refactor, is it covered?" or "restructure this safely" | `tdd-discipline` decides whether behavior is protected by tests and in what order tests and code are written; `refactoring-steps` is the sequence of behavior-preserving moves once a safety net exists. The trigger `finishing a refactor` was removed from `tdd-discipline`, and `refactoring-steps` now says it is for restructuring without behavior change. |
| `concurrency` / `clean-tests` | "This test fails one run in twenty" | `concurrency` when the code under test uses threads, async tasks or timers; `clean-tests` when the flakiness comes from order, clock, shared files or the environment. |
| `error-handling` / `boundaries` | "The payment SDK throws and we catch it everywhere" | `error-handling` designs failure inside your own code (types, messages, null, cleanup); `boundaries` decides which vendor exceptions and types the core may see and translates them at the adapter. |

## Overlap review

Pairs among the other component types, and how they were separated:

- `smells-redundancy` vs `emergent-design`: the former is a catalog of removable things with detection recipes, the latter is the decision rule for choosing between designs. `simplicity-reviewer` preloads both and reviews a diff against them.
- `boy-scout` (skill), `campsite` (style) and `scope-guard` (agent): the skill acts, the style reports, the agent audits whether the budget was respected.
- `checklist` and `final-gate`: interactive walk with next actions versus isolated PASS/FAIL with evidence.
- `review` and `lead`: `review` produces findings; `lead` only decides who should.
- `audit`, `smell-hunt` and `smell-scanner`: the same detection ideas (long functions, nesting, flags, skipped tests, forwarding wrappers) feed all three on purpose, because a scan that cannot be done from another file's text has to be self-contained (forked skills are the subagent's whole task). They differ in output: a health rating per cluster (`audit`), a smell-to-treatment table (`smell-hunt`), a raw census with no judgment (`smell-scanner`). When a recipe changes, change it in all three.
- The final checklist is walked in four places on purpose: `checklist` (interactive, with next actions), `final-gate` (isolated PASS or FAIL), step 4 of `review` (one pass at the end of a findings review) and the `strict-reviewer` style (report format). They share the list, not the behavior.

Upstream sections with no dedicated skill are covered as follows: `Output Expectations` and `Hard rules` are enforced by gates and workflows rather than a skill of their own, because they govern how work is reported and bounded, not how code is shaped.
