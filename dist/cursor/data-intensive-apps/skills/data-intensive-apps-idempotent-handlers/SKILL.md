---
name: "data-intensive-apps-idempotent-handlers"
description: "Use when code may run twice: command handlers, queue consumers, jobs, webhooks, retried calls, or any exactly-once claim. Applies deduplication keys and idempotent state transitions. Event order is ordering-scope; a caller's timeout is write-acknowledgment."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Idempotent handlers and replay safety

Makes work that can be delivered, retried or replayed more than once produce the same result as running it once. Order and versioning of different messages is `data-intensive-apps-ordering-scope`; what a caller does after a timeout is `data-intensive-apps-write-acknowledgment`; windows and delivery guarantees across a pipeline are `data-intensive-apps-stream-processing`.

## When to use

- You write or review a queue consumer, webhook endpoint, scheduled job, saga step or event processor.
- A client or framework retries on timeout, and the endpoint creates, charges or sends something.
- A broker, queue or stream is described as "exactly once" or "no duplicates".
- A job is restarted from a checkpoint or reprocessed from the beginning.
- A counter, balance or total is changed by "add one" or "subtract the amount" inside a handler.

## Rules

1. **Make each command, job and event handler safe to run more than once wherever a retry can follow an unconfirmed delivery or acknowledgment.** Delivery is uncertain whenever the sender cannot see the handler finish. Check: run the handler twice with the same input; the end state and the external effects equal one run.
2. **Prefer to make repeats harmless, either by recording a deduplication key or by writing the effect as a set-to-value transition.** "Set status to shipped" repeats safely; "add 5 to the balance" does not, and needs a key. Check: each handler either records a key atomically with its effect or expresses the effect as a set-to-value transition.
3. **Make processing converge to the same result when part of it is run again after a crash.** A restart resumes from the last committed position, which may be before work already done. Check: restart from the last checkpoint and from the beginning; the state converges to the same result.
4. **Never build on an exactly-once claim unless the boundary it applies to really delivers it and the design demonstrates that.** Check: any "exactly once" claim names the boundary that provides it (for example one transaction covering the input position and the output) and has a test.
5. **Do not let a retry charge, place or send the same thing twice.** Check: external side effects carry a stable key derived from the business operation, not a fresh random value per attempt.
6. **Do not ship an unguarded handler whose side effect is harmful when repeated.** Check: every call to an external system inside a handler is idempotent by key, or is separated into a retried step that is.
7. **Do not let a processor's correctness rest on duplicates being unlikely.** Check: the correctness argument does not contain the word "unlikely".
8. **Do not expect a broker or queue to remove every duplicate for you.** Check: the handler is correct under redelivery even if the broker is configured for the best guarantee it offers.
9. Added judgment: **Write the deduplication record in the same transaction as the effect it guards.** A "seen" marker stored before or after the effect, in a different store, reopens the window the key was meant to close. Check: the marker and the state change commit together.
10. Added judgment: **Derive the key from the business operation, such as `order-id` plus step name.** A UUID generated per attempt differs on every retry and dedups nothing. Check: two attempts of the same operation produce the same key.
11. Added judgment: **Keep dedup records as long as a duplicate can still arrive** (the longest retry, redelivery or replay horizon), or choose a naturally idempotent transition so none is needed. Check: the retention of the dedup table is stated next to the broker's and the job's replay horizon.

## Procedure

1. List the handler's effects in order: state changes in your own store, messages sent, external calls.
2. For each effect, decide: naturally idempotent, or needs a key. Give external calls a key derived from the operation.
3. Put the key check and the state change in one transaction; make outbound effects follow from that state (an outbox or a retried step), not run inline before the commit.
4. Decide the dedup retention from the longest redelivery or replay window.
5. Write the argument for the delivery guarantee: at-least-once with an idempotent handler is the default design; exactly-once needs the boundary named.
6. Add the duplicate-delivery and replay tests (`data-intensive-apps-data-path-tests`).

## Example

```python
# Before: a redelivered PaymentCaptured event adds the amount again and sends a second receipt
def handle_payment_captured(event):
    db.execute("UPDATE revenue SET total = total + %s WHERE day = %s", [event.amount, event.day])
    mailer.send_receipt(event.customer_id, event.order_id)

# After: the event id is recorded in the same transaction as the effect; the receipt is an outbox row
# with its own stable key (outbox.dedup_key is unique), sent by a relay that may itself repeat.
def handle_payment_captured(event):
    with db.transaction() as tx:
        first_time = tx.execute(
            "INSERT INTO processed_events (event_id) VALUES (%s) ON CONFLICT DO NOTHING",
            [event.id]).rowcount == 1
        if not first_time:
            return                                   # duplicate delivery: already applied
        tx.execute("UPDATE revenue SET total = total + %s WHERE day = %s", [event.amount, event.day])
        tx.execute(
            "INSERT INTO outbox (dedup_key, kind, payload) VALUES (%s, 'receipt', %s) ON CONFLICT DO NOTHING",
            [f"receipt:{event.order_id}", json.dumps({"customer_id": event.customer_id, "order_id": event.order_id})])

# relay (separate process): read unsent outbox rows, call mailer.send(..., idempotency_key=row.dedup_key), mark sent.
# A crash between the send and the mark causes a second send with the same key, which the mailer collapses.
```

This is the at-least-once-plus-idempotence design: the broker may deliver twice, the handler applies once.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Counter on redelivery | `+= amount` or `count++` inside a consumer with no key | Dedup key in the same transaction, or recompute from facts |
| Random key per attempt | `uuid4()` created inside the retry loop | Derive the key from the operation |
| Check then act | `if not seen(id): act(); mark(id)` as separate steps | One transaction, or a unique constraint |
| Trusting the broker | Comments or docs saying the queue guarantees exactly once | Handler correct under redelivery |
| Side effect before commit | Email or API call before the database commit | Outbox, or a keyed retried step after commit |

## Trade-offs and exceptions

- Exactly-once effects are possible inside a closed system that commits the input position and the output together (some stream processors, a database transaction that includes the offset). The rule is to name that boundary and prove it, not to forbid the claim.
- Added judgment: at-most-once is acceptable for lossy telemetry or advisory notifications, when stated.
- Added judgment: dedup tables grow; prune by the replay horizon, or prefer naturally idempotent transitions.
- Added judgment: a handler that must not run twice but cannot be keyed (a physical action) needs a human or a compensating step. Say so rather than hide it.

## Verification

- [ ] Running the handler twice with the same input gives the state and external calls of one run.
- [ ] Every external effect has a key derived from the business operation.
- [ ] The dedup marker commits atomically with the state it guards.
- [ ] Restart from the checkpoint and from the beginning produce the same state.
- [ ] No comment or design note relies on a broker's no-duplicates promise.

## Related

`data-intensive-apps-ordering-scope` for reordering; `data-intensive-apps-write-acknowledgment` for callers; `data-intensive-apps-transactions-and-isolation` for outbox and atomicity; `data-intensive-apps-replay-drill` to walk a consumer through duplicate and replay scenarios; `data-intensive-apps-idempotency-reviewer` to review a diff; `data-intensive-apps-idempotency-hardener` to implement the fix.

## Source

- `Idempotency and Replay Rules`
- `Exactly-Once Wishful Thinking`
- `Reliability Rules`: only the anti-pattern on side effects that cannot be retried safely.
