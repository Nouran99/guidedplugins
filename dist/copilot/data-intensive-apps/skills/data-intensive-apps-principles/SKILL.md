---
name: "data-intensive-apps-principles"
description: "Applies the Designing Data-Intensive Applications rule set to data-system work. Use for any task that changes how data is stored, copied, retried, ordered, versioned, replicated or processed, where ownership, consistency or failure behavior matter."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Designing Data-Intensive Applications principles

Data systems are defined by trade-offs. When you cannot tell what a piece of code promises about its data, write the promise down instead of hiding it behind an abstraction.

## When the rules apply

- You change a write path: a handler that writes to a database and also publishes a message, fills a cache, indexes a document or calls another service.
- You add or change a cache, index, search copy, read model, warehouse table or denormalized field.
- You add retries, jobs, consumers, queues, change data capture or stream processing.
- You change a schema, API, message, event, enum or status, or roll out a version that must live next to the old one.
- You read from replicas, choose a partition key, take a lock or lease, or compare timestamps from different machines.
- You review a design or diff where correctness depends on who owns the truth, what a reader may see, or what happens on a duplicate, a reordering or a partial failure.
- Not for: readability of local code (`clean-code`), module depth and interface shape (`philosophy-of-design`), dependency direction between layers (`clean-architecture`), domain language and aggregates (`ddd`, `ddd-implementing`), timeouts, circuit breakers and deployment safety as operational patterns (`release-it`), or making an untested legacy path safe to touch (`legacy-code`, `refactoring`). Those books pair well with this one; see the README.

## The bias this rule set corrects

An agent reads a database call, a queue publish and a cache write as three lines that each work, and quietly assumes they happen together, in order, once, and are visible everywhere at once. Production does not behave that way: the process dies between the lines, the broker redelivers, the follower is behind, two writers race, and the old version of the service is still running while the new one rolls out. This rule set asks for the opposite habit. Before you write or approve the code, name the source of truth, what a reader is allowed to see, what a retry does, which ordering is actually required, how the data changes next quarter, and whether each piece of state is durable, cached, derived or ephemeral. Distributed complexity is not removed by hiding it behind local-looking code, so the contract has to be visible in the code and in the tests.

## Loading the rules

1. For every design or code decision, Read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the optional SessionStart hook injects it.

Modal convention: the source says `MUST` is binding, `SHOULD` is a strong default and `MUST NOT` is forbidden. This plugin reads that in practice as follows (its interpretation, not the source's wording): an unqualified rule is a MUST, `Prefer` is a SHOULD, `Do not` and `Never` are MUST NOT, and `Avoid` is MUST NOT unless the rule qualifies it ("as a default", "by default"), in which case it is a strong default. An explicit user override wins. Skills in this plugin keep that strength: where a rule says "Prefer", the skill says "Prefer".

Provenance labels used throughout: unlabelled rules are stated in `full.md`. **Compact rule** marks guidance that appears only in `mini.md` or `nano.md`. **Added judgment** marks this plugin's own heuristics, techniques and numbers; they are not rules of the source and you may set them aside when the code base has a reason.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `data-intensive-apps-lead` (delegate) |
| Review the working diff or named paths | `data-intensive-apps-review` |
| Health picture of a repository across all concerns | `data-intensive-apps-audit` |
| Plan a non-trivial data change before editing | `data-intensive-apps-plan` |
| Resolve specific findings with the smallest change | `data-intensive-apps-fix` |
| Understand one rule, its strength and its exceptions | `data-intensive-apps-explain-rule` |
| Walk the final checklist while working | `data-intensive-apps-checklist` |
| Strict PASS or FAIL before commit or pull request | `data-intensive-apps-final-gate` (delegate) |
| A write returns success, timeout or error and you must say what happened | `data-intensive-apps-write-acknowledgment`, `data-intensive-apps-write-path-trace`, `data-intensive-apps-write-path-reviewer` |
| A claim that something scales, a slow endpoint, a proposal to add nodes or caches | `data-intensive-apps-load-and-latency`, `data-intensive-apps-capacity-reviewer` |
| The same data lives in several places, or nobody owns a dataset | `data-intensive-apps-source-of-truth`, `data-intensive-apps-ownership-map`, `data-intensive-apps-ownership-reviewer` |
| Choosing relational, document, graph or key-value; SQL versus application-side joins | `data-intensive-apps-data-model-choice`, `data-intensive-apps-storage-reviewer` |
| Adding an index, choosing an engine, separating analytics from transactions | `data-intensive-apps-storage-and-indexing`, `data-intensive-apps-storage-reviewer` |
| Stale reads, read-your-writes, conflicting concurrent updates | `data-intensive-apps-consistency-contract`, `data-intensive-apps-consistency-check`, `data-intensive-apps-consistency-reviewer` |
| A handler, consumer, job or webhook that can run twice | `data-intensive-apps-idempotent-handlers`, `data-intensive-apps-replay-drill`, `data-intensive-apps-idempotency-reviewer`, `data-intensive-apps-idempotency-hardener` |
| Events or updates that can arrive out of order, parallel consumers on one key | `data-intensive-apps-ordering-scope`, `data-intensive-apps-ordering-reviewer` |
| Defining a command, event, log topic or view contract | `data-intensive-apps-event-design`, `data-intensive-apps-stream-reviewer` |
| Changing a schema, API, message, enum or status; planning a rolling upgrade | `data-intensive-apps-encoding-and-evolution`, `data-intensive-apps-compat-matrix`, `data-intensive-apps-evolution-reviewer`, `data-intensive-apps-schema-migrator` |
| Choosing a partition or routing key, hot keys, cross-partition work | `data-intensive-apps-partitioning-locality`, `data-intensive-apps-partitioning-reviewer` |
| Leader-follower, multi-leader, leaderless, failover, quorums, replica reads | `data-intensive-apps-replication-topology`, `data-intensive-apps-replication-reviewer` |
| Atomicity, isolation level, check-then-write, writes to several stores | `data-intensive-apps-transactions-and-isolation`, `data-intensive-apps-invariant-map`, `data-intensive-apps-transaction-reviewer` |
| A cache, index, projection or read model that drifts or cannot be rebuilt | `data-intensive-apps-derived-data`, `data-intensive-apps-derived-view-builder`, `data-intensive-apps-ownership-reviewer` |
| Locks, leases, timestamps, leader election, consensus, linearizability claims | `data-intensive-apps-faults-and-coordination`, `data-intensive-apps-fault-model-reviewer` |
| A batch job, ETL, nightly report, backfill | `data-intensive-apps-batch-jobs`, `data-intensive-apps-batch-reviewer` |
| A stream processor, window, stream join, change data capture, event sourcing | `data-intensive-apps-stream-processing`, `data-intensive-apps-stream-reviewer` |
| Splitting or merging services, cross-service calls on a hot path | `data-intensive-apps-service-boundaries`, `data-intensive-apps-service-boundary-reviewer` |
| Tests for consumers, jobs, projections, migrations or schema changes | `data-intensive-apps-data-path-tests`, `data-intensive-apps-test-gap-reviewer`, `data-intensive-apps-data-test-writer` |
| Session-long behavior: teach the reasoning | `data-intensive-apps-mode-mentor` |
| Session-long behavior: ranked findings only | `data-intensive-apps-mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `data-intensive-apps-mode-pair` |
| Session-long behavior: result first, few lines | `data-intensive-apps-mode-terse` |
| Session-long behavior: a data contract card before any data code | `data-intensive-apps-mode-contract-first` |
| Session-long behavior: a failure walk after every proposal | `data-intensive-apps-mode-failure-first` |

### Where the cross-cutting rules are owned

- The ten look-fors of the source's review rules each have one owning skill: ordering assumptions and missing versions by `data-intensive-apps-ordering-scope`; exactly-once assumptions and missing idempotency by `data-intensive-apps-idempotent-handlers`; missing ownership by `data-intensive-apps-source-of-truth`; broken schema evolution by `data-intensive-apps-encoding-and-evolution`; unrepairable side effects and writes to several stores by `data-intensive-apps-transactions-and-isolation`; projections that cannot be rebuilt by `data-intensive-apps-derived-data`; partitioning blind to locality by `data-intensive-apps-partitioning-locality`. `data-intensive-apps-review` and `data-intensive-apps-audit` check all ten.
- The four forbidden patterns: exactly-once wishful thinking (`data-intensive-apps-idempotent-handlers`), a hidden consistency contract (`data-intensive-apps-consistency-contract`), uncoordinated multi-writes (`data-intensive-apps-transactions-and-isolation`), schema drift by accident (`data-intensive-apps-encoding-and-evolution`).
- The code generation defaults (explicit identifiers and ownership, explicit idempotency, explicit versioning or conflict strategy, authoritative versus derived data, rebuildable downstream state, compatibility-aware schema changes, observability of lag, retries and failures) are applied to a design by `data-intensive-apps-plan`, to code by `data-intensive-apps-fix` and the implementers, and stated up front by `data-intensive-apps-mode-contract-first`.
- The six test classes (duplicate delivery, out-of-order handling, replay, conflict resolution, schema compatibility, rebuild or repair) are owned by `data-intensive-apps-data-path-tests`.

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep cleanup within the scope of the task. A rule about data contracts is a reason to name a gap and propose the smallest closing change, not a reason to redesign the storage layer. A single-node application with one database does not need a distributed mechanism it cannot use; apply the rules that its data actually exercises.

## Final checklist

- [ ] The source of truth is explicit.
- [ ] Consistency expectations are explicit.
- [ ] The code is safe under retry or duplicate delivery.
- [ ] Any ordering dependency is explicit and scoped.
- [ ] Derived data can be rebuilt or repaired.
- [ ] Schema evolution was considered.
- [ ] The atomicity scope is honest.
- [ ] Nothing relies on exactly-once wishful thinking.
- [ ] Service boundaries align with data ownership.
- [ ] Lag and failure are observable.

If any answer is no, revise before shipping. When you report the work, say briefly what changed, which tests ran, and any contract you left open on purpose.

## Source

- `Purpose`
- `Primary Directive`
- `Review Rules`
- `Forbidden Patterns`
- `Code Generation Rules`
- `Review Checklist`
- `Final Instruction`
