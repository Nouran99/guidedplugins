---
name: "release-it-stability-patterns"
description: "Use when choosing a stability pattern by failure mode: steady state (no manual cleanup), fail fast on a request-time precondition or scarce resource, let it crash, decoupling middleware, or a governor. Startup and config checks are `release-it-startup-and-health`; breakers and bulkheads have own skills."
license: "MIT"
metadata:
  plugin: "release-it"
  book: "Release It!"
  invocation: "auto"
---

# Stability patterns by failure mode

The source names a small set of additional patterns and asks you to use each where its failure mode appears. This skill owns steady state, fail fast, let it crash, decoupling middleware and governors, and the choice among all patterns. Breakers are `release-it-circuit-breakers`, bulkheads `release-it-bulkheads`, and handshaking is in `release-it-startup-and-health`.

## When to use

- A table, log, cache, temp directory, in-memory map or queue grows with time and nothing removes old entries.
- Work acquires a scarce resource and only then discovers it cannot finish.
- A process catches every error to "stay up" and keeps running in a questionable state, or crashes with nothing to restart it.
- A direct service-to-service call could be decoupled through a broker, or a broker has just become a new dependency.
- Automation can act on many hosts, records or users at once.

## Rules

1. **Pick the pattern by the failure mode you can name.** [Compact checklist, mini.md: "use stability patterns by failure mode"] Check: the change description says which failure the pattern answers; no pattern is added "for resilience" in general.
2. **Design for steady state.** [MUST, source: USE Steady State] Routine operation must not need manual cleanup, unbounded growth or periodic rescue. Check: every store the change adds has a retention or eviction rule that runs automatically.
3. **Run the cleanup as production work.** [Added judgment] Purges and rotations delete in bounded batches, off peak or paced, and are observable, because a cleanup job can itself become the incident. Check: the purge has a batch size, a pause and a metric.
4. **Fail fast when continuing would hold scarce resources or hide an unrecoverable problem.** [MUST, source: USE Fail Fast, when that condition holds] Check: preconditions (a known-bad dependency, request size, a required input) are checked before a connection, thread or lock is taken. Validating critical configuration when the process starts belongs to `release-it-startup-and-health`.
5. **Make fast failure explicit.** [SHOULD, source: fail visibly instead of hanging silently] A rejected request or aborted task says what precondition failed. Check: the error is specific and carries the reason, not a generic failure.
6. **Keep the fail-fast check cheap.** [Added judgment] A check that reads local state (a loaded setting, a cached health flag, a request size) costs less than the work it guards; one that makes a network call to find out can itself hang. Check: the check is O(1) and does no remote call.
7. **Let it crash only when supervision, isolation and restart behavior make crashing safer than limping.** [MUST condition] Check: a supervisor restarts the unit, restarts are rate-limited, and the unit's state is recoverable or disposable.
8. **Do not crash a process that serves unrelated work or holds unsaved shared state.** [Added judgment, following from the isolation condition] Check: the crashing unit is small (a worker, an actor, a task), not the whole service.
9. **Use decoupling middleware only where it reduces failure propagation, and monitor it as a dependency.** [MUST monitor, source] A broker removes a synchronous dependency and adds one. Check: depth, age, health and consumer lag are observed, and producers and consumers have a defined behavior when it is unavailable.
10. **Put a governor on expensive behavior.** [MUST cap, source: USE Governors] Check: automation that restarts, deletes, migrates, replays or recomputes at scale has a rate and a concurrency cap.
11. **Make a tripped governor visible and overridable.** [Added judgment] A governor that silently drops or delays work hides a backlog. Check: tripping raises an alert, and an authorized operator can raise the cap with an audit record (`release-it-operational-controls`).

## Procedure

1. Name the failure mode: growth over time, wasted scarce resource, limping process, direct-call propagation, runaway automation.
2. Choose the pattern from the table below; if two fit, prefer the one with the smaller operational surface.
3. State the trigger, the action, the signal that it fired, and how to override it.
4. Add the signal to metrics (`release-it-metrics`) and a test that makes it fire (`release-it-resilience-testing`).

| Failure mode | Pattern | Skill |
| --- | --- | --- |
| Data, logs or caches only grow | Steady state | here |
| Resource taken before the work is known to be possible | Fail fast | here |
| Dependency clearly unhealthy | Circuit breaker | `release-it-circuit-breakers` |
| One workload can starve another | Bulkhead | `release-it-bulkheads` |
| Unit in a bad state, supervision available | Let it crash | here |
| Instances receive traffic before they are ready | Handshaking | `release-it-startup-and-health` |
| Direct calls spread failure | Decoupling middleware | here |
| Automation or a job can do too much at once | Governor | here |

## Example

```python
import time
from collections import deque


class RestartGovernor:
    """Caps how many restarts the reaper may perform per window."""

    def __init__(self, limit: int, window_s: float, clock=time.monotonic):
        self.limit, self.window_s, self.clock = limit, window_s, clock
        self.stamps: deque[float] = deque()

    def try_acquire(self) -> bool:
        now = self.clock()
        while self.stamps and now - self.stamps[0] > self.window_s:
            self.stamps.popleft()
        if len(self.stamps) >= self.limit:
            return False
        self.stamps.append(now)
        return True


# Before: every instance that fails its check is restarted at once, so a bad probe can restart the whole fleet.
for instance in fleet.unhealthy():
    instance.restart()

# After: at most 2 restarts per 5 minutes, and a tripped governor raises an alert instead of acting.
governor = RestartGovernor(limit=2, window_s=300)
unhealthy = fleet.unhealthy()
for instance in unhealthy:
    if not governor.try_acquire():
        alert(f"restart governor tripped: {len(unhealthy)} unhealthy, restarts capped")
        break
    instance.restart()
```

The limit and window are examples; real values come from how quickly the fleet can safely lose capacity.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Growth with no retention | Tables, session stores or log directories with inserts and no delete job or TTL | Retention rule that runs on its own |
| Resource-first, check-later | A connection or lock acquired before validating the request | Validate, then acquire |
| Catch-all to stay up | `except Exception: pass` in a worker loop, state left half-updated | Crash under supervision, or handle the specific error |
| Unsupervised crash | `os._exit` or an uncaught panic with no restarter | Supervisor with restart limits, or handle the error |
| Middleware assumed reliable | A broker with no depth, age or availability signal | Monitor it as a dependency; define behavior when it is down |
| Unbounded automation | A loop that restarts, deletes or replays everything it finds | Governor with a visible trip |

## Trade-offs and exceptions

- Let it crash is conditional. Expected errors (a bad request, a missing record) are handled, not crashed on.
- Retention that conflicts with legal or audit requirements is a decision for the owner of that requirement; bound the growth another way, such as archiving (Added judgment).
- A governor can slow a real recovery. Pair it with an override path and an alert.
- Middleware changes consistency and ordering behavior; that analysis is outside this book (use a data-systems plugin).

## Verification

- [ ] Every new store has automatic retention or eviction.
- [ ] Preconditions are checked before scarce resources are taken.
- [ ] Any crash-and-restart behavior has a supervisor with a restart limit.
- [ ] Middleware is monitored and its absence is handled.
- [ ] Mass actions have a governor, and tripping it is visible.

## Related

`release-it-circuit-breakers`, `release-it-bulkheads`, `release-it-startup-and-health` for the patterns with their own skills; `release-it-queues` for the broker's buffer; `release-it-operational-controls` for overriding a governor; `/release-it:failure-mode-scan` to find which failure mode applies.

## Source

- `Additional Stability Patterns`
- `Primary Directive`: only the preference for failing visibly and preserving core service.
- `Load and Capacity Rules`: only the subsection on additional stability patterns.
