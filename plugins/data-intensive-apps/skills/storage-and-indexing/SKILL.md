---
name: storage-and-indexing
description: "Use when adding or reviewing an index, choosing between LSM-tree and B-tree engines, separating OLTP from analytics, or tuning write-heavy or scan-heavy tables. Covers secondary index cost, columnar layouts and memory residency. Model shape is data-model-choice."
---

# Storage engines and indexing

Matches the way data is laid out and found to the way it is written and read. Which model to use (tables, documents, graph) is `/data-intensive-apps:data-model-choice`; which node holds which key is `/data-intensive-apps:partitioning-locality`; proving that the layout is the bottleneck is `/data-intensive-apps:load-and-latency`.

## When to use

- A pull request adds `CREATE INDEX`, an index annotation or a new query that needs one.
- A table takes heavy inserts and also serves range queries or ordered pages.
- Reports or dashboards run scans and aggregates on the same tables that serve checkout or login.
- Someone proposes an in-memory store, a columnar warehouse or a new engine, or calls a cache "the database".
- A secondary index on a partitioned store is queried by a non-key column.

## Rules

1. **Fit the indexing strategy to how data is written and read, whether range scans occur, what updates cost and how recovery must work.** An index is a trade: faster reads for slower writes and more space. Check: for each index you can name the query it serves and the write rate it taxes.
2. **Choose log-structured storage, SSTables and LSM-tree approaches when high write throughput and sequential writes are what the workload mostly wants.** Check: the workload is write-heavy and the reads can tolerate checking several sorted runs; the engine's compaction cost is understood.
3. **Choose B-tree style indexes when the workload leans on ordered access, point lookups and well-established transactional behavior.** Check: reads need in-place ordered structure and transactional locking or snapshotting from the engine.
4. **Regard each secondary index as its own data structure, with its own write amplification, partitioning and consistency costs.** Every insert now writes more than once, and on a partitioned store the index may be local to each partition (scatter on read) or global (cross-partition on write). Check: you can state how many structures one write touches and where the index lives.
5. **Separate transactional (OLTP) access from analytical workloads; do not expect a single layout to serve both well.** Row-at-a-time transactions and column-wide scans want different shapes. Check: analytical queries do not run on the primary serving transactions without a reason.
6. **Adopt column-oriented storage, compression, sort order, materialized views or cubes only when the analytical access pattern earns them.** Check: the queries scan many rows but few columns, or repeat the same aggregation, before a columnar or precomputed layout is chosen.
7. **State what the design assumes about data held in memory; keeping data there speeds access but does not make it durable.** Check: the design says what survives a restart and how the in-memory state is reloaded.
8. Added judgment: **Order composite index columns to the query: equality columns first, then the range or sort column.** The engine can then read matching entries already in order. Check: the plan for the hot query shows the index used for both filter and order, with no separate sort step.
9. Added judgment: **Keep an index register.** For every index on a hot write path list the query it serves; an index that serves nothing current is cost with no benefit. Check: each index maps to at least one query in code or a dashboard; the rest are candidates for removal after checking plans.

## Procedure

1. List the table's writes per second and its reads by kind: point lookup, range scan, ordered page, aggregate, full scan.
2. List existing indexes and, for each, the query it serves.
3. For the new query, decide whether an existing index serves it (leading columns and order), or whether a new structure is justified by its read frequency against the write cost.
4. If the workload is analytical, move it off the transactional store (a replica, a warehouse or a materialized aggregate) and treat that copy as derived (`/data-intensive-apps:derived-data`).
5. For in-memory components, write the recovery path: what is reloaded from where, and what is allowed to be lost.
6. Verify with the engine's plan output on realistic data volume, and measure write throughput before and after.

## Example

```sql
-- Before: two single-column indexes; the hot query is "latest 20 orders of one customer"
CREATE INDEX orders_customer_idx ON orders (customer_id);
CREATE INDEX orders_created_idx  ON orders (created_at);

SELECT * FROM orders WHERE customer_id = 42 ORDER BY created_at DESC LIMIT 20;
-- The planner uses one index and then filters or sorts the rest; both indexes tax every insert.

-- After: one composite index whose column order matches the query (equality first, then the sort column)
CREATE INDEX orders_customer_created_idx ON orders (customer_id, created_at);
-- The 20 newest entries for customer 42 are read in order from the end of that customer's index range.
-- Drop orders_created_idx only after checking that no other query depends on it.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Index everything | A hot-insert table with an index per column | Keep the indexes that serve known queries |
| Analytics on the OLTP primary | Long scans and aggregates against the transactional tables | Replica, warehouse or materialized aggregate as derived data |
| Memory as durability | Data lives only in process memory or a cache | Persist, or document the loss and the reload |
| Engine by fashion | A storage engine chosen with no workload statement | Write the access pattern, then choose |
| Scatter-gather by index | A query by a non-key column that must ask every partition | Accept the cost knowingly, or add a global index or derived lookup |

## Trade-offs and exceptions

- LSM-style engines pay with compaction work and with reads that may check several runs; B-tree engines pay with in-place update and page writes. The rules say to match the workload, not that one is better.
- Small tables do not need indexes beyond the key; do not add structure for data that fits in a few pages.
- Columnar layouts and cubes speed particular aggregates and cost flexibility and freshness; use them only when the analytical pattern is real.
- A materialized view is derived data: its refresh cost and staleness belong in the design (`/data-intensive-apps:derived-data`).

## Verification

- [ ] Each new index is tied to a query and to a write-rate cost.
- [ ] The plan for the hot query was checked on realistic data volume.
- [ ] Analytical queries do not compete with transactions on the same layout without a reason.
- [ ] Anything held only in memory has a stated reload path and loss tolerance.
- [ ] Secondary-index behavior on a partitioned store is stated (local or global, write or read cost).

## Related

`/data-intensive-apps:data-model-choice` for shape; `/data-intensive-apps:partitioning-locality` for node placement; `/data-intensive-apps:derived-data` for materialized views and warehouse copies; `data-intensive-apps:storage-reviewer` to review a diff.

## Source

- `Storage Engine and Indexing Rules`
