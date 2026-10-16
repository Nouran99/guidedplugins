---
name: resilience-testing
description: "Use when writing or reviewing automated tests for failure behavior: timeouts, retries and backoff, degraded dependencies, overload and queue saturation, restartable scripts, startup and health failures. Tests that prove a defense works. Experiments on a running system are `game-day-plan`."
---

# Resilience testing

A defense that was never exercised is a guess. These tests make the failure happen, in the normal suite where that is cheap, and check the bound, the behavior and the signal. Experiments against a running system are `/release-it:game-day-plan`; the design of the defenses is in their own skills, linked below.

## When to use

- A timeout, retry, breaker, limit, queue bound, fallback or health check was added or changed, and no test would fail if it were removed.
- Tests mock a dependency by making it raise, and never by making it stall, slow down or return nonsense.
- A deployment or migration script has no test for interruption.
- A review asks "how do we know this works under failure?"

## Rules

1. **Test timeout behavior.** [MUST] Use a peer that accepts the connection and never answers, not a mock that raises. Check: a test shows the call returns within its budget and releases its resources.
2. **Test retry, backoff and failure boundaries.** [MUST] Check: tests count attempts, show that permanent errors are not retried, that the attempt cap and total time bound hold, and that delays grow (with an injected clock and seeded randomness).
3. **Test degraded dependency scenarios.** [MUST] Slow, down, partially wrong and recovering. Check: each produces the designed fallback or error, the degraded marker is set, and the core flow still completes.
4. **Test overload and queue saturation behavior where practical.** [MUST, source qualifier: where practical] Check: a test fills the queue or exceeds the concurrency limit and observes rejection, the retry hint and the counters.
5. **Test restartable deployment or operational automation where practical.** [MUST, where practical] Check: a test interrupts the script between steps, reruns it, and asserts the final state with no duplicated side effects.
6. **Test startup and health-check failure modes.** [MUST] Check: missing configuration exits with a clear message, a dependency outage makes the instance not ready, and a stalled worker makes it unhealthy.
7. **Use controllable doubles for time, randomness and the network.** [Added judgment] An injected clock, a seeded random generator, a server that stalls, a proxy that drops or delays. Check: no test depends on real sleeping for correctness.
8. **Assert bounds, not exact timings.** [Added judgment] "Returned within one second of a 0.3 second limit" is stable; "took 301 ms" is not. Check: timing assertions have generous margins.
9. **Assert that the signal fires.** [Added judgment, linking to the diagnostics checklist item] The metric or log that tells an operator the defense triggered is part of the behavior. Check: the test reads the counter or the log record.
10. **Test recovery, not only failure.** [Added judgment] The breaker closes, the queue drains, readiness returns. Check: after the fault ends, the system returns to normal without a restart.
11. **Keep heavy capacity tests separate and labelled.** [Added judgment; the source only names capacity tests among the ways to validate operational assumptions, and says nothing about how to schedule them] Fast fault tests run on every commit; long saturation runs run on a schedule or on demand. Check: both exist, and the labelling is clear.

## Procedure

1. List the defenses in the change: limits, retries, breakers, bounds, fallbacks, health checks, scripts.
2. For each, name the failure that should trigger it and the observable result.
3. Build the smallest double that causes the failure: stall, slow, drop, garble, fill.
4. Write the test for the failure, the bound, the signal and the recovery.
5. Remove or disable the defense temporarily and confirm the test fails; restore it.
6. Keep the test deterministic with injected time and randomness.

## Example

```python
import socket
import threading
import time

import pytest


@pytest.fixture
def stalled_server():
    """Accepts connections and never answers: the failure a mock that raises cannot reproduce."""
    srv = socket.socket()
    srv.bind(("127.0.0.1", 0))
    srv.listen()
    srv.settimeout(0.1)
    held, stop = [], threading.Event()

    def accept_loop():
        while not stop.is_set():
            try:
                conn, _ = srv.accept()
                held.append(conn)
            except socket.timeout:
                continue
            except OSError:
                return

    threading.Thread(target=accept_loop, daemon=True).start()
    yield f"http://127.0.0.1:{srv.getsockname()[1]}"
    stop.set()
    srv.close()
    for conn in held:
        conn.close()


def test_rates_client_gives_up_within_its_budget(stalled_server):
    client = RatesClient(base_url=stalled_server, timeout_s=0.3, max_attempts=1)
    started = time.monotonic()
    with pytest.raises(RatesUnavailable):
        client.rate("EUR")
    assert time.monotonic() - started < 1.0          # a bound with margin, not an exact time


def test_validation_errors_are_not_retried(fake_gateway):
    fake_gateway.respond_with(status=422)
    with pytest.raises(ChargeRejected):
        charge("order-1", "tok_test", 1200)
    assert fake_gateway.attempts == 1                # one attempt: permanent failures are not repeated
```

`RatesClient`, `fake_gateway` and `charge` belong to the project under test; the point is the stalled peer and the attempt count.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Mocks that raise | Fault tests where the double throws immediately | Stall, delay or garble instead |
| Sleep-based tests | `sleep(2)` to wait for a timeout | Injected clock or short real limits with margins |
| Success-only suite | No test with a failing or slow dependency | One test per defense |
| Unseeded jitter | Assertions on exact delays from random values | Seed or assert ranges |
| No attempt count | A retry test that only checks the final result | Count attempts |
| Tests that cannot fail | The defense could be deleted and the suite stays green | Mutation check by hand |
| Capacity test on every commit | Minutes-long load test in the unit suite | Separate, scheduled |

## Trade-offs and exceptions

- Timing tests are the usual source of flakiness. Prefer injected clocks, and when real time is unavoidable keep limits short and margins wide.
- The source asks for saturation and automation tests "where practical"; a one-off script may be covered by a manual rehearsal recorded in the change.
- Fault injection at the network layer (proxies, containers) is heavier than in-process doubles; use it for the cases doubles cannot reproduce.
- Production experiments and game days are a different activity with a blast radius; see `/release-it:game-day-plan`.

## Verification

- [ ] Every new defense has a test that fails when it is removed.
- [ ] Timeout tests use a stalled peer and assert a bound.
- [ ] Retry tests count attempts and cover permanent errors.
- [ ] Saturation, interruption and startup failure each have a test or a recorded reason for none.
- [ ] Tests check that the diagnostic signal fires and that recovery works.

## Related

`/release-it:timeouts`, `/release-it:retries`, `/release-it:circuit-breakers`, `/release-it:queues`, `/release-it:restartable-automation`, `/release-it:startup-and-health` for the defenses under test; `/release-it:game-day-plan` for experiments; `release-it:resilience-test-reviewer` to find missing tests; `release-it:resilience-test-writer` to write them.

## Source

- `Testing Rules`
- `Review Checklist`: only the diagnostics item (rule 9) and the list of defenses that need proof.
- `Interconnect, Routing, Security, and Chaos Rules`: only the mention of capacity tests among the ways to validate operational assumptions (rule 11).
