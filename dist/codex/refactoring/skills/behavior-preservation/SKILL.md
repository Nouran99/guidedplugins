---
name: "behavior-preservation"
description: "Use to decide whether a change really is a refactoring: what counts as observable behavior, a feature or bug fix hiding inside cleanup, a risky 'modernization'. Judges the meaning of a change; step size is small-steps, tests are safety-net, packaging is patch-hygiene."
---

# Behavior preservation

The test that separates refactoring from everything else: after the change, does the program do the same observable thing? This skill defines "observable", lists the ways a tidy-looking edit quietly changes it, and says what to do when behavior must change. How big each step is belongs to `$refactoring:small-steps`; the tests that prove sameness belong to `$refactoring:safety-net`; how the change is cut into patches belongs to `$refactoring:patch-hygiene`.

## When to use

- A change is described as cleanup, a rename, a move or a refactoring and you must confirm it.
- A "simplification" replaces a loop, a conditional or a library call with something shorter.
- A bug or an odd behavior shows up in the middle of a restructuring.
- A request mixes "clean this up" with "and make it also do X".

## Rules

1. **Preserve observable behavior during refactoring (MUST).** A structural change that alters what callers can see is not a refactoring. Check: for each touched unit, list its observable surface and mark each item same or changed (see rule 6).
2. **If behavior must change, isolate the behavior change from the structural change (MUST).** Mixed steps cannot be verified or reverted separately. Check: the work is two steps, and only the second may touch a test expectation.
3. **Never disguise a feature change as a refactoring (Never).** A reviewer who trusts the label skips the scrutiny the change needs. Check: if any test expectation, output or error changed, the word "refactor" does not describe the step.
4. **Cleanup does not mean unverified edits.** The source counts unverified cleanup and "modernization" with unclear behavioral impact as not refactoring. Check: each such edit names the check that shows sameness; otherwise it is deferred or treated as a behavior change.
5. **Do not rename everything at once, and do not bundle architecture migration, feature work and cleanup in one uncontrolled patch.** Check: the change has one stated intent; the rest is listed as follow-up.
6. **Added judgment: observable means anything a caller, another system or an operator can depend on.** Return values; exceptions and error types or messages that callers match on; side effects and their order (writes, calls, events, files); timing or ordering contracts; serialized names and formats (JSON keys, column names, queue job names, log lines that are parsed); public symbols. Check: grep the repository for each changed name as a string, not only as a symbol.
7. **Added judgment: when unsure whether something is observable, treat it as observable.** The cost of an unneeded check is small next to a silent change. Check: the doubt is written down, with the check that would settle it.
8. **Added judgment: a bug found during refactoring is preserved, recorded and fixed separately.** It applies the isolation rule (rule 2); the source does not mention bugs found on the way. Fixing it inside the structural step breaks rule 2. Check: the bug appears in a "noticed, not changed" list, and its fix has its own test and step.
9. **Added judgment: watch the equivalence traps.** Short-circuit and evaluation order; eager versus lazy evaluation; swallowed versus propagated errors; aliasing (sharing a collection versus copying it); null versus empty; sorting stability; integer and float arithmetic; time zones and locales; resource close order. Check: for each rewrite, name which trap could apply and why it does not.
10. **Added judgment: public API changes are behavior changes for outside callers even when nothing changes inside.** The source speaks of observable behavior without defining who observes it. Check: a renamed or moved public symbol has a compatibility step, or the user approved the break.

## Procedure

1. State the intent of the change in one sentence: structure only, or behavior.
2. For each touched unit, list the observable surface (rule 6) and the check that covers it (existing test, new characterization test, type checker, manual read).
3. Walk each edit and mark it same, changed or unknown. Unknown is treated as changed until checked.
4. If anything is changed, split it out into its own step (`$refactoring:split-patch` when the patch already exists), and write its test first (test first is Added judgment; the source asks only that the behavior change be isolated).
5. Report: observable surface, what was verified and how, what remains unverified.

## Example

```python
# Before: stops at the first overdue invoice and notifies once
def first_overdue(invoices, today):
    for inv in invoices:
        if inv.due < today and not inv.paid:
            notify(inv.customer)
            return inv
    return None

# "Cleanup" that is a behavior change: now notifies for every overdue invoice
def first_overdue(invoices, today):
    overdue = [inv for inv in invoices if inv.due < today and not inv.paid]
    for inv in overdue:
        notify(inv.customer)
    return overdue[0] if overdue else None

# Structure-only version: same loop, same single notification
def is_overdue(inv, today):
    return inv.due < today and not inv.paid

def first_overdue(invoices, today):
    for inv in invoices:
        if is_overdue(inv, today):
            notify(inv.customer)
            return inv
    return None
```

The second version reads as a harmless comprehension but changes the number of side effects. The third extracts the predicate and leaves control flow and effects alone.

## Anti-patterns

- **Test-edited refactoring.** Detect: a structural patch that changes an expected value, a mock setup or a snapshot. Treat: revert the edit; the step changed behavior.
- **Modernization rider.** Detect: callbacks to async, a library swap or an API redesign described as cleanup. Treat: classify it as a behavior risk and give it its own step and verification.
- **Fix on the way past.** Detect: a diff that changes a boundary condition inside a restructuring. Treat: take the fix out into its own step.
- **Silent public rename.** Detect: an exported symbol, route, config key or serialized name that changed. Treat: add a compatibility alias, or ask.

## Trade-offs and exceptions

- The source allows behavior changes; it requires them to be isolated and, where practical, separated in the patch series. A behavior change is not forbidden, only unlabelled behavior change is.
- When the user explicitly asks for a rewrite or a redesign, follow the request and say which rule it bends; do not call it refactoring.
- If no safety net exists, the conservative reading in rule 7 applies and `$refactoring:safety-net` says what to do next.

## Verification

- [ ] The intent of the change is stated as structure or behavior, not both.
- [ ] The observable surface of every touched unit is listed and each item is marked same.
- [ ] No test expectation changed in a structural step.
- [ ] Any bug or behavior change noticed is recorded and split out.
- [ ] Public symbols, serialized names and error types are unchanged, or the change is flagged.

## Related

`$refactoring:small-steps` for step size; `$refactoring:safety-net` for the tests; `$refactoring:patch-hygiene` for packaging; `$refactoring:error-paths` for failure semantics; `refactoring-behavior-preservation-reviewer` to review a diff for behavior drift.

## Source

- `What Counts as Refactoring`
- `Non-Negotiable Rules`
- `Purpose`
- `Final Instruction`: only the rule to prefer behavior-preserving transformations.
