---
name: resource-budgets
description: "Use when code takes threads, database connections, sockets, file descriptors, memory or CPU worker slots, holds a lock or connection across a slow call, or loads or returns large collections. Covers budgets, release, streaming, pagination. Splitting capacity by workload is `bulkheads`."
---

# Resource budgets

Every scarce resource is finite, and the thing that exhausts it is usually something slow holding it. This skill sets the budget for one resource and makes sure it is released; dividing capacity between workloads is `/release-it:bulkheads`, and the buffers between producers and consumers are `/release-it:queues`.

## When to use

- Code acquires a connection, thread, socket, file handle, lock, semaphore permit or large buffer.
- A pool size, thread count or batch size is being chosen or looks like a guess.
- A remote call, file read or sleep happens while a connection, transaction or lock is held.
- A query, endpoint or job returns or loads everything at once.

## Rules

1. **Budget scarce resources explicitly.** [MUST] The source names threads, database connections, sockets, file descriptors, memory and CPU-intensive worker slots. Check: each has a number in code or configuration and a known set of consumers.
2. **Derive pool sizes, then keep checking them.** [MUST NOT size by guess and ignore it] Check: the size has a reason (expected concurrency times per-request use, and the sum over all instances stays below what the database or peer allows) and a saturation metric. The arithmetic is an Added judgment; the requirement is that the size is not a guess left alone.
3. **Release resources deterministically.** [MUST] Use the language's scoped construct (`try`-with-resources, `defer`, `with`, `using`) so release happens on every exit path, including exceptions, timeouts and cancellation. Check: every acquire has a release that cannot be skipped by an early return.
4. **Do not hold locks or expensive connections across slow remote calls.** [MUST NOT] A connection held during an HTTP call is a connection nobody else can use for as long as that call takes. Check: no network call, sleep or file transfer sits between acquiring and releasing a connection, transaction or lock.
5. **Use streaming or pagination for large payloads where appropriate.** [MUST, source qualifier: where appropriate] Check: no endpoint or query returns an unbounded collection; loops fetch in pages with a stated size.
6. **Guard memory-heavy operations.** [MUST] Check: request bodies, uploads, decompression, sorting and aggregation have size limits enforced at the boundary.
7. **Do not default to one huge in-memory batch.** [MUST NOT] Check: unbounded `fetchall()`, `readAll()`, `collect()` and `toList()` calls are justified or replaced.
8. **Do not block worker threads on slow I/O when a better model exists.** [MUST NOT] Check: blocking calls on an event loop or on a small request pool are moved to async I/O or a dedicated pool.
9. **Bound the wait for the resource itself.** [Added judgment, following from the rule against infinite waits] A pool checkout without a timeout turns exhaustion into a hang. Check: acquisition has a time limit and a defined failure (`/release-it:timeouts`).
10. **Give list APIs a default and a maximum page size.** [Added judgment] Check: a caller cannot ask for an unlimited page.
11. **Make usage visible.** [MUST, saturation signals are in the minimum metrics] Check: in use, idle, waiting and rejected counts exist per pool (`/release-it:metrics`).

## Procedure

1. List the resources the change acquires and where each is released.
2. For each, write the budget and the arithmetic behind it, including how many instances share the peer.
3. Move slow calls out from between acquire and release; reorder, fetch first and then acquire, or release and re-acquire.
4. Replace unbounded loads with pages or streams, and cap request sizes.
5. Add a timeout to the acquisition and a metric for waiting.
6. Test with the pool exhausted and with the largest allowed payload.

## Example

```python
# Before: holds a pooled connection across a slow remote call, loads every row, and never returns
# the connection if archive_api.put raises.
def export_orders(customer_id):
    conn = pool.getconn()
    rows = conn.execute(
        "select id, total_cents, placed_at from orders where customer_id = %s", (customer_id,)
    ).fetchall()
    for row in rows:
        archive_api.put(row)
    pool.putconn(conn)

# After: one short query per page, the connection is released before the slow call, and memory
# is bounded by the page size. Keyset pagination keeps each query cheap.
def export_orders(customer_id, page_size=500):
    last_id = 0
    while True:
        with pool.connection() as conn:                      # held only for the query
            page = conn.execute(
                "select id, total_cents, placed_at from orders "
                "where customer_id = %s and id > %s order by id limit %s",
                (customer_id, last_id, page_size),
            ).fetchall()
        if not page:
            return
        for row in page:
            archive_api.put(row)                              # slow call with no connection held
        last_id = page[-1][0]
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Connection held across a remote call | A network call between `getconn` and `putconn`, or inside a transaction | Reorder, or release and re-acquire |
| Pool sized by guess | A round number with no comment, no metric, same on every instance | Derive, then watch saturation |
| Leaked resource | Release only on the success path | Scoped construct |
| Unbounded load | `fetchall()`, `readAll()`, `collect()` on a growing source | Page or stream |
| Blocking on the event loop | Synchronous I/O in an async handler | Async I/O or a dedicated pool |
| Unlimited upload or response | No body-size or page-size limit | Limit at the boundary |

## Trade-offs and exceptions

- Releasing a connection before a slow call means the work no longer shares one transaction. If the steps need a single atomic unit, restructure so the slow call comes before or after it; consistency semantics are outside this book (use a data-systems plugin such as `data-intensive-apps`).
- Streaming keeps a cursor open for longer. Prefer pagination when the consumer is slower than the producer.
- The source says "where appropriate" for streaming and pagination; a bounded result of ten rows needs neither.
- Offset pagination degrades on large tables and can skip or repeat rows under writes; keyset pagination avoids both (Added judgment).

## Verification

- [ ] Each scarce resource touched by the change has a stated budget.
- [ ] Release happens on every path, including failure and cancellation.
- [ ] Nothing slow runs while a connection, transaction or lock is held.
- [ ] No query, endpoint or job loads or returns an unbounded collection.
- [ ] Acquisition has a time limit and pool saturation is observable.

## Related

`/release-it:bulkheads` for partitioning; `/release-it:queues` for buffers; `/release-it:timeouts` for acquisition waits; `/release-it:data-boundaries` for size limits on input; `release-it:resource-reviewer` to review a diff; `release-it:overload-hardener` to apply bounds.

## Source

- `Resource Management Rules`
- `Code Generation Rules`: only the default of bounded resources.
