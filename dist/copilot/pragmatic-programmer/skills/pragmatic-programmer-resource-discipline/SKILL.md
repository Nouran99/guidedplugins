---
name: "pragmatic-programmer-resource-discipline"
description: "Use when code acquires files, connections, locks, handles, temp state or memory, or loops over data whose size can grow. Covers release on every path and in opposite order, ownership and algorithmic growth. Failure classification is `pragmatic-programmer-error-recovery`; who may mutate shared state is `pragmatic-programmer-shared-state`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Resource discipline

Finish what you start, and know how cost grows. This skill covers anything acquired and later owed back (files, connections, locks, transactions, temporary files, subprocesses, buffers) and the growth of time and memory with input size. How failures are classified and contained is `pragmatic-programmer-error-recovery`; whether state should be shared at all is `pragmatic-programmer-shared-state`.

## When to use

- Code opens, locks, connects, allocates or starts something that must be closed, released or stopped.
- A resource is acquired in one function and released in another, or returned to the caller.
- A loop runs over a collection that can grow, and each iteration searches, queries or copies.
- You are reviewing code on a performance-sensitive path.

## Rules

1. **Finish what you start when allocating, opening, locking or otherwise acquiring resources.** [MUST] Check: for every acquire you can point to its matching release.
2. **Release every resource you acquire.** [MUST] Check: the release is reached on success, on every error path and on early return.
3. **Release in the opposite order from acquisition.** [SHOULD] The source says "preferably". Check: the resource acquired last is released first, as nested scoped constructs and deferred calls do.
4. **Keep resource ownership local and explicit.** [MUST] Check: acquire and release sit in the same function or the same owner object; any hand-off is documented where it happens.
5. **Treat resource ownership as a contract.** [Compact checklist] When a resource crosses a boundary (returned, passed in, stored in a field), say who closes it. Check: a function that returns a handle states that the caller owns it.
6. **Release on both success and failure paths.** [Compact checklist] Check: a test or a read-through covers the failure path for each resource.
7. **Use the language's scoped construct.** [Added judgment] `with` in Python, `defer` in Go, try-with-resources in Java, `using` in C#, destructors in C++ and Rust. Check: no manual `close()` sits at the end of a block that can exit early.
8. **Understand algorithmic growth before writing or accepting performance-sensitive code.** [MUST] Check: for each loop over data that can grow you can state the size variable and how time and memory scale with it.
9. **Look for the usual growth traps.** [Added judgment] Nested scans of two collections, a membership test on a list inside a loop, a query per item, string building by repeated concatenation, and collections kept whole in memory. Check: the loop bodies on the changed path contain none, or a note says why the size stays small.
10. **Measure before micro-tuning.** [Added judgment] Understanding growth is not permission to optimize everything; a better algorithm on a hot path first, constants after a measurement. Check: any optimization beyond fixing the growth cites a measurement.
11. **Count more than handles as resources.** [Added judgment] Locks, transactions, temporary files and directories, subprocesses, background tasks, subscriptions and toggled flags are all owed back. Check: the list of acquisitions in the change includes them.

## Procedure

1. List every acquisition in the changed code, including indirect ones (a library call that returns a handle).
2. For each, find the release and trace every exit: normal, each error, early return, cancellation.
3. Convert manual releases to the scoped construct. Check the order.
4. Write the owner for any resource that crosses a function boundary.
5. List the loops on the changed path over data that can grow. State the size variable and the growth.
6. Fix growth traps where the fix is local; flag the rest with the size at which they hurt.
7. Run the tests, including a failure path for each acquired resource.

## Example

```python
# Before: both resources leak when format_row raises; release order is accidental
def export_orders(path):
    conn = sqlite3.connect(DB_PATH)
    out = open(path, "w")
    for row in conn.execute(QUERY):
        out.write(format_row(row))       # a bad row raises here and nothing is closed
    out.close()
    conn.close()

# After: scoped constructs; out is released first because it was acquired last
def export_orders(path):
    with contextlib.closing(sqlite3.connect(DB_PATH)) as conn, open(path, "w") as out:
        for row in conn.execute(QUERY):
            out.write(format_row(row))
```

Growth in the same module:

```python
# Before: O(n * m): a list membership test for every order
banned = load_banned_ids()                              # list of m ids
flagged = [o for o in orders if o.customer_id in banned]

# After: O(n + m)
banned = set(load_banned_ids())
flagged = [o for o in orders if o.customer_id in banned]
```

`sqlite3.connect` does not close on `with` (the context manager only ends a transaction), so `contextlib.closing` is what releases the connection.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Close at the end | `close()` as the last statement of a block with early exits | Scoped construct |
| Acquire without owner | A function returns a handle with no statement of who closes it | Document ownership or return a managed object |
| Release on success only | `finally`, `defer` or `with` missing around the use | Release on every path |
| Leaked temp state | Temp files, locks or subprocesses with no cleanup | Scoped cleanup, even on error |
| Membership test on a list | `x in some_list` inside a loop | Use a set or a map |
| Query per item | A database or network call inside a loop over results | Batch or join |
| Whole collection in memory | Reading everything before processing | Stream or page |

## Trade-offs and exceptions

- "Preferably" in the source means opposite-order release is a strong default, not an absolute; independent resources may be released in any safe order.
- Process-lifetime resources (a connection pool created at startup) are owned by the application and released at shutdown; local ownership applies to what a function acquires for its own use.
- Understanding growth does not mean tuning. When the input is small and bounded, a simple quadratic loop is fine; write down the bound (Added judgment).
- Pool sizing, deadlines and overload behavior belong to a Release It! plugin; this skill covers release and growth.

## Verification

- [ ] Every acquisition in the change has a release reached on success and failure.
- [ ] Scoped constructs are used wherever the language provides them.
- [ ] Any resource that crosses a function boundary has a stated owner.
- [ ] Each loop over growing data has a stated size variable and growth.
- [ ] No growth trap remains on the changed path without a note about the size bound.

## Related

`pragmatic-programmer-resource-reviewer` to review a diff; `pragmatic-programmer-error-recovery` for failure classification; `pragmatic-programmer-shared-state` for locks and shared mutation; `pragmatic-programmer-test-portfolio` for exhaustion and performance tests.

## Source

- `Resource and Coupling Rules`: only the rules on finishing what you start, releasing every resource, local and explicit ownership, and understanding algorithmic growth.
