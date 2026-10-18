---
name: "test-portfolio"
description: "Use when deciding which tests a change needs (unit, integration, error and recovery, resource exhaustion, performance), when a person found a bug and it needs a regression test, or when tests mirror internals. Speed and flakiness are `$pragmatic-programmer:feedback-loops`; explaining the defect is `$pragmatic-programmer:debugging`."
---

# Test portfolio

Decide what a change must have tests for, and what each test protects. This skill is about coverage of kinds of behavior and failure, and about tests that are tied to a contract. How quickly and clearly checks run is `$pragmatic-programmer:feedback-loops`; reproducing and explaining a defect is `$pragmatic-programmer:debugging`.

## When to use

- A change alters behavior and you must decide what to test.
- A person (a user, support, a reviewer) found a bug that no automatic test caught.
- Tests only cover the happy path, or only mirror the implementation's internals.
- You need to judge whether the existing tests would notice a regression.

## Rules

1. **Test unit behavior, integration, validation and verification, resource exhaustion, errors and recovery, performance, usability and the tests themselves, where relevant.** [MUST] Check: for each changed behavior you can list which kinds apply and which you skipped, with a reason.
2. **Prefer tests that align with the business or technical contract being protected.** [SHOULD] Check: a test's name reads as a statement of the contract, and renaming an internal helper does not break it.
3. **Use automation so validation is habitual, not heroic.** [MUST] Check: the tests run from one command without special preparation.
4. **When a person finds a bug, add or improve an automatic regression test around the protected contract.** [Compact checklist] Check: the new test fails on the old code and passes on the fix.
5. **Say which kinds of test you are skipping, and why.** [Added judgment] Check: the report has a "not tested" line.
6. **Distinguish verification from validation.** [Added judgment] Verification asks whether it was built as specified; validation asks whether the specification serves the user. Check: at least the verification tests exist, and you flag what only a user can validate.
7. **Test errors and recovery, not only success.** [Added judgment] The source names this kind of test; the method is this plugin's. Make the dependency fail, the input malformed, the process stop midway, and assert the recovery or the clean refusal. Check: each failure path in the change has a test that reaches it.
8. **Test resource exhaustion where the code holds resources.** [Added judgment] The source names this kind of test; the method is this plugin's. Exhaust the pool, fill the disk fake, hit the limit, and assert the behavior. Check: the limit cases appear in the tests, not only the average case.
9. **Test performance where growth matters.** [Added judgment] The source names this kind of test; the method is this plugin's. Use realistic input sizes, not the three-row fixture (`$pragmatic-programmer:resource-discipline`). Check: a size that would expose a quadratic path is in the tests.
10. **Test the tests.** [Added judgment] The source names testing the tests; the method is this plugin's. Break the code on purpose (flip a condition, remove a line) and confirm a test fails. Check: a test that cannot fail has been fixed or removed.
11. **Never delete, skip or weaken a failing test to get a pass.** [Added judgment] Fix the code, or fix the test and say why its expectation was wrong. Check: no test lost an assertion or gained a skip in the diff without an explanation.
12. **Flag usability for a person.** [Added judgment] An agent usually cannot judge whether a flow is usable. Check: the report names usability as untested and says who should try it.

## Procedure

1. List the behaviors the change adds or alters, each as a sentence about the contract ("a refund never exceeds what was captured").
2. For each, mark the relevant kinds: unit, integration, error and recovery, resource exhaustion, performance, usability.
3. List what exists. Match behaviors to tests; mark the gaps.
4. For a bug found by a person, write the regression test first, watch it fail, then fix.
5. Name tests after the contract they protect.
6. Break the code once to confirm the new test notices.
7. Report tested, not tested and why.

## Example

Support reports that refunding all three lines of a 10.01 order refunded 10.03. The bug is in tax allocation, which rounds each share up.

```python
# Before: each line's share of the tax is rounded up, so shares can add up to more than the tax
def allocate_tax(lines_cents, tax_cents):
    total = sum(lines_cents)
    return [math.ceil(tax_cents * l / total) for l in lines_cents]
# lines [333, 333, 334] with 1 cent of tax -> shares [1, 1, 1]: 3 cents allocated, 1 cent of tax

# After: floor each share, then hand the leftover cents to the largest remainders
def allocate_tax(lines_cents, tax_cents):
    total = sum(lines_cents)
    if total <= 0:
        raise ValueError("allocate_tax: lines must sum to a positive amount")
    shares = [tax_cents * l // total for l in lines_cents]
    leftover = tax_cents - sum(shares)
    by_remainder = sorted(range(len(lines_cents)),
                          key=lambda i: (tax_cents * lines_cents[i]) % total, reverse=True)
    for i in by_remainder[:leftover]:
        shares[i] += 1
    return shares

# The regression test is named for the contract, not for the helper
def test_full_refund_adds_up_to_the_amount_captured():
    lines, tax = [333, 333, 334], 1
    refunds = [l + s for l, s in zip(lines, allocate_tax(lines, tax))]
    assert sum(refunds) == sum(lines) + tax
```

With the old code the test fails (refunds add up to 1003, not 1001); with the fix it passes (shares are `[0, 0, 1]`). A second test with a zero total checks the refusal path.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Happy-path only | Every test passes valid input and a working dependency | Add error, recovery and limit cases |
| Mirror test | A test that repeats the implementation line by line | Assert the contract's observable result |
| Bug without a test | A fix in the diff with no new test | Write the regression test first |
| Unfalsifiable test | A test that passes when the code is broken | Break the code on purpose and strengthen it |
| Tiny fixtures | Performance-sensitive code tested with three rows | Add a realistic size |
| Quiet weakening | A removed assertion, a new skip, a widened expectation | Restore it or explain it |

## Trade-offs and exceptions

- The source says "where relevant". Not every change needs all kinds; a rename needs none beyond the existing suite. Choose by the risk of the change and say what you left out.
- Performance and resource-exhaustion tests can be slow or environment-dependent. Keep them out of the fast path (`$pragmatic-programmer:feedback-loops`) and run them where they fit.
- Tests tied to a contract still need maintenance when the contract changes; that is the point, not a defect.
- Validation, the question of whether the right thing was built, cannot be settled by automatic tests alone (Added judgment).

## Verification

- [ ] Each changed behavior is stated as a contract and has a test named for it.
- [ ] The relevant kinds of test are present or their absence is explained.
- [ ] Every person-found bug has a regression test that failed before the fix.
- [ ] No test was deleted, skipped or weakened without an explanation.
- [ ] At least one new test was shown to fail when the code was broken.

## Related

`$pragmatic-programmer:feedback-loops` for speed and flakiness; `$pragmatic-programmer:debugging` and `pragmatic-programmer-bug-fixer` for finding and fixing a defect; `pragmatic-programmer-test-portfolio-reviewer` to review a diff; `$pragmatic-programmer:contracts` for the contract a test protects.

## Source

- `Testing Rules`: only the rules on contract-aligned tests and habitual, automatic validation.
- `Project and Team Rules`: only the rule that lists the kinds of testing to apply where relevant.
