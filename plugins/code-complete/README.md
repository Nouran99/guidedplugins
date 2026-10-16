# Code Complete

Steve McConnell's working rules for software construction, turned into a Claude Code toolkit. It makes Claude settle what it is building before it codes, shape routines, data and branches so a reader can verify them, decide explicitly what happens at the edges of every input and assumption, and let evidence rather than a guess drive fixes, refactors and tuning.

Below the overview you will find the generated component list (skills, subagents and output styles), nine usage walkthroughs with exact commands, a map from the rule set's sections to the components, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *Code Complete* is a long, practical handbook on software construction: the design, coding, debugging and testing work that turns a design into working code. The rule set this toolkit applies says that disciplined construction practices reduce defects, improve readability and keep code robust under real-world constraints, and that what you settle before coding (requirements, architecture, major risks, conventions) matters as much as the coding itself. Prepare before large changes. Design routines with one purpose. Make data say what it means. Keep control flow simple enough to verify. Defend the program against bad input and wrong assumptions. Review, test and debug on purpose. Tune only with measurements. Write for the human who reads it next.

**Who this is for.** Developers using Claude Code on production code in any mainstream language, especially where a late defect is expensive: implementing features, reviewing pull requests, fixing bugs, hardening input handling, speeding something up, teaching a team. The rules operate at the level of routines, statements, data and classes, so the plugin pays off most on everyday construction work where an agent tends to stop as soon as the first scenario passes.

**The bias it corrects.** An agent asked for a feature starts from the first solution that comes to mind, writes the happy path, trusts every caller, adds a boolean when one case differs, leaves a `-1` that means "none", nests one more `if`, and reports success because the one scenario it tried passed. This toolkit pushes the opposite order of attention: know what you are building, make each routine, datum and branch inspectable, decide what happens at the edges, and get evidence before changing anything because of a guess. It also carries the rule set's own brake: no cleverness, no fashionable idioms and no speculative code that makes the result harder to inspect.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/code-complete:principles`) that loads the compact rules first, the full rules only when needed, labels where each piece of guidance comes from, and routes every situation to a specific skill, agent or mode.
- One skill per rule cluster, written as decisions rather than slogans: when it applies, how to check it, what to do instead, and where the source itself allows an exception. Routine body versus routine signature, variable lifetime versus data meaning, branch shape versus loops, external input versus internal assumptions versus the failure path are separate skills with discriminating triggers.
- Honest provenance. A rule with no label is stated in the full rule set. **Compact rule** marks guidance found only in the short files. **Added judgment** marks this plugin's own heuristics; the source gives no numeric limits, so every number in these skills is a search aid, not a verdict.
- Ten manual workflows named for what the book teaches: `plan`, `pseudocode`, `trust-boundary-scan`, `test-matrix` and `tune`, next to `review`, `audit`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (routine ledger, signature ledger, decode list, branch-and-loop map, mapping inventory, boundary inventory, assumption ledger, failure-path map, responsibility statements, hot list, comment ledger, deviation list, contract-to-case map, evidence table), four implementers that make small test-backed changes, a mechanical scanner, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `assumptions-first` and `evidence-first`.

**When not to use it.** Reach for a different book when the real risk lies elsewhere: dependency direction and policy independence between layers (a `clean-architecture` plugin), module depth and interface trade-offs (a `philosophy-of-design` plugin), reshaping code that has no tests (a `legacy-code` plugin), production failure behavior such as timeouts, retries and overload (a `release-it` plugin), or distributed data semantics (a `data-intensive-apps` plugin). For a throwaway script the rules still apply, but the ceremony of this toolkit does not.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install code-complete@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/code-complete
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall code-complete@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**58 components:** 30 skills (20 Claude can load on its own, 10 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/code-complete:assertions-and-contracts` | Use when a routine relies on assumptions about inputs, state or results: write preconditions, postconditions, invariants; choose assertion, validation or domain error. External input: /code-complete:trust-boundaries.… |
| `/code-complete:class-design` | Use when a class or module has several responsibilities, exposes internals, mixes persistence, formatting, business rules and integration, or reaches into another's internals. Covers cohesion and coupling. One routine… |
| `/code-complete:coding-standards` | Use when naming, formatting, file structure or idioms diverge from the codebase, or when reformatting and renaming noise appears in a diff that is not about style. Comment content belongs to /code-complete:comments. |
| `/code-complete:comments` | Use when adding, reviewing or deleting comments, or when a comment restates code, is stale, or props up unclear code. Comments keep intent, rationale, contracts. Style and layout: /code-complete:coding-standards. |
| `/code-complete:complexity-management` | Use when code is hard to hold in your head: tangled routines, duplicated logic, clever expressions, growing special cases. One branch: /code-complete:control-flow. One routine: /code-complete:routine-design. To… |
| `/code-complete:construction-process` | Use before a non-trivial change: work starting from a proposed solution, unsettled decisions, or slicing into verifiable increments with early integration. Written plan: /code-complete:plan. One routine… |
| `/code-complete:control-flow` | Use when branches are hard to verify: deep nesting, compound conditions, switch statements, multiple exits, dead branches, side-effecting conditions. Loops and statement order: /code-complete:statements-and-loops.… |
| `/code-complete:data-types` | Use when a value's meaning must be decoded: magic numbers, sentinels like -1, units, boolean flags, status strings, parallel arrays. Choose types and constants. Variable lifetime: /code-complete:variables. Flag… |
| `/code-complete:debugging` | Use when something fails, throws, hangs or returns wrong results and the cause is unknown: reproduce, isolate, explain, fix, verify, add the regression test. No known failure: /code-complete:routine-testing. Designing… |
| `/code-complete:error-handling` | Use when writing or reviewing the failure path: exceptions, error codes, catch blocks, messages, fallbacks. Unknown cause: /code-complete:debugging. Valid input: /code-complete:trust-boundaries. Programmer errors… |
| `/code-complete:performance-tuning` | Use when asked to optimize or speed up, or when a change trades clarity for speed. Needs a requirement and before/after numbers. No speed goal: /code-complete:refactoring-judgment or /code-complete:complexity-management. |
| `/code-complete:principles` | Applies the Code Complete rules to everyday construction work: any task that writes, changes, reviews, debugs or tunes code where defect risk, readability, data meaning, control flow or tests matter. A matching topical… |
| `/code-complete:refactoring-judgment` | Use when deciding whether and how to refactor: structure hides intent, duplicates knowledge or raises defect risk, or refactoring mixes with behavior change or no tests. Symptoms: /code-complete:complexity-management.… |
| `/code-complete:routine-design` | Use when writing or reviewing a routine's body and name: unclear purpose, a name that does not fit, validation, computation and side effects mixed, hidden effects. Signatures: /code-complete:routine-interface. Tangles… |
| `/code-complete:routine-interface` | Use when a routine's signature is the problem: long parameter lists, boolean mode flags, unrelated parameters, or return values that are easy to misuse. Body and naming: /code-complete:routine-design. Flag fields and… |
| `/code-complete:routine-testing` | Use when writing or reviewing tests for a routine: normal, boundary and invalid inputs, defensive checks, contract alignment, table-driven cases. A failure of unknown cause: /code-complete:debugging. |
| `/code-complete:statements-and-loops` | Use when writing or reviewing loops and straight-line code: loop start, stop and update, bloated loop bodies, statement order, negated conditions, normal-path placement. Branch shape: /code-complete:control-flow. |
| `/code-complete:table-driven` | Use when repeated if/else or switch chains map stable categories, ranges, conversions or dispatch to results, or a lookup table needs validating. Other branch problems: /code-complete:control-flow. |
| `/code-complete:trust-boundaries` | Use when code takes input from users, files, networks, other services or callers you do not control: decide what is validated, rejected, recovered, logged. Internal assumptions: /code-complete:assertions-and-contracts.… |
| `/code-complete:variables` | Use when a variable is vaguely named, declared far from use, reused for a second meaning, uninitialized or mutable without need. Types, constants, units, sentinels: /code-complete:data-types. |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/code-complete:audit` | Scan a directory or repository for Code Complete construction health in a forked context and return cluster ratings and ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/code-complete:checklist` | Walk the Code Complete review checklist against your current change with yes, no or n/a per question and a next action for each no. | `[paths \| empty for the current diff]` |
| `/code-complete:explain-rule` | Explain one Code Complete rule: its strength (binding, strong default or forbidden), the reason, how to check it, an original example and the source's own exceptions. | `[rule name \| upstream section \| situation you are unsure about]` |
| `/code-complete:fix` | Resolve given Code Complete findings with the smallest change per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/code-complete:plan` | Plan a non-trivial change before editing: restate the requirement, settle the construction decisions, list risks, cut verifiable increments and choose the test cases. Does not edit. | `[task description \| issue text \| empty to plan around the current diff]` |
| `/code-complete:pseudocode` | Design one complex routine with the Pseudocode Programming Process: sketch the steps, refine them to one abstraction level, convert to code, then prune the comments that only restate code. | `[routine description \| file:routine \| empty to ask]` |
| `/code-complete:review` | Review a diff or paths against the Code Complete rules and report ranked findings with file, line, rule, consequence and the smallest fix. | `[paths \| git ref \| empty for the current diff]` |
| `/code-complete:test-matrix` | Derive the normal, boundary, invalid and defensive-check test cases for one routine from its contract, as a table, before any test is written. Does not edit. | `[file:routine \| routine name \| empty to use the routine in the current diff]` |
| `/code-complete:trust-boundary-scan` | Inventory the places where external input enters a directory or repository, in a forked context, and rate how each one validates, rejects, recovers, asserts and stays diagnosable. At most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/code-complete:tune` | Run a measured tuning loop on one target: confirm the requirement, take a baseline, change one thing, remeasure, keep or revert, and record the clarity trade-off. Never commits. | `[routine or endpoint to speed up \| requirement such as 'p95 under 200 ms' \| empty to ask]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-code-complete:boundary-hardener` | sonnet | can edit files | Implementer that adds boundary validation and internal assertions where review found a defensive gap, converting raw input to a typed value at the entry and adding rejection tests. Use when… |
| `@agent-code-complete:bug-fixer` | sonnet | can edit files | Implementer that fixes one reproduced defect by diagnosis: reproduce, isolate, explain, fix the root cause with the smallest change, add the regression test, verify. Use when a failure has an… |
| `@agent-code-complete:class-design-reviewer` | sonnet | read-only | Reviewer of class and module design: single responsibility, cohesion, exposed representation, mixed persistence, formatting and business concerns, and coupling to internals. Use proactively after… |
| `@agent-code-complete:comment-reviewer` | sonnet | read-only | Reviewer of comments: each gets a disposition of keep, rewrite, delete or replace with code. Use proactively after edits that add or change comments, leave commented-out code, or alter code that has… |
| `@agent-code-complete:complexity-reviewer` | sonnet | read-only | Reviewer of rising complexity: tangled routines, duplicated rules, dense clever expressions and special-case growth. Use proactively after edits that add flags or special cases, copy a block, or… |
| `@agent-code-complete:consistency-reviewer` | sonnet | read-only | Reviewer of consistency with the surrounding codebase: naming, idioms, layout, file structure and unrelated reformatting. Use proactively after edits that add new files or modules, or when a diff… |
| `@agent-code-complete:construction-scanner` | haiku | read-only | Mechanical scanner that produces a census of construction candidates with numbers and locations: routine lengths, parameter counts, nesting, boolean parameters, literals, empty handlers… |
| `@agent-code-complete:contract-reviewer` | sonnet | read-only | Reviewer of the assumptions between routines: preconditions, postconditions, invariants, and whether each check is an assertion, validation or domain error. Use proactively after edits to routines… |
| `@agent-code-complete:control-flow-reviewer` | sonnet | read-only | Reviewer of branches, loops and statement order: nesting, compound conditions, exits, dead branches, loop termination and update, negated conditions. Use proactively after edits that add conditions… |
| `@agent-code-complete:data-reviewer` | sonnet | read-only | Reviewer of data meaning and variable lifetime: magic values, sentinels, units, boolean flags, closed sets, scope, initialization and variable reuse. Use proactively after edits that add literals… |
| `@agent-code-complete:error-flow-reviewer` | sonnet | read-only | Reviewer of failure paths: handler level, preserved context, consistency across routines, swallowed errors and silent fallbacks. Use proactively after edits that add try/catch, catch blocks, error… |
| `@agent-code-complete:final-gate` | sonnet | read-only | Pre-merge gate that runs the Code Complete review checklist and the five forbidden patterns against the working diff and returns PASS or FAIL with evidence. Use before declaring work done… |
| `@agent-code-complete:increment-reviewer` | sonnet | read-only | Reviewer of the shape of a change as an increment: behavior mixed with refactoring, hunks that cannot be verified alone, stranded or orphaned partial work. Use proactively after a sizeable edit and… |
| `@agent-code-complete:interface-reviewer` | sonnet | read-only | Reviewer of routine signatures: parameter lists, boolean mode flags, unrelated parameters and return values that are easy to misuse. Use proactively after edits that add or change a signature or add… |
| `@agent-code-complete:lead` | opus | read-only | Triage lead for Code Complete work. Use first on any non-trivial change or review to decide which specialist reviewers, implementers and skills apply, and in what order. Routes only; does not review… |
| `@agent-code-complete:refactorer` | sonnet | can edit files | Implementer that carries out behavior-preserving structural changes in small, test-backed steps against named findings. Use when review findings or a plan call for renames, extractions, guard… |
| `@agent-code-complete:routine-reviewer` | sonnet | read-only | Reviewer of routine purpose, name, phase separation and hidden effects. Use proactively after edits that add or lengthen routines, mix validation with computation and writes, or rename a routine. |
| `@agent-code-complete:table-reviewer` | sonnet | read-only | Reviewer of repeated branching that is a table in disguise, and of existing lookup tables that are incomplete, overlapping or unvalidated. Use proactively after edits that add a branch to a category… |
| `@agent-code-complete:test-case-reviewer` | sonnet | read-only | Reviewer that maps existing tests to a routine's contract: normal, boundary, invalid and defensive cases, and tests tied to implementation. Use proactively after edits that add or change tests… |
| `@agent-code-complete:test-writer` | sonnet | can edit files | Implementer that writes tests from a routine's contract: normal, boundary, invalid and defensive cases. Edits test files only. Use when test-case findings or a test matrix call for tests, or before… |
| `@agent-code-complete:trust-boundary-reviewer` | sonnet | read-only | Reviewer of inputs that cross a trust boundary: what is validated, rejected, recovered from, asserted and kept diagnosable. Use proactively after edits that add handlers, parsers, readers… |
| `@agent-code-complete:tuning-reviewer` | sonnet | read-only | Reviewer of the evidence behind a performance change: requirement, baseline, single change, remeasurement and the stated clarity trade-off. Use proactively after edits described as optimization or… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style code-complete:assumptions-first` | Lists the inputs, trust boundaries and assumptions before writing or changing code, then shows where each is validated, asserted or tested when the change is done. |
| `/output-style code-complete:evidence-first` | Claims no cause, fix, refactoring safety or speedup without an evidence line: a reproduction, a test result or a measurement; unproven claims are labelled and never stated as fact. |
| `/output-style code-complete:mentor` | Teaches the Code Complete rule behind each construction decision, names it, and ends non-trivial answers with one short check-for-understanding question. |
| `/output-style code-complete:pair` | Works in small narrated steps with a test run between them, and asks before any change larger than a few lines or one that touches public API. |
| `/output-style code-complete:strict-reviewer` | Answers as a ranked findings table against the Code Complete rules, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style code-complete:terse` | Result first, no preamble, a few lines at most unless asked, while still reporting what ran, the unresolved risk, and failing output in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with the `lead` agent or the routing table in `/code-complete:principles` when you are not sure what applies. The `lead` names at most five steps: usually the specialist reviewers for the concerns the change touches, an implementer only if you asked for changes, and `final-gate` last. Each reviewer owns one concern and reports in its own shape; a reviewer that finds something outside its concern names the sibling that owns it. Findings go to the implementers or to `/code-complete:fix`, which make the smallest change, run the project's tests and do not commit. Planning lives in `/code-complete:plan` (a whole change), `/code-complete:pseudocode` (one routine) and `/code-complete:test-matrix` (the cases for one routine). The scans `audit` and `trust-boundary-scan` run in a forked context and return at most 40 lines so a whole-repository scan does not fill your conversation. Output styles change the rhythm and the report format of the entire session. The vendored rule sets live in `skills/principles/references/` (`full`, `mini`, `nano`); every component names the upstream sections it applies in its `## Source` list.

Skills are invoked as `/code-complete:<name>`, agents are addressed as `code-complete:<name>` (ask for them by name or let Claude delegate), and styles are selected with `/output-style code-complete:<name>`.

## Usage walkthroughs

### 1. Review the work in progress

You have edited a few files and want a second opinion before you stage anything.

```text
/code-complete:review
```

With no argument it runs `git status` and `git diff` (and `git diff --staged`), sorts the change by concern (routines, data, control flow, boundaries and failures, classes, comments and style, tests, process), looks for the ten things the source says to look for and the five forbidden patterns, and applies the owning skills. For a large diff it delegates to the matching reviewers. You get ranked findings from blocker to nit, each with `file:line`, the rule by name, a provenance tag (`source`, `compact` or `judgment`) so you can discount the plugin's own heuristics, the consequence and the smallest fix with the skill that owns it. If it finds nothing it prints `No findings` and lists the clusters it checked. To act on the result:

```text
/code-complete:fix last review
```

`fix` resolves the findings one at a time in severity order, using the owning skill's procedure for each, runs the project's tests after each step, reverts that one edit and reports if a failure has no obvious cause, and does not commit. A finding that is really a failing behavior with an unknown cause is handed to `/code-complete:debugging` instead.

### 2. Plan a risky change, then build it in steps

You are about to add a CSV import of supplier price lists, and the requirements mention "partial failure" without saying what that means.

```text
/code-complete:plan add CSV import of supplier price lists with partial-failure reporting
```

You get a plan, not edits: the requirement restated apart from the solution, the six construction decisions (language constraints, error policy, data representation, reuse, integration, testing approach) marked settled, inherited from a named file, or open with an owner, options for the decisions that are expensive to reverse with the criterion that decided each, risks and assumptions, increments that each end in a runnable tested state with their integration points, and the tests per routine. Derive the cases for the first routine:

```text
/code-complete:test-matrix parsePriceRow
```

The matrix lists normal, boundary, invalid and defensive cases with the contract line each one checks, and the questions only the author can answer. Then hand the cases on to the implementer, naming the routine and the matrix so the delegated agent receives them (a subagent does not see the earlier conversation unless the delegation carries it; in a fresh session, paste the matrix):

```text
Use the code-complete:test-writer agent to write the tests for parsePriceRow from the matrix above.
```

Carry out the first increment in the pairing mode, switched on as its own command:

```text
/output-style code-complete:pair
```

`test-writer` edits test files only. In `pair` mode Claude opens each turn with the next step, makes only that step, runs the covering tests, and asks before a change larger than a few lines, a public name or a behavior change.

### 3. Write a tricky routine from a sketch

A routine has to merge overlapping date ranges and the algorithm is not obvious.

```text
/code-complete:pseudocode src/schedule.ts:mergeRanges
```

Claude first states the algorithm in its own words and stops if it cannot, because pseudocode is not a substitute for understanding. Then it writes the contract in three lines, sketches the steps at one abstraction level, walks a typical and two edge inputs through the sketch by hand, converts line by line, and prunes the sketch comments that only restate the code. It runs the project's tests, points you to `/code-complete:test-matrix` for the case list, and does not commit.

### 4. Fix a failing test by diagnosis

A test fails and nobody knows why.

```text
Use the code-complete:bug-fixer agent on tests/test_report.py::test_week_has_seven_days.
/output-style code-complete:evidence-first
```

`bug-fixer` reproduces the failure first (and stops without changing anything if it cannot), isolates it, states the cause in a sentence that also explains the passing cases, makes the smallest change that removes the cause, adds a regression test that fails before the fix and passes after, and runs the related tests. It returns a diagnosis record with the evidence for each step and lists similar spots it saw without changing them. In `evidence-first` mode every claim of cause or fix carries a reproduction or test line, and anything unproven is labelled `unverified`.

### 5. Inventory input boundaries and close the gaps

You inherited an API and want to know where outside data enters unchecked.

```text
/code-complete:trust-boundary-scan src
```

In a forked context it finds the entry points (handlers, consumers, readers, configuration, public functions), traces each input to its first use, and returns at most 40 lines: a table of what is validated, rejected, recovered, asserted and diagnosable per entry point, at most five ranked gaps, and a next step. To close the worst gap:

```text
Use the code-complete:boundary-hardener agent on the gaps listed above, starting with the refund consumer in jobs/refund.py.
```

The hardener needs the findings and the files in scope, and asks once and stops if either is missing, so the delegation must carry the gap list (in a fresh session, paste it). It classifies each input as external (validate), caller's job (assert) or expected business outcome (domain error), reuses the repository's validation style, adds one parsing step at the entry that returns a typed value or a diagnosable rejection, adds rejecting tests, and reports every input that is now refused and was accepted before, because that is a behavior change for callers.

### 6. Make something faster, with proof

A product asks for the catalogue page to be faster.

```text
/code-complete:tune catalogue page, p95 under 200 ms
```

The gate comes first: with no requirement it stops and asks for one, and with no evidence that the requirement is missed, the first step is to obtain that evidence. Claude then looks for an existing measurement in the project (it installs and downloads nothing), takes a baseline several times, locates the cost, makes one change, runs the tests, remeasures under the same conditions, and keeps or reverts the change, recording a tuning log. Ask for an audit of the evidence:

```text
Use the code-complete:tuning-reviewer agent on my current changes.
```

It returns an evidence table: requirement, baseline and workload, one change per measurement, result under the same conditions, tests after the change, and whether the clarity trade-off is written down.

### 7. Learn the reasoning while you work

You are onboarding someone, or yourself, and want the rule behind each choice.

```text
/output-style code-complete:mentor
/code-complete:explain-rule avoid flag arguments
```

In `mentor` mode every answer does the task first, adds a short **Why** block naming the rules used with a provenance label, notes any trade-off, and ends with one check question. `explain-rule` gives one rule in detail: its strength (binding, strong default or forbidden, using the source's wording), the reason, a check you can run on real code, an original example and the exceptions the source allows. If you ask about a number or a threshold it tells you that the source gives none.

### 8. Audit a repository

You want to know where the pain is before changing anything.

```text
/code-complete:audit src
```

`audit` runs in a fork and returns at most 40 lines: a rating (healthy, watch or hot) for routines, interfaces, data, control flow, boundaries, errors, classes, complexity, comments and standards, and tests, each with a file and line as evidence, at most five ranked hot spots each pointing to the skill that treats it, and a next step. If you want raw counts first, ask for them:

```text
Use the code-complete:construction-scanner agent on src.
```

The scanner reports numbers and locations only (long parameter lists, boolean parameters, deep nesting, literals in conditions, empty handlers, commented-out code, skipped tests) and states what its patterns cannot see.

### 9. Gate a pull request

Before you open the PR, check that the change is one verifiable increment, then gate it:

```text
Use the code-complete:increment-reviewer agent on my current changes.
Use the code-complete:final-gate agent on my current changes.
```

`increment-reviewer` groups the hunks by intent and flags behavior hidden inside structural changes and stranded or orphaned partial work (a branch that has gone long without integrating, or unfinished code with no caller, no switch that is read and no owner). `final-gate` checks the ten review-checklist questions and the five forbidden patterns against the diff with evidence for each, and answers `GATE: PASS` or `GATE: FAIL` with the blocking items. For a lighter, interactive walk with a next action for every no, use `/code-complete:checklist`.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale, including which skill owns each item of `Review Rules` and each forbidden pattern, is in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Purpose | `principles`, `explain-rule` |
| Primary Directive | `principles`, `construction-process`, `complexity-management`, `plan`, `explain-rule`, `mentor`, `terse` |
| Foundational Construction Rules | `principles`, `complexity-management`, `coding-standards` |
| Construction Prerequisites and Decisions | `construction-process`, `plan`, `lead` |
| Pseudocode Programming Process | `pseudocode`, `comments` |
| Routine Design Rules | `routine-design`, `routine-interface`, `routine-reviewer`, `interface-reviewer` |
| Variable and Data Rules | `variables`, `data-types`, `data-reviewer` |
| Data Type Rules | `data-types`, `data-reviewer` |
| Control Flow Rules | `control-flow`, `statements-and-loops`, `control-flow-reviewer` |
| Statement, Conditional, and Loop Rules | `statements-and-loops`, `table-driven`, `control-flow-reviewer` |
| Defensive Programming Rules | `trust-boundaries`, `assertions-and-contracts`, `error-handling`, `trust-boundary-scan`, `trust-boundary-reviewer`, `contract-reviewer`, `boundary-hardener`, `assumptions-first` |
| Error Handling Rules | `error-handling`, `error-flow-reviewer`, `trust-boundaries` |
| Table-Driven and Data-Driven Rules | `table-driven`, `table-reviewer`, `test-matrix` |
| Class and Module Design Rules | `class-design`, `class-design-reviewer` |
| Complexity Management Rules | `complexity-management`, `complexity-reviewer`, `refactoring-judgment` |
| Construction with Preconditions and Postconditions | `assertions-and-contracts`, `contract-reviewer`, `test-matrix`, `boundary-hardener`, `assumptions-first` |
| Comment Rules | `comments`, `comment-reviewer`, `pseudocode` |
| Coding Standards Rules | `coding-standards`, `consistency-reviewer` |
| Incremental Construction Rules | `construction-process`, `increment-reviewer`, `refactoring-judgment`, `refactorer`, `pair` |
| Quality, Collaboration, Debugging, and Refactoring | `debugging`, `refactoring-judgment`, `bug-fixer`, `refactorer`, `increment-reviewer`, `fix`, `evidence-first` |
| Performance, Integration, Tools, and Craftsmanship | `performance-tuning`, `tune`, `tuning-reviewer`, `construction-process`, `evidence-first` |
| Review Rules | `review`, `audit`, `construction-scanner`, `strict-reviewer` and the owner skills listed in `docs/DESIGN.md` |
| Forbidden Patterns | `review`, `audit`, `final-gate`, `strict-reviewer` and the owner skills (`complexity-management`, `routine-design`, `trust-boundaries`, `comments`, `coding-standards`) |
| Code Generation Rules | `principles`, `pseudocode`, `fix` |
| Testing Rules | `routine-testing`, `test-matrix`, `test-case-reviewer`, `test-writer`, `table-driven` |
| Review Checklist | `principles`, `checklist`, `final-gate`, `review`, `lead` |
| Final Instruction | `principles`, `checklist`, `final-gate`, `explain-rule`, `mentor` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. They are qualitative, mostly based on the compact rule files, and not validated by task runs. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `clean-code` | Overlap (conflict 30%, overlap 78%) | Both govern everyday implementation hygiene. Choose one construction-quality rule set. Clean Code is the tighter guide for small, local readability changes; Code Complete is broader, covering requirements, data, control flow, defensive programming, debugging, reviews and tuning. If you load both, make this plugin primary for risk and construction planning and limit the other to local readability in touched code. |
| `pragmatic-programmer` | Overlap (conflict 18%, overlap 64%) | Both are general engineering guides for readable, verified, low-defect work. Prefer this plugin for routine design, validation, control flow, debugging, reviews and tuning; prefer the other for project uncertainty, DRY ownership, orthogonality, automation, feedback loops and reversible decisions. Use both only for a high-risk implementation that needs both kinds of pressure. |
| `philosophy-of-design` | Complementary (conflict 20%, overlap 50%) | It decides module depth, API shape, information hiding and complexity reduction; this plugin decides defect-risk checks, data clarity, defensive checks and reviewable increments. Use both when construction choices need defect-risk checks and the design book must judge whether the resulting routines and interfaces reduce total complexity. The risk is duplicate general guidance on the same local code-shape decision, so name one arbiter per task. |
| `refactoring` and `legacy-code` | Complementary (conflict 12%, overlap 38%) | They control safe change sequencing: behavior preserved, small steps, characterization, seams. Use them when existing code must be reshaped toward these rules without changing behavior; prefer them while tests are weak or behavior is unclear, then apply this plugin inside the controlled area. |
| `release-it` | Complementary (conflict 12%, overlap 34%) | It owns timeouts, retries, isolation, limits and observability at production boundaries; this plugin owns the local construction. Use both when a change touches services, jobs or queues. The tension is mechanism cost: reliability patterns add complexity and belong only where a real production failure mode exists. |

The other books are generally complementary when their trigger is actually present: `clean-architecture` (policy independence; the tension is boundary cost), `data-intensive-apps` (consistency, schemas and replay; the tension is over-modeling before data semantics are explicit), the three Domain-Driven Design plugins `ddd`, `ddd-distilled` and `ddd-implementing` (model language and contexts; the tension is ceremony), `enterprise-patterns` (persistence, workflow and remoting; the tension is pattern pressure) and `refactoring-guru` (smell-driven treatment).

**Recommended pairing.** Keep Code Complete as the one always-on rule set (`inject_rules` on) when the work is mostly production construction, and bring in `refactoring` or `legacy-code` on demand for changes to existing code, and `release-it` for production boundaries. **Avoid loading together:** `clean-code` and `pragmatic-programmer` alongside this plugin with equal weight and `inject_rules` on in all of them; their general guidance competes on the same decisions. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **Context cost.** Twenty model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; install only the book plugins you need, because Claude Code's per-skill overrides do not apply to plugin skills and the whole plugin is the smallest unit you can turn off; and do not load many book plugins at once. The upstream notes warn that loading too many rule files crowds out task context.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce code that looks disciplined while missing the task. The reviewers, gate and output styles add structure, but they cannot guarantee obedience.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the mistakes your agents actually make; it will usually matter more than any generic rule.
- **A short digest, not the whole book.** The upstream rule set is a compact policy distilled from the book. Topics the book treats at length may be absent from it, and this plugin does not add them as rules of the source. Where a skill goes beyond the rule set it says so with the label **Added judgment**, and every number (nesting depth, parameter count, "more than ten files") is one of those.
- **Overengineering risk.** Applied mechanically, the rules on named predicates, tables, wrapper types and extraction can produce more structure than a small change needs. The skills include the source's own brake (use a table only when it is clearer; keep clarity unless a measured trade-off is explicit; keep cleanup proportionate), but you still need to judge. The source scopes its up-front decisions to large implementation work, so small changes do not need the full procedure.
- **Contested advice.** How small a routine should be, how many returns are acceptable, how often to assert, how much to comment, and when a flag is acceptable are debated. Where the source says "prefer", "as practical" or "when possible", the skills say the same; they do not turn those into absolutes.
- **What it cannot detect.** The reviewers work by reading diffs and files. They do not run code, so they cannot find runtime performance problems, race conditions, security flaws that depend on deployment, or a test that passes for the wrong reason without seeing its output. The tuning and debugging workflows can run the project's own commands, but only the ones that exist. The validator for this repository checks structure and traceability, not the quality of the advice.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule (result types instead of exceptions, a framework base class, a required header), the priority order is your instruction, then the repository, then the book.
- **The model may already know the book.** The value here is a short, decision-changing reminder plus structure and honest labels, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Code Complete rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Code Complete* is by Steve McConnell. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
