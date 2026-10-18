---
name: "duplication"
description: "Use when the same logic appears in several places, a fix had to be made twice, or someone proposes a utils or common module. Merge copies of one piece of knowledge into one owner; leave coincidental similarity alone. Removing a layer is needless-abstraction."
---

# Duplication

Duplicated logic is a default target for elimination, but only when the copies are one piece of knowledge. This skill gives the test for that, says where the shared code goes, and keeps coincidental similarity from being fused into a vague helper. Removing forwarding layers is `$refactoring:needless-abstraction`; reshaping one long function is `$refactoring:function-bodies`.

## When to use

- A bug fix or rule change had to be applied in two or more places.
- Two functions or files differ by one literal or one branch.
- A reviewer or an assistant suggests extracting into `utils`, `helpers` or `common`.
- The same edit is about to be made a third time.

## Rules

1. **Treat duplicate logic as a default target for elimination.** Copies drift, and a fix lands in one of them. Check: you searched for the other copies before editing one.
2. **Remove duplication by extracting shared behavior, not by creating a vague utility dumping ground.** Check: the new shared code has a name that states a concept, and a home near the concept that owns the knowledge.
3. **Do not abstract coincidental similarity (MUST NOT).** Two pieces of code that look alike but change for different reasons are not duplicates. Check: apply the sameness test in rule 4.
4. **Added judgment: the sameness test.** If a change to one copy would always require the same change to the others, for the same reason, they are one piece of knowledge: merge. If they could legitimately diverge, leave them. Check: you can write the single sentence both copies implement.
5. **Do not create `utils`, `helpers` or `common` modules as the default response to duplication (Do not).** Organize modules around concepts and behavior, not leftover convenience. Check: the module name would still make sense to a domain expert.
6. **Do not replace understandable duplication with unclear shared code, and do not create common libraries for one caller.** Check: the merged version is no harder to read at each call site than the copies were.
7. **When the same edit appears for a third time, centralize ownership instead of copying again (compact checklist).** Check: count the occurrences; at three, extract.
8. **Added judgment: when copies differ in one detail, make the detail a parameter or a named step.** Parameterize the method, or form a template with a controlled variation point, rather than copying the body. Check: the difference appears exactly once, as an argument or an overridable step.
9. **Move the shared knowledge to the type or module that owns it.** Put a calculation next to the data it uses (`$refactoring:ownership`). Check: callers import a concept, not a convenience bag.
10. **Added judgment: merge in two steps.** First make the copies textually identical (rename, reorder, extract the differing part), run the tests, then replace them with one definition. Check: the first step changes no behavior and the second only removes text.

## Procedure

1. Search for the other copies (identifiers, literals, the shape of the branch). List every occurrence.
2. Apply the sameness test (rule 4) to each pair. Group the copies that pass; leave out those that fail.
3. Make the grouped copies identical in small steps, tests after each.
4. Extract one definition with a concept name at the owner's location; replace the copies one at a time.
5. Note the coincidental similarities you deliberately left.

## Example

```python
# Before: the late-fee rule exists twice
def invoice_late_fee(amount, days_late):
    if days_late <= 5:
        return 0
    return round(amount * 0.015 * (days_late - 5), 2)

def subscription_late_fee(amount, days_late):
    if days_late <= 5:
        return 0
    return round(amount * 0.015 * (days_late - 5), 2)

TERMS_DAYS = 30        # invoice payment terms
TRIAL_DAYS = 30        # trial length: same number, different knowledge

# After: one rule in a module named for the concept; the two 30s stay separate
# billing/late_fees.py
GRACE_DAYS = 5
DAILY_RATE = 0.015

def late_fee(amount, days_late):
    if days_late <= GRACE_DAYS:
        return 0
    return round(amount * DAILY_RATE * (days_late - GRACE_DAYS), 2)

invoice_late_fee = late_fee
subscription_late_fee = late_fee
```

The fee rule passes the sameness test and merges. The two `30`s change for unrelated reasons and are left as two constants.

## Anti-patterns

- **Utils dumping ground.** Detect: a `utils` module with unrelated functions and many importers. Treat: move each function to the concept that owns it.
- **Coincidence merge.** Detect: a shared function with flags that select which caller's behavior applies. Treat: split it back, or keep the copies.
- **One-caller library.** Detect: a "common" package imported from one place. Treat: inline it.
- **Copy at the third time.** Detect: the third paste of the same block. Treat: centralize now.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- The source prefers understandable duplication over unclear shared code; two small copies in different contexts can be the right answer.
- Duplication across a service or module boundary may be cheaper than a shared dependency; weigh that before merging across boundaries (Added judgment).
- Tests may repeat setup for readability; do not merge test data into opaque shared fixtures to remove "duplication". (Added judgment)

## Verification

- [ ] You searched for every copy before changing any.
- [ ] Each merged group passes the sameness test, and the sentence they share is written down.
- [ ] The shared code has a concept name and sits with its owner, not in a bag.
- [ ] Coincidental similarities were left and listed.
- [ ] Tests pass after each copy was replaced.

## Related

`$refactoring:ownership` for where shared behavior lives; `$refactoring:needless-abstraction` for the opposite pressure; `$refactoring:function-bodies` for extraction inside one function; `refactoring-duplication-reviewer` to review a diff for duplication decisions.

## Source

- `Duplicated Code`
- `Class and Module Rules`: only the rule against default utils, helpers and common modules, and the rule to organize modules around concepts.
- `Abstracting Too Early`
- `Review Rules`: only the duplicated logic item.
