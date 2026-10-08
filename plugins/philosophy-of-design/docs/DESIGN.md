# A Philosophy of Software Design plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings (and a few `###` headings) of `skills/principles/references/full.md`.

## Design decisions

1. **The rule set is small, so the split follows decisions, not volume.** The upstream full file has 24 `##` sections and about 370 lines. Each topical skill takes one section or one decision cluster that crosses two or three sections (for example `flags-and-knobs` gathers the flag, setup-step and mode-parameter rules that the book spreads over Interface Design, Pull Complexity Downward and Tactical Programming). No skill restates another cluster; each points to its neighbour.
2. **Complexity is the unit of judgment.** Every reviewer, workflow and style measures a change by what it does to the reader's burden and to future change, not by line counts, function sizes or pattern names. This is why there is no "small function" skill: `functions-and-variables` exists to stop over-splitting.
3. **Depth is split into positive and negative skills.** `deep-modules` says how to design for depth; `pass-through-layers` says how to recognise and remove forwarding layers and when to refuse a new one; `split-or-merge` decides boundaries between units; `collapse-layer` is the editing workflow.
4. **Interface problems are split by what they judge.** `interface-design` judges the shape of one public element; `flags-and-knobs` judges parameters that switch behavior and configuration pushed to callers; `temporal-decomposition` judges required call order; `information-hiding` judges where knowledge lives; `pull-complexity-down` judges what every caller repeats.
5. **Errors and special cases are separate skills.** `define-errors-away` redesigns invariants so that an error case disappears; `generality-and-special-cases` keeps legitimate rare behavior out of the core path. Both are needed because not every rare case is an error.
6. **The book's workflows are explicit.** `design-twice` (compare two designs), `comments-first` (contract before code), `depth-map` (module inventory), `symptom-trace` (from complaint to cause) and `collapse-layer` (remove a forwarding layer) follow what the book teaches rather than generic review steps.
7. **Tactical patching is a first-class concern.** `strategic-programming`, `tactical-patch-reviewer` and the scope rule in the hub keep the book's investment mindset proportionate: improve the structure around the change, do not rewrite the module.
8. **Model-invocable skills are 19 (cap 20).** All procedures with arguments are manual skills.
9. **Reviewers own one concern and have their own report shape.** A depth reviewer reports a module table, a leakage reviewer a knowledge map, an exception reviewer an error-site map, a temporal reviewer a sequence map.
10. **Where this book disagrees with another, say so.** The compatibility notes mark Clean Code as the one real tension (small functions, comment defaults). The skills `functions-and-variables` and `comments-as-design` and the README state what this plugin decides and why.

## Skills: model-invocable (19)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Core Complexity Rules; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules itself. |
| `complexity-symptoms` | Name the symptom (change amplification, cognitive load, unknown unknowns, hidden dependencies, spread, temporal coupling) and ask the default-response questions | Core Complexity Rules; Symptoms of Complexity; Default Response; Primary Directive | It diagnoses; every other topical skill treats one cause. |
| `deep-modules` | Design for a small, meaningful interface over substantial hidden work | Module Depth Rules; Prefer Deep Modules; Avoid Shallow Modules; Primary Directive (shorter-files line only) | `pass-through-layers` is about recognising and removing the opposite; this is the design target. |
| `pass-through-layers` | Recognise and refuse forwarding services, thin wrappers, rename-only helpers, facades without simplification | Module Depth Rules; Avoid Shallow Modules; Shallow Decomposition; Combine or Separate Code; Code Generation Rules | It starts from an existing or proposed layer; `deep-modules` starts from a module being designed. |
| `information-hiding` | Decide which module owns a decision, representation, format or piece of bookkeeping, and stop it leaking | Information Hiding Rules; Interface Leakage | `interface-design` shapes one element; this places knowledge across modules. |
| `interface-design` | Shape public elements around what callers need to know; narrow but meaningful | Interface Design Rules; Code Generation Rules; Interface Leakage | `flags-and-knobs` is the sub-problem of parameters that switch behavior; this is the general shape. |
| `flags-and-knobs` | Replace boolean and mode parameters, configuration knobs and callback escape hatches by decisions made inside | Interface Design Rules; Tactical Complexity Debt; Pull Complexity Downward | It only judges parameters and options; `temporal-decomposition` judges call order. |
| `strategic-programming` | Decide how much design investment a change deserves; refuse symptom patches that raise global complexity | Strategic Programming over Tactical Programming; Strategic Programming; Tactical Programming; Tactical Complexity Debt | It is about the attitude and scale of a change; the other skills are about structure. |
| `generality-and-special-cases` | Pick the generality level of an interface and keep rare cases out of the general path | General-Purpose vs Special-Purpose Modules; Special-General Decomposition; Combine or Separate Code (normal and special cases rule only) | `define-errors-away` removes error cases; this places legitimate special behavior. |
| `define-errors-away` | Change the interface or invariant so an exception case no longer exists | Error Handling and Exception Elimination | It targets errors and invalid states; `generality-and-special-cases` targets valid rare behavior. |
| `pull-complexity-down` | Move repeated caller work into the owning module even if its implementation grows | Pull Complexity Downward; Complexity Spread; Code Generation Rules | `information-hiding` asks who should know; this asks what callers currently repeat. |
| `comments-as-design` | What comments earn their place (contracts, invariants, decisions, rationale) and which signal a design problem | Comment Rules; Design Alternatives and Comments-First Design | `comments-first` (manual) drafts a contract before code; this judges existing and new comments. |
| `functions-and-variables` | Function depth, extraction that hides work, variables that carry meaning, local detail kept local | Function and Variable Rules | `split-or-merge` decides boundaries across units; this judges one function body and its variables. |
| `temporal-decomposition` | Structure around concepts, not execution phases; remove call-order traps and partial objects | Temporal Decomposition Rules; Interface Design Rules | `flags-and-knobs` judges parameters; this judges sequence and phase structure. |
| `split-or-merge` | Decide whether code is separated or combined by total complexity | Combine or Separate Code; Function and Variable Rules | `pass-through-layers` handles forwarding layers; this is the general split/merge decision. |
| `design-alternatives` | Compare at least two plausible designs on four criteria before building the first one that works | Design Alternatives and Comments-First Design | `design-twice` (manual) produces the comparison; this holds the rules and anti-patterns. |
| `naming-and-obviousness` | Names that reveal abstractions, consistent conventions, obvious behavior, surprise as complexity | Naming, Consistency, and Obviousness; Interface Design Rules | `comments-as-design` handles prose; this handles identifiers and conventions. |
| `performance-and-trends` | Require evidence before trading depth for speed or adopting a pattern, framework or paradigm; hide optimizations | Performance, Trends, and Tests | It judges added complexity that claims a benefit; `pass-through-layers` judges layers with no claim. |
| `testing-through-interfaces` | Test public behavior and contracts; keep tests from forcing leaky interfaces | Testing Rules; Performance, Trends, and Tests | It is about tests only; no other skill discusses test coupling. |

## Skills: manual workflows (11)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Forbidden Patterns; Review Checklist | `audit` scans a tree for health; `review` judges a change. |
| `audit` | yes | no | Complexity health scan of a directory or repository, rated by rule cluster, at most 40 lines | Core Complexity Rules; Review Rules; Forbidden Patterns | `depth-map` is a module inventory; `audit` rates every cluster. |
| `plan` | no | no | Plan a non-trivial change: concept, narrowest interface, hidden details, caller impact, special cases, scope | Code Generation Rules; Design Alternatives and Comments-First Design; Strategic Programming over Tactical Programming | `design-twice` only compares designs; `plan` sequences a whole change. |
| `explain-rule` | no | no | Explain one rule: modal strength, reason, check, example, exception | Purpose; Primary Directive; every section named in its topic index | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the book's final checklist with yes/no/not-applicable and a next action for each no | Review Checklist; Final Instruction | `final-gate` is the isolated strict PASS/FAIL; `checklist` is the in-session interactive walk. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Review Rules; Testing Rules; Strategic Programming over Tactical Programming | `collapse-layer` and `module-deepener` have a fixed move; `fix` takes any finding. |
| `design-twice` | no | no | Write two or more designs as call sites, score them on four criteria, choose, record | Design Alternatives and Comments-First Design; Primary Directive | `plan` sequences work; this produces the comparison itself. |
| `comments-first` | no | no | Draft the interface contract and comments before the body; revise the abstraction if the comment gets complicated | Design Alternatives and Comments-First Design; Comment Rules | `design-twice` compares designs; this tests one design by writing its contract. |
| `depth-map` | yes | no | Inventory modules in a scope by interface weight and hidden work; rank the shallow ones | Module Depth Rules; Avoid Shallow Modules; Shallow Decomposition | `audit` rates all clusters; this answers one question for every module. |
| `symptom-trace` | no | no | From a complaint or history (touched many files, hard to follow, surprise) to the likely cause and the skill that treats it | Core Complexity Rules; Symptoms of Complexity; Default Response; Review Rules | `complexity-symptoms` defines symptoms; this gathers evidence with `git log --stat` and routes. |
| `collapse-layer` | no | yes | Remove a forwarding layer or merge shallow fragments safely, moving real work to the owner | Module Depth Rules; Avoid Shallow Modules; Combine or Separate Code; Pull Complexity Downward | `module-deepener` is the delegated agent for several layers; this is the in-session loop for one. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to specialists and skills; does not review | principles | Review Rules; Primary Directive; Code Generation Rules | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the final checklist on the working diff and returns PASS or FAIL | principles | Review Checklist; Final Instruction; Forbidden Patterns | Binary gate with evidence; reviewers return ranked findings. |
| `complexity-reviewer` | sonnet | Net complexity delta of a change by symptom | complexity-symptoms | Core Complexity Rules; Symptoms of Complexity; Default Response | Output is a symptom ledger; others judge a cause. |
| `depth-reviewer` | sonnet | Interface weight versus hidden work per module; pass-through layers | deep-modules, pass-through-layers | Module Depth Rules; Prefer Deep Modules; Avoid Shallow Modules | Output is a module depth table; `split-merge-reviewer` judges boundaries between units. |
| `leakage-reviewer` | sonnet | Which modules know which decision, format or representation | information-hiding | Information Hiding Rules; Interface Leakage | Output is a knowledge map; `interface-reviewer` judges individual elements. |
| `interface-reviewer` | sonnet | Shape of each public element: flags, modes, option bags, mechanism-revealing arguments. Call order and setup sequences are handed to `temporal-reviewer` | interface-design, flags-and-knobs | Interface Design Rules; Tactical Complexity Debt | Output is a per-element ledger; `temporal-reviewer` owns required call order. |
| `tactical-patch-reviewer` | sonnet | Classifies each hunk as structural, symptom patch, copy-paste, extra flag or exposed detail | strategic-programming | Strategic Programming over Tactical Programming; Tactical Programming; Tactical Complexity Debt | Only reviewer that judges the approach of the change rather than its resulting structure. |
| `special-case-reviewer` | sonnet | Generality of interfaces and rare cases cluttering core paths | generality-and-special-cases | General-Purpose vs Special-Purpose Modules; Special-General Decomposition | Output is a branch census; `exception-reviewer` covers error cases. |
| `exception-reviewer` | sonnet | Error sites that could be defined away, masked low or kept | define-errors-away | Error Handling and Exception Elimination | Output is an error-site map. |
| `caller-burden-reviewer` | sonnet | Work repeated at call sites that the callee could own | pull-complexity-down | Pull Complexity Downward; Complexity Spread | Output is a call-site tax table. |
| `comment-reviewer` | sonnet | Disposition for every comment and missing contracts | comments-as-design | Comment Rules | Every comment gets a disposition. |
| `function-depth-reviewer` | sonnet | Extraction fragments, pass-through variables, leaked intermediate state | functions-and-variables | Function and Variable Rules | Judges bodies; `split-merge-reviewer` judges larger units. |
| `temporal-reviewer` | sonnet | Required call order and phase structure, and where it is enforced | temporal-decomposition | Temporal Decomposition Rules | Output is a sequence map. |
| `split-merge-reviewer` | sonnet | Boundaries between units: keep, merge or split | split-or-merge | Combine or Separate Code | Output is a boundary ledger. |
| `naming-reviewer` | sonnet | Mechanism names, inconsistent siblings, surprising behavior | naming-and-obviousness | Naming, Consistency, and Obviousness | Output is a concept-to-name matrix. |
| `evidence-reviewer` | sonnet | Optimizations, patterns and frameworks against their claimed benefit | performance-and-trends | Performance, Trends, and Tests | Output is a claim ledger. |
| `test-contract-reviewer` | sonnet | Tests coupled to internals or forcing exposure | testing-through-interfaces | Testing Rules | Output is a test coupling table. |
| `module-deepener` | sonnet | Collapses forwarding layers and moves repeated work into the owner | pass-through-layers, pull-complexity-down | Module Depth Rules; Pull Complexity Downward; Combine or Separate Code | Changes structure across several units; the others change one thing. |
| `interface-simplifier` | sonnet | Replaces flags, mode parameters and mechanism-revealing arguments by caller-oriented operations and updates callers; collapses a setup sequence only when a `temporal-reviewer` finding names it | interface-design, flags-and-knobs | Interface Design Rules; Tactical Complexity Debt; Pull Complexity Downward | Changes signatures; `module-deepener` changes layers. |
| `special-case-isolator` | sonnet | Moves rare-case handling out of the core path | generality-and-special-cases | Special-General Decomposition; General-Purpose vs Special-Purpose Modules | Behavior-preserving move of branches only. |
| `contract-writer` | sonnet | Writes interface contracts and invariant comments, edits comments only | comments-as-design | Comment Rules; Design Alternatives and Comments-First Design | Comment-only edits; reports where a comment exposes a design problem instead of papering over it. |
| `test-writer` | sonnet | Writes contract-level tests and focused special-case tests | testing-through-interfaces | Testing Rules; Special-General Decomposition (context only: the special cases under test) | Writes tests only; never edits production code. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Purpose; Primary Directive; Review Checklist | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Forbidden Patterns; Review Checklist | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Strategic Programming over Tactical Programming; Combine or Separate Code | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full; brevity applies to prose, never to design clarity | Primary Directive; Final Instruction | Brevity rules. |
| `architect` | Design before code: the abstraction, the interface, what it hides, what callers no longer need to know, two designs for non-trivial choices | Code Generation Rules; Design Alternatives and Comments-First Design; Module Depth Rules | Whole-session design-first discipline. |
| `complexity-ledger` | Every code answer ends with a ledger: facts the reader must hold, files touched by a change, special cases, before and after | Core Complexity Rules; Symptoms of Complexity; Review Checklist | Report is about net complexity, not about diagnosis or teaching. |

## Coverage check against the upstream sections

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | principles, explain-rule, mentor |
| Primary Directive | principles, complexity-symptoms, deep-modules, explain-rule, design-twice, lead, mentor, terse |
| Core Complexity Rules | principles, complexity-symptoms, audit, symptom-trace, complexity-reviewer, complexity-ledger |
| Module Depth Rules | deep-modules, pass-through-layers, depth-map, collapse-layer, depth-reviewer, module-deepener, architect |
| Information Hiding Rules | information-hiding, leakage-reviewer |
| Interface Design Rules | interface-design, flags-and-knobs, temporal-decomposition, naming-and-obviousness, interface-reviewer, interface-simplifier |
| Strategic Programming over Tactical Programming | strategic-programming, plan, fix, pair, tactical-patch-reviewer |
| General-Purpose vs Special-Purpose Modules | generality-and-special-cases, special-case-reviewer, special-case-isolator |
| Error Handling and Exception Elimination | define-errors-away, exception-reviewer |
| Pull Complexity Downward | pull-complexity-down, flags-and-knobs, collapse-layer, caller-burden-reviewer, module-deepener, interface-simplifier |
| Comment Rules | comments-as-design, comments-first, comment-reviewer, contract-writer |
| Function and Variable Rules | functions-and-variables, split-or-merge, function-depth-reviewer |
| Temporal Decomposition Rules | temporal-decomposition, temporal-reviewer |
| Special-General Decomposition | generality-and-special-cases, special-case-reviewer, special-case-isolator, test-writer |
| Combine or Separate Code | split-or-merge, pass-through-layers, collapse-layer, generality-and-special-cases, split-merge-reviewer, module-deepener, pair |
| Design Alternatives and Comments-First Design | design-alternatives, design-twice, comments-first, comments-as-design, plan, contract-writer, architect |
| Naming, Consistency, and Obviousness | naming-and-obviousness, naming-reviewer |
| Performance, Trends, and Tests | performance-and-trends, testing-through-interfaces, evidence-reviewer |
| Review Rules | review, audit, symptom-trace, fix, lead, strict-reviewer |
| Forbidden Patterns | review, audit, final-gate, strict-reviewer |
| Code Generation Rules | plan, architect, interface-design, pull-complexity-down, pass-through-layers, lead |
| Testing Rules | testing-through-interfaces, test-contract-reviewer, test-writer, fix |
| Review Checklist | principles, review, checklist, final-gate, strict-reviewer, mentor, complexity-ledger |
| Final Instruction | principles, checklist, final-gate, terse |

`explain-rule` also cites every section its topic index points at, so it is not repeated in each row above.

## Overlap review

Pairs that were close and how they were separated:

- `deep-modules` and `pass-through-layers`: design target versus recognition and refusal of forwarding layers. The first never lists wrapper anti-patterns; the second never explains how to build a strong interface.
- `pass-through-layers` and `split-or-merge`: the first begins with a layer that forwards; the second begins with a boundary between units of any kind and applies the two-sided test.
- `information-hiding`, `interface-design` and `pull-complexity-down`: knowledge placement across modules, shape of one element, and work repeated by callers. Each reviewer for them has a different table.
- `flags-and-knobs` and `temporal-decomposition`: parameters that select behavior versus order of calls. Setup methods belong to the temporal skill when order is the problem and to the flags skill when the configuration surface is the problem.
- `interface-reviewer`, `temporal-reviewer` and `interface-simplifier`: `interface-reviewer` judges parameters, flags, option bags and mechanism-revealing arguments only; required call order and setup sequences belong to `temporal-reviewer`, and `interface-reviewer` notes them in one line and hands off. `interface-simplifier` collapses a setup sequence only after a `temporal-reviewer` finding names it.
- `function-depth-reviewer` and `split-merge-reviewer`: both react to extractions, so their triggers are split by unit. The first fires on helpers and variables introduced inside a function; the second on classes, files, services or packages added, moved, merged or split.
- Skill descriptions that could match the same request carry a discriminating clause: `split-or-merge` (units larger than a function) against `functions-and-variables` (inside one function body); `information-hiding` (one decision known by several modules) against `pull-complexity-down` (the same lines repeated at the call sites of one callee); `design-alternatives` (two or more designs being weighed) against `interface-design` (shaping a single element).
- `define-errors-away` and `generality-and-special-cases`: error and invalid-state removal versus valid rare behavior. The error skill ends where the caller genuinely must react.
- `comments-as-design`, `comments-first` and `contract-writer`: rules for comments, the contract-before-code workflow, and the comment-only implementer.
- `design-alternatives` and `design-twice`: rules and anti-patterns versus the workflow with a result template.
- `symptom-trace` and `complexity-symptoms`: the workflow runs read-only history commands and routes; the skill defines the symptoms.
- `collapse-layer`, `module-deepener` and `fix`: one-layer in-session loop, multi-layer delegated agent, and generic finding resolution.
- `performance-and-trends` and `strategic-programming`: the first requires evidence for added complexity that claims a benefit; the second sizes the investment of a change.
- `checklist` and `final-gate`: interactive walk with next actions versus isolated PASS/FAIL with evidence.
- `review` and `lead`: `review` produces findings; `lead` only decides who should.
