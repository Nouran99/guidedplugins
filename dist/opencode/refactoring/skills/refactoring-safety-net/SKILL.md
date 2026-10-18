---
name: "refactoring-safety-net"
description: "Use before risky structural edits, or when tests are absent, weak or being edited during a refactoring: finding or building a safety net, characterization tests, keeping tests honest. The tests that prove behavior; judging the change's meaning is behavior-preservation."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "auto"
---

# Safety net

A refactoring is only as safe as the check that would catch a mistake. This skill decides what that check is, what to do when there is none, and how tests may and may not change while code is restructured. Writing the characterization tests step by step is `refactoring-characterize`; deciding whether the change preserved meaning is `refactoring-behavior-preservation`.

## When to use

- You are about to restructure code and have not yet named the check that would fail if you broke it.
- The area has no tests, thin tests, or tests that only assert that the code runs.
- A structural patch edits, skips or deletes tests.
- The behavior of the code is unclear and a refactoring is still wanted.

## Rules

1. **Create or identify a safety net before risky refactoring (MUST).** Without one, a mistake is found by users. Check: you can name the command, test or tool-verified move that would catch a slip in this change.
2. **Prefer characterization tests when working on unclear existing behavior.** They record what the code does now, not what someone thinks it should do. Check: the test expectations were obtained by running the code, and are labelled as observed.
3. **Add characterization tests before risky edits when behavior is unclear.** Check: the tests exist and pass before the first structural edit.
4. **If tests are absent, make the smallest changes possible and improve testability first.** Check: the first step is the smallest move that makes the next one checkable, not a broad cleanup.
5. **Keep refactoring and test updates aligned with preserved behavior.** Check: a structural step contains no changed expectation.
6. **Never delete a failing test just to complete a refactoring (MUST NOT).** A failing test is information. Check: no test was removed, skipped, loosened or marked flaky in a structural step.
7. **Update tests only when behavior intentionally changes.** Check: every changed expectation sits in the behavior-change step and is explained there.
8. **Keep tests focused on externally visible behavior, and do not couple them to private implementation details more than necessary.** Tests tied to internals break on every legitimate refactoring. Check: the test passes through public entry points and survives a rename of a private helper.
9. **Refactor tests too when they become noisy or duplicative, and keep test data expressive and minimal.** Check: setup in each test contains only what that test needs.
10. **Do not do untested structural surgery.** That means large refactors with no safety net, cleanup on fragile code with no verification strategy, or assuming behavior is obvious when it is not. Check: for each risky area, a net or an explicit verification strategy is written down.
11. **When no net can be built, record the verification gap (compact checklist).** Say what was not verified and why, and limit yourself to changes you can verify by reading or with tool-checked moves. Check: the gap is in your report.
12. **Added judgment: judge a net by its assertions, not its test names.** A test that calls the code and asserts nothing about the result catches nothing. Check: for the lines you will touch, at least one assertion depends on their output.

## Procedure

1. Find the project's test command (`package.json`, `Makefile`, `pyproject.toml`, `go.mod`, build files). Run the covering tests and record the baseline.
2. Map the code you will touch to the tests that exercise it. Mark touched behaviors with no covering assertion.
3. For each gap: write a characterization test if the area is risky (`refactoring-characterize`), or limit the step to a tool-verified move, or record the gap.
4. Restructure in small steps, running the net after each. Never edit an expectation in these steps.
5. If a test breaks, treat it as evidence that behavior changed, and revert the step before deciding anything.

## Example

```python
def line_total(qty, unit_price):
    total = qty * unit_price
    if qty >= 10:
        total = total * 0.9
    return total

# Characterization: pins what the code does today, including the odd case.
# Expectations were observed by running the function, not derived from a spec.
import pytest

@pytest.mark.parametrize("qty, unit_price, expected", [
    (1, 10.0, 10.0),
    (9, 10.0, 90.0),
    (10, 10.0, 90.0),    # observed: 10% discount from 10 units; 9 units pay full price
    (0, 10.0, 0.0),
    (-1, 10.0, -10.0),   # observed: negative quantity is accepted; do not fix inside a refactoring
])
def test_line_total_as_observed(qty, unit_price, expected):
    assert line_total(qty, unit_price) == expected
```

With this net in place the function can be restructured freely; the negative-quantity case becomes a recorded question for a separate behavior change.

## Anti-patterns

- **Deleted red test.** Detect: a removed or skipped test in a diff that also changes production code. Treat: restore it and find why it fails.
- **Test edited to match.** Detect: expected values changed in a structural patch. Treat: revert; the step changed behavior.
- **Implementation-coupled test.** Detect: assertions on private calls, call counts of internal helpers, exact internal structure. Treat: assert on outputs and effects at a public seam.
- **Smoke-only net.** Detect: tests that call the code and only assert "no exception". Treat: add assertions on results before relying on it.
- **Cleanup with no verification strategy.** Detect: no command, no tests, no gap recorded. Treat: stop and build or record one.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Tool-verified mechanical moves (an IDE rename, an extract with automatic checking) are a legitimate net for tiny changes when no tests exist; say that is what you relied on. (Added judgment)
- Characterization tests may pin behavior nobody wants (the negative quantity above). Pin it anyway, mark it, and change it only in a behavior step. (Added judgment)
- Tests that must change because the observable contract changes belong to the behavior step; that is the exception the source allows.

## Verification

- [ ] A named check would fail if this change broke behavior.
- [ ] The baseline was run and its result recorded.
- [ ] No test was deleted, skipped or loosened to finish.
- [ ] No expectation changed in a structural step.
- [ ] Any gap in verification is stated in the report.

## Related

`refactoring-characterize` to write the tests; `refactoring-safety-net-reviewer` to map coverage; `refactoring-test-change-reviewer` to audit test edits in a diff; `refactoring-behavior-preservation` for what must stay the same.

## Source

- `Tests and Verification`
- `Testing Rules`
- `Untested Structural Surgery`
