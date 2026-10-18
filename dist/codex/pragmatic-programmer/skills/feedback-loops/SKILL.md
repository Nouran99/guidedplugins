---
name: "feedback-loops"
description: "Use when tests or checks are slow, flaky, environment-dependent or run too late, when failures are hard to see, or before declaring work done. Covers the speed and visibility of the signal. Which tests a change needs is `$pragmatic-programmer:test-portfolio`; scripting repeated manual steps is `$pragmatic-programmer:automation`."
---

# Feedback loops

Shorten the time between a change and the signal about it, and make that signal impossible to miss. This skill is about how quickly and how clearly checks speak. Which behaviors and failure modes deserve a test at all is `$pragmatic-programmer:test-portfolio`; scripts for repeated manual work are `$pragmatic-programmer:automation`.

## When to use

- A check takes long enough that people stop running it, or it runs only in CI at the end.
- A test fails intermittently, depends on the network, the clock or a shared environment, or needs a large unrelated setup.
- A failure message does not point at the cause, or the failure is easy to overlook.
- You are about to say the work is done and have run no tests, or only a narrow one.

## Rules

1. **Shorten the time between change and feedback.** [MUST] Check: after an edit, the narrowest relevant check runs in seconds, not minutes.
2. **Run relevant tests early and often.** [MUST] Check: you ran the narrowest relevant test after each edit and a broader set before calling the work done.
3. **Use automated checks where they reduce real risk.** [MUST] Check: each check you add or keep catches a failure that has happened or plausibly will; a check that never fails and costs minutes is a candidate to cut.
4. **Make failure visible fast.** [MUST] Check: the first failure stops the run or is reported first, and the output names what failed without reading a log.
5. **Prefer a cheap early signal over a late expensive surprise.** [SHOULD] Check: type checks, linting and unit tests run before integration and end-to-end checks.
6. **Keep tests runnable quickly and often.** [MUST] Check: the default test command finishes fast enough that you run it without deciding to.
7. **Keep flaky and environment-dependent tests out of the critical feedback path where possible.** [MUST] The qualifier "where possible" is the source's and stays. Check: such tests are in a separate, named group and the fast path does not depend on them.
8. **When tests are slow, flaky, environment-dependent or need excessive unrelated setup, improve the feedback path instead of normalizing skipped checks.** [Compact checklist] Check: nobody's workaround is "skip it locally".
9. **Run the relevant automatic tests before calling the change done.** [Compact checklist] Check: the report names the command and its result, or says none could be run and why.
10. **Order checks by cost.** [Added judgment] Cheapest first, so a typo does not wait behind a ten-minute suite. Check: the pipeline fails on lint before it starts the slow stages.
11. **Do not hide feedback.** [Added judgment] Retrying until green, swallowing errors in a test, widening an assertion until it passes and muting a test are all ways of turning the signal off. Check: no change in the diff makes a check pass without changing what it checks.
12. **Make the failure message point at the cause.** [Added judgment] Check: an assertion states expected and actual values and the operation it was checking.

## Procedure

1. Find the project's test and check commands (`package.json`, `Makefile`, `pyproject.toml`, `go.mod`, CI files).
2. Pick the narrowest command that covers the change and run it after each edit.
3. Note how long it takes and how it reports failure. If slow or flaky, find the cause: real waiting, network, the clock, shared state, large fixtures.
4. Fix the cause where it is cheap: replace a sleep with a controllable clock or a fake, replace a network call with a fake in the fast path, split the slow group into its own command.
5. Before declaring done, run the broader set and report the commands and results.

## Example

```python
# Before: in the fast unit suite. It waits two seconds for a worker and calls a real mail sandbox over the network.
def test_welcome_email_sent():
    client.post("/signup", json={"email": "a@example.com"})
    time.sleep(2)
    assert mail_sandbox.inbox("a@example.com")     # intermittently empty on a slow CI day

# After: the fast path checks the behavior this code owns, deterministically and in milliseconds
def test_signup_enqueues_welcome_email(fake_queue):
    client.post("/signup", json={"email": "a@example.com"})
    assert fake_queue.messages == [("welcome_email", "a@example.com")]

# The real delivery check is kept, but outside the fast loop and named for what it needs
@pytest.mark.integration
def test_welcome_email_delivered_through_sandbox():
    client.post("/signup", json={"email": "a@example.com"})
    assert wait_until(lambda: mail_sandbox.inbox("a@example.com"), timeout_s=30)
```

Day to day the fast command is `pytest -m "not integration"`; CI also runs `pytest -m integration`. The flaky dependency no longer decides whether a change looks safe, and the integration test still exists.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Sleep as synchronization | `sleep(n)` in a test | A controllable clock, a fake, or a wait with a condition and a timeout |
| Unit test on the network | A fast-suite test that needs credentials or connectivity | Fake it in the fast path; keep one integration test |
| Skip as a workaround | `skip`, `xfail` or a muted job added "for now" | Fix the cause, or record the removal condition |
| Late-only check | A check that runs only in CI at the end | Add a local command that runs it earlier |
| Retry until green | Automatic reruns of failed tests | Find the flakiness |
| Opaque failure | `assert result` with no message on a complex value | State expected and actual |

## Trade-offs and exceptions

- Some feedback is inherently slow: a full end-to-end run or a load test. Keep it, run it where it fits (CI, nightly), and give the fast path its own signal.
- Fast tests that check nothing are not feedback. The source ties tests to the contract they protect (`$pragmatic-programmer:test-portfolio`).
- Isolating a flaky test is a containment, not a fix; give it a removal condition (`$pragmatic-programmer:broken-windows`).
- If you cannot run the tests in this environment, say so. Never report a result you did not see.

## Verification

- [ ] The narrowest relevant check ran after the edit, with its command and result recorded.
- [ ] The broader set ran before the work was called done, or the report says it could not.
- [ ] No flaky or network-dependent test sits in the default fast command.
- [ ] No check was skipped, muted or retried to get a pass.
- [ ] Each failure names what failed and what was expected.

## Related

`$pragmatic-programmer:test-portfolio` for which tests exist; `pragmatic-programmer-feedback-loop-reviewer` to review a diff; `$pragmatic-programmer:automation` to script the commands; `$pragmatic-programmer:fix` for the run-tests-after-each-change loop.

## Source

- `Feedback Loop Rules`
- `Testing Rules`: only the rules on quick, frequent test runs and keeping flaky or environment-dependent tests out of the critical feedback path.
