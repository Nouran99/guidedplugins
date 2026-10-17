---
name: tdd-discipline
description: "Use when changing behavior, fixing a bug, or deciding how much to test. Covers failing-test-first, bug-fix tests, coverage as a signal, ignored tests and boundary cases. Decides whether and when tests exist; test quality is /clean-code:clean-tests, restructuring is /clean-code:refactoring-steps."
---

# Test-first discipline and proportionate validation

Decides whether a change is protected by tests and in what order the tests and the code are written. What a good individual test looks like is `/clean-code:clean-tests`.

## When to use

- You are about to implement behavior that can be specified as an example.
- You are fixing a bug.
- A refactor touches code whose behavior is not pinned by any test (the sequence of moves is `/clean-code:refactoring-steps`).
- You see `skip`, `@Ignore`, `xit`, `t.Skip` or a test marked flaky.
- Running the build or the tests takes several manual steps.

## Rules

1. **Prefer to write a failing test first when the behavior can be stated clearly.** The failing test is the specification and proves the test can fail. Check: you saw the new test fail, for the reason you expected, before making it pass.
2. **Do not add production behavior that no failing test or stated requirement calls for.** Check: every new branch in the diff is reachable by a test or a stated requirement; speculative options are removed.
3. **Size tests so that one failure points at one behavior or concept.** Check: the failing test's name alone tells you what to look at.
4. **Add or adjust tests whenever behavior changes, a bug is fixed or a refactor is significant.** Check: the diff includes test changes that correspond to each changed behavior.
5. **For a bug fix, add a test that would have caught the bug, when that is feasible.** Write it first and watch it fail on the unfixed code. Check: the regression test fails without the fix and passes with it.
6. **Do not ship a change without validation that fits its risk.** A rename needs less than a pricing change. Check: you ran the relevant tests or checks and can state the command and the result; if you could not run them, say so plainly.
7. **Use coverage to locate untested risk, never as a replacement for meaningful assertions.** Check: a covered line has an assertion that would fail if the line were wrong; a coverage number is not offered as proof of quality.
8. **Treat an ignored, flaky or skipped test as an open question, not a settled fact.** Either fix it, delete it with a recorded reason, or open a tracked follow-up. Check: no test is silently skipped in the touched area, and no flaky test is re-run until green without a cause.
9. **Test the boundaries.** Cover empty, one, many, first, last, just under and just over limits, and absent values. Check: for each comparison or index in the changed code, a test sits on both sides of the edge.
10. **Avoid builds and test runs that need several manual steps.** Check: one documented command builds and runs the tests; if the diff adds a prerequisite step, it is automated or removed.
11. **Run tests at the pace of the change.** Added judgment, following from rule 6: run the narrowest relevant test after each small step and the wider suite before you call the work done.

## Procedure

1. Restate the behavior as an example: given this input and state, expect this result.
2. Find the project's test command (`package.json`, `Makefile`, `pyproject.toml`, `go.mod`, build files). If none can be found, say so.
3. Write one failing test. Run it. Confirm it fails for the right reason (an assertion about the behavior, not a typo or an import error).
4. Write the least production code that passes it. Run it.
5. Refactor with the tests green: names first, then structure.
6. Repeat for the next example, starting with the edges.
7. For a bug: reproduce with a test, watch it fail, fix, watch it pass, keep it.
8. Before reporting: run the wider suite, list what ran and what did not, and mention any skipped or ignored tests in the touched area.

## Example

```python
# Bug report: a 5-item order on a page size of 5 reports 2 pages.

# Step 1 - failing test first (fails: assert 2 == 1)
def test_exactly_one_full_page_is_one_page():
    assert page_count(total_items=5, page_size=5) == 1

# Step 2 - extra edges, then the fix
def test_empty_listing_has_zero_pages():
    assert page_count(total_items=0, page_size=5) == 0

def test_one_item_over_a_full_page_adds_a_page():
    assert page_count(total_items=6, page_size=5) == 2

def page_count(total_items, page_size):
    return -(-total_items // page_size)   # ceiling division; was total_items // page_size + 1
```

The old formula was right for most inputs and wrong exactly on the boundary, which is why the bug survived.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Test after the fact, never seen failing | New test passes on the first run with no change | Revert the fix locally; confirm the test fails |
| Gold-plated production code | Options, branches or parameters no test or requirement calls | Delete them |
| Coverage chasing | Assertion-free tests, tests that execute code and check nothing | Add meaningful assertions or delete |
| Silent skip | `skip`, `xit`, `@Ignore`, `t.Skip` without a reason in the touched area | Fix, delete with reason, or ticket |
| Retry until green | CI rerun policy hides a flaky test | Treat as a defect; find the cause (see `/clean-code:concurrency`) |
| Missing boundary | Tests on typical values only | Add the edge on both sides |
| Multi-step build | README says to run three commands in a specific order | Script it |
| Unreported validation | "Should work" with no command run | Run it, or state that it was not run |

## Trade-offs and exceptions

- Test-first is a preference ("Prefer"). When behavior cannot yet be specified clearly (exploratory spikes, layout work), write the test as soon as the behavior is clear and say that you did.
- Some changes have no meaningful test: a comment, a rename verified by the compiler. Proportionate validation may be the compiler and the existing suite.
- When no test infrastructure exists, do not invent a passing result. Say what is missing, and propose the smallest harness.
- For untested legacy code, pin the current behavior with a few characterization tests before restructuring; a legacy-code plugin goes deeper.
- Do not add a regression test that depends on the fix's implementation; test the behavior.

## Verification

- [ ] Every changed behavior has a test that fails without the change.
- [ ] A bug fix includes a regression test you saw fail first.
- [ ] No production behavior was added beyond what a test or requirement justifies.
- [ ] Edge cases for each touched comparison, index or limit are covered on both sides.
- [ ] No test in the touched area is skipped or ignored without a recorded reason.
- [ ] You ran the relevant tests with one command and reported the result.

## Related

`/clean-code:clean-tests` for test quality; `/clean-code:smells-surprise` for boundary behavior bugs; `/clean-code:plan` to sequence the work; `clean-code:test-gap-reviewer` to find unprotected behavior; `clean-code:test-writer` to delegate writing.

## Source

- `Tests`
- `TDD and clean test rules`
- `Change Process`: only the steps on adding tests and running validation.
- `Smells to detect and eliminate`: only the ignored tests, insufficient boundary tests and multi-step build smells.
