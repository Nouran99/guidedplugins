---
name: "ddd-implementing-event-sourcing"
description: "Use when deciding whether to persist an aggregate as its sequence of events, or when writing or reviewing event streams, replay, event versions or upcasters. Storage by events only. Events as announced facts, with or without sourcing, are domain-events."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Event sourcing

Owns one persistence choice: the stored truth of an aggregate is its sequence of domain events, and state is rebuilt by replaying them. It decides when that choice is right and what must hold when it is made. The shape and naming of the events is `ddd-implementing-domain-events`; reads for clients are `ddd-implementing-client-representations`.

## When to use

- Someone proposes "let's use event sourcing" because the system already publishes domain events.
- You write an aggregate that is loaded by replaying events, or a store that appends them.
- An event's meaning or fields change after events were already stored.
- A rebuilt aggregate does not match the state it had before the restart.
- A review asks why one aggregate is event-sourced and its neighbors are not.

## Rules

1. **[MUST] Use event sourcing only when storing the sequence of domain events is the right persistence model for the aggregate.** It changes how everything is stored, read and evolved. Check: the design states what the history buys for this aggregate (a business need for the full history, replay into new read models, temporal questions) that state storage plus published events would not.
2. **[MUST NOT] Choose event sourcing just because domain events exist.** Publishing events does not require storing them as the source of truth. Check: the decision record says why state storage with events is not enough.
3. **[MUST] Keep event streams consistent with aggregate identity and versioning.** One stream belongs to one aggregate instance. Check: the stream key equals the aggregate's identity, and each append states the stream version it expects so concurrent writers are detected (the optimistic version check is Added judgment on how).
4. **[MUST] Rebuild state from events deterministically.** The same events must always give the same state. Check: a test replays a recorded stream and asserts the resulting state, twice, with identical results.
5. **[MUST] Version events, and use upcasters or translators when event meaning evolves.** Events already stored must stay readable after the meaning changes. Check: a changed event has a new version or an upcaster or translator for old stored shapes, with a test per old version.
6. **[MUST NOT] Use events for every property change.** A stream of `FieldChanged` events stores bookkeeping, not facts. Check: each stored event states a business fact (`ddd-implementing-domain-events`).
7. **[MUST NOT] Put framework request objects or persistence artifacts in events.** They live as long as the stream. Check: event types reference no web, ORM or serializer type.
8. **[Added judgment] Separate deciding from applying.** A command method checks the rules and records events; an `apply(event)` method only changes state, with no failing checks, no clock, no randomness and no I/O. Check: `apply` can be called on any stored event without raising.
9. **[Added judgment] Test with given events, when a command, then events.** The outcome tests of the Testing Rules take this form for sourced aggregates. Check: aggregate tests construct state from events, not from setters (`ddd-implementing-domain-tests`).
10. **[Added judgment] Treat snapshots as an optimization after measurement.** A snapshot is derived data that must be rebuildable from the stream. Check: deleting every snapshot changes performance, not state.
11. **[Added judgment] Keep queries off the aggregate.** Lists and searches read projections built from the stream. Check: no use case loads many streams to answer a question (`ddd-implementing-client-representations`).
12. **[Added judgment] Treat stored events as history and do not rewrite them in place.** The source asks for versions and upcasters or translators; it does not say stored payloads are immutable or when translation runs. A rewrite with no translator and no test loses the old meaning silently. Check: any change to stored payloads goes through an upcaster or translator with a test fed an old sample, and no ad-hoc UPDATE of the event table exists outside that path.

## Procedure

1. Write the reason event sourcing is needed for this aggregate. If you cannot, stay with state storage plus published events and stop.
2. Define the events as past-tense facts with explicit versions; give each stream the aggregate's identity as its key.
3. Write `apply` as a pure state transition for every event type; write command methods that check rules and record events.
4. Add `fromHistory(events)`; add an append that passes the expected version and rejects a conflict.
5. For every change of an existing event, write the upcaster and a test fed with a stored old-version sample.
6. Run replay tests: given a recorded stream, state equals the expected state; replay twice gives identical results.

## Example

```python
from dataclasses import dataclass
from datetime import datetime, timedelta

@dataclass(frozen=True)
class SeatHeld:                 # version 2: absolute expiry
    hold_id: str
    seat: str
    expires_at: datetime

@dataclass(frozen=True)
class SeatReleased:
    hold_id: str
    released_at: datetime

def upcast_seat_held_v1(stored: dict, occurred_at: datetime) -> SeatHeld:
    """Version 1 stored a duration in minutes; version 2 stores the expiry time."""
    expires_at = occurred_at + timedelta(minutes=stored["minutes"])
    return SeatHeld(stored["hold_id"], stored["seat"], expires_at)

class SeatHold:
    def __init__(self) -> None:
        self.hold_id: str | None = None
        self._expires_at: datetime | None = None
        self._released = False
        self._loaded_version = 0
        self._pending: list[object] = []

    @classmethod
    def from_history(cls, events: list[object]) -> "SeatHold":
        hold = cls()
        for event in events:
            hold._apply(event)                    # no checks, no clock, no I/O
        hold._loaded_version = len(events)
        return hold

    def release(self, now: datetime) -> None:     # decide, then record a fact
        if self._released:
            return
        self._record(SeatReleased(self.hold_id, now))

    def _record(self, event: object) -> None:
        self._apply(event)
        self._pending.append(event)

    def _apply(self, event: object) -> None:
        if isinstance(event, SeatHeld):
            self.hold_id, self._expires_at = event.hold_id, event.expires_at
        elif isinstance(event, SeatReleased):
            self._released = True

    def changes(self) -> tuple[int, list[object]]:
        return self._loaded_version, list(self._pending)

# application service: store.append(stream_id=hold.hold_id, expected_version=v, events=pending)
```

The upcaster is the only place that knows version 1 counted minutes; `apply` sees only version 2.

## Anti-patterns

- **Sourcing because events exist.** Detect: no stated need for history, and the same state could be stored directly.
- **Impure apply.** `apply` reads the clock, calls a service or raises. Detect: time, random or I/O calls inside `apply`.
- **Edited history (Added judgment).** An in-place rewrite of stored events without an upcaster or translator and a test. Detect: a migration or script that UPDATEs event payloads with no translator code and no old-sample test.
- **Property-change stream.** Events named `*Changed` per field. Detect: event types that mirror setters.
- **Stream per table or per context.** Detect: a stream key that is not an aggregate identity.
- **Giant stream queries.** Loading many streams to answer a screen. Detect: use cases that replay lists of aggregates.

## Trade-offs and exceptions

- The source allows event sourcing only where the event sequence is the right model; mixing is normal. One event-sourced aggregate beside state-stored neighbors is a legitimate design.
- Upcasting is the source's option; whether to translate on read, on write or in a migration is not specified. Added judgment: translate on read so stored events stay untouched.
- Event delivery, ordering and exactly-once claims are not covered by this rule set; see the sibling plugin `data-intensive-apps`.
- Compliance or personal-data deletion obligations may conflict with immutable history. This rule set does not address it; treat it as a requirement to settle before choosing the model.

## Verification

- [ ] A written reason says what the history buys for this aggregate.
- [ ] The stream key is the aggregate's identity and appends check the expected version.
- [ ] `apply` is deterministic and has no checks, clock or I/O.
- [ ] A replay test passes twice with identical results.
- [ ] Every event version change has an upcaster and a test with an old sample.
- [ ] No event carries a framework or persistence type.

## Related

`ddd-implementing-domain-events` for the events; `ddd-implementing-client-representations` for projections; `ddd-implementing-domain-tests` for given-when-then tests; `ddd-implementing-event-sourcing-reviewer` to review a diff.

## Source

- `Domain Event Rules`: only the Event Sourcing subsection and the anti-patterns on property-change events and persistence artifacts in events.
- `Event Sourcing`
