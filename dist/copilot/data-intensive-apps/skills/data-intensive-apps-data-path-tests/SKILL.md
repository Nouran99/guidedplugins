---
name: "data-intensive-apps-data-path-tests"
description: "Use when writing or reviewing tests for consumers, jobs, handlers, projections, migrations or schema changes. Covers duplicate delivery, out-of-order messages, replay, conflict resolution, schema compatibility and rebuild or repair of derived views."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Tests for data paths

Turns the data-system rules into tests that fail when a contract is broken: duplicates, reordering, replay, conflicts, schema compatibility and rebuilds. The design rules themselves are in the sibling skills; this one says how to prove them. Style of unit tests in general is outside this book.

## When to use

- You add or change a consumer, webhook, job, projection or migration.
- A review asks "what happens if this arrives twice" or "if these two arrive in the other order".
- A schema, payload or enum changes and compatibility must be shown, not asserted.
- A derived view exists and nobody has tried to rebuild it.
- Only happy-path tests exist for code that reads from a queue, a log or a replica.

## Rules

1. **Test that a message delivered twice is handled correctly.** Deliver the same message twice. Check: after two deliveries the state and every external call equal one delivery.
2. **Test that events or messages arriving in the wrong order are handled, wherever order can matter.** Apply a newer then an older event for the same entity. Check: the final state equals the newer fact, and the stale case is counted or logged.
3. **Test that replaying history is safe.** Process the full history from empty, and from a mid-stream checkpoint. Check: the end state equals the incrementally built state.
4. **Test how concurrent writers to one record are resolved, including optimistic concurrency checks.** Run two writers against the same record. Check: the outcome is the defined one: one rejected, or a deterministic merge.
5. **Test that old and new versions of a contract can still read each other whenever it changes.** Feed old-format data to new code and new-format data to the previous reader or its pinned schema. Check: both directions pass, and a payload with unknown fields and unknown enum values is handled.
6. **Test that a derived view can be rebuilt or repaired, for every view that offers that ability.** Delete the view, rebuild it, compare. Check: the rebuilt content equals the incrementally maintained one.
7. Added judgment: **Keep recorded payloads of the previous version as fixtures.** Real shapes from version N-1 and N catch more than hand-written ones. Check: a fixtures folder exists and is read by the compatibility tests.
8. Added judgment: **Script faults; do not rely on luck.** Use a fake broker, clock and database that can duplicate, delay, reorder or fail on command, and a seeded shuffle for property-style checks. Check: the same test run twice gives the same result.
9. Added judgment: **Inject a crash after each step of a write path and rerun.** Check: for every step k, the state after crash-at-k and restart equals the state of an uninterrupted run (or a defined recovery state).
10. Added judgment: **Use a real database for isolation and transaction tests.** Fakes cannot show write skew or lock behavior. Check: tests of guarded invariants run against the engine that production uses.

## Procedure

1. List the data contracts the change touches: dedup, order, replay, conflict, compatibility, rebuild.
2. For each, write one test that fails against the naive implementation.
3. Make time, delivery and failure injectable. Seed any randomness.
4. Add fixtures of previous formats for compatibility tests.
5. Run the new tests against the old code if it exists, to confirm they detect the problem.
6. Keep the tests small and named for the contract ("applies_a_stale_event_as_noop").

## Example

```python
# balance_view.py: a read model fed by events carrying a per-account version
class BalanceView:
    def __init__(self):
        self.rows = {}                                     # account_id -> (version, balance)

    def apply(self, e):                                    # e: dict(event_id, account_id, version, balance)
        current = self.rows.get(e["account_id"])
        if current is None or current[0] < e["version"]:
            self.rows[e["account_id"]] = (e["version"], e["balance"])

# test_balance_view.py
import random

EVENTS = [
    {"event_id": "e1", "account_id": "a", "version": 1, "balance": 100},
    {"event_id": "e2", "account_id": "a", "version": 2, "balance": 80},
    {"event_id": "e3", "account_id": "a", "version": 3, "balance": 95},
]

def final_state(events):
    view = BalanceView()
    for e in events:
        view.apply(e)
    return view.rows

def test_duplicate_delivery_changes_nothing():
    assert final_state(EVENTS + [EVENTS[1]]) == final_state(EVENTS)

def test_out_of_order_arrival_keeps_the_newest_fact():
    assert final_state(list(reversed(EVENTS))) == {"a": (3, 95)}

def test_resume_from_checkpoint_with_overlap_matches_full_replay():
    before_crash = BalanceView()
    for e in EVENTS[:2]:
        before_crash.apply(e)
    resumed = BalanceView()
    resumed.rows = dict(before_crash.rows)                 # state restored from the last checkpoint
    for e in EVENTS[1:]:                                   # at-least-once: restart one event early
        resumed.apply(e)
    assert resumed.rows == final_state(EVENTS)

def test_shuffled_with_duplicates_converges():
    rng = random.Random(7)                                 # seeded: failures are reproducible
    for _ in range(50):
        noisy = EVENTS + [rng.choice(EVENTS) for _ in range(5)]
        rng.shuffle(noisy)
        assert final_state(noisy) == {"a": (3, 95)}
```

The view ignores versions that are not newer, so duplicates, reordering and a restart that re-reads an event all converge. Replace the version comparison with an unconditional assignment and the duplicate, out-of-order and shuffled tests fail, which is what they are for; the restart test guards a different mistake, such as a view that adds amounts instead of replacing them.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Happy-path only | Every test delivers each message once, in order | Add duplicate, reorder and replay tests |
| Mock that cannot redeliver | The broker mock delivers exactly once by construction | A fake that can duplicate and reorder |
| Sleep synchronization | `sleep` to wait for a consumer | Deterministic hooks or an injectable clock |
| Call-count only | Asserts the mailer was called, never what state remains | Assert state and effects |
| Fakes for isolation | Write skew "tested" against an in-memory map | Test against the real engine |
| Untested rebuild | A projection nobody has rebuilt | Rebuild and compare in a test |

## Trade-offs and exceptions

- Integration tests with real brokers and databases are slower; reserve them for transactional behavior and isolation, and use fakes for duplicate, reorder and replay logic.
- Property-style tests (shuffle, duplicate, compare final state) find ordering bugs cheaply but only for properties you can state.
- Not every consumer needs every test class: a handler for append-only independent facts may not need ordering tests. Say so.
- Compatibility fixtures need upkeep; prune when a version is retired.

## Verification

- [ ] A duplicate-delivery test exists for each consumer or job changed.
- [ ] An out-of-order test exists wherever state carries a version.
- [ ] A replay or rebuild test compares with incrementally built state.
- [ ] A compatibility test uses recorded old-format data and unknown values.
- [ ] Randomness is seeded and time and faults are injected.

## Related

`data-intensive-apps-idempotent-handlers`, `data-intensive-apps-ordering-scope`, `data-intensive-apps-encoding-and-evolution`, `data-intensive-apps-derived-data` and `data-intensive-apps-transactions-and-isolation` for the behaviors under test; `data-intensive-apps-test-gap-reviewer` to find missing tests; `data-intensive-apps-data-test-writer` to write them.

## Source

- `Testing Rules`
