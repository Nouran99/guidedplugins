# Working Effectively with Legacy Code

A Claude Code toolkit that makes an agent change code it cannot yet trust the way Michael Feathers's *Working Effectively with Legacy Code* teaches: pin what the code does, find the smallest seam, break one dependency, change, and leave the area easier to change than before. It turns the book's rule set into skills, subagents and output styles for reviewing, planning, characterizing, breaking dependencies, adding behavior beside fragile code, auditing and teaching.

This plugin is unofficial and is not affiliated with the book's author or publisher. See [Attribution and license](#attribution-and-license).

## Overview

**The book in short.** Code that nobody can change with confidence is expensive no matter how it looks. The way out is not a rewrite; it is control. Treat any area without trustworthy tests as legacy code. State what the change must alter and what must stay the same. When current behavior is unclear, record what the code does today in characterization tests, even where the result is ugly. To get the code under test, find a seam: a place where behavior can be changed without editing the surrounding code, used to observe what the code does, to substitute a dependency, or both. Break the one dependency that blocks the test: a clock, a random source, an environment read, a file or network call, a constructor that does real work, a static or global, a framework callback. Make the change as its own step. When editing fragile code is too risky, add the new behavior beside it with a sprout or a wrap. Refactor locally afterwards, and keep a temporary seam only while it still pays for itself.

**What an agent gets wrong without it.** Asked to change old code, an agent reads, guesses and edits. When the code is hard to run, it rewrites it, renames it, or reshapes the module in one large step nobody can verify. This rule set replaces that with a short loop that earns control first.

**What this toolkit adds.** The upstream rule set is a compact policy. This plugin turns it into working parts:

- skills that carry one cluster of rules each (pinning behavior, choosing a seam, hidden inputs, hard outputs, construction, statics and globals, substitution, last-resort seams, sprout and wrap, large methods, policy versus mechanism, rewrite pressure, patch shape) with rule strength, a check for every rule, an original example and the exceptions the book allows;
- workflows you run by name (`/legacy-code:characterize`, `/legacy-code:find-seam`, `/legacy-code:effect-sketch`, `/legacy-code:plan`, `/legacy-code:review`, `/legacy-code:split-patch` and others);
- read-only reviewers, each with its own report shape, and implementers that remove one kind of barrier in small, tested steps;
- output styles that change how a whole session behaves, including a mode that pins before it edits and a read-only exploration mode.

Rule strength follows the source: an unqualified rule is a must, "prefer" is a should, "do not" and "avoid" are must-nots (except the items the source lists under "Preferred avoidance", which are shoulds). Every rule in a skill carries a tag: `[MUST]`, `[SHOULD]`, `[MUST NOT]`, `[Compact checklist]` for phrasing that exists only in the shortened rule files, and `[Added judgment]` for this plugin's own heuristics. The source names most techniques and says when to use them but does not describe their mechanics; the mechanics, language caveats and search aids in this plugin are labelled as added judgment so you can tell the book's rules from the plugin's suggestions.

**Use it when** you change code with weak or missing tests, hidden dependencies or runtime setup that blocks local feedback, or when someone proposes a rewrite of code you cannot observe.

**Do not use it as the primary rule set when** the code is already well protected and the task is behavior-preserving restructuring (use the `refactoring` plugin), when the task is local readability (`clean-code`), dependency direction between layers (`clean-architecture`), or production failure behavior (`release-it`). Those apply inside the area this plugin first makes safe to change.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install legacy-code@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/legacy-code
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand. A repository that is mostly legacy code is a reasonable place to make this the primary one.

To remove it later:

```text
/plugin uninstall legacy-code@guided-plugins
```

## Components

<!-- COMPONENTS:START -->

**55 components:** 29 skills (18 Claude can load on its own, 11 you run by name), 20 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/legacy-code:change-separation` | Use when shaping a legacy patch or reviewing its shape: keep behavior change, structural refactoring and cleanup apart, stay at the change point, take one small dependency break. Order of work is `legacy-loop`; whether… |
| `/legacy-code:characterization-tests` | Use when current behavior is uncertain and must be captured before a change: pinning actual outputs, ugly behavior consumers rely on, suspicious results, probes. New-requirement tests are `focused-tests`; where to test… |
| `/legacy-code:construction-barriers` | Use when a class cannot be instantiated cheaply in a test: constructors that do real work, collaborators created inside methods, factory calls buried in behavior, graphs built mid-logic. Static access is… |
| `/legacy-code:focused-tests` | Use when choosing test level and speed or writing tests for the requested behavior through a new seam: fast focused tests, old versus new behavior tests, real-boundary integration tests. Pinning unknown behavior is… |
| `/legacy-code:hard-outputs` | Use when code writes files, calls the network, exits the process, writes the database, publishes messages or uses logging as control flow, so effects cannot be observed in a test. Clock and environment reads are… |
| `/legacy-code:hidden-inputs` | Use when a test is not repeatable because code reads the clock, random numbers, environment variables, thread-local state or the implicit current user or request. Your own static singletons and global config are… |
| `/legacy-code:large-methods` | Use when changing a long method, large class or tangled branches: pure computation first, side effects second, method objects, tests around extracted parts. Adding behavior beside it is `sprout-and-wrap`; layers are… |
| `/legacy-code:last-resort-seams` | Use only when ordinary object seams are impractical and you consider subclass-and-override, extract-and-override, link, preprocessing, import, template or text redefinition seams. Covers when they are allowed and their… |
| `/legacy-code:legacy-loop` | Use when starting a change in untested code and you need the order of work: state the delta, check protection, seam, break one dependency, change, refactor locally. Pinning is `characterization-tests`; patch shape is… |
| `/legacy-code:policy-vs-mechanism` | Use when business decisions are trapped in framework entry points, UI handlers, callbacks or database-heavy code: separate policy from query, mapping and runtime, keep adapters thin. One long body is `large-methods`… |
| `/legacy-code:principles` | Applies the Working Effectively with Legacy Code rules to changes in code that is untested, poorly understood or hard to instantiate. Use first on any such change: it states the modal convention and routes to every… |
| `/legacy-code:rewrite-pressure` | Use when a rewrite, wholesale replacement, large new architecture or module-wide cleanup is proposed, or renaming and formatting are offered instead of making the change safe. Picks the next smaller verified move; work… |
| `/legacy-code:scratch-refactoring` | Use when code is too tangled to understand before a change: throwaway restructuring, marking and grouping responsibilities, keeping exploratory edits out of the commit. Choosing what to test is `test-points`; a real… |
| `/legacy-code:seams` | Use when deciding where a seam goes and what it is for: smallest seam, sensing versus separation, explicit over magical. Where to observe an effect is `test-points`; techniques live in the barrier skills and… |
| `/legacy-code:sprout-and-wrap` | Use when new behavior must go into fragile code you cannot yet test: sprout method, sprout class, wrap method, wrap class, insert-beside-and-redirect. Reshaping existing code is `large-methods`; removing dependencies… |
| `/legacy-code:static-and-global` | Use when static calls, singletons, global configuration or shared global state block substitution: wrappers, facades, instance delegators, getters, caller migration. Clock, randomness and environment reads are… |
| `/legacy-code:substitution-seams` | Use when a concrete or oversized dependency blocks compiling or substituting it: narrow interfaces, adapters for framework objects, extracted implementers, parameterized methods, primitive parameters. Constructors are… |
| `/legacy-code:test-points` | Use when the impact of a change is unclear and you must choose where to observe it: effect sketches, test points, interception points, pinch points. A seam's place is `seams`; restructuring to understand is… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/legacy-code:audit` | Scan a directory or repository for legacy-change risk in a forked context and return rated clusters and ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/legacy-code:characterize` | Pin the current behavior of one function, class or branch with characterization tests, mark suspicious results, and stop at the first barrier that keeps the code from being called. Writes tests only; never changes… | `[function \| class \| file:line \| behavior to pin \| empty to choose from the diff]` |
| `/legacy-code:checklist` | Walk the nine Working Effectively with Legacy Code review questions against the current work, answering yes, no or not applicable with evidence and a next action for each no. | `[paths \| git ref \| empty for the current diff]` |
| `/legacy-code:effect-sketch` | Trace the effects of a change outward from its change point in a forked context and return a sketch with test points, interception points and pinch points in at most 40 lines. | `[function \| class \| file:line \| planned change in a sentence]` |
| `/legacy-code:explain-rule` | Explain one Working Effectively with Legacy Code rule: its strength (must, should, must not), the reason, how to check it, an original example and the book's own exceptions. | `[rule name \| section \| situation you are unsure about]` |
| `/legacy-code:find-seam` | For one target and the test you want to write, name the first barrier, list candidate seams, pick the smallest, and name its technique, owning skill and implementer. Proposes only; never edits. | `[function \| class \| file:line] [the test you want to write, in a sentence]` |
| `/legacy-code:fix` | Resolve given legacy-change findings with the smallest change per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/legacy-code:plan` | Plan a change in untested code as the legacy loop: delta, protection, test points, barrier, seam, ordered steps and cleanup obligations. Plans only; never edits. | `[change request \| issue text \| empty to ask]` |
| `/legacy-code:review` | Review a diff or paths against the Working Effectively with Legacy Code rules and report ranked findings, each with the owning skill and the implementer that can fix it. Reads only; never edits. | `[paths \| git ref \| empty for the current diff]` |
| `/legacy-code:seam-ledger` | Inventory existing test-only structure in a forked context (override points, widened visibility, test setters, build flags, probes) and mark each keep, fold or remove, in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/legacy-code:split-patch` | Classify the hunks of a mixed legacy patch (behavior, dependency break, structure, cleanup, test) and propose an ordered split into separately verifiable steps. Proposes only; never stages or commits. | `[git ref \| paths \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-legacy-code:boundary-wrapper` | sonnet | can edit files | Implementer that puts a clock, random source, environment read, file write, network call, process exit, database write or message behind a small collaborator, in tested steps. Use when hidden-input… |
| `@agent-legacy-code:change-intent-reviewer` | sonnet | read-only | Reviewer of patch shape in legacy changes: labels each hunk by intent and flags mixed behavior and structure, broad edits, rewrites as the first move, cosmetic-only refactoring and new hidden… |
| `@agent-legacy-code:characterization-writer` | sonnet | can edit files | Implementer that writes characterization tests for a list of named targets without asking questions, marking suspicious results instead, and never touching production code. Use when several targets… |
| `@agent-legacy-code:collaborator-injector` | sonnet | can edit files | Implementer that turns a hard-coded collaborator into an explicit input: parameterize constructor or method, extract a narrow interface, adapt a parameter, expose a static method. Use when… |
| `@agent-legacy-code:construction-reviewer` | sonnet | read-only | Reviewer of construction barriers: constructors that do real work, collaborators created inside methods, hidden factory calls and object graphs built mid-logic. Use proactively after edits to… |
| `@agent-legacy-code:final-gate` | sonnet | read-only | Pre-merge gate that runs the nine Working Effectively with Legacy Code review questions against the working diff and returns PASS or FAIL with evidence. Use before declaring legacy work done… |
| `@agent-legacy-code:global-encapsulator` | sonnet | can edit files | Implementer that wraps statics, singletons and global configuration behind a narrow facade and migrates callers incrementally, testing after each batch. Use when static-and-global findings call for… |
| `@agent-legacy-code:hard-output-reviewer` | sonnet | read-only | Reviewer of hard outputs: direct file writes, network calls, process exits, database writes, message publication and logging used as control flow inside logic. Use proactively after edits to code… |
| `@agent-legacy-code:hidden-input-reviewer` | sonnet | read-only | Reviewer of hidden inputs: clock, randomness, environment variables, thread-local state and the implicit current user or request read from inside logic. Use proactively after edits to code that… |
| `@agent-legacy-code:large-method-reviewer` | sonnet | read-only | Reviewer of edits to large methods and classes: extraction order, pure versus effect code, branches changed at once, tests around extracted parts. Use proactively after edits inside a long method or… |
| `@agent-legacy-code:lead` | opus | read-only | Triage lead for Working Effectively with Legacy Code work. Use first on any non-trivial change to code without trustworthy tests to decide which specialists, workflows and skills apply, in what… |
| `@agent-legacy-code:method-extractor` | sonnet | can edit files | Implementer that carves pure computation out of a large method or a handler holding decisions, one extraction at a time under a broad pin, then isolates effects if asked. Use when large-method or… |
| `@agent-legacy-code:policy-mechanism-reviewer` | sonnet | read-only | Reviewer of business decisions trapped in framework entry points, UI handlers, callbacks and database-heavy code, and of adapter thickness. Use proactively after edits to route handlers, listeners… |
| `@agent-legacy-code:protection-reviewer` | sonnet | read-only | Reviewer of test protection for legacy changes: whether modified logic has trustworthy tests and whether characterization tests are honest. Use proactively after edits to code that has few or no… |
| `@agent-legacy-code:seam-cleaner` | sonnet | can edit files | Implementer that retires or folds test-only structure once safer structure exists: probes, sensing variables, test setters, override points, widened visibility. Use when seam-ledger or seam-reviewer… |
| `@agent-legacy-code:seam-reviewer` | sonnet | read-only | Reviewer of seams a change adds: kind, sensing or separation, size, explicit or magical, last-resort tier and cleanup path. Use proactively after edits that add parameters, interfaces, override… |
| `@agent-legacy-code:sprout-opportunity-reviewer` | sonnet | read-only | Reviewer of how new behavior enters fragile code: deep edits where a sprout or wrap would lower risk, and sprouts and wraps done badly. Use proactively after a change adds a rule, step or condition… |
| `@agent-legacy-code:sprouter` | sonnet | can edit files | Implementer that adds requested behavior beside fragile code as a sprouted method or class or as a wrap, with tests for the new unit and a one-call insertion point. Use when a rule, step or… |
| `@agent-legacy-code:static-global-reviewer` | sonnet | read-only | Reviewer of static and global reach-through: static calls, singletons, global configuration and shared global state used from logic, and new reach-through the diff adds. Use proactively after edits… |
| `@agent-legacy-code:test-level-reviewer` | sonnet | read-only | Reviewer of test level, speed and focus in legacy changes: tests through the seam, old versus new behavior tests, broad tests as scaffolding, integration tests at real boundaries. Use proactively… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style legacy-code:characterize-first` | Before any edit to code without trustworthy tests, prints a safety preamble and writes the pin first; after the change prints a loop trace of what was pinned, seamed and left unprotected. |
| `/output-style legacy-code:explorer` | Read-only understanding mode for unfamiliar legacy code: effect sketch, responsibility groups, open questions, candidate test points and seams, and one next safe move. Produces no patch. |
| `/output-style legacy-code:mentor` | Teaches the legacy-code rule behind each decision, names its strength and the loop step it belongs to, and checks understanding with one question. |
| `/output-style legacy-code:pair` | Works in small narrated steps through the legacy loop, runs tests after each, and asks before any change larger than a few lines or touching public API. |
| `/output-style legacy-code:strict-reviewer` | Answers as a ranked findings table for legacy-change risks, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style legacy-code:terse` | Result first, no preamble, a few lines unless asked, while still stating protection and showing failing output in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with `legacy-code:lead` when you are unsure what a task needs: it names at most five steps, in order, and proposes implementers only when you asked for changes. The analysis steps are workflows (`/legacy-code:effect-sketch` to choose where to look, `/legacy-code:find-seam` to name the barrier and the smallest seam, `/legacy-code:characterize` to pin). The reviewers each look at one concern and hand the fix to the implementer for that barrier: `legacy-code:hidden-input-reviewer` and `legacy-code:hard-output-reviewer` to `legacy-code:boundary-wrapper`, `legacy-code:construction-reviewer` to `legacy-code:collaborator-injector`, `legacy-code:static-global-reviewer` to `legacy-code:global-encapsulator`, `legacy-code:large-method-reviewer` and `legacy-code:policy-mechanism-reviewer` to `legacy-code:method-extractor`, `legacy-code:sprout-opportunity-reviewer` to `legacy-code:sprouter`, `legacy-code:protection-reviewer` to `legacy-code:characterization-writer`, and leftover test-only structure to `legacy-code:seam-cleaner`. `legacy-code:final-gate` ends the sequence with a pass or fail. The order inside a change is fixed by the book's loop: pins, dependency breaks, the behavior change, then local cleanup. The one exception is a dependency break that is what makes a pin possible; it comes first, kept conservative (signature kept, old behavior as the default), and the pin follows at once.

The skills named in the table above load themselves when their trigger matches (their descriptions say which request fires which skill). The workflows run only when you call them. The agents run when you or Claude delegate to them.

## Usage walkthroughs

Each walkthrough shows the commands and what the components do with them. Outputs are described by shape; your repository determines the content.

### 1. Fix a bug in an untested function that reads today's date

*Situation.* `billing/fees.py` has `fee_for(invoice)`; late fees keep compounding forever and should stop after 90 days. Nothing tests it, and it calls `date.today()` inside.

```text
/output-style legacy-code:characterize-first
/legacy-code:plan stop compounding late fees after 90 days in billing/fees.py
```

The mode prints a safety preamble before any edit (change point, delta, what must stay, protection, first pin). `plan` writes the loop card: protection is none, the barrier is the clock read, the seam is a `today` parameter, and the steps run in the order the book gives, except that the clock injection comes first because it is what stops every pin.

```text
/legacy-code:find-seam billing/fees.py:fee_for call it with a fixed date and assert on the fee
```

The proposal names the first barrier (`date.today()`, a hidden input), the candidate seams with their enabling points, the chosen one (a `today` parameter defaulting to the real date), the technique and its owner (`/legacy-code:hidden-inputs`, implementer `legacy-code:boundary-wrapper`) and says that pinning first is not possible, so this break is the enabling step.

Delegate the break to `legacy-code:boundary-wrapper` with that proposal. It finds no test, sees that the barrier stops every pin, makes the signature-preserving change, reports `Protection: none: enabling step made conservatively, pin next` and stops.

```text
/legacy-code:characterize billing/fees.py:fee_for
```

The workflow pins the current results with a fixed date, marks any surprising result with a `CHARACTERIZATION` marker and a question for the owner, and runs the pins on unchanged logic. Now make the 90-day change as its own step with its own test, then:

```text
/legacy-code:review
```

The review checks protection, patch shape and new hidden dependencies, and names the next step. Run `legacy-code:final-gate` before committing: it answers the nine review questions with evidence and returns PASS or FAIL.

### 2. Add a rule to a long, untested function without reshaping it

*Situation.* Customers should earn loyalty points inside `checkout()` in `orders/checkout.ts`, a function of several hundred lines that nothing tests.

Ask Claude to use `legacy-code:lead` on the request. It classifies the change as new behavior in fragile code and returns an ordered plan of at most five steps, for example the effect sketch, the sprouter, the sprout reviewer and the gate.

```text
/legacy-code:effect-sketch orders/checkout.ts:checkout add loyalty points after the total is computed
```

The forked workflow returns at most 40 lines: what `checkout` reads, writes and calls, the pinch and interception points, the first test point and the barrier, if any.

Delegate to `legacy-code:sprouter` with the one-sentence behavior, the function and the insertion point. It checks protection around the insertion point (if the flow cannot be called in a test it reports the flow as unprotected and continues, because a sprout is made for that case), writes the tests for the new `loyaltyPointsFor` unit first, adds the single call in the legacy body and reports how many legacy lines it touched. Then run `legacy-code:sprout-opportunity-reviewer`: it returns an insertion ledger saying whether the edit is a call or logic inline, and whether the sprouted unit has its own tests.

### 3. Review a pull request that mixes a rename, a seam and a rule change

*Situation.* A branch fixes a refund rule, but the diff also renames a module and reformats a directory.

```text
/legacy-code:review origin/main
```

The review lists ranked findings with the owning skill and the implementer for each. The mixed intent and the reformat show up as findings about patch shape, and the next step it names is `/legacy-code:split-patch`. For a large diff it suggests `legacy-code:lead` and the reviewers it names rather than reading everything itself.

```text
/legacy-code:split-patch origin/main
```

`split-patch` labels each hunk (behavior, dependency break, structure, cleanup, test), says which hunks depend on which, and proposes the order: pins, dependency breaks, the behavior change with its own test, then structure and cleanup. It lists the hunks that cannot be separated and the ones that are out of scope. It does not stage or commit; you do that. For the ledger of hunks with findings, run `legacy-code:change-intent-reviewer`.

### 4. Audit a repository and retire leftover test scaffolding

*Situation.* A service has years of test-only setters, protected methods and a few debug counters from earlier rescue work.

```text
/legacy-code:audit src
```

The forked audit returns at most 40 lines: eight clusters rated healthy, watch or hot (protection, hidden inputs, hard outputs, construction, statics and globals, logic in entry points, large methods, temporary seams), up to five ranked hot spots with the first move for each, and one next command.

```text
/legacy-code:seam-ledger src
```

The ledger lists the existing test-only structure with its kind, what it serves (sensing, separation or both) and a status: keep, fold into an explicit seam, or remove. Hand the fold and remove rows to `legacy-code:seam-cleaner`; it checks all users, folds a row into an explicit parameter or interface, migrates the tests that used the old seam, deletes the old one and runs the tests after each row. Rows it cannot trace to every user are skipped and reported.

### 5. Learn why the book says not to subclass and override by default

*Situation.* You want to override a network call in a subclass for a test and wonder whether that is acceptable.

```text
/output-style legacy-code:mentor
```

Ask: "Can I just subclass this class and override the call to the rate service?" The answer applies the rule, names its strength (the book restricts the technique to cases where safer composition seams are not available), shows the cost (a cleanup obligation and a narrow override point) and ends with one check question. For the rule on its own:

```text
/legacy-code:explain-rule subclass and override method
```

You get the strength, the reason, a check you can run on real code, an original example and the book's own exceptions. `/legacy-code:last-resort-seams` holds the full rule set for these seams.

### 6. Understand unfamiliar code before touching it

*Situation.* You inherited `close_month` and cannot say what it does.

```text
/output-style legacy-code:explorer
```

Ask what `close_month` does. The mode produces no patch: it reads, then prints an effect sketch with unconfirmed lines marked, responsibilities as verb phrases, open questions, candidate test points and seams, and one next safe move such as pinning a specific case with `/legacy-code:characterize`. `/legacy-code:scratch-refactoring` covers the case where you want to restructure a copy to understand it and discard the result.

## How it maps to the book

Section names are the headings of the upstream full rule set (`skills/principles/references/full.md`). A component that cites a subsection (for example `Large Methods` or `Sprout Class`) is listed under its parent section. The generated `docs/TRACEABILITY.md` lists the components that cite each section heading directly; `docs/DESIGN.md` has the full table of every citing component, including subsections. The table below names the main components for each section.

| Upstream section | Main components |
| --- | --- |
| Purpose | `principles`, `legacy-loop`, `explain-rule`, `mentor` |
| Primary Directive | `principles`, `legacy-loop`, `plan`, `rewrite-pressure`, `characterize-first` |
| Non-Negotiable Rules | `legacy-loop`, `characterization-tests`, `seams`, `hidden-inputs`, `rewrite-pressure`, `explain-rule`, `characterize` |
| Default Workflow for Legacy Changes | `legacy-loop`, `plan`, `effect-sketch`, `lead`, `pair` |
| Testing Strategy Rules | `characterization-tests`, `focused-tests`, `characterize`, `characterization-writer` |
| Seam Rules | `seams`, `substitution-seams`, `last-resort-seams`, `find-seam`, `seam-ledger`, `seam-reviewer`, `seam-cleaner` |
| Dependency Breaking Rules | `hidden-inputs`, `hard-outputs`, `audit`, `find-seam`, `hidden-input-reviewer`, `hard-output-reviewer` |
| Test Selection and Understanding Rules | `test-points`, `scratch-refactoring`, `effect-sketch`, `test-level-reviewer`, `explorer` |
| Preferred Legacy Techniques | `sprout-and-wrap`, `last-resort-seams`, `sprouter`, `sprout-opportunity-reviewer` |
| Dependency-Breaking Technique Index | `substitution-seams`, `construction-barriers`, `static-and-global`, `last-resort-seams`, `large-methods`, `policy-vs-mechanism`, `find-seam` |
| Legacy Refactoring Heuristics | `change-separation`, `test-points`, `scratch-refactoring`, `sprout-and-wrap`, `policy-vs-mechanism`, `split-patch` |
| Handling Risky Areas | `large-methods`, `policy-vs-mechanism`, `static-and-global`, `construction-barriers`, `audit` |
| Review Rules | `review`, `change-separation`, `lead`, `protection-reviewer`, `change-intent-reviewer`, `sprout-opportunity-reviewer`, `strict-reviewer` |
| Forbidden Patterns | `rewrite-pressure`, `change-separation`, `review`, `change-intent-reviewer` |
| Code Generation Rules | `plan`, `fix`, `focused-tests`, `construction-barriers`, `sprout-and-wrap`, `rewrite-pressure` |
| Testing Rules | `focused-tests`, `policy-vs-mechanism`, `test-level-reviewer` |
| Review Checklist | `principles`, `checklist`, `final-gate`, `review`, `strict-reviewer` |
| Final Instruction | `principles`, `rewrite-pressure`, `checklist`, `final-gate`, `terse` |

The technique index is distributed by barrier rather than kept in one skill: every technique has exactly one owning skill, listed in `docs/DESIGN.md`. The same file lists the pairs of skills that could fire on one request and how their descriptions separate them.

## Works with other plugins

The upstream compatibility notes compare every pair of books. All thirteen pairings with this book are rated complementary, with one recurring tension: refactoring and design pressure must wait until characterization or a safe seam exists in weakly tested code. The ones that matter most here:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `refactoring` | Complementary (conflict 10%, overlap 58%) | The highest overlap of the set. This plugin creates observation and seams; the refactoring plugin then governs the behavior-preserving structural move. Prefer this plugin when tests are weak or behavior is unclear; prefer `refactoring` once control exists. |
| `refactoring-guru` | Complementary (conflict 10%, overlap 58%) | Same relationship: smell diagnosis and smallest treatment come after characterization or a safe seam. Use it for treatment choice inside the area this plugin has made safe. |
| `clean-code` | Complementary (conflict 12%, overlap 38%) | One rule set controls safe change sequencing, the other defines the target shape of the code. Characterize and seam first, then apply readability rules inside the controlled area. The tension is scope creep: cleanup must not override characterization. |
| `clean-architecture` | Complementary (conflict 12%, overlap 38%) | Dependency direction and replaceable details are the target; this plugin is how to get there from untested code in small steps. Do not introduce large architecture before basic seams exist. |
| `release-it` | Complementary (conflict 12%, overlap 38%) | Production failure behavior (timeouts, isolation, observability) is the target for the code you have just made testable. Apply it inside the controlled change area. |

The remaining books (`ddd`, `ddd-distilled`, `ddd-implementing`, `enterprise-patterns`, `data-intensive-apps`, `philosophy-of-design`, `code-complete`, `pragmatic-programmer`) are rated complementary at the same 12% conflict and 38% overlap: use them when their trigger is actually present, after control exists.

**Recommended pairing.** In a repository where most of the work is on weakly tested code, keep this plugin as the primary rule set (turn `inject_rules` on) and add `refactoring` on demand for the behavior-preserving structural steps once the pins exist. In a well-tested repository, keep another plugin primary and bring this one in per task for the areas without protection. **Avoid loading together** `refactoring` and `refactoring-guru` with this plugin at equal weight and `inject_rules` on in all of them: the overlap is about 58 percent and their sequencing rules compete. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **No measured benefit.** The upstream project's own criticism notes say there are no benchmarks, before-and-after comparisons, defect counts or review-effort data showing that rule files improve agent output. Treat this plugin as structured guidance, not proven quality.
- **Context cost.** Loading many rules costs tokens and can crowd out task context. This plugin keeps the always-on form to the compact `nano.md` (off by default), loads the longer rules on demand and caps the number of skills that Claude can load by itself. Loading several book plugins at once defeats that.
- **The model may ignore rules, and may comply on the surface.** A change can look disciplined (a seam, a test, a Why block) while missing the real task. Reviewers and the gate check evidence, but they read code and diffs; they do not run your tests, measure coverage or know your users. Whether a test is "trusted" is a judgment the reviewers make from what they can read.
- **Book-derived, not incident-derived.** The rules come from a book and its compression, not from your repository's failures. Add your own project rules for the mistakes your agent actually makes.
- **Possible overengineering.** Applying a heavy loop to a one-line change in well-tested code is overhead. The skills say when the loop can be shortened; the user's instruction and the repository's conventions come first.
- **The source is language-agnostic and compressed.** It names about fifteen dependency-breaking techniques and gives triggers, not mechanics. The mechanics, the language-specific cautions (virtual calls from constructors, import patches, link and preprocessing seams) and the search aids in `/legacy-code:audit` are this plugin's added judgment, drawn from general knowledge of the book, and may not match your language or build. Some seam kinds exist only in some languages.
- **Characterization records, it does not judge.** A pinned bug is still a bug. The workflows mark surprising results and ask; they cannot decide what is intended, and they cannot find consumers outside the repository that rely on ugly behavior.
- **Added-judgment heuristics are not the book.** Where this plugin gives an order of preference, a decision rule between sprout and wrap, or a conservative form for the first dependency break, it says so with the words "Added judgment". The source gives no numeric thresholds; any number in an example is an example.
- **Rules are not the book.** This plugin paraphrases working rules and does not reproduce the text. Read the book for the reasoning, the worked examples and the complete catalog of techniques.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed *Working Effectively with Legacy Code* rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Working Effectively with Legacy Code* is by Michael Feathers. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
