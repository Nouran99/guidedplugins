---
name: "debugging"
description: "Use when something fails, throws, hangs or returns wrong results and the cause is unknown: reproduce, isolate, explain, fix, verify, add the regression test. No known failure: $code-complete:routine-testing. Designing the failure path: $code-complete:error-handling."
---

# Debugging as diagnosis

Treats a failure as something to explain before it is changed: reproduce, isolate, explain, fix, verify. It starts from a failure whose cause is unknown; designing tests for a routine with no failure is `$code-complete:routine-testing`, and the agent that carries out the sequence is `code-complete-bug-fixer`.

## When to use

- A test fails, an exception is thrown, output is wrong, a process hangs or a user reports a defect.
- You are about to change code "to see if it helps".
- A fix works but you cannot say why the old code failed.
- The same kind of defect has appeared before.

## Rules

1. **Treat debugging as diagnosis: reproduce, isolate, explain, fix and verify rather than guessing.** Why: a guessed fix often moves the failure instead of removing it. Check: each of the five steps has a recorded result before you call the defect fixed.
2. **Compact rule: when debugging begins from a guess, first make the failure repeatable and collect evidence.** Check: you have a command, input or test that fails on demand, and the failing output in front of you.
3. **Isolate the path.** Check: you can name the smallest input, the smallest set of components and, where history helps, the change that introduced the failure; the cause is narrowed, not assumed.
4. **Explain the cause.** Check: your explanation predicts the failure and also predicts the inputs that do not fail. Added judgment: if it cannot predict both, you have a theory, not a cause.
5. **Fix the root cause when practical, not only the symptom.** Check: the change removes the condition that produced the failure. When only a symptom fix is possible now, say so in the change description and record the follow-up.
6. **Verify.** Check: the reproduction now passes, the related cases and the full relevant tests still pass, and the result matches what your explanation predicted.
7. **Add tests around defects so the same failure is easier to detect next time.** Check: a test fails before the fix and passes after it; it uses the failing input and its boundary neighbors (`$code-complete:routine-testing`).
8. **Use tools to reduce error-prone manual work, not to replace understanding.** Source rule on debuggers, scripts and profilers, with the compact qualifier. Check: a debugger, a bisect or a log statement answers a question you formed first.
9. Added judgment: change one thing at a time. Two edits that "might both help" leave you unable to say which mattered or whether one hid the other.
10. Added judgment: when you cannot reproduce the failure, say so. Do not claim a fix; report what you tried and what evidence would settle it.
11. Added judgment: after finding the cause, search for the same pattern elsewhere (the same off-by-one, the same unchecked input) and report what you find without fixing it unasked.
12. Added judgment: keep temporary debugging output out of the final change.

## Procedure

1. Write down the symptom exactly: what was expected, what happened, where and with which input.
2. Reproduce it, preferably as a failing automated test or a single command. If it only fails sometimes, record how often and under what conditions.
3. Isolate: shrink the input, disable components, or walk history until the failing region is small.
4. Form a hypothesis, then test it with one observation (a print, a breakpoint, a unit call). Discard hypotheses the evidence rejects.
5. State the cause in a sentence that explains both the failure and the passing cases.
6. Fix the cause with the smallest change. Run the reproduction and the surrounding tests.
7. Keep the regression test, remove debug output, and note any similar spots you saw.

## Example

```python
# Symptom: the weekly report has 6 rows for a 7-day week, and an empty report for a one-day filter.
def days_in_range(start: date, end: date) -> list[date]:
    return [start + timedelta(days=i) for i in range((end - start).days)]

# Diagnosis log
#   Repro:       days_in_range(date(2024, 3, 4), date(2024, 3, 10)) -> 6 dates; expected 7
#   Isolation:   the report builder passes the list through unchanged; the function alone reproduces it
#   Cause:       range() excludes its upper bound and (end - start).days is 6, so the last day never appears;
#                with start == end the span is 0, so the result is empty (explains the one-day report too)
#   Fix:         make the end inclusive
#   Verify:      new tests below fail before the fix and pass after; report tests unchanged

def days_in_range(start: date, end: date) -> list[date]:
    """Every date from start to end, both inclusive. Empty when end is before start."""
    span_days = (end - start).days
    return [start + timedelta(days=i) for i in range(span_days + 1)]

def test_full_week_has_seven_days():
    assert len(days_in_range(date(2024, 3, 4), date(2024, 3, 10))) == 7

def test_single_day_range_has_one_date():
    assert days_in_range(date(2024, 3, 4), date(2024, 3, 4)) == [date(2024, 3, 4)]

def test_end_before_start_is_empty():
    assert days_in_range(date(2024, 3, 5), date(2024, 3, 4)) == []
```

## Anti-patterns

- **Guess-and-patch.** Edit, rerun, hope. Detect: several edits in a row with no recorded observation between them.
- **Symptom patch.** A guard that hides the wrong value. Detect: the fix adds a check at the point of the crash instead of at the origin of the bad value.
- **Unreproduced fix.** "Should be fixed now." Detect: no failing command or test before the change.
- **Explanation by coincidence.** The failure stopped after an unrelated edit. Detect: you cannot say why the old code failed.
- **Fix-all commit.** The fix is bundled with refactoring and cleanup. Detect: the diff cannot show which hunk removes the defect (`$code-complete:refactoring-judgment`).
- **Debug residue.** Prints or sleeps left in. Detect: new logging in the diff that no requirement asked for.

## Trade-offs and exceptions

- A symptom fix is acceptable when the root cause is outside your reach or too risky to change now; the source says "when practical". Mark it as a symptom fix and track the root cause.
- Some failures (timing, concurrency, environment) cannot be forced on demand. Then the evidence-gathering step is the work: add targeted diagnostics, record frequency, and report honestly which conditions you could and could not reproduce.
- A very small, obvious defect (a typo in a literal) does not need a diagnosis document; it still needs a reproduction or a test and a verification.
- Tools help, but the compact rules put understanding first: a debugger session without a hypothesis is guessing with extra steps.

## Verification

- [ ] The failure is reproduced by a command or an automated test that fails now.
- [ ] The cause is stated and explains why other inputs pass.
- [ ] The change removes the cause (or is labelled a symptom fix with a follow-up).
- [ ] A regression test fails before the change and passes after.
- [ ] Related tests pass, and no debug output remains.

## Related

`$code-complete:routine-testing` for designing the regression test; `$code-complete:refactoring-judgment` for keeping cleanup out of the fix; `$code-complete:error-handling` and `$code-complete:trust-boundaries` when the cause is a missing check; `code-complete-bug-fixer` to carry out the sequence.

## Source

- `Quality, Collaboration, Debugging, and Refactoring`
- `Performance, Integration, Tools, and Craftsmanship`: only the rule on using tools, debuggers and scripts to reduce error-prone manual work.
- `Testing Rules`: only the rule to cover normal, boundary and invalid inputs, applied to the regression test.
