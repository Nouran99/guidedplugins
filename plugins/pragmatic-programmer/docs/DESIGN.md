# The Pragmatic Programmer plugin: component map

This file is the plan the components were built from, kept in step with what was built. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`; `###` headings are cited where a component owns exactly one subsection. A `Source` bullet with a note means only that part of the section applies.

## Design decisions

1. **The rule set is a list of habits, not a catalog, so the split follows the decision a developer is making.** The upstream full file has 26 `##` sections, most of them four to eight one-line rules. Clusters are cut along the moments a reader meets in work: where does this fact live, what else must change, what do I build first, what do I keep, how will I know, what is assumed, how does a failure travel, who releases this, who can touch this state, how do I explain it, why does it fail. Two sections that mix themes (`Resource and Coupling Rules`, `Reversibility, Domain Languages, and Requirements`) are cut by theme and each theme is owned by exactly one skill.
2. **The book is general, so the plugin stays general.** It does not restate what the code-level plugins own (naming and function shape in `clean-code`, construction detail in `code-complete`, safe change sequencing in `refactoring`, production failure defenses in `release-it`). Where this book touches the same ground (failure handling, cleanup, state) the skill takes the pragmatic angle: ownership, classification, containment, visible assumptions.
3. **Debugging is one source rule, so it is built on Added judgment, clearly labelled.** The source gives the sequence (reproduce, observe, isolate, explain, fix, verify) and two compact-checklist triggers (a human-found bug gets a regression test; unexplained working behavior is proved before it is relied on). `debugging` states those as rules and tags every technique beyond them `[Added judgment]`; `debug-session` is the workflow that records the evidence; `bug-fixer` is the implementer.
4. **Rule provenance is marked inline.** Every numbered rule in a topical skill carries a tag right after its statement: `[MUST]`, `[SHOULD]` or `[MUST NOT]` (the source's modal strength, with its qualifiers such as "where practical"), `[Added judgment]` (this plugin's heuristic or threshold), or `[Compact checklist]` (phrasing that exists only in `mini.md` or `nano.md`).
5. **Model-invocable skills are capped at 20.** There are exactly 20: the hub plus 19 topical skills. Everything that is a procedure with arguments is manual (12 manual skills, 3 of them forked).
6. **Rule skills and their workflows are separate roles, never rewordings.** `debugging` holds rules, `debug-session` produces an evidence record. `prototypes` holds the decision rules, `prototype-charter` writes the charter. The pairs are listed below so no one has to guess which to use.
7. **Reviewers own one concern and report a different artifact.** A duplication reviewer reports a touched-fact ledger, a contract reviewer a contract table, a resource reviewer an acquire/release ledger, a slice reviewer a layer map. No two reviewers share a report shape.
8. **Implementers are separated by what they change**: a defect (`bug-fixer`), duplicated knowledge (`knowledge-consolidator`), manual steps (`automation-scripter`), implicit assumptions (`contract-writer`). There is no generic test-writer: the regression test belongs to the bug fix, and the test-portfolio concern is a reviewer.
9. **The book's own brake is built in.** The source is explicit that quality has a stopping point and that rituals without benefit are forbidden. `ownership`, `plan`, `fix`, `tidy-touched`, every implementer and the `pair` and `terse` styles carry a proportionality rule: change what the request and the touched area justify, and stop.
10. **Numbers are never presented as rules of the book.** The source gives no thresholds, no time limits and no counts. Any number in a component is an example or is labelled `[Added judgment]`.

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Core Pragmatic Principles; Code Generation Rules; Review Checklist; Final Instruction | It decides which component to use; it holds no cluster rules. |
| `ownership` | Own the result: surface trade-offs and risks, negotiate and bound quality, stop at good enough, drop rituals without benefit | Own the Result; Named Pragmatic Habits; Cargo-Cult Process; Project and Team Rules; Primary Directive (ritual rule only) | `broken-windows` decides what decay to fix in touched code; `ownership` decides how far to go and how to report it. |
| `broken-windows` | Small decay in touched code: fix when cheap, contain visibly when not, never normalize; temporary hacks need an exit | Broken Windows Rule; Think Beyond the Local Edit; Named Pragmatic Habits (entropy, boiled frog); Review Checklist | `ownership` has the stopping rule; this skill has the fix-or-contain decision for specific decay. |
| `dry-knowledge` | One authoritative owner per fact; derive, generate, validate or trace the other representations | DRY Rules; Knowledge Duplication; Review Rules; Code Generation Rules | `generators-and-dsls` is about tools that produce copies; this is about choosing the owner among copies that exist. |
| `orthogonality` | Independent components, no overlapping responsibilities, policy vs mechanism, data vs presentation, orchestration vs computation | Orthogonality Rules; Non-Orthogonal Design; Review Rules; Code Generation Rules | `shy-code` is about reach and call order inside collaborations; `orthogonality` is about module boundaries and the ripple of one change. |
| `shy-code` | Reveal only what is needed, Law of Demeter, temporal coupling, blackboard coordination only when earned | Resource and Coupling Rules | It never discusses module boundaries or global state; it judges how one object reaches another and in what order. |
| `tracer-bullets` | Thin end-to-end slice first, refine from feedback, small increments, honest estimates, risk visible early | Tracer Bullets and Iterative Delivery; Estimation and Increment Rules; Code Generation Rules | `prototypes` is for a disposable experiment; a tracer slice is the skeleton that is kept and grown. |
| `prototypes` | What a prototype proves and does not, isolation, never silently production, carry forward only what deserves to survive | Prototyping Rules; Prototype Fossilization; Tracer Bullets and Iterative Delivery | `tracer-bullets` builds the kept path; `prototypes` governs the throwaway and its graduation. |
| `reversible-choices` | Keep volatile decisions reversible: vendors, platforms, databases, deployment, policies, formats; plain text, versioned formats, no unjustified lock-in | Reversibility, Domain Languages, and Requirements; Favor Adaptability; Text and Data Rules | `orthogonality` separates concerns inside the code; this skill keeps decisions that may change cheap to change. |
| `requirements` | Dig for the real need, separate need from solution, avoid the specification trap, respect informed hesitation | Reversibility, Domain Languages, and Requirements | `tracer-bullets` plans how to deliver; `requirements` decides what is actually being asked. |
| `automation` | Script repeatable work, align local with shared automation, no hand-done scriptable tasks, tooling leverage | Automation Rules; Manual Everything; Tooling Rules; Basic Tool Rules; DRY Rules | `feedback-loops` is about how fast and how visibly the signal arrives; `automation` is about whether repeated work is a script. |
| `feedback-loops` | Shorten change-to-signal time, run relevant tests early, fail visibly, fix slow or flaky paths instead of skipping | Feedback Loop Rules; Testing Rules | `test-portfolio` decides which kinds of tests exist; `feedback-loops` decides how quickly and clearly they speak. |
| `test-portfolio` | Which kinds of test a change needs, contract-aligned tests, regression tests for human-found bugs, testing the tests | Testing Rules; Project and Team Rules | It never judges speed; it judges whether the behavior and the failure modes are protected at all. |
| `contracts` | Make assumptions explicit in code: preconditions, postconditions, invariants, assertions, no nonsense values | Design by Contract and Assertions; Review Rules; Code Generation Rules | `error-recovery` is about how a failure that already happened travels; `contracts` defines what counts as one. |
| `error-recovery` | Detect near the source, keep context, classify retryable, recoverable and permanent failures, contain without collapse | Error Handling and Recovery; Design by Contract and Assertions | It starts after a failure exists; `contracts` states the obligations, `resource-discipline` owns cleanup. |
| `resource-discipline` | Finish what you start, release on every path in opposite order, local ownership, understand algorithmic growth | Resource and Coupling Rules | `shared-state` is about who may mutate; this is about who must release and how cost grows. |
| `shared-state` | Treat shared mutable state as expensive, prefer immutability and isolation, visible concurrency assumptions, async only when earned | State and Concurrency Rules; Orthogonality Rules | `orthogonality` leaves globals and ambient context to this skill; `resource-discipline` owns release of locks, this owns whether they should exist. |
| `code-communication` | Names, comments, docs, commit messages, scripts and tests that communicate intent and rationale | Naming and Communication Rules; Project and Team Rules; Review Rules | `ownership` covers what to tell the user about a decision; this covers the artifacts that stay in the repository. |
| `debugging` | Reproduce, observe, isolate, explain, fix, verify; no guessing, no blaming tools; prove unexplained working behavior | Basic Tool Rules | `error-recovery` designs failure handling; `debugging` finds why a defect happens. |
| `generators-and-dsls` | Generated code, scaffolds, small domain languages, metaprogramming: keep the spec authoritative and understand the output | Basic Tool Rules; Reversibility, Domain Languages, and Requirements; Resource and Coupling Rules | `dry-knowledge` chooses owners among existing copies; this skill governs tools and languages that create or hide copies. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules, concern by concern, and report ranked findings | Review Rules; Review Checklist; Forbidden Patterns | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Repository or directory scan, rating each concern, at most 40 lines | Review Rules; Forbidden Patterns | `knowledge-map` and `manual-step-hunt` each follow one concern deeply; `audit` samples all of them. |
| `plan` | no | no | Plan a non-trivial change: need, owners of facts, slice, reversible decisions, feedback, automation, risks | Code Generation Rules; Primary Directive; Estimation and Increment Rules | `tracer-plan` plans one new capability as a thin slice; `plan` plans any change across all concerns. |
| `explain-rule` | no | no | Explain one rule: strength, reason, check, example, exceptions | Purpose; Primary Directive | The only manual skill that teaches instead of reporting findings. |
| `checklist` | no | no | Walk the review checklist with yes, no or n/a and a next action for each no | Review Checklist | `final-gate` is the isolated strict gate; `checklist` is the interactive walk. |
| `fix` | no | yes | Resolve given findings with the smallest change, run tests, never commit | Code Generation Rules; Testing Rules; Feedback Loop Rules | `tidy-touched` finds its own targets; `fix` only resolves given findings. |
| `tracer-plan` | no | no | Define the thinnest real end-to-end slice for a new capability, what it proves, and the increments after it | Tracer Bullets and Iterative Delivery; Estimation and Increment Rules; Code Generation Rules | `plan` is general; this produces one slice definition with a proving command. |
| `knowledge-map` | yes | no | Inventory system facts and every place each is represented; propose owners | DRY Rules; Knowledge Duplication; Review Rules | `knowledge-duplication-reviewer` judges the facts a diff touches; this inventories a tree whether or not anything changed, and picks its own facts. |
| `manual-step-hunt` | yes | no | Find manual rituals, README step lists, local-versus-CI divergence and hidden environment assumptions | Automation Rules; Manual Everything; Tooling Rules; Cargo-Cult Process | `audit` rates automation as one concern among many; `automation-reviewer` judges the procedures a diff touches; this sweeps the scripts, docs and CI definitions of a tree whether or not anything changed. |
| `debug-session` | no | no | Walk one defect through the six debugging steps and record the evidence before any fix | Basic Tool Rules; Feedback Loop Rules | `debugging` holds the rules; this produces the record and stops at the explanation unless a fix is requested. |
| `prototype-charter` | no | no | Write or audit a prototype charter: question, proof, shortcuts, isolation, and the fate of each artifact | Prototyping Rules; Prototype Fossilization; Tracer Bullets and Iterative Delivery | `prototypes` holds the rules; the charter is the artifact and the graduation review. |
| `tidy-touched` | no | yes | Fix the cheap decay in the code a change touched and write containment notes for the rest | Broken Windows Rule; Think Beyond the Local Edit; Review Checklist | `fix` needs a findings list; `tidy-touched` chooses targets from the diff and enforces the budget. |

## Subagents (20)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Primary Directive; Review Checklist; Review Rules | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the review checklist on the working diff and returns PASS or FAIL | principles | Review Checklist; Final Instruction | Binary gate with evidence; reviewers return ranked findings. |
| `knowledge-duplication-reviewer` | sonnet | Touched-fact ledger: the facts a diff or named files touch, what the change did to each, other copies, whether they are in sync, proposed owner | dry-knowledge | DRY Rules; Knowledge Duplication | Judges a change and hands a whole-tree inventory to `knowledge-map`; `coupling-reviewer` looks at change ripple. |
| `coupling-reviewer` | sonnet | Ripple map, responsibility overlap, reach-through and call-order coupling | orthogonality, shy-code | Orthogonality Rules; Non-Orthogonal Design; Resource and Coupling Rules | Output is what must change together; `shared-state-reviewer` owns mutable state. |
| `contract-reviewer` | sonnet | Contract table per routine and where each part is enforced | contracts | Design by Contract and Assertions | Judges stated obligations; `failure-path-reviewer` judges how failures travel. |
| `failure-path-reviewer` | sonnet | Failure classification, context kept, containment boundary | error-recovery | Error Handling and Recovery; Design by Contract and Assertions | Output is a failure map; it does not define contracts. |
| `resource-reviewer` | sonnet | Acquire and release ledger plus growth notes | resource-discipline | Resource and Coupling Rules | Output is a ledger of lifetimes; `shared-state-reviewer` is about mutation. |
| `shared-state-reviewer` | sonnet | Inventory of shared mutable state, guards and ambient reads | shared-state | State and Concurrency Rules; Orthogonality Rules | Output is a state inventory; `resource-reviewer` owns release. |
| `automation-reviewer` | sonnet | Touched-step ledger: the procedures and scripts a diff or named files touch, what the change did to each, script alignment | automation | Automation Rules; Manual Everything; Tooling Rules | Judges a change and hands a whole-repository sweep to `manual-step-hunt`; `feedback-loop-reviewer` looks at signal latency. |
| `feedback-loop-reviewer` | sonnet | Signal table: latency class, flakiness, position in the critical path | feedback-loops | Feedback Loop Rules; Testing Rules | Looks at speed and visibility; `test-portfolio-reviewer` looks at coverage of kinds. |
| `test-portfolio-reviewer` | sonnet | Behavior-to-test matrix over the kinds of test the source names | test-portfolio | Testing Rules; Project and Team Rules | Looks at what is protected; it never rates speed. |
| `reversibility-reviewer` | sonnet | Commitment register: hard-coded volatile choices and reversal cost | reversible-choices | Reversibility, Domain Languages, and Requirements; Text and Data Rules; Favor Adaptability | Looks at decisions that may change; `coupling-reviewer` looks at module boundaries. |
| `provenance-reviewer` | sonnet | Provenance ledger of prototype, scaffold, generated and tool-derived code | prototypes, generators-and-dsls | Prototyping Rules; Prototype Fossilization; Basic Tool Rules | Asks where trust in a piece of code comes from; `slice-reviewer` asks how much of the path is real. |
| `slice-reviewer` | sonnet | Layer map of a plan or change: real, stubbed or absent, and the proving command | tracer-bullets | Tracer Bullets and Iterative Delivery; Estimation and Increment Rules; Code Generation Rules | Reviews delivery shape, not code defects. |
| `communication-reviewer` | sonnet | Artifact ledger: does each name, comment, message, script and test carry intent | code-communication | Naming and Communication Rules; Project and Team Rules | Looks at written artifacts; `decay-reviewer` looks at neglected ones. |
| `decay-reviewer` | sonnet | Decay register of the touched area: fix, contain or leave | broken-windows | Broken Windows Rule; Think Beyond the Local Edit | Looks at neglect in touched code; it does not judge design. |
| `bug-fixer` | sonnet | Implementer: reproduce with a failing test, explain, smallest fix, verify | debugging | Basic Tool Rules; Feedback Loop Rules | Starts from a symptom; `knowledge-consolidator` starts from a known duplication. |
| `knowledge-consolidator` | sonnet | Implementer: move copies of a fact onto one owner in test-backed steps | dry-knowledge | DRY Rules; Knowledge Duplication; Code Generation Rules | Behavior-preserving; `bug-fixer` changes behavior to fix a defect. |
| `automation-scripter` | sonnet | Implementer: replace a manual ritual with a versioned, inspectable script | automation | Automation Rules; Text and Data Rules; Tooling Rules; Manual Everything | Writes scripts and build targets; it does not change product code. |
| `contract-writer` | sonnet | Implementer: encode assumptions the code already makes as checks, types and tests | contracts | Design by Contract and Assertions | Encodes existing assumptions; it does not add new business rules. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice and its strength, ends non-trivial answers with one check question | Purpose; Primary Directive | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Review Checklist; Forbidden Patterns | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Estimation and Increment Rules; Feedback Loop Rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Named Pragmatic Habits; Naming and Communication Rules | Brevity rules. |
| `tracer-first` | Before building a capability, states the thinnest real end-to-end path and its proving command; runs it before widening | Tracer Bullets and Iterative Delivery; Estimation and Increment Rules; Code Generation Rules | Sequence of work, not tone. |
| `owner` | Ends each task with an Ownership block: decisions and trade-offs, risks, what is unverified, what is reversible, what was left alone | Own the Result; Named Pragmatic Habits; Project and Team Rules | Report is about accountability, not diagnosis or teaching. |

## Confusable pairs

Model-invocable skills whose triggers could fire on the same request, and the clause that separates them. The discriminating clause is written into both descriptions: each description of a listed pair names the other skill in backticks and says what belongs there. The `ownership` description opens with the concrete signals (a good-enough question, a trade-off or risk to report, a blamed framework or deadline, a ritual with no benefit) so it does not fire on every coding turn alongside `principles`.

| Pair | Separation |
| --- | --- |
| `dry-knowledge` / `generators-and-dsls` | Copies of a rule that already exist versus tools, generated output, macros and rule languages that create or hide copies. |
| `orthogonality` / `shy-code` | Module boundaries and the ripple of one change versus how one object reaches into another and the order of calls. |
| `orthogonality` / `shared-state` | Responsibilities and layering versus mutable state, globals, ambient context and concurrency. |
| `shy-code` / `shared-state` | A shared workspace or blackboard whose use needs a justification, and the order of calls, versus mutable state that is shared (globals, caches, threads, ambient context). |
| `tracer-bullets` / `prototypes` | A thin path that is kept and grown versus a throwaway experiment and its graduation. |
| `tracer-bullets` / `requirements` | How to sequence and size delivery versus what is actually being asked for. |
| `reversible-choices` / `requirements` | A decision that may change and must stay cheap to change versus a request that names a solution instead of a need. |
| `feedback-loops` / `test-portfolio` | Speed, flakiness and visibility of a signal versus which behaviors and failure modes have a test at all. |
| `feedback-loops` / `automation` | Waiting on or ignoring checks versus repeated manual steps that should be scripts. |
| `automation` / `generators-and-dsls` | Scripts and build steps for repeated work versus deriving code or behavior from a specification. |
| `contracts` / `error-recovery` | What counts as a violation and where it is enforced versus how a failure travels, what context survives and where it is contained. |
| `error-recovery` / `resource-discipline` | Classifying and containing failures versus guaranteeing release and ownership on every path, including failure paths. |
| `error-recovery` / `debugging` | Designing failure behavior in code versus finding why an observed defect happens. |
| `debugging` / `test-portfolio` | Explaining a defect versus deciding which tests protect the behavior; the regression test is owned by `test-portfolio`, referenced from `debugging`. |
| `shared-state` / `resource-discipline` | Whether state should be shared and who may mutate it versus who must release what and how cost grows. |
| `ownership` / `broken-windows` | How far to go, when to stop and how to report versus which small decay to fix or contain. |
| `ownership` / `code-communication` | What to tell the user or sponsor about a decision versus the written artifacts that stay in the repository. |
| `code-communication` / `contracts` | Comments, names and messages versus assumptions that should be enforced in code instead of described in comments. |
| `prototypes` / `generators-and-dsls` | Hand-written throwaway code versus tool-produced scaffolds and generated output (both feed `provenance-reviewer`). |

Rules skills and their workflows (different roles, not rewordings; only the rules skill is model-invocable):

| Rules skill | Workflow | What the workflow adds |
| --- | --- | --- |
| `debugging` | `debug-session` | An evidence record and a stop at the explanation. |
| `prototypes` | `prototype-charter` | The charter artifact and the graduation review. |
| `broken-windows` | `tidy-touched` | A budgeted edit of the touched area with containment notes. |
| `tracer-bullets` | `tracer-plan` | A slice definition with a proving command. |
| `dry-knowledge` | `knowledge-map` | A fact-by-representation map of a tree, in a fork. |
| `automation` | `manual-step-hunt` | A scan of docs, scripts and CI for manual rituals, in a fork. |

Reviewers and the tree-wide workflows that produce a similar table. Each one judges a change and hands the whole-tree job to its workflow (and the workflow says to use the reviewer for a diff), and the two report different tables:

| Reviewer | Workflow | Separation |
| --- | --- | --- |
| `knowledge-duplication-reviewer` | `knowledge-map` | Touched-fact ledger for the facts a diff or named files touch, with findings and what the change did to each copy, versus a tree inventory of facts the skill picks itself, whether or not anything changed. |
| `automation-reviewer` | `manual-step-hunt` | Touched-step ledger for the procedures and scripts a diff or named files touch, with findings, versus a sweep of docs, scripts and CI for rituals across a tree. |

Agent pairs that share a theme and how their reports differ:

| Pair | Separation |
| --- | --- |
| `contract-reviewer` / `failure-path-reviewer` | Contract table (obligations and where enforced) versus failure map (class, context, boundary). |
| `feedback-loop-reviewer` / `test-portfolio-reviewer` | Signal table (latency, flakiness) versus behavior-to-test matrix. |
| `coupling-reviewer` / `shared-state-reviewer` / `reversibility-reviewer` | Ripple map versus state inventory versus commitment register. |
| `provenance-reviewer` / `slice-reviewer` | Where trust in code comes from versus how much of the path is real. |
| `communication-reviewer` / `decay-reviewer` | Intent carried by written artifacts versus neglect in touched code. |

## Coverage check against the upstream sections

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | principles, explain-rule, mentor |
| Primary Directive | principles, plan, explain-rule, lead, mentor |
| Core Pragmatic Principles | principles |
| DRY Rules | dry-knowledge, automation, knowledge-map, knowledge-duplication-reviewer, knowledge-consolidator |
| Orthogonality Rules | orthogonality, shared-state, coupling-reviewer, shared-state-reviewer |
| Tracer Bullets and Iterative Delivery | tracer-bullets, prototypes, plan, tracer-plan, prototype-charter, slice-reviewer, tracer-first |
| Reversibility, Domain Languages, and Requirements | reversible-choices, requirements, generators-and-dsls, reversibility-reviewer |
| Prototyping Rules | prototypes, prototype-charter, provenance-reviewer |
| Automation Rules | automation, manual-step-hunt, automation-reviewer, automation-scripter |
| Feedback Loop Rules | feedback-loops, fix, debug-session, feedback-loop-reviewer, bug-fixer, pair |
| Design by Contract and Assertions | contracts, error-recovery, contract-reviewer, failure-path-reviewer, contract-writer |
| Error Handling and Recovery | error-recovery, failure-path-reviewer |
| Naming and Communication Rules | code-communication, communication-reviewer, terse |
| Text and Data Rules | reversible-choices, reversibility-reviewer, automation-scripter |
| State and Concurrency Rules | shared-state, shared-state-reviewer |
| Estimation and Increment Rules | tracer-bullets, plan, tracer-plan, slice-reviewer, pair, tracer-first |
| Tooling Rules | automation, manual-step-hunt, automation-reviewer, automation-scripter |
| Resource and Coupling Rules | resource-discipline, shy-code, generators-and-dsls, resource-reviewer, coupling-reviewer |
| Project and Team Rules | ownership, test-portfolio, code-communication, test-portfolio-reviewer, communication-reviewer, owner |
| Broken Windows Rule | broken-windows, tidy-touched, decay-reviewer |
| Review Rules | review, audit, knowledge-map, dry-knowledge, orthogonality, contracts, code-communication, lead, strict-reviewer |
| Forbidden Patterns | review, audit, strict-reviewer, plus the per-family subsections below |
| Code Generation Rules | principles, plan, fix, tracer-plan, dry-knowledge, orthogonality, contracts, tracer-bullets, slice-reviewer, knowledge-consolidator, tracer-first |
| Testing Rules | fix, feedback-loops, test-portfolio, feedback-loop-reviewer, test-portfolio-reviewer |
| Review Checklist | checklist, final-gate, review, tidy-touched, broken-windows, lead, strict-reviewer, principles |
| Final Instruction | principles, final-gate |

Subsections cited by exactly one family: `Own the Result` and `Named Pragmatic Habits` (ownership, owner, terse), `Think Beyond the Local Edit` (broken-windows, tidy-touched, decay-reviewer), `Favor Adaptability` (reversible-choices, reversibility-reviewer), `Basic Tool Rules` (automation, debugging, debug-session, generators-and-dsls, provenance-reviewer, bug-fixer), `Cargo-Cult Process` (ownership, manual-step-hunt), `Knowledge Duplication` (dry-knowledge, knowledge-map, knowledge-duplication-reviewer, knowledge-consolidator), `Non-Orthogonal Design` (orthogonality, coupling-reviewer), `Manual Everything` (automation, manual-step-hunt, automation-reviewer, automation-scripter), `Prototype Fossilization` (prototypes, prototype-charter, provenance-reviewer).

## Overlap review

Pairs that were close and how they were separated:

- `ownership` and `broken-windows`: the first holds the stopping rule and the reporting rule, the second holds the decision about specific decay. The tie-break between "stop polishing" and "tidy what you touch" is written in both: tidy only where the cost is low and the value is immediate (Added judgment on how to read "low").
- `orthogonality`, `shy-code` and `shared-state`: all three are coupling, split by the thing that couples: module boundaries, object reach and order, mutable state. A cross-reference at the top of each skill says which of the three to use.
- `contracts`, `error-recovery` and `resource-discipline`: obligations, the path a failure takes, and release on every path. A function that acquires a resource, enforces a precondition and reports a failure touches all three; each skill states only its own decision.
- `feedback-loops` and `test-portfolio`: latency and visibility versus coverage of kinds. The regression-test rule for human-found bugs lives in `test-portfolio` only; `feedback-loops` points to it.
- `debugging`, `debug-session` and `bug-fixer`: rules, evidence record, implementer. The record is the hand-off: `bug-fixer` takes the explanation `debug-session` produced or produces its own.
- `tracer-bullets` and `prototypes`: kept path versus disposable experiment. The choice between the two is written in `prototypes` as an Added-judgment rule, because the source states the two ideas separately.
- `lead` and `review`: `review` produces findings; `lead` only decides who should.

All 26 `##` sections of the upstream full file are cited by at least one component; the validator checks this through the `## Source` sections. `Core Pragmatic Principles` is cited by the hub because its subsections are split between `ownership`, `broken-windows` and `reversible-choices`.
