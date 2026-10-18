---
name: "pragmatic-programmer-debugging"
description: "Use when a bug, failing test, intermittent failure or surprising behavior must be explained, or when code works for reasons nobody can explain. Covers reproduce, observe, isolate, explain, fix, verify. Failure design is `pragmatic-programmer-error-recovery`; which tests protect the fix is `pragmatic-programmer-test-portfolio`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Debugging from facts

Do not guess. Find out why a defect happens before changing anything, then fix the cause and prove the fix. The source gives the sequence in one line (reproduce, observe, isolate, explain, fix, verify) and two triggers from the compact rules; the techniques below are labelled Added judgment. To run the sequence with an evidence record, use `pragmatic-programmer-debug-session`; designing how failures travel is `pragmatic-programmer-error-recovery`.

## When to use

- A test fails, a user reports wrong behavior, or a failure is intermittent.
- A change "fixed" a symptom and nobody can say why it worked.
- A theory blames the compiler, the operating system, a library or a vendor.
- Code works, but nobody can explain why, and something depends on it.

## Rules

1. **When debugging, do not guess: reproduce, observe, isolate, explain, fix and verify.** [MUST NOT] Guessing is forbidden and the sequence is how you avoid it. Check: each step has a recorded result before the next starts.
2. **Reproduce first.** [MUST] It is the first step of the source's sequence. Added judgment on the how: get a failing command or test that shows the symptom. If you cannot reproduce it, say so and gather observations; do not fix blind. Check: the reproduction is a command someone else can run.
3. **Observe before theorizing.** [MUST] Added judgment: record the facts first: actual inputs and outputs, versions, environment, logs, timing. Check: the notes contain what happened, separate from what you think it means.
4. **Isolate.** [MUST] Added judgment: shrink to the smallest input and code path that still fails, change one thing at a time, and compare a failing case with a passing one. Ask the user before checking out other revisions to search history. Check: you can name the smallest failing case.
5. **Explain.** [MUST] Added judgment: write the cause in a sentence that predicts other symptoms, before you edit. Check: the explanation says what else must be true if it is right.
6. **Fix the cause, with the smallest change that follows from the explanation.** [MUST] Check: the change addresses the explained cause, not the observed symptom.
7. **Verify.** [MUST] Added judgment: the reproduction now passes, nearby tests pass, and the other predictions of the explanation hold. Check: you saw each result; none is assumed.
8. **Do not blame compilers, operating systems, libraries or vendors before the facts say so.** [Compact checklist] Check: a claim against a tool comes with a minimal case that fails without your code.
9. **When code works for reasons nobody can explain, stop and prove the behavior with data before depending on it.** [Compact checklist] Check: the behavior has a test or a recorded measurement, not an anecdote.
10. **When a person found the bug, add or improve an automatic regression test around the protected contract.** [Compact checklist] See `pragmatic-programmer-test-portfolio`. Check: the test failed before the fix.
11. **Keep a record of what you tried.** [Added judgment] Symptom, evidence, hypotheses (including rejected ones), explanation, fix. Check: the next person can see what was ruled out.
12. **Revert experiments that did not help.** [Added judgment] Check: the final diff contains only the fix and its test.

## Procedure

1. Write the symptom exactly: what was expected, what happened, where, how often.
2. Find the project's test or run command and reproduce with the narrowest case.
3. Observe and record facts; gather logs, inputs and versions.
4. List hypotheses with the observation that would reject each; test the cheapest rejection first.
5. Isolate until a minimal case fails.
6. Write the explanation and its predictions. Stop here if the user asked for diagnosis only.
7. Write the failing regression test, make the smallest fix, run the test and its neighbors.
8. Record the outcome. Hand the fix to `pragmatic-programmer-bug-fixer` when it is large.

## Example

A test fails only on some runs: `test_report_covers_today`.

```text
Symptom      test_report_covers_today fails on some runs: expected 2026-03-14, got 2026-03-15
Reproduce    At 17:30 local time with TZ=America/Los_Angeles, the test fails; at 10:00 it passes
Observe      build_daily_report() reads the date from the UTC clock; the test reads date.today(), local time
Hypotheses   H1 the date source differs between code and test (predicts: fails only while the local date
                and the UTC date differ)
             H2 order dependence between tests (predicts: also fails when run alone) -> rejected, it passes alone
Isolate      With fixed instants, 2026-03-14 23:30 at UTC-7 fails and 12:00 at UTC-7 passes
Explanation  The report defines "today" by the UTC date; the test defines it by the local date. They differ
             for part of every day on any machine that is not on UTC.
Fix          build_daily_report takes the date as a parameter; production passes the business-timezone date;
             the test passes a fixed date
Verify       Reproduction now passes at 17:30 and 10:00; full suite passes under TZ=UTC and TZ=Pacific/Auckland
```

```python
# Before
def build_daily_report():
    today = datetime.now(timezone.utc).date()
    ...

# After
def build_daily_report(today: date):
    ...

# production: build_daily_report(datetime.now(BUSINESS_TZ).date())
def test_report_covers_given_day():
    assert build_daily_report(date(2026, 3, 14)).date == date(2026, 3, 14)
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Shotgun fix | Several unrelated changes made at once "to see if it helps" | One change per hypothesis; revert failures |
| Symptom patch | A guard that hides the wrong value without explaining it | Find why the value was wrong |
| Blame the tool | "It's a compiler bug" with no minimal case | Reproduce without your code first |
| Works by accident | A fix nobody can explain | Explain it or prove it with data |
| Fix without a test | A person-found bug and no regression test | Write the test that fails first |
| Retry as cure | A retry added to make an intermittent failure disappear | Find the cause of the intermittence |
| Undocumented dead ends | A fix with no record of what was ruled out | Keep the evidence record |

## Trade-offs and exceptions

- The source states the sequence and the rule against guessing; it does not prescribe tools or techniques. The techniques here are Added judgment, offered because the sequence is only useful if each step is concrete.
- Some defects cannot be reproduced on demand (rare races, production-only data). Say so, gather observations and add instrumentation as a deliberate step, rather than patching on a theory.
- A trivial typo does not need the full record. Rule 1 still holds: confirm the cause before editing.
- Searching history for the commit that introduced a bug is a strong technique, but it checks out other revisions; ask first, and never run it on a dirty working tree (Added judgment).

## Verification

- [ ] A reproduction command or test exists and was run before any fix.
- [ ] Observations are recorded separately from theories.
- [ ] The explanation names the cause and a prediction that was checked.
- [ ] The fix is the smallest change that follows from the explanation.
- [ ] A regression test fails before the fix and passes after it.

## Related

`pragmatic-programmer-debug-session` for the guided record; `pragmatic-programmer-bug-fixer` to carry out the fix; `pragmatic-programmer-test-portfolio` for regression tests; `pragmatic-programmer-error-recovery` for failure design.

## Source

- `Basic Tool Rules`: only the rules on debugging by reproducing, observing, isolating, explaining, fixing and verifying, and on not relying on tools you do not understand.
