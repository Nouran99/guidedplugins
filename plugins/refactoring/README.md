# Refactoring

Martin Fowler's discipline of changing the structure of code without changing what it does, turned into a Claude Code toolkit. It makes Claude find or build a safety net first, separate structural edits from behavior changes, prepare the ground before a feature instead of bolting it on, apply named moves in small verified steps, and stop when the change is easy instead of drifting into a rewrite.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), seven usage walkthroughs with exact commands, a map from the rule set's sections to the components, and an honest section on what this cannot do.

<!-- START-HERE:START -->
## Start here

9 components cover most uses; everything else is reachable from the `refactoring:principles` skill's routing table.

| To | Run |
| --- | --- |
| Review your current change | `/refactoring:review` |
| Plan a non-trivial change before you edit | `/refactoring:plan` |
| Walk the book's final checklist against your change | `/refactoring:checklist` |
| Act on review findings, one at a time | `/refactoring:fix` |
| In a forked context, confirm smells in a scope and map each to the smallest named catalog move, its precondition, safety net | `/refactoring:smell-to-refactoring` |
| Do only the preparatory refactoring for a stated change | `/refactoring:prepare` |
| Pin the current behavior of unclear code with characterization tests before refactoring it | `/refactoring:characterize` |
| Not sure which specialist applies? Route the task | ask Claude to use `refactoring:lead` |
| Strict pass or fail before you commit or open a pull request | ask Claude to use `refactoring:final-gate` |

Using this book next to others? `/plugin install guided-<preset>@guided-plugins` installs a primary book with complementary ones, and `/guided:review` reviews with all of them at once. Project settings (ignored paths, strictness, the primary book): [`.guided-plugins.json`](https://github.com/Nouran99/guidedplugins/blob/main/docs/PROJECT_CONFIG.md).
<!-- START-HERE:END -->

## Overview

**The book in one paragraph.** *Refactoring* treats improving the design of existing code as ordinary daily work with one hard constraint: observable behavior stays the same. The method is a loop of small, named transformations, each checked by tests before the next one starts, so that a long journey from tangled code to a clear design is made of steps that are individually boring and individually safe. Smells in the code are prompts to look, not verdicts. A catalog of named moves (extract, inline, move, split, encapsulate, replace a conditional, pull up) gives the steps a shared vocabulary. Refactoring happens around feature work: reshape first so the change is easy, make the change, then clean up what it left.

**Who this is for.** Developers using Claude Code on existing code in any mainstream language: adding a feature to code that resists it, fixing a bug in code nobody fully understands, reviewing a pull request that calls itself cleanup, paying down a specific smell, or teaching a team what a safe refactoring looks like. It pays off most where agents are most dangerous, in changes that touch code with weak tests.

**The bias it corrects.** Left alone, an agent fails in one of two directions. Asked to add a feature to awkward code, it bolts the feature on and leaves the structure worse. Asked to improve code, it rewrites a module, renames half the tree, adds an interface for a future that has not been requested, and ships one patch in which nobody can tell which lines change behavior. This toolkit asks for the narrow path between them: establish a safety net, make the smallest structural change that makes the requested change easy, make that change separately, clean up what it introduced, and stop. Restraint is part of the discipline. The rule set forbids abstracting coincidental similarity, replacing an honest conditional with indirection, and adding interfaces before a second real need.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/refactoring:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- Process skills for the discipline itself: what counts as behavior (`behavior-preservation`), step size and the rewrite brake (`small-steps`), the safety net (`safety-net`), preparation before a feature (`preparatory-steps`), the shape of a patch (`patch-hygiene`) and when to stop (`stopping-rules`).
- Smell-and-move skills, one owner per smell and per group of catalog entries: duplication, function bodies, call signatures, hidden dependencies, ownership, primitive obsession, mutation control, conditionals, variation and state, needless abstraction, inheritance moves, error paths and renaming. Each one carries a "leave it alone" branch, because the rule set does.
- Workflows named for what the book teaches: `smell-to-refactoring` (a smell becomes the smallest named move with its precondition, safety net and stop condition), `characterize` (pin behavior before touching it), `prepare` (do only the preparatory refactoring), `split-patch` (turn a mixed diff into single-intent patches), next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (a behavior-delta ledger, an intent ledger, a coverage map, an evidence table, an error-path equivalence table and so on), four implementers that make small test-backed changes, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `two-hats`, which labels every edit as structure or behavior, and `prep-first`, which runs every change task in the book's order.

**When not to use it.** Reach for a different book when the real question lies elsewhere: the target architecture or domain model (`clean-architecture`, `ddd`, `enterprise-patterns`), taking untested legacy code under control with seams and dependency-breaking techniques (`legacy-code`; this plugin's `characterize` is the light version), module depth and interface trade-offs (`philosophy-of-design`), or production failure behavior such as timeouts and overload (`release-it`). For a throwaway script the rules still hold, but the ceremony of this toolkit does not pay.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install refactoring@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/refactoring
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand. This plugin is a good candidate for always-on when most of your work changes existing code.

To remove it later:

```text
/plugin uninstall refactoring@guided-plugins
```

## Components

<!-- COMPONENTS:START -->

**58 components:** 30 skills (20 Claude can load on its own, 10 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/refactoring:behavior-preservation` | Use to decide whether a change really is a refactoring: what counts as observable behavior, a feature or bug fix hiding inside cleanup, a risky 'modernization'. Judges the meaning of a change; step size is small-steps… |
| `/refactoring:call-signatures` | Use when a function has many parameters, boolean flags that switch behavior, an argument order callers must memorize, or repeated argument groups. Reshapes the call, not the types behind it (primitive-obsession) or the… |
| `/refactoring:conditionals` | Use when branching inside one function is hard to read: nested if/else, repeated or compound conditions, control flags, a tempting lookup table. Local branch structure and restraint; repetition by kind is… |
| `/refactoring:duplication` | Use when the same logic appears in several places, a fix had to be made twice, or someone proposes a utils or common module. Merge copies of one piece of knowledge into one owner; leave coincidental similarity alone.… |
| `/refactoring:error-paths` | Use when error handling hides the main path, or a refactoring touches validation, cleanup, recovery, error codes or exceptions. Keeps failure behavior identical while making it readable. Ordinary branching is… |
| `/refactoring:function-bodies` | Use when a function is long or mixes parsing, validation, computation and I/O, or when temporaries and expressions hide intent. Where to cut a function and the moves inside a body. Parameters are call-signatures… |
| `/refactoring:hidden-dependencies` | Use when code reads globals, singletons, the clock, environment, config or ambient request context, or a function has side effects its name hides. What code reads from outside its signature; who may write shared state… |
| `/refactoring:inheritance-moves` | Use when a hierarchy needs reshaping: duplicated or misplaced superclass members, inheritance used for reuse, empty layers, or two variation axes in one tree. Hierarchy mechanics only; constant-only subclasses are… |
| `/refactoring:mutation-control` | Use when state is public or changed from many places: exposed fields or collections, needless setters, duplicated update logic, bidirectional links. What others may write; what code reads from ambient state is… |
| `/refactoring:needless-abstraction` | Use when a class or layer only forwards calls, an interface has one implementation, a library has one caller, or code exists just in case. Removes weight that exists; merging copies is duplication, hierarchies are… |
| `/refactoring:ownership` | Use when one class changes for many reasons, one change edits many files, a method mostly works on another object's data, or domain rules sit in UI or I/O code. Where behavior lives among peers; types for concepts are… |
| `/refactoring:patch-hygiene` | Use when shaping a diff, commit series or pull request that mixes renames, code motion, redesign and logic changes, or is too big to review. Packaging and intent per patch; whether behavior actually changed is… |
| `/refactoring:preparatory-steps` | Use when a requested feature or bug fix is awkward to add in the current structure: ask what makes it awkward, reshape locally first, then change behavior, then clean up. Bound to one upcoming change; general step… |
| `/refactoring:primitive-obsession` | Use when the same primitives travel together or carry rules: ids and codes as strings, parallel fields, positional arrays, magic values. Introduces named types; call shape is call-signatures, which class owns behavior… |
| `/refactoring:principles` | Applies the Refactoring rule set (behavior-preserving structural change in small, tested steps) to any task that changes existing code. Use first for feature work, bug fixes, cleanup and review of existing code; it… |
| `/refactoring:renaming` | Use when names hide intent, describe mechanism, or disagree with domain terms, or a rename is proposed. Safe renames and how far to take them in one change. No other skill rewrites identifiers; the packaging of a large… |
| `/refactoring:safety-net` | Use before risky structural edits, or when tests are absent, weak or being edited during a refactoring: finding or building a safety net, characterization tests, keeping tests honest. The tests that prove behavior… |
| `/refactoring:small-steps` | Use when planning or doing a structural change and tempted to rewrite or change a lot at once: step size, reversibility, runnable states, order of work. Not meaning (behavior-preservation), when to stop… |
| `/refactoring:stopping-rules` | Use when deciding whether to keep cleaning: the change is already easy, the smell is gone, the next abstraction is speculative, or cleanup looks like theater. When to stop, not how to proceed (small-steps); removing… |
| `/refactoring:variation-and-state` | Use when the same type code, status or mode is switched on in several places, subclasses only override constants, repeated null checks share one meaning, fields are set only on some paths, or creation needs a name.… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/refactoring:audit` | Scan a directory or repository in a forked context for refactoring readiness: where change is expensive, whether the area has a safety net, and which smells cost most. Ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/refactoring:characterize` | Pin the current behavior of unclear code with characterization tests before refactoring it. Writes or edits test files only; never touches production code. | `[file \| function \| module \| empty to use the files in the current diff]` |
| `/refactoring:checklist` | Walk the final Refactoring checklist against the current work in the session and give a concrete next action for every item that is not yet a yes. | `[paths \| git ref \| empty for the current diff]` |
| `/refactoring:explain-rule` | Explain one Refactoring rule, smell or catalog move: its strength, the reason, how to check it, an original example and the source's own limits. | `[rule name \| smell \| catalog move \| topic \| empty to list topics]` |
| `/refactoring:fix` | Resolve given refactoring findings with the smallest named move per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| row numbers \| 'last review' \| empty to ask]` |
| `/refactoring:plan` | Plan a change to existing code in the book's order: friction, safety net, preparatory refactoring, the behavior change, follow-up cleanup and a stop condition. Plans only; edits nothing. | `[change request \| ticket text \| file:function \| empty to infer from the current diff]` |
| `/refactoring:prepare` | Do only the preparatory refactoring for a stated change: at most five verified behavior-preserving steps that make the change straightforward, then hand back before the behavior change. | `[the change you are about to make \| ticket text \| empty to ask]` |
| `/refactoring:review` | Review a diff or paths against the Refactoring rules and report ranked findings, starting with whether the change keeps behavior, one intent and a safety net. | `[paths \| git ref \| empty for the current diff]` |
| `/refactoring:smell-to-refactoring` | In a forked context, confirm smells in a scope and map each to the smallest named catalog move, its precondition, safety net and stop condition, ranked, in at most 40 lines. Includes a leave-it-alone verdict. | `[directory \| file \| glob \| empty for the files in the current diff]` |
| `/refactoring:split-patch` | Turn a mixed diff into an ordered series of single-intent patches (renames, moves, preparation, behavior) and say which hunks belong to each. Plans the split; does not stage or commit. | `[git ref \| paths \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-refactoring:abstraction-reviewer` | sonnet | read-only | Reviewer that builds an evidence table for each abstraction in changed code (interfaces, wrappers, factories, strategies, shared modules) and judges keep or inline. Use proactively after edits that… |
| `@agent-refactoring:behavior-preservation-reviewer` | sonnet | read-only | Reviewer that builds a behavior-delta ledger for a change claimed to preserve behavior: the observable surface of each touched unit, marked same, changed or unknown. Use proactively after edits… |
| `@agent-refactoring:class-splitter` | sonnet | can edit files | Implementer that splits one class that changes for several reasons into cohesive classes, one field or method at a time, tests between steps. Use when an ownership review names a god class and… |
| `@agent-refactoring:conditional-refactorer` | sonnet | can edit files | Implementer that replaces repeated type-based branching with a table, strategy or polymorphism only when the repetition justifies it, and removes modeling added for a single branch. Use when a… |
| `@agent-refactoring:conditional-reviewer` | sonnet | read-only | Reviewer that inventories branches and type switches in changed code and gives each a proportionate verdict, including leave-as-is. Use proactively after edits that add branches, switch on a type or… |
| `@agent-refactoring:dependency-reviewer` | sonnet | read-only | Reviewer that inventories hidden inputs and effects in changed code: globals, singletons, clock, environment, config and ambient context, plus side effects a name hides. Use proactively after edits… |
| `@agent-refactoring:duplication-reviewer` | sonnet | read-only | Reviewer of duplication decisions: groups repeated logic into clusters and judges whether each is one piece of knowledge to merge, coincidence to leave, or a merge made too early. Use proactively… |
| `@agent-refactoring:error-path-reviewer` | sonnet | read-only | Reviewer that compares error behavior before and after a change, exit by exit: error type, message, timing relative to side effects, cleanup, logging and recovery. Use proactively after edits that… |
| `@agent-refactoring:final-gate` | sonnet | read-only | Pre-merge gate that runs the Refactoring review checklist and forbidden patterns against the working diff and returns PASS or FAIL with evidence per item. Use before declaring work done, committing… |
| `@agent-refactoring:friction-reviewer` | sonnet | read-only | Reviewer that compares a finished change with the friction it was meant to remove, and returns a stop-rule verdict: friction removed, not removed, or cleanup overshot. Use proactively after a… |
| `@agent-refactoring:function-reviewer` | sonnet | read-only | Reviewer of function bodies: where to cut, mixed phases and abstraction levels, reused temporaries, parameter reassignment, and over-extraction. Use proactively after edits that add or lengthen… |
| `@agent-refactoring:hierarchy-reviewer` | sonnet | read-only | Reviewer that maps inheritance hierarchies touched by a change and names the move each problem suggests: pull up, push down, collapse, template method, delegation, or teasing apart axes. Use… |
| `@agent-refactoring:lead` | opus | read-only | Triage lead for Refactoring work. Use first on any non-trivial change to existing code to decide, in at most five steps, which specialists and skills apply and in what order. Routes only; does not… |
| `@agent-refactoring:mutation-reviewer` | sonnet | read-only | Reviewer that lists the mutation surface of changed classes: public fields, setters, exposed collections, duplicated state transitions and association direction, with the writers of each. Use… |
| `@agent-refactoring:ownership-reviewer` | sonnet | read-only | Reviewer of where behavior and data live: classes that change for many reasons, changes that ripple across files, methods that envy another object's data, and domain rules in UI or I/O code. Use… |
| `@agent-refactoring:patch-intent-reviewer` | sonnet | read-only | Reviewer that labels every hunk of a diff by intent (rename, move, extract-inline, prepare, behavior, test-for-behavior, format, unrelated) and gives a single-intent or mixed verdict. Use… |
| `@agent-refactoring:primitive-reviewer` | sonnet | read-only | Reviewer that finds recurring primitive bundles, loaded primitives and positional arrays in changed code and names the type each one implies, or says to leave it. Use proactively after edits that… |
| `@agent-refactoring:refactorer` | sonnet | can edit files | Implementer that carries out a list of refactoring findings or a plan as named behavior-preserving moves, running the tests between steps. Use when review findings or a plan span several functions… |
| `@agent-refactoring:safety-net-reviewer` | sonnet | read-only | Reviewer that maps the behavior a planned or finished refactoring touches to the tests that would catch a mistake, and says whether the net is ready. Use proactively before risky structural edits… |
| `@agent-refactoring:signature-reviewer` | sonnet | read-only | Reviewer of function signatures and call sites: long parameter lists, behavior-switching flags, argument-order traps, repeated argument groups and unpack-and-pass calls. Use proactively after edits… |
| `@agent-refactoring:test-change-reviewer` | sonnet | read-only | Reviewer that lists every test added, edited, skipped or deleted in a diff and judges each against preserved behavior. Use proactively after any refactoring that touches test files, or when a test… |
| `@agent-refactoring:value-type-introducer` | sonnet | can edit files | Implementer that introduces one named type for a recurring primitive bundle or loaded primitive and threads it inward from the boundary, keeping accepted input unchanged. Use when a primitive review… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style refactoring:mentor` | Teaches the Refactoring rule or smell behind each choice, names the catalog move used, and ends non-trivial answers with one check-for-understanding question. |
| `/output-style refactoring:pair` | Works in small narrated steps with tests between them, and asks before any change larger than a few lines or touching a public name. |
| `/output-style refactoring:prep-first` | Runs every change task in the book's order and reports it as a fixed sequence: friction, safety net, preparation, change, follow-up cleanup, and the reason it stopped. |
| `/output-style refactoring:strict-reviewer` | Answers as a ranked findings table against the Refactoring rules, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style refactoring:terse` | Gives the result first with no preamble, in at most a few lines unless more is asked, while still showing failing test output in full. |
| `/output-style refactoring:two-hats` | Tags every edit as STRUCTURE or BEHAVIOR, never both in one step, and announces each switch of hat so structural changes and behavior changes stay separable. |

<!-- COMPONENTS:END -->

Skills are invoked as `/refactoring:<name>`, agents are addressed as `refactoring:<name>` (ask for them by name or let Claude delegate), and styles are selected with `/output-style refactoring:<name>`.

**How the pieces fit.** `refactoring:lead` is the router: given a task or a diff it names at most five steps and does not review anything itself. The specialist reviewers are read-only and each owns one concern; the process reviewers come first (`safety-net-reviewer`, `behavior-preservation-reviewer`, `patch-intent-reviewer`, `test-change-reviewer`), then the cluster reviewers for the smell in play. When changes are wanted, `refactorer` carries out a list of findings and three specialists handle the multi-step moves that need judgment (`class-splitter`, `conditional-refactorer`, `value-type-introducer`). `final-gate` closes the work with a binary verdict. The manual skills are the commands you type: `plan` and `prepare` before a change, `characterize` when the net is missing, `review`, `audit` and `smell-to-refactoring` to find work, `fix` to do it, `split-patch` to repackage it, `checklist` to walk the end. The two forked skills (`audit`, `smell-to-refactoring`) run in an isolated context and return at most 40 lines.

## Usage walkthroughs

### 1. Review a change that calls itself cleanup

You have a branch whose description says "refactor billing". You want to know whether it is one.

```text
/refactoring:review
```

With no argument it runs `git status` and `git diff` (and `git diff --staged`), states the intent the change claims and the intent it actually shows, applies the rule clusters the change touches, and prints ranked findings with `file:line`, the rule or pattern by name, the consequence and the smallest fix. A typical first finding is a mismatch: the claimed intent is structure, the observed intent is both, because one hunk changes a grace period. If the finding is that the patch mixes intents, label the hunks with the specialist first:

```text
Use the refactoring:patch-intent-reviewer agent on my current changes.
```

The agent labels every hunk (rename, move, extract-inline, prepare, behavior, test-for-behavior, format, unrelated) and ends with a verdict, SINGLE or MIXED, and a pointer to `/refactoring:split-patch`. Then send the slash command as its own message, because a slash command only runs when it starts a message:

```text
/refactoring:split-patch
```

The skill returns an ordered series of single-intent patches, mechanical renames alone, moves with no edits inside, preparation, then the behavior change with its test. It does not stage or commit anything; you apply the plan.

### 2. Add a feature to code with weak tests

You must add a 30-day refund window to a checkout module whose tests are thin.

```text
/refactoring:plan add a 30-day refund window to the checkout module
```

You get a plan, not edits: the friction that makes the change awkward (with a file and line), whether the safety net is present, thin or missing, at most five preparatory steps, the behavior change with the test to write first (test first is this plugin's judgment, not a rule of the source), follow-up cleanup, and a stop condition. If the net is thin, pin the behavior before touching anything:

```text
/refactoring:characterize src/checkout.ts
```

`characterize` writes or edits test files only. It runs the code, records what it actually does (including odd results, which it labels and does not fix), and reports which behaviors are pinned and which are not. Then, as the next message:

```text
/refactoring:prepare add a 30-day refund window to the checkout module
```

`prepare` records a baseline, names the awkward point, does at most five behavior-preserving steps with the tests after each, and stops before the change. Its hand-back names the first test to write. You (or Claude, outside the skill) write that test and make the change. Then check the result, one command per message:

```text
/refactoring:review
```

```text
/refactoring:fix last review
```

```text
/refactoring:checklist
```

`fix` resolves the findings of the review one at a time in severity order, runs the tests after each, stops if a failure has no obvious cause, and does not commit. `checklist` is the last walk, after the fixes, and gives a next action for every item that is not yet a yes.

### 3. Turn smells into the smallest moves

A billing module has grown, and you want symptoms mapped to treatments before anyone edits.

```text
/refactoring:smell-to-refactoring src/billing
```

The skill runs in a fork and returns at most 40 lines: a ranked table of confirmed smells (a search hit is a candidate, not a smell), each with the candidate move, its precondition, the safety net and a verdict, including `leave alone` for things the rules say to keep, such as a single honest conditional. Rows marked "treat after characterize" go to `/refactoring:characterize` first. Then resolve a row:

```text
/refactoring:fix 1
```

The pairing of smell to catalog move is this plugin's judgment; the rule set names the smells and, separately, the moves.

### 4. Delegate a multi-step move

A reviewer flagged that `InvoiceService` changes for pricing, PDF layout and e-mail reasons.

```text
Use the refactoring:ownership-reviewer agent on src/billing/InvoiceService.java.
```

The reviewer returns a placement ledger: the reasons the class changed (read from its history), what it envies, and the suggested move. Read the ledger, then send the implementer as a second message:

```text
Use the refactoring:class-splitter agent on InvoiceService.
```

`class-splitter` builds a field-by-method usage matrix, extracts the least coupled group first, moves state before behavior, keeps the old class delegating so callers do not change, and runs the tests after every move. The same pattern holds for repeated type switches (`refactoring:conditional-reviewer`, then `refactoring:conditional-refactorer`, which also decides when the right answer is to leave the conditional or undo modeling that never earned its place) and for primitive bundles (`refactoring:primitive-reviewer`, then `refactoring:value-type-introducer`, which keeps accepted input unchanged and proposes tightened validation as a separate behavior step).

### 5. Audit a repository before changing anything

You inherit a service and want to know where change is expensive and whether it is safe to touch.

```text
/refactoring:audit src
```

The audit reads up to 15 files chosen by churn, size and suspicious names, probes the review signals (duplicated logic, long functions, feature envy, shotgun surgery, pass-through layers, hidden side effects, code that needs too much context) and rates each hot area for its safety net: present, thin or none. It prints at most five ranked hot spots with the skill that treats each, a list of paths that need characterization tests first, and a next command, usually `/refactoring:smell-to-refactoring <directory>`. The thresholds it uses to find candidates are labelled as search aids, not rules of the book.

### 6. Learn the reasoning while you work

You are onboarding someone, or yourself.

```text
/output-style refactoring:mentor
```

```text
/refactoring:explain-rule Replace Conditional with Polymorphism
```

In `mentor` mode every answer does the task first, adds a short Why block that names the rule or move, its strength in the source and the check that showed behavior was kept, and ends non-trivial answers with one question. It also says when it declined to refactor something and which restraint rule applied. `explain-rule` explains one item: its strength (must, should or must-not from the source's wording, or "compact checklist", or "Added judgment"), the reason, a check you can run, an original example, and the source's own limits for it. For catalog moves it says that the source gives only a trigger and that the mechanics are this plugin's.

### 7. Keep structure and behavior apart for a whole session, then gate the result

You will touch several things in one sitting and want every edit labelled.

```text
/output-style refactoring:two-hats
```

Every edit is tagged `[STRUCTURE]` or `[BEHAVIOR]`, never both, and each switch of hat is announced. Structural steps change no test expectation; behavior steps write the test first (this plugin's judgment). The session ends with a ledger of steps and the patch order to use. For a session that follows the whole sequence on every task (friction, safety net, preparation, change, follow-up, and why it stopped), use `/output-style refactoring:prep-first` instead. Before you commit or open the pull request:

```text
Use the refactoring:final-gate agent on my current changes.
```

It checks the twelve checklist questions and the five forbidden patterns against the diff with evidence (new untracked files count as part of the change, and it passes an empty diff only when `git status` is clean), treats a test result that was not shown as unproven, and answers `GATE: PASS` or `GATE: FAIL` with the blocking items. For a lighter, interactive walk that gives a next action for each "no", use `/refactoring:checklist`.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale, the ownership tables and the list of confusable pairs are in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Purpose | `principles`, `behavior-preservation`, `explain-rule`, `mentor` |
| Primary Directive | `principles`, `small-steps`, `preparatory-steps`, `plan`, `lead`, `pair` |
| What Counts as Refactoring | `behavior-preservation`, `behavior-preservation-reviewer`, `renaming` |
| Non-Negotiable Rules | `behavior-preservation`, `small-steps`, `preparatory-steps`, `stopping-rules`, `fix`, `refactorer`, `two-hats` |
| Safety Rules (tests and verification, commit and patch discipline, preparatory refactoring) | `safety-net`, `safety-net-reviewer`, `characterize`, `patch-hygiene`, `patch-intent-reviewer`, `split-patch`, `preparatory-steps`, `prepare`, `fix` |
| Code Smell Policy | `audit`, `smell-to-refactoring`, and one owner per smell (table below) |
| Preferred Refactoring Moves | `renaming`, `function-bodies`, `ownership`, `conditionals`, `primitive-obsession`, `smell-to-refactoring` |
| Refactoring Catalog Index | `explain-rule`, `smell-to-refactoring`, and the move skills (table below) |
| Function-Level Rules | `function-bodies`, `hidden-dependencies`, `function-reviewer`, `dependency-reviewer` |
| Class and Module Rules | `ownership`, `duplication`, `needless-abstraction`, `inheritance-moves`, `ownership-reviewer`, `class-splitter` |
| Rules for Working with Conditionals | `conditionals`, `variation-and-state`, `conditional-reviewer`, `conditional-refactorer` |
| Data and Mutation Rules | `mutation-control`, `mutation-reviewer` |
| Error Handling Rules | `error-paths`, `error-path-reviewer` |
| Review Rules | `review`, `audit`, `hidden-dependencies`, `strict-reviewer` |
| Forbidden Patterns | `review`, `audit`, `final-gate`, `small-steps`, `patch-hygiene`, `stopping-rules`, `safety-net` |
| Code Generation Rules | `small-steps`, `preparatory-steps`, `plan`, `prepare`, `fix`, `refactorer`, `lead`, `prep-first` |
| Testing Rules | `safety-net`, `characterize`, `test-change-reviewer` |
| Stopping Rules | `stopping-rules`, `friction-reviewer`, `plan`, `prepare`, `prep-first` |
| Review Checklist | `checklist`, `final-gate`, `review`, `friction-reviewer`, `strict-reviewer` |
| Final Instruction | `principles`, `small-steps`, `checklist`, `final-gate`, `terse`, `mentor` |

**Smell ownership.** Each smell in the rule set has exactly one owning skill; others point to it.

| Smell | Owner | Reviewer |
| --- | --- | --- |
| Duplicated Code | `duplication` | `duplication-reviewer` |
| Long Functions | `function-bodies` | `function-reviewer` |
| Long Parameter Lists | `call-signatures` | `signature-reviewer` |
| Global Data and Hidden Dependencies | `hidden-dependencies` | `dependency-reviewer` |
| Divergent Change, Shotgun Surgery, Feature Envy | `ownership` | `ownership-reviewer` |
| Data Clumps and Primitive Obsession | `primitive-obsession` | `primitive-reviewer` |
| Switch Statements and Conditionals | `conditionals` (local), `variation-and-state` (repeated by kind) | `conditional-reviewer` |
| Temporary Fields and Weird Lifecycles | `variation-and-state` | `conditional-reviewer` |
| Middle Man and Speculative Generality | `needless-abstraction` | `abstraction-reviewer` |

**Catalog ownership.** The five groups of the catalog index are distributed by what they change: Composing Methods in `function-bodies`; Moving Features in `ownership` (with Inline Class and Remove Middle Man in `needless-abstraction`); Organizing Data across `primitive-obsession`, `mutation-control` and `variation-and-state`; Simplifying Calls and Conditionals across `call-signatures`, `conditionals`, `variation-and-state`, `mutation-control`, `error-paths` and `renaming`; Generalization and Big Refactorings in `inheritance-moves` and `ownership`.

## Works with other plugins

The upstream compatibility notes compare this book with every other book in the collection, pair by pair, and give each pair a verdict (complementary, overlapping or conflicting) with three percentages: conflict, overlap and complementarity. Thirteen pairs exist for *Refactoring*. Twelve are rated **Complementary** and one is rated **Overlap**; none is rated conflicting. The ratings are qualitative and source-based: they compare the compact rule files, they were not validated by task runs, and two pairs (`philosophy-of-design` and `refactoring-guru`) also drew on outside descriptions of the books. They rate the underlying rule sets, not this plugin's extra components.

| Plugin | Verdict | Conflict / overlap / complementarity | What the pair means |
| --- | --- | --- | --- |
| `legacy-code` | Complementary | 10% / 58% / 76% | Use together for risky changes to existing code: `legacy-code` first, to understand and characterize behavior and to create the smallest seam; this plugin second, for the behavior-preserving structural move inside the controlled area. The tension is sequencing: structural pressure must wait until characterization or a safe seam exists in weakly tested code. Prefer `legacy-code` when tests are weak or behavior is unclear; prefer this plugin only after control, characterization or seams make the change safe. Highest overlap of the complementary pairs. |
| `philosophy-of-design` | Complementary | 28% / 46% / 74% | Highest conflict of the thirteen. Load together to reshape code toward deeper modules, cleaner interfaces and better information hiding: `philosophy-of-design` defines what a better design looks like, this plugin defines how to get there without hidden behavior change. The tension is that it can justify broader design exploration while this plugin forbids turning cleanup into redesign, so this plugin arbitrates sequencing and behavior preservation. Prefer this plugin when the task is mainly safe structural transformation; prefer `philosophy-of-design` for design judgment about new APIs, modules, abstraction boundaries and complexity reduction. |
| `refactoring-guru` | Overlap | 8% / 90% / 30% | Choose one refactoring rule set. There is little contradiction; the risk is duplicated context and technique-catalog pressure, because both cover behavior preservation, smell diagnosis, the smallest treatment, verification and stopping. Prefer this plugin for most code-change tasks (it is the more procedural, safety-focused set); prefer `refactoring-guru` when the task is specifically smell identification or technique selection. Load both only when a review-heavy cleanup needs this process plus an explicit smell catalog. |
| `clean-code` | Complementary | 12% / 38% / 78% | Adds local readability, naming, function shape, side-effect and test pressure, and scoped cleanup. |
| `clean-architecture` | Complementary | 12% / 38% / 78% | Adds business policy independent of frameworks, databases and delivery mechanisms, with dependencies pointing inward. |
| `code-complete` | Complementary | 12% / 38% / 78% | Adds defect reduction, data clarity, defensive checks, evidence-based debugging and reviewability. |
| `data-intensive-apps` | Complementary | 12% / 38% / 78% | Adds source of truth, consistency, durability, replay, schema evolution, partitioning and distributed failure. |
| `ddd` | Complementary | 12% / 38% / 78% | Adds model language, Bounded Contexts, invariants, lifecycle rules and domain-language tests. |
| `ddd-distilled` | Complementary | 12% / 38% / 78% | Adds selective DDD: subdomain importance, Bounded Contexts, local language and justified tactical patterns. |
| `ddd-implementing` | Complementary | 12% / 38% / 78% | Adds DDD implementation choices: contexts, aggregates, repositories, events, application services and translation. |
| `enterprise-patterns` | Complementary | 12% / 38% / 78% | Adds enterprise-pattern forces across workflow, persistence, transactions, integration, session state and remoting. |
| `release-it` | Complementary | 12% / 38% / 78% | Adds production failure semantics: demand limits, timeouts, retries, isolation, observability and recovery. |
| `pragmatic-programmer` | Complementary | 12% / 38% / 78% | Adds ownership, DRY knowledge, orthogonality, reversibility, tracer feedback, automation and contracts. |

**The ten 12% / 38% / 78% pairs share one loading decision.** Use them together when existing code must be reshaped toward the other plugin's goals without changing observable behavior: one rule set controls the safe sequencing of the change, the other defines the target design, construction, architecture, data or production quality. The only tension upstream names is scope creep: a design or architecture improvement must not override behavior preservation, characterization or the current-smell stop condition. Prefer this plugin when observable behavior must stay unchanged; prefer the other plugin when designing new behavior rather than reshaping existing structure. Upstream calls these pairs useful only where both scopes are active; in practice that means a task that has both a change to existing code and a question about the target design.

**Recommended pairing and loading.**

- **Primary rule set.** Upstream's general loading advice (in its criticism notes) is one primary always-on rule set, the others on demand, and the smallest loading mechanism that still changes decisions: the compact `mini` rules as the working layer, `nano` only for a tight always-on budget, the full rules as reference. When most of your work changes existing code, this plugin is a good candidate for that primary slot (`inject_rules` on); that suggestion is this plugin's judgment, not a rating.
- **One target-design plugin per task, on demand.** Pick the plugin whose scope is actually active (this plugin's reading of the pairs above): `clean-code` for local readability, `philosophy-of-design` for module depth, `clean-architecture` or `enterprise-patterns` for structure, a DDD plugin (`ddd`, `ddd-distilled`, `ddd-implementing`) for a domain model, `release-it` for production failure behavior, `data-intensive-apps` for data ownership and replay, `code-complete` for defect-focused construction, `pragmatic-programmer` for ownership and duplicated knowledge. Because twelve pairs are rated complementary and none is rated conflicting, the reason to be selective is context cost and competing guidance, not contradiction. The ratings cover pairs; upstream has no rating for three or more rule sets loaded together.
- **Weak tests or unclear behavior.** Follow the upstream order: `legacy-code` first, then this plugin inside the area it has put under control. This plugin's `/refactoring:characterize` and `/refactoring:safety-net` are a lighter version for code that is easy to call; that is this plugin's judgment, and upstream prefers `legacy-code` when tests are weak or behavior is unclear.
- **Do not load `refactoring-guru` alongside this plugin by default.** Choose one refactoring rule set; bring the other in only for the smell-catalog case above.
- **One router.** Do not run several books' `lead` agents at once; choose one (this plugin's judgment).

## Limitations

The upstream project publishes the criticisms it received in a public discussion, with a validity score for each and its own estimate of how far it has addressed them, as of 9 September 2026. They apply here because this plugin is built on those rule sets. The scores and statuses are the upstream maintainers' own estimates, not independent measurements; the last column says what each point means for this plugin.

| Criticism | Upstream validity | Upstream status | What it means here |
| --- | --- | --- | --- |
| No clear measurement of improvement | 9/10 | Weakly addressed, about 2/10 solved | There are no benchmarks, before-and-after comparisons, defect counts or review-time data for these rules; compression is auditable, outcomes are not measured. This plugin structures the advice and does not prove it works. Treat findings as informed review comments, not as a score. |
| This can burn tokens and pollute the context | 9/10 | Largely addressed, about 8/10 solved | Upstream ships three sizes (`mini` as the working layer, `nano` for tight always-on budgets, full for reference), but cannot stop a user attaching too much. Here, twenty model-invocable skills keep their descriptions in context on every turn; the hub reads the compact rules first and the full rules only on demand, the hook is off by default, and the whole plugin is the smallest unit you can turn off, since Claude Code's per-skill overrides do not apply to plugin skills. |
| Skills or progressive loading may be better than one big rules file | 9/10 | Largely addressed, about 9/10 solved | This plugin is built that way: skills load by description, specialists and output styles on demand, the always-on form is opt-in. |
| A short project-specific rule set may work better | 9/10 | Partially addressed, about 6/10 solved | Upstream still ships book-derived packs, not rules generated from one team's code. Its own suggestion is a compact file of 10 to 15 strong, testable, project-specific instructions; add one next to this plugin, because it may matter more than any generic rule. |
| The model may ignore many rules anyway | 8/10 | Partially addressed, about 6/10 solved | There is no empirical obedience data for the compressed sets, and more rules can mean ambiguity and instruction fatigue. The output styles, `refactoring:final-gate` and the forked scans add structure; they cannot guarantee obedience. |
| Rules should come from real project failures | 8/10 | Weakly addressed, about 3/10 solved | The rules come from a book, not from your incidents, and upstream has no mechanism for turning failed agent runs or postmortems into rules. When an agent repeats a mistake in your repository, record it as a project rule. |
| Rules from different books may conflict | 8/10 | Largely addressed, about 9/10 solved | The pairwise ratings above are the answer, but they are qualitative and source-based, not validated by task runs, and they cover pairs, not stacks of three or more. |
| The approach may cause overengineering | 8/10 | Largely addressed, about 7/10 solved | The source keeps its own anti-ceremony pressure (no abstracting coincidental similarity, no interfaces before a second real need) and every smell skill here has a leave-it-alone branch. Upstream cannot enforce good task selection, and this toolkit is heavy for a one-line change or a throwaway script. |
| The project could include more AI-agent-specific material | 7/10 | Partially addressed, about 6/10 solved | The rules are software-engineering-first, not an agent-operations handbook. The workflows here (`plan`, `prepare`, `characterize`, `fix`, the gates) add operational structure; that structure is this plugin's addition. |
| Too many abstract rules may lead to pseudo-compliance | 7/10 | Partially addressed, about 5/10 solved | An agent can produce a change that looks principled and still misses the task, and upstream has no outcome evaluations. Ask for evidence per checklist item: `refactoring:final-gate` treats a test result that was not shown as unproven. |
| Legal or licensing concerns | 6/10 | Weakly addressed, about 3/10 solved; resolution policy: won't fix | Upstream has no legal review and will not provide legal clearance; it frames its files as practical instructions inspired by the books, not official materials, not substitutes and not reproductions. This plugin is MIT-licensed, unofficial and vendors the upstream files unmodified (see Attribution and license). None of this is legal advice. |
| The model may already know these books | 5/10 | Moderately addressed, about 6/10 solved | Upstream agrees: the value is a short, decision-changing reminder, not full-book context, and it has no experiment showing the reminders beat the model's own priors. The value here is that reminder plus structure and a safe workflow, not secret knowledge. |
| Some principles may be outdated in the AI coding era | 5/10 | Partially addressed, about 5/10 solved | The core ideas (readability, modularity, testability, boundaries) still hold, but the source is classic and upstream has few AI-native rules. AI changes the economics of rewriting, so the rewrite brake here is a default, not a ban: an explicit user request for a rewrite ranks first in the hub's priority order. |

Caveats specific to this book and this toolkit:

- **The whole discipline leans on tests.** The rule set's answer to "how do I know I kept behavior" is a safety net. Where there is none, this plugin can only help you build a small one (`/refactoring:characterize`), limit yourself to tool-verified moves, and record the verification gap. Upstream's compatibility notes go further and prefer `legacy-code` when tests are weak or behavior is unclear. This plugin cannot manufacture confidence.
- **Reviewers read; they do not run.** They compare before and after by reading diffs and files. They cannot find a behavior change that appears only at runtime (timing, concurrency, resource limits), a test that passes for the wrong reason without seeing its output, or an external caller of a public name that lives outside the repository. `refactoring:behavior-preservation-reviewer` says "unknown" instead of guessing, and treats unknown as changed.
- **Two opposite risks.** Applied mechanically, small-step and extraction rules can produce many tiny helpers and slow plans; applied timidly, they can talk an agent out of a rewrite that really is the right call. The skills carry the source's brakes (stopping rules, restraint on abstraction), and the user's explicit instruction ranks first, but you still need to judge.
- **Compression drops detail by design.** Upstream's compact files intentionally drop per-smell recipes and individual catalog entries; the exact recipes remain only in the full file. The always-on `nano` form also drops detailed error-handling discipline, UI and domain synchronization, and the full class and module review taxonomy, so with `inject_rules` on and no skill loaded those points apply only when you ask for them.
- **Move mechanics are this plugin's, not the book's.** The source's catalog index gives a trigger per move, not the steps. The step-by-step mechanics, the pairing of a smell with a move and the numeric thresholds are labelled "Added judgment" in the components, and text labelled "compact checklist" appears only in the short rule files.
- **Contested or edition-dependent advice.** How small a step should be, when polymorphism beats a conditional, the right granularity of extracted functions and whether to prepare before every feature are debated. Where the source says "prefer", the skills say "prefer". The catalog index uses mostly first-edition names for the moves, and the second edition renames some of them.
- **Search thresholds are aids.** The line counts, nesting levels and parameter counts that the audit and the reviewers use to find candidates are not rules of the book.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule (public fields on data carriers, result types instead of exceptions, a framework base class), the priority order is your instruction, then the repository, then the book.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed *Refactoring* rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Refactoring* is by Martin Fowler. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
