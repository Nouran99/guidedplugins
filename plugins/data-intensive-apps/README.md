# Designing Data-Intensive Applications

Martin Kleppmann's data-system trade-offs, turned into a Claude Code toolkit. It makes Claude say where the truth lives, what a reader may see, what a retry or a replay does, which ordering is really needed, how a contract changes next quarter, and what happens when a clock, a lock or a replica lets you down, before it writes or approves the code.

Below the overview you will find the generated component list (skills, subagents and output styles), eight usage walkthroughs with exact commands, a map from the rule set's sections to the components, how the plugin pairs with its siblings, and an honest section on what it cannot do.

## Overview

**The book in one paragraph.** *Designing Data-Intensive Applications* argues that the hard part of most modern systems is the data: how much of it there is, how fast it changes, how many places hold a copy, and how many things can fail between a write and the moment someone relies on it. It walks from the foundations (reliability, scalability, maintainability; data models and query languages; storage engines and indexes; encodings and schema evolution) through distributed data (replication, partitioning, transactions, the trouble with networks and clocks, consistency and consensus) to derived data (batch processing, stream processing and the idea of building systems from logs and the views derived from them). Its method is to name the trade-off in every choice instead of hiding it behind a product name.

**Who this is for.** Developers using Claude Code on services that store, move or copy data: web backends with a database and a queue, event-driven systems, pipelines, search and caching layers, anything with more than one process writing or reading the same facts. The rules matter most for changes that look small (one more consumer, one more cache, one renamed field) and fail only under retries, restarts, lag and rolling deploys.

**The bias it corrects.** An agent reads a database call, a queue publish and a cache write as three lines that each work, and assumes they happen together, in order, once, and are visible everywhere at once. Production breaks each assumption: the process dies between the lines, the broker redelivers, the follower is behind, two writers race, and the old version of the service is still running while the new one rolls out. This toolkit pushes the opposite habit: write the contract down first (source of truth, visibility, retry behavior, ordering scope, evolution path, durable versus derived state), then write the code and the test that keep it.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/data-intensive-apps:principles`) that loads the compact rules first, the full rules only when needed, labels where each statement comes from, and routes every situation to a specific skill, agent or mode.
- Nineteen topical skills, one per decision a data-system author makes: write acknowledgment, load and latency, source of truth, data model, storage and indexing, consistency, idempotency, ordering, event design, encoding and evolution, partitioning, replication, transactions and isolation, derived data, faults and coordination, batch jobs, stream processing, service boundaries and data-path tests. Each states when it applies, how to check it, what to do instead, and where the source itself allows an exception.
- Workflows that follow what the rule set tells an author to do: `consistency-check`, `write-path-trace`, `compat-matrix`, `replay-drill`, `ownership-map` and `invariant-map`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- Sixteen read-only specialist reviewers, each with its own report shape (a write-path gap ledger, an invariant table with the breaking interleaving, a handler ledger, a compatibility matrix, a dataset ledger, an assumption ledger), four implementers that make small test-backed changes, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `contract-first` and `failure-first`.

**Provenance labels.** The rule set in `skills/principles/references/full.md` is the canonical source. A statement with no label is stated there. **Compact rule** marks guidance found only in the shorter `mini.md` or `nano.md` files (for example fencing a stale lock holder). **Added judgment** marks this plugin's own techniques and numbers (outbox rows, expand-and-contract releases, index column order, any threshold). Nothing in the toolkit presents a plugin heuristic as a rule of the book.

**When not to use it.** Reach for a different book when the real risk lies elsewhere: readability of local code (a Clean Code plugin), module depth and interfaces (a software-design plugin), dependency direction between layers (a Clean Architecture plugin), domain language and aggregates (the DDD plugins), operational patterns such as timeouts and circuit breakers (a release-engineering plugin), or making untested legacy code safe to touch (a legacy-code plugin). For a single-node application with one database and no copies, retries or contracts, most of this toolkit has nothing to say, and the `lead` agent will tell you so.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install data-intensive-apps@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/data-intensive-apps
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall data-intensive-apps@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**60 components:** 32 skills (20 Claude can load on its own, 12 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/data-intensive-apps:batch-jobs` | Use when writing or reviewing a batch job, ETL, nightly report, backfill, reprocessing run or MapReduce-style pipeline. Makes inputs and outputs recomputable and keeps side effects out of replayable work. Event-time str… |
| `/data-intensive-apps:consistency-contract` | Use when reads may be stale, a user must see their own write, caches or replicas serve reads, or two clients may edit one record. Makes freshness, visibility and conflict handling a contract. Races inside one transactio… |
| `/data-intensive-apps:data-model-choice` | Use when picking or reviewing a data model or query style: relational, document, graph, key-value or analytical; schema shape; SQL versus application-side joins. Index and engine choice is storage-and-indexing. |
| `/data-intensive-apps:data-path-tests` | Use when writing or reviewing tests for consumers, jobs, handlers, projections, migrations or schema changes. Covers duplicate delivery, out-of-order messages, replay, conflict resolution, schema compatibility and rebui… |
| `/data-intensive-apps:derived-data` | Use when adding or changing a cache, search index, read model, projection, materialized view or denormalized field, or when one is stale, drifting or cannot be rebuilt. Defines propagation, lag visibility and rebuild. W… |
| `/data-intensive-apps:encoding-and-evolution` | Use when changing a schema, column, API field, message, enum or status value, choosing JSON, Protocol Buffers, Avro or Thrift, or planning a rolling upgrade across old and new readers and writers. Event meaning and ids … |
| `/data-intensive-apps:event-design` | Use when defining or changing a command, event, log topic or materialized view contract, or the consumers of a durable log. Separates commands from facts and sets identifiers, metadata and versions. Payload compatibilit… |
| `/data-intensive-apps:faults-and-coordination` | Use when code relies on timeouts, wall-clock timestamps, locks, leases, leader election, majority votes, coordination services or consensus, or claims linearizability. Requires a fault model, monotonic clocks and fencin… |
| `/data-intensive-apps:idempotent-handlers` | Use when code may run twice: command handlers, queue consumers, jobs, webhooks, retried calls, or any exactly-once claim. Applies deduplication keys and idempotent state transitions. Event order is ordering-scope; a cal… |
| `/data-intensive-apps:load-and-latency` | Use when someone claims a design will scale, proposes more nodes, caches or sharding for speed, or reports slowness. Demands load parameters, percentile latency and a named bottleneck first. Skewed keys are partitioning… |
| `/data-intensive-apps:ordering-scope` | Use when events or updates for one entity can arrive out of order, parallel consumers touch the same key, code assumes global order, or last write wins by arrival. Scopes ordering per key or partition and adds versions.… |
| `/data-intensive-apps:partitioning-locality` | Use when choosing a partition, shard or routing key, spreading data across nodes, handling hot keys or skew, or seeing queries and transactions that cross partitions. Colocates data and work by the key that drives consi… |
| `/data-intensive-apps:principles` | Applies the Designing Data-Intensive Applications rule set to data-system work. Use for any task that changes how data is stored, copied, retried, ordered, versioned, replicated or processed, where ownership, consistenc… |
| `/data-intensive-apps:replication-topology` | Use when choosing or reviewing leader-follower, multi-leader or leaderless replication, sync versus async followers, failover, quorums, replica read routing or replica conflict resolution. Freshness promises are consist… |
| `/data-intensive-apps:service-boundaries` | Use when splitting or merging services, designing an API between services or teams, or adding a cross-service call on a hot path. Aligns boundaries with data ownership. One dataset's owner is source-of-truth; wire forma… |
| `/data-intensive-apps:source-of-truth` | Use when the same data lives in several places, a cache or copy is written directly, two services update one fact, or ownership is unclear. Names the primary owner, derived copies, update path and repair. Rebuilding a c… |
| `/data-intensive-apps:storage-and-indexing` | Use when adding or reviewing an index, choosing between LSM-tree and B-tree engines, separating OLTP from analytics, or tuning write-heavy or scan-heavy tables. Covers secondary index cost, columnar layouts and memory r… |
| `/data-intensive-apps:stream-processing` | Use when writing or reviewing a stream processor, windowed aggregate, stream join, change data capture or event sourcing. Sets event, processing and ingestion time, windows, lateness, state, checkpoints and guarantees. … |
| `/data-intensive-apps:transactions-and-isolation` | Use when a change must be atomic across rows or systems, an isolation level is chosen, a check-then-write may race (lost update, write skew, phantom), or a handler writes several stores or sends effects around a commit.… |
| `/data-intensive-apps:write-acknowledgment` | Use when a write, command or request ends in success, timeout or error and you must say what happened: accepted, persisted, applied or durable, including unknown outcomes. Run-twice receivers are idempotent-handlers; at… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/data-intensive-apps:audit` | Scan a directory or repository for data-contract health in a forked context and return concerns rated healthy, watch or hot, with ranked hot spots, in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/data-intensive-apps:checklist` | Walk the ten-item review checklist for the current change one item at a time, with evidence and a next action for each no. | `[paths \| git ref \| empty for the current diff]` |
| `/data-intensive-apps:compat-matrix` | Build the old-and-new compatibility matrix for one schema, API, message or enum change and order the rollout so no reader meets a form it cannot read. | `[change description \| migration or schema path \| empty to use the contract files in the current diff]` |
| `/data-intensive-apps:consistency-check` | Map every read path in a scope to its freshness need, where it is served from and the guarantee it gets, plus the conflict model for concurrent writes, in a forked context and at most 40 lines. | `[feature \| directory \| entity name \| empty for the repository root]` |
| `/data-intensive-apps:explain-rule` | Explain one rule of the Designing Data-Intensive Applications rule set: its modal strength, the reason, how to check it, a small example and where the source allows an exception. | `[rule name \| section name \| phrase \| empty to list the sections]` |
| `/data-intensive-apps:fix` | Resolve named data-contract findings with the smallest change per finding, run the tests, never commit, and stop to ask before any contract or stored-data change. | `[findings text \| path to a findings file \| finding numbers from the last review]` |
| `/data-intensive-apps:invariant-map` | List the business invariants in a scope, the mechanism that enforces each, the isolation in effect and the anomaly still possible (lost update, write skew, phantom), in a forked context and at most 40 lines. | `[module \| feature \| invariant in words \| empty for the repository root]` |
| `/data-intensive-apps:ownership-map` | Inventory the datasets in a scope with their class, owner, writers, derived copies, propagation, lag visibility and rebuild path, in a forked context and at most 40 lines. | `[directory \| service name \| dataset name \| empty for the repository root]` |
| `/data-intensive-apps:plan` | Plan a non-trivial change to a data path before editing: the five questions, touched concerns, rollout order, tests and observability. | `[change description \| issue text \| empty to plan from the current diff]` |
| `/data-intensive-apps:replay-drill` | Walk one consumer, job or handler through duplicate, reordered, late, crash, restart and full-replay scenarios by reading the code, and report the predicted outcome of each. | `[consumer \| job \| handler path or name \| empty for the one in the current diff]` |
| `/data-intensive-apps:review` | Review a diff or paths against the Designing Data-Intensive Applications rules and report ranked findings by data concern. | `[paths \| git ref \| empty for the current diff]` |
| `/data-intensive-apps:write-path-trace` | Follow one write step by step and record what is durable and visible after each step, what a crash or timeout there leaves behind, how a retry behaves and how the state is repaired. | `[handler \| endpoint \| file:function \| empty to trace the write path in the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-data-intensive-apps:batch-reviewer` | sonnet | read-only | Reviewer of batch jobs: rerun safety, input versioning, atomic output publication, side effects inside replayable steps and partial-failure behavior. Use proactively after edits to ETL, scheduled rep… |
| `@agent-data-intensive-apps:capacity-reviewer` | sonnet | read-only | Reviewer of performance and scalability claims: load parameters, percentile latency, named bottleneck, evidence and operability of new components. Use when a change or design claims to scale, adds no… |
| `@agent-data-intensive-apps:consistency-reviewer` | sonnet | read-only | Reviewer of the consistency contract: freshness needs per read path, read-your-writes expectations, staleness tolerance and conflict handling for concurrent updates. Use proactively after edits that … |
| `@agent-data-intensive-apps:data-test-writer` | sonnet | can edit files | Implementer of tests only: writes duplicate-delivery, out-of-order, replay, conflict, schema-compatibility and rebuild tests for existing data-path behavior. Use when test-gap-reviewer reports missin… |
| `@agent-data-intensive-apps:derived-view-builder` | sonnet | can edit files | Implementer that makes one cache, index, projection or read model rebuildable, with a checkpoint, a lag metric and a rebuild entry point. Use when ownership-reviewer or ownership-map flagged a derive… |
| `@agent-data-intensive-apps:evolution-reviewer` | sonnet | read-only | Reviewer of contract changes: schema, column, API, message, enum and encoding changes against old readers, old writers, stored data and in-flight messages. Use proactively after edits to migrations, … |
| `@agent-data-intensive-apps:fault-model-reviewer` | sonnet | read-only | Reviewer of fault assumptions: timeouts, wall-clock use, locks, leases, leader election, majorities, coordination services and linearizability claims. Use proactively after edits that add a lock, lea… |
| `@agent-data-intensive-apps:final-gate` | sonnet | read-only | Pre-merge gate that runs the ten-item data-intensive checklist against the working diff and returns PASS or FAIL with evidence per item. Use before declaring a data-path change done, committing, or o… |
| `@agent-data-intensive-apps:idempotency-hardener` | sonnet | can edit files | Implementer that makes one retry-unsafe handler, consumer or job safe to run twice, with a dedup key or idempotent transition and its duplicate-delivery test. Use when idempotency-reviewer or a repla… |
| `@agent-data-intensive-apps:idempotency-reviewer` | sonnet | read-only | Reviewer of handlers that can run more than once: consumers, jobs, webhooks, retried commands. Reports effects, dedup mechanism and the result of duplicate delivery and replay. Use proactively after … |
| `@agent-data-intensive-apps:lead` | opus | read-only | Triage lead for data-intensive work. Use first on any non-trivial change or review that touches storage, messaging, replication, schemas or transactions, to decide which specialists and skills apply,… |
| `@agent-data-intensive-apps:ordering-reviewer` | sonnet | read-only | Reviewer of ordering assumptions: what order the logic needs, the scope the transport provides, consumer concurrency per key and version or sequence handling. Use proactively after edits to event con… |
| `@agent-data-intensive-apps:ownership-reviewer` | sonnet | read-only | Reviewer of data ownership and derived copies: primary owner, other writers, caches, indexes and projections, propagation, lag visibility and rebuild path. Use proactively after edits that add or wri… |
| `@agent-data-intensive-apps:partitioning-reviewer` | sonnet | read-only | Reviewer of partition and routing keys: whether common operations stay on one partition, hot-key and skew risk, cross-partition cost, secondary-index placement and rebalancing. Use when a change adds… |
| `@agent-data-intensive-apps:replication-reviewer` | sonnet | read-only | Reviewer of replication design: leader-follower, multi-leader or leaderless choice, sync versus async, failover behavior, quorum claims, read routing and replica conflict resolution. Use when a chang… |
| `@agent-data-intensive-apps:schema-migrator` | sonnet | can edit files | Implementer that carries out one contract change (rename, retype, split, enum or format change) as staged expand, migrate and contract steps with compatibility tests. Use when evolution-reviewer or c… |
| `@agent-data-intensive-apps:service-boundary-reviewer` | sonnet | read-only | Reviewer of service boundaries and cross-service contracts: data ownership per service, chatty hot-path calls, split invariants and contract identifiers, versions and failure semantics. Use when a ch… |
| `@agent-data-intensive-apps:storage-reviewer` | sonnet | read-only | Reviewer of data model, index and storage-layout fit: relational versus document versus graph, indexes versus write cost, OLTP versus analytical load, application-side joins, memory residency. Use pr… |
| `@agent-data-intensive-apps:stream-reviewer` | sonnet | read-only | Reviewer of stream processors and event contracts: event, processing and ingestion time, windows, lateness, state and checkpoints, delivery guarantees, change data capture and event definitions. Use … |
| `@agent-data-intensive-apps:test-gap-reviewer` | sonnet | read-only | Reviewer of tests for data paths: finds missing duplicate, out-of-order, replay, conflict, compatibility and rebuild tests for the behavior a change adds. Use proactively after edits to consumers, jo… |
| `@agent-data-intensive-apps:transaction-reviewer` | sonnet | read-only | Reviewer of atomicity scope, isolation and multi-store writes: invariants versus anomalies (lost update, write skew, phantom), dual writes and effects around a commit. Use proactively after edits wit… |
| `@agent-data-intensive-apps:write-path-reviewer` | sonnet | read-only | Reviewer of write paths: what is durable and visible after each step, what a crash or timeout leaves behind, and what the caller is told. Use proactively after edits to handlers or jobs that write a … |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style data-intensive-apps:contract-first` | Before any data code or design, prints a data contract card answering the five basic questions, marks unanswered ones OPEN, and does not decide correctness-critical OPEN items silently. |
| `/output-style data-intensive-apps:failure-first` | After proposing any change that writes data, handles messages, keeps a copy or changes a contract, shows a failure walk of scenarios, outcomes and guards before the code. |
| `/output-style data-intensive-apps:mentor` | Teaches the data-system rule behind each decision, names the trade-off, and ends non-trivial answers with one check-for-understanding question. |
| `/output-style data-intensive-apps:pair` | Works in small narrated steps and asks before any change larger than a few lines or one that touches a data contract: schema, message shape, public API, partition key or isolation setting. |
| `/output-style data-intensive-apps:strict-reviewer` | Answers as a ranked findings table against the data-intensive rules, never rewrites code unless asked, and says No findings explicitly when clean. |
| `/output-style data-intensive-apps:terse` | Gives the result first in a few lines with no preamble, adds a one-line data-contract note only when a gap exists, and still shows failing output in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** The `lead` agent reads a task or diff and names, in at most five steps, which specialists apply and in what order. The reviewers each own one concern and report in their own shape, handing anything outside their concern to a named sibling. The four implementers (`idempotency-hardener`, `schema-migrator`, `derived-view-builder`, `data-test-writer`) make one kind of change at a time, run the project's tests, and never commit. The `final-gate` agent closes the loop with a PASS or FAIL against the ten-item checklist. The workflows (`review`, `plan`, `fix` and the six book-specific ones) are the slash commands you run yourself, and the topical skills are what Claude loads by description while it works. The design map in `docs/DESIGN.md` lists every component with the reason it is not a duplicate of its nearest sibling.

## Usage walkthroughs

### 1. Review a pull request that adds a queue consumer

The change adds a consumer for `PaymentCaptured` messages that adds the amount to a daily revenue row and sends a receipt email.

```text
Use the data-intensive-apps:lead agent on my working diff.
```

`lead` classifies the diff (a write plus an email around a commit, redelivery, tests) and returns a short ordered plan. For this change it typically names `data-intensive-apps:transaction-reviewer` first (the receipt is sent around the commit), then `data-intensive-apps:idempotency-reviewer`, with `data-intensive-apps:final-gate` last, and says why it skips ordering (adding amounts commutes). The transaction reviewer hands redelivery of the consumer to the idempotency reviewer, so this walkthrough continues with that step:

```text
Use the data-intensive-apps:idempotency-reviewer agent on the working diff.
```

You get a handler ledger: the handler, how it receives work, its effects, its guard (none), and the result of a duplicate delivery (revenue counted twice, two receipts) and of a replay. The finding is a blocker with the smallest fix, and a hand-off line pointing to `data-intensive-apps:idempotency-hardener`. Ask for the fix:

```text
Use the data-intensive-apps:idempotency-hardener agent on the blocker in consumer/payments.py.
```

The hardener finds the test command, records the baseline, writes the duplicate-delivery test first and confirms it fails, records the event id in the same transaction as the revenue update, turns the receipt into an outbox row with a key derived from the order, writes an additive migration file without applying it, runs the tests and reports what it left alone. It does not commit. Finish with the gate:

```text
Use the data-intensive-apps:final-gate agent on my current changes.
```

### 2. Plan a rename that must survive a rolling deploy

You want to rename `contacts.phone` to `contacts.phone_number` in a service that runs several instances and consumes a queue.

```text
/data-intensive-apps:plan rename contacts.phone to phone_number without downtime
```

You get a plan, not edits: the five questions answered or marked OPEN, the concerns touched (encoding and evolution, tests), the rollout in steps that are each safe to stop after, the tests to add, and a line saying that the compatibility matrix is built by `/data-intensive-apps:compat-matrix`. Build it:

```text
/data-intensive-apps:compat-matrix rename contacts.phone to phone_number
```

It finds the writers, readers, stored rows and retained messages, fills the old-by-new matrix (a one-release rename breaks wherever old and new meet), proposes expand, migrate and contract as separate releases with the cleanup condition, and lists the tests for both directions and for unknown values. Then hand the first stage over:

```text
Use the data-intensive-apps:schema-migrator agent on the plan above.
```

It writes the compatibility tests first, implements the expand stage (write both fields, read either), writes the backfill without running it, and records the contract stage as a follow-up with its condition instead of dropping the old column. When the diff is ready, `data-intensive-apps:evolution-reviewer` judges it.

### 3. Learn the reasoning while you work

You are onboarding someone, or yourself, and want the rule behind each choice.

```text
/output-style data-intensive-apps:mentor
/data-intensive-apps:explain-rule exactly-once
```

In `mentor` mode every answer does the task first, adds a short **Why** block naming the rules used and the failure each prevents, and ends with one check question about the code at hand. `explain-rule` takes one rule and prints its strength (MUST NOT for "never assume exactly-once delivery unless the boundary provides it and the design proves it", with the source's own verb), the reason, how to check it, a small original example, the exceptions the source gives, and which skill and reviewer apply it.

### 4. Audit a repository, then map who owns what

You inherit a service with a database, a search index and several jobs, and want to know where the data contracts are weakest.

```text
/data-intensive-apps:audit src
```

`audit` runs in a forked context and returns at most 40 lines: each concern rated healthy, watch, hot or unknown with `file:line` evidence, and at most five hot spots ranked by what a normal failure would cost. Suppose the top finding is a search index written inline with errors ignored. Its `Next step` points at the ownership inventory:

```text
/data-intensive-apps:ownership-map src
```

You get a table of datasets with class (primary, derived, cache, ephemeral), writers, propagation, lag signal and rebuild path, and flags such as "derived, written inline, no rebuild, no lag". Fix the worst flag:

```text
Use the data-intensive-apps:derived-view-builder agent on product_search.
```

It makes the application write the source only, adds a projector with a checkpoint and an idempotent apply, exposes lag, writes a rebuild that builds a fresh index and switches, and tests that a rebuild equals the incrementally maintained copy. Review the result with `data-intensive-apps:ownership-reviewer`.

### 5. Find where reads can be stale

Users save their display name and sometimes still see the old one.

```text
/data-intensive-apps:consistency-check profile
```

The forked skill maps each read path of the entity to its need (own writes, bounded stale, any), where it is served from and the guarantee it gives, and lists concurrent-writer entities with their conflict policy. You get a row such as `GET /profile | own writes | replica | lag, unbounded | gap`. Pass the gap to `fix`:

```text
/data-intensive-apps:fix GET /profile reads from a replica after a write and the writer must see their own write
```

`fix` runs the covering tests for a baseline, makes the smallest change in the shape `/data-intensive-apps:consistency-contract` describes (for example route the writer's reads by a log position or to the primary), adds a test, and does not commit. Because read routing is not a contract change it does not stop to ask; a schema or message change would. Then `data-intensive-apps:consistency-reviewer` reviews the diff.

### 6. Review, fix and gate a handler that writes two stores

A pull request saves an order and then publishes an event, ignoring publish errors.

```text
/data-intensive-apps:review
```

`review` classifies the change (write path, several stores), applies the ten look-fors and four forbidden patterns, and prints ranked findings: for example a blocker for the event that can be lost between commit and publish (rule: no side effects outside the transactional boundary without a repair path). To act on it:

```text
/data-intensive-apps:fix 1
```

The smallest fix is an outbox row written in the same transaction. That needs a new table, which is a stored-schema change, so `fix` stops and asks before touching it, offering the options with one line of consequence each. Once you agree, it writes the change and the test (crash between commit and publish), runs the tests, and reports. Close with the gate:

```text
Use the data-intensive-apps:final-gate agent on my current changes.
```

### 7. Check the invariants a limit relies on

A team must always keep at least one owner. The code counts owners, then demotes one.

```text
/data-intensive-apps:invariant-map team ownership
```

You get an invariant table: the rule in one sentence, how it is enforced (a count and an update in two statements), the isolation in effect (or `unknown`, with where to look), the anomaly still possible (write skew: two owners demote each other and both commit), and the closing mechanism (a conditional update on a shared counter row, or serializable isolation with retry). The skill runs in a forked context, only reads and recommends, and returns at most 40 lines. After the fix is written, `data-intensive-apps:transaction-reviewer` checks the diff with a concrete interleaving for each race it reports.

### 8. Design with the contract on the table

You are about to add a loyalty-points balance that changes when orders ship.

```text
/output-style data-intensive-apps:contract-first
```

Before any code Claude prints a data contract card answering the five questions in at most eight lines and marking unanswered ones `OPEN`. Whether points are earned on shipment or on payment capture, and what a returned order does to them, decide correctness, so Claude stops and asks instead of choosing. For the next feature switch to `/output-style data-intensive-apps:failure-first`: each proposal arrives with a failure walk (crash between steps, duplicate delivery, reordering, unknown outcome, replay, old reader) and the guard for each before the code is shown.

## How it maps to the book

Upstream sections are the `##` headings of `skills/principles/references/full.md`. The generated `docs/TRACEABILITY.md` lists every component that cites each one; the table shows the main applications.

| Upstream section | Where it is applied |
| --- | --- |
| Purpose | `principles` (modal convention), `explain-rule`, `mentor` |
| Primary Directive | `principles`, `plan` (the five questions), `write-path-trace`, `lead`, `contract-first` |
| Reliability Rules | `write-acknowledgment`, `write-path-trace`, `write-path-reviewer`, `failure-first` |
| Scalability and Maintainability Rules | `load-and-latency`, `capacity-reviewer` |
| Data Model and Storage Rules (and Source of Truth) | `source-of-truth`, `data-model-choice`, `ownership-map`, `ownership-reviewer` |
| Query Model and Data Shape Rules | `data-model-choice`, `storage-reviewer` |
| Storage Engine and Indexing Rules | `storage-and-indexing`, `storage-reviewer` |
| Consistency Rules (and Write Semantics) | `consistency-contract`, `consistency-check`, `consistency-reviewer` |
| Idempotency and Replay Rules | `idempotent-handlers`, `replay-drill`, `idempotency-reviewer`, `idempotency-hardener` |
| Ordering Rules | `ordering-scope`, `ordering-reviewer` |
| Event, Log, and Stream Rules (and Event Design) | `event-design`, `stream-processing`, `stream-reviewer` |
| Schema Evolution Rules | `encoding-and-evolution`, `compat-matrix`, `evolution-reviewer`, `schema-migrator` |
| Encoding and Data Flow Rules | `encoding-and-evolution`, `service-boundaries`, `compat-matrix`, `evolution-reviewer` |
| Partitioning and Locality Rules | `partitioning-locality`, `partitioning-reviewer` |
| Replication Rules | `replication-topology`, `replication-reviewer`, `consistency-check` |
| Transaction Rules (and Isolation and Invariants) | `transactions-and-isolation`, `invariant-map`, `transaction-reviewer` |
| Derived Data Rules | `derived-data`, `ownership-map`, `ownership-reviewer`, `derived-view-builder` |
| Distributed Fault, Clock, and Consensus Rules | `faults-and-coordination`, `fault-model-reviewer` |
| Batch and Stream Processing Rules | `batch-jobs`, `stream-processing`, `batch-reviewer`, `stream-reviewer` |
| API and Service Boundary Rules | `service-boundaries`, `service-boundary-reviewer` |
| Review Rules | `review`, `audit`, `final-gate`, `strict-reviewer`; each look-for has one owning skill (`docs/DESIGN.md`) |
| Forbidden Patterns | `idempotent-handlers`, `consistency-contract`, `transactions-and-isolation`, `encoding-and-evolution`, plus `review`, `audit`, `final-gate` |
| Code Generation Rules | `plan`, `fix`, `contract-first`, `pair`, the four implementers |
| Testing Rules | `data-path-tests`, `test-gap-reviewer`, `data-test-writer`, `replay-drill` |
| Review Checklist | `checklist`, `final-gate`, `review`, `terse` |
| Final Instruction | `principles`, `plan`, `lead`, `mentor` |

## Works with other plugins

The upstream compatibility notes in `ciembor/agent-rules-books` compare every pair of books. All five below are rated complementary with this one: they pull on different questions, and the real risk is overlap in an always-on context, not contradiction.

| Plugin | Verdict | Use together when | Prefer which |
| --- | --- | --- | --- |
| `release-it` | Complementary (conflict 28%, overlap 46%, complementarity 80%) | A production service where both data correctness and operational failure behavior matter: retries, queues, caches, jobs and integrations | This plugin for ownership, consistency, ordering, replay, schemas and derived data; `release-it` for timeouts, retry bounds, breakers, bulkheads, overload and deployment. Its operational patterns can mask a data-contract problem if they are applied without the rules here. |
| `ddd-implementing` | Complementary (conflict 10%, overlap 35%, complementarity 80%) | An aggregate, repository, event or integration design that also changes state, events, schemas or ownership | This plugin when consistency, replay, schemas or distributed failure are the hard part; the DDD plugin when the model's language and boundaries are. |
| `clean-architecture` | Complementary (10%, 35%, 80%) | Layered code whose persistence, messaging or projections decide correctness | Source-of-truth and failure semantics first; an abstraction must not hide them. |
| `refactoring` | Complementary (conflict 12%, overlap 38%, complementarity 78%) | Reshaping existing data-handling code toward these goals | The refactoring plugin when observable behavior must stay unchanged; this one for designing new behavior. Scope creep is the tension: design improvement must not override behavior preservation. |
| `legacy-code` | Complementary (12%, 38%, 78%) | Weakly tested code that reads and writes data in risky ways | `legacy-code` first (characterize behavior, find the smallest seam), then this plugin inside the controlled area. |

**Recommended pairing.** For a production service, load this plugin as the on-demand data layer and `release-it` beside it: this plugin's `final-gate` for the data checklist, theirs for production readiness. Make at most one book plugin always-on with `inject_rules`; the rest load their skills by description.

**What to avoid.** Do not run several book plugins' always-on hooks together, and do not let a structural plugin (clean architecture, DDD tactics, patterns) add layers before the source of truth, failure behavior and evolution path are written down. The upstream notes state the conflict that way: the non-data rule sets can improve structure, but data semantics have to be explicit before abstractions hide ownership or failure behavior.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project's own criticism notes say there are no benchmarks or before-and-after task data showing that these rules improve outcomes, and this toolkit inherits that gap. Treat it as structured prompts and checklists, not as a guarantee.
- **Context cost.** Twenty skills are model-invocable, so their descriptions are present every turn. Keep unrelated book plugins disabled for a task, use the manual workflows for heavy scans, and prefer on-demand loading over `inject_rules` unless this is your one primary rule set.
- **The model may ignore rules.** More instructions can compete with each other. The reviewers help by demanding evidence per finding, but they are prompts, not compilers.
- **Book-derived, not incident-derived.** The rules come from a book, not from your outages. The best additions to this toolkit are rules distilled from your own postmortems; there is no mechanism here for collecting them.
- **Overengineering risk.** A strict reading would add keys, versions, outboxes and rebuild jobs to a small application that needs none. The hub, `lead` and the reviewers say to apply only the rules the data actually exercises, and the source itself says to use strong consistency, consensus and distribution only where required, but the judgment of "required" stays yours.
- **Pseudo-compliance.** An agent can write "idempotent" in a comment without a mechanism. The toolkit asks for the mechanism (the key, the transaction, the test) and for a test that fails without it; it cannot verify that the test is meaningful.
- **Static review cannot see runtime configuration.** Isolation levels, broker redelivery and retention, replica routing, consumer concurrency and managed-service defaults often live outside the repository. Reviewers mark these `unknown` and name the setting to check; they do not guess a pass.
- **Tests cannot prove distributed properties.** Fakes can script duplicates and reordering, but only a real engine shows write skew or lock behavior, and nothing here replaces fault-injection in a real environment.
- **Contested ground.** "Avoid distributed transactions as a default" and "never assume exactly-once unless proven" are firm positions in the source; some teams reasonably run two-phase commit or rely on a stream engine's transactional guarantee. The skills say to name the boundary and prove it rather than forbid the claim.
- **Numbers are heuristics.** The source gives no thresholds. Every number in this toolkit (lead times, retention windows, severity bands, search cues in `audit`) is labelled Added judgment and is meant to be replaced by your own.
- **It is a compression of the book.** The upstream rule set is a compact policy distilled from the book. It is not a substitute for reading it, and some background in the skills (how formats resolve schemas, how partitioning and rebalancing behave) is general knowledge, not source text.

## Attribution and license

This plugin is MIT licensed. It is built on the rule sets in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz; the three files in `skills/principles/references/` are unmodified copies of the upstream `designing-data-intensive-applications` rule sets. The skills, subagents and output styles are original work by Nouran Darwish.

It is an unofficial toolkit. It is not affiliated with, endorsed by, or approved by Martin Kleppmann, the book's publisher, or the upstream maintainer, and it does not reproduce the book's text. See [NOTICE.md](NOTICE.md) for the full attribution and the upstream license, and [LICENSE](LICENSE) for this plugin's license. The component map is in [docs/DESIGN.md](docs/DESIGN.md).
