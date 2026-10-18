---
name: "data-intensive-apps-derived-data"
description: "Use when adding or changing a cache, search index, read model, projection, materialized view or denormalized field, or when one is stale, drifting or cannot be rebuilt. Defines propagation, lag visibility and rebuild. Who owns the truth is source-of-truth."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Derived data: caches, indexes, projections and read models

Keeps every copy of data repairable: it knows where it comes from, shows how far behind it is, and can be rebuilt from its source. Deciding which dataset is the truth is `data-intensive-apps-source-of-truth`; choosing the index structure is `data-intensive-apps-storage-and-indexing`; the processors that feed copies from a log are `data-intensive-apps-stream-processing`.

## When to use

- You add a search index, cache, read model, materialized view, warehouse table or denormalized column.
- Application code writes a derived store directly alongside the primary write.
- A derived store is behind or wrong and nobody can say by how much or how to fix it.
- Someone asks "can we rebuild this if it breaks", or the answer is "we would have to recreate it by hand".
- A projection is fed by events and has never been replayed from the start.

## Rules

1. **Regard indexes, search copies, caches and read models as derived data, unless one is explicitly declared authoritative.** Check: each derived store is labelled and has one upstream source.
2. **Derived data must be recoverable from its source through a repair, a rebuild or a re-sync.** Check: a documented command or job rebuilds it from the source, and it has been run, at least in a test environment.
3. **Understand what users see when a derived copy lags behind its source.** Check: for each derived store the sentence "if this is N minutes behind, the user sees ..." is written.
4. **Instrument the pipelines that produce derived data so their state can be watched in production.** Check: lag, error count and last processed position are metrics with an alert.
5. **Do not ship a projection that cannot be rebuilt.** Check: delete a projection in a test environment and rebuild it from the source.
6. **Do not run without lag visibility.** Check: an operator can see how far behind each derived store is without reading code.
7. **Do not let primary writes go straight into derived stores without an ownership model.** Check: every writer of the derived store is named and driven by the owner's changes (a pipeline, a read-through loader, or a write-through with the owner as the single source). Added judgment: prefer the stricter form where you can, with application code writing the source only and the derived store changing through the pipeline.
8. **Define ownership, propagation, staleness, write cost, lag visibility, rebuild and repair whenever you add or change a derived representation.** Compact rule (trigger). Check: all seven items appear in the change description.
9. Added judgment: **Record the source position each derived record reflects** (a sequence number or offset). It gives you lag, makes applying a change idempotent, and lets you verify a rebuild. Check: the derived record or a checkpoint table carries the position.
10. Added judgment: **Rebuild into a new store and switch, rather than in place.** The old copy keeps serving while the new one is built. Check: the rebuild procedure ends with an atomic switch (alias, rename, pointer) and a catch-up from a noted position.
11. Added judgment: **Reconcile on a schedule.** Compare a sample of derived records with the source to find drift the pipeline cannot see. Check: a job reports mismatch counts.

## Procedure

1. Name the derived store, its source, and the pipeline between them.
2. Prefer to make the application write the source only; feed the derived store from the source's change feed, event stream or a periodic job.
3. Store the source position with the derived data or in a checkpoint.
4. Write the lag metric (source head minus applied position) and alert on it.
5. Write the rebuild: build a fresh copy from the source, catch up from the position noted at the start, then switch.
6. Document the staleness the user can see and, for caches, set the expiry from the tolerated staleness (`data-intensive-apps-consistency-contract`).
7. Run the rebuild in a test environment and compare with the incrementally maintained copy (`data-intensive-apps-data-path-tests`).

## Example

```python
# Before: the application indexes inline and ignores failures; the index drifts and nobody can tell
def save_product(p):
    db.execute("UPDATE products SET name = %s, price_cents = %s WHERE id = %s", [p.name, p.price_cents, p.id])
    try:
        search.index(p.id, to_doc(p))
    except Exception:
        pass                                # "search is best effort"

# After: the application writes the source only; a projector derives the index from an ordered change feed,
# remembers its position, exposes its lag, and the whole index can be rebuilt.
def project(batch_size=500):
    pos = checkpoints.get("product_search")
    for ch in changes.read_after(pos, limit=batch_size):          # product_changes, ordered by seq
        p = None if ch.deleted else db.get_product(ch.product_id)
        if p is None:
            search.delete(ch.product_id)                          # deleted, or deleted since the change was recorded
        else:
            search.index(ch.product_id, to_doc(p))                # upsert by id: safe to repeat
        checkpoints.set("product_search", ch.seq)
    metrics.gauge("product_search.lag", changes.head_seq() - checkpoints.get("product_search"))

def rebuild():
    start = changes.head_seq()                                    # note the position before scanning
    search.create_index("products_v2")
    for p in db.scan_products():
        search.index_into("products_v2", p.id, to_doc(p))
    search.switch_alias("products", "products_v2")
    checkpoints.set("product_search", start)                      # the projector re-applies changes made during the scan
```

Because applying a change is an upsert keyed by product id, repeating changes after the checkpoint reset is harmless.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Best-effort dual write | Inline index or cache write with the error swallowed | Pipeline from the source with a checkpoint |
| No rebuild path | No command or job recreates the store | Write and test the rebuild |
| Invisible lag | No metric for how far behind a copy is | Position-based lag metric and alert |
| Cache as truth | The only copy of a value is in the cache | Make the primary hold it (`data-intensive-apps-source-of-truth`) |
| TTL as correctness | Expiry chosen to "fix" a staleness bug with no requirement | Derive staleness from the read contract |
| Manual repair | Fixing copies by editing rows by hand | A repair job driven from the source |

## Trade-offs and exceptions

- A cache with a TTL is acceptable when a bounded staleness is the stated contract. The rule is that the bound is known, not that there is none.
- Full rebuilds of very large stores are expensive; support incremental repair (reprocess a key range or a time window) as well.
- An event-sourced design makes rebuild natural because the log is the source, but it moves complexity into log retention and snapshots (`data-intensive-apps-stream-processing`).
- A read-through cache is written by its loader on a miss and by invalidation; that is an explicit protocol, not "mixing writes in".

## Verification

- [ ] The derived store has one named source, and every writer to it is named and driven by that source's changes.
- [ ] A rebuild procedure exists and was exercised.
- [ ] Lag is a metric with an alert, and the user-visible effect of lag is written.
- [ ] The source position is stored with the derived data or in a checkpoint.
- [ ] Repeating the last batch after a crash changes nothing.

## Related

`data-intensive-apps-source-of-truth` for ownership; `data-intensive-apps-stream-processing` for processors and CDC; `data-intensive-apps-ownership-map` for an inventory; `data-intensive-apps-ownership-reviewer` to review a diff; `data-intensive-apps-derived-view-builder` to implement the rebuild.

## Source

- `Derived Data Rules`
- `Source of Truth`: only the rule that derived copies need a replication path and an update path.
- `Review Rules`: only the look-for on projections that cannot be rebuilt.
