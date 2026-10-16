---
name: restartable-automation
description: "Use when writing or reviewing deployment scripts, migrations, one-time jobs or runbooks that touch many machines or may be rerun after partial failure. Covers idempotent steps, durable checkpoints, resuming. Rollout staging is `release-risk`; who may run them is `operational-controls`."
---

# Restartable operational automation

Automation fails halfway more often than it succeeds cleanly, usually at the worst moment. Design it so rerunning it, or resuming it, is the normal recovery. This skill covers what a script does when interrupted or repeated; who may start it and how it is stopped is `/release-it:operational-controls`, and how a change is staged is `/release-it:release-risk`.

## When to use

- A script deploys to, configures or restarts many hosts or instances.
- A schema migration, backfill or one-time job runs while old and new application versions coexist.
- A release procedure is a document of manual steps run under time pressure.
- A previous deployment died partway and nobody knew what had already been done.

## Rules

1. **Make deployment and operational automation idempotent or restartable where practical.** [MUST, source qualifier: where practical] Check: running the script twice, or killing it at any line and running it again, ends in the intended state without duplicating side effects.
2. **Decide explicitly whether the source's four cases apply.** [MUST] Restartability is required when deployments touch many machines, scripts may be rerun after partial failure, migrations run while old and new versions coexist, or procedures must be repeatable under release pressure. Check: the script's header or review note says which apply.
3. **Record progress durably.** [MUST, source: no manual repair steps with no recorded state] Write a checkpoint per unit of work after that unit is verified. Check: the state survives the process (a file written atomically, or a table), and a rerun reads it.
4. **Decide from observed reality, not only from remembered state.** [Added judgment] Before skipping a step, check the actual condition (installed version, applied migration). A checkpoint can be stale or missing. Check: each step has a "is this already done?" probe that looks at the target.
5. **Do not perform side effects before a durable release checkpoint without a recovery plan.** [MUST NOT] Check: irreversible or externally visible actions (notifications, traffic flips, deletions) come after the checkpoint that makes a retry safe, and have a stated recovery.
6. **Avoid partial migration steps without a rollback or roll-forward path.** [MUST NOT] Check: each step names its inverse or its forward fix, and every intermediate state is safe for the versions that can see it.
7. **Do not ship one-shot scripts that cannot safely resume.** [MUST NOT] Check: no "run from the top again" instructions that would repeat completed work, and no hard-coded host lists mutated by hand mid-run.
8. **Migrations and one-time jobs must be deliberate, observable and recoverable.** [MUST] Run them from a controlled place, not at every application boot. Check: progress is logged and counted, work is batched, and a run can be paused, resumed and verified.
9. **Verify each unit, and stop at the first failure.** [Added judgment, following from small exposure steps] Check: after each host or batch the script checks health and halts rather than continuing across the rest of the fleet.
10. **Pace the work.** [Added judgment] Bound batch size and concurrency so a backfill does not starve online traffic. Check: rate and concurrency are parameters with safe defaults (`/release-it:stability-patterns` covers governors).
11. **Make the run explainable.** [MUST, source: keep process code, scripts and automation observable enough to see what changed and why] Check: each run has an id, logs its inputs, each step and outcome, and leaves a record of what it changed.

## Procedure

1. List the steps, the side effects of each, and which are reversible.
2. For each step write the "already done?" probe and the checkpoint.
3. Order steps so irreversible ones come after a verified checkpoint.
4. Add verification and a halt rule between units.
5. Add progress logging and counters; bound batch size and rate.
6. Test by killing the script between every pair of steps and rerunning it (`/release-it:resilience-testing`).

## Example

```python
import json
import os
import tempfile


def load_state(path):
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def save_state(path, state):
    """Atomic write: a crash leaves either the old file or the new one, never half of it."""
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".")
    with os.fdopen(fd, "w") as f:
        json.dump(state, f)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


# Before: a failure on host 7 means rerunning from the top, which stops and reinstalls hosts 1-6 again,
# and nothing records which hosts run which build.
for host in hosts:
    stop(host); install(host, build); start(host)


# After: resumable, checks reality before acting, verifies each host, and halts at the first failure.
def deploy(hosts, build, state_path):
    state = load_state(state_path)                          # {host: build already verified there}
    for host in hosts:
        if state.get(host) == build:
            continue
        if installed_version(host) != build:                # decide from the target, not only from the file
            drain(host)
            install(host, build)
        start(host)
        if not wait_healthy(host, timeout_s=120):
            raise DeployHalted(f"{host} unhealthy after install of {build}; later hosts untouched")
        state[host] = build
        save_state(state_path, state)                       # checkpoint only after verification
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| One-shot script | A loop with no record of progress and no per-step probe | Checkpoint plus probe |
| Trusting the checkpoint alone | A skip decision that reads only the state file | Also check the target |
| Side effect first | Traffic flip, notification or delete before the verified checkpoint | Reorder; add a recovery plan |
| Manual repair with no record | "Fix by hand and continue" in the runbook | Make the repair a recorded step |
| Boot-time migration | Schema change inside application startup on every instance | Separate, controlled job |
| Unbounded backfill | One statement or loop over the whole table | Bounded, paced, resumable batches |
| Continue past failure | Ignored exit codes, `set +e` with no checks, loops that keep going after an error | Halt and report |

## Trade-offs and exceptions

- The source says "where practical". A throwaway one-time script for a single host does not need a state store; it still needs to say what happens if it is rerun.
- Idempotence can be expensive for operations that are naturally one-way (sending mail); use a deduplication key or move them behind a checkpoint.
- Checkpoint files on the machine running the script are lost with it; for long fleet operations store state somewhere that survives (Added judgment).
- Database migration tooling often provides versioned, resumable migrations; use it rather than building your own.

## Verification

- [ ] Killing the script at any step and rerunning it reaches the intended state.
- [ ] Every skip decision is based on the target's real state.
- [ ] Irreversible actions come after a verified checkpoint, with a recovery plan.
- [ ] Each step has a rollback or roll-forward path.
- [ ] The run halts on the first unhealthy unit.
- [ ] Progress and changes are recorded.

## Related

`/release-it:release-risk` for staging and compatibility; `/release-it:operational-controls` for who may run and stop it; `/release-it:startup-and-health` for startup work; `/release-it:resilience-testing` for interruption tests; `release-it:deployment-reviewer` to review a diff; `release-it:automation-hardener` to apply the change.

## Source

- `Restartable Automation`
- `Runtime State and Restart Safety Rules`
- `Deployment and Startup Rules`: only the rule that migrations and one-time jobs are deliberate, observable and recoverable.
- `Incidents, Capacity, and Runtime Control`: only the rule to keep process code, scripts and automation observable.
- `Code Generation Rules`: only the default of restartable deployment and operational automation and the ban on one-shot release automation.
