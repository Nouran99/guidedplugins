---
name: release-risk
description: "Use when planning how a change reaches production: rollout steps, exposure, rollback, version coexistence, config changes, or treating passing QA as proof of readiness. Resumable scripts are `restartable-automation`; pipeline access is `operational-controls`; interface shape is `api-contracts`."
---

# Release risk

Shipping is part of the design. This skill plans how a change is exposed, how long old and new versions overlap, and how it is undone. The resumability of the scripts that carry it out is `/release-it:restartable-automation`, the startup behavior of the new process is `/release-it:startup-and-health`, and the compatibility promise of an interface is `/release-it:api-contracts`.

## When to use

- A change alters a schema, a message format, a configuration key, an API or a dependency that other running versions touch.
- A deployment plan says "release everywhere at once" or "restore from backup" is the rollback.
- Someone says the feature is done because QA passed.
- You cannot tell which version or configuration is running on a given instance.

## Rules

1. **Do not treat QA success or feature completion as proof of production readiness.** [MUST NOT] Tests exercise the happy path of a controlled environment. Check: the plan lists operational evidence (rollback path, signals, capacity assumption), not only test results.
2. **Design deployment, operations, security, observability and rollback as part of the system.** [MUST] Check: the change contains how it ships, how it is watched and how it is undone, in the same plan or pull request.
3. **Reduce release risk with small exposure steps, compatibility discipline and reversible changes.** [MUST] Check: exposure grows in stages with a stop point between them (a canary, a percentage, one tenant or region, a dark launch; these are examples, Added judgment), and each stage can be halted.
4. **Keep compatibility across the coexistence window.** [MUST] During a rollout, old and new code run together against the same data and the same peers. Check: new code reads data written by old code, old code survives data written by new code, and messages and configuration obey the same rule. Expand-then-contract schema changes are the usual way (Added judgment).
5. **Avoid partial deployment or migration steps without a rollback or roll-forward path.** [MUST NOT] Check: every intermediate state is safe to stay in for a while, and each step names its inverse or its forward fix.
6. **Mark the steps that cannot be undone and gate them separately.** [Added judgment, following from the rule against side effects before a durable checkpoint with no recovery plan] Dropping a column, deleting data and sending external messages do not roll back. Check: irreversible steps are separate, later, and approved on evidence from earlier steps.
7. **Make version, build, configuration, dependency and runtime state visible enough to diagnose a live instance.** [MUST] Check: a running instance reports its version, build id and configuration revision, and after a rollout you can list which instances run what.
8. **Make configuration changes auditable and reversible.** [MUST] Check: configuration changes go through a versioned, reviewed channel, are logged with an actor, and the previous value can be restored.
9. **Decide the continue and abort signals before the rollout.** [Added judgment] Name the metrics, thresholds and decision owner. Check: the plan says "stop if X" with a measurable X.
10. **Do not bundle unrelated risky changes.** [Added judgment] Bundling destroys attribution and makes rollback larger than the fault. Check: one risky change per release, or each separately switchable.
11. **Treat feature switches as configuration.** [Added judgment] A switch that nobody audits or removes becomes permanent hidden behavior. Check: switches have an owner, an audit trail and a removal date.

## Procedure

1. List what the change touches that other running things also touch: data shape, messages, configuration, APIs, peers.
2. Write the sequence of releases or steps so every intermediate state is compatible.
3. Mark reversible and irreversible steps; place irreversible ones last.
4. Define exposure stages, continue and abort signals, and who decides.
5. Ensure instances report version, build and configuration revision.
6. Hand the scripted steps to `/release-it:restartable-automation` and the review to `release-it:deployment-reviewer`.

## Example

```sql
-- Before: one release renames the column. Until every instance runs the new code, old instances
-- query a column that no longer exists, and rolling back the code does not bring the column back.
ALTER TABLE orders RENAME COLUMN shipping_fee TO shipping_fee_cents;

-- After: four steps; each leaves a state that both the previous and the next code version can run on.
-- Step 1 (expand, reversible): add the column. Code now writes both columns and still reads the old one.
ALTER TABLE orders ADD COLUMN shipping_fee_cents bigint;
-- Backfill in bounded, restartable batches by id range, never one statement over the whole table.
UPDATE orders SET shipping_fee_cents = ROUND(shipping_fee * 100)
 WHERE id BETWEEN :from_id AND :to_id AND shipping_fee_cents IS NULL;

-- Step 2 (switch, reversible): deploy code that reads the new column and still writes both.
-- Rolling back to step 1 code is safe because the old column is still maintained.

-- Step 3 (stop writing the old column, hard to undo): deploy code that writes only the new column.
-- Rolling back now requires re-filling the old column, so gate this step on step 2's signals.

-- Step 4 (contract, irreversible): after a bake period with no reads of the old column.
ALTER TABLE orders DROP COLUMN shipping_fee;
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Big-bang release | Everything switches in one step, no stages | Staged exposure with stop points |
| Rollback means restore | The only plan is "restore from backup" | Reversible steps, or an explicit roll-forward |
| Incompatible in place | A rename or removal shipped with the code that depends on it | Expand, switch, contract across releases |
| Ready because tests pass | A readiness claim that cites only test results | Operational evidence |
| Invisible versions | No version, build or configuration revision on a running instance | Expose them |
| Hand-edited configuration | Settings changed on servers without a record | Versioned, audited channel |
| Bundled risk | Schema, dependency upgrade and feature in one release | Separate and sequence |

## Trade-offs and exceptions

- Staged rollouts cost time and complexity. The source asks for small exposure steps to reduce risk; scale the ceremony to the blast radius (a copy edit needs none).
- Where rollback is unsafe, a tested roll-forward path is acceptable; the rule is that a path exists.
- Feature switches reduce risk and add configuration surface; weigh both.
- Data compatibility rules for event and schema evolution at depth belong to a data-systems plugin such as `data-intensive-apps`.

## Verification

- [ ] The plan shows operational evidence, not only test results.
- [ ] Every intermediate state is compatible with the versions that can see it.
- [ ] Reversible and irreversible steps are separated.
- [ ] Continue and abort signals are measurable and named.
- [ ] Instances report version, build and configuration revision.
- [ ] Configuration changes are versioned and reversible.

## Related

`/release-it:restartable-automation` for the scripts; `/release-it:startup-and-health` for the new process; `/release-it:api-contracts` for interface compatibility; `/release-it:operational-controls` for who may run the pipeline and how it is stopped; `/release-it:plan` to sequence the change; `/release-it:launch-check` for a go or no-go; `release-it:deployment-reviewer` to review a diff.

## Source

- `Production Readiness and Release Risk Rules`
- `Runtime State and Restart Safety Rules`: only the rule to avoid partial deployment or migration steps without a rollback or roll-forward path.
- `Restartable Automation`: only the anti-pattern of side effects before a durable release checkpoint with no recovery plan.
