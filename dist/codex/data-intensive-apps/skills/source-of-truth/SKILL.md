---
name: "source-of-truth"
description: "Use when the same data lives in several places, a cache or copy is written directly, two services update one fact, or ownership is unclear. Names the primary owner, derived copies, update path and repair. Rebuilding a copy is derived-data."
---

# Source of truth and ownership

For every important piece of data there is one answer to "who is allowed to say what it is". This skill finds the answer, writes it down, and finds the code that contradicts it. Keeping a copy rebuildable, lagging visibly and repairable is `$data-intensive-apps:derived-data`; how services are cut around owners is `$data-intensive-apps:service-boundaries`.

## When to use

- Two services, jobs or code paths write the same field, in the same or different stores.
- A cache, search index or denormalized column is written by application code alongside the primary write.
- A bug report says "the value is different in the app and in the report".
- You are asked to add a field that "also needs to be in" another table, topic or service.
- Nobody can say which of two tables is authoritative.

## Rules

1. **State plainly who owns each dataset.** One owner decides what the data is and how it changes. Check: for each dataset there is one named owner (service, module or table) written in code or docs.
2. **For each important piece of data, record five things: its primary owner, its derived copies, how it is replicated, how it is updated and what consistency is expected.** Check: fill the five fields; a blank field is a finding.
3. **Tell primary data apart from indexes, caches, projections and search copies.** A copy is allowed to be wrong for a while, the primary is not. Check: the code that writes each copy is identifiable, and it is driven by the owner's changes, not by a second source of input.
4. **Do not leave several writable copies of a fact without an owner.** Two writers of one fact will disagree. Check: search for every place the same field is written; more than one writer needs an owner decision.
5. **Do not let a cache quietly become the real source of truth.** A cache that holds the only copy of something is a database with none of a database's guarantees. Check: if the cache is flushed, can every value be recovered from the primary?
6. **Do not keep denormalized copies without a repair strategy.** Check: you can state how a wrong copy is detected and how it is corrected.
7. **Say for each datum whether it is durable, cached, derived or ephemeral.** That label decides how much care a loss deserves. Check: the data inventory carries the label.
8. Added judgment: **When two systems both look like owners, make one of them send a request to the other instead of writing.** The second writer becomes a client of the owner's API or a consumer of its changes. Check: after the change, only one code path performs `UPDATE`/`PUT` on the fact.
9. Added judgment: **Make the role visible in names.** Tables and modules called `*_projection`, `*_cache`, `*_snapshot` tell the next reader that they are not authoritative. Check: no table holding derived data is named as if it were the entity itself.

## Procedure

1. Pick the fact (for example "stock on hand", "user email", "order status") and list every store, topic and service that holds a version of it.
2. Mark one as primary. If the code disagrees (several writers), decide the owner by who must enforce the invariant for that fact.
3. For each other holder, record how it learns of changes (event, change feed, nightly job, read-through) and what it does when it is wrong.
4. Remove or redirect direct writes to derived holders so they are fed only from the primary's changes.
5. Write the five fields (owner, derived copies, replication path, update path, consistency expectation) next to the code or in the data inventory.
6. Hand off the copies to `$data-intensive-apps:derived-data` for lag, rebuild and repair.

## Example

```ts
// Before: catalog-service also decrements its own copy of stock on every order event,
// while inventory-service decrements its table on the same event. Two writers, two truths.
async function onOrderPlaced(e: OrderPlaced) {
  for (const line of e.lines) {
    await db.query("UPDATE products SET stock = stock - $1 WHERE id = $2", [line.qty, line.productId]);
  }
}

// After: inventory-service owns stock levels and publishes each change with a per-product sequence number.
//   StockLevelChanged { productId, onHand, seq }
// catalog-service keeps only a derived flag and never computes stock itself.
async function onStockLevelChanged(e: StockLevelChanged) {
  await db.query(
    `INSERT INTO product_availability (product_id, in_stock, source_seq)
     VALUES ($1, $2, $3)
     ON CONFLICT (product_id) DO UPDATE
       SET in_stock = EXCLUDED.in_stock, source_seq = EXCLUDED.source_seq
       WHERE product_availability.source_seq < EXCLUDED.source_seq`,
    [e.productId, e.onHand > 0, e.seq]);
}
// product_availability is a projection: it can be dropped and rebuilt from inventory-service's snapshot plus its change feed.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Many writable copies | The same column or field assigned in more than one service or job | Pick the owner; others consume its changes |
| Cache as truth | A key whose loss cannot be recovered from the primary | Put the data in the primary, or accept loss and document it |
| Denormalized copy with no repair | A copied field with no rebuild job and no comparison | Add a rebuild path (`$data-intensive-apps:derived-data`) |
| Unlabelled projection | A table that looks like an entity but is filled by a pipeline | Rename and document it as derived |
| Shared database, silent writers | Several services write the same table | One service owns writes; others read through an API or a feed |

## Trade-offs and exceptions

- A shared database inside one team can be a legitimate arrangement if ownership by table or column is explicit and enforced by convention or permissions.
- Read-through caches are a recognized pattern: the cache is written only by the loader on a miss, and the owner stays the primary. The rule targets caches written by arbitrary callers.
- Some facts are legitimately multi-writer (collaborative documents). Then the owner is a conflict-resolution scheme, which belongs to `$data-intensive-apps:replication-topology` and `$data-intensive-apps:consistency-contract`.

## Verification

- [ ] Each touched dataset has exactly one named owner.
- [ ] Each derived copy has a stated feed from the owner and no other writer.
- [ ] No cache holds data that cannot be recovered from the primary.
- [ ] Every denormalized copy has a way to detect and correct drift.
- [ ] The durable, cached, derived or ephemeral label is stated for the new data.

## Related

`$data-intensive-apps:derived-data` for lag, rebuild and repair; `$data-intensive-apps:service-boundaries` for owner-aligned cuts; `$data-intensive-apps:ownership-map` for a repository-wide inventory; `data-intensive-apps-ownership-reviewer` to review a diff.

## Source

- `Data Model and Storage Rules`: the rules on explicit ownership and on distinguishing primary data from indexes, caches, projections and search copies.
- `Source of Truth`
- `Primary Directive`: only the question on whether state is durable, cached, derived or ephemeral.
