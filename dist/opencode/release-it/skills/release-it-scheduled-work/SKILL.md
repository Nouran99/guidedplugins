---
name: "release-it-scheduled-work"
description: "Use when adding or reviewing cron jobs, periodic tasks, timers, batch runs or long-running background work. Covers spreading start times, failure and retry policy, backoff, bounded runtime, progress, cancellation. Client-call retries are `retries`; job buffers are `queues`."
license: "MIT"
metadata:
  plugin: "release-it"
  book: "Release It!"
  invocation: "auto"
---

# Scheduled and background work

Work started by the clock arrives in pulses, and work that runs for a long time can hold resources for as long as it likes. This skill spreads the starts and bounds the runs. Retrying a client call is `release-it-retries`, and the buffer between producers and consumers is `release-it-queues`.

## When to use

- A cron entry, timer, scheduler job or periodic task is added or its schedule changes.
- Many instances, tenants or jobs share the same schedule.
- A batch job, backfill, export or sync can run for minutes or hours.
- A job fails and is retried, or an incident began at the top of an hour.

## Rules

1. **Spread scheduled work so demand does not concentrate at the same instant.** [MUST] Check: for the set of jobs and instances, list start times and confirm no large group shares a second.
2. **Do not put all periodic jobs on the same obvious clock boundary.** [MUST NOT] The top of the hour, midnight and `:00`/`:30` are where everyone else's jobs run too. Check: schedules use per-job offsets (stable, derived from the job's identity) or start-time jitter.
3. **Make failure and retry policy explicit.** [MUST] Check: for each job, a written statement of what failure means, how many attempts, what happens after giving up (alert, park), and whether a missed run is skipped or made up.
4. **Retried work must use increasing backoff where synchronized retry pulses would create load.** [MUST] Check: retry delays grow and are jittered, so many instances do not retry together.
5. **Give long-running work bounded waits.** [MUST] Every call inside the job has a time limit (`release-it-timeouts`). Check: no step can block forever.
6. **Give long-running work progress visibility.** [MUST] Check: the job reports last progress time and items done, and a stalled job is detectable.
7. **Give long-running work an overall timeout.** [MUST] Check: a maximum runtime exists, and exceeding it ends the run cleanly.
8. **Give long-running work a cancellation strategy.** [MUST] Check: the job checks a stop signal between units, so an operator or a deploy can end it without killing it mid-write.
9. **Prevent overlapping runs of the same job.** [Added judgment] A slow run followed by the next scheduled start piles up. Check: a lease or lock with expiry guards each job, or the scheduler forbids concurrency.
10. **Choose a catch-up policy.** [Added judgment] After downtime, run once, not once per missed slot. Check: the policy is written and tested.
11. **Pace the work and isolate it from online traffic.** [Added judgment, following from keeping best-effort tasks from crowding out critical work] Bound batch size and rate, and run heavy jobs on their own capacity (`release-it-bulkheads`). Check: a running job does not move the latency of interactive requests.
12. **Run singleton jobs once across the fleet.** [Added judgment] Check: with N instances, exactly one runs the job, or each runs a defined shard.

## Procedure

1. List the jobs, their schedules and the fleet that runs them.
2. Assign offsets or jitter; move heavy jobs off shared boundaries.
3. Write the failure, retry, overlap and catch-up policy for each job.
4. Add a time limit to each step, a maximum runtime, a progress record and a stop check between units.
5. Add metrics: last success, duration, items processed, failures; alert on a missed run.
6. Test an overlapping start, a mid-run stop and a failing step.

## Example

```python
import threading
import time
import zlib
from datetime import datetime, timedelta

# Before: a crontab line "0 * * * *" starts 40 heavy hourly jobs in the same second of every hour,
# so the database sees all 40 at once, every hour.


def next_hourly_run(job_name: str, now: datetime) -> datetime:
    """A stable offset inside the hour per job: spread across jobs, identical from hour to hour."""
    offset = zlib.crc32(job_name.encode()) % 3600            # seconds after the hour
    this_hour = now.replace(minute=0, second=0, microsecond=0)
    candidate = this_hour + timedelta(seconds=offset)
    return candidate if candidate > now else candidate + timedelta(hours=1)


def run_job(job, stop: threading.Event, max_runtime_s: float = 900.0) -> str:
    """A bounded run: stop signal, maximum runtime and progress after every batch."""
    deadline = time.monotonic() + max_runtime_s
    for batch in job.batches():                              # each batch is small and has its own time limits
        if stop.is_set():
            job.record_progress(status="stopped")
            return "stopped"
        if time.monotonic() > deadline:
            job.record_progress(status="timed_out")
            return "timed_out"
        job.process(batch)
        job.record_progress(status="running", done=batch.last_id)
    job.record_progress(status="finished")
    return "finished"
```

`zlib.crc32` is used because Python's built-in `hash()` of a string changes between processes, which would move the offsets on every restart.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Everyone at :00 | Many entries with `0 * * * *`, `0 0 * * *` | Offsets or start jitter |
| Lockstep retries | Fixed retry delay identical across instances | Growing, jittered backoff |
| Overlapping runs | No guard; next start while the last is running | Lease or lock with expiry |
| Unbounded job | No overall timeout, no stop check, no progress record | Maximum runtime, cancellation, heartbeat |
| Catch-up storm | After an outage, every missed slot runs | Run once |
| Heavy job on request threads | A scheduler sharing the web pool | Separate capacity |
| Local-time schedules | Cron in a time zone with daylight saving | UTC, or handle skipped and repeated hours |

## Trade-offs and exceptions

- Some work must happen at a boundary (a day-end cut-off). Trigger at the boundary but spread the work: enqueue per-tenant tasks with jitter instead of running all tenants at once.
- A stable offset is predictable, which helps debugging; random jitter spreads better across a large fleet. Either meets the rule (Added judgment).
- Singleton leasing across a fleet is a distributed-coordination problem; use the scheduler's own mechanism or a data-systems plugin such as `data-intensive-apps` for depth.
- Not every job needs a cancellation path as elaborate as the example; a short idempotent job can simply finish.

## Verification

- [ ] No large group of jobs or instances starts in the same second.
- [ ] Every job has a written failure, retry and catch-up policy.
- [ ] Retries back off and are jittered.
- [ ] Long jobs have time limits, a maximum runtime, progress and a stop check.
- [ ] Overlap is prevented and a missed run raises an alert.

## Related

`release-it-retries` for client-call retries; `release-it-queues` for buffers; `release-it-timeouts` for step limits; `release-it-bulkheads` for isolating heavy work; `release-it-restartable-automation` for resumable operational jobs; `release-it-schedule-reviewer` to review a diff.

## Source

- `Scheduled and Background Work Rules`
