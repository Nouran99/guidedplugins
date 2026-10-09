---
name: event-design
description: "Use when defining or changing a command, event, log topic or materialized view contract, or the consumers of a durable log. Separates commands from facts and sets identifiers, metadata and versions. Payload compatibility is encoding-and-evolution; processors are stream-processing."
---

# Commands, events, logs and views

Gives each message in the system a clear kind and a stable shape: a command asks, an event states a fact, a log keeps history, a view is derived. How any payload changes over time is `/data-intensive-apps:encoding-and-evolution`; windows, lateness and delivery guarantees in processors are `/data-intensive-apps:stream-processing`.

## When to use

- You name or define a new message type, topic or table that others will consume.
- An "event" tells the consumer what to do, or carries a serialized internal object.
- A topic is used as a pipe and nobody has decided how long it is kept or whether it can be replayed.
- A consumer needs to correlate messages from several services.
- A read model is fed from events and someone asks whether it can be rebuilt.

## Rules

1. **Keep commands, events and materialized views clearly apart.** Different kinds have different failure and ownership semantics. Check: names and types differ (`CapturePayment` as a command, `PaymentCaptured` as an event, `order_summary` as a view). Added judgment: also keep commands and events on separate topics, so a consumer subscribed to facts never receives requests.
2. **An event records something that has already happened; a command asks for something to be done.** A consumer can refuse a command, but cannot dispute a fact. Check: an event carries what occurred, in the past tense, and no instruction to the consumer.
3. **Regard a log or stream as a durable history, not just a pipe that moves messages.** Check: retention, the ordering key and the replay procedure are written down for each topic.
4. **Build consumers that cope with falling behind, duplicates, restarts and replays.** Check: each consumer is safe under redelivery (`/data-intensive-apps:idempotent-handlers`) and lag is measured.
5. **Make derived projections rebuildable where feasible.** Check: a projection can be reproduced from the log and the rebuild is documented (`/data-intensive-apps:derived-data`).
6. **Identify events, and the things they concern, with identifiers that stay the same over time.** Check: an event can be recognized again after redelivery or replay, and a consumer can tell which entity it concerns. Added judgment on the means: a unique event id plus the id of the entity concerned.
7. **Carry enough metadata for events to be correlated with their causes and replayed.** Check: a consumer can relate the event to what caused it and place it in the entity's history. Added judgment, for example: when it occurred, who produced it, a correlation or causation id, and the entity version or sequence.
8. **Version payloads carefully and keep semantics explicit.** A field's meaning is part of the contract. Check: the schema has a version and a changed meaning gets a new field or type.
9. **Do not bind an event payload to a single serializer or to the producer's internal object layout.** Check: the event shape is defined in a schema independent of the producer's classes or ORM.
10. **Do not build projections that cannot be rebuilt, and do not assume consumers keep up forever.** Check: retention is longer than the slowest consumer's worst plausible outage, and lag is alarmed.
11. Added judgment: **Name the key on each event type.** The ordering and partitioning key is part of the contract (`/data-intensive-apps:ordering-scope`). Check: the schema doc says which field is the key.
12. Added judgment: **Decide thin versus fat events deliberately.** A thin event (ids only) forces consumers to call back and read newer state than the event describes; a fat event copies state that can go stale. Check: the choice and its reason are written with the schema.

## Procedure

1. Classify each message: command, event, view update. Rename or split if one message plays two roles.
2. For each event write the fact in the past tense, the entity it concerns, and the key.
3. Add the identifiers and metadata fields. Added judgment, a starting set: event id, entity id, occurred-at, producer, correlation id and entity version.
4. Define the schema separately from the producer's classes; add an explicit schema version.
5. Decide retention and replay: how long is the topic kept, who may replay it, how is a projection rebuilt.
6. List the consumers and their lag tolerance; add lag metrics and an alert.

## Example

```ts
// Before: a snapshot of whatever the ORM object looks like today, with a vague name
publish("orders", { type: "OrderUpdated", payload: JSON.stringify(orderEntity) });

// After: a named fact with identifiers, metadata and an explicit version, independent of internal classes
interface OrderShipped {
  eventId: string;          // unique per fact; consumers dedupe on it
  type: "order.shipped";
  schemaVersion: 2;
  occurredAt: string;       // ISO-8601, set by the producer when the shipment was recorded
  orderId: string;          // partition and ordering key
  orderVersion: number;     // per-order sequence so consumers can spot stale or missing facts
  correlationId: string;    // the request or process that caused it
  carrier: string;
  trackingNumber: string;
  shippedLineIds: string[];
}

function publishShipped(event: OrderShipped): void {
  publish("orders", { key: event.orderId, value: event });
}
```

The command that precedes it, `ShipOrder`, is a different type (in this sketch, on a different topic); the warehouse may reject it, but nobody can reject `OrderShipped`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Command named as event | `OrderUpdate` that tells consumers what to do | Rename and split command and fact |
| Serializer-bound payload | Java-serialized objects, ORM entities or pickles on the wire | A schema independent of the producer |
| Pipe, not history | No retention, no replay procedure | Document retention and replay |
| Missing identity | No event id, no entity id | Add stable identifiers |
| Eternal consumer | Retention shorter than a plausible outage | Longer retention, lag alarm |
| Unrebuildable view | A projection with no path back to the log | Add a rebuild (`/data-intensive-apps:derived-data`) |

## Trade-offs and exceptions

- Added judgment: domain events inside a single process or transaction boundary do not need the full metadata set; the rules matter at the boundary where others consume the message.
- Added judgment: a command may be recorded in a log as a fact that it was issued; that is a different event from the outcome of executing it.
- Added judgment: log compaction keeps only the latest record per key; it suits state-like topics and not histories that must be replayed in full.
- Event sourcing makes the log the source of truth for an entity; it is a choice with costs, covered in `/data-intensive-apps:stream-processing`.

## Verification

- [ ] Each message type is clearly a command, an event or a view update.
- [ ] Each event is identifiable across redelivery and carries enough metadata to correlate and replay it (for example event id, entity id, occurrence time, correlation id, version or sequence).
- [ ] The schema is defined independently of the producer's classes and carries a version.
- [ ] Retention, key and replay procedure are written for each topic.
- [ ] Consumer lag is measured and alarmed.

## Related

`/data-intensive-apps:encoding-and-evolution` for changing payloads; `/data-intensive-apps:ordering-scope` for key and version use; `/data-intensive-apps:idempotent-handlers` for consumers; `/data-intensive-apps:stream-processing` for processors; `data-intensive-apps:stream-reviewer` to review a diff.

## Source

- `Event, Log, and Stream Rules`
- `Event Design`
