# Designing Data-Intensive Applications plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md`; a few `###` headings are cited where only that slice applies.

## Design decisions

1. **The rule set is a list of concerns, so the plugin is a list of concerns.** The upstream file has 26 `##` sections and most are one decision a data-system author makes: what a write acknowledgment means, how a dataset is owned, how readers see it, what a retry does, which order is required, how a payload changes, where data is cut, how replicas agree, which anomalies a transaction allows, what is derived, what the clocks can be trusted for, how jobs recover. Topical skills follow those seams, with four deliberate exceptions. `Data Model and Storage Rules` is divided between `data-intensive-apps-source-of-truth` (ownership, the `Source of Truth` slice) and `data-intensive-apps-data-model-choice` (storage shape). `Reliability Rules` is divided by anti-pattern between `data-intensive-apps-write-acknowledgment` (accepted, persisted, applied; downstream success) and `data-intensive-apps-idempotent-handlers` (effects that cannot be retried safely). `Batch and Stream Processing Rules` is divided between `data-intensive-apps-batch-jobs` and `data-intensive-apps-stream-processing` by the first question a reader asks: can the work be rerun, or does time matter. `Schema Evolution Rules` and `Encoding and Data Flow Rules` are one skill, `data-intensive-apps-encoding-and-evolution`, because the two sections answer the same question about the same contract. `Distributed Fault, Clock, and Consensus Rules` stays one skill because timeouts, clocks, leases and majorities are one assumption: trusting time and a quorum. `Review Rules`, `Forbidden Patterns`, `Code Generation Rules` and `Review Checklist` are applied by the workflows, the gate and the owner skills named in the ownership tables rather than by a topical skill of their own.
2. **The appendix asks for one reviewer per data-system concern.** Storage, encoding and evolution, replication, partitioning, transactions, consistency, batch and streams each have a reviewer with its own report shape (see the Subagents table). The cross-cutting concerns the rule set stresses (idempotency, ordering, ownership and derivation, faults, boundaries, test gaps, capacity claims, write-path states) also get one each.
3. **Workflows follow what the rule set tells an author to do, not generic review steps.** `data-intensive-apps-consistency-check` is the workflow named in the appendix. The other book-specific workflows each operationalize one trigger rule of the upstream mini file: `data-intensive-apps-write-path-trace` (changing a write path), `data-intensive-apps-compat-matrix` (changing a schema or contract), `data-intensive-apps-replay-drill` (adding retries, consumers or replayable work), `data-intensive-apps-ownership-map` (adding or changing derived representations), `data-intensive-apps-invariant-map` (choosing isolation).
4. **Rule provenance is labelled.** A rule with no label is stated in `references/full.md`. `Compact rule` marks guidance found only in `mini.md` or `nano.md` (for example fencing of stale lock holders, or convergence after replica divergence). `Added judgment` marks this plugin's own heuristics and techniques (index column ordering, outbox, expand and contract migrations, defaults for new required fields, fixed logical partitions instead of modulo by node count, the concrete event metadata field list, per-field merge, lateness policy, and every number). The source gives no numeric thresholds, so every number in this plugin is Added judgment. The same label covers scoping exceptions and trade-off notes that the source does not state, so a reviewer finding is never justified by "the book allows this" unless the source says so.
5. **The book's own brake is kept.** The rule set asks for explicit contracts and is also explicit that the right tool is the one the workload fits: strong consistency only where the product truly requires it, consensus and atomic commit only when the coordination problem requires them, a document model when data is self-contained, and no unnecessary distribution. Reviewers do not flag a simple single-database design for lacking a distributed mechanism it does not need, and implementers make the smallest change that closes a finding. That scoping is Added judgment built on those rules: the source asks for explicit contracts and names no designs that are exempt.
9. **Rules are paraphrased, not copied.** The bold sentence of each rule in a topical skill restates the upstream rule in new words and keeps its modal verb (an unqualified verb stays binding, `Prefer` stays a strong default, `Do not` and `Avoid` stay prohibitions). The `Check` and the reason that follow carry the plugin's added value. When the upstream wording is needed, `data-intensive-apps-explain-rule` reads it from `references/full.md`.
6. **Model-invocable skills are at the cap of 20.** That is the hub plus 19 topical skills. Everything that is a procedure with arguments is manual (12 skills, 4 of them `context: fork`).
7. **Agents own one concern and have their own report shape.** A write-path reviewer reports a gap ledger of failing steps, a partitioning reviewer reports key analysis, an ownership reviewer reports the datasets a diff touches, a fault-model reviewer reports an assumption ledger. No two reviewers share a table.
8. **Implementers are few and specific.** `data-intensive-apps-idempotency-hardener`, `data-intensive-apps-schema-migrator`, `data-intensive-apps-derived-view-builder` and `data-intensive-apps-data-test-writer` each change one kind of thing. Everything else goes through `data-intensive-apps-fix`, which maps a finding to the owning skill and makes the smallest change.

## Ownership of the Review Rules look-fors

Every item of the upstream `Review Rules` has exactly one owning skill. `review`, `audit` and `data-intensive-apps-final-gate` check all of them; other skills do not restate them.

| Look for | Owner skill | Reviewer |
| --- | --- | --- |
| hidden assumptions about ordering | `data-intensive-apps-ordering-scope` | `data-intensive-apps-ordering-reviewer` |
| hidden assumptions about exactly-once delivery | `data-intensive-apps-idempotent-handlers` | `data-intensive-apps-idempotency-reviewer` |
| lack of idempotency | `data-intensive-apps-idempotent-handlers` | `data-intensive-apps-idempotency-reviewer` |
| no source-of-truth ownership | `data-intensive-apps-source-of-truth` | `data-intensive-apps-ownership-reviewer` |
| broken schema evolution practices | `data-intensive-apps-encoding-and-evolution` | `data-intensive-apps-evolution-reviewer` |
| no versioning or sequencing where concurrency matters | `data-intensive-apps-ordering-scope` (versions on entity state), `data-intensive-apps-transactions-and-isolation` (compare-and-set on shared rows) | `data-intensive-apps-ordering-reviewer`, `data-intensive-apps-transaction-reviewer` |
| side effects that cannot be repaired | `data-intensive-apps-transactions-and-isolation` | `data-intensive-apps-transaction-reviewer` |
| write paths that update several stores with unclear guarantees | `data-intensive-apps-transactions-and-isolation` | `data-intensive-apps-transaction-reviewer` |
| projections that cannot be rebuilt | `data-intensive-apps-derived-data` | `data-intensive-apps-ownership-reviewer` |
| partitioning blind to locality or hotspots | `data-intensive-apps-partitioning-locality` | `data-intensive-apps-partitioning-reviewer` |

## Ownership of the Forbidden Patterns

| Forbidden pattern | Owner skill | Also checked by |
| --- | --- | --- |
| Exactly-Once Wishful Thinking | `data-intensive-apps-idempotent-handlers` | `data-intensive-apps-idempotency-reviewer`, `data-intensive-apps-final-gate` |
| Hidden Consistency Contract | `data-intensive-apps-consistency-contract` | `data-intensive-apps-consistency-reviewer`, `data-intensive-apps-final-gate` |
| Uncoordinated Multi-Writes | `data-intensive-apps-transactions-and-isolation` | `data-intensive-apps-transaction-reviewer`, `data-intensive-apps-final-gate` |
| Schema Drift by Accident | `data-intensive-apps-encoding-and-evolution` | `data-intensive-apps-evolution-reviewer`, `data-intensive-apps-final-gate` |

## Ownership of the Reliability, Testing and Code Generation rules

| Upstream item | Owner |
| --- | --- |
| Reliability: acknowledgment semantics, accepted versus persisted versus applied, downstream success not implied | `data-intensive-apps-write-acknowledgment` |
| Reliability: side effects that cannot be retried safely | `data-intensive-apps-idempotent-handlers` |
| Testing Rules (all six) | `data-intensive-apps-data-path-tests`, with `data-intensive-apps-test-gap-reviewer` and `data-intensive-apps-data-test-writer` |
| Code Generation Rules (seven defaults, four avoid-by-default) | `plan` applies them to a design; `fix` and the implementers apply them to code; `contract-first` shows them before code |
| Observability of lag, retries and failures (default 7) | `data-intensive-apps-derived-data` (pipelines, lag), `data-intensive-apps-stream-processing` (consumer lag, retries), `data-intensive-apps-load-and-latency` (inspectable production behavior) |

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, labels, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Review Rules; Forbidden Patterns; Code Generation Rules; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules itself. |
| `data-intensive-apps-write-acknowledgment` | What "success" means for a write (accepted, persisted, applied, durable), unknown outcome after timeout or crash, recovery | Reliability Rules; Primary Directive; Write Semantics; Distributed Fault, Clock, and Consensus Rules | `data-intensive-apps-idempotent-handlers` is the receiver that may run twice; this is what the caller is told and what it may do next. |
| `data-intensive-apps-load-and-latency` | Concrete load parameters, percentiles, named bottleneck, operability and accidental complexity before architecture changes | Scalability and Maintainability Rules | The only skill about measuring and claiming capacity; `data-intensive-apps-partitioning-locality` handles skew once the key is the issue. |
| `data-intensive-apps-source-of-truth` | Primary owner, derived copies, update path, repair for every important dataset | Data Model and Storage Rules; Source of Truth; Primary Directive | `data-intensive-apps-derived-data` starts after ownership is settled and is about rebuild, lag and observability of a copy. |
| `data-intensive-apps-data-model-choice` | Relational, document, graph, key-value, analytical; declarative queries; application-side joins | Query Model and Data Shape Rules; Data Model and Storage Rules | Chooses the shape of data and the query style; `data-intensive-apps-storage-and-indexing` chooses the engine and index structure. |
| `data-intensive-apps-storage-and-indexing` | LSM versus B-tree fit, secondary index cost, OLTP versus analytics, columnar layouts, memory residency | Storage Engine and Indexing Rules | `data-intensive-apps-data-model-choice` decides what the data looks like; this decides how it is laid out and found. |
| `data-intensive-apps-consistency-contract` | Read-after-write, staleness tolerance, conflict handling, visibility; the slogan "eventual consistency" replaced by a contract | Consistency Rules; Write Semantics; Hidden Consistency Contract | Product-level promise to readers; `data-intensive-apps-replication-topology` is the mechanism that does or does not deliver it. |
| `data-intensive-apps-idempotent-handlers` | Dedup keys, naturally idempotent transitions, replay, exactly-once claims | Idempotency and Replay Rules; Exactly-Once Wishful Thinking; Reliability Rules | Handles "the same input arrives twice"; `data-intensive-apps-ordering-scope` handles "different inputs arrive in the wrong order". |
| `data-intensive-apps-ordering-scope` | Minimum ordering needed, scope per key or stream, versions and sequence policy, parallel consumers | Ordering Rules; Review Rules | Never discusses duplicates; `data-intensive-apps-idempotent-handlers` never discusses order. |
| `data-intensive-apps-event-design` | Commands versus events versus views, stable identifiers, metadata, versioned payloads, logs as histories | Event, Log, and Stream Rules; Event Design | Meaning and identity of an event; `data-intensive-apps-encoding-and-evolution` is how any payload changes over time. |
| `data-intensive-apps-encoding-and-evolution` | Backward and forward compatibility, field reuse, enums, encoding formats, rolling upgrades, RPC that hides failure | Schema Evolution Rules; Encoding and Data Flow Rules; Schema Drift by Accident | Applies to any contract (table, API, message); `data-intensive-apps-event-design` applies only to the event's meaning and identifiers. |
| `data-intensive-apps-partitioning-locality` | Partition key choice, skew and hot keys, cross-partition cost, routing and rebalancing | Partitioning and Locality Rules; Review Rules | About where data is cut; `data-intensive-apps-service-boundaries` is about where code and ownership are cut. |
| `data-intensive-apps-replication-topology` | Leader-follower, multi-leader, leaderless; sync versus async; failover; quorums; conflict resolution | Replication Rules | The mechanism; `data-intensive-apps-consistency-contract` is the promise it must support. |
| `data-intensive-apps-transactions-and-isolation` | Atomicity scope, distributed transactions as last resort, isolation versus invariants, multi-store writes, side effects around commit | Transaction Rules; Isolation and Invariants; Uncoordinated Multi-Writes; Review Rules | Inside one operation's atomicity and anomalies; `data-intensive-apps-consistency-contract` is about what other readers see afterwards. |
| `data-intensive-apps-derived-data` | Caches, indexes, read models, projections: propagation, lag visibility, rebuild, repair | Derived Data Rules; Source of Truth; Review Rules | `data-intensive-apps-source-of-truth` decides who owns the fact; this keeps the copies repairable. |
| `data-intensive-apps-faults-and-coordination` | Fault model, timeouts as unknown, monotonic clocks, locks and leases with fencing, linearizability and consensus only when needed | Distributed Fault, Clock, and Consensus Rules | The only skill about trusting clocks, leases and majorities; `data-intensive-apps-replication-topology` covers data copies, not mutual exclusion. |
| `data-intensive-apps-batch-jobs` | Recomputable and recoverable batch work, side effects kept out, atomic publication of output | Batch and Stream Processing Rules; Testing Rules | Bounded input you can rerun; `data-intensive-apps-stream-processing` is unbounded input where time semantics matter. |
| `data-intensive-apps-stream-processing` | Event versus processing versus ingestion time, windows, late data, joins, state, checkpoints, CDC, event sourcing, delivery guarantees | Batch and Stream Processing Rules; Event, Log, and Stream Rules | Unbounded input and time; `data-intensive-apps-batch-jobs` never discusses windows or watermarks. |
| `data-intensive-apps-service-boundaries` | Boundaries by data ownership, chatty hot paths, contracts with identifiers, versions and failure semantics | API and Service Boundary Rules; Encoding and Data Flow Rules; Review Checklist | Where services are cut and how they call each other; `data-intensive-apps-encoding-and-evolution` is how their messages change. |
| `data-intensive-apps-data-path-tests` | Duplicate, out-of-order, replay, conflict, schema compatibility and rebuild tests | Testing Rules | Only skill about the test cases; every other skill says what to build, this one says how to prove it. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Forbidden Patterns; Review Checklist | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Repository scan across the ten look-fors and four forbidden patterns, rated per concern, at most 40 lines | Review Rules; Forbidden Patterns; Review Checklist | `data-intensive-apps-ownership-map` and `data-intensive-apps-consistency-check` each go deep on one question; `audit` is the broad health picture. |
| `plan` | no | no | Plan a data change: the five questions, touched concerns, rollout, tests, observability | Primary Directive; Code Generation Rules; Testing Rules; Final Instruction | Produces a plan before edits; `data-intensive-apps-write-path-trace` examines an existing path. |
| `data-intensive-apps-explain-rule` | no | no | Explain one rule: modal strength, reason, check, example, exception | Purpose; Primary Directive | The only manual skill that teaches instead of reporting findings. |
| `checklist` | no | no | Walk the ten-item review checklist with yes, no or not applicable and a next action for each no | Review Checklist; Final Instruction | `data-intensive-apps-final-gate` is the isolated PASS or FAIL with evidence; `checklist` is the interactive walk with next actions. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Code Generation Rules; Review Rules; Testing Rules | Takes findings from any reviewer; the implementers are scoped to one kind of change. |
| `data-intensive-apps-consistency-check` | yes | no | For each read path: freshness need, where it is served from, guarantee provided, conflict model | Consistency Rules; Write Semantics; Replication Rules; Hidden Consistency Contract | `data-intensive-apps-consistency-reviewer` reviews a diff and returns findings; this maps every read path in a scope. |
| `data-intensive-apps-write-path-trace` | no | no | Follow one write step by step: state after each step, crash outcome, retry outcome, repair path | Primary Directive; Reliability Rules; Transaction Rules; Uncoordinated Multi-Writes | Traces a synchronous write through several stores; `data-intensive-apps-replay-drill` traces redelivered work. |
| `data-intensive-apps-compat-matrix` | no | no | Build old and new writers by old and new readers for one contract change and order the rollout | Schema Evolution Rules; Encoding and Data Flow Rules; Schema Drift by Accident | `data-intensive-apps-evolution-reviewer` judges a diff; this constructs the matrix and rollout order before the change. |
| `data-intensive-apps-replay-drill` | no | no | Walk one consumer, job or handler through duplicate, reordered, late, crash, restart and full-replay scenarios by reading the code | Idempotency and Replay Rules; Ordering Rules; Batch and Stream Processing Rules; Testing Rules | Scenario outcomes for redelivered work; `data-intensive-apps-idempotency-reviewer` reports a ledger of side effects and dedup mechanisms. |
| `data-intensive-apps-ownership-map` | yes | no | Inventory datasets, owners, writers, derived copies, propagation, lag visibility and rebuild paths | Source of Truth; Data Model and Storage Rules; Derived Data Rules | A repository-wide inventory; `data-intensive-apps-ownership-reviewer` reviews the datasets touched by a change. |
| `data-intensive-apps-invariant-map` | yes | no | List business invariants in a scope, the mechanism enforcing each, the isolation in effect and the anomaly still possible, at most 40 lines | Transaction Rules; Isolation and Invariants | An inventory built from the invariants outward over a module or repository, ending in a closing mechanism per gap; `data-intensive-apps-transaction-reviewer` reviews the invariants a diff touches and reports a breaking interleaving and a ranked verdict. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `data-intensive-apps-lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Primary Directive; Review Checklist; Final Instruction | Only agent that does not read code for defects. |
| `data-intensive-apps-final-gate` | sonnet | Runs the ten-item checklist on the working diff and returns PASS or FAIL | principles | Review Checklist; Review Rules; Forbidden Patterns | Binary gate with evidence; reviewers return ranked findings. |
| `data-intensive-apps-write-path-reviewer` | sonnet | Gap ledger of the write-path steps where the code is wrong or silent: what a crash or timeout leaves behind, what the caller is told | write-acknowledgment | Reliability Rules; Primary Directive | Reports only the failing steps of a diff, ranked; `data-intensive-apps-write-path-trace` produces the complete step ledger of one path; `data-intensive-apps-idempotency-reviewer` starts from receivers of redelivered work. |
| `data-intensive-apps-transaction-reviewer` | sonnet | Invariants relied on by the diff with the interleaving that breaks each, plus a multi-write inventory | transactions-and-isolation | Transaction Rules; Isolation and Invariants; Uncoordinated Multi-Writes | Judges atomicity and anomalies; `data-intensive-apps-write-path-reviewer` judges what the caller is told. |
| `data-intensive-apps-consistency-reviewer` | sonnet | Read paths touched by the diff (promise versus delivery) and the conflict model per entity | consistency-contract | Consistency Rules; Write Semantics; Hidden Consistency Contract | Reviews the promise; `data-intensive-apps-replication-reviewer` reviews the mechanism. |
| `data-intensive-apps-replication-reviewer` | sonnet | Topology sheet: sync and async, failover, read routing, quorum claims, conflict resolution | replication-topology | Replication Rules | Output is a topology sheet; no product freshness decisions. |
| `data-intensive-apps-idempotency-reviewer` | sonnet | Handler ledger: effects, dedup mechanism, duplicate and replay outcome | idempotent-handlers | Idempotency and Replay Rules; Exactly-Once Wishful Thinking; Review Rules | Duplicates only; `data-intensive-apps-ordering-reviewer` owns order. |
| `data-intensive-apps-ordering-reviewer` | sonnet | Ordering map: assumed order, scope provided, consumer concurrency, version policy | ordering-scope | Ordering Rules; Review Rules | Order only; never reports dedup. |
| `data-intensive-apps-stream-reviewer` | sonnet | Source-to-sink sheet: time semantics, windows, lateness, state, checkpoints, guarantee, event contract | stream-processing, event-design | Batch and Stream Processing Rules; Event, Log, and Stream Rules; Event Design | Unbounded processing; `data-intensive-apps-batch-reviewer` handles rerunnable jobs. |
| `data-intensive-apps-batch-reviewer` | sonnet | Job recovery sheet: input snapshot, output publication, rerun result, side effects | batch-jobs | Batch and Stream Processing Rules; Testing Rules | Bounded rerunnable work; no time-semantics questions. |
| `data-intensive-apps-evolution-reviewer` | sonnet | Compatibility matrix per contract change | encoding-and-evolution | Schema Evolution Rules; Encoding and Data Flow Rules; Schema Drift by Accident | Judges a diff; `data-intensive-apps-compat-matrix` builds the matrix before the change. |
| `data-intensive-apps-partitioning-reviewer` | sonnet | Key analysis: operation, frequency, partitions touched, skew | partitioning-locality | Partitioning and Locality Rules; Review Rules | Looks at keys and routing only. |
| `data-intensive-apps-storage-reviewer` | sonnet | Workload-fit table for models, indexes and layouts; indexes with no consumer | storage-and-indexing, data-model-choice | Storage Engine and Indexing Rules; Query Model and Data Shape Rules; Data Model and Storage Rules | Structure fit to workload; `data-intensive-apps-partitioning-reviewer` looks at cuts across nodes. |
| `data-intensive-apps-ownership-reviewer` | sonnet | Datasets touched by the diff: class, what changes, writers after the change, lag and rebuild after the change | source-of-truth, derived-data | Data Model and Storage Rules; Source of Truth; Derived Data Rules | Reports who owns and whether copies are repairable for the datasets a diff touches; `data-intensive-apps-storage-reviewer` never does, and `data-intensive-apps-ownership-map` inventories a whole scope. |
| `data-intensive-apps-fault-model-reviewer` | sonnet | Assumption ledger for timeouts, clocks, locks, leases, leaders, majorities | faults-and-coordination | Distributed Fault, Clock, and Consensus Rules | Mutual exclusion and time; `data-intensive-apps-replication-reviewer` covers data copies. |
| `data-intensive-apps-service-boundary-reviewer` | sonnet | Boundary sheet: datasets written per service, hot-path calls, contract fields | service-boundaries | API and Service Boundary Rules; Encoding and Data Flow Rules | Cuts between services; `data-intensive-apps-partitioning-reviewer` cuts within a store. |
| `data-intensive-apps-test-gap-reviewer` | sonnet | Behavior-to-test map for the six test classes | data-path-tests | Testing Rules | Finds tests that do not exist; no other reviewer reports test gaps. |
| `data-intensive-apps-capacity-reviewer` | sonnet | Claim sheet: load parameters, percentiles, bottleneck, evidence | load-and-latency | Scalability and Maintainability Rules | Judges performance and scalability claims; no data-correctness findings. |
| `data-intensive-apps-idempotency-hardener` | sonnet | Makes one handler retry-safe and adds its duplicate-delivery test | idempotent-handlers, data-path-tests | Idempotency and Replay Rules; Code Generation Rules; Testing Rules | Changes production code in a handler; `data-intensive-apps-data-test-writer` writes only tests. |
| `data-intensive-apps-schema-migrator` | sonnet | Carries out a contract change in expand, migrate, contract steps | encoding-and-evolution | Schema Evolution Rules; Encoding and Data Flow Rules; Code Generation Rules | One contract change in staged releases; no handler changes. |
| `data-intensive-apps-derived-view-builder` | sonnet | Makes a projection, cache or index rebuildable and observable | derived-data | Derived Data Rules; Code Generation Rules | Edits the derivation path only. |
| `data-intensive-apps-data-test-writer` | sonnet | Writes duplicate, reorder, replay, conflict, compatibility and rebuild tests | data-path-tests | Testing Rules | Tests only; never edits production code. |

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
| `data-intensive-apps-write-acknowledgment` / `data-intensive-apps-idempotent-handlers` | What the caller is told and may do after a timeout versus making a receiver safe to run twice. | both |
| `data-intensive-apps-write-acknowledgment` / `data-intensive-apps-transactions-and-isolation` | The meaning of success and unknown outcome versus atomicity scope and anomalies. | both |
| `data-intensive-apps-write-acknowledgment` / `data-intensive-apps-faults-and-coordination` | Ack levels and recovery of a write versus clocks, leases and the fault model. | wording |
| `data-intensive-apps-consistency-contract` / `data-intensive-apps-replication-topology` | The promise to readers versus the replica mechanism. | both |
| `data-intensive-apps-consistency-contract` / `data-intensive-apps-transactions-and-isolation` | What readers may see after the write and how two clients' updates to one record are detected and resolved, versus races and anomalies between concurrent transactions. Both bodies prescribe a version or compare-and-set for lost updates, so the descriptions say which side owns the scope: `data-intensive-apps-consistency-contract` for who sees what and conflicts across clients or regions, `data-intensive-apps-transactions-and-isolation` for check-then-write inside a transaction. | both |
| `data-intensive-apps-source-of-truth` / `data-intensive-apps-derived-data` | Who owns the fact versus keeping a copy rebuildable and visible. | both |
| `data-intensive-apps-source-of-truth` / `data-intensive-apps-service-boundaries` | A dataset's owner versus how services are cut and call each other. | `data-intensive-apps-service-boundaries` |
| `data-intensive-apps-idempotent-handlers` / `data-intensive-apps-ordering-scope` | Same input twice versus inputs in the wrong order. | both |
| `data-intensive-apps-idempotent-handlers` / `data-intensive-apps-stream-processing` | Making one handler safe versus time, windows and delivery guarantees across a pipeline. | `data-intensive-apps-stream-processing` |
| `data-intensive-apps-event-design` / `data-intensive-apps-encoding-and-evolution` | What an event means and carries versus how any payload changes over time. | both |
| `data-intensive-apps-event-design` / `data-intensive-apps-stream-processing` | The contract of the event versus the processor that consumes it. | `data-intensive-apps-event-design` |
| `data-intensive-apps-batch-jobs` / `data-intensive-apps-stream-processing` | Bounded rerunnable input versus unbounded input with time semantics. | both |
| `data-intensive-apps-derived-data` / `data-intensive-apps-stream-processing` | Keeping a copy repairable versus the processor semantics (windows, CDC, event sourcing). | wording |
| `data-intensive-apps-partitioning-locality` / `data-intensive-apps-storage-and-indexing` | Which node holds the data versus how a node finds it. | wording |
| `data-intensive-apps-partitioning-locality` / `data-intensive-apps-load-and-latency` | Choosing the key and skew versus proving the bottleneck with numbers. | `data-intensive-apps-load-and-latency` |
| `data-intensive-apps-data-model-choice` / `data-intensive-apps-storage-and-indexing` | Shape and query style versus engine and index structure. | both |
| `data-intensive-apps-replication-topology` / `data-intensive-apps-faults-and-coordination` | Data copies and failover versus leases, locks and consensus. | both |
| `data-intensive-apps-transactions-and-isolation` / `data-intensive-apps-faults-and-coordination` | Atomicity and isolation versus mutual exclusion under pauses and clock error. | wording |
| `data-intensive-apps-service-boundaries` / `data-intensive-apps-encoding-and-evolution` | Where the line is drawn versus how messages across it change. | `data-intensive-apps-service-boundaries` |
| `data-intensive-apps-data-path-tests` / every rule skill | Test cases for duplicates, order, replay, conflicts, compatibility and rebuild versus the design rule itself. | wording (it fires on test-writing requests only) |
| `principles` / every topical skill | The hub routes and holds no cluster rules; a topical skill holds the rules. They may load together by design. | wording |

Manual pairs: `review` / `audit` (a change versus a tree), `checklist` / `data-intensive-apps-final-gate` (interactive walk with next actions versus isolated PASS or FAIL with evidence), `plan` / `data-intensive-apps-write-path-trace` (a change not yet made versus a path that exists), `data-intensive-apps-write-path-trace` / `data-intensive-apps-replay-drill` (a synchronous write through several stores versus redelivered work through one consumer or job), `data-intensive-apps-consistency-check` / `data-intensive-apps-consistency-reviewer` (every read path in a scope versus a diff), `data-intensive-apps-compat-matrix` / `data-intensive-apps-evolution-reviewer` (build the matrix before the change versus judge a diff), `data-intensive-apps-ownership-map` / `data-intensive-apps-ownership-reviewer` (inventory versus a diff), `data-intensive-apps-invariant-map` / `data-intensive-apps-transaction-reviewer` (start from invariants versus start from a diff), `fix` / the four implementers (any finding list versus one kind of change each).

Maintenance: skill and agent pairs restate one procedure on purpose, because an agent must be self-contained and cannot rely on its preloaded skill being present. Change both copies in the same edit: `data-intensive-apps-idempotent-handlers` / `data-intensive-apps-idempotency-hardener`, `data-intensive-apps-encoding-and-evolution` / `data-intensive-apps-schema-migrator`, `data-intensive-apps-derived-data` / `data-intensive-apps-derived-view-builder`, `data-intensive-apps-data-path-tests` / `data-intensive-apps-data-test-writer`.

## Coverage check against the upstream sections

Generated from `docs/TRACEABILITY.md` when the plugin was built; the `###` headings (Source of Truth, Write Semantics, Event Design, Isolation and Invariants and the four forbidden patterns) are cited by the skills named in the ownership tables above.

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | explain-rule, principles, mentor (style) |
| Primary Directive | explain-rule, plan, principles, source-of-truth, write-acknowledgment, write-path-trace, lead, data-intensive-apps-write-path-reviewer, contract-first (style) |
| Reliability Rules | idempotent-handlers, write-acknowledgment, write-path-trace, data-intensive-apps-write-path-reviewer, failure-first (style) |
| Scalability and Maintainability Rules | load-and-latency, data-intensive-apps-capacity-reviewer |
| Data Model and Storage Rules | data-model-choice, ownership-map, source-of-truth, data-intensive-apps-ownership-reviewer, data-intensive-apps-storage-reviewer |
| Query Model and Data Shape Rules | data-model-choice, data-intensive-apps-storage-reviewer |
| Storage Engine and Indexing Rules | storage-and-indexing, data-intensive-apps-storage-reviewer |
| Consistency Rules | consistency-check, consistency-contract, data-intensive-apps-consistency-reviewer |
| Idempotency and Replay Rules | idempotent-handlers, replay-drill, data-intensive-apps-idempotency-hardener, data-intensive-apps-idempotency-reviewer, failure-first (style) |
| Ordering Rules | ordering-scope, replay-drill, data-intensive-apps-ordering-reviewer |
| Event, Log, and Stream Rules | event-design, stream-processing, data-intensive-apps-stream-reviewer |
| Schema Evolution Rules | compat-matrix, encoding-and-evolution, data-intensive-apps-evolution-reviewer, data-intensive-apps-schema-migrator, pair (style) |
| Encoding and Data Flow Rules | compat-matrix, encoding-and-evolution, service-boundaries, data-intensive-apps-evolution-reviewer, data-intensive-apps-schema-migrator, data-intensive-apps-service-boundary-reviewer |
| Partitioning and Locality Rules | partitioning-locality, data-intensive-apps-partitioning-reviewer |
| Replication Rules | consistency-check, replication-topology, data-intensive-apps-replication-reviewer |
| Transaction Rules | invariant-map, transactions-and-isolation, write-path-trace, data-intensive-apps-transaction-reviewer |
| Derived Data Rules | derived-data, ownership-map, data-intensive-apps-derived-view-builder, data-intensive-apps-ownership-reviewer |
| Distributed Fault, Clock, and Consensus Rules | faults-and-coordination, write-acknowledgment, data-intensive-apps-fault-model-reviewer |
| Batch and Stream Processing Rules | batch-jobs, replay-drill, stream-processing, data-intensive-apps-batch-reviewer, data-intensive-apps-stream-reviewer |
| API and Service Boundary Rules | service-boundaries, data-intensive-apps-service-boundary-reviewer |
| Review Rules | audit, derived-data, fix, ordering-scope, partitioning-locality, principles, review, transactions-and-isolation, data-intensive-apps-final-gate, data-intensive-apps-idempotency-reviewer, data-intensive-apps-ordering-reviewer, data-intensive-apps-partitioning-reviewer, strict-reviewer (style) |
| Forbidden Patterns | audit, principles, review, data-intensive-apps-final-gate, strict-reviewer (style) |
| Code Generation Rules | fix, plan, principles, data-intensive-apps-derived-view-builder, data-intensive-apps-idempotency-hardener, data-intensive-apps-schema-migrator, contract-first (style), pair (style) |
| Testing Rules | batch-jobs, data-path-tests, fix, plan, replay-drill, data-intensive-apps-batch-reviewer, data-intensive-apps-data-test-writer, data-intensive-apps-idempotency-hardener, data-intensive-apps-test-gap-reviewer, failure-first (style) |
| Review Checklist | audit, checklist, principles, review, service-boundaries, data-intensive-apps-final-gate, lead, terse (style) |
| Final Instruction | checklist, plan, principles, lead, mentor (style) |

## Overlap review

Pairs that were close and how they were separated:

- `data-intensive-apps-write-acknowledgment` and `data-intensive-apps-idempotent-handlers`: caller side (what a response or a timeout means, what to do next) versus receiver side (what a second delivery does). Both mention an idempotency key, but the first only as the means to resolve an unknown outcome and the second as the design of the dedup record.
- `data-intensive-apps-consistency-contract` and `data-intensive-apps-replication-topology`: the first never discusses topology; the second never decides what the product needs. Read-your-writes appears in both, once as a contract line item and once as the routing mechanism that provides it.
- `data-intensive-apps-source-of-truth` and `data-intensive-apps-derived-data`: ownership versus repairability. `data-intensive-apps-ownership-reviewer` uses both skills but reports one ledger, so there is no second reviewer for derived data.
- `data-intensive-apps-transactions-and-isolation` and `data-intensive-apps-write-acknowledgment`: the first is about atomicity of one operation (what commits together, which anomalies can race), the second about the meaning of the answer returned to a caller and recovery after an unknown outcome.
- `data-intensive-apps-batch-jobs` and `data-intensive-apps-stream-processing`: reruns of bounded input versus time semantics of unbounded input. Both cite the upstream section on source-to-sink guarantees, each for its own kind of path.
- `data-intensive-apps-write-path-trace` and `data-intensive-apps-replay-drill`: the first starts at a request that writes; the second at a message, job or event that is delivered more than once.
- `data-intensive-apps-write-path-reviewer` and `data-intensive-apps-idempotency-reviewer`: the first reports state after each step of one write; the second reports a handler's behavior when the same input is delivered again.
- `data-intensive-apps-write-path-reviewer` and `data-intensive-apps-transaction-reviewer`: both fire on a handler that writes a store and then publishes or calls out. The first reports what is durable and visible after each step and what the caller is told; the second reports which invariants a concurrent transaction can break and whether the atomicity scope is stated and repaired. Each description names the other, and each Constraints line hands the other's concern over.
- `data-intensive-apps-data-path-tests` and `data-intensive-apps-test-gap-reviewer` and `data-intensive-apps-data-test-writer`: rules for the six test classes, the read-only map of gaps, and the writer of the missing tests. The hardener adds only the duplicate-delivery test for the handler it changed.
- `data-intensive-apps-ownership-reviewer` and `data-intensive-apps-storage-reviewer`: ownership and repair versus fit of model, index and layout to workload.
