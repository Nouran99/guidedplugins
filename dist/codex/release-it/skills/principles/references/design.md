# Release It! plugin: component map

This file is the plan the components were built from, kept in step with what was built. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`; `###` headings are cited where a component owns exactly one subsection. A `Source` bullet with a note means only that part of the section applies.

## Design decisions

1. **The rule set is short, so the split follows failure domains, not section order.** The upstream full file has 22 `##` sections, several of them one-paragraph lists. Clusters are cut along the decisions a reader makes in code: how long to wait, whether to repeat a call, what to stop calling, what to partition, how much to accept, how to ship, how to see. Two large sections are split by situation (`Dependency Protection Rules` into four skills, `Operational Visibility Rules` into logging and metrics).
2. **The "do not" lists become anti-pattern entries with detection hints** in the skill that owns the defense. `Forbidden Patterns` is not a skill of its own, because each family (retry storms, collapse by queue, blast-radius amplification, silent failure, happy-path design) already has an owning defense; `release-it-hazard-scanner` finds the raw hits and `$release-it:review` and `$release-it:audit` route them.
3. **Model-invocable skills are capped at 20.** There are exactly 20: the hub plus 19 topical skills. Everything that is a procedure with arguments is manual (11 manual skills, 3 of them forked).
4. **Chaos, incidents and launch checks are workflows, not rule skills.** The source gives them process rules (hypothesis, blast radius, stop condition; failure chain, detection gaps) rather than code rules. They are the manual skills `$release-it:game-day-plan`, `$release-it:incident-review` and `$release-it:launch-check`. `$release-it:game-day-plan` only plans; no component injects faults.
5. **Numbers are never presented as rules of the book.** The source gives no timeout values, retry counts, pool sizes or thresholds. Any number in a component is an example, or is labelled "Added judgment", or is flagged "needs confirmation".
6. **Rule provenance is marked inline.** Every numbered rule in a topical skill carries a tag right after its statement: `[MUST]`, `[SHOULD]` or `[MUST NOT]` (the source's modal strength, including its qualifiers such as "where practical"), `[Added judgment]` (this plugin's heuristic), or `[Compact checklist]` (phrasing that exists only in `mini.md`).
7. **Proportionality is built in.** The compatibility notes name the tension: reliability mechanisms add complexity. The hub, `plan`, `review`, the reviewers' constraints and every implementer carry the scope guard: apply these rules to code that crosses a process boundary, holds a scarce resource, buffers work, or ships and operates the system; leave pure in-process logic alone.
8. **Reviewers own one failure domain and report a different artifact.** A timeout reviewer reports a ledger of call sites, a retry reviewer a policy table with an amplification factor, an isolation reviewer a shared-fate map, and so on.
9. **Implementers are separated by what they change**: outbound call sites, demand controls (entry points, queues, pools), operational automation, and tests.
10. **A change that adds a defense changes behavior, so numbers are never silently guessed.** `fix`, `plan`, the implementers and the `pair` style all route an unsourced number to "needs confirmation" or to a question.

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Stability Mindset Rules; Code Generation Rules; Review Checklist; Final Instruction | It decides which component to use; it holds no cluster rules. |
| `timeouts` | Explicit time limits on every outbound call and wait; per-dependency budgets; deadline propagation | Timeouts Are Mandatory; Dependency Protection Rules; Stability Mindset Rules; Code Generation Rules | `retries` decides whether to repeat a call; `timeouts` decides how long one attempt may take. |
| `retries` | Retry eligibility, count and time bounds, backoff and jitter, permanent failures, retries stacked across layers | Retries Must Be Disciplined; Retry Storms; Dependency Protection Rules; Code Generation Rules; Operational Visibility Rules | It starts after a call has failed; it never sets the wait limit (that is `timeouts`). |
| `$release-it:circuit-breakers` | Stop calling a clearly unhealthy dependency, fast failure, explicit fallback and degraded mode | Circuit Breakers and Fast Failure; Stability Mindset Rules; Primary Directive; Metrics | `bulkheads` partitions capacity; a breaker reacts to the observed health of one dependency. |
| `bulkheads` | Separate pools per workload, slow-work isolation, shared-fate and single-point analysis, fan-out | Bulkheads and Isolation; Blast-Radius Amplification; Dependency Protection Rules; Interconnect, Routing, Security, and Chaos Rules | A breaker stops calls; a bulkhead limits how much of a shared resource a failing workload can take. |
| `$release-it:stability-patterns` | Choose among steady state, fail fast, let it crash, decoupling middleware and governors by failure mode | Additional Stability Patterns; Primary Directive; Load and Capacity Rules | The other defense skills each own one pattern; this one owns the five that have no larger home and the choice among all. |
| `$release-it:back-pressure` | Overload strategy at entry points: reject, defer, queue or degrade; demand limits; reserved capacity; load shedding; hostile traffic as load | Back Pressure; Demand Control; Load Shedding; Load and Capacity Rules; Collapse by Queue; Interconnect, Routing, Security, and Chaos Rules | `queues` is about the buffer itself; `$release-it:back-pressure` is the policy at the door. |
| `queues` | Bounded queues, full behavior, age and depth monitoring, producers outpacing consumers, dead-letter and poison messages | Queues; Collapse by Queue; Code Generation Rules; Load and Capacity Rules | It owns the internals of a buffer; `$release-it:back-pressure` owns what the caller is told. |
| `$release-it:resource-budgets` | Budget threads, connections, sockets, descriptors, memory; deterministic release; no locks across slow calls; streaming and pagination | Resource Management Rules; Code Generation Rules | `bulkheads` divides a budget between workloads; this skill sets and enforces the budget. |
| `$release-it:data-boundaries` | Untrusted input and responses: shape, status, content type, plausibility; parse errors versus domain errors; no poisoning | Data Boundary Rules; Runtime State and Restart Safety Rules | `$release-it:api-contracts` declares what you promise; `$release-it:data-boundaries` checks what you receive. |
| `logging` | Structured context, correlation identifiers, failure logging, no secrets, no log spam, no silent failure | Logging; Observability Is Part of the Design; Silent Failure; Operational Visibility Rules; Production Readiness and Release Risk Rules | `metrics` counts and times; `logging` records the event with context. |
| `metrics` | The minimum signal set, dependency latency, saturation, queue depth, retry and breaker signals | Metrics; Observability Is Part of the Design; Operational Visibility Rules; Incidents, Capacity, and Runtime Control; Production Readiness and Release Risk Rules | It never decides what a log line says; it decides which numbers must exist. |
| `$release-it:startup-and-health` | Fail fast on missing configuration, startup work, health that reflects ability to serve, readiness, handshaking, routing and discovery freshness | Deployment and Startup Rules; Production Readiness and Release Risk Rules; Additional Stability Patterns; Interconnect, Routing, Security, and Chaos Rules; Operational Visibility Rules | `$release-it:restartable-automation` is about scripts rerun by operators; this is about a process starting and saying whether it can serve. |
| `$release-it:release-risk` | Small exposure steps, compatibility windows, reversible changes, rollback, visible version and configuration state | Production Readiness and Release Risk Rules; Runtime State and Restart Safety Rules; Restartable Automation | It plans how a change reaches production; `$release-it:api-contracts` shapes the contract being changed. |
| `$release-it:restartable-automation` | Idempotent, resumable deployment and operational scripts, migrations and one-time jobs, durable checkpoints | Restartable Automation; Runtime State and Restart Safety Rules; Deployment and Startup Rules; Incidents, Capacity, and Runtime Control; Code Generation Rules | `$release-it:operational-controls` decides who may run it and how it is stopped; this decides what happens when it is rerun or fails midway. |
| `$release-it:operational-controls` | Admin interfaces, control planes and delivery tooling: authorization, audit, safe defaults, stop mechanism; security readiness | Incidents, Capacity, and Runtime Control; Interconnect, Routing, Security, and Chaos Rules; Data Boundary Rules | It never discusses resumability; `$release-it:restartable-automation` never discusses authorization. |
| `$release-it:api-contracts` | Failure modes in the contract, retryable versus non-retryable outcomes, coarse-grained calls, versioning, documented timeout and retry expectations | API and Contract Rules | `$release-it:data-boundaries` validates inbound data; this declares the outbound promise. |
| `caching` | Cache as optimization, miss storms, stale data, outage behavior, dogpile control | Cache Rules | `$release-it:back-pressure` handles demand in general; `caching` handles the specific demand a cache absorbs and releases. |
| `$release-it:scheduled-work` | Spread periodic jobs, explicit failure and retry policy, backoff on retried work, bounded long-running jobs | Scheduled and Background Work Rules | `retries` covers retrying a call; `$release-it:scheduled-work` covers when jobs start and how a long job is bounded. |
| `$release-it:resilience-testing` | Tests that prove the defenses: timeouts, retries, degraded dependencies, saturation, restartable automation, startup and health failure | Testing Rules; Review Checklist; Interconnect, Routing, Security, and Chaos Rules | `$release-it:game-day-plan` experiments on a running system; `$release-it:resilience-testing` is the automated suite. |

## Skills: manual workflows (11)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths and report ranked findings by failure domain | Review Rules; Review Checklist; Forbidden Patterns | `audit` scans a tree; `review` judges a change. |
| `audit` | yes | no | Repository or directory scan, rating each failure domain, at most 40 lines | Review Rules; Forbidden Patterns; Happy-Path Design | `$release-it:failure-mode-scan` follows one flow; `audit` samples the whole tree. |
| `plan` | no | no | Plan a change that crosses a boundary: failure semantics, limits, rollout, signals, tests | Code Generation Rules; Primary Directive; Production Readiness and Release Risk Rules | `$release-it:launch-check` judges a finished service; `plan` precedes the change. |
| `$release-it:explain-rule` | no | no | Explain one rule: strength, reason, check, example, exceptions | Purpose; Primary Directive | The only manual skill that teaches instead of reporting findings. |
| `checklist` | no | no | Walk the final checklist with yes, no or not applicable and a next action per no | Review Checklist | `release-it-final-gate` is the isolated strict gate; `checklist` is the interactive walk. |
| `fix` | no | yes | Resolve given findings with the smallest change, run tests, never commit | Code Generation Rules; Testing Rules | The only workflow that edits on a findings list in the current session; the hardeners are delegated, isolated versions. |
| `$release-it:failure-mode-scan` | yes | no | Walk one flow's boundaries through the six stability assumptions, at most 40 lines | Stability Mindset Rules; Primary Directive | `audit` rates domains over a tree; this enumerates what happens at each boundary of one flow. |
| `$release-it:call-chain-budget` | no | no | Compute worst-case time and attempt multiplication along a request path | Retries Must Be Disciplined; Timeouts Are Mandatory; Dependency Protection Rules | `retries` and `timeouts` give rules per call site; this is arithmetic across layers. |
| `$release-it:incident-review` | no | no | Turn an incident into a failure chain, missing defenses, detection gaps and design changes | Incidents, Capacity, and Runtime Control | `$release-it:failure-mode-scan` is forward-looking; this starts from something that already failed. |
| `$release-it:game-day-plan` | no | no | Plan a fault-injection experiment or game day; never injects | Interconnect, Routing, Security, and Chaos Rules | `$release-it:resilience-testing` is automated tests in the suite; this is an experiment with a blast radius. |
| `$release-it:launch-check` | yes | no | Go or no-go for putting a service into production, with evidence per item, at most 40 lines | Production Readiness and Release Risk Rules; Deployment and Startup Rules; Interconnect, Routing, Security, and Chaos Rules | `audit` finds code hot spots; `$release-it:launch-check` asks for operational evidence (rollback, signals, capacity, security). |

## Subagents (21)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`. `release-it-hazard-scanner` is read-only and runs on `haiku`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `release-it-lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Purpose; Primary Directive; Review Checklist | Only agent that does not read code for defects. |
| `release-it-final-gate` | sonnet | Runs the final checklist against the working diff and returns PASS or FAIL | principles | Review Checklist; Final Instruction | Binary result with evidence; reviewers return ranked findings. |
| `release-it-timeout-reviewer` | sonnet | Every outbound call and wait has an intentional limit | timeouts | Timeouts Are Mandatory; Stability Mindset Rules | Output is a call-site ledger; `release-it-retry-reviewer` owns repetition. |
| `release-it-retry-reviewer` | sonnet | Retry eligibility, bounds, backoff, stacking across layers | retries | Retries Must Be Disciplined; Retry Storms | Output is a retry-policy table with an amplification factor. |
| `release-it-isolation-reviewer` | sonnet | Breakers, fallbacks, shared pools, shared fate | circuit-breakers, bulkheads | Circuit Breakers and Fast Failure; Bulkheads and Isolation; Blast-Radius Amplification | Output is a shared-fate map. |
| `release-it-overload-reviewer` | sonnet | Entry-point limits, rejection, shedding, reserved capacity, queues | back-pressure, queues | Back Pressure; Demand Control; Load Shedding; Queues; Collapse by Queue | Output is a demand-path ledger from door to consumer. |
| `release-it-resource-reviewer` | sonnet | Budgets, release paths, locks across remote calls, unbounded payloads | resource-budgets | Resource Management Rules | Output is a resource budget table. |
| `release-it-data-boundary-reviewer` | sonnet | Validation of input and responses, poisoning risk | data-boundaries | Data Boundary Rules; Runtime State and Restart Safety Rules | Output is a trust-boundary table. |
| `release-it-observability-reviewer` | sonnet | Logs, metrics, correlation, silent failure at failure points | logging, metrics | Operational Visibility Rules; Silent Failure; Observability Is Part of the Design; Logging; Metrics | Output is a signal-coverage matrix. |
| `release-it-startup-reviewer` | sonnet | Startup validation, health and readiness meaning, routing freshness | startup-and-health | Deployment and Startup Rules; Additional Stability Patterns | Output is a lifecycle table. |
| `release-it-deployment-reviewer` | sonnet | Rollout, rollback, restartable scripts, migrations | release-risk, restartable-automation | Production Readiness and Release Risk Rules; Restartable Automation | Output is a restartability ledger. |
| `release-it-contract-reviewer` | sonnet | Declared failure modes, retryable flags, versioning, chattiness | api-contracts | API and Contract Rules | Output is a contract failure table. |
| `release-it-cache-reviewer` | sonnet | Miss storms, stale data, outage behavior, dogpiles | caching | Cache Rules | Output is a cache behavior matrix. |
| `release-it-schedule-reviewer` | sonnet | Job timing collisions, retry policy, long-running bounds | scheduled-work | Scheduled and Background Work Rules | Output is a schedule table. |
| `release-it-control-plane-reviewer` | sonnet | Authorization, audit, safe defaults and stop for admin and delivery tooling | operational-controls | Incidents, Capacity, and Runtime Control; Interconnect, Routing, Security, and Chaos Rules | Output is a control inventory. |
| `release-it-resilience-test-reviewer` | sonnet | Which defenses have no test proving them | resilience-testing | Testing Rules | Output is a defense-to-test map. |
| `release-it-call-hardener` | sonnet | Implementer: explicit timeouts, safe bounded retries and response checks at named call sites | timeouts, retries | Timeouts Are Mandatory; Retries Must Be Disciplined; Code Generation Rules | Edits outbound call sites only. |
| `release-it-overload-hardener` | sonnet | Implementer: bounds queues and pools, adds rejection, shedding and dead-letter handling | back-pressure, queues | Back Pressure; Queues; Resource Management Rules | Edits demand controls; leaves call sites to `release-it-call-hardener`. |
| `release-it-automation-hardener` | sonnet | Implementer: makes scripts and migrations idempotent with durable checkpoints | restartable-automation | Restartable Automation; Runtime State and Restart Safety Rules; Deployment and Startup Rules | Edits operational scripts only; never runs them against real targets. |
| `release-it-resilience-test-writer` | sonnet | Implementer: writes tests for timeout, retry, degraded and saturation behavior; never edits production code | resilience-testing | Testing Rules | Writes tests only. |
| `release-it-hazard-scanner` | haiku | Mechanical census of hazard patterns with file and line | none (recipes are in its body) | Review Rules; Forbidden Patterns | Reports locations and counts only; no judgment, no ratings. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice and its strength, ends non-trivial answers with one check question | Purpose; Stability Mindset Rules | Teaching is the only goal. |
| `strict-reviewer` | Ranked findings table, no rewrites unless asked, explicit `No findings` | Review Rules; Review Checklist | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines, touching public API, or choosing a number | Code Generation Rules; Production Readiness and Release Risk Rules | Interaction rhythm. |
| `terse` | Result first, few lines, failing output in full | Primary Directive | Brevity rules. |
| `failure-first` | Before any design or edit, prints a failure ledger for each boundary touched | Stability Mindset Rules; Primary Directive; Happy-Path Design | The ledger precedes every change. |
| `operator` | Ends each non-trivial change with an operations note: signals to watch, stop switch, rollback or roll-forward path | Operational Visibility Rules; Incidents, Capacity, and Runtime Control; Production Readiness and Release Risk Rules | The report is addressed to whoever runs the system at night. |

## Confusable pairs

Model-invocable skills whose requests could overlap, and the clause that separates them (written into the descriptions of both).

| Pair | Discriminator |
| --- | --- |
| `timeouts` / `retries` | How long one attempt may take, versus whether and how often a failed attempt is repeated. |
| `timeouts` / `$release-it:circuit-breakers` | A per-call wait limit, versus a decision to stop calling at all based on the dependency's observed health. |
| `$release-it:circuit-breakers` / `bulkheads` | Reacting to one unhealthy dependency, versus partitioning capacity before anything is unhealthy. |
| `$release-it:circuit-breakers` / `$release-it:stability-patterns` | Fail fast based on dependency state is the breaker; fail fast on a missing precondition or scarce resource is in `$release-it:stability-patterns`. |
| `bulkheads` / `$release-it:resource-budgets` | Dividing capacity between workloads, versus sizing and releasing one resource. |
| `$release-it:back-pressure` / `queues` | The overload policy at the entry point, versus the contents and monitoring of a buffer. |
| `queues` / `$release-it:scheduled-work` | A buffer between producer and consumer, versus jobs started by the clock. |
| `retries` / `$release-it:scheduled-work` | Repeating a client call or redelivering a message, versus when periodic jobs start and how a long job is bounded. |
| `$release-it:data-boundaries` / `$release-it:api-contracts` | Checking what arrives, versus declaring what you promise. |
| `$release-it:api-contracts` / `$release-it:release-risk` | The shape and compatibility promise of an interface, versus the staged rollout of a change to it. |
| `logging` / `metrics` | An event with context, versus a counted or timed signal. |
| `$release-it:startup-and-health` / `$release-it:restartable-automation` | A process starting and reporting readiness, versus a script that operators rerun after partial failure. |
| `$release-it:restartable-automation` / `$release-it:operational-controls` | What happens on rerun or midway failure, versus who may start it, how it is audited and how it is stopped. |
| `$release-it:release-risk` / `$release-it:restartable-automation` | How a change is exposed and undone, versus how the steps of a deployment script survive interruption. |
| `caching` / `$release-it:back-pressure` | Behavior of a cache miss or cache outage, versus demand limits in general. |
| `$release-it:resilience-testing` / `$release-it:startup-and-health` | Proving the failure behavior in a test, versus designing the health behavior. |
| `$release-it:operational-controls` / `$release-it:release-risk` | Who may run delivery tooling, how it is audited and how it is stopped, versus how a change is staged, exposed and undone. Both descriptions name the other. |
| `$release-it:stability-patterns` / `$release-it:startup-and-health` | Failing fast at request or task time on a precondition or scarce resource, versus validating critical configuration and refusing to start at process boot. |
| `$release-it:data-boundaries` / `queues` | Validating the content of a message or response before it is cached or enqueued, versus attempt caps, parking and monitoring of messages that keep failing. |

Manual workflows that could be mixed up: `audit` / `$release-it:failure-mode-scan` / `$release-it:launch-check` (tree, flow, release), `review` / `checklist` / `release-it-final-gate` (findings, interactive walk, strict gate), `$release-it:failure-mode-scan` / `$release-it:incident-review` (before versus after a failure), `$release-it:game-day-plan` / `$release-it:resilience-testing` (experiment versus suite).

## Coverage check against the upstream sections

The authoritative, generated version is `docs/TRACEABILITY.md`. In summary, every one of the 22 `##` sections is applied by at least two components, and the subsections cited directly are Timeouts Are Mandatory, Retries Must Be Disciplined, Circuit Breakers and Fast Failure, Bulkheads and Isolation, Back Pressure, Queues, Demand Control, Load Shedding, Additional Stability Patterns, Restartable Automation, Observability Is Part of the Design, Logging, Metrics, Happy-Path Design, Retry Storms, Collapse by Queue, Silent Failure and Blast-Radius Amplification.

Sections served by the smallest number of components: `Load and Capacity Rules` (`$release-it:back-pressure`, `queues`, `$release-it:stability-patterns`), `API and Contract Rules`, `Cache Rules` and `Scheduled and Background Work Rules` (one skill and one reviewer each), `Final Instruction` (`principles`, `release-it-final-gate`). Those are small sections, fully applied by their owners.

## Overlap review

Pairs that were close and how they were separated:

- `timeouts` and `retries`: the first never discusses repetition, the second never sets a wait limit. `$release-it:call-chain-budget` is where the two meet, as arithmetic, and it states no new rules of the book.
- `timeouts` and `queues`: the infinite-wait ban is about waits on something outside the caller's control. An idle consumer parked on its own in-process queue, holding no request, lock or lease, is exempt (Added judgment, written into `timeouts` rule 3 and `release-it-timeout-reviewer`); the worker example in `queues` still polls with a timeout so it can shut down.
- `$release-it:back-pressure` and `queues`: the door versus the buffer. A rule about rejecting new work belongs to `$release-it:back-pressure`; a rule about what a queue stores, ages or discards belongs to `queues`.
- `$release-it:call-chain-budget` and the two reviewers that also multiply along a path (`release-it-retry-reviewer`: worst-case attempts per request; `release-it-timeout-reviewer`: inner limit against caller limit): the reviewers report the multiplication as evidence for one finding in their own domain, and their Not-checked lines point to `$release-it:call-chain-budget`. It is the only component that builds the full per-layer table and proposes a single retry owner.
- `$release-it:circuit-breakers` and `$release-it:stability-patterns`: the words "fail fast" appear in both source sections. In `$release-it:circuit-breakers` it means stop calling an unhealthy dependency; in `$release-it:stability-patterns` it means check a precondition or scarce resource before starting work.
- `$release-it:restartable-automation`, `$release-it:release-risk`, `$release-it:operational-controls`, `$release-it:startup-and-health`: four deployment-side skills, separated by object (script, change, tool, process). Configuration validation at boot is in `$release-it:startup-and-health`; auditable and reversible configuration changes are in `$release-it:release-risk`. Both `$release-it:operational-controls` and `$release-it:release-risk` touch delivery pipelines: staging and rollback of a rollout are `$release-it:release-risk`, who may trigger or stop the pipeline is `$release-it:operational-controls`.
- `$release-it:stability-patterns` and `$release-it:startup-and-health`: both say "fail fast". A precondition checked while serving a request or task, before a scarce resource is taken, is `$release-it:stability-patterns`; configuration checked at process boot is `$release-it:startup-and-health`.
- `$release-it:data-boundaries` and `queues`: both talk about poison messages. Content that fails validation is kept out at the boundary (`$release-it:data-boundaries`); a message that keeps failing in the consumer is capped, parked and monitored (`queues`).
- `logging` and `metrics`: both cite `Observability Is Part of the Design`; `logging` owns the correlation identifier and the failure log line, `metrics` owns the minimum signal set and saturation. Health endpoints are owned by `$release-it:startup-and-health`.
- `review`, `checklist` and `release-it-final-gate`: findings versus interactive walk with next actions versus isolated PASS or FAIL. `checklist` and `release-it-final-gate` use the same twelve questions on purpose; their outputs differ.
- `release-it-overload-hardener` and `release-it-call-hardener`: demand controls (entry points, queues, pools) versus outbound call sites. A change that needs both is two delegations.
- `release-it-resilience-test-reviewer` and `release-it-resilience-test-writer`: finds missing proof, writes it. The writer never edits production code.
- `release-it-hazard-scanner` and `audit`: the scanner reports raw counts and locations; `audit` reads and rates.
- `failure-first` (style) and `$release-it:failure-mode-scan` (skill): the style puts a short ledger before each edit in a session; the skill is a deliberate scan of one flow in a fork.
- `fix` and the hardeners: `fix` edits in the current session from a findings list; the hardeners are the isolated versions for call sites, demand controls and scripts, and `fix` hands off only the writing of a large test, to `release-it-resilience-test-writer`.

Hand-offs the README walkthroughs rely on: `review` ends with `$release-it:fix last review`; `$release-it:call-chain-budget` ends with `release-it-call-hardener` or `$release-it:fix`; `release-it-call-hardener` ends with a list for `release-it-resilience-test-writer`; `$release-it:failure-mode-scan` ends with `$release-it:call-chain-budget` or `$release-it:plan`; `plan` ends with `$release-it:checklist` then `release-it-final-gate`; `$release-it:incident-review` ends with `$release-it:plan` then `$release-it:game-day-plan`; `release-it-hazard-scanner` ends by pointing at `$release-it:review` or `$release-it:audit`; `audit` and `$release-it:launch-check` end with a next command.

Upstream sections with no skill of their own: `Forbidden Patterns` and `Review Rules` are enforced by `review`, `audit` and `release-it-hazard-scanner` and distributed as anti-pattern entries across the defense skills; `Final Instruction` and `Primary Directive` live in the hub, `release-it-final-gate`, `failure-first` and `terse`.
