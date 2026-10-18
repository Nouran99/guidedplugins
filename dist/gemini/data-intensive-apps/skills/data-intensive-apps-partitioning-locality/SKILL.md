---
name: "data-intensive-apps-partitioning-locality"
description: "Use when choosing a partition, shard or routing key, spreading data across nodes, handling hot keys or skew, or seeing queries and transactions that cross partitions. Colocates data and work by the key that drives consistency or aggregation."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Partitioning, locality and skew

Cuts data and work by the key that the common operations share, so ordinary queries and updates stay on one partition. The structures inside a partition are `data-intensive-apps-storage-and-indexing`; the service lines around ownership are `data-intensive-apps-service-boundaries`; evidence that a node is the bottleneck is `data-intensive-apps-load-and-latency`.

## When to use

- You pick the key for a sharded database, a topic's partitions, a cache cluster or a work queue.
- A query that is frequent must ask every shard, or a common transaction touches several.
- One tenant, user or product receives a large share of traffic or storage.
- Data is sharded by an id because the id is convenient, while the application reads by another attribute.
- Nodes are added or removed and a large share of keys move.

## Rules

1. **Group data and the work on it onto the same partition, by the key behind most consistency decisions and aggregations.** Operations that share a key can then run on one partition without coordination. Check: list the top queries and transactions; each should touch one partition.
2. **Derive the partition key from how the workload reads and writes, not from whatever is easiest to pick.** Check: the chosen key appears in the dominant access path; a surrogate id chosen only because it exists is a finding.
3. **Spell out where hot keys and skew could form.** One key can carry more load than a node. Check: the share of traffic and data held by the largest key is measured or estimated, and a mitigation is named.
4. **Treat each operation that crosses partitions as a design problem of its own.** Check: each scatter-gather query has a cost note and each cross-partition write has a coordination story (`data-intensive-apps-transactions-and-isolation`).
5. **Do not choose a layout that sends every frequent query to several nodes.** Check: the most frequent read does not fan out to all partitions.
6. **Do not ship a design that has no stated response to uneven load on particular keys.** Check: there is a documented response for the largest keys (sub-keying, dedicated capacity, caching with a staleness bound).
7. **Do not make everyday business operations need a cross-partition transaction in order to succeed.** Check: the routine business operation is confined to one partition; cross-partition work is the exception.
8. **Make routing metadata, secondary-index behavior and rebalancing cost explicit.** Compact rule. Check: you can say how a client finds the partition for a key, whether a secondary index is local to each partition or global, and how much data moves when a node is added.
9. Added judgment: **Test the ordinary query path against the partitioning.** Take the five most frequent operations and mark each single- or multi-partition. Check: the table exists in the design and the most frequent are single.
10. Added judgment: **Prefer a fixed number of logical partitions mapped to nodes over `hash(key) mod number_of_nodes`.** Rebalancing then moves whole partitions instead of rehashing most keys. Check: adding a node does not change which partition a key belongs to.

## Procedure

1. Write the access paths: the operations, their frequency, and the attribute each is addressed by.
2. Pick the attribute shared by the most frequent operations and by the operations that need consistency together (a customer's orders, a document's edits).
3. Check the distribution of that attribute for skew: the largest values, growth over time, time-ordered keys that make the newest partition hot.
4. Decide hot-key handling for the largest keys and accept its cost explicitly.
5. Mark the remaining cross-partition operations and state how each is executed and what consistency it has.
6. Document routing, secondary-index placement and rebalancing.

## Example

```python
# Before: orders are spread evenly by order id, so "show this customer's orders" and
# "this customer's open credit" have to ask every partition.
def partition_for(order_id: str, n_partitions: int) -> int:
    return stable_hash(order_id) % n_partitions

# After: the dominant access path is "everything about one customer", so route by customer.
# n_partitions is a fixed count of logical partitions that a routing table maps to nodes;
# stable_hash is a hash that gives the same answer in every process (not a per-process hash seed).
def partition_for(customer_id: str, n_partitions: int) -> int:
    return stable_hash(customer_id) % n_partitions

# Known hot customers (one tenant is 30% of traffic) get an explicit sub-key policy in the routing table,
# which spreads their orders over several partitions and accepts scatter-gather for that customer only.
```

Choosing time of creation as the key is another classic trap: with key-range partitioning by timestamp, all current writes land on the newest partition.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Convenience key | The key is an auto id unrelated to how data is read | Key by the access attribute |
| Scatter by default | The most frequent query touches every partition | Re-key, or add a derived lookup for that query |
| Celebrity key | One key holds a large share of load | Sub-key or dedicated handling with stated cost |
| Time-ordered hot spot | New writes all hit one range | Key that spreads writes, or accept and size for it |
| Modulo rebalancing (Added judgment) | `hash(key) % node_count` | Fixed logical partitions mapped to nodes |
| Cross-partition by routine | Ordinary operations need a distributed transaction | Choose the partition key so the routine case is local |

## Trade-offs and exceptions

- Key-range partitioning supports range scans and ordered access but can concentrate load; hash partitioning spreads load but gives up cheap range queries. This is background to the rules, not a rule of the source.
- Perfect locality for every query is impossible. The rule is that the common path is local and the rest are chosen and priced.
- Secondary indexes on a partitioned store are either local (writes are cheap, reads ask all partitions) or global (reads are targeted, writes cross partitions). Pick by workload (`data-intensive-apps-storage-and-indexing`).
- A single-node database needs none of this; do not partition before the workload calls for it (`data-intensive-apps-load-and-latency`, rule on unnecessary distribution).

## Verification

- [ ] The most frequent operations are marked single- or multi-partition, and the most frequent are single.
- [ ] The key appears in the dominant access path.
- [ ] The largest key's share of load and data is known and has a mitigation.
- [ ] Routing, secondary-index placement and rebalancing cost are written down.
- [ ] No routine operation requires a cross-partition transaction.

## Related

`data-intensive-apps-ordering-scope` for per-key order; `data-intensive-apps-storage-and-indexing` for index placement; `data-intensive-apps-service-boundaries` for ownership lines; `data-intensive-apps-load-and-latency` for evidence; `data-intensive-apps-partitioning-reviewer` to review a diff.

## Source

- `Partitioning and Locality Rules`
- `Review Rules`: only the look-for on partitioning that is blind to locality or hotspots.
