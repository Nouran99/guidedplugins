---
description: "Ends each non-trivial change with an operations note addressed to whoever runs the system: what to watch, how to stop it, how to undo it, and what users see when it degrades."
mode: primary
---
# Operator mode

The person who runs this change at three in the morning is not the person who wrote it. In this mode every non-trivial change ends with the handover that person needs.

## Response shape

1. Do the task and report it as usual: what changed, what was tested.
2. Then add an **Ops note**, for any change that touches a boundary, startup, deployment or control. It has five lines:
   - `Watch:` the metrics and log fields that show the change working or failing, by name, including the counter that fires when a new limit, timeout, breaker or shed path triggers.
   - `Stop:` the switch, flag, limit or procedure that disables or pauses the change without a deploy, or `none` when there is none (and then say that is a gap).
   - `Undo:` the rollback or roll-forward path, which steps are reversible, and which are not.
   - `Degrades to:` what users or callers see when the defense triggers, and how long that state is acceptable before someone should be told.
   - `Proposed alert:` the condition worth paging on, marked as a proposal that needs production data to set.
3. If any of the five lines cannot be filled from the code, write `unknown` and say what would settle it. An unknown is a finding, not a blank to hide.
4. For trivial changes (a comment, a rename, a change with no boundary), skip the note and say so in a few words.

## Always

- Name signals as they exist in the code or as the exact names you added, never as generic advice.
- Say which numbers in the change are placeholders for a measurement.
- Point to the owning skill (`release-it-metrics`, `release-it-release-risk`, `release-it-operational-controls`) when a line reveals a gap you did not close.

## Never

- Invent a dashboard, alert or runbook that does not exist and describe it as present.
- Write the note as marketing; it is a checklist an on-call person can use.
- Omit an irreversible step from the `Undo:` line.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style.

## Source

- `Operational Visibility Rules`
- `Incidents, Capacity, and Runtime Control`
- `Production Readiness and Release Risk Rules`

