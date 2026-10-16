# The Pragmatic Programmer

A rule set derived from Andrew Hunt and David Thomas's *The Pragmatic Programmer*, turned into a Claude Code toolkit (unofficial). It makes Claude keep one authoritative owner for each fact, keep unrelated things independent, prove assumptions with a thin working slice before building layers, script what repeats, write assumptions into code instead of comments, debug from facts, and own the result beyond the edit, while stopping when the work is good enough for its real users.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), eight usage walkthroughs with exact commands, a map from the rule set's sections to the components, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *The Pragmatic Programmer* is about the habits that separate a developer who delivers a change from one who owns an outcome. It asks you to treat knowledge as the thing worth keeping in one place, to keep components independent so that one change touches one place, to get a thin working path running before the layers around it exist, to keep decisions reversible until evidence arrives, to learn from throwaway experiments without letting them ship, to automate what repeats, to shorten the time between a change and its feedback, to make assumptions explicit in code, to debug by finding facts instead of guessing, and to fix small decay before it becomes normal. Above all it asks you to be pragmatic rather than dogmatic: practices are justified by what they do for real users and risks, not by ritual. This plugin works from a compact rule set derived from that thinking; it paraphrases the ideas as working rules and does not reproduce the book.

**Who this is for.** Developers using Claude Code on application code, libraries, scripts and build tooling in any mainstream language, who want an engineering-judgment layer rather than a code-style layer. The rules are about decisions that cross a single edit: where a fact lives, what else must change, what to build first, what to keep, how to know it works, and what to tell people. It is a general frame, so it pairs with the more specific book plugins instead of replacing them.

**The bias it corrects.** An agent asked for a change optimizes the edit in front of it. It copies the nearest similar block because that is the quickest route to a green test, adds a call where the data happens to live, takes a request that names a solution as if it were the requirement, runs one test file and calls the work done, leaves a "temporary" workaround with no exit, and blames the framework for the shape of the result. Each choice is reasonable alone and the system pays later: the same rule lives in four places, one change needs six edits, the release has a seven-step ritual nobody has scripted, and the first end-to-end run happens last. This toolkit asks for the opposite habit: own the outcome beyond the edit.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/pragmatic-programmer:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- One skill per decision the rules govern, written as rules with a check rather than slogans: ownership, broken windows, DRY at the level of knowledge, orthogonality, shy code, tracer bullets, prototypes, reversible choices, requirements, automation, feedback loops, test portfolio, contracts, error recovery, resource discipline, shared state, code communication, debugging, and generators and domain languages. Each rule is tagged with its strength in the source (`[MUST]`, `[SHOULD]`, `[MUST NOT]`), `[Compact checklist]` marks phrasing that exists only in the shorter rule files, and `[Added judgment]` marks this plugin's own heuristics and thresholds, so you can always tell the book's rules from the plugin's.
- Workflows that follow what the book teaches: `tracer-plan`, `knowledge-map`, `manual-step-hunt`, `debug-session`, `prototype-charter` and `tidy-touched`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (a touched-fact ledger, a ripple map, a contract table, a failure map, a lifetime ledger, a state inventory, a touched-step ledger, a signal table, a behavior-to-test matrix, a commitment register, a provenance ledger, a layer map, an artifact ledger, a decay register), four implementers that make small test-backed changes, a `lead` that routes work in at most five steps and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `tracer-first` and `owner`.

**When not to use it.** Reach for a different book when the real risk lies elsewhere: local readability and function shape (a Clean Code plugin), routine-level construction detail (a Code Complete plugin), behavior-preserving restructuring (a refactoring plugin), reshaping untested code (a legacy-code plugin), dependency direction between layers (a Clean Architecture plugin), or production failure defenses such as time limits and circuit breakers (a Release It! plugin). For a one-line change, the toolkit says so and adds no ceremony; the book itself calls rituals without benefit a forbidden pattern.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install pragmatic-programmer@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/pragmatic-programmer
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. This is a good candidate for the one always-on book plugin, because its rules are general. Leave it off if you load several book plugins and prefer another as the primary: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall pragmatic-programmer@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**58 components:** 32 skills (20 Claude can load on its own, 12 you run by name), 20 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/pragmatic-programmer:automation` | Use when work depends on repeated manual steps: setup, build, test, lint, package, deploy or release rituals, README step lists, 'works on my machine' scripts, or bulk edits made by hand. Slow or flaky checks are… |
| `/pragmatic-programmer:broken-windows` | Use when touched code shows small decay (suppressed warnings, commented-out code, a skipped test, a 'temporary' hack) or a quick fix would add more. Decides what to fix now, contain or leave. How far to go and how to… |
| `/pragmatic-programmer:code-communication` | Use when writing or reviewing names, comments, docs, commit messages, scripts, tests or PR text where intent or rationale is missing, or a comment restates the code. Covers every written artifact. Reporting to the user… |
| `/pragmatic-programmer:contracts` | Use when a routine's assumptions live in comments or caller folklore, when adding assertions, preconditions, postconditions or invariants, or when impossible states return nonsense values. Defines the obligations; how… |
| `/pragmatic-programmer:debugging` | Use when a bug, failing test, intermittent failure or surprising behavior must be explained, or when code works for reasons nobody can explain. Covers reproduce, observe, isolate, explain, fix, verify. Failure design… |
| `/pragmatic-programmer:dry-knowledge` | Use when the same rule, validation, status mapping, calculation or config meaning exists in more than one place (UI, API, service, database, docs, tests), or before copying logic. Picks one owner per fact. Generated… |
| `/pragmatic-programmer:error-recovery` | Use when writing or reviewing how failures travel: where an error is detected, what context survives, whether callers can tell retryable, recoverable and permanent failures apart, and where it stops. Expectations are… |
| `/pragmatic-programmer:feedback-loops` | Use when tests or checks are slow, flaky, environment-dependent or run too late, when failures are hard to see, or before declaring work done. Covers the speed and visibility of the signal. Which tests a change needs… |
| `/pragmatic-programmer:generators-and-dsls` | Use when code is generated, scaffolded or produced by a tool or macro, when a small domain language or rules file is proposed, or when metaprogramming hides behavior. Existing copies of a rule are `dry-knowledge`… |
| `/pragmatic-programmer:orthogonality` | Use when one change forces edits in many unrelated places, two modules share a responsibility, or policy, mechanism, data, presentation, orchestration and computation are tangled. Shared mutable state is… |
| `/pragmatic-programmer:ownership` | Use when asked whether a change is good enough or finished, when a trade-off, risk or uncertainty must be reported, when a poor result is blamed on the framework or deadline, or when a ritual has no benefit. Small… |
| `/pragmatic-programmer:principles` | Applies The Pragmatic Programmer rule set to everyday engineering decisions. Use for any task that writes, reviews, changes or plans code where duplicated knowledge, coupling, feedback speed, automation, contracts or… |
| `/pragmatic-programmer:prototypes` | Use when building a throwaway experiment, spike or proof of concept, or when prototype, spike or demo code is about to be reused in production. Covers what it proves, isolation, and the discard-or-harden decision. A… |
| `/pragmatic-programmer:requirements` | Use when a request names a solution instead of a need ('add a cache', 'use a cron job'), a spec keeps growing without removing uncertainty, or the team hesitates. Covers digging for the real requirement. Delivery order… |
| `/pragmatic-programmer:resource-discipline` | Use when code acquires files, connections, locks, handles, temp state or memory, or loops over data whose size can grow. Covers release on every path and in opposite order, ownership and algorithmic growth. Failure… |
| `/pragmatic-programmer:reversible-choices` | Use when code hard-codes a vendor, database, platform, endpoint or policy that may change, or when choosing a serialization, config or file format. Covers reversibility, lock-in, plain text and versioned formats. A… |
| `/pragmatic-programmer:shared-state` | Use when state is mutable and shared (globals, singletons, caches, ambient context, thread-locals), when adding threads, async tasks or locks, or a function reads hidden context. Layering is `orthogonality`… |
| `/pragmatic-programmer:shy-code` | Use when code reaches through an object's internals (a.b().c().d()), needs calls in a fixed order (init before use), or a shared workspace is proposed. Covers Law of Demeter, temporal coupling and blackboards.… |
| `/pragmatic-programmer:test-portfolio` | Use when deciding which tests a change needs (unit, integration, error and recovery, resource exhaustion, performance), when a person found a bug and it needs a regression test, or when tests mirror internals. Speed… |
| `/pragmatic-programmer:tracer-bullets` | Use when starting a new capability, sizing or sequencing work, or when many layers are being built before anything runs end to end. Covers thin end-to-end slices, small increments and honest estimates. A throwaway… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/pragmatic-programmer:audit` | Scan a directory or repository against The Pragmatic Programmer in a forked context, rate each concern, and return the top hot spots with their owning skills in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/pragmatic-programmer:checklist` | Walk The Pragmatic Programmer review checklist against your current change, with yes, no or not-applicable and evidence for each, and a next action for every no. | `[paths \| empty for the current diff]` |
| `/pragmatic-programmer:debug-session` | Walk one defect through reproduce, observe, isolate, explain, fix and verify with an evidence record. Stops at the explanation unless a fix is requested. Fixes with a regression test and never commits. | `[symptom, failing test or error text \| add 'and fix' to also fix \| empty to ask]` |
| `/pragmatic-programmer:explain-rule` | Explain one Pragmatic Programmer rule: its strength (must, should, must not), the failure it prevents, how to check it, an original example and the exceptions the source gives. | `[rule name \| section \| situation you are unsure about]` |
| `/pragmatic-programmer:fix` | Resolve given Pragmatic Programmer findings with the smallest change per finding, run the tests after each, and report. Flags behavior changes. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/pragmatic-programmer:knowledge-map` | Inventory the system facts in a directory or repository in a forked context: every place each business rule, validation, mapping, calculation or config meaning is represented, whether the copies agree, and a proposed… | `[directory \| glob \| named fact such as 'order cancellation' \| empty for the repository root]` |
| `/pragmatic-programmer:manual-step-hunt` | Hunt for manual rituals in a forked context: step lists in docs, local commands that differ from CI, unscripted release steps and hidden environment assumptions, with the script that would replace each, in at most 40… | `[directory \| empty for the repository root]` |
| `/pragmatic-programmer:plan` | Plan a non-trivial change before editing: the real need, who owns each fact, the first slice, reversible versus committed choices, contracts, feedback, automation, cleanup budget and risks. Produces a plan only. | `[change description \| empty to plan the follow-up to the current diff]` |
| `/pragmatic-programmer:prototype-charter` | Write the charter for a prototype (question, what it proves and does not, shortcuts, isolation, stop condition, fate), or review a prototype before promotion and say what must be hardened or discarded. Plans and… | `[experiment description \| 'promote <path>' \| empty to ask]` |
| `/pragmatic-programmer:review` | Review a diff or paths against The Pragmatic Programmer rules, concern by concern, and report ranked findings with the owning skill for each. | `[paths \| git ref \| empty for the current diff]` |
| `/pragmatic-programmer:tidy-touched` | Fix the cheap decay in the code a change already touches, in separate small steps with tests after each, and write containment notes for the rest. Chooses its own targets from the diff. Never widens scope; never commits. | `[paths \| empty for the files in the current diff]` |
| `/pragmatic-programmer:tracer-plan` | Define the thinnest real end-to-end slice for a new capability: what it proves, what is real and what is trivial, the one proving command, and the increments after it, ordered by risk. Produces a plan only. | `[capability to build \| empty to ask]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-pragmatic-programmer:automation-reviewer` | sonnet | read-only | Reviewer of repeated manual work: step lists in docs, local-versus-CI drift, unscripted release steps, hand-made bulk edits and unprotected scripts. Use proactively after edits to README steps… |
| `@agent-pragmatic-programmer:automation-scripter` | sonnet | can edit files | Implementer that replaces a manual ritual with a versioned, inspectable script or build target that checks its prerequisites and defaults to safe. Use when a review or manual-step-hunt names a… |
| `@agent-pragmatic-programmer:bug-fixer` | sonnet | can edit files | Implementer that resolves one defect: reproduce with a failing test, record the explanation, make the smallest fix, verify. Use when a defect is reported or a failing test needs its cause fixed… |
| `@agent-pragmatic-programmer:communication-reviewer` | sonnet | read-only | Reviewer of written intent: names, comments, docs, commit messages, scripts and tests, and whether each carries rationale and domain meaning. Use proactively after edits that add comments, docs… |
| `@agent-pragmatic-programmer:contract-reviewer` | sonnet | read-only | Reviewer of explicit contracts: preconditions, postconditions, invariants, assertions and nonsense return values, and where each is enforced. Use proactively after edits that add or change public… |
| `@agent-pragmatic-programmer:contract-writer` | sonnet | can edit files | Implementer that encodes assumptions a routine already makes as checks, types and tests, without adding new business rules. Use when review findings name comment-only preconditions, scattered… |
| `@agent-pragmatic-programmer:coupling-reviewer` | sonnet | read-only | Reviewer of coupling: what a change forces elsewhere, overlapping responsibilities, policy and presentation mixed into logic, reach-through call chains and fixed call orders. Use proactively after… |
| `@agent-pragmatic-programmer:decay-reviewer` | sonnet | read-only | Reviewer of decay in touched code: suppressed warnings, commented-out code, skipped tests, temporary hacks without an exit; classifies each as fix, contain or leave. Use proactively after edits… |
| `@agent-pragmatic-programmer:failure-path-reviewer` | sonnet | read-only | Reviewer of how failures travel: detection point, context kept, retryable versus permanent classes, swallowed errors and containment boundaries. Use proactively after edits that add try/catch, error… |
| `@agent-pragmatic-programmer:feedback-loop-reviewer` | sonnet | read-only | Reviewer of the speed and visibility of feedback: slow, flaky or network-dependent checks in the fast path, late-only checks, skipped tests and opaque failures. Use proactively after edits to tests… |
| `@agent-pragmatic-programmer:final-gate` | sonnet | read-only | Pre-merge gate that runs The Pragmatic Programmer review checklist against the working diff and returns PASS or FAIL with evidence per item. Use before declaring work done, committing, or opening a… |
| `@agent-pragmatic-programmer:knowledge-consolidator` | sonnet | can edit files | Implementer that moves copies of one fact onto a single owner in small, test-backed steps. Use when review or a knowledge map names a duplicated rule, mapping or validation and the owner has been… |
| `@agent-pragmatic-programmer:knowledge-duplication-reviewer` | sonnet | read-only | Reviewer of duplicated knowledge: the same rule, validation, mapping, calculation or config meaning in more than one place, and whether each copy is derived, validated or independent. Use… |
| `@agent-pragmatic-programmer:lead` | opus | read-only | Triage lead for Pragmatic Programmer work. Use first on any non-trivial change or review to decide which specialists, skills and workflows apply, in what order (at most five steps). Routes only… |
| `@agent-pragmatic-programmer:provenance-reviewer` | sonnet | read-only | Reviewer of code of uncertain origin: prototype, spike, scaffold, generated and tool-derived code, and whether it was understood, hardened or silently promoted. Use proactively after edits that… |
| `@agent-pragmatic-programmer:resource-reviewer` | sonnet | read-only | Reviewer of resource lifetimes and growth: acquire and release on every path, release order, ownership hand-offs and loops whose cost grows with input size. Use proactively after edits that open… |
| `@agent-pragmatic-programmer:reversibility-reviewer` | sonnet | read-only | Reviewer of hard-to-reverse choices: vendors, databases, platforms, policies and data formats hard-coded or unversioned, with the cost to reverse. Use proactively after edits that add an SDK, a… |
| `@agent-pragmatic-programmer:shared-state-reviewer` | sonnet | read-only | Reviewer of shared mutable state: globals, singletons, caches, ambient context, locks and async tasks, with owners, guards and visible assumptions. Use proactively after edits that add module-level… |
| `@agent-pragmatic-programmer:slice-reviewer` | sonnet | read-only | Reviewer of delivery shape: whether a plan or change for a new capability has a real end-to-end path with a proving command, or is built layer by layer. Use proactively when a plan, design or pull… |
| `@agent-pragmatic-programmer:test-portfolio-reviewer` | sonnet | read-only | Reviewer of what a change protects: a matrix of changed behaviors against the kinds of test the source names, plus regression tests for person-found bugs. Use proactively after edits that change… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style pragmatic-programmer:mentor` | Teaches the Pragmatic Programmer rule behind each engineering decision, says how strong the rule is, and checks understanding with one question. |
| `/output-style pragmatic-programmer:owner` | Ends each non-trivial task with an Ownership block: decisions and trade-offs, risks, what is unverified, what is reversible, and what was left alone. |
| `/output-style pragmatic-programmer:pair` | Works in small narrated steps with a check after each, and asks before any change larger than a few lines, before touching a public API, and before choosing a quality bar. |
| `/output-style pragmatic-programmer:strict-reviewer` | Answers as a ranked findings table against The Pragmatic Programmer rules, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style pragmatic-programmer:terse` | Result first, no preamble, a few lines at most, still shows failing output in full and still states a trade-off or risk when one exists. |
| `/output-style pragmatic-programmer:tracer-first` | Before building a new capability, states the thinnest real end-to-end path and its proving command, builds and runs that first, then widens in steps ordered by risk. |

<!-- COMPONENTS:END -->

**How the pieces fit.** The `lead` agent reads a task or diff and names at most five steps. The topical skills hold the rules for one decision each and load themselves by description. The specialist reviewers apply one concern's rules to a diff and report in their own format. The implementers (`bug-fixer`, `knowledge-consolidator`, `automation-scripter`, `contract-writer`) make the changes the reviewers or workflows asked for, one small step at a time, and report what they left alone. The workflows answer questions that span concerns: a new capability (`tracer-plan`), the places a fact lives (`knowledge-map`), the rituals in a repository (`manual-step-hunt`), a defect (`debug-session`), an experiment (`prototype-charter`) and the decay in what you touched (`tidy-touched`). The `final-gate` agent closes the loop with PASS or FAIL. Reviewers and auditors never edit; implementers edit only the scope they were given, never commit, and never run release, deploy or publish steps.

## Usage walkthroughs

### 1. Review the work in progress

You changed how orders are cancelled and want a second opinion before you stage anything.

```text
/pragmatic-programmer:review
```

With no argument it runs `git status`, `git diff` and `git diff --staged`, reads the untracked files `git status` lists (a new file has no diff), works out which concerns the change touches (copied rules, module ripple, shared state, acquired resources, contracts, failure paths, hard-coded choices, manual steps, tests, written intent, decay), runs a baseline sweep for the nine things the source says to look for in a review, applies the matching skills, and prints ranked findings with `file:line`, the rule by name, the consequence and the smallest fix. On a large diff it delegates a concern to the matching reviewer agent. It ends with the next step, usually:

```text
/pragmatic-programmer:fix last review
```

`fix` resolves the findings one at a time in severity order, runs the project's tests first and after each change, starts a defect with a failing test, tells you which callers saw a behavior change when it adds a check, and does not commit. When you think you are done:

```text
/pragmatic-programmer:checklist
```

This walks twelve items (the source's eight review-checklist questions plus four from the compact checklist) with yes, no or n/a, evidence and a next action for every no. For a strict, isolated verdict ask for `Use the pragmatic-programmer:final-gate agent on my uncommitted changes`; it returns PASS or FAIL with evidence per item, marking `[x]` satisfied, `[ ]` failed or unproven and `[-]` not applicable with the reason. If everything is already committed, name the base instead (`... on the diff of this branch against main`).

### 2. Find where a rule lives, then consolidate it

The cancellation rule seems to exist in the UI, the API and a report, and support says they disagree.

```text
/pragmatic-programmer:knowledge-map order cancellation
```

This runs in a fork and returns at most 40 lines. It searches the whole repository for every representation of that fact (constants, enum names, SQL, docs, fixtures), reads them, marks each pair `agree`, `differ` or `unclear`, proposes an owner (preferring the representation that cannot be bypassed) and the relation for each copy: call, derive, generate, validate or trace. It ends with the worst three and a next step, for example:

```text
Use the pragmatic-programmer:knowledge-consolidator agent on the order-cancellation fact, with domain/order.ts as the owner
```

A subagent does not see this conversation, so the main session pastes the fact, the owner and the copies (the `file:line` list from the map) into the agent's prompt. The map marked the owner `domain/order.ts (new)`, so the agent creates that file holding only the settled rule, and says so in its report (`Owner: ... (created)`). `knowledge-consolidator` records a test baseline, compares the copies at their edges and, if they disagree and nobody has said which is right, reports the differences and stops instead of choosing for you. Once the rule is settled it creates the owner if it is new, adds a test that pins the owner, redirects one copy at a time with the tests run after each, searches docs and fixtures for the rest, and reports a `Needs a decision` line for behavior changes.

### 3. Explain an intermittent failure, then fix it

A report test fails on some runs, mostly in the evening.

```text
/pragmatic-programmer:debug-session test_report_covers_today fails on some runs, expected 2026-03-14 got 2026-03-15
```

The skill writes the symptom, finds the narrowest command and reproduces, records facts separately from theories, lists hypotheses each with the observation that would reject it, isolates the smallest failing case, and writes the cause in one sentence together with the other symptom it predicts. Because you asked only for a diagnosis, it stops there with a debug record and offers `pragmatic-programmer:bug-fixer`. To continue:

```text
Use the pragmatic-programmer:bug-fixer agent on the debug record above
```

The main session pastes the record (symptom, reproduction command, explanation) into the agent's prompt, because a subagent cannot see the conversation. The agent re-verifies the reproduction instead of trusting the record, writes a failing regression test named for the contract it protects, makes the smallest change that follows from the explanation, runs the reproduction and the neighboring tests, and reports what it ruled out. It never deletes or weakens a test, never checks out other revisions to search history (it asks you to), and never commits. Adding "and fix" to the `debug-session` arguments runs the same steps in one pass.

### 4. Plan a new capability as a thin slice, then build it that way

You must send each customer a monthly PDF report by email.

```text
/pragmatic-programmer:tracer-plan send each customer a monthly PDF report by email
```

You get a plan, not code: the outcome, the assumptions to test (riskiest first), the slice from one input to one output with what is real, what may be trivial and which boundaries are only stood in for by a fixture or a fake (so their assumptions stay unproven), the single proving command, the increments after it with done conditions and effort ranges that name their unknown, the decisions that stay provisional, and what is deliberately not in the slice. Ask for a second opinion on the shape of the plan:

```text
Use the pragmatic-programmer:slice-reviewer agent on this plan
```

The main session passes the plan text in the agent's prompt, since a subagent cannot see the plan above. It returns a layer map marking each layer real, stubbed (a fake, a mock or a recorded fixture) or absent, the proving command, the first step at which something runs end to end, and whether the riskiest assumption is tested early. Then build with the session mode that enforces the order:

```text
/output-style pragmatic-programmer:tracer-first
```

In `tracer-first` mode Claude prints the Slice block (path, real parts, stand-ins, trivial parts, proving command, riskiest assumption) before the first edit, builds only the slice, runs the proving command and reports the result, and names the next increment from what it learned. Finish with `/pragmatic-programmer:checklist`.

### 5. Decide what happens to a spike

You spent two days on a duplicate-customer matcher and someone wants it in the nightly job.

```text
/pragmatic-programmer:prototype-charter promote experiments/dedupe_spike
```

In promotion mode the skill reads the code and any header, lists the shortcuts actually present (hard-coded paths, no error handling, in-memory state, no tests), searches production paths for imports of the spike, and decides for each artifact: discard, rewrite from the lessons, or harden, with a list of what hardening needs. It states what the prototype never proved and ends with a verdict: ready, needs hardening, or do not promote. For a second view of the pull request that wires it in:

```text
Use the pragmatic-programmer:provenance-reviewer agent on my working diff
```

It returns a provenance ledger: each artifact's origin, whether production depends on it, whether anyone understood it, and its status. Before the next spike, write the charter first with `/pragmatic-programmer:prototype-charter find duplicate customers with fuzzy matching`, which records the question, what the spike proves and does not, its shortcuts, where it lives and when it ends.

### 6. Hunt manual rituals and replace one

```text
/pragmatic-programmer:manual-step-hunt
```

In a fork, it reads the README, contributing guide, docs, build files, scripts and CI definitions without running anything. It lists procedures that live in prose, compares the command contributors are told to run with the command CI runs, finds hidden environment assumptions and scripts that do not protect themselves, and returns at most 40 lines with the script that would replace each ritual. Its next step is the implementer:

```text
Use the pragmatic-programmer:automation-scripter agent on the release checklist in docs/release.md, script it in scripts/release.sh
```

The agent follows the repository's conventions, writes a script that checks its prerequisites, stops on the first failure and makes anything destructive opt-in, points the docs at it, and runs only `--help` or a dry run. It never runs a release, deploy or publish. To check the result:

```text
Use the pragmatic-programmer:automation-reviewer agent on scripts/ and docs/release.md
```

### 7. Audit a repository, then drill into the worst concern

```text
/pragmatic-programmer:audit src/
```

In a fork, it reads up to 15 files, rates knowledge, coupling, state and resources, contracts and failures, reversibility, provenance, automation and feedback, and communication and decay as healthy, watch, hot or unknown, and returns at most five hot spots, each with the owning skill, plus a next step. If coupling is hot:

```text
Use the pragmatic-programmer:coupling-reviewer agent on src/billing
```

You get a ripple map (which changed files the purpose of the change explains and which are ripple, with the missing fact or boundary) and a reach-and-order ledger of call chains and fixed call orders, each with its smallest fix.

### 8. Let the lead route a large pull request, then pick a session mode

```text
Use the pragmatic-programmer:lead agent on the diff of this branch against main
```

The agents read the working tree by default (uncommitted changes and new untracked files), so for committed work on a branch name the base, as above; on a clean tree with no base the lead asks for one. The lead reads the diff just far enough to see which concerns it touches and returns at most five steps in total, for example the knowledge-duplication reviewer, the failure-path reviewer, the test-portfolio reviewer and the final gate, with a one-line reason each and a list of what it skipped. It proposes an implementer only if you asked for changes. For the rest of a session you can change behavior with one of the modes:

```text
/output-style pragmatic-programmer:owner
```

`owner` ends each non-trivial task with an Ownership block (decided, traded away, risk, not verified, reversible, left alone); `tracer-first` states the thinnest real path before building; `mentor` explains the rule behind each choice and how strong it is; `strict-reviewer` answers as a ranked findings table; `terse` leads with the result; `pair` works in small steps and asks before larger changes. To understand a single rule at any time, for example `/pragmatic-programmer:explain-rule one authoritative representation`, which states its strength, the failure it prevents, a check and an original example.

## How it maps to the book

The upstream rule set has 26 sections. The validator fails the build if any section has no component applying it. Section names below are those of the vendored `full.md`; the book's text is not reproduced.

| Upstream section | Components |
| --- | --- |
| Purpose | `principles`, `explain-rule`, `mentor` |
| Primary Directive | `principles`, `plan`, `explain-rule`, `lead`, `mentor` |
| Core Pragmatic Principles | `principles`, and its subsections: `ownership`, `owner`, `broken-windows`, `reversible-choices` |
| DRY Rules | `dry-knowledge`, `knowledge-map`, `knowledge-duplication-reviewer`, `knowledge-consolidator`, `automation` |
| Orthogonality Rules | `orthogonality`, `shared-state`, `coupling-reviewer`, `shared-state-reviewer` |
| Tracer Bullets and Iterative Delivery | `tracer-bullets`, `tracer-plan`, `prototypes`, `prototype-charter`, `slice-reviewer`, `tracer-first`, `plan` |
| Reversibility, Domain Languages, and Requirements | `reversible-choices`, `requirements`, `generators-and-dsls`, `reversibility-reviewer` |
| Prototyping Rules | `prototypes`, `prototype-charter`, `provenance-reviewer` |
| Automation Rules | `automation`, `manual-step-hunt`, `automation-reviewer`, `automation-scripter` |
| Feedback Loop Rules | `feedback-loops`, `fix`, `debug-session`, `feedback-loop-reviewer`, `bug-fixer`, `pair` |
| Design by Contract and Assertions | `contracts`, `error-recovery`, `contract-reviewer`, `failure-path-reviewer`, `contract-writer` |
| Error Handling and Recovery | `error-recovery`, `failure-path-reviewer` |
| Naming and Communication Rules | `code-communication`, `communication-reviewer`, `terse` |
| Text and Data Rules | `reversible-choices`, `reversibility-reviewer`, `automation-scripter` |
| State and Concurrency Rules | `shared-state`, `shared-state-reviewer` |
| Estimation and Increment Rules | `tracer-bullets`, `tracer-plan`, `plan`, `slice-reviewer`, `pair`, `tracer-first` |
| Tooling Rules | `automation`, `manual-step-hunt`, `automation-reviewer`, `automation-scripter` |
| Resource and Coupling Rules | `resource-discipline`, `shy-code`, `generators-and-dsls`, `resource-reviewer`, `coupling-reviewer` |
| Project and Team Rules | `ownership`, `test-portfolio`, `code-communication`, `owner`, `test-portfolio-reviewer`, `communication-reviewer` |
| Broken Windows Rule | `broken-windows`, `tidy-touched`, `decay-reviewer` |
| Review Rules | `review`, `audit`, `knowledge-map`, `strict-reviewer`, `lead` |
| Forbidden Patterns | `review`, `audit`, `strict-reviewer`, and the per-family subsections `Cargo-Cult Process`, `Knowledge Duplication`, `Non-Orthogonal Design`, `Manual Everything`, `Prototype Fossilization` in the skills named for each |
| Code Generation Rules | `principles`, `plan`, `fix`, `tracer-plan`, `dry-knowledge`, `orthogonality`, `contracts`, `knowledge-consolidator`, `tracer-first` |
| Testing Rules | `feedback-loops`, `test-portfolio`, `fix`, `feedback-loop-reviewer`, `test-portfolio-reviewer` |
| Review Checklist | `checklist`, `final-gate`, `review`, `tidy-touched`, `principles`, `strict-reviewer`, `lead` |
| Final Instruction | `principles`, `final-gate` |

Rule provenance is marked inside the skills. `[MUST]`, `[SHOULD]` and `[MUST NOT]` follow the source's wording and keep its qualifiers ("where practical", "where relevant", "unless justified"). `[Compact checklist]` marks phrasing that exists only in the shorter `mini.md` or `nano.md`, such as the trigger to add a regression test when a person finds a bug. `[Added judgment]` marks this plugin's own heuristics and every threshold: the source gives no numbers, so any number in an example is an illustration. Debugging deserves a note: the source states the sequence (reproduce, observe, isolate, explain, fix, verify) in one line, so the techniques in `debugging` and `debug-session` beyond that sequence are all `[Added judgment]`.

## Works with other plugins

The upstream compatibility notes are qualitative and based on the compact rule sets, not on measured task runs. This rule set is a general engineering frame, so two of its closest neighbors are rated as overlap and the specific books as complementary.

| Plugin | Verdict and overlap | How to combine |
| --- | --- | --- |
| `clean-code` | Overlap; conflict 24%, overlap 68%, complementarity 54% | Choose one primary general coding rule set. Clean Code is local code shape; this book is an operating style for uncertainty, feedback, automation and ownership. The notes allow using both only when this plugin is the frame and `clean-code` is limited to local readability checks. The tension is dogma against pragmatism: this book asks you to choose the practice and the stopping point by real outcomes. |
| `code-complete` | Overlap; conflict 18%, overlap 64%, complementarity 58% | Choose one as the broad construction and engineering guide unless the task needs both Code Complete's routine-level construction detail and this plugin's uncertainty, automation and feedback checks. Prefer `code-complete` for routine design, validation, control flow and defensive programming; prefer this plugin for DRY ownership, orthogonality, automation and process. |
| `refactoring` | Complementary; conflict 12%, overlap 38%, complementarity 78% | Use together when changing existing code: `refactoring` controls the sequence and behavior preservation, this plugin defines the target (one owner per fact, independent components). Prefer `refactoring` while observable behavior must stay unchanged. The tension is scope creep: design improvement must not override behavior preservation. |
| `legacy-code` | Complementary; conflict 12%, overlap 38%, complementarity 78% | When tests are weak or behavior is unclear, characterize behavior and create the smallest seam first, then apply this plugin inside the controlled area. Prefer `legacy-code` until you have control of the change. |
| `release-it` | Complementary; conflict 12%, overlap 34%, complementarity 78% | Use together when the task has production boundaries: keep the code and model shape this plugin asks for, and add time limits, isolation and observability only where a real production failure mode triggers them. The tension is mechanism cost: reliability patterns add complexity. |

The same notes rate `philosophy-of-design` (conflict 20%, overlap 50%), `clean-architecture`, `data-intensive-apps`, `ddd`, `ddd-distilled`, `ddd-implementing`, `enterprise-patterns` and `refactoring-guru` as complementary. For the domain and data books the notes' tension is ceremony or over-modeling: load them when a domain model, an aggregate boundary or a data contract is the hard part, and let this plugin supply the stopping points.

**Recommended pairing.** Make this plugin the always-on rule set (`inject_rules`) for general work, and bring `refactoring` in on demand when you restructure existing code, with `legacy-code` first if the code has no tests. **What to avoid.** Do not make `clean-code` or `code-complete` always-on alongside this plugin; the notes call the active guidance redundant unless their roles are explicitly separated. More generally, do not make several book plugins always-on at once: the upstream guidance is one primary rule set and on-demand secondary ones.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project's own criticism notes say there is still no empirical evaluation showing that such rules improve outcomes. This plugin is a structured reminder and a set of review procedures, not proof of better software.
- **Context cost.** Loading too many rules burns tokens and can crowd out the task. The skills read `mini.md` first, the full file on demand, the always-on hook is off by default, and only 20 skills are model-invocable. Use the smallest mechanism that changes the agent's decisions.
- **The model may ignore rules, or comply on the surface.** Reviewers and gates are designed to demand evidence (`file:line`), but a rule-shaped answer is not the same as a better system. The upstream notes name this pseudo-compliance risk.
- **Book-derived, not incident-derived.** The strongest rules usually come from your own failures. The skills here are general; a short list of rules written from your own incidents may serve a project better than any book.
- **Judgment-heavy by design.** "Be pragmatic, not dogmatic" cannot be checked mechanically. A reviewer can defend a refactor or a shortcut with the same book, so the plugin makes the reasoning explicit (done-criteria, trade-offs, containment notes) and ranks your instruction and your repository's conventions above the rules.
- **Over-application.** DRY pursued as text matching merges things that change for different reasons; orthogonality pursued as layering adds files without removing ripple; reversibility pursued everywhere adds abstraction nobody needs. The skills say to judge by independent change and real volatility, and many source rules are qualified with "where practical" or "where relevant", but a user who applies the rules everywhere will over-engineer.
- **Compression loses topics.** The upstream traceability notes say the compact files drop personal-practice detail such as the knowledge portfolio, and fold individual tool examples and estimation mechanics into broader rules. Debugging is a single line in the source. Anything beyond that in this plugin is labelled `[Added judgment]` and is the plugin's opinion.
- **Static reading cannot see runtime.** Reviewers read code and configuration. They cannot measure latency, flakiness, growth at real data sizes or usability, and they say so (`unmeasured`, `untested (person)`) instead of guessing.
- **Scope.** The rule set does not cover production failure defenses, deep concurrency models, security testing or data consistency semantics. Implementers run only the project's own non-destructive checks and never release, deploy or publish.
- **Contested ground.** Teams disagree about how much duplication to tolerate, how much to automate, and whether a spike may be hardened. Where the plugin adds a heuristic it is labelled, and your explicit instruction outranks it.

## Attribution and license

This plugin is MIT licensed (see [LICENSE](LICENSE)). It is built on the rule sets for *The Pragmatic Programmer* published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz; the three vendored files in `skills/principles/references/` are unmodified upstream copies, and [NOTICE.md](NOTICE.md) reproduces the upstream license and credits. *The Pragmatic Programmer* is by Andrew Hunt and David Thomas. This plugin is unofficial: it is not affiliated with, endorsed by or approved by the book's authors, its publisher or the upstream maintainer, it does not reproduce the book's text, and it is not a substitute for reading the book.
