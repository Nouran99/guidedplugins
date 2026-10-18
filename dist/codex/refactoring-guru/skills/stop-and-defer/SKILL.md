---
name: "stop-and-defer"
description: "Use when a refactoring is running long: another smell appears, cleanup keeps expanding, a treatment would cross API or ownership scope, or a visible smell should be left in place. Stop conditions, deliberate exceptions, deferred smells; choosing is treatment-choice."
---

# Stop and defer

Owns the fourth step of the loop (stop) and the permission to leave a smell alone. Choosing the treatment belongs to `$refactoring-guru:treatment-choice`; checking behavior belongs to `$refactoring-guru:refactoring-process`.

## When to use

- You finished one treatment and notice another smell in the same file.
- The diff is growing past what the request needs, or a step turned out to need a different diagnosis.
- The next improvement would change a public API, cross a team's ownership boundary or add feature scope.
- A smell is visible in touched code and you think the mechanical treatment would make the code worse.
- You must write down what you did not treat.

## Rules

1. **Decide the stop condition before editing** (the fourth step of the loop). Check: the plan says in one sentence what "done" looks like for this smell.
2. **Stop when the named smell is gone or materially reduced.** Check: you can point to the symptom you named and show it is absent or smaller.
3. **Stop when the next improvement requires a different smell diagnosis.** A different diagnosis is a different refactoring with its own check. Check: the next candidate step would need a new "symptom, cost, technique" line.
4. **Stop when the work would cross ownership, public API or feature scope without explicit approval.** Check: every touched file belongs to the requested scope, and every changed signature is covered by `$refactoring-guru:public-compatibility`.
5. **Stop when the code is cleaner enough for the requested change and further cleanup is speculative.** Check: each remaining idea is justified by a cost you can name today, not by a future need.
6. **Do not continue refactoring just because another smell was discovered** (`MUST NOT`). Record it separately, unless it blocks the current change. Check: every hunk belongs to the diagnosed smell or to a step that unblocks it.
7. **Stop and reduce scope when the refactoring becomes too large to reason about locally** (`MUST`), and when it exposes a larger, different problem, stop and report the new scope. Check: your report names the larger problem instead of starting on it.
8. **Pause and re-diagnose when a chain of small edits is not improving clarity** (`SHOULD`). Check: after the pause you either name a new smell or revert the chain.
9. **Do not treat every smell mechanically** (`MUST NOT`); confirm that the treatment improves clarity for this codebase. Check: you can describe how a reader's task is easier after the change.
10. **The source permits leaving these in place** (`MAY`): a simple conditional when polymorphism would obscure a direct rule; duplicate fragments when the shared abstraction would be less obvious than the duplication; comments that explain why, external constraints or algorithms that resisted simpler structure; a small class that communicates a real extension point or boundary; behavior separated from data when the design intentionally supports interchangeable behavior; a long parameter list temporarily when removing parameters would create stronger unwanted dependencies. Check: the reason you give matches one of these, in the code's own terms.
11. **Document or report every intentional non-treatment of a visible smell in touched code** (`MUST`). Check: each left smell appears in the report or the code review with its reason.
12. **After editing, confirm no new smell was introduced** (especially middle man, speculative generality or inappropriate intimacy) and report the technique used, the stop condition reached and the validation performed. Check: the report has those three items.

## Procedure

1. Before the first edit, write the stop condition next to the smell.
2. After each step, ask the four stop questions: gone or reduced? different diagnosis needed? crossing scope? cleaner enough?
3. When you notice another smell, decide in one line: blocks the current change (treat it as a second, separate refactoring with its own card) or does not block it (record it).
4. Record deferred smells in the report using the format below. Added judgment: one line each so the list stays readable.
5. Before finishing, review the diff for hunks that belong to no recorded smell, and revert or move them.

## Example

Three phases of `invoice_total` were extracted to resolve a long method. While working, two more smells came into view.

```python
# Diagnosed smell: Long Method (three commented phases).
# Stop condition: the coordinator reads on one screen and needs no comments.
def invoice_total(order):
    amount = apply_loyalty_discount(line_subtotal(order), order.customer)
    return amount + shipping_fee(amount)
```

```text
Technique: Extract Method x3 (line_subtotal, apply_loyalty_discount, shipping_fee). Stop reached.
Validation: pytest tests/test_invoice.py, 14 passed before and after.
Not treated, not blocking this change:
- Primitive Obsession: amounts are floats here and in tax.py. Cost: rounding drift. Revisit when a tax rule changes.
- Feature Envy (unsure): apply_loyalty_discount reads only customer.years. Left in place: one field, one caller, no better owner is evident.
```

The report separates what was done from what was noticed, so the reviewer can accept the first and schedule the second.

## Anti-patterns

- **Smell chasing.** Each fix reveals the next, and the diff keeps growing. Detect: the description lists more smells than the request mentions.
- **Silent leave-behind.** A visible smell in touched code with no note. Detect: review asks "why did you not fix this?" and there is no answer in the report.
- **Stop by exhaustion.** Stopping because time ran out with half-moved code. Detect: an intermediate state is committed that is neither the old nor the new structure.
- **Scope laundering.** Calling an API change "part of the cleanup". Detect: a public name or signature changed without approval.
- **Permanent exception.** A deliberate non-treatment never revisited. Detect: the same note appears in successive reports. Added judgment: attach a trigger to revisit.

## Trade-offs and exceptions

- A smell that blocks the current change is not deferrable; treat it as its own step with its own check, then stop.
- Stopping early is not permission to leave the touched area as unclear as before: a refactoring that leaves the code just as unclear is not a success (see `$refactoring-guru:refactoring-process`).
- Added judgment: when approval is required (API, ownership), stop at a clean intermediate state and ask, instead of finishing speculatively.

## Verification

- [ ] The stop condition was written before the first edit.
- [ ] No hunk addresses a smell other than the diagnosed one, unless it unblocks it.
- [ ] Every smell left in touched code is listed with a reason.
- [ ] No public API, ownership or feature scope was crossed without approval.
- [ ] The report names technique, stop condition reached and validation.

## Related

`$refactoring-guru:treatment-choice` for choosing; `$refactoring-guru:smell-to-treatment` for a card that includes a stop line; `refactoring-guru-scope-guard` to audit a finished diff against the stop condition; `$refactoring-guru:debt-triage` for ranking the deferred list.

## Source

- `Diagnose, Treat, Verify, Stop`
- `Smell Exception Rules`
- `Smell Detection Process`: only the rule against continuing because another smell was found.
- `Keep the Result Cleaner`: only the rule to pause and re-diagnose.
- `Work in Small Steps`: only the rule to stop and reduce scope.
- `Refactoring Workflow for Agents`: only the stop-and-report items of the editing and after-editing lists.
