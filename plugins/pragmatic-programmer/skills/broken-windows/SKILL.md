---
name: broken-windows
description: "Use when touched code shows small decay (suppressed warnings, commented-out code, a skipped test, a 'temporary' hack) or a quick fix would add more. Decides what to fix now, contain or leave. How far to go and how to report is `ownership`."
---

# Broken windows

Decide what to do about small decay in the code a change touches: fix it now when that is cheap, contain it visibly when it is not, and never treat it as normal. The stopping rule and the reporting rule are `/pragmatic-programmer:ownership`; hunting decay across a whole tree is `/pragmatic-programmer:audit`.

## When to use

- The function you are editing has a suppressed warning, commented-out code, a skipped test, an unexplained magic number or a "temporary" workaround.
- You are about to add a quick fix whose copies will multiply: a third special case, a "just this once" flag.
- Someone says "it was already like that".
- A trend is visible: warnings, skipped tests, TODOs or build time creeping up commit after commit.

## Rules

1. **Do not normalize local decay.** [MUST NOT] A defect left in place tells the next reader that care is optional and makes the next copy easier to justify. Check: you never cite existing decay as the reason to add more of it ("the other handlers do it too").
2. **Fix small quality problems before they signal that nobody cares.** [MUST] Check: the diff contains the small fixes that were cheap, or a note says why not.
3. **Tidy the code you touch where the cost is low and the value is immediate.** [MUST] Added judgment on "low": the fix is inside a function or file you already edit, is verified by tests that exist or by reading, and does not depend on the requested behavior, so it can be reviewed apart from it. Check: each tidy fix has a one-sentence reason.
4. **Leave the area better than you found it.** [MUST] The review checklist asks for at least one small fix when decay exists in the touched area. Check: the answer to "did we fix at least one broken window?" is yes, or "none present".
5. **Avoid leaving behind "temporary" hacks with no cleanup plan.** [MUST NOT] Added judgment on what a plan is: a removal trigger (what makes the hack unnecessary), a place that shows it is a hack, and a pointer to who or what tracks it. Check: each hack in the diff has a comment or ticket reference stating what removes it.
6. **Treat a small quick fix that multiplies future cost as a bad bargain.** [SHOULD] The source says "usually". Check: for each quick fix, name the second copy it invites; if there is one, pay for the proper fix now or contain it.
7. **Watch for entropy: look for the signs that decay is becoming normal.** [MUST] Added judgment on signs: growing ignore or exception lists, commented-out blocks, skipped tests, suppressed warnings and copy-pasted variants. Check: you looked for them in the touched files, not just in the lines you changed.
8. **Watch for boiled-frog drift, where gradual degradation becomes invisible.** [MUST] Added judgment: compare a simple measure over recent history with read-only `git log` and `git diff` (suppression comments added, tests skipped, warnings printed) instead of judging one commit at a time. Check: you looked at the direction, not only the level.
9. **When it cannot be fixed cheaply, contain it visibly.** [Compact checklist] Fix it if cheap; otherwise leave an explicit containment or cleanup path: isolate it behind a name that admits what it is, mark it, and record what would remove it. Check: a reader who finds it learns that it is known.
10. **Keep unrelated cleanup out of the change.** [Added judgment] Decay outside the touched area goes on the follow-up list; a cleanup larger than the change it rides on is its own change. Check: the diff is explainable by the request plus the tidy fixes.

## Procedure

1. List the files and functions the change touches (`git status`, `git diff`, and the untracked files `git status` lists).
2. In those only, list decay candidates: suppressed warnings, commented-out code, skipped tests, TODOs with no condition, duplicated blocks, misleading names, magic numbers, dead flags. Read the code before listing one; a text match is a candidate.
3. For each, estimate cost (minutes, risk, test coverage) and value (does it make this change safer or the next one cheaper).
4. Decide: fix now, contain, or leave, and say why in a line.
5. Make the fixes as separate small hunks and run the tests after each.
6. Write the containment notes in the code, next to the thing contained.
7. Report what was fixed, contained and left, and the follow-ups.

## Example

Task: add a `VIP` code to discount handling. The function already had decay.

```python
# Before
def apply_discount(order, code):
    # if code == "SPRING":            # old promo, keep for now
    #     order.total *= 0.9
    try:
        pct = DISCOUNTS[code]
    except Exception:                  # noqa
        pct = 0
    order.total = order.total - order.total * pct / 100   # TEMP: rounding fix later
    return order

# After: the new code is one dictionary entry; decay inside this function is fixed or contained
def apply_discount(order, code):
    pct = DISCOUNTS.get(code, 0)       # unknown code means no discount
    # Known limit: float arithmetic. Exact once order.total becomes a Decimal (pricing backlog).
    order.total = order.total - order.total * pct / 100
    return order
```

The commented-out promo is deleted (version control keeps it). The blanket `except` is replaced by `.get`; call sites pass string codes (checked), so behavior is unchanged except that a non-hashable code now raises instead of being swallowed. The rounding hack is contained with a named limit and a removal trigger, because fixing it means changing the type of `order.total`, which is outside this change.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Precedent excuse | "Existing code already does this" in a review reply or commit | Fix the instance you touch, or contain it |
| Silent suppression | New `# noqa`, `@ts-ignore`, `eslint-disable` or a warning pragma with no reason | Fix the cause or state the reason beside it |
| Immortal TEMP | `TEMP`, `HACK` or `FIXME` with no condition or owner | Add a removal trigger and a place that tracks it |
| Drive-by rewrite | A cleanup hunk larger than the change it rides on | Split it out as its own change |
| Cleanup tourism | Tidying files the change never touched | Move to the follow-up list |
| Invisible fix | A real cleanup that appears nowhere in the report | List it under tidy fixes |

## Trade-offs and exceptions

- The source limits tidying to "where the cost is low and the value is immediate". Tidy hunks cost reviewers attention, so keep them separable and small.
- If behavior around the decay is unclear and no test covers it, containment is the right answer, not a fix. Characterizing untested code first is the job of a legacy-code plugin.
- Generated and vendored code is not tidied by hand; fix the generator or leave it (`/pragmatic-programmer:generators-and-dsls`).
- A team's lint and style configuration outrank your preferences; fix decay against the project's standard.
- The stop rule in `/pragmatic-programmer:ownership` still applies: this skill is not a license to rewrite a module.

## Verification

- [ ] Every tidy fix is inside a function or file the change already touches.
- [ ] Tests ran after each tidy fix, and any behavior change was called out.
- [ ] Each remaining hack has a removal trigger and a visible marker.
- [ ] You did not cite existing decay to justify adding more.
- [ ] The report lists what was fixed, contained and left.

## Related

`/pragmatic-programmer:tidy-touched` to run the fix-or-contain pass with a budget; `pragmatic-programmer:decay-reviewer` to review a diff for decay; `/pragmatic-programmer:ownership` for the stopping rule; `/pragmatic-programmer:dry-knowledge` when the decay is a copied rule.

## Source

- `Broken Windows Rule`
- `Think Beyond the Local Edit`
- `Named Pragmatic Habits`: only the habits on entropy and boiled-frog drift.
- `Review Checklist`: only the question about fixing at least one small broken window in the touched area.
