---
name: "queues"
description: "Use when adding or reviewing a queue, buffer, channel, consumer, work list or dead-letter setup, or when producers can outpace consumers. Covers bounds, full behavior, depth and age monitoring, parking failing messages. Message validity is `$release-it:data-boundaries`; entry-point overload is `$release-it:back-pressure`."
---

# Queues and buffers

A queue is a buffer that absorbs a short mismatch between producers and consumers. It is not storage, and an unbounded one converts overload into memory exhaustion or a backlog nobody can drain. The policy at the door is `$release-it:back-pressure`; sizing threads and connections is `$release-it:resource-budgets`.

## When to use

- A new in-memory queue, channel, executor work queue, broker topic, job table or retry list.
- A consumer processes messages that can fail, and failed messages come back.
- Backlog, memory or disk use grows when consumers slow down.
- A dead-letter queue exists but nobody watches it, or does not exist at all.

## Rules

1. **Treat queues as buffers, not infinite storage.** [MUST] Check: every queue has a stated capacity and a stated reason for that size.
2. **Bound every queue.** [MUST NOT leave unbounded queues] This covers in-memory structures, executor work queues, broker length and retention, log buffers and job tables. Check: constructors and settings that default to unbounded (`new LinkedBlockingQueue<>()`, an unbuffered-growth list, a topic with infinite retention) are flagged.
3. **Know what happens when producers outpace consumers.** [MUST] Choose among blocking with a timeout, rejecting, dropping the oldest or newest, spilling to durable storage, or scaling consumers, and write down why. Check: a test fills the queue and observes the chosen behavior.
4. **Give the producer a signal when the queue is full.** [Added judgment, following from "reject, defer, queue or degrade intentionally"] A `put` that silently drops or blocks forever hides the problem. Check: the enqueue call returns a result or raises, and callers handle it.
5. **Monitor length, age, throughput and failure rate.** [MUST] Age (how long the oldest item has waited) shows a stalled consumer that length alone can hide. Check: all four exist as metrics, and age has an alert (`$release-it:metrics`).
6. **Define dead-letter or poison-message handling explicitly.** [MUST] One message that always fails must not block the consumer or loop forever. Check: delivery attempts are capped, failures are parked with a reason, and the parking place is itself bounded and monitored.
7. **Do not accept work with no plan to finish it.** [MUST NOT] Attach a deadline or time-to-live where the result stops mattering, and discard expired items instead of processing them (Added judgment on the TTL). Check: old items are expired by rule, not processed because they happen to be next.
8. **Bound the processing time of each item.** [Added judgment, following from the timeout rules] A consumer stuck on one item stops the whole partition. Check: each handler call has a time limit (`$release-it:timeouts`).
9. **Treat redrive as a controlled operation.** [Added judgment] Replaying a dead-letter queue all at once recreates the overload that produced it. Check: redrive is rate-limited, visible and can be stopped (`$release-it:operational-controls`).
10. **Do not let best-effort items starve critical ones.** [MUST NOT, source: best-effort tasks crowding out critical work] Check: critical and optional work use separate queues or a priority rule.

## Procedure

1. List queues and buffers in the change, including ones hidden in libraries (executor queues, client send buffers).
2. For each: capacity, full behavior, expiry rule, consumer time limit, retry limit, parking place.
3. Add the four signals and alerts on age and dead-letter growth.
4. Make the enqueue path return a result the caller must handle.
5. Test: fill it, stall the consumer, feed it a message that always fails.

## Example

```python
import queue
import threading
import time

# Before: an unbounded queue. A slow consumer becomes unlimited memory growth, and a message that
# always raises is retried forever.
jobs = queue.Queue()

def submit(job):
    jobs.put(job)

# After: bounded, with a rejection signal, an age limit, capped attempts and a parking place.
jobs: "queue.Queue[tuple[float, Job]]" = queue.Queue(maxsize=500)
dead_letters: "queue.Queue[tuple[Job, str]]" = queue.Queue(maxsize=100)
MAX_ATTEMPTS = 3
MAX_AGE_S = 30.0
stop = threading.Event()                                   # set on shutdown so the worker can exit

def submit(job: Job) -> bool:
    try:
        jobs.put((time.monotonic(), job), timeout=0.05)   # wait briefly, then tell the producer no
        return True
    except queue.Full:
        metrics.incr("jobs.rejected_full")
        return False

def park(job: Job, reason: str) -> None:
    try:
        dead_letters.put_nowait((job, reason))
    except queue.Full:
        metrics.incr("jobs.dead_letter_overflow")          # the parking place is full too: alert

def worker() -> None:
    while not stop.is_set():
        try:
            enqueued_at, job = jobs.get(timeout=1.0)        # an idle wait on its own queue, bounded so shutdown can interrupt it
        except queue.Empty:
            continue
        waited = time.monotonic() - enqueued_at
        metrics.observe("jobs.queue_wait_s", waited)       # a stalled consumer also needs a probe on the head item
        if waited > MAX_AGE_S:
            metrics.incr("jobs.expired")                   # nobody is waiting for this result any more
            continue
        try:
            handle(job)                                     # handle() carries its own time limit
        except PermanentError as exc:
            park(job, f"permanent: {exc}")
        except TransientError as exc:
            job.attempts += 1
            if job.attempts >= MAX_ATTEMPTS:
                park(job, f"gave up after {job.attempts} attempts: {exc}")
            else:
                resubmit_with_backoff(job)
```

The numbers are examples; real ones come from consumer throughput and how long a result stays useful.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Unbounded queue | Default constructors, `maxsize=0`, topics with infinite retention | Explicit capacity and full behavior |
| Poison loop | The same message redelivered with no attempt cap | Attempt limit and a parking place |
| Invisible dead letters | A dead-letter queue with no depth metric or alert | Monitor and bound it |
| Length-only monitoring | A gauge for depth but nothing for age | Add oldest-item age |
| Stuck consumer | Handler with no time limit | Per-item timeout |
| Blocking producer in a request path | `put()` with no timeout inside a handler | Bounded wait, then reject |

## Trade-offs and exceptions

- Blocking producers pass back pressure upstream, which is good in a pipeline and dangerous in a request path where blocking holds threads. Use a bounded wait in request paths.
- Dropping the oldest suits latency-sensitive data (a stale price); rejecting the newest suits work that must not be lost. This is a product decision to state, not a default (Added judgment).
- Durable queues still need a bound on disk or retention.
- A message whose content is invalid fails the same way on every attempt. Check it at the consumer's boundary and park it at once with that reason, instead of spending the attempt budget (Added judgment; the validation rules are `$release-it:data-boundaries`).
- An idle consumer parked on its own in-process queue, holding no request, lock or connection, is not calling a dependency, so the infinite-wait ban in `$release-it:timeouts` is not aimed at it (Added judgment on the scope). The one-second poll in the example exists so the worker can notice a shutdown request; a blocking `put()` or `get()` inside a request path is a different case and stays bounded.
- Delivery guarantees, ordering and consumer idempotency are data-semantics questions outside this book; use a data-systems plugin such as `data-intensive-apps`.

## Verification

- [ ] Every queue has a capacity and a defined full behavior.
- [ ] Producers get a signal when the queue is full.
- [ ] Length, age, throughput and failure rate are observable.
- [ ] Failed messages are capped, parked with a reason and monitored.
- [ ] Items that stop mattering are expired, not processed.

## Related

`$release-it:back-pressure` for the entry-point policy; `$release-it:resource-budgets` for pools; `$release-it:scheduled-work` for jobs started by the clock; `$release-it:stability-patterns` for decoupling middleware; `$release-it:data-boundaries` for validating a message before it is enqueued or after it is taken; `release-it-overload-reviewer` to review a diff; `release-it-overload-hardener` to apply the change.

## Source

- `Queues`
- `Collapse by Queue`: only the rules against unbounded queue growth and missing poison-message handling.
- `Code Generation Rules`: only the default of bounded resources and queues.
- `Load and Capacity Rules`: only the anti-patterns on accepting work with no plan to finish it and on best-effort tasks crowding out critical work (rules 7 and 10).
