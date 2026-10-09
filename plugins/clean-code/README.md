# Clean Code

Robert C. Martin's working rules for code that the next person can read, change and trust, turned into a Claude Code toolkit. It makes Claude name things well, keep functions honest about what they do, write tests that protect behavior, keep vendor and framework detail at the edge, and leave the code it touched a little better than it found it, without turning every task into a rewrite.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), eight usage walkthroughs with exact commands, a map from the book's sections to the components, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *Clean Code* argues that code is read far more often than it is written, so the cost of a change is mostly the cost of understanding what is already there. Its answer is a set of habits: names that say what things are, functions that do one thing at one level, no hidden effects, comments only for what code cannot say, errors handled deliberately, tests treated as production code, third-party code kept behind boundaries of your own, and a refusal to leave a mess behind because the schedule is tight. The mantra that ties it together is the Boy Scout Rule: leave the code you touch cleaner than you found it.

**Who this is for.** Developers using Claude Code on everyday application code in any mainstream language: implementing features, fixing bugs, reviewing pull requests, cleaning up, teaching a team. The rules are about the local shape of code, so the plugin pays off most on routine changes, where agents tend to stop as soon as the tests pass.

**The bias it corrects.** An agent asked to add behavior tends to leave the names it chose while exploring, drops a new branch into a function that already does three things, adds one more caller to a boolean flag, and explains with a comment what a rename would have made obvious. Asked to "clean up", the same agent often over-corrects and reshapes half a module. This toolkit pushes the middle path: cleanliness is part of delivery, and the amount of cleanup is capped by what the requested change makes safe and readable.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/clean-code:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- One skill per rule cluster, written as decisions rather than slogans: when it applies, how to check it, what to do instead, and where the book itself allows an exception.
- The book's smell catalog split by family so each smell has one owner, a detection recipe and a treatment: names, functions, comments, design (redundancy, coupling, surprise) and tests, plus concurrency and boundaries as skills of their own.
- Workflows that follow what the book teaches: `smell-hunt`, `boy-scout`, `extract-till-you-drop`, `successive-refinement`, `learning-tests` and `vocabulary-audit`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape, four implementers that make small test-backed changes, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `smell-first` and `boy-scout`.

**When not to use it.** Reach for a different book when the real risk lies elsewhere: dependency direction between layers and policy independence (a Clean Architecture plugin), module depth and interface design trade-offs (a software-design plugin), reshaping code that has no tests (a legacy-code plugin), production failure behavior such as timeouts and overload (a release-engineering plugin), or distributed data semantics. For a throwaway script, the rules still apply, but the ceremony of this toolkit does not.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install clean-code@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/clean-code
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall clean-code@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**59 components:** 31 skills (19 Claude can load on its own, 12 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/clean-code:boundaries` | Use when core logic calls a third-party library, SDK or external service directly, when upgrading such a dependency, or when coding against an API that does not exist yet. Covers local adapters, narrow interfaces and… |
| `/clean-code:class-design` | Use when a class or module is growing, changes for several unrelated reasons, has fields used by only some methods, or is named Manager, Helper or Util. Covers single responsibility, cohesion, change locality… |
| `/clean-code:clean-tests` | Use when writing, reviewing or refactoring unit and integration tests, or when tests are slow, fragile, order-dependent or hard to read. Covers one-idea tests, setup and assertions, test vocabulary, isolation… |
| `/clean-code:comments` | Use when adding, reviewing or deleting comments, TODO notes or commented-out code, or when a comment explains what code does. Covers the five legitimate comment categories, noise removal, comment-heavy code and TODO… |
| `/clean-code:concurrency` | Use when adding or changing threads, async tasks, locks, queues, background workers, shutdown or cancellation logic, or when a test fails intermittently. Decides whether concurrency is warranted and keeps shared state… |
| `/clean-code:data-and-objects` | Use when designing or reviewing what a type exposes: getter and setter pairs, call chains through several objects, DTOs, or types that are half data and half behavior. Decides object versus data carrier and hides… |
| `/clean-code:emergent-design` | Use when choosing between designs, deciding whether to add an abstraction, class, layer or dependency, or tempted to redesign. Applies the four-criteria tie-breaker, working-draft refinement, boring solutions and… |
| `/clean-code:error-handling` | Use when writing or reviewing exceptions, error codes, null or absent returns, error messages, or cleanup and shutdown paths. Keeps the happy path readable and failures explicit and diagnosable. |
| `/clean-code:formatting` | Use when arranging a file, ordering functions, grouping related code, or reacting to formatting noise in a diff. Covers vertical ordering, proximity of related concepts, file size, line length, indentation, brittle… |
| `/clean-code:function-contracts` | Use when a function takes many parameters, a boolean flag or an output argument, changes state while answering a question, or must be called in a hidden order. Covers argument design, command/query separation, hidden… |
| `/clean-code:function-shape` | Use when a function is long, deeply nested, mixes levels of detail, or needs a comment to separate its phases. Covers function size, one thing per function, one abstraction level, top-down order, nesting, negative… |
| `/clean-code:naming` | Use when naming or renaming variables, functions, types or constants, or when a reader cannot tell what an identifier means. Covers intention-revealing names, one word per concept, searchable names, magic numbers and… |
| `/clean-code:principles` | Applies the Clean Code rule set to everyday coding and review. Use for any task that writes, reviews or changes code where readability, names, function shape, side effects, comments, error handling, tests or cleanup of… |
| `/clean-code:refactoring-steps` | Use when restructuring existing code, preparing for a change by cleaning first, or sequencing a cleanup. Covers small safe steps, behavior preservation, make-it-work-then-right, rename and extract and inline moves, and… |
| `/clean-code:smells-coupling` | Use when one requirement edits many files, a base class mentions its subclasses, unrelated concepts share a type or constant, or the same type switch repeats. Smell family for coupling, placement and repeated… |
| `/clean-code:smells-redundancy` | Use when code repeats itself, contains unused code, or has layers that only forward calls. Smell family for duplicated logic, dead code and unused abstractions, unnecessary indirection and accidental complexity, with… |
| `/clean-code:smells-surprise` | Use when code does not do the obvious thing its name promises, edge inputs behave wrongly, checks are disabled or suppressed, or behavior depends on hidden defaults and magic. Smell family for surprising behavior… |
| `/clean-code:system-construction` | Use when business code creates its own collaborators, reads global configuration, wires dependencies mid-flow, or is cluttered by logging, transactions or retries. Separates building a system from using it and keeps… |
| `/clean-code:tdd-discipline` | Use when changing behavior, fixing a bug, finishing a refactor, or deciding how much to test. Covers failing-test-first, no unjustified production behavior, bug-fix tests, coverage as a signal, ignored tests, boundary… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/clean-code:audit` | Scan a directory or repository for Clean Code health in a forked context and return ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/clean-code:boy-scout` | Leave the code you touched cleaner than you found it: one worthwhile cleanup per touched area, inside the touched code, with tests. Reports what was left alone. | `[paths \| empty for the files in the current diff]` |
| `/clean-code:checklist` | Walk the Clean Code final checklist and hard rules against your current change, with a yes, no or not-applicable and a next action for each no. | `[paths \| empty for the current diff]` |
| `/clean-code:explain-rule` | Explain one Clean Code rule: its strength (must, should, must not), the reason, how to check it, an original example and the book's own exceptions. | `[rule name \| section \| situation you are unsure about]` |
| `/clean-code:extract-till-you-drop` | Decompose one long function into single-level functions by extracting step by step with tests after each, and stop before the pieces become named fragments. | `[file:function \| function name \| empty for the longest function in the current diff]` |
| `/clean-code:fix` | Resolve given Clean Code findings with the smallest change per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/clean-code:learning-tests` | Pin down how a third-party library already in the project behaves with small tests that call it the way you will, then propose the narrow local interface around it. | `[library or API \| file where it is used \| empty to find vendor usage in the diff]` |
| `/clean-code:plan` | Plan a non-trivial change with the Clean Code change process: intent, simplest correct change, tests first, validation and an explicit cleanup budget. Does not edit. | `[task description \| issue text \| empty to plan around the current diff]` |
| `/clean-code:review` | Review a diff or paths against the Clean Code rules and report ranked findings with file, line, rule, consequence and the smallest fix. | `[paths \| git ref \| empty for the current diff]` |
| `/clean-code:smell-hunt` | Hunt the Clean Code smell catalog by family (names, functions, comments, design, tests) in a forked context and map each hit to its treatment skill, in at most 40 lines. | `[names\|functions\|comments\|design\|tests\|all] [paths \| empty for the current diff]` |
| `/clean-code:successive-refinement` | Take a working but rough draft and refine it in named rounds (names, shape, duplication, contracts, tests) with the tests green after each, until the four design criteria hold. | `[feature description \| file path \| empty to refine the draft in the current diff]` |
| `/clean-code:vocabulary-audit` | Build the concept-to-term table for a directory in a forked context: synonyms used for one concept and words used for two, with a recommended single term for each. | `[directory \| glob \| empty for the repository root]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-clean-code:adapter-builder` | sonnet | can edit files | Implementer that wraps a third-party dependency behind a narrow interface in the core's vocabulary, adds learning tests, and migrates callers one at a time. Use when boundary findings call for an… |
| `@agent-clean-code:boundary-reviewer` | sonnet | read-only | Reviewer of third-party and external dependency use: vendor types in core code, wide interfaces, untranslated errors and unpinned behavior. Use proactively after edits that import an SDK, ORM or… |
| `@agent-clean-code:class-design-reviewer` | sonnet | read-only | Reviewer of class and module responsibility, cohesion and change locality, including coupling smells. Use proactively after edits that grow a class, add a module, add a subclass, or make one change… |
| `@agent-clean-code:comment-reviewer` | sonnet | read-only | Reviewer of comments and TODO notes. Use proactively after edits that add or change comments, leave commented-out code, add TODOs, or alter code that has comments attached. |
| `@agent-clean-code:concurrency-reviewer` | sonnet | read-only | Reviewer of concurrency and async code: whether it is needed, shared mutable state, lock scope, task lifecycle, cancellation, and testability under varied schedules. Use proactively after edits… |
| `@agent-clean-code:construction-reviewer` | sonnet | read-only | Reviewer of object construction and wiring: collaborators created inside business code, hidden lazy init, global lookups, bootstrapping that decides behavior, cross-cutting clutter. Use proactively… |
| `@agent-clean-code:contract-reviewer` | sonnet | read-only | Reviewer of function signatures and effects: parameters, flags, output arguments, hidden side effects, command/query mixing and surprising behavior. Use proactively after edits that change… |
| `@agent-clean-code:error-handling-reviewer` | sonnet | read-only | Reviewer of failure design: exceptions, error codes, null and absent returns, error messages, swallowed errors and cleanup paths. Use proactively after edits that add try/catch, return null or error… |
| `@agent-clean-code:final-gate` | sonnet | read-only | Pre-merge gate that runs the Clean Code final checklist and hard rules against the working diff and returns PASS or FAIL with evidence. Use before declaring work done, committing or opening a pull… |
| `@agent-clean-code:function-extractor` | sonnet | can edit files | Implementer that decomposes one long function into single-level functions, extracting step by step with tests after each and stopping before the pieces become named fragments. Use when a function… |
| `@agent-clean-code:function-reviewer` | sonnet | read-only | Reviewer of function bodies: size, single purpose, abstraction levels, nesting and conditionals. Use proactively after edits that add or lengthen functions, add branches, or nest control flow. |
| `@agent-clean-code:layout-reviewer` | sonnet | read-only | Reviewer of file layout: vertical ordering, proximity of related code, file size, line length and brittle alignment. Use proactively after edits that add functions to a file, move code, or produce… |
| `@agent-clean-code:lead` | opus | read-only | Triage lead for Clean Code work. Use first on any non-trivial change or review to decide which specialist reviewers, implementers and skills apply, in what order, and how much cleanup is… |
| `@agent-clean-code:naming-reviewer` | sonnet | read-only | Reviewer of identifier names and vocabulary. Use proactively after edits that add or rename variables, functions, types or constants, or that introduce numeric or string literals with business… |
| `@agent-clean-code:object-design-reviewer` | sonnet | read-only | Reviewer of what types expose: objects versus data carriers, getter and setter mirrors, call chains, smart DTOs and leaked representation. Use proactively after edits that add or change classes… |
| `@agent-clean-code:refactorer` | sonnet | can edit files | Implementer that carries out behavior-preserving structural changes in small, test-backed steps. Use when review findings or a plan call for renames, extractions, inlining, flag removal or dead-code… |
| `@agent-clean-code:scope-guard` | sonnet | read-only | Reviewer that compares a diff with the request and classifies each hunk as required, enabling cleanup, opportunistic cleanup or out of scope. Use proactively after cleanup or refactoring, before… |
| `@agent-clean-code:simplicity-reviewer` | sonnet | read-only | Reviewer of unearned structure: speculative abstractions, pass-through layers, needless dependencies, duplicated rules, premature optimization. Use proactively after edits that add interfaces… |
| `@agent-clean-code:smell-scanner` | haiku | read-only | Mechanical scanner that produces a census of smell candidates with numbers and locations: long functions, nesting, parameter counts, flags, commented-out code, skipped tests, suppressions. Use when… |
| `@agent-clean-code:test-gap-reviewer` | sonnet | read-only | Reviewer that finds changed behavior with no protecting test: missing bug-fix tests, untested boundaries, skipped or ignored tests, multi-step builds. Use proactively after any behavior change or… |
| `@agent-clean-code:test-quality-reviewer` | sonnet | read-only | Reviewer of the quality of tests that exist: one idea per test, readable setup, determinism, isolation, speed and brittleness. Use proactively after edits that add or change tests, or when tests… |
| `@agent-clean-code:test-writer` | sonnet | can edit files | Implementer that writes clean tests first for behavior changes and bug fixes, shows each failing for the right reason, and edits test files only. Use when test-gap findings call for tests or before… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style clean-code:boy-scout` | Does the requested task, then closes every answer that changed code with a Campsite block: what was left cleaner inside the touched code and what was deliberately not touched. |
| `/output-style clean-code:mentor` | Teaches the Clean Code rule behind each decision, names it, and ends non-trivial answers with one short check-for-understanding question. |
| `/output-style clean-code:pair` | Works in small narrated steps with tests between them and asks before any change larger than a few lines or one that touches public API. |
| `/output-style clean-code:smell-first` | Names the smells in the code it is about to touch before any edit, ties each edit to a named smell and its treatment, and lists what remains afterwards. |
| `/output-style clean-code:strict-reviewer` | Answers as a ranked findings table against the Clean Code rules, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style clean-code:terse` | Result first, no preamble, a few lines at most unless asked, while still reporting what ran, the unresolved risk, and failing output in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with the `lead` agent or the routing table in `/clean-code:principles` when you are not sure what applies. The `lead` names the specialist reviewers and skills for the change; each reviewer owns one concern (names, function bodies, signatures and effects, comments, layout, type surface, class responsibility, errors, boundaries, construction, test quality, test gaps, concurrency, unearned structure, scope) and reports in its own shape. Findings go to the implementers or to `/clean-code:fix`, which make the smallest change and run the tests. `final-gate` runs the checklist last. The manual workflows are the entry points you type; `audit`, `smell-hunt` and `vocabulary-audit` run in a forked context and return at most 40 lines so a whole-repository scan does not fill your conversation. Output styles change the rhythm and the report format of the entire session. The vendored rule sets live in `skills/principles/references/` (`full`, `mini`, `nano`); every component names the upstream sections it applies in its `## Source` list.

Skills are invoked as `/clean-code:<name>`, agents are addressed as `clean-code:<name>` (ask for them by name or let Claude delegate), and styles are selected with `/output-style clean-code:<name>`.

## Usage walkthroughs

### 1. Review the work in progress

You have edited a few files and want a second opinion before you stage anything.

```text
/clean-code:review
```

With no argument it runs `git status` and `git diff`, classifies which clusters the change touches, applies those skills, and prints ranked findings with `file:line`, the rule by name, the consequence and the smallest fix. If it finds nothing it prints `No findings` and lists the clusters it checked. To act on the result:

```text
/clean-code:fix last review
```

`fix` resolves the findings one at a time in severity order, runs the project's tests after each, stops if a failure has no obvious cause, and does not commit.

### 2. Plan a risky change before touching code

You are about to add a 30-day refund window to a checkout service whose tests are thin.

```text
/clean-code:plan add a 30-day refund window to the checkout service
```

You get a plan, not edits: the behavior that changes and the behavior that must not, the simplest correct change and the alternative you rejected, the first failing test, the validation commands, and an explicit cleanup budget saying which smell in the touched code you will fix and what you will leave alone. Carry it out in small steps with the pairing mode:

```text
/output-style clean-code:pair
```

In `pair` mode Claude narrates each step, runs the tests after it, and asks before anything larger than a few lines or anything that touches a public name.

### 3. Hunt smells in one module and fix the worst function

A billing module has grown. You want symptoms mapped to treatments, then one targeted fix.

```text
/clean-code:smell-hunt functions src/billing
/clean-code:extract-till-you-drop src/billing/fees.ts:applyFees
```

`smell-hunt` runs in a fork and returns at most 40 lines: a ranked table of confirmed smells (not mere grep matches), each with the skill that treats it, and the three to treat first. `extract-till-you-drop` records a test baseline, writes the outline of the function as a sentence, extracts the lowest-level named block, runs the tests, repeats, and stops before the pieces become fragments whose names only restate the code.

### 4. Finish a feature the Boy Scout way

You implemented a feature and want the touched code left cleaner, within a budget.

```text
/clean-code:boy-scout
```

It looks only at the functions and classes in your diff, picks the one smell per area that most raises the cost of the next change, applies the smallest cleanup, runs the tests and prints what it left cleaner and what it saw but left alone. Then audit the proportions:

```text
Use the clean-code:scope-guard agent to compare my diff with the request "add the refund window".
```

`scope-guard` returns a scope ledger that classifies every hunk as required, enabling cleanup, opportunistic cleanup or out of scope, with the line counts of each.

### 5. Learn the reasoning while you work

You are onboarding someone, or yourself, and want the rule behind each choice.

```text
/output-style clean-code:mentor
/clean-code:explain-rule boolean flag parameters
```

In `mentor` mode every answer does the task first, adds a short **Why** block that names the rules used, and ends with one check question. `explain-rule` gives one rule in detail: its strength (must, should or must not, taken from the source's wording), the reason, a check you can run on real code, an original example and the book's own exceptions.

### 6. Audit a repository and clean up its vocabulary

You inherit a service and want to know where the pain is before changing anything.

```text
/clean-code:audit src
/clean-code:vocabulary-audit src
```

`audit` returns a rating (healthy, watch or hot) for each cluster with evidence, and at most five ranked hot spots, each pointing to the skill that treats it. `vocabulary-audit` builds the concept-to-term table: where `get`, `fetch` and `load` all mean the same thing, where `add` means two things, and which names are public API and need a decision rather than a quiet rename.

### 7. Put a third-party SDK behind your own interface

Business logic calls a payments SDK directly, and an upgrade is coming.

```text
/clean-code:learning-tests payments sdk
```

Claude writes small tests that call the real, already-declared dependency the way you use it, records what it actually does at the edges, and drafts a narrow interface in your vocabulary. Then delegate the build:

```text
Use the clean-code:adapter-builder agent to build the PaymentGateway adapter from those findings.
```

The adapter agent defines the interface, writes the adapter, migrates callers one at a time with tests after each, and never installs a package or calls a live service.

### 8. Gate a pull request

Before you open the PR:

```text
Use the clean-code:final-gate agent on my current changes.
```

It checks the ten checklist items and six hard rules against the diff, cites evidence for each, and answers `GATE: PASS` or `GATE: FAIL` with the blocking items. For a lighter, interactive walk with next actions use `/clean-code:checklist`.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale is in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Priority and behavior | `principles`, `plan`, `boy-scout`, `scope-guard`, `lead`, `mentor`, `boy-scout` (style) |
| Core clean code principles | `principles`, `emergent-design`, `smells-surprise`, `explain-rule` |
| Naming rules | `naming`, `vocabulary-audit`, `naming-reviewer` |
| Function rules | `function-shape`, `function-contracts`, `extract-till-you-drop`, `function-reviewer`, `contract-reviewer`, `function-extractor` |
| Comment rules | `comments`, `comment-reviewer` |
| Formatting and structure | `formatting`, `layout-reviewer` |
| Objects, modules, and data structures | `data-and-objects`, `object-design-reviewer`, `smells-coupling` |
| Class and module design | `class-design`, `class-design-reviewer`, `smells-coupling` |
| Error handling | `error-handling`, `error-handling-reviewer` |
| Boundaries and external dependencies | `boundaries`, `learning-tests`, `boundary-reviewer`, `adapter-builder` |
| System construction rules | `system-construction`, `construction-reviewer` |
| Tests | `clean-tests`, `tdd-discipline`, `test-quality-reviewer`, `test-gap-reviewer`, `test-writer` |
| TDD and clean test rules | `clean-tests`, `tdd-discipline`, `test-writer`, `test-gap-reviewer` |
| Concurrency and async work | `concurrency`, `concurrency-reviewer` |
| Refactoring rules | `refactoring-steps`, `refactorer`, `fix`, `successive-refinement`, `smells-redundancy` |
| Emergent design and successive refinement | `emergent-design`, `successive-refinement`, `simplicity-reviewer`, `boy-scout` |
| Smells to detect and eliminate | `naming`, `function-shape`, `function-contracts`, `comments`, `smells-redundancy`, `smells-coupling`, `smells-surprise`, `smell-hunt`, `smell-scanner`, `smell-first` |
| Change Process | `plan`, `fix`, `refactoring-steps`, `tdd-discipline`, `pair`, `smell-first` |
| Implementation preferences | `emergent-design`, `smells-surprise`, `simplicity-reviewer` |
| Review checklist | `review`, `checklist`, `audit`, `final-gate`, `strict-reviewer` |
| Output Expectations | `fix`, `review`, `final-gate`, `terse`, `mentor` |
| Hard rules | `principles`, `checklist`, `function-contracts`, `scope-guard`, `final-gate`, `strict-reviewer` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `philosophy-of-design` | Overlap, with real tension (conflict 55%, overlap 72%) | Both govern naming, functions, comments and tests, but they pull differently on function size and comments. Pick one as primary. If you load both, make the arbiter explicit: the design book decides module and API boundaries, this plugin decides local naming, side effects and readability of touched code. |
| `clean-architecture` | Complementary (conflict 16%, overlap 35%) | It supplies dependency direction and replaceable details; this plugin supplies local decision criteria. Use both when a change involves both policy independence and local readability. The tension is boundary cost: do not add ports and adapters where a small local change will do. |
| `refactoring` | Complementary (conflict 12%, overlap 38%) | It controls safe change sequencing; this plugin defines the target shape. Use both when reshaping existing code toward these rules without changing behavior. Prefer the refactoring plugin when observable behavior must stay exactly the same. |
| `legacy-code` | Complementary (conflict 12%, overlap 38%) | When tests are weak or behavior is unclear, characterize first and create the smallest seam, then apply this plugin inside the controlled area. Prefer the legacy-code plugin until you have control. |
| `code-complete` | Overlap (conflict 30%, overlap 78%) | A broader construction guide that mostly duplicates this plugin's implementation hygiene. Prefer Code Complete for larger production construction, defensive programming and debugging; prefer this plugin for small implementation and review changes. |

The other books are generally complementary when their trigger is actually present: Release It! (production failure behavior), Designing Data-Intensive Applications (consistency and schemas), the three Domain-Driven Design books (model language and contexts), Patterns of Enterprise Application Architecture (persistence, workflow, remoting) and Refactoring.Guru (smell-driven treatment). The Pragmatic Programmer is an overlap: choose one general operating style.

**Recommended pairing.** Keep Clean Code as the one always-on rule set (`inject_rules` on) for everyday work, and bring in `refactoring` for behavior-preserving restructuring or `legacy-code` for weakly tested code on demand, per task. **Avoid loading together:** `philosophy-of-design`, `code-complete` and `the-pragmatic-programmer` alongside this plugin with equal weight and `inject_rules` on in all of them; their general guidance competes on the same decisions. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **Context cost.** Nineteen model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; disable skills you do not use, and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce code that looks tidy while missing the task. The reviewers, gate and output styles add structure, but they cannot guarantee obedience.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the mistakes your agents actually make; it will usually matter more than any generic rule.
- **Overengineering and fragmentation risk.** Applied mechanically, the small-function and extraction rules can produce many tiny helpers. The skills include the book's own brake (inline abstractions that no longer earn their cost), and `extract-till-you-drop` has an explicit stop rule, but you still need to judge.
- **Contested advice.** Function length, comment minimalism, one assertion per test and the preference for polymorphism over conditionals are debated. Where the source says "prefer", the skills say "prefer"; text labeled "Added judgment" is this plugin's own heuristic, not a rule of the source.
- **What it cannot detect.** The reviewers work by reading diffs and files. They do not execute code, so they cannot find performance problems, security flaws, race conditions that only appear at runtime, or a test that passes for the wrong reason without seeing its output. The validator for this repository checks structure and traceability, not the quality of the advice.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule (an interface naming prefix, result types instead of exceptions, a framework base class), the priority order is your instruction, then the repository, then the book.
- **The model may already know the book.** The value here is a short, decision-changing reminder plus structure, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Clean Code rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Clean Code* is by Robert C. Martin. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
