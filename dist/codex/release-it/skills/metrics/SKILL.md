---
name: "metrics"
description: "Use when adding instrumentation, dashboards or alerts, or when a failure would be invisible: the minimum signal set of request rate, success and failure counts, dependency latency, timeouts, queue depth, retries, breaker state and saturation. Events with context are `$release-it:logging`."
---

# Metrics and saturation signals

A defense you cannot see working is a defense you will not notice failing. This skill decides which numbers must exist. The text of a failure and its correlation id are `$release-it:logging`; whether a health endpoint tells the truth is `$release-it:startup-and-health`.

## When to use

- A new dependency, queue, pool, cache, breaker, retry loop or scheduled job is added.
- A dashboard or alert is being written, or an incident showed that nothing paged.
- Latency is reported only as an average, or errors only as one lump count.
- You are asked what to measure for "production readiness".

## Rules

1. **Measure latency, throughput, error rate, saturation, queue depth and retry behavior.** [MUST] Check: each exists for every critical path the change touches.
2. **Capture the minimum set.** [MUST] Request rate, success and failure counts, dependency latency, timeout counts, queue depth, retry counts, circuit-breaker state and saturation signals. Check: walk the list against the change; each item is present or marked not applicable with a reason (no queue, no breaker).
3. **Never leave a slow dependency without metrics.** [MUST NOT] Check: every outbound dependency has a latency measurement labelled by dependency and outcome (`ok`, `timeout`, `error`).
4. **Keep the latency distribution, not only the mean.** [Added judgment, the source asks capacity investigations to inspect latency distribution] Use histograms or percentiles so a slow tail is visible. Check: the instrument can answer "how slow is the slowest tail".
5. **Measure saturation, not just use.** [MUST] Saturation is how close a resource is to its limit and how much work is waiting: in use over maximum, waiters, rejected acquisitions. Check: each pool, queue, thread group and memory budget has in-use, limit and waiting.
6. **Track queue age as well as depth.** [MUST, source: monitor queue length, age, throughput and failure rate] Check: age of the oldest item or wait time at dequeue is exposed.
7. **Count timeouts, retries and short-circuits separately.** [MUST, retries and timeouts are listed signals] A single "errors" counter hides which defense is working. Check: distinct counters or outcome labels exist.
8. **Expose breaker state and degraded-mode time.** [MUST for breaker state; Added judgment for degraded time] Check: state, transitions and time spent degraded are queryable.
9. **Label with identifiers that stay bounded.** [Added judgment] Dependency name, operation and outcome are fine; user ids, raw URLs and error messages explode the number of series. Check: no unbounded value is used as a label.
10. **Make version and configuration identifiable from the metrics.** [MUST, source: make build, version and configuration state visible] Check: an info-style metric or label exposes the build id and a configuration revision.
11. **Alert on what threatens the core service.** [Added judgment] Alert on saturation, error budget burn, queue age and dead-letter growth, and check each alert against the last incident: would it have fired in time? Check: every alert names the action it calls for.

## Procedure

1. List the new boundaries: calls, queues, pools, caches, jobs.
2. Against each, pick the signals from rule 2 and give each a name, type and labels.
3. Wrap the boundary once so every call is measured the same way.
4. Add saturation gauges for each limited resource.
5. Define the alert for each signal that would signal danger, and its first action.
6. Trigger each condition in a test or staging and watch the metric move.

## Example

```python
import time
from prometheus_client import Counter, Gauge, Histogram

CALL_SECONDS = Histogram(
    "dependency_call_seconds", "Outbound call latency", ["dependency", "outcome"]
)
TIMEOUTS = Counter("dependency_timeouts_total", "Outbound calls that hit their time limit", ["dependency"])
QUEUE_DEPTH = Gauge("jobs_queue_depth", "Jobs waiting in the in-memory queue")
QUEUE_DEPTH.set_function(jobs.qsize)       # saturation: how much is waiting right now


def timed_call(dependency, fn):
    """Measure every outbound call the same way: latency by outcome, plus a timeout counter."""
    started = time.monotonic()
    outcome = "error"
    try:
        result = fn()
        outcome = "ok"
        return result
    except TimeoutError:                    # map your client's timeout exception here
        outcome = "timeout"
        TIMEOUTS.labels(dependency).inc()
        raise
    finally:
        CALL_SECONDS.labels(dependency, outcome).observe(time.monotonic() - started)


# Before: rates = rates_client.get("EUR")        (slow calls are invisible until users complain)
# After:  rates = timed_call("rates", lambda: rates_client.get("EUR"))
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| No dependency metrics | Outbound clients with no latency or outcome measurement | Wrap once; label by dependency and outcome |
| Average only | A mean latency panel with no tail | Histogram or percentiles |
| One lump of errors | Timeouts, rejections and validation failures in one counter | Separate counters or outcome labels |
| Success path only | Instrumentation placed after the call returns | Measure in `finally` |
| Unbounded labels | User id, URL or message text as a label | Bounded identifiers |
| Depth without age | A queue gauge with no wait-time measure | Add age |
| Metrics with no alert | A dashboard nobody is paged by | Alert with a named action |

## Trade-offs and exceptions

- Each series costs memory and money. Start with the minimum list and the critical paths; do not instrument pure in-process functions.
- Per-instance metrics see only that instance's view; aggregate across instances before alerting on rates (Added judgment).
- Distributed tracing is a separate tool that complements metrics; the source asks only that correlation and timing exist.
- Health endpoints are for routing and orchestration, not a replacement for metrics.

## Verification

- [ ] Every outbound dependency has latency by outcome.
- [ ] Timeouts, retries and breaker state are counted separately.
- [ ] Each pool and queue has in-use, limit, waiting and age or depth.
- [ ] No label can take an unbounded set of values.
- [ ] Each alert names the action it calls for.

## Related

`$release-it:logging` for the event record; `$release-it:startup-and-health` for health signals; `$release-it:queues` and `$release-it:resource-budgets` for what to measure on buffers and pools; `$release-it:incident-review` to check alerts against an incident; `release-it-observability-reviewer` to review a diff.

## Source

- `Metrics`
- `Observability Is Part of the Design`
- `Operational Visibility Rules`: only the anti-pattern of no metrics for slow dependencies.
- `Incidents, Capacity, and Runtime Control`: only the rule listing what to inspect in performance and capacity incidents.
- `Production Readiness and Release Risk Rules`: only the rule to make version, build and configuration state visible.
