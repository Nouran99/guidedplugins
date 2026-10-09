# Designing Data-Intensive Applications plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`; a few `###` headings are cited where only that slice applies.

## Design decisions

1. **The rule set is a list of concerns, so the plugin is a list of concerns.** The upstream file has 26 `##` sections and most are one decision a data-system author makes: what a write acknowledgment means, how a dataset is owned, how readers see it, what a retry does, which order is required, how a payload changes, where data is cut, how replicas agree, which anomalies a transaction allows, what is derived, what the clocks can be trusted for, how jobs recover. Topical skills follow those seams, with four deliberate exceptions. `Data Model and Storage Rules` is divided between `source-of-truth` (ownership, the `Source of Truth` slice) and `data-model-choice` (storage shape). `Reliability Rules` is divided by anti-pattern between `write-acknowledgment` (accepted, persisted, applied; downstream success) and `idempotent-handlers` (effects that cannot be retried safely). `Batch and Stream Processing Rules` is divided between `batch-jobs` and `stream-processing` by the first question a reader asks: can the work be rerun, or does time matter. `Schema Evolution Rules` and `Encoding and Data Flow Rules` are one skill, `encoding-and-evolution`, because the two sections answer the same question about the same contract. `Distributed Fault, Clock, and Consensus Rules` stays one skill because timeouts, clocks, leases and majorities are one assumption: trusting time and a quorum. `Review Rules`, `Forbidden Patterns`, `Code Generation Rules` and `Review Checklist` are applied by the workflows, the gate and the owner skills named in the ownership tables rather than by a topical skill of their own.
2. **The appendix asks for one reviewer per data-system concern.** Storage, encoding and evolution, replication, partitioning, transactions, consistency, batch and streams each have a reviewer with its own report shape (see the Subagents table). The cross-cutting concerns the rule set stresses (idempotency, ordering, ownership and derivation, faults, boundaries, test gaps, capacity claims, write-path states) also get one each.
3. **Workflows follow what the rule set tells an author to do, not generic review steps.** `consistency-check` is the workflow named in the appendix. The other book-specific workflows each operationalize one trigger rule of the upstream mini file: `write-path-trace` (changing a write path), `compat-matrix` (changing a schema or contract), `replay-drill` (adding retries, consumers or replayable work), `ownership-map` (adding or changing derived representations), `invariant-map` (choosing isolation).
4. **Rule provenance is labelled.** A rule with no label is stated in `references/full.md`. `Compact rule` marks guidance found only in `mini.md` or `nano.md` (for example fencing of stale lock holders, or convergence after replica divergence). `Added judgment` marks this plugin's own heuristics and techniques (index column ordering, outbox, expand and contract migrations, defaults for new required fields, fixed logical partitions instead of modulo by node count, the concrete event metadata field list, per-field merge, lateness policy, and every number). The source gives no numeric thresholds, so every number in this plugin is Added judgment. The same label covers scoping exceptions and trade-off notes that the source does not state, so a reviewer finding is never justified by "the book allows this" unless the source says so.
5. **The book's own brake is kept.** The rule set asks for explicit contracts and is also explicit that the right tool is the one the workload fits: strong consistency only where the product truly requires it, consensus and atomic commit only when the coordination problem requires them, a document model when data is self-contained, and no unnecessary distribution. Reviewers do not flag a simple single-database design for lacking a distributed mechanism it does not need, and implementers make the smallest change that closes a finding. That scoping is Added judgment built on those rules: the source asks for explicit contracts and names no designs that are exempt.
9. **Rules are paraphrased, not copied.** The bold sentence of each rule in a topical skill restates the upstream rule in new words and keeps its modal verb (an unqualified verb stays binding, `Prefer` stays a strong default, `Do not` and `Avoid` stay prohibitions). The `Check` and the reason that follow carry the plugin's added value. When the upstream wording is needed, `/data-intensive-apps:explain-rule` reads it from `references/full.md`.
6. **Model-invocable skills are at the cap of 20.** That is the hub plus 19 topical skills. Everything that is a procedure with arguments is manual (12 skills, 4 of them `context: fork`).
7. **Agents own one concern and have their own report shape.** A write-path reviewer reports a gap ledger of failing steps, a partitioning reviewer reports key analysis, an ownership reviewer reports the datasets a diff touches, a fault-model reviewer reports an assumption ledger. No two reviewers share a table.
8. **Implementers are few and specific.** `idempotency-hardener`, `schema-migrator`, `derived-view-builder` and `data-test-writer` each change one kind of thing. Everything else goes through `/data-intensive-apps:fix`, which maps a finding to the owning skill and makes the smallest change.

## Ownership of the Review Rules look-fors

Every item of the upstream `Review Rules` has exactly one owning skill. `review`, `audit` and `final-gate` check all of them; other skills do not restate them.

| Look for | Owner skill | Reviewer |
| --- | --- | --- |
| hidden assumptions about ordering | `ordering-scope` | `ordering-reviewer` |
| hidden assumptions about exactly-once delivery | `idempotent-handlers` | `idempotency-reviewer` |
| lack of idempotency | `idempotent-handlers` | `idempotency-reviewer` |
| no source-of-truth ownership | `source-of-truth` | `ownership-reviewer` |
| broken schema evolution practices | `encoding-and-evolution` | `evolution-reviewer` |
| no versioning or sequencing where concurrency matters | `ordering-scope` (versions on entity state), `transactions-and-isolation` (compare-and-set on shared rows) | `ordering-reviewer`, `transaction-reviewer` |
| side effects that cannot be repaired | `transactions-and-isolation` | `transaction-reviewer` |
| write paths that update several stores with unclear guarantees | `transactions-and-isolation` | `transaction-reviewer` |
| projections that cannot be rebuilt | `derived-data` | `ownership-reviewer` |
| partitioning blind to locality or hotspots | `partitioning-locality` | `partitioning-reviewer` |

## Ownership of the Forbidden Patterns

| Forbidden pattern | Owner skill | Also checked by |
| --- | --- | --- |
| Exactly-Once Wishful Thinking | `idempotent-handlers` | `idempotency-reviewer`, `final-gate` |
| Hidden Consistency Contract | `consistency-contract` | `consistency-reviewer`, `final-gate` |
| Uncoordinated Multi-Writes | `transactions-and-isolation` | `transaction-reviewer`, `final-gate` |
| Schema Drift by Accident | `encoding-and-evolution` | `evolution-reviewer`, `final-gate` |

## Ownership of the Reliability, Testing and Code Generation rules

| Upstream item | Owner |
| --- | --- |
| Reliability: acknowledgment semantics, accepted versus persisted versus applied, downstream success not implied | `write-acknowledgment` |
| Reliability: side effects that cannot be retried safely | `idempotent-handlers` |
| Testing Rules (all six) | `data-path-tests`, with `test-gap-reviewer` and `data-test-writer` |
| Code Generation Rules (seven defaults, four avoid-by-default) | `plan` applies them to a design; `fix` and the implementers apply them to code; `contract-first` shows them before code |
| Observability of lag, retries and failures (default 7) | `derived-data` (pipelines, lag), `stream-processing` (consumer lag, retries), `load-and-latency` (inspectable production behavior) |

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, labels, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Review Rules; Forbidden Patterns; Code Generation Rules; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules itself. |
| `write-acknowledgment` | What "success" means for a write (accepted, persisted, applied, durable), unknown outcome after timeout or crash, recovery | Reliability Rules; Primary Directive; Write Semantics; Distributed Fault, Clock, and Consensus Rules | `idempotent-handlers` is the receiver that may run twice; this is what the caller is told and what it may do next. |
| `load-and-latency` | Concrete load parameters, percentiles, named bottleneck, operability and accidental complexity before architecture changes | Scalability and Maintainability Rules | The only skill about measuring and claiming capacity; `partitioning-locality` handles skew once the key is the issue. |
| `source-of-truth` | Primary owner, derived copies, update path, repair for every important dataset | Data Model and Storage Rules; Source of Truth; Primary Directive | `derived-data` starts after ownership is settled and is about rebuild, lag and observability of a copy. |
| `data-model-choice` | Relational, document, graph, key-value, analytical; declarative queries; application-side joins | Query Model and Data Shape Rules; Data Model and Storage Rules | Chooses the shape of data and the query style; `storage-and-indexing` chooses the engine and index structure. |
| `storage-and-indexing` | LSM versus B-tree fit, secondary index cost, OLTP versus analytics, columnar layouts, memory residency | Storage Engine and Indexing Rules | `data-model-choice` decides what the data looks like; this decides how it is laid out and found. |
| `consistency-contract` | Read-after-write, staleness tolerance, conflict handling, visibility; the slogan "eventual consistency" replaced by a contract | Consistency Rules; Write Semantics; Hidden Consistency Contract | Product-level promise to readers; `replication-topology` is the mechanism that does or does not deliver it. |
| `idempotent-handlers` | Dedup keys, naturally idempotent transitions, replay, exactly-once claims | Idempotency and Replay Rules; Exactly-Once Wishful Thinking; Reliability Rules | Handles "the same input arrives twice"; `ordering-scope` handles "different inputs arrive in the wrong order". |
| `ordering-scope` | Minimum ordering needed, scope per key or stream, versions and sequence policy, parallel consumers | Ordering Rules; Review Rules | Never discusses duplicates; `idempotent-handlers` never discusses order. |
| `event-design` | Commands versus events versus views, stable identifiers, metadata, versioned payloads, logs as histories | Event, Log, and Stream Rules; Event Design | Meaning and identity of an event; `encoding-and-evolution` is how any payload changes over time. |
| `encoding-and-evolution` | Backward and forward compatibility, field reuse, enums, encoding formats, rolling upgrades, RPC that hides failure | Schema Evolution Rules; Encoding and Data Flow Rules; Schema Drift by Accident | Applies to any contract (table, API, message); `event-design` applies only to the event's meaning and identifiers. |
| `partitioning-locality` | Partition key choice, skew and hot keys, cross-partition cost, routing and rebalancing | Partitioning and Locality Rules; Review Rules | About where data is cut; `service-boundaries` is about where code and ownership are cut. |
| `replication-topology` | Leader-follower, multi-leader, leaderless; sync versus async; failover; quorums; conflict resolution | Replication Rules | The mechanism; `consistency-contract` is the promise it must support. |
| `transactions-and-isolation` | Atomicity scope, distributed transactions as last resort, isolation versus invariants, multi-store writes, side effects around commit | Transaction Rules; Isolation and Invariants; Uncoordinated Multi-Writes; Review Rules | Inside one operation's atomicity and anomalies; `consistency-contract` is about what other readers see afterwards. |
| `derived-data` | Caches, indexes, read models, projections: propagation, lag visibility, rebuild, repair | Derived Data Rules; Source of Truth; Review Rules | `source-of-truth` decides who owns the fact; this keeps the copies repairable. |
| `faults-and-coordination` | Fault model, timeouts as unknown, monotonic clocks, locks and leases with fencing, linearizability and consensus only when needed | Distributed Fault, Clock, and Consensus Rules | The only skill about trusting clocks, leases and majorities; `replication-topology` covers data copies, not mutual exclusion. |
| `batch-jobs` | Recomputable and recoverable batch work, side effects kept out, atomic publication of output | Batch and Stream Processing Rules; Testing Rules | Bounded input you can rerun; `stream-processing` is unbounded input where time semantics matter. |
| `stream-processing` | Event versus processing versus ingestion time, windows, late data, joins, state, checkpoints, CDC, event sourcing, delivery guarantees | Batch and Stream Processing Rules; Event, Log, and Stream Rules | Unbounded input and time; `batch-jobs` never discusses windows or watermarks. |
| `service-boundaries` | Boundaries by data ownership, chatty hot paths, contracts with identifiers, versions and failure semantics | API and Service Boundary Rules; Encoding and Data Flow Rules; Review Checklist | Where services are cut and how they call each other; `encoding-and-evolution` is how their messages change. |
| `data-path-tests` | Duplicate, out-of-order, replay, conflict, schema compatibility and rebuild tests | Testing Rules | Only skill about the test cases; every other skill says what to build, this one says how to prove it. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Forbidden Patterns; Review Checklist | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Repository scan across the ten look-fors and four forbidden patterns, rated per concern, at most 40 lines | Review Rules; Forbidden Patterns; Review Checklist | `ownership-map` and `consistency-check` each go deep on one question; `audit` is the broad health picture. |
| `plan` | no | no | Plan a data change: the five questions, touched concerns, rollout, tests, observability | Primary Directive; Code Generation Rules; Testing Rules; Final Instruction | Produces a plan before edits; `write-path-trace` examines an existing path. |
| `explain-rule` | no | no | Explain one rule: modal strength, reason, check, example, exception | Purpose; Primary Directive | The only manual skill that teaches instead of reporting findings. |
| `checklist` | no | no | Walk the ten-item review checklist with yes, no or not applicable and a next action for each no | Review Checklist; Final Instruction | `final-gate` is the isolated PASS or FAIL with evidence; `checklist` is the interactive walk with next actions. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Code Generation Rules; Review Rules; Testing Rules | Takes findings from any reviewer; the implementers are scoped to one kind of change. |
| `consistency-check` | yes | no | For each read path: freshness need, where it is served from, guarantee provided, conflict model | Consistency Rules; Write Semantics; Replication Rules; Hidden Consistency Contract | `consistency-reviewer` reviews a diff and returns findings; this maps every read path in a scope. |
| `write-path-trace` | no | no | Follow one write step by step: state after each step, crash outcome, retry outcome, repair path | Primary Directive; Reliability Rules; Transaction Rules; Uncoordinated Multi-Writes | Traces a synchronous write through several stores; `replay-drill` traces redelivered work. |
| `compat-matrix` | no | no | Build old and new writers by old and new readers for one contract change and order the rollout | Schema Evolution Rules; Encoding and Data Flow Rules; Schema Drift by Accident | `evolution-reviewer` judges a diff; this constructs the matrix and rollout order before the change. |
| `replay-drill` | no | no | Walk one consumer, job or handler through duplicate, reordered, late, crash, restart and full-replay scenarios by reading the code | Idempotency and Replay Rules; Ordering Rules; Batch and Stream Processing Rules; Testing Rules | Scenario outcomes for redelivered work; `idempotency-reviewer` reports a ledger of side effects and dedup mechanisms. |
| `ownership-map` | yes | no | Inventory datasets, owners, writers, derived copies, propagation, lag visibility and rebuild paths | Source of Truth; Data Model and Storage Rules; Derived Data Rules | A repository-wide inventory; `ownership-reviewer` reviews the datasets touched by a change. |
| `invariant-map` | yes | no | List business invariants in a scope, the mechanism enforcing each, the isolation in effect and the anomaly still possible, at most 40 lines | Transaction Rules; Isolation and Invariants | An inventory built from the invariants outward over a module or repository, ending in a closing mechanism per gap; `transaction-reviewer` reviews the invariants a diff touches and reports a breaking interleaving and a ranked verdict. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Primary Directive; Review Checklist; Final Instruction | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the ten-item checklist on the working diff and returns PASS or FAIL | principles | Review Checklist; Review Rules; Forbidden Patterns | Binary gate with evidence; reviewers return ranked findings. |
| `write-path-reviewer` | sonnet | Gap ledger of the write-path steps where the code is wrong or silent: what a crash or timeout leaves behind, what the caller is told | write-acknowledgment | Reliability Rules; Primary Directive | Reports only the failing steps of a diff, ranked; `/data-intensive-apps:write-path-trace` produces the complete step ledger of one path; `idempotency-reviewer` starts from receivers of redelivered work. |
| `transaction-reviewer` | sonnet | Invariants relied on by the diff with the interleaving that breaks each, plus a multi-write inventory | transactions-and-isolation | Transaction Rules; Isolation and Invariants; Uncoordinated Multi-Writes | Judges atomicity and anomalies; `write-path-reviewer` judges what the caller is told. |
| `consistency-reviewer` | sonnet | Read paths touched by the diff (promise versus delivery) and the conflict model per entity | consistency-contract | Consistency Rules; Write Semantics; Hidden Consistency Contract | Reviews the promise; `replication-reviewer` reviews the mechanism. |
| `replication-reviewer` | sonnet | Topology sheet: sync and async, failover, read routing, quorum claims, conflict resolution | replication-topology | Replication Rules | Output is a topology sheet; no product freshness decisions. |
| `idempotency-reviewer` | sonnet | Handler ledger: effects, dedup mechanism, duplicate and replay outcome | idempotent-handlers | Idempotency and Replay Rules; Exactly-Once Wishful Thinking; Review Rules | Duplicates only; `ordering-reviewer` owns order. |
| `ordering-reviewer` | sonnet | Ordering map: assumed order, scope provided, consumer concurrency, version policy | ordering-scope | Ordering Rules; Review Rules | Order only; never reports dedup. |
| `stream-reviewer` | sonnet | Source-to-sink sheet: time semantics, windows, lateness, state, checkpoints, guarantee, event contract | stream-processing, event-design | Batch and Stream Processing Rules; Event, Log, and Stream Rules; Event Design | Unbounded processing; `batch-reviewer` handles rerunnable jobs. |
| `batch-reviewer` | sonnet | Job recovery sheet: input snapshot, output publication, rerun result, side effects | batch-jobs | Batch and Stream Processing Rules; Testing Rules | Bounded rerunnable work; no time-semantics questions. |
| `evolution-reviewer` | sonnet | Compatibility matrix per contract change | encoding-and-evolution | Schema Evolution Rules; Encoding and Data Flow Rules; Schema Drift by Accident | Judges a diff; `/data-intensive-apps:compat-matrix` builds the matrix before the change. |
| `partitioning-reviewer` | sonnet | Key analysis: operation, frequency, partitions touched, skew | partitioning-locality | Partitioning and Locality Rules; Review Rules | Looks at keys and routing only. |
| `storage-reviewer` | sonnet | Workload-fit table for models, indexes and layouts; indexes with no consumer | storage-and-indexing, data-model-choice | Storage Engine and Indexing Rules; Query Model and Data Shape Rules; Data Model and Storage Rules | Structure fit to workload; `partitioning-reviewer` looks at cuts across nodes. |
| `ownership-reviewer` | sonnet | Datasets touched by the diff: class, what changes, writers after the change, lag and rebuild after the change | source-of-truth, derived-data | Data Model and Storage Rules; Source of Truth; Derived Data Rules | Reports who owns and whether copies are repairable for the datasets a diff touches; `storage-reviewer` never does, and `/data-intensive-apps:ownership-map` inventories a whole scope. |
| `fault-model-reviewer` | sonnet | Assumption ledger for timeouts, clocks, locks, leases, leaders, majorities | faults-and-coordination | Distributed Fault, Clock, and Consensus Rules | Mutual exclusion and time; `replication-reviewer` covers data copies. |
| `service-boundary-reviewer` | sonnet | Boundary sheet: datasets written per service, hot-path calls, contract fields | service-boundaries | API and Service Boundary Rules; Encoding and Data Flow Rules | Cuts between services; `partitioning-reviewer` cuts within a store. |
| `test-gap-reviewer` | sonnet | Behavior-to-test map for the six test classes | data-path-tests | Testing Rules | Finds tests that do not exist; no other reviewer reports test gaps. |
| `capacity-reviewer` | sonnet | Claim sheet: load parameters, percentiles, bottleneck, evidence | load-and-latency | Scalability and Maintainability Rules | Judges performance and scalability claims; no data-correctness findings. |
| `idempotency-hardener` | sonnet | Makes one handler retry-safe and adds its duplicate-delivery test | idempotent-handlers, data-path-tests | Idempotency and Replay Rules; Code Generation Rules; Testing Rules | Changes production code in a handler; `data-test-writer` writes only tests. |
| `schema-migrator` | sonnet | Carries out a contract change in expand, migrate, contract steps | encoding-and-evolution | Schema Evolution Rules; Encoding and Data Flow Rules; Code Generation Rules | One contract change in staged releases; no handler changes. |
| `derived-view-builder` | sonnet | Makes a projection, cache or index rebuildable and observable | derived-data | Derived Data Rules; Code Generation Rules | Edits the derivation path only. |
| `data-test-writer` | sonnet | Writes duplicate, reorder, replay, conflict, compatibility and rebuild tests | data-path-tests | Testing Rules | Tests only; never edits production code. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice and ends non-trivial answers with one check question | Purpose; Final Instruction | Teaching is the goal. |
| `strict-reviewer` | Ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Forbidden Patterns | Never changes code. |
| `pair` | Small steps, narrates intent, asks before changes larger than a few lines or touching a contract | Code Generation Rules; Schema Evolution Rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Review Checklist | Brevity rules. |
| `contract-first` | Before any data code or design, prints a data contract card answering the five questions and marks unanswered ones OPEN | Primary Directive; Code Generation Rules | Fixes what is asserted about data before code exists. |
| `failure-first` | After any proposal, shows a failure walk of scenarios with outcome and guard before the code | Reliability Rules; Idempotency and Replay Rules; Testing Rules | Fixes what happens under faults; `contract-first` fixes what is claimed. |

## Confusable pairs

Model-invocable skills whose triggers could fire on the same request, and how they are separated. "Clause in" names the description that carries an explicit pointer to its sibling (`both` when each does). `wording` means the two descriptions list disjoint signals and name no sibling, because the 300-character budget is spent on the signals that distinguish them.

| Pair | Separated by | Clause in |
| --- | --- | --- |
| `write-acknowledgment` / `idempotent-handlers` | What the caller is told and may do after a timeout versus making a receiver safe to run twice. | both |
| `write-acknowledgment` / `transactions-and-isolation` | The meaning of success and unknown outcome versus atomicity scope and anomalies. | both |
| `write-acknowledgment` / `faults-and-coordination` | Ack levels and recovery of a write versus clocks, leases and the fault model. | wording |
| `consistency-contract` / `replication-topology` | The promise to readers versus the replica mechanism. | both |
| `consistency-contract` / `transactions-and-isolation` | What readers may see after the write and how two clients' updates to one record are detected and resolved, versus races and anomalies between concurrent transactions. Both bodies prescribe a version or compare-and-set for lost updates, so the descriptions say which side owns the scope: `consistency-contract` for who sees what and conflicts across clients or regions, `transactions-and-isolation` for check-then-write inside a transaction. | both |
| `source-of-truth` / `derived-data` | Who owns the fact versus keeping a copy rebuildable and visible. | both |
| `source-of-truth` / `service-boundaries` | A dataset's owner versus how services are cut and call each other. | `service-boundaries` |
| `idempotent-handlers` / `ordering-scope` | Same input twice versus inputs in the wrong order. | both |
| `idempotent-handlers` / `stream-processing` | Making one handler safe versus time, windows and delivery guarantees across a pipeline. | `stream-processing` |
| `event-design` / `encoding-and-evolution` | What an event means and carries versus how any payload changes over time. | both |
| `event-design` / `stream-processing` | The contract of the event versus the processor that consumes it. | `event-design` |
| `batch-jobs` / `stream-processing` | Bounded rerunnable input versus unbounded input with time semantics. | both |
| `derived-data` / `stream-processing` | Keeping a copy repairable versus the processor semantics (windows, CDC, event sourcing). | wording |
| `partitioning-locality` / `storage-and-indexing` | Which node holds the data versus how a node finds it. | wording |
| `partitioning-locality` / `load-and-latency` | Choosing the key and skew versus proving the bottleneck with numbers. | `load-and-latency` |
| `data-model-choice` / `storage-and-indexing` | Shape and query style versus engine and index structure. | both |
| `replication-topology` / `faults-and-coordination` | Data copies and failover versus leases, locks and consensus. | both |
| `transactions-and-isolation` / `faults-and-coordination` | Atomicity and isolation versus mutual exclusion under pauses and clock error. | wording |
| `service-boundaries` / `encoding-and-evolution` | Where the line is drawn versus how messages across it change. | `service-boundaries` |
| `data-path-tests` / every rule skill | Test cases for duplicates, order, replay, conflicts, compatibility and rebuild versus the design rule itself. | wording (it fires on test-writing requests only) |
| `principles` / every topical skill | The hub routes and holds no cluster rules; a topical skill holds the rules. They may load together by design. | wording |

Manual pairs: `review` / `audit` (a change versus a tree), `checklist` / `final-gate` (interactive walk with next actions versus isolated PASS or FAIL with evidence), `plan` / `write-path-trace` (a change not yet made versus a path that exists), `write-path-trace` / `replay-drill` (a synchronous write through several stores versus redelivered work through one consumer or job), `consistency-check` / `consistency-reviewer` (every read path in a scope versus a diff), `compat-matrix` / `evolution-reviewer` (build the matrix before the change versus judge a diff), `ownership-map` / `ownership-reviewer` (inventory versus a diff), `invariant-map` / `transaction-reviewer` (start from invariants versus start from a diff), `fix` / the four implementers (any finding list versus one kind of change each).

Maintenance: skill and agent pairs restate one procedure on purpose, because an agent must be self-contained and cannot rely on its preloaded skill being present. Change both copies in the same edit: `idempotent-handlers` / `idempotency-hardener`, `encoding-and-evolution` / `schema-migrator`, `derived-data` / `derived-view-builder`, `data-path-tests` / `data-test-writer`.

## Coverage check against the upstream sections

Generated from `docs/TRACEABILITY.md` when the plugin was built; the `###` headings (Source of Truth, Write Semantics, Event Design, Isolation and Invariants and the four forbidden patterns) are cited by the skills named in the ownership tables above.

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | explain-rule, principles, mentor (style) |
| Primary Directive | explain-rule, plan, principles, source-of-truth, write-acknowledgment, write-path-trace, lead, write-path-reviewer, contract-first (style) |
| Reliability Rules | idempotent-handlers, write-acknowledgment, write-path-trace, write-path-reviewer, failure-first (style) |
| Scalability and Maintainability Rules | load-and-latency, capacity-reviewer |
| Data Model and Storage Rules | data-model-choice, ownership-map, source-of-truth, ownership-reviewer, storage-reviewer |
| Query Model and Data Shape Rules | data-model-choice, storage-reviewer |
| Storage Engine and Indexing Rules | storage-and-indexing, storage-reviewer |
| Consistency Rules | consistency-check, consistency-contract, consistency-reviewer |
| Idempotency and Replay Rules | idempotent-handlers, replay-drill, idempotency-hardener, idempotency-reviewer, failure-first (style) |
| Ordering Rules | ordering-scope, replay-drill, ordering-reviewer |
| Event, Log, and Stream Rules | event-design, stream-processing, stream-reviewer |
| Schema Evolution Rules | compat-matrix, encoding-and-evolution, evolution-reviewer, schema-migrator, pair (style) |
| Encoding and Data Flow Rules | compat-matrix, encoding-and-evolution, service-boundaries, evolution-reviewer, schema-migrator, service-boundary-reviewer |
| Partitioning and Locality Rules | partitioning-locality, partitioning-reviewer |
| Replication Rules | consistency-check, replication-topology, replication-reviewer |
| Transaction Rules | invariant-map, transactions-and-isolation, write-path-trace, transaction-reviewer |
| Derived Data Rules | derived-data, ownership-map, derived-view-builder, ownership-reviewer |
| Distributed Fault, Clock, and Consensus Rules | faults-and-coordination, write-acknowledgment, fault-model-reviewer |
| Batch and Stream Processing Rules | batch-jobs, replay-drill, stream-processing, batch-reviewer, stream-reviewer |
| API and Service Boundary Rules | service-boundaries, service-boundary-reviewer |
| Review Rules | audit, derived-data, fix, ordering-scope, partitioning-locality, principles, review, transactions-and-isolation, final-gate, idempotency-reviewer, ordering-reviewer, partitioning-reviewer, strict-reviewer (style) |
| Forbidden Patterns | audit, principles, review, final-gate, strict-reviewer (style) |
| Code Generation Rules | fix, plan, principles, derived-view-builder, idempotency-hardener, schema-migrator, contract-first (style), pair (style) |
| Testing Rules | batch-jobs, data-path-tests, fix, plan, replay-drill, batch-reviewer, data-test-writer, idempotency-hardener, test-gap-reviewer, failure-first (style) |
| Review Checklist | audit, checklist, principles, review, service-boundaries, final-gate, lead, terse (style) |
| Final Instruction | checklist, plan, principles, lead, mentor (style) |

## Overlap review

Pairs that were close and how they were separated:

- `write-acknowledgment` and `idempotent-handlers`: caller side (what a response or a timeout means, what to do next) versus receiver side (what a second delivery does). Both mention an idempotency key, but the first only as the means to resolve an unknown outcome and the second as the design of the dedup record.
- `consistency-contract` and `replication-topology`: the first never discusses topology; the second never decides what the product needs. Read-your-writes appears in both, once as a contract line item and once as the routing mechanism that provides it.
- `source-of-truth` and `derived-data`: ownership versus repairability. `ownership-reviewer` uses both skills but reports one ledger, so there is no second reviewer for derived data.
- `transactions-and-isolation` and `write-acknowledgment`: the first is about atomicity of one operation (what commits together, which anomalies can race), the second about the meaning of the answer returned to a caller and recovery after an unknown outcome.
- `batch-jobs` and `stream-processing`: reruns of bounded input versus time semantics of unbounded input. Both cite the upstream section on source-to-sink guarantees, each for its own kind of path.
- `write-path-trace` and `replay-drill`: the first starts at a request that writes; the second at a message, job or event that is delivered more than once.
- `write-path-reviewer` and `idempotency-reviewer`: the first reports state after each step of one write; the second reports a handler's behavior when the same input is delivered again.
- `write-path-reviewer` and `transaction-reviewer`: both fire on a handler that writes a store and then publishes or calls out. The first reports what is durable and visible after each step and what the caller is told; the second reports which invariants a concurrent transaction can break and whether the atomicity scope is stated and repaired. Each description names the other, and each Constraints line hands the other's concern over.
- `data-path-tests` and `test-gap-reviewer` and `data-test-writer`: rules for the six test classes, the read-only map of gaps, and the writer of the missing tests. The hardener adds only the duplicate-delivery test for the handler it changed.
- `ownership-reviewer` and `storage-reviewer`: ownership and repair versus fit of model, index and layout to workload.
