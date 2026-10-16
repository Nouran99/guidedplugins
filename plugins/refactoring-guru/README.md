# Refactoring.Guru

The refactoring material of the Refactoring.Guru website (what refactoring is, when to do it, how to do it safely, the catalog of code smells and the catalog of refactoring techniques), turned into a Claude Code toolkit. It makes Claude name the smell before it changes anything, choose the smallest catalog technique that treats it, keep refactoring apart from feature and bug-fix edits, verify each risky step, and stop when the smell is gone instead of drifting into a redesign.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), seven usage walkthroughs with exact commands, a map from the rule set's sections to the components, and an honest section on what this cannot do.

## Overview

**The material in one paragraph.** Refactoring.Guru presents refactoring as a controlled change to the structure of code that adds no functionality, motivated by technical debt that compounds by slowing every later change. Its pages cover what refactoring is, how debt builds up, when to refactor (the rule of three, while adding a feature, while fixing a bug, during review), how to do it safely, a catalog of code smells in groups, and a catalog of refactoring techniques in groups. The rule set this plugin is built on is a paraphrase of those pages written for coding agents. It leaves out the site's example code, images, course pages and design pattern pages, and keeps the process, the smells, the treatments, and the many places where the advice says "not here".

**Who this is for.** Developers using Claude Code to change existing code in any mainstream language: paying down a smell that blocks a feature, reviewing a refactoring pull request, deciding which technique fits, or teaching a team the vocabulary. It pays off most on tasks that begin with a sentence such as "this is hard to change" or "clean this up", where an agent is most tempted to rewrite.

**The bias it corrects.** An agent asked to improve code tends to treat refactoring as a general tidy-up. It renames and reformats whatever looks untidy, folds a behavior change into the same edit, reaches for a pattern or a class hierarchy because the name sounds modern, wraps primitives that gain nothing, deletes code that looked unused, and keeps going because the next smell is also visible. The rule set replaces that with a loop repeated for each smell: diagnose (symptom, cost, scope, real or style), treat (the smallest technique that addresses it), verify (a named check, run after risky steps), stop (when the smell is gone, a different diagnosis is needed, the scope would grow, or further cleanup is speculative).

**What the toolkit adds to the raw rule set.**

- A hub skill (`/refactoring-guru:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- Two kinds of topical skill, so the catalog is used for the job it does best. Nine smell skills diagnose and rank treatments: they say how to recognize the smell, what it costs, which treatment is preferred, which is the fallback, which is risky, and when to leave it alone. Five technique skills perform: for each named technique they say when to use it, when not to, the safe steps and the verification (two of the smell skills, `type-codes-and-switches` and `hierarchies`, also carry the techniques of their own family). Five process skills cover separation, timing, stopping, treatment choice and public compatibility.
- Every one of the 23 smells and every one of the technique entries has exactly one owner, listed in [docs/DESIGN.md](docs/DESIGN.md).
- Workflows that follow what the material teaches: `smell-to-treatment` (a diagnose, treat, verify, stop card), `classify-change` (refactoring, feature or bug fix per hunk), `reachability-check` (can this symbol be deleted or changed) and `debt-triage`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of fourteen read-only specialist reviewers, each with its own report shape, six implementers that make small test-backed changes (one of which writes tests only), a `lead` that routes work in at most five steps, and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `treatment-card` (a written diagnosis before every edit) and `labeled-steps` (every change tagged refactor, feature or bug fix).

**When not to use it.** Reach for a different plugin when the real risk lies elsewhere: behavior that is unclear or untested (use a legacy-code plugin to characterize it first), the target shape of a design or architecture (use a software-design, architecture or domain-modeling plugin), production failure behavior, or distributed data semantics. If you also load the `refactoring` plugin, keep one of the two as primary: the upstream compatibility notes rate the pair as overlapping, not complementary. For a throwaway script the rules still hold, but the ceremony of this toolkit does not pay for itself.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install refactoring-guru@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/refactoring-guru
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall refactoring-guru@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**58 components:** 30 skills (20 Claude can load on its own, 10 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/refactoring-guru:behavior-ownership` | Use when a method works mostly on another object's data (feature envy), a class holds data while clients hold the logic (data class), or two classes depend on each other's internals (inappropriate intimacy). Decides… |
| `/refactoring-guru:change-locality` | Use when one change forces edits across many classes (shotgun surgery), one class changes for unrelated reasons (divergent change), or the same logic is repeated (duplicate code). Decides how to centralize or leave… |
| `/refactoring-guru:composing-methods` | Use when about to perform Extract Method, Inline Method, Extract Variable, Inline Temp, Replace Temp with Query, Split Temporary Variable, Remove Assignments to Parameters, Method Object or Substitute Algorithm.… |
| `/refactoring-guru:conditional-moves` | Use when about to perform Decompose Conditional, Consolidate Conditional Expression, Consolidate Duplicate Conditional Fragments, Remove Control Flag, guard clauses or Introduce Assertion. Checks side effects and… |
| `/refactoring-guru:data-smells` | Use when primitives, arrays or magic numbers stand in for concepts, a signature has more than three or four parameters, or the same group of values travels together (primitive obsession, parameter list, data clumps).… |
| `/refactoring-guru:dead-weight` | Use when code may be unused or not earning its cost: unused parameters, fields, methods, classes, near-empty classes, or abstractions built for imagined needs (dead code, lazy class, speculative generality). Decides… |
| `/refactoring-guru:delegation-and-gaps` | Use when client code walks a chain of objects (message chains), a class only forwards calls (middle man), or a library class lacks an operation you keep working around (incomplete library class). Balances hiding… |
| `/refactoring-guru:explanatory-comments` | Use when a comment explains what confusing code does, sits above a block that could be named, or guards a hidden assumption. Decides rename, extract variable, extract method or assertion versus keeping a comment for… |
| `/refactoring-guru:hierarchies` | Use when a subclass ignores inherited members (refused bequest), two classes do one job with different interfaces, a new subclass forces a matching subclass elsewhere, or when pulling up, pushing down, extracting a… |
| `/refactoring-guru:method-call-moves` | Use when about to change a method's name or signature: Add or Remove Parameter, Separate Query from Modifier, Parameterize Method, explicit methods for a flag, Preserve Whole Object, Parameter Object, factory method… |
| `/refactoring-guru:moving-features` | Use when about to perform Move Method, Move Field, Extract Class, Inline Class, Hide Delegate, Remove Middle Man, Introduce Foreign Method or Local Extension. Mechanics and safety checks, not diagnosis… |
| `/refactoring-guru:organizing-data` | Use when about to perform Replace Data Value with Object, change value to reference or back, Replace Array with Object, encapsulate a field or collection, change association direction, or replace a magic number.… |
| `/refactoring-guru:principles` | Applies the Refactoring.Guru rule set to changes of existing code. Use when smells, technique choice, behavior preservation or cleanup scope matter; it routes to the narrower skills, agents and modes of this plugin. |
| `/refactoring-guru:public-compatibility` | Use before deleting, renaming, inlining, hiding or changing the signature, constructor, visibility or type hierarchy of anything other code may reach: public, generated, reflected, serialized, plugin-facing or… |
| `/refactoring-guru:refactoring-process` | Use when carrying out a refactoring: keeping it separate from feature or bug-fix edits, working in small steps, choosing and running checks, and judging whether the code got cleaner. Not for deciding whether to… |
| `/refactoring-guru:size-smells` | Use when a method needs scrolling or comments to follow, a class carries several responsibilities, or fields are valid only in some situations (long method, large class, temporary field). Diagnoses and picks the… |
| `/refactoring-guru:stop-and-defer` | Use when a refactoring is running long: another smell appears, cleanup keeps expanding, a treatment would cross API or ownership scope, or a visible smell should be left in place. Stop conditions, deliberate… |
| `/refactoring-guru:treatment-choice` | Use when choosing among refactoring treatments for a diagnosed smell: smallest technique first, fallbacks, risky options, and rejecting polymorphism, wrappers, parameter objects or superclasses that do not earn their… |
| `/refactoring-guru:type-codes-and-switches` | Use when a switch or repeated if chain branches on a type, mode or status, a type code controls behavior, or null checks dominate a branch. Decides among explicit methods, type class, subclasses, state or strategy… |
| `/refactoring-guru:when-to-refactor` | Use when deciding whether to refactor now or later: third occurrence of duplication, before or after a feature, during a bug fix or review, or when debt slows the current change. Not for how to do it… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/refactoring-guru:audit` | Scan a directory or repository for smells in the source's scan order, in a forked context, and return ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/refactoring-guru:checklist` | Walk the ten Refactoring.Guru review questions interactively against the current work, with evidence and a next action for every no. | `[paths \| git ref \| empty for the current diff]` |
| `/refactoring-guru:classify-change` | Label each hunk of a diff as refactoring, feature, bug fix or mixed, and propose an order and a split so structure and behavior are reviewed separately. | `[paths \| git ref \| empty for the current diff]` |
| `/refactoring-guru:debt-triage` | Rank known technical debt by its effect on current change speed, correctness and team understanding, and decide absorb now, schedule or accept for each item. | `[list of debt items \| file \| empty to use deferred smells and TODOs in the current diff]` |
| `/refactoring-guru:explain-rule` | Explain one Refactoring.Guru rule, smell or technique: its strength, the reason, how to check it, an original example and the source's own exception. | `[rule text \| smell name \| technique name \| question]` |
| `/refactoring-guru:fix` | Resolve named refactoring findings one technique at a time with the smallest change, run the tests after each step, and never commit. | `[findings text \| file:line \| 'last review' \| empty to ask]` |
| `/refactoring-guru:plan` | Plan a non-trivial change before editing: primary smell, cost, smallest refactoring, cleaner end state, stop condition, checks and ordering against feature work. | `[goal or ticket text \| paths \| empty to plan from the current diff]` |
| `/refactoring-guru:reachability-check` | For one symbol, parameter or file, search every way other code may reach it and return a verdict on whether deleting, renaming or changing it is safe, in at most 40 lines. | `<symbol \| file \| function(param)> [change: delete \| rename \| change signature \| hide \| inline]` |
| `/refactoring-guru:review` | Review a diff or paths against the Refactoring.Guru rules and report ranked findings with a disposition for each. | `[paths \| git ref \| empty for the current diff]` |
| `/refactoring-guru:smell-to-treatment` | Turn one smell (named, or found in the diff or paths) into a diagnose, treat, verify, stop card with preferred, fallback and risky treatments. | `[smell name \| paths \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-refactoring-guru:bloat-reviewer` | sonnet | read-only | Reviewer of oversized units. Use proactively after edits that grow a method, add responsibilities to a class, or add fields that are used by only one operation: long method, large class, temporary… |
| `@agent-refactoring-guru:call-contract-reviewer` | sonnet | read-only | Reviewer of call shape and contracts. Use proactively after edits that rename methods, add or remove parameters, split queries from modifiers, replace flags with methods, change setters… |
| `@agent-refactoring-guru:change-locality-reviewer` | sonnet | read-only | Reviewer of where knowledge lives. Use proactively after edits that touch many files for one requirement, add a reason to change to an already busy class, or copy logic that exists elsewhere… |
| `@agent-refactoring-guru:characterizer` | sonnet | can edit files | Implementer that writes tests pinning current behavior before a risky refactoring, and never edits production code. Use when a planned move, extraction or substitution has no covering test and the… |
| `@agent-refactoring-guru:comment-reviewer` | sonnet | read-only | Reviewer of comments as a smell. Use proactively after edits that add or change comments above blocks, beside cryptic names or conditions, or that record assumptions about state: gives every comment… |
| `@agent-refactoring-guru:compatibility-reviewer` | sonnet | read-only | Reviewer of changes to externally reachable surface. Use proactively after edits that delete, rename, inline, hide or retype anything exported, or change a signature, constructor, visibility or… |
| `@agent-refactoring-guru:coupling-reviewer` | sonnet | read-only | Reviewer of who knows what about whom. Use proactively after edits that add methods reading another object's fields, long call chains, forwarding classes, data-only classes with logic in clients, or… |
| `@agent-refactoring-guru:data-modeling-reviewer` | sonnet | read-only | Reviewer of data modeling choices. Use proactively after edits that add primitives with domain meaning, arrays used by position, long parameter lists, repeated parameter groups, or new value types… |
| `@agent-refactoring-guru:dead-code-remover` | sonnet | can edit files | Implementer that deletes or inlines unused code only after reachability evidence exists. Use when dead-weight candidates were found and checked, and the user asked for the removal; it refuses… |
| `@agent-refactoring-guru:dead-weight-reviewer` | sonnet | read-only | Reviewer of structure that may not earn its cost. Use proactively after edits that add parameters, hooks, interfaces, options or subclasses without a second user, or that leave unused code behind… |
| `@agent-refactoring-guru:final-gate` | sonnet | read-only | Pre-merge gate that runs the ten Refactoring.Guru review questions against the working diff and returns PASS or FAIL with evidence. Use before declaring a refactoring done, committing, or opening a… |
| `@agent-refactoring-guru:hierarchy-reviewer` | sonnet | read-only | Reviewer of inheritance structure. Use proactively after edits that add or change subclasses, interfaces or superclasses, pull members up or push them down, or collapse a hierarchy: refused bequest… |
| `@agent-refactoring-guru:intent-reviewer` | sonnet | read-only | Reviewer of change intent. Use proactively after edits that are described as a refactoring, cleanup or tidy-up, or when a diff mixes structural changes with new rules, changed defaults, or bug… |
| `@agent-refactoring-guru:lead` | opus | read-only | Triage lead for refactoring work. Use first on any non-trivial change or review to decide, in at most five steps, which reviewers, implementers and skills apply and in what order. Routes only; does… |
| `@agent-refactoring-guru:method-body-reviewer` | sonnet | read-only | Reviewer of rewritten method bodies. Use proactively after extractions, inlinings, temp changes, consolidated conditions, guard clauses or control-flag removal: checks what is read, written… |
| `@agent-refactoring-guru:method-extractor` | sonnet | can edit files | Implementer that extracts one fragment at a time into a purpose-named method with full variable accounting. Use when a long method or commented block has been diagnosed and the user asked for the… |
| `@agent-refactoring-guru:refactorer` | sonnet | can edit files | Implementer that carries out a list of refactoring findings, one named technique per step, with tests after each. Use when a review, audit or smell card has produced findings and the user asked for… |
| `@agent-refactoring-guru:responsibility-mover` | sonnet | can edit files | Implementer that moves members between classes: Move Method, Move Field, Extract Class, Inline Class, with temporary delegation. Use when a data-ownership or class-size finding has been confirmed… |
| `@agent-refactoring-guru:safety-net-reviewer` | sonnet | read-only | Reviewer of verification evidence for refactorings. Use proactively after a refactoring that moves, extracts, inlines or restructures code, or that touches tests: it maps each risky step to the… |
| `@agent-refactoring-guru:scope-guard` | sonnet | read-only | Reviewer of refactoring scope. Use proactively after a refactoring or cleanup to compare the diff with the named smell and stop condition: it flags extra smells chased, mechanical treatments… |
| `@agent-refactoring-guru:type-introducer` | sonnet | can edit files | Implementer that introduces a value type, parameter object or object replacing an array, after its semantics are written down. Use when a data-modeling finding was confirmed and the user asked for… |
| `@agent-refactoring-guru:type-switch-reviewer` | sonnet | read-only | Reviewer of type-based branching. Use proactively after edits that add a case to a switch or if chain on a type, mode or status, introduce a type code, or add subclasses, state or strategy objects… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style refactoring-guru:labeled-steps` | Tags every change REFACTOR, FEATURE or BUGFIX and delivers them as separate sections in review order, so structure and behavior are never one indistinguishable edit. |
| `/output-style refactoring-guru:mentor` | Teaches the smell, treatment and stop rule behind each refactoring decision and checks understanding with one question. |
| `/output-style refactoring-guru:pair` | Works in small narrated refactoring steps and asks before any change larger than a few lines or touching a public interface. |
| `/output-style refactoring-guru:strict-reviewer` | Answers only with a ranked findings table against the Refactoring.Guru review questions; no rewrites unless asked; says No findings explicitly. |
| `/output-style refactoring-guru:terse` | Result first and brief: what changed, which technique, which check ran, what was left; failing output still shown in full. |
| `/output-style refactoring-guru:treatment-card` | Prints a smell, cost, technique, check and stop card before every edit and a one-line result after it, so no change happens without a diagnosis. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with the `lead` agent or the routing table in `/refactoring-guru:principles` when you are not sure what applies. The `lead` names at most five steps: reviewers for the clusters the change touches (intent, safety net, bloat, data modeling, type switches, hierarchies, change locality, dead weight, coupling, comments, compatibility, method bodies, call contracts, scope), each reporting in its own shape. Findings go to `/refactoring-guru:fix` or to an implementer (`refactorer` for a list, `method-extractor`, `responsibility-mover`, `type-introducer` and `dead-code-remover` for one kind of move, `characterizer` when no check exists), which make the smallest change, run the project's tests, and never commit. `final-gate` runs the ten review questions last. The smell skills decide, the technique skills perform, and `treatment-choice`, `stop-and-defer` and `public-compatibility` apply to every smell. The manual workflows are the entry points you type; `audit` and `reachability-check` run in a forked context and return at most 40 lines so a whole-repository search does not fill your conversation. Output styles change the rhythm and the report format of the entire session.

Skills are invoked as `/refactoring-guru:<name>`, agents are addressed as `refactoring-guru:<name>` (ask for them by name or let Claude delegate), and styles are selected with `/output-style refactoring-guru:<name>`.

## Usage walkthroughs

### 1. Review a tidy-up before you open the pull request

You changed pricing code and your description says "tidy the bulk discount". You suspect it does more than that.

```text
/refactoring-guru:review
```

With no argument it runs `git status` and `git diff`, labels the change refactoring, feature, bug fix or mixed, probes the touched code for smells in the source's scan order, and prints ranked findings with `file:line`, the smell or rule by name, the consequence, the smallest named fix and a disposition (fix now, isolate and schedule, or ask the author). Suppose it reports the change as mixed and finds a blocker: a threshold that changed from `> 100` to `>= 100` inside an extraction. Because the change is mixed, it points you to the next command:

```text
/refactoring-guru:classify-change
```

This prints a hunk ledger with a label per hunk (R, F, B or M), lists the behavior edits it found inside the refactoring (here the threshold), proposes an order (for example `[refactor]` extraction first, then `[feature]` threshold change with its own test) and says how to split each mixed hunk. It never stages or commits; you split the work and record it however your repository records changes. Then ask for the strict pass:

```text
Use the refactoring-guru:final-gate agent on my working diff.
```

The gate answers each of the ten review questions with evidence and returns `GATE: PASS` or `GATE: FAIL`. A test run it cannot see is reported as "not run" and fails item 5.

### 2. Plan a feature in code that has no tests

You must add a gift-order type to a checkout summary that switches on the order type in several files and has no test coverage.

```text
/refactoring-guru:plan add a gift-order type to the checkout summary
```

You get a plan, not edits: the goal labelled feature, the primary smell with its cost and scope, the preferred treatment with fallback and risky options marked, the cleaner end state and the stop condition, the checks, the order against the feature, the public interfaces touched and the smells you will not treat. Because the touched code has no covering test, the first step is to pin its behavior. Hand that step to the agent that only writes tests:

```text
Use the refactoring-guru:characterizer agent to pin the current behavior of src/checkout/summary.ts before the planned extraction.
```

It records the baseline, writes tests whose expected values come from observed output, reports oddities it did not change, and prints `Production code changed: none`. Then carry out the refactoring steps of the plan and keep the feature separate:

```text
/output-style refactoring-guru:labeled-steps
Use the refactoring-guru:refactorer agent to carry out the refactoring steps of the plan.
```

The refactorer applies one named technique per step, runs the covering tests after each, stops at each finding's stop condition, and lists what it noticed but left. The feature step then arrives as its own section, tagged `[FEATURE]`.

### 3. Find the hot spots, then treat one smell

A billing directory has grown and every new tax rule seems to touch many files.

```text
/refactoring-guru:audit src/billing
```

The audit runs in a fork and returns at most 40 lines: a rating (healthy, watch or hot) for each of the six stops of the scan order (bloaters, object-orientation abusers, change preventers, dispensables, couplers, library gaps), up to five hot spots ranked by cost of the next change, and the next command for each. Take the first hot spot:

```text
/refactoring-guru:smell-to-treatment Shotgun Surgery src/billing
```

The card has the diagnosis (symptom, cost, scope, real or style), the treatment ladder (preferred: Move Method and Move Field to centralize ownership; fallback: Inline Class or Extract Class; risky: more forwarding layers without fewer edit sites), the verification, the stop condition and the exceptions to weigh. It edits nothing. To act on it:

```text
/refactoring-guru:fix last review
```

`fix` takes the findings of the most recent review, card or audit in the conversation, records a test baseline, applies one technique at a time with the family skill's safe steps (here `/refactoring-guru:moving-features`), runs the tests after each step and does not commit. Finally check proportion:

```text
Use the refactoring-guru:scope-guard agent to compare my diff with the Shotgun Surgery card.
```

It classifies every hunk (treats the diagnosed smell, enabling step, extra smell chased, abstraction without evidence), says whether the stop condition held, and whether the smells left behind were reported.

### 4. Delete unused code without breaking outside users

A function called `formatLegacyInvoice` looks unused in a package that other teams install.

```text
/refactoring-guru:reachability-check formatLegacyInvoice delete
```

In a fork, it searches nine channels (definition, language references, generated code, reflection and strings, serialization and storage, plugin surface, tests and documentation, other consumers, overrides) and returns a verdict: `SAFE`, `TRANSITION PATH NEEDED` or `UNKNOWN`, in at most 40 lines. For an exported function it will not say `SAFE` from the absence of references in this repository alone. If the verdict is safe:

```text
Use the refactoring-guru:dead-code-remover agent to delete formatLegacyInvoice; the reachability check found no usage.
```

The remover re-checks that the evidence covers each channel, deletes in its own step, runs the covering tests, searches for stale references and reports. If the verdict was `TRANSITION PATH NEEDED`, the agent refuses to delete and proposes the transition instead (keep the old form, add a deprecation notice, remove in a later release). For a parameter that nothing reads on a public function, see the example in `/refactoring-guru:public-compatibility`.

### 5. Learn the reasoning while you work

You are new to the catalog and want the names, not just the edits.

```text
/output-style refactoring-guru:mentor
```

Now ask: "This method has three comments that mark phases. What should I do?" Claude does the extraction first, keeping it small, then adds a Why block: the smell (Long Method), the technique and rung (Extract Method, the preferred rung), the stop condition reached, anything left alone and why, and one closing question that tests the idea. For the rule behind a technique:

```text
/refactoring-guru:explain-rule Replace Temp with Query
```

You get the technique entry in a fixed shape: what it does, the strength of the source's wording, why, how to check, a short original example, the source's own exception and which skill or agent applies it. If you prefer to see the diagnosis before each edit instead of after, try `/output-style refactoring-guru:treatment-card`, which prints a smell, cost, technique, check and stop card before every change.

### 6. Triage the debt before a sprint

Several shortcuts are noted in comments and in a backlog file, and you cannot do them all.

```text
/refactoring-guru:debt-triage docs/debt.md
```

The skill reads the file as the list, asks for the current change if it is unclear, and returns a table: each item with its smell name, location, source of the debt, its effect on current change speed, correctness and understanding, whether it sits on the path of the current change, and a decision (absorb now, schedule with a reason, or accept with a trigger to revisit). It warns if the plan postpones everything to a future cleanup project. For an item you decided to absorb:

```text
/refactoring-guru:smell-to-treatment Primitive Obsession
```

### 7. Let the lead route a large diff

You have a branch with forty changed files and do not know which reviewers apply.

```text
Use the refactoring-guru:lead agent on my current diff.
```

The lead reads just enough to name the change type and the touched smell groups, and returns at most five steps in order, a skip list, the stop condition and a risk level. A typical answer is `intent-reviewer` (the diff mixes a rename with a rule change), `safety-net-reviewer` (tests were edited in the same hunks), `coupling-reviewer` (new forwarding classes), then `final-gate`. Run the steps it names; each reviewer is read-only and reports in its own shape: an intent ledger, an evidence map, a data-use and path ledger. The lead proposes an implementer only if you asked for changes.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale is in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Source and Scope | `principles`, `explain-rule` |
| Purpose | `principles`, `refactoring-process`, `mentor` |
| Primary Directive | `refactoring-process`, `classify-change`, `intent-reviewer`, `labeled-steps` |
| Refactoring Process | `refactoring-process`, `safety-net-reviewer`, `intent-reviewer`, `pair`, `fix` |
| When to Refactor | `when-to-refactor`, `plan`, `debt-triage` |
| Technical Debt Rules | `when-to-refactor`, `debt-triage`, `audit` |
| Smell Detection Process | `audit`, `smell-to-treatment`, `stop-and-defer`, `lead`, `treatment-card` |
| Bloaters | `size-smells`, `data-smells`, `bloat-reviewer`, `data-modeling-reviewer` |
| Object-Orientation Abusers | `type-codes-and-switches`, `hierarchies`, `size-smells`, `type-switch-reviewer`, `hierarchy-reviewer` |
| Change Preventers | `change-locality`, `hierarchies`, `change-locality-reviewer` |
| Dispensables | `dead-weight`, `explanatory-comments`, `behavior-ownership`, `change-locality`, `dead-weight-reviewer`, `comment-reviewer` |
| Couplers | `behavior-ownership`, `delegation-and-gaps`, `coupling-reviewer` |
| Technique Selection Rules | `treatment-choice`, `refactorer`, and one owner per technique family: `composing-methods`, `moving-features`, `organizing-data`, `type-codes-and-switches`, `conditional-moves`, `method-call-moves`, `hierarchies` |
| Smell-to-Treatment Priority Map | `treatment-choice`, `smell-to-treatment`, every smell skill, `refactorer` |
| Technique Playbook | `composing-methods`, `moving-features`, `organizing-data`, `conditional-moves`, `method-call-moves`, `hierarchies`, `method-extractor`, `explain-rule` |
| Decision Anti-Patterns | `treatment-choice`, `scope-guard`, `review`, `strict-reviewer`, `public-compatibility` |
| Technique Execution Safety | `fix`, the family skills through their safety sections, `method-body-reviewer`, `call-contract-reviewer`, `hierarchy-reviewer` |
| Safety and Tradeoff Rules | `treatment-choice`, `public-compatibility`, `compatibility-reviewer`, `reachability-check`, `dead-weight` |
| Refactoring Workflow for Agents | `plan`, `fix`, `review`, `checklist`, `refactorer`, `lead`, `final-gate`, `pair`, `terse` |
| Review Checklist | `checklist`, `review`, `final-gate`, `strict-reviewer`, `principles` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `refactoring` | Overlap (conflict 8%, overlap 90%, complementarity 30%) | Both solve the same problem: changing structure without changing behavior. The upstream note calls `refactoring` the stronger process rule set and this one a smell-and-technique checklist, and says to choose one. Prefer `refactoring` for most code-change tasks; prefer this plugin when the task is specifically smell identification or technique selection. Use both only for a review-heavy cleanup that needs the process plus an explicit smell catalog. The cost of loading both is duplicate context, not contradictory advice. |
| `legacy-code` | Complementary (conflict 10%, overlap 58%, complementarity 76%) | When tests are weak or behavior is unclear, characterize first and create the smallest seam, then apply this plugin inside the controlled area. The tension is sequencing: refactoring pressure waits until control exists. Prefer the `legacy-code` plugin, where available, until you have that control. |
| `clean-code` | Complementary (conflict 12%, overlap 38%, complementarity 78%) | It sets local readability targets (names, function shape, side effects); this plugin chooses the treatment and the stop point. Use both when reshaping code toward those targets without changing behavior. The tension is scope creep: readability goals must not override behavior preservation or the current-smell stop condition. |
| `philosophy-of-design` | Complementary (conflict 12%, overlap 38%, complementarity 78%) | It supplies module depth, interface shape and information hiding; this plugin supplies safe sequencing. The same scope-creep tension applies: a design ideal does not license a rewrite inside a refactoring. |
| `clean-architecture` | Complementary (conflict 12%, overlap 38%, complementarity 78%) | It supplies dependency direction and replaceable details; use this plugin to move existing code toward that shape in small, verified steps. Prefer this plugin when observable behavior must stay unchanged; prefer the architecture plugin when designing new behavior. |

The remaining books (`ddd`, `ddd-distilled`, `ddd-implementing`, `enterprise-patterns`, `data-intensive-apps`, `release-it`, `pragmatic-programmer`, `code-complete`) carry the same ratings in the upstream notes (conflict 12%, overlap 38%, complementarity 78%): complementary when their own trigger is present, with the same scope-creep tension when you reshape existing code toward them.

**Recommended pairing.** Keep one design or readability plugin as the always-on rule set for everyday work and bring this plugin in on demand when the task is to change existing code structure, for example `clean-code` always on and `refactoring-guru` loaded per refactoring task. For code without tests, start with `legacy-code` (where available) and add this plugin once the behavior is pinned. **Avoid loading together:** `refactoring` and this plugin as co-primary rule sets with `inject_rules` on in both, and the `lead` agents of several book plugins at once; they would give overlapping routing advice on the same diff.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **Context cost.** Twenty model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small. Disable skills you do not use, and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce a change that looks like a textbook technique while missing the task. The reviewers, gate and output styles add structure; they cannot guarantee obedience.
- **Book-derived, not incident-derived.** The rules come from public material, not from your team's failures. A short, project-specific rules file for the mistakes your agents actually make will usually matter more than any generic rule.
- **Mechanical application is the main risk.** Applied by rote, a catalog invites needless polymorphism, wrappers, parameter objects and tiny extracted methods. The source's own brakes (simple honest conditionals, coincidental similarity, useful comments, boundary-keeping layers, small extension points) are in every smell skill, and `stop-and-defer` and `scope-guard` exist to enforce them, but you still need to judge.
- **A class-and-method vocabulary.** The technique names (Extract Class, Pull Up Method, Replace Inheritance with Delegation) assume an object-oriented language. In functional, data-oriented or scripting code, translate the intent: the smell and the stop rule still apply, the mechanics differ. This is the plugin author's observation, not a statement of the source.
- **Thresholds are warnings.** Ten lines for a method and three or four parameters are the source's own warning levels, not limits. Any other number in a skill is labeled "Added judgment" and is a search aid.
- **Contested advice.** The Rule of Three, polymorphism over conditionals, deleting unused code and extracting small methods are debated. Where the source says "should", the skills say "should"; where it says "may", they say "may".
- **Design patterns are out of scope.** The upstream rule set excludes the site's design pattern pages. This plugin tells you how to treat a smell, not which pattern to apply to a new design.
- **What it cannot detect.** The reviewers work by reading diffs and files. They do not execute code, so they cannot find a behavior change that only appears at runtime, a performance regression, or a test that passes for the wrong reason without seeing its output. The `characterizer` pins only what its tests exercise. The validator for this repository checks structure and traceability, not the quality of the advice.
- **Compatibility verdicts are qualitative.** The upstream pairwise ratings are based mostly on the compressed rule files, not on measured task runs.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule, the priority order is your instruction, then the repository, then the rule set.
- **The model may already know this material.** The value here is a short, decision-changing reminder plus structure, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Refactoring.Guru rule set published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. The refactoring material it is derived from is published by Refactoring.Guru. This plugin is not affiliated with, endorsed by or approved by that website, its authors or publisher, or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the site's text, images or example code and are not a substitute for reading it.
