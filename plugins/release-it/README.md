# Release It!

A rule set derived from Michael T. Nygard's *Release It!*, turned into a Claude Code toolkit (unofficial). It makes Claude put an explicit limit on every wait, repeat a failed call only when that is safe, keep one failing dependency from taking the service down, say no to work it cannot finish, ship changes in steps that can be undone, and leave enough signals behind that someone can diagnose the result at night.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), eight usage walkthroughs with exact commands, a map from the rule set's sections to the components, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *Release It!* is about the distance between software that passes its tests and software that survives production. Production brings slow dependencies rather than clean outages, bursts of load, callers that retry at the worst moment, bad data, hostile traffic, deployments that stop halfway and operators who need to see what the system is doing. The book's answer is a way of designing in which every integration point is assumed to fail, failures are kept from spreading, overload is met with a decision instead of a collapse, and the system is built so that people can deploy it, watch it and fix it. This plugin works from a compact rule set derived from that thinking; it paraphrases the ideas as working rules and does not reproduce the book.

**Who this is for.** Developers and operators using Claude Code on services, APIs, workers, queues, scheduled jobs, deployment scripts and admin tooling, in any mainstream language. The rules are about boundaries, so the plugin pays off whenever a change crosses a process boundary, holds a scarce resource, buffers work, or changes how software is shipped and run. It also fits reviews of incidents and launch decisions.

**The bias it corrects.** An agent writes the call, sees the test pass, and stops. The HTTP client keeps the library's wait, retries pile up at three layers, the queue has no ceiling, the health endpoint returns 200 without looking at anything, the deploy script has to start over after a partial failure, and the only diagnostic is a stack trace. This toolkit asks for the opposite habit: assume every dependency can be slow, unavailable or wrong, every queue can fill, every cache can miss at once, every timeout can cascade, every caller can retry badly, and every temporary degraded state can last for hours, then design the failure behavior before production does.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/release-it:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- One skill per failure domain, written as decisions rather than slogans: timeouts, retries, circuit breakers, bulkheads, stability patterns, back pressure, queues, resource budgets, data boundaries, logging, metrics, startup and health, release risk, restartable automation, operational controls, API contracts, caching, scheduled work and resilience testing. Each rule is tagged with its strength in the source (`[MUST]`, `[SHOULD]`, `[MUST NOT]`), and anything this plugin adds is tagged `[Added judgment]`, so you can always tell the book's rules from the plugin's heuristics.
- Workflows that follow what the book teaches: `failure-mode-scan`, `call-chain-budget`, `incident-review`, `game-day-plan` and `launch-check`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (a timeout ledger, a retry policy table, a shared-fate map, a demand-path ledger, and so on), four implementers that make small test-backed changes, a mechanical `hazard-scanner`, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `failure-first` and `operator`.

**When not to use it.** Reach for a different book when the real risk lies elsewhere: local readability and function shape (a Clean Code plugin), dependency direction between layers (a Clean Architecture plugin), consistency, replication and schema-evolution semantics (a data-systems plugin), or reshaping untested legacy code (a legacy-code plugin). For pure in-process logic with no boundary, no shared resource and no deployment effect, these defenses are cost without benefit, and the toolkit says so rather than adding them.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install release-it@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/release-it
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall release-it@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**58 components:** 31 skills (20 Claude can load on its own, 11 you run by name), 21 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/release-it:api-contracts` | Use when designing or changing an API, event schema or integration contract: error responses, retryable versus non-retryable outcomes, call granularity, versioning, and documented timeout and retry expectations.… |
| `/release-it:back-pressure` | Use when an endpoint, consumer or job accepts work and nothing says what happens at overload, or when adding rate limits, concurrency caps, rejection, load shedding or reserved capacity, or limiting abusive or… |
| `/release-it:bulkheads` | Use when workloads or dependencies share a thread pool, connection pool or worker capacity, when one slow integration could starve the rest, or when mapping single points of failure and fan-out. Partitions capacity in… |
| `/release-it:caching` | Use when adding or changing a cache, memoization, CDN rule or read-through store, or when a cache miss, expiry or outage would send load to the source of truth. Covers miss storms, stale data, outage behavior… |
| `/release-it:circuit-breakers` | Use when a dependency can fail slowly or for long and callers keep hammering it, when adding a breaker, fast-fail path, fallback or degraded mode, or when a fallback is silent. Reacts to observed dependency health… |
| `/release-it:data-boundaries` | Use when code accepts external input or reads a dependency's response (bodies, messages, files) and decides what to trust. Covers status, shape and plausibility checks, parse versus domain errors, validating before… |
| `/release-it:logging` | Use when adding or reviewing log statements, catch blocks, error handlers or retry loops, or when an incident left no usable trail. Covers structured context, correlation identifiers, failure logging, secrets, log spam… |
| `/release-it:metrics` | Use when adding instrumentation, dashboards or alerts, or when a failure would be invisible: the minimum signal set of request rate, success and failure counts, dependency latency, timeouts, queue depth, retries… |
| `/release-it:operational-controls` | Use when adding or changing an admin endpoint, control plane, kill switch or the access, audit and stop controls of delivery tooling that can affect production, or reviewing secrets and admin access. Rerun safety is… |
| `/release-it:principles` | Applies the Release It! production-survival rules to services, APIs, jobs, queues, deployment paths and control tooling. Use for any task that adds or changes code crossing a process boundary, holding a scarce… |
| `/release-it:queues` | Use when adding or reviewing a queue, buffer, channel, consumer, work list or dead-letter setup, or when producers can outpace consumers. Covers bounds, full behavior, depth and age monitoring, parking failing… |
| `/release-it:release-risk` | Use when planning how a change reaches production: rollout steps, exposure, rollback, version coexistence, config changes, or treating passing QA as proof of readiness. Resumable scripts are `restartable-automation`… |
| `/release-it:resilience-testing` | Use when writing or reviewing automated tests for failure behavior: timeouts, retries and backoff, degraded dependencies, overload and queue saturation, restartable scripts, startup and health failures. Tests that… |
| `/release-it:resource-budgets` | Use when code takes threads, database connections, sockets, file descriptors, memory or CPU worker slots, holds a lock or connection across a slow call, or loads or returns large collections. Covers budgets, release… |
| `/release-it:restartable-automation` | Use when writing or reviewing deployment scripts, migrations, one-time jobs or runbooks that touch many machines or may be rerun after partial failure. Covers idempotent steps, durable checkpoints, resuming. Rollout… |
| `/release-it:retries` | Use when code repeats a failed call, redelivers a message, or sits behind a client or gateway with automatic retries. Covers eligibility, bounded attempts and time, backoff with jitter, permanent failures, retries… |
| `/release-it:scheduled-work` | Use when adding or reviewing cron jobs, periodic tasks, timers, batch runs or long-running background work. Covers spreading start times, failure and retry policy, backoff, bounded runtime, progress, cancellation.… |
| `/release-it:stability-patterns` | Use when choosing a stability pattern by failure mode: steady state (no manual cleanup), fail fast on a request-time precondition or scarce resource, let it crash, decoupling middleware, or a governor. Startup and… |
| `/release-it:startup-and-health` | Use when a process starts, reads configuration, exposes health or readiness endpoints, registers with a load balancer, or does heavy work at boot. Covers fail-fast startup, truthful health, handshaking. Rerunnable… |
| `/release-it:timeouts` | Use when code makes an outbound call or waits on something outside the process (HTTP, RPC, database, queue, lock, future) and you must decide how long one attempt may take. Covers explicit limits, per-dependency… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/release-it:audit` | Scan a directory or repository for production-survival hot spots in a forked context, rate each failure domain, and return the top five with their owning skills in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/release-it:call-chain-budget` | Compute worst-case time and attempt multiplication along a request path: per-layer time limits, retries and who owns them, mismatched deadlines and nested retries. Produces a table and a proposed single retry owner. | `[entry point, route or job \| empty to ask]` |
| `/release-it:checklist` | Walk the Release It! final checklist against your current change, with yes, no or not-applicable and evidence for each, and a next action for every no. | `[paths \| empty for the current diff]` |
| `/release-it:explain-rule` | Explain one Release It! rule: its strength (must, should, must not), the failure it prevents, how to check it, an original example and the exceptions the source gives. | `[rule name \| section \| situation you are unsure about]` |
| `/release-it:failure-mode-scan` | Walk one flow's boundaries through the source's six stability assumptions in a forked context and return a table of what happens when each is slow, down or wrong, the gaps and the owning skills, in at most 40 lines. | `[flow, endpoint, job or path \| empty for the flows touched by the current diff]` |
| `/release-it:fix` | Resolve given Release It! findings with the smallest change per finding, run the tests after each, and report. Flags every number chosen without a source. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/release-it:game-day-plan` | Plan a chaos experiment, disaster drill or game day: hypothesis, steady-state signals, blast radius, stop condition, recovery path and feedback into design. Produces a plan for humans to run. Never injects faults. | `[system or flow and the failure to rehearse \| hypothesis \| empty to ask]` |
| `/release-it:incident-review` | Turn an incident, outage or capacity problem into a failure chain, missing defenses, detection gaps and ranked design changes, using only the evidence provided. Not a blame exercise. | `[incident description \| path to postmortem, log or metrics export \| empty to ask]` |
| `/release-it:launch-check` | Go or no-go for putting a service into production, in a forked context: look for evidence of rollback, startup validation, health, limits, signals, security and rehearsal, and return a verdict with the missing items in… | `[service directory \| empty for the repository root]` |
| `/release-it:plan` | Plan a change that crosses a boundary before editing: failure semantics per boundary, limits, rollout and rollback, signals and tests. Produces a plan only; edits nothing. | `[change description \| empty to plan the current diff's follow-up]` |
| `/release-it:review` | Review a diff or paths against the Release It! rules, domain by domain, and report ranked findings with the owning skill for each. | `[paths \| git ref \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-release-it:automation-hardener` | sonnet | can edit files | Implementer that makes deployment scripts, migrations and one-time jobs restartable: already-done probes, atomic checkpoints, halt on first failure and an opt-in dry-run flag. Use when review… |
| `@agent-release-it:cache-reviewer` | sonnet | read-only | Reviewer of cache behavior under failure: cold starts, miss storms, stale data, cache outages, dogpiles and correctness hidden in cache freshness. Use proactively after edits that add or change a… |
| `@agent-release-it:call-hardener` | sonnet | can edit files | Implementer that gives named outbound call sites explicit time limits, a single safe and bounded retry owner, and response checks, in small test-backed steps. Use when review findings call for… |
| `@agent-release-it:contract-reviewer` | sonnet | read-only | Reviewer of API and integration contracts: declared failure modes, retryable versus non-retryable outcomes, call granularity, versioning and documented timeout and retry expectations. Use… |
| `@agent-release-it:control-plane-reviewer` | sonnet | read-only | Reviewer of administrative controls and delivery tooling: authorization, audit, safe defaults, stop mechanisms, secrets and permissions. Use proactively after edits to admin endpoints, control… |
| `@agent-release-it:data-boundary-reviewer` | sonnet | read-only | Reviewer of input and response validation: status, content type, shape and plausibility checks, parse versus domain errors, and bad data reaching caches, queues or downstream systems. Use… |
| `@agent-release-it:deployment-reviewer` | sonnet | read-only | Reviewer of how a change ships: rollout stages, rollback or roll-forward, version coexistence, configuration changes, deployment scripts, migrations and one-time jobs. Use proactively after edits to… |
| `@agent-release-it:final-gate` | sonnet | read-only | Pre-merge gate that runs the Release It! final checklist against the working diff and returns PASS or FAIL with evidence per item. Use before declaring work done, committing, or opening a pull… |
| `@agent-release-it:hazard-scanner` | haiku | read-only | Mechanical scanner that counts hazard patterns (calls with no visible time limit, unbounded queues, swallowed errors, whole-collection loads, constant-green health, clock-boundary schedules) with… |
| `@agent-release-it:isolation-reviewer` | sonnet | read-only | Reviewer of failure isolation: circuit breakers, fast failure, fallbacks, shared pools, fan-out and single points of failure. Use proactively after edits that add dependencies, executors, connection… |
| `@agent-release-it:lead` | opus | read-only | Triage lead for Release It! work. Use first on any non-trivial change, incident or readiness question to decide which specialists, skills and workflows apply, in what order (at most five steps).… |
| `@agent-release-it:observability-reviewer` | sonnet | read-only | Reviewer of diagnosability: structured failure logs, correlation identifiers, secrets in logs, swallowed errors and the minimum metric set at each failure point. Use proactively after edits that add… |
| `@agent-release-it:overload-hardener` | sonnet | can edit files | Implementer that adds bounds and overload behavior in small, test-backed steps: queue and buffer capacities, rejection with retry hints at entry points, dead-letter handling, pool bounds and request… |
| `@agent-release-it:overload-reviewer` | sonnet | read-only | Reviewer of overload handling from the door to the consumer: entry-point limits, rejection, shedding, reserved capacity, queue bounds, age monitoring and dead letters. Use proactively after edits… |
| `@agent-release-it:resilience-test-reviewer` | sonnet | read-only | Reviewer of failure-behavior tests: which defenses have no test proving them, and which tests would still pass if the defense were removed. Use proactively after edits that add timeouts, retries… |
| `@agent-release-it:resilience-test-writer` | sonnet | can edit files | Implementer that writes tests for failure behavior: stalled peers, retry attempt bounds, degraded dependencies, queue saturation, interrupted scripts and startup failures. Writes tests only and… |
| `@agent-release-it:resource-reviewer` | sonnet | read-only | Reviewer of scarce-resource budgets: threads, connections, sockets, descriptors, memory, release paths, locks held across slow calls and unbounded payloads. Use proactively after edits that acquire… |
| `@agent-release-it:retry-reviewer` | sonnet | read-only | Reviewer of retry policy: eligibility, attempt and time bounds, backoff and jitter, permanent failures, and retries stacked across layers. Use proactively after edits that add retry loops, retry… |
| `@agent-release-it:schedule-reviewer` | sonnet | read-only | Reviewer of scheduled and background work: start-time concentration, failure and retry policy, backoff, overlap, maximum runtime, progress and cancellation. Use proactively after edits that add cron… |
| `@agent-release-it:startup-reviewer` | sonnet | read-only | Reviewer of the process lifecycle: startup validation, health and readiness meaning, handshaking, boot-time work and routing freshness. Use proactively after edits to main, bootstrap, configuration… |
| `@agent-release-it:timeout-reviewer` | sonnet | read-only | Reviewer of time limits on outbound calls and waits. Use proactively after edits that add or change HTTP, RPC, database, cache or broker clients, blocking waits, pool checkouts or lock acquisition. |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style release-it:failure-first` | Before any design or edit, prints a failure ledger for each boundary the task touches (slow, down, wrong, what protects it, the gap), tags each edit with a ledger row, and lists the failure modes left open. |
| `/output-style release-it:mentor` | Teaches the Release It! rule behind each production-survival decision, says how strong the rule is, and checks understanding with one question. |
| `/output-style release-it:operator` | Ends each non-trivial change with an operations note addressed to whoever runs the system: what to watch, how to stop it, how to undo it, and what users see when it degrades. |
| `/output-style release-it:pair` | Works in small narrated steps, asks before any change larger than a few lines, before touching a public API, and before choosing any timeout, limit or retry value. |
| `/output-style release-it:strict-reviewer` | Answers as a ranked findings table against the Release It! rules, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style release-it:terse` | Result first, no preamble, a few lines at most, still shows failing output in full and still flags numbers chosen without a source. |

<!-- COMPONENTS:END -->

**How the pieces fit.** The `lead` agent reads a task or diff and names at most five steps. The topical skills hold the rules for one failure domain each and load themselves by description. The specialist reviewers apply one domain's rules to a diff and report in their own format. The implementers (`call-hardener`, `overload-hardener`, `automation-hardener`, `resilience-test-writer`) make the changes the reviewers asked for, one small step at a time, and report what they left alone. The workflows answer questions that span domains: a single flow (`failure-mode-scan`), a request path (`call-chain-budget`), an incident (`incident-review`), a rehearsal (`game-day-plan`) or a release (`launch-check`). The `final-gate` agent closes the loop with PASS or FAIL. Reviewers and auditors never edit; implementers edit only the scope they were given and never commit.

## Usage walkthroughs

### 1. Review the work in progress

You added a client for a rates service and a retry in the order handler, and want a second opinion before you stage anything.

```text
/release-it:review
```

With no argument it runs `git status` and `git diff`, works out which failure domains the change touches (outbound calls, queues, startup, contracts and so on), runs a baseline sweep for the ten things the source says to look for, applies the matching skills, and prints ranked findings with `file:line`, the rule by name, the consequence and the smallest fix. Numbers it proposes are marked "needs confirmation". On a large diff it delegates a domain to the matching reviewer agent. It ends with the next step, usually:

```text
/release-it:fix last review
```

`fix` resolves the findings one at a time in severity order, runs the project's tests first and after each change, states what callers will now see when a new limit fires, lists every number chosen without a source under "Needs confirmation", and does not commit. When you think you are done:

```text
/release-it:checklist
```

This walks the twelve checklist items (the source's ten plus two from the compact checklist) with yes, no or n/a, evidence and a next action for every no. For a strict, isolated verdict ask for `Use the release-it:final-gate agent on my working diff`; it returns PASS or FAIL with evidence per item.

### 2. Find out how a request path behaves under failure

An order request passes a gateway, the orders service and an inventory client, and each of them has "a few retries".

```text
/release-it:call-chain-budget POST /orders
```

The skill traces the chain, records each layer's per-attempt limit, attempts and who performs the retry, and does the arithmetic. A result looks like this:

```text
Layer              Retries by      Attempts  Per-attempt limit  Worst case (no backoff)
edge gateway       gateway         2         3.0 s              6.0 s
orders service     app code        3         1.0 s              3.0 s
inventory client   sdk default     3         0.5 s              1.5 s
Attempts reaching inventory from one request, worst case: 2 x 3 x 3 = 18
```

It lists the findings (nested retries, an inner worst case longer than the outer per-attempt limit, two adjacent limits that expire together), proposes one retry owner, and recomputes (1 x 2 x 1 = 2 attempts) with every proposed number flagged "needs confirmation". Its next step is to apply the proposal:

```text
Use the release-it:call-hardener agent to apply the call-chain-budget proposal for POST /orders
```

`call-hardener` records a test baseline, changes one call site at a time, takes numbers from your configuration or marks them for confirmation, and ends with a list of behaviors that need tests. Hand that list on:

```text
Use the release-it:resilience-test-writer agent to cover the tests call-hardener listed
```

The writer edits test files only, builds a stalled peer or a counting fake, and reports honestly when a test fails because a defense is still missing.

### 3. Walk the failure modes of a flow you inherited

```text
/release-it:failure-mode-scan POST /orders
```

This runs in a fork and returns at most 40 lines. For each boundary on the flow it records, with evidence, what happens when the dependency is slow, down or wrong, which queue can fill, what a cold cache does to the source, whether timeouts cascade, whether callers retry badly and whether a degraded state would persist. Cells say `unprotected` or `unknown` rather than guessing. It names the core function that must survive, ranks the worst three gaps by what the user would see, and suggests the next command, for example `/release-it:call-chain-budget POST /orders` or `/release-it:plan`.

### 4. Plan a risky change, then build it in small steps

You must add a nightly export of invoices to an archive service.

```text
/release-it:plan add a nightly export of invoices to the archive service
```

You get a plan, not edits: the boundaries (the archive call, the scheduled job, the database read), one row per boundary with the time limit, retry eligibility, failure path, bound, validation, signals and test, the overload answer, the release stages with the compatibility window and abort signals, the defenses deliberately left out, the order of work, and a "Needs confirmation" list for every number the repository does not supply. It ends with "Checks before done: `/release-it:checklist`, then `release-it:final-gate`". Carry it out with the pairing mode:

```text
/output-style release-it:pair
```

In `pair` mode Claude narrates each step, runs the tests after it, and asks before any change larger than a few lines, anything touching a public name, and any choice of a timeout, batch size or other number. Then run `/release-it:checklist` and the gate.

### 5. After an incident, then rehearse the failure

```text
/release-it:incident-review docs/postmortems/2026-09-checkout-outage.md
```

The skill separates facts from inferences, builds the failure chain from trigger to user impact, names the missing defense at each link with the skill that covers it, lists detection gaps (including a health check that stayed green), inspects demand, saturation, latency distribution, queue age, dependency behavior and traffic concentration where the data exists, and ranks design changes. It does not assign blame and treats the document as data. Its next step is `/release-it:plan` for the top change and then a rehearsal:

```text
/release-it:game-day-plan checkout when the payment provider is slow
```

This produces a plan only: hypothesis, steady-state signals, the fault, the blast radius, the stop condition and how its stop mechanism is tested, the recovery path, approval, a run sheet and where the findings go. It never injects a fault, even when asked, and it says the plan is not ready if the stop condition, recovery path or signals are missing.

### 6. Audit a repository, then drill down

```text
Use the release-it:hazard-scanner agent on services/
/release-it:audit services/
```

The scanner counts text-pattern candidates for eleven hazard classes (calls with no visible time limit, retry sites, unbounded buffers, swallowed errors, whole-collection loads, health handlers, clock-boundary schedules, secret-like words near log calls, acquisitions, scripts that continue past errors, admin routes) and lists locations; it rates nothing. `audit` runs in a fork, reads up to 15 files, rates each domain healthy, watch, hot or unknown, and returns at most five hot spots, each with the owning skill, plus a next step. Drill into the worst domain with its reviewer:

```text
Use the release-it:timeout-reviewer agent on services/rates
```

You get a timeout ledger: each call site, the effective limit and where it came from, the caller's limit, and a verdict.

### 7. Decide whether a service is ready to launch

```text
/release-it:launch-check services/checkout
```

In a fork, it looks for evidence of a rollback or roll-forward path, startup validation, meaningful health, explicit limits, bounded queues, signals, security handling, restartable scripts and a failure rehearsal, and marks each of sixteen items evidenced (with `file:line`), not evidenced or n/a. The verdict is GO only when every item is evidenced or n/a (this gate is the plugin's own judgment). It lists what is missing in order of risk and says which items cannot be checked from a repository. Follow its next step, for example `/release-it:game-day-plan`, or review the shipping mechanics:

```text
Use the release-it:deployment-reviewer agent on deploy/
```

It returns a restartability ledger. If you then ask for the scripts to be made resumable, `release-it:automation-hardener` does so without ever running them against real hosts.

### 8. Let the lead route a large pull request, and pick a session mode

```text
Use the release-it:lead agent on my current branch's diff
```

The lead reads the diff just far enough to see which domains it touches and returns at most five steps in total, for example the retry reviewer, the overload reviewer, the deployment reviewer and the final gate, with a one-line reason each and a list of what it skipped. It proposes an implementer only if you asked for changes. For the rest of a session you can change behavior with one of the modes:

```text
/output-style release-it:failure-first
```

`failure-first` prints a failure ledger for the boundaries the task touches before the first edit and tags each edit with its ledger row; `operator` ends each non-trivial change with an ops note (what to watch, how to stop, how to undo, what users see); `mentor` explains the rule behind each choice; `strict-reviewer` answers as a ranked findings table; `terse` leads with the result; `pair` works in small steps.

## How it maps to the book

The upstream rule set has 22 sections. The validator fails the build if any section has no component applying it. Section names below are those of the vendored `full.md`; the book's text is not reproduced.

| Upstream section | Components |
| --- | --- |
| Purpose | `principles`, `explain-rule`, `lead`, `mentor` |
| Primary Directive | `principles`, `plan`, `failure-mode-scan`, `explain-rule`, `circuit-breakers`, `stability-patterns`, `lead`, `failure-first`, `terse` |
| Stability Mindset Rules | `principles`, `failure-mode-scan`, `circuit-breakers`, `timeouts`, `timeout-reviewer`, `failure-first`, `mentor` |
| Production Readiness and Release Risk Rules | `release-risk`, `startup-and-health`, `launch-check`, `plan`, `logging`, `metrics`, `deployment-reviewer`, `pair`, `operator` |
| Dependency Protection Rules | `timeouts`, `retries`, `circuit-breakers`, `bulkheads`, `call-chain-budget` and their reviewers |
| Load and Capacity Rules | `back-pressure`, `queues`, `stability-patterns`, `overload-reviewer`, `overload-hardener` |
| Runtime State and Restart Safety Rules | `restartable-automation`, `release-risk`, `data-boundaries`, `automation-hardener`, `data-boundary-reviewer` |
| Resource Management Rules | `resource-budgets`, `resource-reviewer`, `overload-hardener` |
| Data Boundary Rules | `data-boundaries`, `operational-controls`, `data-boundary-reviewer` |
| Operational Visibility Rules | `logging`, `metrics`, `startup-and-health`, `observability-reviewer`, `operator` |
| Incidents, Capacity, and Runtime Control | `incident-review`, `operational-controls`, `restartable-automation`, `metrics`, `control-plane-reviewer`, `operator` |
| Deployment and Startup Rules | `startup-and-health`, `restartable-automation`, `launch-check`, `startup-reviewer`, `automation-hardener` |
| Interconnect, Routing, Security, and Chaos Rules | `game-day-plan`, `bulkheads`, `back-pressure`, `startup-and-health`, `operational-controls`, `resilience-testing`, `launch-check`, `control-plane-reviewer` |
| API and Contract Rules | `api-contracts`, `contract-reviewer` |
| Cache Rules | `caching`, `cache-reviewer` |
| Scheduled and Background Work Rules | `scheduled-work`, `schedule-reviewer` |
| Review Rules | `review`, `audit`, `hazard-scanner`, `strict-reviewer` |
| Forbidden Patterns | `review`, `audit`, `hazard-scanner`, plus the anti-pattern tables of the domain skills |
| Code Generation Rules | `plan`, `fix`, `principles`, `call-hardener`, `pair`, and the defaults in each domain skill |
| Testing Rules | `resilience-testing`, `resilience-test-reviewer`, `resilience-test-writer`, `fix` |
| Review Checklist | `checklist`, `final-gate`, `principles`, `review`, `lead`, `strict-reviewer` |
| Final Instruction | `principles`, `final-gate` |

Rule provenance is marked inside the skills. `[MUST]`, `[SHOULD]` and `[MUST NOT]` follow the source's wording and keep its qualifiers ("where practical", "when appropriate", "where failure isolation matters"). `[Compact checklist]` marks phrasing that exists only in the shorter `mini.md`. `[Added judgment]` marks this plugin's own heuristics and every number: the source gives no timeout values, retry counts, pool sizes or thresholds, so any number in an example is an illustration and any number a component proposes is flagged "needs confirmation".

## Works with other plugins

All of the pairs below are rated complementary in the upstream compatibility notes, which are qualitative and based on the compact rule sets, not on measured task runs. The notes name a tension for each kind of partner. For design-oriented books it is mechanism cost: reliability patterns add complexity, so apply them where a real production failure mode exists and not to simple local code. For change-sequencing books (`refactoring`, `legacy-code`) it is scope creep: design improvements must not override behavior preservation. For the data-systems book it is operational patterns masking data-contract problems.

| Plugin | Verdict and overlap | How to combine |
| --- | --- | --- |
| `data-intensive-apps` | Complementary; conflict 28%, overlap 46%, complementarity 80% | The closest partner. That book owns data semantics (source of truth, consistency, ordering, idempotency, replay, schema evolution, replication); this one owns production failure behavior (timeouts, retries, isolation, overload, deployment, observability). They overlap around retries, queues, events and boundaries. Release It! patterns can mask data-contract problems if applied without the data rules, so load both for services whose correctness and survival both matter. |
| `clean-architecture` | Complementary; conflict 12%, overlap 34% | Clean Architecture keeps policy independent of frameworks and vendors; this plugin adds timeouts, isolation and signals at the adapters. Preserve the layer shape and add defenses only where a boundary is crossed. |
| `refactoring` | Complementary; conflict 12%, overlap 38% | Use together when reshaping existing code toward production goals: refactoring controls the sequence and behavior preservation, this plugin defines the target. Prefer `refactoring` while observable behavior must stay unchanged; adding a timeout or a limit changes behavior and belongs in its own step. |
| `legacy-code` | Complementary; conflict 12%, overlap 38% | When tests are weak, characterize behavior and create a seam first, then apply these defenses inside the controlled area. Prefer the legacy-code rules until you have control of the change. |
| `philosophy-of-design` | Complementary; conflict 12%, overlap 34% | The notes' tension is mechanism cost: reliability patterns add complexity. Added judgment: keep each defense inside the module that owns the dependency, so interfaces stay deep and callers do not carry it. |

The same notes rate `clean-code`, `code-complete`, `ddd`, `ddd-distilled`, `ddd-implementing`, `enterprise-patterns`, `refactoring-guru` and `pragmatic-programmer` as complementary with this rule set (conflict 12% each, overlap 34% to 38%).

**Recommended pairing.** For a service with real production traffic, make this plugin the always-on rule set (`inject_rules`) for operational work and bring `data-intensive-apps` in on demand when the task touches data semantics. **What to avoid.** Do not make several book plugins always-on at once; the upstream guidance is one primary rule set and on-demand secondary ones. Do not load this plugin for purely local design or construction work, where the compatibility notes prefer the other book.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project's own criticism notes say there is still no empirical evaluation showing that such rules improve outcomes. This plugin is a structured reminder and a set of review procedures, not a proof of resilience.
- **Context cost.** Loading too many rules burns tokens and can crowd out the task. The skills keep rules in `mini.md` first, the full file on demand and the always-on hook off by default, and only 20 skills are model-invocable. Use the smallest mechanism that changes the agent's decisions.
- **The model may still ignore rules, or comply on the surface.** Reviewers and gates are designed to demand evidence (`file:line`), but a rule-shaped answer is not the same as a working defense.
- **Book-derived, not incident-derived.** The strongest rules usually come from your own outages. `/release-it:incident-review` exists to turn a real incident into design changes; this plugin does not read your postmortems on its own.
- **Overengineering risk.** A breaker, a bulkhead and a queue bound on every function is its own failure. The hub, `plan`, `review` and every implementer carry a proportionality rule, and many source rules are qualified with "where practical" or "when appropriate".
- **Static reading cannot see production.** Real latency, capacity, library defaults, network behavior and traffic shape are invisible from a repository. Reviewers write `default, unverified` when they cannot read a library's configuration, `/release-it:launch-check` lists what a repository cannot show, and the source gives no numbers, so every limit, pool size and threshold needs your data.
- **Planning, not experimenting.** `/release-it:game-day-plan` writes a plan for people to run. No component injects faults, runs load or touches a running system, and the implementers never run deployment scripts against real targets.
- **Scope.** The rule set does not cover data consistency and schema semantics, application security testing, cost, or distributed tracing as a tool. The scanner's patterns are text matches for common languages and miss custom wrappers.
- **Contested ground.** Teams disagree about breaker tuning, retry budgets, deep readiness checks and how much to rehearse failure. Where the plugin adds a heuristic it is labelled `[Added judgment]`, and your explicit instruction and your repository's conventions outrank it.

## Attribution and license

This plugin is MIT licensed (see [LICENSE](LICENSE)). It is built on the *Release It!* rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz; the three vendored files in `skills/principles/references/` are unmodified upstream copies, and [NOTICE.md](NOTICE.md) reproduces the upstream license and credits. *Release It!* is by Michael T. Nygard. This plugin is unofficial: it is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream maintainer, it does not reproduce the book's text, and it is not a substitute for reading the book.
