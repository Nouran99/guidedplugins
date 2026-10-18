---
name: "data-intensive-apps-transactions-and-isolation"
description: "Use when a change must be atomic across rows or systems, an isolation level is chosen, a check-then-write may race (lost update, write skew, phantom), or a handler writes several stores or sends effects around a commit. Reader freshness: consistency-contract; caller's view: write-acknowledgment."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Transactions, isolation and multi-store writes

Makes the atomicity scope honest and matches the isolation level to the invariants the application depends on. What readers see after the commit is `data-intensive-apps-consistency-contract`; what a caller is told is `data-intensive-apps-write-acknowledgment`; leases and mutual exclusion are `data-intensive-apps-faults-and-coordination`.

## When to use

- A handler updates two tables, a table and a cache, a database and a message broker, or two services.
- Code reads a value, decides, then writes (check-then-write): balances, limits, seats, unique names, "at least one owner".
- You are asked to set or change the isolation level, or you see `SELECT ... FOR UPDATE`, optimistic locking or retry-on-conflict code.
- A side effect (email, webhook, event) is emitted inside or just after a transaction.
- Someone proposes two-phase commit or a distributed transaction across services.

## Rules

1. **Use a single-database transaction for writes that must succeed or fail together, when that alone removes the inconsistency.** Check: each group of writes that must succeed or fail together is in one transaction in one database.
2. **Avoid reaching for a distributed transaction as the first answer when parts of one operation live in different systems.** Check: no multi-system atomic commit is introduced without a written reason that a local transaction plus a repair path cannot meet.
3. **If an operation has to span a system or service boundary, write down its commit point, its recovery path, how mismatches get reconciled and what each failure leaves behind.** Check: for each cross-boundary operation you can state what commits first, what happens if the second part fails, and who reconciles.
4. **State how far atomicity reaches.** Check: a note names what is atomic together and what is not ("order and its lines atomic; the shipment event is not").
5. **For each invariant, decide which of read committed, snapshot isolation, serial execution, two-phase locking or serializable snapshot isolation it needs.** Check: each invariant has an entry naming the isolation level or other mechanism it relies on, and the level actually configured.
6. **Where correctness depends on ruling out a lost update, write skew or a phantom, put an explicit guard on that code path.** Check: every check-then-write has a guard (atomic conditional update, lock, constraint, serializable isolation with retry, version check).
7. **Do not rely on a weak isolation level for an invariant that correctness depends on, unless something else deliberately protects it.** Check: where isolation is weak, a compensating mechanism is named.
8. **Do not fire an effect outside the transaction with no way to repair a missed or failed one.** Check: each effect that follows a commit is recorded in the same transaction (an outbox row) or is idempotent and retried.
9. **Do not describe an asynchronous follow-up step as atomic with the write merely because it nearly always completes.** Check: the design does not state "and then the event is published" as part of the atomic unit.
10. **Do not let one operation update several systems of record unless it is atomic or has a stated repair path.** Check: count the stores and services one operation writes; for more than one, a mechanism is named.
11. **Map each anomaly to the invariant it can break before weakening isolation.** Compact rule: add serializable isolation, locks, compare-and-set, versioning, reconciliation or another compensating design where needed. Check: the map exists and each broken-invariant row has a mechanism.
12. Added judgment: **Make racing transactions write the same row.** Under snapshot isolation two transactions that read the same data and write different rows both commit (write skew). A counter or lock row that both must update turns the race into a conflict the database detects. Check: the guarded invariant is represented by a row that every competing transaction writes.
13. Added judgment: **Retry on serialization failure.** Serializable isolation and optimistic checks abort losers by design. Check: the transaction is wrapped in a bounded retry that re-reads inside the new transaction.

## Procedure

1. List the invariants the code relies on (unique, non-negative, at most N, at least one, no overlap).
2. For each, find where it is enforced and whether it is a check-then-write.
3. Choose the enforcement: a constraint if the database can state it, an atomic conditional update, a lock or version check, or serializable isolation with retries.
4. List every store and service one operation writes; put what can be local in one transaction; give the rest a durable intent and a repair path.
5. Replace inline side effects with outbox rows or keyed retried steps.
6. State the atomicity scope next to the operation.
7. Add a concurrent test for each guarded invariant and a crash test for each multi-store write (`data-intensive-apps-data-path-tests`).

## Example

```python
# Before: a team must always keep at least one owner. Two owners demote each other at the same moment.
# Under read committed or snapshot isolation both transactions see two owners, each demotes a DIFFERENT row, both commit: zero owners.
def demote_owner(db, team_id, user_id):
    owners = db.scalar("SELECT count(*) FROM members WHERE team_id = %s AND role = 'owner'", [team_id])
    if owners > 1:
        db.execute("UPDATE members SET role = 'member' WHERE team_id = %s AND user_id = %s", [team_id, user_id])

# After: the invariant lives in a counter on the team row; every demotion must update that one row,
# with a single conditional statement, so competing demotions conflict instead of skewing.
# owner_count is maintained in the same transaction by every path that adds, promotes or removes an owner;
# where the engine can state the rule as a declared constraint, prefer that to a hand-kept counter.
def demote_owner(db, team_id, user_id):
    with db.transaction() as tx:
        changed = tx.execute(
            "UPDATE members SET role = 'member' WHERE team_id = %s AND user_id = %s AND role = 'owner'",
            [team_id, user_id]).rowcount
        if changed != 1:
            raise NotAnOwner(user_id)
        kept = tx.execute(
            "UPDATE teams SET owner_count = owner_count - 1 WHERE id = %s AND owner_count > 1", [team_id]).rowcount
        if kept != 1:
            raise LastOwnerError(team_id)        # raising rolls the transaction back, including the role change
# Either the second transaction waits for the first, then re-evaluates "owner_count > 1" on the new value and is refused,
# or the engine detects the write-write conflict and fails it with a serialization error that the caller retries
# (which of the two happens depends on the engine and its isolation level). In both cases one demotion is refused.
```

A second shape of the same rule is side effects around a commit:

```python
# Before: a crash between the commit and the publish loses the event; a failed publish leaves an order nobody hears about
with db.transaction() as tx:
    tx.execute("INSERT INTO orders (id, customer_id, total) VALUES (%s, %s, %s)", [oid, cid, total])
bus.publish("order.placed", {"order_id": oid})

# After: the intent is recorded atomically with the order; a relay publishes it at least once and consumers dedupe on event_id
with db.transaction() as tx:
    tx.execute("INSERT INTO orders (id, customer_id, total) VALUES (%s, %s, %s)", [oid, cid, total])
    tx.execute("INSERT INTO outbox (event_id, topic, payload) VALUES (%s, 'order.placed', %s)", [eid, payload])
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Check then write | `SELECT` followed by `UPDATE` based on it, in separate statements | One conditional statement, lock, constraint, or serializable plus retry |
| Dual write | Two stores written in sequence in one handler | Single transaction, outbox, or documented repair |
| Distributed by default | Two-phase commit across services as the first answer | Local transactions plus intent and reconciliation |
| Effect before commit | Email or webhook sent before the transaction ends | After commit via outbox |
| "Usually happens" | Async step described as part of the atomic unit | Name what is not atomic |
| Weak isolation, no guard | Read committed with a limit invariant and no lock | Map the anomaly, add a mechanism |

## Trade-offs and exceptions

- Serializable isolation costs aborts and throughput; use it where the invariant needs it and retry on failure. Where an invariant is not at risk (a tolerant analytics counter) a weaker level is fine.
- Serial execution, two-phase locking and serializable snapshot isolation are different ways to get the same guarantee with different costs; choose by workload and engine support.
- When a distributed transaction is truly required, define the commit and recovery semantics instead of assuming the protocol covers coordinator failure (`data-intensive-apps-faults-and-coordination`).
- An outbox gives at-least-once publication; consumers must be idempotent (`data-intensive-apps-idempotent-handlers`).

## Verification

- [ ] Each invariant has a named enforcement and the isolation level it relies on.
- [ ] No check-then-write relies on a read that another transaction can invalidate.
- [ ] Every operation that writes more than one store states how failures are repaired.
- [ ] Side effects after a commit are recorded in it or are idempotent and retried.
- [ ] The atomicity scope is written next to the operation.
- [ ] A concurrent test exists for each guarded invariant.

## Related

`data-intensive-apps-invariant-map` to list invariants and their mechanisms; `data-intensive-apps-write-acknowledgment` for the caller's view; `data-intensive-apps-idempotent-handlers` for outbox consumers; `data-intensive-apps-derived-data` for derived stores; `data-intensive-apps-transaction-reviewer` to review a diff.

## Source

- `Transaction Rules`
- `Isolation and Invariants`
- `Uncoordinated Multi-Writes`
- `Review Rules`: only the look-fors on side effects that cannot be repaired and on write paths that update several stores with unclear guarantees.
