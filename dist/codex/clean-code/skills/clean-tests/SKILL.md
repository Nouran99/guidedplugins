---
name: "clean-tests"
description: "Use when writing, reviewing or refactoring unit and integration tests, or when tests are slow, fragile, order-dependent or hard to read. Judges how a test is written; whether one is needed or written first is $clean-code:tdd-discipline, flakiness from threads or timers is $clean-code:concurrency."
---

# Clean tests

Judges the quality of a test and of a test suite: readable, deterministic, isolated and focused. Whether the right tests exist at all, and the order in which tests and production code are written, is `$clean-code:tdd-discipline`.

## When to use

- You write a new test, or review a diff that adds or changes tests.
- A test needs forty lines of setup before it asserts anything.
- A refactor of production code breaks tests that should not care.
- Tests fail depending on order, clock, machine, or whether a service is running.
- A failing test name does not tell you what behavior broke.

## Rules

1. **Treat tests as production-quality code.** Dirty tests make production code unsafe to change, because nobody trusts or updates them. Check: the same naming, duplication and structure standards apply to the test file as to the code under test.
2. **Keep tests clean, readable, deterministic and maintainable.** Check: no randomness, wall-clock time, network or file-system state leaks into outcomes unless that is the thing under test, and then it is controlled.
3. **A test communicates one main idea.** Check: the test name states a behavior, and every assertion supports it. Several assertions are fine when they describe one concept; unrelated assertions are two tests.
4. **Prefer simple setup and clear assertions.** The reader should see arrange, act and assert at a glance. Check: the data that matters to the outcome is visible in the test; incidental data is hidden in a builder.
5. **Avoid brittle tests coupled to irrelevant implementation details.** Check: renaming a private method or reordering internal calls does not fail the test; assertions target observable behavior.
6. **Tests should be fast when possible.** A slow suite is run less. Check: unit tests need no network, no real clock sleeps, and no heavyweight container.
7. **Tests should be isolated and order-independent.** Check: any single test can run alone and in any order; no test reads state another one wrote.
8. **Tests should be self-checking.** A test decides pass or fail itself. Check: no test requires a human to read printed output.
9. **Use test names and test data that reveal the business or technical behavior under test.** Check: from the failure line alone you can tell which rule broke; values like `42` and `"test"` are replaced by values that explain themselves.
10. **Build a small testing vocabulary or helper DSL when repeated setup hides intent.** Check: a helper such as `aMemberWithFines(600)` replaces five lines of construction.
11. **Avoid environment-dependent tests without need.** Check: tests do not depend on time zone, locale, installed tools or a developer's machine unless they exist to verify exactly that.
12. **Keep one concept per failure.** A failure should name one behavior. Check: when the test breaks, you know what to look at without a debugger.

## Procedure

1. Read the test as a stranger: name, setup, action, assertion. Write what behavior it claims.
2. If the claim needs "and", split the test.
3. Find setup the reader does not need to see; move it to a named helper or builder. Keep the values that matter to the result inline.
4. Replace assertions on internals with assertions on outputs, state or messages visible to the caller.
5. Replace sleeps, real clocks and random data with injected fakes or fixed values.
6. Run the file alone, then in random or reversed order if the runner supports it.
7. Rename tests so a failure reads as a sentence about behavior.

## Example

```python
# Before: unclear name, hidden data, two ideas, depends on today's date
def test_borrow():
    m = make_member()
    m.fines = 600
    b = Book("x")
    r = lib.borrow(m, b)
    assert r is False
    assert len(lib.loans) == 0
    m.fines = 0
    r = lib.borrow(m, b)
    assert r is True
    assert lib.loans[0].due == date.today() + timedelta(days=14)

# After: two tests, intent visible, time controlled
def test_member_with_fines_above_limit_cannot_borrow(library):
    member = a_member(fines_cents=600)
    assert library.borrow(member, a_book()) is False
    assert library.loans == []

def test_loan_is_due_fourteen_days_after_borrowing(library, clock):
    clock.set(date(2025, 3, 3))
    library.borrow(a_member(), a_book())
    assert library.loans[0].due == date(2025, 3, 17)
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Fragile test | Fails on refactors that preserve behavior; asserts call order or private state | Assert observable behavior; reduce mocks |
| Environment-dependent test | Needs a specific time zone, locale, path or running service | Inject the dependency or make it explicit |
| Order dependence | Passes alone, fails after another test; shared mutable fixtures | Fresh state per test |
| Sleep-based wait | `sleep` in tests | Fake clock or explicit signal; see `$clean-code:concurrency` |
| Mystery guest | Test depends on data defined in a distant fixture | Put the relevant data in the test |
| Assertion roulette | Many unrelated assertions, no messages, one test name | Split by idea |
| Print-and-look | Output inspected by a human | Assert it |
| Copy-paste setup | Same ten setup lines in many tests | Builder or helper with a name |

## Trade-offs and exceptions

- One assertion per test is a preference when it improves clarity; several assertions that describe one concept are fine.
- Integration tests may legitimately use real files, ports or databases; keep them separate from the fast suite and make their requirements explicit.
- Property-based and table-driven tests are clean when each case row is readable and failures name the row.
- Do not rewrite a large untouched test file to satisfy this skill. Improve the tests you add or change.
- Added judgment: tests that pin current behavior of untested legacy code (characterization) may start ugly; the source's rule that tests are production-quality code means they should be cleaned as they are kept.

## Verification

- [ ] Each touched test has one stated idea and a behavior-revealing name.
- [ ] A reader sees the data that matters to the outcome in the test body.
- [ ] No touched test asserts on internals the user cannot observe.
- [ ] Each test passes alone and in any order, without network, wall-clock or machine-specific state.
- [ ] Failure output points at one behavior.

## Related

`$clean-code:tdd-discipline` for when tests must exist; `$clean-code:concurrency` for timing-sensitive tests; `clean-code-test-quality-reviewer` to review a diff; `clean-code-test-writer` to delegate writing.

## Source

- `Tests`
- `TDD and clean test rules`: the rules on small tests, one conceptual assertion, test names and data, helper vocabulary and clean test code.
- `Smells to detect and eliminate`: only the fragile test and environment-dependent test smells.
