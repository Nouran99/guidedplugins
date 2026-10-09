---
name: write-acknowledgment
description: "Use when a write, command or request ends in success, timeout or error and you must say what happened: accepted, persisted, applied or durable, including unknown outcomes. Run-twice receivers are idempotent-handlers; atomicity is transactions-and-isolation."
---

# Write acknowledgment and unknown outcomes

Decides what a "success" answer means, what the caller may do after silence or an error, and how the system recovers when a step dies halfway. Making the receiver safe to run twice is `/data-intensive-apps:idempotent-handlers`; the atomicity and isolation of the writes themselves is `/data-intensive-apps:transactions-and-isolation`; the clock and lease assumptions behind timeouts are `/data-intensive-apps:faults-and-coordination`.

## When to use

- An endpoint, job or message handler returns a single `ok`, `201` or `true` after doing several things.
- Code treats a timeout, a connection reset or a 5xx from another system as proof that the work did not happen.
- A write is acknowledged to the user before it reached storage, or before a downstream effect (event, cache, email) happened.
- You are asked what happens if the process dies right after the database commit, or right before the publish.

## Rules

1. **Take crashes, partial writes, duplicate work, timeouts and stale reads as expected inputs to the design, not exceptions to it.** A design that only works when nothing fails has no specification for the day something does. Check: for the write path you can state the outcome of a crash after each step.
2. **State what a write acknowledgment promises.** The caller should know whether "ok" means queued, written to the primary, applied everywhere, or replicated to a quorum. Check: the API contract, type or doc names the level, and a test asserts it.
3. **Tell accepted, persisted and applied apart.** Accepted means the system took responsibility, persisted means it is on durable storage, applied means the visible effects exist. Check: no single boolean `success` stands for all three; response codes or states differ.
4. **Avoid unstated assumptions about when a write has durably succeeded.** Name the point after which the data survives a crash (commit returned, broker ack with the configured replication level, fsync). Check: you can point at the line that is the durability point.
5. **Do not read one successful response as proof that every downstream effect happened.** The database commit says nothing about the event, the cache or the email. Check: each downstream effect is in the same transaction, recorded as an intent that is retried, or documented as allowed to be lost.
6. **Plan for restarts, replays and recovery from partial failure.** After a crash the system has to converge without a human. Check: stop the process between any two steps of the write path in a test; the restarted system reaches a consistent state.
7. **Treat a timeout as an unknown outcome, not a failure.** The source says not to infer remote failure or success from a timeout alone. Check: on timeout the code records "unknown" and resolves it (lookup by the same key, reconciliation), rather than undoing local state or telling the user it failed.
8. **State the write-path facts when you change a write path.** Compact rule: name the source of truth, consistency boundary, durability point, visibility point, downstream effects, rollback or repair path, and the behavior after timeout or unknown success. Check: the change description or a code comment has each item.
9. Added judgment: **Give accepted-but-not-applied work a status the client can read.** Return an identifier and a status resource, or push a completion event, so "accepted" does not become a silent promise. Check: a client holding only the response can find out the final state.
10. Added judgment: **Record an unknown outcome durably as its own state and give it an owner.** A reconciler job or a human queue moves it to success or failure. Check: grep for the unknown state shows a writer and a resolver.

## Procedure

1. List the steps of the write path in order: validation, each store write, each message, each external call, the response.
2. After each step write down what is durable and what is visible to other readers.
3. For each step ask two questions: what if the process dies here, and what if the call to the next system times out here?
4. Choose the caller-visible states (for example `accepted`, `completed`, `failed`, `unknown`) and the response for each.
5. For every unknown-outcome case decide how it is resolved: a lookup by stable key, a reconciler, or a documented loss.
6. Put the durability point and the resolution path in the code or docs next to the handler.
7. Add a crash-between-steps test and a timeout test with a fake that times out after performing the effect.

## Example

```ts
// Before: a timeout from the payment provider is treated as "not charged"
async function charge(orderId: string): Promise<void> {
  try {
    await payments.capture(orderId);            // may time out AFTER the provider captured
  } catch (e) {
    await orders.setStatus(orderId, "payment_failed");   // customer may be charged and the order marked failed
    throw e;
  }
  await orders.setStatus(orderId, "paid");
}

// After: a timeout is its own state, with the same key on every attempt and a resolver
type PaymentState = "paid" | "payment_failed" | "payment_unknown";

async function charge(orderId: string): Promise<PaymentState> {
  const key = `capture:${orderId}`;                      // stable across retries, derived from the operation
  let res: CaptureResult;
  try {
    res = await payments.capture(orderId, { idempotencyKey: key, timeoutMs: 3000 });
  } catch (e) {
    if (!isTimeout(e)) throw e;
    await orders.setStatus(orderId, "payment_unknown");  // durable; a reconciler resolves it
    return "payment_unknown";
  }
  const state: PaymentState = res.status === "captured" ? "paid" : "payment_failed";
  await orders.setStatus(orderId, state);
  return state;
}

// Reconciler: payments.lookup(key) returns captured | not_found; it moves payment_unknown to paid or payment_failed.
```

The example assumes the provider honors idempotency keys and offers a lookup by key. Where it does not, the unknown state needs a human or a statement-based reconciliation instead.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Boolean success | A function returns `true`/`ok` for queued, stored and delivered alike | Separate states or response codes |
| Timeout equals failure | `catch (timeout)` rolls back local state or reports failure | Record unknown, resolve by key |
| Commit then hope | Event publish or cache fill after the commit with errors ignored | Same transaction, a durable intent, or a documented loss |
| Early acknowledgment | Response sent before the durability point | Move the response after it, or return `accepted` with a status resource |
| Undocumented durability | Nobody can say when a write survives a crash | Name the point and the replication level |

## Trade-offs and exceptions

- Loss may be acceptable for sampled metrics or best-effort telemetry. State that decision in the code; do not leave it implicit.
- Waiting for every replica before acknowledging costs latency and availability. Choosing a lower level is legitimate when the loss window is written down (`/data-intensive-apps:replication-topology`).
- Internal calls inside one database transaction do not need accepted/persisted/applied states; the distinction matters at boundaries between systems.
- Do not add a status resource for operations that complete synchronously and atomically.

## Verification

- [ ] The response or return type distinguishes accepted, persisted and applied where they differ.
- [ ] The durability point is named in the code or docs.
- [ ] A timeout never triggers a rollback of local state or a "failed" message without a way to resolve it.
- [ ] Every downstream effect has a stated mechanism (same transaction, retried intent, or accepted loss).
- [ ] A test stops the flow between two steps and checks the restarted state.

## Related

`/data-intensive-apps:idempotent-handlers` for the receiver; `/data-intensive-apps:transactions-and-isolation` for atomicity of the writes; `/data-intensive-apps:faults-and-coordination` for timeouts and clocks; `/data-intensive-apps:write-path-trace` for the step-by-step walk; `data-intensive-apps:write-path-reviewer` to review a diff.

## Source

- `Reliability Rules`
- `Primary Directive`: only the questions on retries, duplicates and partial failure, and the question of what is durable, cached, derived or ephemeral.
- `Write Semantics`: only the durability bullet.
- `Distributed Fault, Clock, and Consensus Rules`: only the rule not to infer remote failure or success from a timeout.
- `Replication Rules`: only the rule on stating synchronous and asynchronous trade-offs, used for the acknowledgment-level trade-off.
