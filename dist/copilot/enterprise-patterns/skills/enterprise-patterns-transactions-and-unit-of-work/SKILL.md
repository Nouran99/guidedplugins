---
name: "enterprise-patterns-transactions-and-unit-of-work"
description: "Use when deciding who opens and commits a transaction, saves are scattered across callers, an ORM flushes at surprising times, or a remote call sits inside a transaction. One request's commit scope; cross-request edits are offline-locking, reads are loading-behavior."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Transactions and Unit of Work

Owns one question: for a single use case, who begins and ends the transaction, which writes are part of it, and when they reach the database. Conflicts between users across several requests are `enterprise-patterns-offline-locking`; reads and identity are `enterprise-patterns-loading-behavior`.

## When to use

- `save()` or `commit()` calls appear in helpers, repositories, handlers and domain objects.
- A use case writes several rows and a failure halfway would leave a partial result.
- An HTTP or message call happens between `begin` and `commit`.
- An ORM session auto-flushes, and the order or timing of writes changes behavior.
- A long business process is run as one database transaction.

## Rules

1. **Make transaction boundaries explicit in the application workflow.** Readers must be able to see what commits together. Check: for each use case you can point to one place where the transaction begins and ends, usually the application service.
2. **Avoid transactions that span remote calls when possible.** A slow or failing remote call holds locks and connections open, and may fail after the local work has committed. Check: no HTTP, RPC, message publish or email send between begin and commit; if one is unavoidable, a comment states why.
3. **Keep transactions short.** Long transactions hold locks and connections and raise the chance of conflicts. Check: no user wait, file transfer, sleep or unbounded loop inside.
4. **Do not bury transaction ownership deep in helper classes.** Helpers and repositories take part in the caller's transaction. A hidden commit makes the atomicity of the whole use case depend on a helper. Check: no `commit` or `begin` in a repository, mapper, gateway or domain object.
5. **Make transactional write coordination explicit with a Unit of Work.** Collecting changes lets them be written together in a known order. Check: you can point to where changed objects are registered and where they are written.
6. **Commit the work as one logical unit.** A partial commit leaves data that no use case intended. Check: all writes of the use case succeed or fail together; there is no second `commit` later in the same use case.
7. **Keep the unit-of-work scope understandable.** Added judgment: one unit of work per use-case invocation, created at its start and discarded at its end, never shared across requests or threads.
8. **Do not use hidden auto-persistence with surprising write timing.** Writes whose timing depends on the framework are hard to reason about and to test. Check: the code does not depend on the ORM flushing before a query or on dirty tracking to save a change nobody mentions; if the ORM's unit of work is used, the flush point is known.
9. **Do not save each object ad hoc from random callers.** Scattered saves make it impossible to say what a use case wrote, or to undo it. Check: writes are registered with the unit of work or issued by the service, not from helpers.
10. **Do not treat long-running workflows as one immediate transaction.** A transaction held through waits or other systems blocks others and still does not make the work atomic across them. Check: processes that wait for people or other systems are split into steps, each with its own transaction and a recorded state between them.
11. **Test the workflow for commit and rollback behavior.** Atomicity is a property you want to see fail in a test, not one to trust on faith. Check: a test makes the last write fail and asserts nothing earlier was kept (see `enterprise-patterns-testing-by-responsibility`).

## Procedure

1. Trace the use case from entry to exit and mark every read, write, commit and outbound call.
2. Choose the owner: the application service in almost every case.
3. Collapse scattered `commit`s into one at the end of the use case; remove `commit` from helpers.
4. Introduce a unit of work (or use the ORM's, knowing its flush rules) that collects new and changed objects and writes them in a known order.
5. Move outbound calls to after the commit, or to a record of intent that a later step sends.
6. Run the tests after each step, then add the failure-injection test from rule 11.

## Example

```python
# Before: each helper commits on its own, and a remote call sits between the two writes
def transfer(conn, http, src_id, dst_id, cents):
    debit(conn, src_id, cents)          # commits inside
    http.post("/audit", json={"from": src_id, "to": dst_id})
    credit(conn, dst_id, cents)         # if this fails, the debit is already permanent

# After: one unit of work collects the writes and commits once; the remote call follows the commit
class UnitOfWork:
    def __init__(self, conn, mappers):
        self.conn, self.mappers = conn, mappers
        self.new, self.dirty = [], []
    def register_new(self, obj):
        self.new.append(obj)
    def register_dirty(self, obj):
        if obj not in self.new and obj not in self.dirty:
            self.dirty.append(obj)
    def commit(self):
        try:
            for obj in self.new:
                self.mappers[type(obj)].insert(obj)
            for obj in self.dirty:
                self.mappers[type(obj)].update(obj)
            self.conn.commit()
        except Exception:
            self.conn.rollback()
            raise
        finally:
            self.new.clear()
            self.dirty.clear()

def transfer(uow, accounts, auditor, src_id, dst_id, cents):
    src, dst = accounts.get(src_id), accounts.get(dst_id)
    src.withdraw(cents)
    dst.deposit(cents)
    uow.register_dirty(src)
    uow.register_dirty(dst)
    uow.register_new(LedgerEntry(src_id, dst_id, cents))
    uow.commit()                                  # one logical unit, in one place
    auditor.transfer_completed(src_id, dst_id, cents)   # after the commit
```

`withdraw` raising for insufficient funds happens before anything is registered, so nothing is written. A failing `update` rolls back the inserts as well. If the audit call fails after the commit, the money has moved; decide whether that is acceptable or whether the audit needs its own retryable record.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Random commits | `commit` in helpers, repositories or handlers | One commit in the service or unit of work |
| Remote call in a transaction | Network call between begin and commit | Move after commit, or restructure |
| Ad hoc saves | `save()` scattered through domain and helper code | Register with the unit of work |
| Flush surprise | A change is persisted only because a later query triggered a flush | Make the flush point explicit |
| Workflow as one transaction | A transaction held across user input or other systems | Split into steps with stored state |
| Unowned transaction | No answer to "who commits this" | Assign the service layer |

## Trade-offs and exceptions

- "When possible" matters: some systems cannot avoid a remote call in the middle of a unit of work. Keep it short, set time limits (`release-it` covers that), and write the reason down.
- If the ORM already implements a unit of work and identity tracking, use it rather than writing another; the rule is that its scope and flush behavior are understood.
- Read-only use cases may not need an explicit transaction; if the project always opens one, keep that convention.
- Cross-system consistency semantics (sagas, outbox, exactly-once delivery) are the subject of `data-intensive-apps`, not of this book.

## Verification

- [ ] One place per use case begins and ends the transaction.
- [ ] No helper, repository, mapper or domain object commits.
- [ ] No remote call lies between begin and commit, or the reason is written down.
- [ ] Writes are registered with a unit of work or issued by the service.
- [ ] A test proves a late failure leaves nothing partially saved.
- [ ] The tests pass.

## Related

`enterprise-patterns-service-layer` for where the boundary sits; `enterprise-patterns-offline-locking` for conflicts across requests; `enterprise-patterns-loading-behavior` for identity and reads; `enterprise-patterns-transaction-reviewer` to review a diff.

## Source

- `Concurrency and Transaction Rules`
- `Transaction Boundaries`
- `Unit of Work`
- `Identity, Caching, and Unit-of-Work Rules`
- `Unclear Transaction Ownership`
- `Testing Rules`: only the rule to test workflow transaction behavior.
