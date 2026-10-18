---
name: "release-it-operational-controls"
description: "Use when adding or changing an admin endpoint, control plane, kill switch or the access, audit and stop controls of delivery tooling that can affect production, or reviewing secrets and admin access. Rerun safety is `release-it-restartable-automation`; rollout staging is `release-it-release-risk`."
license: "MIT"
metadata:
  plugin: "release-it"
  book: "Release It!"
  invocation: "auto"
---

# Operational controls and delivery tooling

The tools used to run and fix production can break production faster than any bug. This skill makes them safe to hold: authorized, auditable, safe by default and stoppable. What a script does when interrupted is `release-it-restartable-automation`; the overload policy of ordinary endpoints is `release-it-back-pressure`.

## When to use

- An admin endpoint, internal console, feature-switch tool, replay or purge utility, or ops script is created or exposed.
- A deployment pipeline, release tool or infrastructure automation gains permissions over production.
- A review involves secrets, service accounts, network access or administrative access.
- An incident was made worse by a tool that could not be stopped, left no record, or acted on too much at once.

## Rules

1. **Provide administrative interfaces and operational controls only with authorization, auditability, safe defaults and clear stop mechanisms.** [MUST] All four are required, not a menu. Check: for each control, name the authorization rule, the audit record, the default scope and the stop.
2. **Authorize by role, narrowly.** [Added judgment, giving the source's authorization requirement a concrete check] Separate "may look" from "may change", and avoid shared accounts and static admin keys in code. Check: the permission needed is specific and the caller identity is individual.
3. **Record who did what, to what, and with what result.** [MUST, source: auditability] Check: each action writes actor, action, parameters, target, outcome and time to storage the actor cannot edit.
4. **Make the safe choice the default.** [MUST, source: safe defaults; the dry-run, narrow-scope, ceiling and confirmation examples are Added judgment] Dry run unless told otherwise, narrow scope unless widened, a ceiling on batch size, confirmation for large effects. For a control that already exists, changing its default is a behavior change to agree with its users first. Check: calling the control with no options changes nothing or very little.
5. **Provide a stop that works while the operation is running.** [MUST, source: clear stop mechanisms] Check: a pause, cancel or kill switch exists, is checked between units of work, and does not depend on the thing being stopped.
6. **Keep scripts and automation observable.** [MUST] Operators must see what changed and why. Check: each run has an id, logged inputs and a change record.
7. **Treat control planes and delivery tooling as production systems when they can affect production.** [MUST] Check: they have access control, monitoring, change review, backups and an availability target proportionate to their reach, and the tool needed to repair production does not depend on the production system it repairs (Added judgment on the last clause).
8. **Include security in production readiness.** [MUST] Secrets, permissions, administrative access, dependency trust and input handling. Check: secrets come from a secret store and not from the repository, images or logs; credentials are scoped and rotatable; third-party dependencies are pinned and sourced deliberately (the specifics are Added judgment).
9. **Limit the blast radius of each invocation.** [Added judgment] Per-call caps, rate limits and scoping by tenant or shard. Check: a single mistaken call cannot affect everything.
10. **Plan emergency access.** [Added judgment] A break-glass path is acceptable if it is time-limited, loud and reviewed afterwards. Check: bypassing a control leaves a record and expires.
11. **Validate the inputs of controls like any other external input.** [Added judgment, applying the rule that all external input is untrusted to operators too] Check: filters, ids and counts are validated before they drive a bulk action.

## Procedure

1. List the controls the change adds or touches and what each can do to production.
2. For each, answer the four properties in writing: authorization, audit, default, stop.
3. Add per-call caps and pacing.
4. Move secrets to a secret store; narrow credentials.
5. Check that the tool works when production is unhealthy.
6. Test the dry run, the audit record and the stop.

## Example

```ts
// Before: any signed-in user can replay every dead letter at once. There is no record and no way to stop it.
app.post("/admin/replay", async (req, res) => {
  await deadLetters.replayAll();
  res.sendStatus(200);
});

// After: authorized role, validated input, audit record, dry run by default, capped and paced, with a stop endpoint.
const REPLAYABLE_QUEUES = new Set(["orders", "invoices", "emails"]);
const MAX_REPLAY = 1000;

app.post("/admin/replay", requireRole("ops-admin"), async (req, res) => {
  const { filter, limit = 100 } = req.body;                       // narrow by default
  if (!REPLAYABLE_QUEUES.has(filter?.queue) || !Number.isInteger(limit) || limit < 1) {
    return res.status(422).json({ error: "filter.queue must be a known queue and limit a positive integer" });
  }
  const safeFilter = { queue: filter.queue };                     // only the allowlisted shape reaches the store
  const effective = Math.min(limit, MAX_REPLAY);                  // one ceiling, used for the dry run, the record and the worker
  const execute = req.query.execute === "true";                   // dry run unless asked otherwise
  const matched = await deadLetters.count(safeFilter);
  const run = await replayRuns.create({ actor: req.user.id, filter: safeFilter, limit: effective, execute, matched });
  if (!execute) return res.json({ runId: run.id, wouldReplay: Math.min(matched, effective) });
  replayWorker.start(run.id, { filter: safeFilter, limit: effective, perSecond: 20 }); // capped and paced
  res.status(202).json({ runId: run.id, stop: `/admin/replay/${run.id}/stop` });
});

app.post("/admin/replay/:id/stop", requireRole("ops-admin"), async (req, res) => {
  await replayWorker.stop(req.params.id);                         // the worker checks this between items
  await replayRuns.record(req.params.id, { stoppedBy: req.user.id });
  res.sendStatus(204);
});
```

The caps and rate are examples; real values come from what the downstream can absorb.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Unauthenticated or network-only admin | Admin routes protected only by "internal" reachability | Role-based authorization |
| No audit trail | Mutating admin calls with no record of the actor | Audit record with actor and parameters |
| Destructive default | Purge, replay or delete that acts without a flag | Dry run by default |
| No stop | Long-running operation with no cancel path | Stop checked between units |
| Shared credential | One static admin key in code or a shared secret | Individual identity, scoped credentials |
| Tooling that needs prod | A repair script that requires the failing service | Independent path |
| Secrets in the repository | Keys in source, images, CI logs | Secret store |

## Trade-offs and exceptions

- Friction slows emergencies. Allow break-glass access, but log it and expire it, instead of weakening the default.
- Audit logs hold sensitive data; restrict who can read them and keep parameters minimal.
- A small internal tool with a single operator still needs the four properties, scaled down (an audit line, a dry-run flag, a way to stop).
- Application security testing and threat modelling go beyond this book; the source asks only that security be part of readiness.

## Verification

- [ ] Each control has a named authorization rule and an individual identity.
- [ ] Every mutating call writes an audit record.
- [ ] The default invocation is a dry run or a narrow scope.
- [ ] A stop mechanism works mid-run.
- [ ] Secrets are not in the repository, images or logs.
- [ ] Per-call blast radius is capped.

## Related

`release-it-restartable-automation` for resumability; `release-it-release-risk` for how a change is staged and rolled back; `release-it-game-day-plan` for experiments that need these controls; `release-it-stability-patterns` for governors; `release-it-logging` for keeping secrets out of logs; `release-it-control-plane-reviewer` to review a diff.

## Source

- `Incidents, Capacity, and Runtime Control`: only the rules on administrative controls, observable automation, and treating control planes and delivery tooling as production systems.
- `Interconnect, Routing, Security, and Chaos Rules`: only the rule to include security in production readiness.
- `Data Boundary Rules`: only the rule to treat all external input as untrusted.
