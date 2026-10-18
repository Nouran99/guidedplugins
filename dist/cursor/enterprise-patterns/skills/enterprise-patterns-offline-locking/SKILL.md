---
name: "enterprise-patterns-offline-locking"
description: "Use when two users or sessions can edit the same data across separate requests: lost updates, a version column, row locks held between requests, locks on related objects, or stale locks. One request's commit scope is transactions-and-unit-of-work."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Offline locking

Covers conflicts between edits that span more than one request or transaction: Optimistic Offline Lock, pessimistic locking, Coarse-Grained Lock and Implicit Lock. The commit scope of a single request is `enterprise-patterns-transactions-and-unit-of-work`.

## When to use

- A user opens a record, edits it for minutes, and saves; someone else may have saved in between.
- Last-write-wins is silently overwriting changes.
- A design proposes holding a database lock while a user thinks.
- An order and its lines (or any group that is edited as one) must not be edited by two people at once.
- A framework acquires locks for you and nobody can say when or why.

## Rules

1. **Use Optimistic Offline Lock when conflicts are possible but uncommon.** An optimistic lock costs nothing until a conflict happens, which is cheap when conflicts are rare. Check: you can state why contention is rare for this data.
2. **Detect conflicting concurrent updates.** Otherwise the later save overwrites the earlier one without anyone noticing. Check: each update is conditional on the state the editor read (a version number, or an equivalent that changes on every write), and the code checks that exactly one row was updated.
3. **Fail safely and explicitly.** A silent failure is worse than a visible one. Check: the conflict path raises a named error, nothing is half-written, and the caller cannot mistake it for success.
4. **Surface conflict resolution or merge semantics intentionally.** A conflict has a human consequence, and the system needs a defined answer to it. Check: the use case says what happens on conflict (reject and reload, or merge named fields) and that decision is written down.
5. **Use pessimistic locking only when contention is expected and the cost is justified.** Locks held while users think block others and invite abandoned locks. Check: you can name the contention and the cost (blocked users, held locks, deadlock risk).
6. **Plan for stale locks when you lock pessimistically.** Compact checklist (from `mini.md`): a lock has an owner, an expiry and a cleanup path, so an abandoned session cannot block others forever.
7. **Use a Coarse-Grained Lock when related objects must be locked together to preserve a user-level edit.** In the user's mind, an edit to a member of a group is an edit to the group. Check: the group shares one lock or version (usually on the root), and editing any member changes it.
8. **Use an Implicit Lock only when lock acquisition is reliably hidden without making concurrency invisible to maintainers.** Hidden locks reduce boilerplate, but only if people can still find them. Check: the framework or base class acquires and checks locks, and a maintainer can still find where.
9. **Do not let implicit locking make transaction ownership or contention impossible to diagnose.** Contention you cannot diagnose cannot be fixed. Check: for any conflict you can find who held which lock and when (names, logs, error messages).
10. **Choose lock semantics explicitly instead of relying on developer discipline.** Compact checklist (from `mini.md`). The assumption that nobody edits simultaneously fails in production. Check: the choice (optimistic, pessimistic, coarse, implicit) is a line in the design, not an assumption that "people will not edit at the same time".
11. **Do not treat a long-running workflow as one immediate transaction.** The source lists this under unclear transaction ownership as a forbidden pattern. A long transaction blocks other users and does not make the edit safe. Check: user think time is outside any open transaction.
12. **Test the concurrency behavior.** Concurrency bugs do not show up in single-threaded tests. Check: a test performs two interleaved edits and asserts the designed outcome (one fails, or they merge).

## Procedure

1. Identify the data edited across requests and who can edit it concurrently.
2. Estimate contention: rare (optimistic), frequent or costly to redo (consider pessimistic).
3. For optimistic: add the version, make updates conditional, add the conflict error and its handling in the use case.
4. Decide the unit that must be locked together; if it is a group, put the version on the root and bump it when a member changes.
5. For pessimistic: define lock owner, acquisition, expiry and release; add cleanup.
6. Write the interleaved-edit test, then run the suite.

## Example

```python
class StaleObjectError(Exception):
    pass

# Before: last write wins; the second editor silently erases the first editor's change
def save_ticket(conn, ticket):
    conn.execute("update tickets set title = ?, status = ? where id = ?",
                 (ticket.title, ticket.status, ticket.id))

# After: the update is conditional on the version the editor read
def save_ticket(conn, ticket):
    cur = conn.execute(
        "update tickets set title = ?, status = ?, version = version + 1 where id = ? and version = ?",
        (ticket.title, ticket.status, ticket.id, ticket.version))
    if cur.rowcount != 1:
        raise StaleObjectError(f"ticket {ticket.id} changed since version {ticket.version}")
    ticket.version += 1
```

If two people load version 3, the first save moves the row to version 4 and the second finds no row with version 3, so it raises `StaleObjectError` instead of overwriting. For an order and its lines edited as one, bump the order's version whenever a line changes and check only the order's version: that is the Coarse-Grained Lock, with one lock for the group.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Last write wins | Updates conditioned only on the id | Version check and conflict error |
| Swallowed conflict | `rowcount` ignored, or conflict logged and dropped | Raise; handle in the use case |
| Lock across think time | Transaction or row lock open while a user edits | Optimistic lock, or an expiring application-level lock |
| Orphaned lock | Lock rows with no owner, no expiry | Add owner, expiry and cleanup |
| Invisible lock | Framework locks that nobody can locate | Name, log and document where they are taken |
| Child edits unprotected | Lines saved without touching the order version | Coarse-grained lock on the root |

## Trade-offs and exceptions

- Optimistic locking pushes the cost to the loser of the race; if conflicts are frequent or redoing the work is expensive, the source allows pessimistic locking, justified.
- Implicit locking is allowed when it is reliably hidden and still diagnosable; the failure is invisible concurrency.
- Merge semantics can be as simple as "reject and reload"; the requirement is that the choice is deliberate.
- Distributed locking, clocks and consensus are subjects of `data-intensive-apps`, not of this book.

## Verification

- [ ] Every cross-request edit path has a stated lock semantics.
- [ ] Updates are conditional on the read version and check the affected row count.
- [ ] The conflict path raises a named error with a defined user outcome.
- [ ] Pessimistic locks have owner, expiry and cleanup.
- [ ] Groups edited as one share a lock.
- [ ] An interleaved-edit test passes.

## Related

`enterprise-patterns-transactions-and-unit-of-work` for one request's commit; `enterprise-patterns-session-state` when the edit state lives in a session; `enterprise-patterns-lock-reviewer` to review a diff; `enterprise-patterns-lock-adder` to add an optimistic lock.

## Source

- `Concurrency and Transaction Rules`
- `Optimistic Offline Lock`
- `Pessimistic Locking`
- `Additional Offline Concurrency Patterns`
- `Unclear Transaction Ownership`: only the rule against treating long-running workflows as one immediate transaction.
- `Testing Rules`: only the rule to test locking behavior.
