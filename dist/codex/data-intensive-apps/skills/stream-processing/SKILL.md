---
name: "stream-processing"
description: "Use when writing or reviewing a stream processor, windowed aggregate, stream join, change data capture or event sourcing. Sets event, processing and ingestion time, windows, lateness, state, checkpoints and guarantees. Batch is batch-jobs; one handler's retries are idempotent-handlers."
---

# Stream processing, CDC and event sourcing

Defines what time means in an unbounded pipeline, how state survives restarts, and what each path from source to sink guarantees. Rerunnable bounded jobs are `$data-intensive-apps:batch-jobs`; the identity and shape of events are `$data-intensive-apps:event-design`; making one handler safe to run twice is `$data-intensive-apps:idempotent-handlers`; keeping the target copy repairable is `$data-intensive-apps:derived-data`.

## When to use

- You write or change a consumer that aggregates, joins or enriches events over time.
- A metric is "per minute" or "per day", and events can arrive late, early or twice.
- A system copies data from a database with change data capture, or builds state by replaying an event log.
- A processor keeps local state (counts, sessions, join tables) that must survive a restart.
- A design says the pipeline is "exactly once" or "real time".

## Rules

1. **Keep event time, processing time and ingestion time apart.** Event time is when it happened, ingestion time is when the system first received it, processing time is when this step handled it. Check: every timestamp field is named for which one it is. Added judgment: windows use event time unless the metric is about the processor itself.
2. **For any stream whose output affects correctness, settle its windowing, its handling of late data, its joins, where state is stored, its checkpoints and its fault tolerance.** Check: each is in the design note for any pipeline whose output someone relies on.
3. **Regard change data capture, event sourcing and log-based synchronization as ways to derive and propagate data; none of them makes anything consistent by itself.** Check: no claim that the target equals the source at all times; lag, ordering and failure behavior are documented.
4. **Declare, for every source-to-sink path, whether processing is at-most-once, at-least-once or exactly-once.** Check: a table lists each path, its guarantee and the mechanism (idempotent sink, transactional offset and output, deduplication).
5. **Have every consumer cope with lag, duplicate delivery, restarts and replay.** Check: `$data-intensive-apps:idempotent-handlers` applies to every consumer, and lag is a metric.
6. **Do not count on consumers always keeping pace.** A consumer that falls behind a retention limit loses data. Check: retention exceeds the longest plausible outage plus catch-up time, and lag has an alert.
7. **Prove duplicate, replay, ordering, retention, side-effect and recovery safety when adding retries, consumers, CDC, event sourcing or stream processors.** Compact rule. Check: each of the six is addressed in the change, with a test where one is feasible.
8. Added judgment: **State a lateness policy.** How long the window stays open for stragglers, and what happens to events after it closes: drop with a count, send to a correction path, or reopen. Check: the code has a branch and a metric for the late case.
9. Added judgment: **Checkpoint the input position and the processor state together.** Recovery then restores a consistent pair rather than state from one moment and a position from another. Check: both are written in one atomic checkpoint, or the state is idempotent to replay.
10. Added judgment: **Say which side of a join holds state and how it is rebuilt.** A join of a stream with a table needs the table as a changelog that is bootstrapped before the stream is processed. Check: the join's state source, bootstrap and time alignment are written.
11. Added judgment: **If an event log is the source of truth, treat views as derived.** Keep snapshots to bound replay time and plan retention for the history you rely on. Check: the rebuild-from-log time is known and acceptable.

## Procedure

1. Write the pipeline as source, processor, sink for each path.
2. Name the time attribute used for each aggregation and why.
3. Choose window type and size, allowed lateness and the late-event policy.
4. List the state the processor keeps and where it is stored, how it is checkpointed and how it is restored.
5. For each path write the delivery guarantee and the mechanism that achieves it.
6. Check retention and lag alerts against failure scenarios.
7. Add tests for duplicates, reordering, late events and restart (`$data-intensive-apps:data-path-tests`).

## Example

```ts
const WINDOW_MS = 60_000;
const ALLOWED_LATENESS_MS = 120_000;

// Before: counts per minute of when the processor happened to see the event. After an outage the backlog
// lands in the current minute, and a replay counts everything again in a different minute.
function onClickBefore(_e: ClickEvent) {
  bump(Math.floor(Date.now() / WINDOW_MS) * WINDOW_MS);
}

// After: the window comes from event time; a watermark decides when a window is complete;
// events that arrive after that are handled on purpose. (Deduplicate on e.eventId before this step.)
let watermark = 0;                                    // events older than this are assumed to have arrived

function onClick(e: ClickEvent) {
  const start = Math.floor(e.occurredAt / WINDOW_MS) * WINDOW_MS;
  watermark = Math.max(watermark, e.occurredAt - ALLOWED_LATENESS_MS);
  if (start + WINDOW_MS <= watermark) {               // the window was already emitted
    metrics.inc("clicks.late");
    corrections.append(e);                            // handled by a correction path, not silently dropped
    return;
  }
  bump(start);
}

function emitClosedWindows() {
  for (const start of openWindowStarts()) {
    if (start + WINDOW_MS <= watermark) emitAndForget(start);
  }
}
```

Replaying the same events in the same order now gives the same counts. In a different order, which events count as late can change, so per-window counts can differ; the on-time counts plus the correction path together still account for every event once.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Clock as event time | `Date.now()` or `now()` where the event's own time belongs | Use the timestamp carried in the event |
| No lateness policy | Windows close with no rule for stragglers | Allowed lateness, count and correction path |
| Unbounded state | A map keyed by id that never expires | Expiry tied to window or session close |
| CDC as consistency | "The replica is always in sync" | Document lag and ordering |
| Position and state apart | Offsets committed separately from state | One checkpoint, or replay-idempotent state |
| Slow-consumer blindness | No lag alert, retention shorter than outages | Alert and size retention |

## Trade-offs and exceptions

- Added judgment: processing time is the right clock for monitoring the processor (throughput, backlog age). The point is not to use it for business time by accident.
- Added judgment: a longer allowed lateness gives more complete results and more state and delay; a shorter one gives timely results and more corrections.
- Added judgment: exactly-once effects can be built from at-least-once delivery plus idempotent sinks, or come from an engine that commits input position and output together. Either way, name the mechanism.
- Added judgment: event sourcing buys auditability and rebuild at the price of schema evolution on history and longer recovery; use it where the history is the product.

## Verification

- [ ] Each timestamp is named as event, processing or ingestion time and windows use the right one.
- [ ] Window size, allowed lateness and the late-event policy are written.
- [ ] State and input position are checkpointed together or replay is idempotent.
- [ ] Each source-to-sink path has a stated guarantee and mechanism.
- [ ] Retention, lag alerts and restart behavior were checked together.
- [ ] Tests cover duplicate, reordered, late and restart cases.

## Related

`$data-intensive-apps:batch-jobs` for bounded jobs; `$data-intensive-apps:event-design` for events; `$data-intensive-apps:idempotent-handlers` for consumers; `$data-intensive-apps:derived-data` for the targets; `data-intensive-apps-stream-reviewer` to review a diff.

## Source

- `Batch and Stream Processing Rules`: the rules on time semantics, windowing and state, change data capture and event sourcing, and source-to-sink guarantees.
- `Event, Log, and Stream Rules`: only the rule that consumers must tolerate lag, duplicates, restart and replay, and the anti-pattern of assuming consumers keep up.
