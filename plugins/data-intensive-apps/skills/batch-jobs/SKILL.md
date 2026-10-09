---
name: batch-jobs
description: "Use when writing or reviewing a batch job, ETL, nightly report, backfill, reprocessing run or MapReduce-style pipeline. Makes inputs and outputs recomputable and keeps side effects out of replayable work. Event-time streaming is stream-processing."
---

# Batch jobs and recomputation

Designs bounded jobs so that a failed or repeated run, or a run over old data, leaves the same correct result. The same questions asked of an unbounded stream (event time, windows, lateness, checkpoints) are `/data-intensive-apps:stream-processing`; idempotent effects of single messages are `/data-intensive-apps:idempotent-handlers`; keeping an output copy repairable is `/data-intensive-apps:derived-data`.

## When to use

- You write or change a scheduled job, ETL, report generation or backfill.
- A job is rerun after a failure and someone worries about duplicates or half-written output.
- A job both computes results and calls an external system (mail, payment, API).
- You choose between hand-written map and reduce steps, a dataflow engine and a high-level batch API.
- A job reads "everything since yesterday" using the current time.

## Rules

1. **Build every batch job so that, after a failure, it can recompute or recover its inputs, outputs and intermediate state.** A job you can only run once is a liability. Check: rerunning the job for the same input yields the same output, and intermediate files can be deleted and regenerated.
2. **Keep calls that change the outside world out of replayable jobs, unless the job makes them idempotent on purpose.** A replay then cannot email a customer twice. Check: calls to mail, payment or partner APIs sit in a separate step that carries a stable key, or are absent.
3. **Choose between MapReduce-style jobs, dataflow engines and high-level batch APIs by how joins are executed, whether intermediate results are materialized, and what running them demands.** Check: the choice is written with its reason (for example "a high-level API, because the optimizer picks the join strategy and the code stays readable").
4. **State, for each path from input to output, whether processing is at-most-once, at-least-once or exactly-once.** Check: each path from input to output has its guarantee and the mechanism that provides it.
5. **Test that derived outputs can be rebuilt or repaired, wherever the job offers that ability.** Check: a test runs the job twice for the same input and compares outputs (`/data-intensive-apps:data-path-tests`).
6. Added judgment: **Treat inputs as immutable and write outputs as new, replaceable versions.** A job that updates its input in place cannot be rerun on the original. Check: the job writes to a new location or a partition it owns, and never edits its source.
7. Added judgment: **Name the input window and version in the job's parameters.** Use `--day 2026-03-01`, not "now minus one day". Check: a backfill is the same code with a different parameter.
8. Added judgment: **Publish output atomically.** Write to a staging location, then swap or replace the partition in one step so readers never see half a result. Check: a reader running during the job sees either the old complete output or the new complete output.
9. Added judgment: **Define the failure behavior of a partial run.** Failed tasks are retried without double-counting; leftover staging data is cleaned or overwritten. Check: kill the job midway in a test and rerun it.

## Procedure

1. Write the job's contract: inputs (with version or window), output location, and the guarantee from source to sink.
2. Make the window a parameter. Remove any use of the current time inside the computation.
3. Make the output a function of the inputs: derive it into staging, then replace the target partition in one step.
4. Split external side effects into a separate, keyed step that reads the published output.
5. Choose the processing style and write the reason.
6. Add the rerun test (twice, same input) and the kill-and-rerun test.
7. Add run identity and duration to the job's logs and metrics, so that a late or failed run is visible (`/data-intensive-apps:load-and-latency`, rule on inspectable behavior).

## Example

```python
# Before: appends on every run, so a retry or a manual rerun double-counts the day;
# the notification loop sits inside the job, so a rerun also emails managers again.
def run(day):
    rows = db.query("SELECT region, SUM(amount) FROM orders WHERE placed_on = %s GROUP BY region", [day])
    for region, total in rows:
        db.execute("INSERT INTO daily_totals (day, region, total) VALUES (%s, %s, %s)", [day, region, total])
        mailer.send(manager_of(region), f"{region} total for {day}: {total}")

# After: the job derives one day's partition from its input and replaces it in a single transaction;
# notification is a separate step whose messages carry a stable key.
def run(day):
    with db.transaction() as tx:
        tx.execute("DELETE FROM daily_totals WHERE day = %s", [day])
        tx.execute(
            """INSERT INTO daily_totals (day, region, total)
               SELECT placed_on, region, SUM(amount)
                 FROM orders WHERE placed_on = %s
                GROUP BY placed_on, region""", [day])

def notify(day):
    for region, total in db.query("SELECT region, total FROM daily_totals WHERE day = %s", [day]):
        mailer.send(manager_of(region), f"{region} total for {day}: {total}",
                    idempotency_key=f"daily-total:{day}:{region}")
```

The rerun is only equal to the first run if the day's orders are no longer changing; if late orders can arrive for a closed day, rerunning later gives a corrected total, which is the point of recomputation, and `notify` then needs to say it is a correction.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Append on rerun | `INSERT` without replacing the partition it owns | Replace the partition atomically |
| Side effect in the loop | Mail, payment or API call inside the compute step | Separate keyed step |
| Time-dependent job | `now()` or `today()` inside the logic | Window as a parameter |
| In-place input edit | The job updates the table it reads | New output location; keep the input immutable |
| Anonymous run | No run id or input version in logs | Log the window, version and run id |
| Unreadable pipeline | Hand-written map and reduce for a simple join | A higher-level API, where the optimizer helps |

## Trade-offs and exceptions

- Added judgment: some jobs must change data in place (privacy deletion, retention). Make that an explicit, audited operation, not the default shape of a job.
- Added judgment: very large outputs cannot be swapped in one transaction. Use versioned directories and a pointer that is switched when the output is complete.
- MapReduce-style intermediate materialization buys fault tolerance at the cost of I/O; newer dataflow engines keep more in memory and recompute on failure. Choose by operational need (`/data-intensive-apps:load-and-latency`).
- Added judgment: exactly-once effects in a batch usually come from rerunnable, replace-style output, not from the engine.

## Verification

- [ ] Rerunning the job for the same window yields identical output.
- [ ] The window and input version are parameters, not the current time.
- [ ] Output replaces its partition atomically, and readers never see partial output.
- [ ] External side effects are outside the replayable step or keyed.
- [ ] Each source-to-sink path has a stated guarantee.
- [ ] A kill-and-rerun test exists.

## Related

`/data-intensive-apps:stream-processing` for unbounded input; `/data-intensive-apps:idempotent-handlers` for keyed effects; `/data-intensive-apps:derived-data` for output copies; `/data-intensive-apps:replay-drill` to walk a job through reruns; `data-intensive-apps:batch-reviewer` to review a diff.

## Source

- `Batch and Stream Processing Rules`: the rules on recomputable jobs, side effects in replayable jobs, choice of batch style, and source-to-sink guarantees.
- `Testing Rules`: only the rule on testing rebuild or repair of derived outputs.
