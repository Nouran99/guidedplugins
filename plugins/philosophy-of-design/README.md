# A Philosophy of Software Design

John Ousterhout's argument that the central job of software design is fighting complexity, turned into a Claude Code toolkit. It makes Claude judge a change by what it does to the next reader and the next change: deeper modules behind smaller interfaces, knowledge owned by one module, fewer flags and special cases for callers, contracts instead of narration, and evidence before added machinery.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), nine usage walkthroughs with exact commands, a map from the book's rule sections to the components, how it sits next to the other book plugins, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *A Philosophy of Software Design* starts from a plain definition: complexity is anything that makes software hard to understand or hard to change. It shows up as change amplification (a small change needs edits in many places), cognitive load (a reader must hold too many facts), and unknown unknowns (it is unclear what must change or what matters), and it grows a little with every shortcut. The book's answer is to treat design as continuous investment rather than a phase. Build deep modules whose simple interfaces hide a lot of real work; keep each design decision known by one module; shape interfaces around what callers need, not how the code works; pull complexity downward so callers do less; define errors and special cases away where the design allows it; write comments that carry contracts and reasons instead of narrating code; keep names, conventions and behavior obvious; and spend effort on performance or fashionable techniques only when evidence says it pays.

**Who this is for.** Developers using Claude Code to design or change modules and APIs in any mainstream language: adding a service, reshaping a library's public surface, reviewing a pull request that adds a layer, deciding between two designs, or untangling a feature that "should have been easy". The rules are about the shape of interfaces and the placement of knowledge, so the plugin pays off most where an agent is tempted to add a wrapper, a flag, a helper or a copy and call it done.

**The bias it corrects.** An agent that has working code tends to treat "it passes, the pieces are small, the pattern is familiar" as proof of simplicity. It wraps a library in a class that forwards every call, splits a function into five three-line helpers, adds a boolean parameter for the new caller, makes one more field public so a second module can finish the job, and puts a comment over a name that should have been changed. Each step looks like good practice; together they raise the number of facts a reader must hold and spread one decision over many files. This toolkit asks for the opposite habits, and for proportion: the improvement belongs in the code the task touches, not in a rewrite.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/philosophy-of-design:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or output style.
- One skill per decision cluster, written as rules you can check: when it applies, how to tell, what to do instead, and where the book itself lets the rule bend. Nineteen skills load on their own; the rest are commands you run by name.
- Workflows that follow what the book teaches rather than a generic review: `design-twice` (two designs scored on the rule set's four criteria), `comments-first` (write the contract before the body and revise the design if the comment gets complicated), `depth-map` (rank modules by how much they hide), `symptom-trace` (from "this was hard" to a cause, with history as evidence), and `collapse-layer` (remove a forwarding layer without losing its real logic), next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (a module depth table, a knowledge map, an interface ledger, an error-site map, a sequence map, a call-site tax table), five implementers that make small test-backed changes, a `lead` that routes work and a `final-gate` that returns PASS or FAIL against the book's review checklist.
- Six output styles that change how a whole session behaves, including `architect` (design note before code) and `complexity-ledger` (every code answer ends with a before-and-after ledger).
- Honest labeling: text marked "Added judgment" is this plugin's own heuristic. Everything else follows the modal strength of the source: where it says "prefer", the skill says "prefer".

**Where this book disagrees with others.** The compatibility notes mark one real tension: `clean-code`. The two books govern the same layer (names, functions, comments, tests) but pull differently on function size and on comments. This plugin takes the Ousterhout side on both: do not split code into shallow fragments just because a function is long, and treat contract and rationale comments as part of the design. Section "Works with other plugins" says how to load both without confusing the agent.

**When not to use it.** Reach for a different book when the real risk lies elsewhere: dependency direction between architectural layers (a Clean Architecture plugin), production failure policy such as timeouts, retries and bulkheads (a release-engineering plugin), distributed data semantics, the language of the business domain, or reshaping code that has no tests (a legacy-code plugin: characterize first, then come back). For a throwaway script the ideas still apply, but the ceremony of this toolkit does not.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install philosophy-of-design@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/philosophy-of-design
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall philosophy-of-design@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**58 components:** 30 skills (19 Claude can load on its own, 11 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/philosophy-of-design:comments-as-design` | Use when writing, reviewing or deleting comments and doc comments: contracts, invariants, hidden design decisions and rationale belong in comments; narration or excuses for poor names and structure do not. |
| `/philosophy-of-design:complexity-symptoms` | Use when a change feels awkward, one edit touches many files, a reader must reconstruct hidden dependencies, or you must judge whether a design got simpler. Names the symptom and asks the default-response questions… |
| `/philosophy-of-design:deep-modules` | Use when designing or reviewing a class, module, service or package: judge whether its interface is small and meaningful relative to the work it hides, and whether it carries its own weight. |
| `/philosophy-of-design:define-errors-away` | Use when adding validation, try/catch, null checks or error codes, or when many callers repeat the same defensive handling. Redesigns the interface or invariant so the exception case does not exist, instead of adding… |
| `/philosophy-of-design:design-alternatives` | Use before committing to a non-trivial interface, abstraction or decomposition, and whenever two or more designs are being weighed: compare at least two plausible designs on interface simplicity, information hiding… |
| `/philosophy-of-design:flags-and-knobs` | Use when the signature itself has a boolean or mode parameter that switches behavior, an options bag that keeps growing, or a callback added so one caller can override a step. Decides inside or splits by intent. Not… |
| `/philosophy-of-design:functions-and-variables` | Use when splitting a long function, extracting tiny helpers, or adding intermediate variables inside one function body: judge each by whether it hides meaningful work and captures meaning, not by line counts. |
| `/philosophy-of-design:generality-and-special-cases` | Use when an interface fits exactly one caller, an abstraction is so general it says nothing, or a few rare cases clutter the core path with conditionals. Sets the generality level and isolates special behavior. |
| `/philosophy-of-design:information-hiding` | Use when deciding where knowledge belongs: one decision or format (file format, storage shape, protocol detail, internal representation, normalization or edge handling) known by several modules, or workflow bookkeeping… |
| `/philosophy-of-design:interface-design` | Use when shaping a single public function, method, class or API element as a whole: design it around what callers need to know, not how the implementation works. Narrow but meaningful, names that reveal the… |
| `/philosophy-of-design:naming-and-obviousness` | Use when naming or renaming modules, methods, parameters and variables, when related operations differ in naming or argument order, or when code surprises a reader. Names reveal the abstraction; surprise counts as… |
| `/philosophy-of-design:pass-through-layers` | Use when a class, service, facade, adapter or helper module mostly forwards calls, wraps a library without simplifying it, or only renames obvious operations; also before adding such a layer. |
| `/philosophy-of-design:performance-and-trends` | Use when asked to optimize, when a cache or micro-optimization is proposed, or when a pattern, paradigm, framework or fashionable technique is about to be adopted. Requires evidence and hides optimizations behind… |
| `/philosophy-of-design:principles` | Applies A Philosophy of Software Design to module, API and refactoring decisions. Use for any task that creates, reviews or changes code where complexity, module depth, information hiding, interface shape or tactical… |
| `/philosophy-of-design:pull-complexity-down` | Use when the same preparation, normalization or default-choosing lines are repeated at the call sites of one callee, or every caller must remember a rule to call it correctly. The fix is more work inside the callee.… |
| `/philosophy-of-design:split-or-merge` | Use when deciding whether to extract, split or merge units larger than a function (classes, files, services, packages), or when understanding one idea means jumping through shallow fragments or a module hides two… |
| `/philosophy-of-design:strategic-programming` | Use when the change is a deadline patch or a copy-paste of existing code, the same workaround is about to appear a third time, or recurring friction suggests reshaping an abstraction. Sizes the design investment; it… |
| `/philosophy-of-design:temporal-decomposition` | Use when code is organized as prepare/process/finalize phases, objects need staged calls before use, init/open/configure sequences exist, or callers must know a hidden call order. |
| `/philosophy-of-design:testing-through-interfaces` | Use when writing or reviewing tests for modules with hidden complexity: test public behavior and contracts, add focused tests for isolated special cases, and avoid tests that need implementation details or force leaky… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/philosophy-of-design:audit` | Scan a directory or repository for complexity health in a forked context and return clusters rated healthy, watch or hot plus ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/philosophy-of-design:checklist` | Walk the book's final checklist against the current work with yes, no or not-applicable per item and a concrete next action for every no. | `[paths \| git ref \| empty for the current diff]` |
| `/philosophy-of-design:collapse-layer` | Remove a forwarding layer or merge shallow fragments safely: move any real logic to the owner, repoint callers in small steps with tests, then delete the layer. Never commits. | `[class, file or module to collapse \| empty to ask]` |
| `/philosophy-of-design:comments-first` | Draft the interface contract and explanatory comments for a module before writing its body, and revise the abstraction when the comment gets complicated. Outputs stubs, not implementations. | `[module, class or function to design \| paths \| empty to draft contracts for new public elements in the diff]` |
| `/philosophy-of-design:depth-map` | Inventory the modules in a scope by interface weight and hidden work in a forked context, and return the shallow and pass-through ones ranked, in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/philosophy-of-design:design-twice` | Write two or more designs for an interface or module as call sites, score them on the rule set's four criteria, choose one and record the price. Does not edit. | `[problem statement \| paths \| empty to compare the design in the current diff]` |
| `/philosophy-of-design:explain-rule` | Explain one rule of A Philosophy of Software Design: its modal strength, the reason, how to check it, an original example and where the book allows an exception. | `[rule name \| topic \| upstream section \| empty to list topics]` |
| `/philosophy-of-design:fix` | Resolve given design findings with the smallest change per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/philosophy-of-design:plan` | Plan a non-trivial change with the book's generation sequence: concept, narrowest interface, hidden details, caller impact, special cases, alternatives and scope. Does not edit. | `[task description \| issue text \| paths \| empty to plan from the current diff]` |
| `/philosophy-of-design:review` | Review a diff or paths against A Philosophy of Software Design and report findings ranked by complexity cost. | `[paths \| git ref \| empty for the current diff]` |
| `/philosophy-of-design:symptom-trace` | Trace a complaint such as 'this change touched too many files' or 'I cannot follow this' from the symptom to its likely cause with history evidence, and name the skill that treats it. | `[complaint text \| paths \| git ref \| empty to look for co-changing files in recent history]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-philosophy-of-design:caller-burden-reviewer` | sonnet | read-only | Reviewer of work pushed onto callers: repeated setup, conversions, guards and workarounds around one function that its owner could absorb. Use proactively after edits that add a parameter, a… |
| `@agent-philosophy-of-design:comment-reviewer` | sonnet | read-only | Reviewer of comments as design: gives every comment in the change a disposition and lists public elements that lack a contract. Use proactively after edits that add or alter doc comments, inline… |
| `@agent-philosophy-of-design:complexity-reviewer` | sonnet | read-only | Reviewer of the net complexity change in a diff, judged by symptom: change amplification, cognitive load, unknown unknowns, hidden dependencies, spread and temporal coupling. Use proactively after a… |
| `@agent-philosophy-of-design:contract-writer` | sonnet | can edit files | Implementer that edits comments only: writes interface contracts, invariants and decision notes, deletes narration, and reports where a contract cannot be written briefly. Use when public elements… |
| `@agent-philosophy-of-design:depth-reviewer` | sonnet | read-only | Reviewer of module depth: interface weight against hidden work, and pass-through layers, thin wrappers and rename-only helpers. Use proactively after edits that add classes, services, wrappers… |
| `@agent-philosophy-of-design:evidence-reviewer` | sonnet | read-only | Reviewer of added complexity that claims a benefit: optimizations, caches, patterns, frameworks and paradigms. Checks for evidence, and for the complexity staying behind a stable interface. Use… |
| `@agent-philosophy-of-design:exception-reviewer` | sonnet | read-only | Reviewer of error surface: exceptions, error codes, null checks and validation that could be defined away, handled inside the module, or must stay. Use proactively after edits that add throws… |
| `@agent-philosophy-of-design:final-gate` | sonnet | read-only | Pre-merge gate that runs the book's review checklist against the working diff and returns PASS or FAIL with evidence per item. Use before declaring work done, committing, or opening a pull request. |
| `@agent-philosophy-of-design:function-depth-reviewer` | sonnet | read-only | Reviewer of function bodies and variables: fragment chains, pass-through variables, syntax-mirroring names, leaked intermediate state and long functions that really mix concepts. Use proactively… |
| `@agent-philosophy-of-design:interface-reviewer` | sonnet | read-only | Reviewer of public interface shape: boolean and mode parameters, option bags, mechanism-revealing arguments and caller-oriented signatures. Use proactively after edits that add or change a public… |
| `@agent-philosophy-of-design:interface-simplifier` | sonnet | can edit files | Implementer that replaces boolean and mode parameters, option bags and mechanism-revealing arguments with caller-oriented operations and updates the callers. Collapses a setup sequence only when a… |
| `@agent-philosophy-of-design:lead` | opus | read-only | Triage lead for A Philosophy of Software Design work. Use first on any non-trivial change or review to decide which specialist reviewers, implementers and skills apply, in what order, and how much… |
| `@agent-philosophy-of-design:leakage-reviewer` | sonnet | read-only | Reviewer of information hiding: which modules know a format, storage shape, protocol, representation or piece of bookkeeping. Use proactively after edits that add public members, change data shapes… |
| `@agent-philosophy-of-design:module-deepener` | sonnet | can edit files | Implementer that collapses forwarding layers, merges shallow fragments and moves work repeated by callers into the owning module, in small test-backed steps. Use when review findings or a depth map… |
| `@agent-philosophy-of-design:naming-reviewer` | sonnet | read-only | Reviewer of names and obviousness: mechanism-revealing or vague names, inconsistent sibling operations, and behavior that would surprise a reader. Use proactively after edits that add public names… |
| `@agent-philosophy-of-design:special-case-isolator` | sonnet | can edit files | Implementer that moves rare-case branches out of a core path into named, isolated places while keeping behavior identical, after pinning each moved case's current behavior. Use when review findings… |
| `@agent-philosophy-of-design:special-case-reviewer` | sonnet | read-only | Reviewer of generality and special cases: interfaces fitted to one caller, abstractions too vague to say anything, and rare branches cluttering core paths. Use proactively after edits that add… |
| `@agent-philosophy-of-design:split-merge-reviewer` | sonnet | read-only | Reviewer of boundaries between units: extractions, new files, classes and services, and boundaries kept by habit. Decides keep, merge or split by total complexity. Use proactively after edits that… |
| `@agent-philosophy-of-design:tactical-patch-reviewer` | sonnet | read-only | Reviewer of how a change was made: quick symptom patches, copy-paste, extra flags, newly exposed details and added exception paths versus structural fixes. Use proactively after bug fixes and… |
| `@agent-philosophy-of-design:temporal-reviewer` | sonnet | read-only | Reviewer of time-shaped design: prepare/process/finalize modules, init-before-use objects, required call orders and partial objects, and where each ordering rule is enforced. Use proactively after… |
| `@agent-philosophy-of-design:test-contract-reviewer` | sonnet | read-only | Reviewer of how tests couple to the design: assertions on private state or call order, members exposed only for tests, missing tests for isolated special cases. Use proactively after tests are added… |
| `@agent-philosophy-of-design:test-writer` | sonnet | can edit files | Implementer that writes tests from a stated contract, one per guarantee and edge behavior, through the public interface only. Use when a module's promises are unpinned, before or after a structural… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style philosophy-of-design:architect` | Designs before coding: states the abstraction, the narrowest interface, what it hides and what callers no longer need to know, and compares two designs for non-trivial choices. |
| `/output-style philosophy-of-design:complexity-ledger` | Ends every code answer with a short complexity ledger: facts a reader must hold, files a similar future change touches, special cases at call sites, public surface and net direction, before and after. |
| `/output-style philosophy-of-design:mentor` | Teaches the design principle behind each decision, names it, shows what it costs a reader, and checks understanding with one short question. |
| `/output-style philosophy-of-design:pair` | Works in small narrated steps, says what complexity each step removes, and asks before any change larger than a few lines, a new module or layer, or anything touching public API. |
| `/output-style philosophy-of-design:strict-reviewer` | Answers as a ranked findings table with the complexity cost of each finding, rewrites no code unless asked, and says No findings explicitly. |
| `/output-style philosophy-of-design:terse` | Result first, no preamble, a few lines unless asked, with failing output still in full. Brevity applies to prose, never to the clarity of the design. |

<!-- COMPONENTS:END -->

**How the pieces fit.** `philosophy-of-design:lead` reads a task or diff and names which specialists and skills apply, in order, without reviewing anything itself. Before anything is built, `design-twice` and `comments-first` test a design cheaply. The specialist reviewers each look at one concern and report in their own format, so a depth table, a knowledge map and an interface ledger never blur together. The implementers (`module-deepener`, `interface-simplifier`, `special-case-isolator`, `contract-writer`, `test-writer`) make small, test-backed changes inside the scope they were given and never commit. `final-gate` closes the loop by running the book's review checklist and refusing to pass on missing evidence. Output styles sit beside all of this and change the manner of the whole session.

## Usage walkthroughs

### 1. Review the work in progress

You have edited a few files and want a second opinion before you stage anything.

```text
/philosophy-of-design:review
```

With no argument it runs `git status` and `git diff`, works out which concerns the change touches (public signatures, new layers, shared knowledge, error handling, special cases, comments, names, tests), applies those skills, and prints findings ranked blocker to nit. Each finding has a `file:line`, the rule by name, the complexity cost in terms of who must now know or do what, and the smallest fix. The header says whether net complexity went down, stayed flat or went up. If it finds nothing it prints `No findings` and lists what it checked. To act on the result:

```text
/philosophy-of-design:fix last review
```

`fix` resolves the findings one at a time in severity order, runs the project's tests after each, stops and asks if a finding would change what a public operation means, and does not commit.

### 2. Decide between two designs before building

You need to send reminders only to users who want them, and the first idea (check preferences in every sender) is already forming.

```text
/philosophy-of-design:design-twice send a reminder only when the user wants one
/philosophy-of-design:comments-first Reminders module
```

`design-twice` writes at least two designs as call sites with a contract each, scores them on interface simplicity, information hiding, special-case reduction and future cognitive load, and names the winner, the price you accept and what new fact would change the choice. `comments-first` then drafts the winner's interface comments as signatures with no bodies and runs the complexity test: if a comment needs "unless", mentions a mechanism or describes a required call order, it reports the design change that fixes the comment instead of polishing the prose. When the design is settled:

```text
/philosophy-of-design:plan add reminders and migrate the seven senders
```

### 3. Find shallow modules and collapse one

A service layer has grown and nobody is sure what it does.

```text
/philosophy-of-design:depth-map src
```

This runs in a forked context and returns at most 40 lines: each module with its public elements, what it hides, how many files call it, and a verdict of deep, adequate, shallow or pass-through, with the shallow ones ranked by callers. Then pick one:

```text
/philosophy-of-design:collapse-layer src/billing/BillingService.ts
```

`collapse-layer` lists the layer's methods and callers, classifies each as forwarding, translating, validating or real logic, refuses to remove a layer that translates a vendor vocabulary, moves any real logic into the owning module first, repoints callers in small groups with the tests run after each, and only then deletes the layer. For several layers at once delegate to `philosophy-of-design:module-deepener`.

### 4. Understand why a change touched nine files

Adding a currency took edits in nine files and you want to know why, not only how to make the pain stop.

```text
/philosophy-of-design:symptom-trace adding the EUR currency touched nine files
```

The skill classifies the complaint as change amplification, gathers evidence with read-only history (`git log --stat` for the files that changed together, a search for the shared literal), answers the five default-response questions with a file and line each, and names the likely cause: here, one decision (how an amount is written) known by many modules. It routes to `/philosophy-of-design:information-hiding` and `/philosophy-of-design:pull-complexity-down` and gives the first concrete step. It does not edit anything.

### 5. Learn the reasoning while you work

You want the changes made and the principles explained as you go, for a junior teammate or for yourself.

```text
/output-style philosophy-of-design:mentor
```

Each answer does the task first, then adds a short Why block naming the idea applied (deep module, information hiding, defining an error away) and what it saved a reader, then ends with one concrete question such as how many modules you would edit if the file format changed. To look at one rule in isolation:

```text
/philosophy-of-design:explain-rule flags
```

You get the rule's modal strength and the source word that sets it, the reason, how to check it, a small original example, the exception the book allows, and which lines are this plugin's own heuristics.

### 6. Route and gate a pull request

You are about to open a pull request that adds an `OrderService`, a new options parameter and a cache.

```text
Use the philosophy-of-design:lead agent on my working diff.
```

`lead` returns an ordered plan: perhaps `depth-reviewer` for the new service, `interface-reviewer` for the options parameter, `evidence-reviewer` for the cache, then the gate, with a restructuring budget that says what to fix now and what to propose later. Run the reviewers it names, then:

```text
Use the philosophy-of-design:final-gate agent.
```

`final-gate` evaluates the review checklist item by item with evidence and returns `GATE: PASS` or `GATE: FAIL`, listing the blocking items. An item without evidence counts as unknown and fails.

### 7. Audit a repository

You inherit a service and want a health picture before touching it.

```text
/philosophy-of-design:audit services/payments
```

In a forked context it samples up to fifteen files, probes depth, knowledge placement, interfaces, caller burden, special cases, time structure, comments, functions, tests and tactical debt with read-only searches, rates each cluster healthy, watch or hot, ranks at most five hot spots by the cost of the next change, and ends with a single next command, for example `/philosophy-of-design:depth-map services/payments`. The thresholds it uses to find candidates are search aids labelled as such, not rules of the book.

### 8. Replace flags and setup sequences

A reviewer has flagged a `fetch_report(id, use_cache, refresh, raw, fmt)` function and an exporter that needs eight calls.

```text
Use the philosophy-of-design:interface-reviewer agent on src/reports.
Use the philosophy-of-design:temporal-reviewer agent on src/reports.
Use the philosophy-of-design:interface-simplifier agent to resolve the findings in src/reports.
```

The interface reviewer produces an interface ledger and the three most common call sites as they read today, and judges the `fetch_report` flags. It does not judge the exporter: it notes the eight-call open, configure, write, close ritual under "Handed off". The temporal reviewer then maps that sequence, records where each ordering rule is enforced (or that none is) and returns a finding that names the exporter. The simplifier resolves both sets of findings: per parameter it decides whether the callee should decide, the operation should split by intent, or the option is real and should stay named and optional; it collapses the exporter setup into one call because the temporal finding names it; it writes the new call sites first, keeps a deprecated shim for public elements, migrates callers in groups with the tests run after each, and reports meaning changes as decisions needed from you. Without the temporal review (or an explicit instruction from you to collapse the exporter), the simplifier leaves the setup sequence under "Needs a decision".

### 9. Run a design-first session

You are starting a new module and want the design on the table before any code.

```text
/output-style philosophy-of-design:architect
```

For every task that adds or changes a module or public interface, Claude first prints a design note of at most fifteen lines (abstraction, three call sites, what it hides, what callers no longer need to know, isolated special cases, the contract), compares two designs when the choice is non-trivial, and only then writes code, followed by a one-line depth check. Trivial edits skip the note. Switch to `/output-style philosophy-of-design:complexity-ledger` to end every code answer with a before-and-after ledger instead.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale is in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Purpose | `principles`, `explain-rule`, `mentor` |
| Primary Directive | `principles`, `complexity-symptoms`, `design-twice`, `explain-rule`, `lead`, `terse` |
| Core Complexity Rules | `complexity-symptoms`, `symptom-trace`, `audit`, `complexity-reviewer`, `complexity-ledger` |
| Module Depth Rules | `deep-modules`, `pass-through-layers`, `depth-map`, `collapse-layer`, `depth-reviewer`, `module-deepener` |
| Information Hiding Rules | `information-hiding`, `leakage-reviewer` |
| Interface Design Rules | `interface-design`, `flags-and-knobs`, `temporal-decomposition`, `interface-reviewer`, `interface-simplifier` |
| Strategic Programming over Tactical Programming | `strategic-programming`, `plan`, `fix`, `pair`, `tactical-patch-reviewer` |
| General-Purpose vs Special-Purpose Modules | `generality-and-special-cases`, `special-case-reviewer` |
| Error Handling and Exception Elimination | `define-errors-away`, `exception-reviewer` |
| Pull Complexity Downward | `pull-complexity-down`, `collapse-layer`, `caller-burden-reviewer`, `module-deepener` |
| Comment Rules | `comments-as-design`, `comments-first`, `comment-reviewer`, `contract-writer` |
| Function and Variable Rules | `functions-and-variables`, `split-or-merge`, `function-depth-reviewer` |
| Temporal Decomposition Rules | `temporal-decomposition`, `temporal-reviewer` |
| Special-General Decomposition | `generality-and-special-cases`, `special-case-reviewer`, `special-case-isolator` |
| Combine or Separate Code | `split-or-merge`, `pass-through-layers`, `split-merge-reviewer`, `pair` |
| Design Alternatives and Comments-First Design | `design-alternatives`, `design-twice`, `comments-first`, `architect`, `contract-writer` |
| Naming, Consistency, and Obviousness | `naming-and-obviousness`, `naming-reviewer` |
| Performance, Trends, and Tests | `performance-and-trends`, `testing-through-interfaces`, `evidence-reviewer` |
| Review Rules | `review`, `audit`, `symptom-trace`, `lead`, `strict-reviewer` |
| Forbidden Patterns | `review`, `audit`, `final-gate`, `strict-reviewer` |
| Code Generation Rules | `plan`, `architect`, `interface-design`, `pull-complexity-down` |
| Testing Rules | `testing-through-interfaces`, `test-contract-reviewer`, `test-writer` |
| Review Checklist | `checklist`, `final-gate`, `review`, `complexity-ledger` |
| Final Instruction | `principles`, `checklist`, `final-gate`, `terse` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting, with conflict, overlap and complementarity percentages. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `clean-code` | Overlap, with real tension (conflict 55%, overlap 72%, complementarity 42%) | Both govern naming, decomposition, comments and tests, but they pull differently on function size and on comments. Choose one as the primary design and hygiene rule set. If you load both, make the arbiter explicit: this plugin decides module depth, API shape, decomposition and comment contracts; Clean Code decides local naming, side effects and readability of touched code. Otherwise an agent can split code until one book is satisfied while the other calls the split shallow. |
| `refactoring` | Complementary (conflict 28%, overlap 46%, complementarity 74%) | One book defines what a better design looks like, the other how to get there without hidden behavior change. Use both for behavior-preserving restructuring toward deeper modules; let the refactoring plugin arbitrate sequencing and scope, and this plugin decide whether the target actually reduces complexity. |
| `clean-architecture` | Complementary (conflict 28%, overlap 44%, complementarity 68%) | Clean Architecture sets policy and detail boundaries; this plugin then rejects ports, adapters and layers that only add pass-through complexity. Use both when boundaries are being introduced or repaired, and prefer Clean Architecture when policy independence is the actual risk. |
| `ddd` | Complementary (conflict 14%, overlap 38%, complementarity 74%) | Domain language, invariants and bounded contexts drive the model; this plugin judges whether the resulting modules and interfaces are deep and leak nothing. The tension is ceremony: tactical patterns must protect model meaning and not add layers for their own sake. The same verdict holds for `ddd-distilled` and `ddd-implementing`. |
| `legacy-code` | Complementary (conflict 12%, overlap 38%, complementarity 78%) | When tests are weak or behavior is unclear, characterize first and create the smallest seam, then apply this plugin inside the controlled area. Prefer the legacy-code plugin until you have control. |

The other books are generally complementary when their trigger is actually present: `release-it` (production failure behavior; reliability mechanisms add complexity and must be scoped to real failure modes), `data-intensive-apps` (source of truth, consistency and schema evolution come before abstractions that hide them; complementarity 80%), `enterprise-patterns` (persistence, workflow and remoting patterns, chosen by force and not by habit) and `refactoring-guru` (smell diagnosis and stop conditions). `code-complete` and `pragmatic-programmer` are complementary but share the most general guidance (overlap 50%): choose a primary rule set when both try to govern the same local code-shape decision.

**Recommended pairing.** Keep this plugin as the one always-on rule set (`inject_rules` on) when your work is mostly module and API design, and bring in `refactoring` for behavior-preserving restructuring or `legacy-code` for weakly tested code, on demand and per task. **Avoid loading together:** `clean-code` or `code-complete` alongside this plugin with equal weight and `inject_rules` on in all of them; their general guidance competes on the same decisions. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **Context cost.** Nineteen model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; install only the book plugins you need, because Claude Code's per-skill overrides do not apply to plugin skills and the whole plugin is the smallest unit you can turn off; and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce code that sounds principled while missing the task. The reviewers, gate and output styles add structure, but they cannot guarantee obedience.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the mistakes your agents actually make; it will usually matter more than any generic rule.
- **Depth is a judgment, not a metric.** No tool here measures how deep a module is. `depth-map` and `depth-reviewer` read code and compare an interface with the work behind it; two careful readers can disagree about a borderline module. The counts and sizes used to find candidates are search aids, labelled as Added judgment, not rules of the book.
- **Overcorrection risk.** Applied mechanically, "prefer deep modules" and "pull complexity downward" can produce large classes that do too much, or push a business choice into a place that cannot know it. The skills carry the brakes the book gives (pull down only what the owner can know; keep a narrow override; separate by real design decisions), and `split-or-merge` can demand a split as readily as a merge, but you still need to judge.
- **Contested advice.** The book's stance on function length and on comments differs from some popular guides, and its advice to define errors away trades explicit failures for broader contracts. Where the source says "prefer", the skills say "prefer"; text labeled "Added judgment" is this plugin's own heuristic, not a rule of the source.
- **What it cannot detect.** The reviewers work by reading diffs and files. They do not execute code, so they cannot find performance problems, race conditions that only appear at runtime, or a test that passes for the wrong reason, and `evidence-reviewer` cannot run benchmarks; it asks for the numbers. The validator for this repository checks structure and traceability, not the quality of the advice.
- **Overengineering and ceremony.** For a small, local change the full toolkit is too much. The `lead` agent and the proportionality rule in the hub exist to say so; use them, or just use `/philosophy-of-design:review`.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule (a framework-mandated controller class, a doc-comment style, a lint rule on function length), the priority order is your instruction, then the repository, then the book.
- **The model may already know the book.** The value here is a short, decision-changing reminder plus structure, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed A Philosophy of Software Design rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *A Philosophy of Software Design* is by John Ousterhout. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
