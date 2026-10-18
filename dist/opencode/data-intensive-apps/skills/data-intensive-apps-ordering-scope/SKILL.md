---
name: "data-intensive-apps-ordering-scope"
description: "Use when events or updates for one entity can arrive out of order, parallel consumers touch the same key, code assumes global order, or last write wins by arrival. Scopes ordering per key or partition and adds versions. Duplicates are idempotent-handlers."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Ordering scope and versioning

Decides which ordering the business logic really needs, scopes it to the key or stream that defines it, and gives state a version so that a late message cannot overwrite a newer fact. Repeated delivery of the same message is `data-intensive-apps-idempotent-handlers`; cutting data by key is `data-intensive-apps-partitioning-locality`; stronger orderings such as total order broadcast are `data-intensive-apps-faults-and-coordination`.

## When to use

- A consumer applies "updated" events to a read model, and two updates for one entity can be in flight.
- Several consumer instances read the same queue or topic without a key-based assignment.
- Code compares timestamps produced on different machines to decide which update wins.
- A design says "events are processed in order" without saying in order with respect to what.
- A state machine (order, subscription, shipment) can receive its transitions out of sequence.

## Rules

1. **Do not treat events from a distributed system as if they arrive in one shared sequence.** Messages on different keys, partitions, queues or producers have no shared order. Check: no logic depends on the relative arrival order of events from different keys.
2. **Demand only as much ordering as a business rule actually depends on.** Stronger ordering costs parallelism. Check: each ordering dependency has the business reason written beside it ("a refund must follow its payment").
3. **Where order matters, define the boundary inside which it holds: a key, a stream, a partition, or the one entity whose history the events extend.** Check: the consumer's documentation or code names the scope.
4. **Co-locate order-dependent logic with the key or stream that establishes the order.** Check: all processing for one key runs in one place at a time (one partition owner, one actor, one serialized queue).
5. **Do not write code that silently needs every event to be handled in a single total order.** Check: grep for comments and code that assume "the previous event has been handled" across keys.
6. **Do not let a late or reordered event overwrite newer state; give the state a version or sequence rule.** Check: every update to entity state compares the event's version with the stored version, or the operation is commutative.
7. **Do not run several consumers against the same key unless something decides the order of their updates.** Check: consumer concurrency is assigned by key hash, not by message.
8. Added judgment: **Decide the fate of a stale event on purpose.** Options are drop it, apply it as a no-op, or send it to a correction path; count each occurrence in a metric. Check: the code has a branch and a counter for the stale case.
9. Added judgment: **Take the version from the entity's writer, monotonic per entity, rather than a wall-clock timestamp.** Timestamps from different machines can disagree (`data-intensive-apps-faults-and-coordination`). Check: the version field is assigned by the single writer of that entity.
10. Added judgment: **Prefer operations that commute (set-add, max, replace with version) when you can.** They need no ordering at all. Check: if two events can be applied in either order with the same result, say so in a test.

## Procedure

1. List the entities whose state the consumer updates and the events that update each.
2. For each event pair that must keep its order, write the reason. If none must, stop here: no ordering mechanism is needed.
3. Choose the scope: the key whose history is updated.
4. Make the transport deliver that key's events to one consumer at a time (key-based partition assignment), and make concurrency per key serial.
5. Add the version to the event and the stored state; apply only newer versions; define the stale-event branch.
6. Add tests for reversed and shuffled arrival (`data-intensive-apps-data-path-tests`).

## Example

```ts
// Before: eight consumer instances share one queue; two address changes for the same customer race,
// and whichever UPDATE runs last wins, even if it carries the older address.
consumer.on("CustomerAddressChanged", async (e) => {
  await db.query("UPDATE customer_view SET address = $1 WHERE id = $2", [e.address, e.customerId]);
});

// After: the publisher uses customerId as the partition key and stamps a per-customer version.
// The consumer applies a change only if it is newer than what is stored, and counts the ones it ignores.
consumer.on("CustomerAddressChanged", async (e) => {
  const r = await db.query(
    `INSERT INTO customer_view (id, address, version) VALUES ($1, $2, $3)
     ON CONFLICT (id) DO UPDATE SET address = EXCLUDED.address, version = EXCLUDED.version
     WHERE customer_view.version < EXCLUDED.version`,
    [e.customerId, e.address, e.version]);
  if (r.rowCount === 0) metrics.inc("customer_view.stale_event_ignored");
});
```

Partitioning by key keeps one customer's events together; the version makes the update safe even if the transport or a retry reorders them.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Arrival order is truth | An unconditional `UPDATE ... SET x = ?` from events | Version check or commutative update |
| Producer wall-clock as version | Timestamps from several hosts compared | Per-entity counter owned by the writer |
| Per-message parallelism | Worker pool pulls any message | Assign by key, serialize per key |
| Hidden global order | "After event A comes B" across different keys | Make the dependency explicit or remove it |
| Silent drop | A guard that discards stale events with no metric | Count and alert |

## Trade-offs and exceptions

- Per-key ordering limits parallelism to the number of distinct keys, and a hot key serializes (`data-intensive-apps-partitioning-locality`).
- Total order across the whole system needs a coordination mechanism with a real cost; use it only when the problem needs it (`data-intensive-apps-faults-and-coordination`).
- Idempotent set-to-value updates with a version need no further ordering plan; read models with last-state semantics are the easy case, while counters and ledgers need more care.
- When facts are append-only and independent (an event log of page views), order may not matter at all.

## Verification

- [ ] Each ordering requirement has a business reason and a named scope.
- [ ] Concurrency of consumers is per key, not per message.
- [ ] State updates compare a version or are commutative.
- [ ] The stale-event branch exists and is counted.
- [ ] A test applies events reversed and shuffled and gets the same final state.

## Related

`data-intensive-apps-idempotent-handlers` for duplicates; `data-intensive-apps-partitioning-locality` for key choice; `data-intensive-apps-event-design` for version and key fields in the event; `data-intensive-apps-transactions-and-isolation` for compare-and-set on shared rows; `data-intensive-apps-ordering-reviewer` to review a diff.

## Source

- `Ordering Rules`
- `Review Rules`: only the look-fors on hidden ordering assumptions and on missing versioning or sequencing where concurrency matters.
