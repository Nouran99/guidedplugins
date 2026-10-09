---
name: testing-seams
description: "Use when writing, placing or judging tests for entities, use cases, adapters or boundary contracts, or when business rules can only be tested with a framework, database or network. Covers core-first tests, fakes and adapter tests. What a use case contains is use-cases."
---

# Testing at the seams

Owns where tests sit relative to the architectural seams and what each kind may touch. The style of an individual test (naming, one idea per test) is a `clean-code` plugin concern; the shape of the use case under test is `/clean-architecture:use-cases`; how a port is declared is `/clean-architecture:ports-and-gateways`.

## When to use

- A test of a business rule starts a web server, a database container or an application context.
- You are deciding which tests a new use case, adapter or gateway needs.
- A suite is slow or flaky and the cause is that policy is only tested through real details.
- A test reaches into private internals even though a use-case boundary exists.
- You are asked whether a fake or the real adapter should be used in a given test.

## Rules

1. **Prioritize tests for entities, use cases and boundary contracts.** `[MUST]` Check: the business rules and use cases at risk in the change have a core test that does not involve an adapter; list any that do not.
2. **Run core tests without the real framework, the real database and the network.** `[MUST]` Check: a core test passes with the web framework, driver and network libraries excluded from its dependencies.
3. **Run core tests fast and deterministically.** `[MUST]` Check: no sleeps, wall-clock reads or unseeded randomness; the clock and identifier generators enter as ports or values (`/clean-architecture:ports-and-gateways`).
4. **Test adapters separately.** `[MUST]` Cover mapping correctness, gateway behavior, controller translation, presenter formatting and the integration with the framework or external service. Check: each adapter has tests whose subject is the adapter, not a business rule.
5. **Do not let slow integration tests stand in for tests of the business rules.** `[MUST NOT]` Check: deleting all integration tests would not leave a rule untested.
6. **Test through the supported boundary.** `[MUST]` Avoid reaching private internals when a public use-case boundary exists. Check: the test calls the use case's entry point.
7. **Prefer testing use cases with fakes or mocks for the ports.** `[SHOULD]` Check: ports are supplied by the test; no real client is constructed.
8. **Use integration tests only where architectural seams meet real details.** `[MUST]` Check: each integration test names the seam it exercises (database mapping, HTTP route, queue protocol).
9. **Rewrite tests coupled to the framework to target use cases and entities directly where possible.** `[SHOULD]` The source softens this with "where possible", so it stays a strong default; the cases where it is not possible are the ones rule 10 handles. Check: no business-rule test depends on the framework's application context, or the exception is stated.
10. **When a test needs a volatile detail to verify a rule, move it inward or add a boundary contract.** `[MUST]` Move the test to a use case or entity with a fake, or add a stable boundary contract (compact rules). Check: the rule's test no longer imports an adapter.
11. **Write a shared contract suite for each stateful port.** Added judgment: one set of expectations ("find returns nothing for an unknown id; save then find returns equal data") runs against the in-memory fake and against the real adapter. The fake is then trustworthy, and the adapter test is short. Check: both implementations are in the suite's parameter list.
12. **Use state-based fakes for stores, interaction checks for outbound effects.** Added judgment: a store fake that holds data answers questions the way the real one does; a mailer is checked by asking what it was asked to send. Check: no test asserts the order of internal calls that the behavior does not depend on.

## Procedure

1. List the rules and use cases in the change and the tests that currently cover each.
2. For each test, mark what it needs: framework, database, network, clock, filesystem.
3. For a rule test that needs a detail, restructure: pull the rule into an entity (`/clean-architecture:entities-and-invariants`), supply the ports as fakes, and test through the use case.
4. Add adapter tests per adapter for what only it can get wrong: mapping, queries, translation, formatting.
5. Add a contract suite for any stateful port and run it against both implementations.
6. Keep a small number of integration tests at the seams; run the whole suite.

## Example

```python
# Before: a business rule needs a real database
def test_overdue_fee(postgres_container):
    conn = postgres_container.connect()
    conn.execute("insert into loans values ('L1', 'B1', '2026-01-01')")
    fee = compute_fee(conn, "L1", date(2026, 1, 11))
    assert fee == 100
```

```python
# After: the rule and the use case are tested with fakes
class InMemoryLoans:
    def __init__(self, *loans):
        self._by_id = {loan.loan_id: loan for loan in loans}

    def get(self, loan_id):
        return self._by_id[loan_id]


class FixedClock:
    def __init__(self, today):
        self._today = today

    def today(self):
        return self._today


def test_fee_is_ten_cents_per_day_overdue():
    loans = InMemoryLoans(Loan("L1", book_id="B1", due_on=date(2026, 1, 1)))
    fee = AssessLateFee(loans, FixedClock(date(2026, 1, 11))).execute("L1")
    assert fee.cents == 100        # ten days at ten cents


# adapters/sqlite/test_sqlite_loan_gateway.py: separate test, only mapping and queries
def test_gateway_round_trips_a_loan(tmp_path):
    gateway = SqliteLoanGateway(open_database(tmp_path / "loans.db"))
    gateway.add(Loan("L1", book_id="B1", due_on=date(2026, 1, 1)))
    assert gateway.get("L1") == Loan("L1", book_id="B1", due_on=date(2026, 1, 1))
```

The rule is checked in microseconds with no database. The gateway test still proves the mapping against a real file. If `InMemoryLoans` and `SqliteLoanGateway` also run the same contract suite, the fake can be trusted.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Rule tested through a container | A rule test that needs a database, broker or web server | Test the use case with a fake port |
| Integration-only suite | Business behavior covered only by end-to-end tests | Add core tests; trim the integration tests |
| Private-internals test | A test calling a private helper or reaching into state | Test through the use-case entry point |
| Framework-coupled test | A rule test that boots the application context | Rewrite to call the use case directly |
| Time bomb | Wall-clock or random inputs in a core test | Inject a clock or id generator |
| Untested adapter | Mapping, queries or presenters with no tests of their own | Add adapter tests |
| Mock choreography | Assertions on the order and count of internal calls | Assert on outcomes and observable effects |

## Trade-offs and exceptions

- The source asks for integration tests "where architectural seams meet real details", so do not delete them to chase speed. Added judgment: keep the pyramid, with many core tests, fewer adapter tests and a few integration tests; the source gives the order of priority but no proportions.
- Fakes or mocks are both acceptable for ports; pick by what the port is. A hand-written fake that behaves like the real store costs effort but survives refactors.
- When the project already has an end-to-end harness, keep it for the paths it protects; add core tests beside it rather than replacing it.
- Without a runnable test command, say so; do not report green results you did not see.

## Verification

- [ ] Every business rule at risk in the change has a test that needs no framework, database or network.
- [ ] Core tests are fast and deterministic, with time and ids injected.
- [ ] Each adapter has its own tests for mapping, queries, translation or formatting.
- [ ] Integration tests exist only at named seams.
- [ ] No test calls private internals when a use-case entry point exists.
- [ ] Stateful ports share a contract suite across fake and real implementations.

## Related

`/clean-architecture:use-cases` for what is under test; `/clean-architecture:persistence-independence` for gateways; `clean-architecture:test-seam-reviewer` to review where tests sit; `clean-architecture:seam-test-writer` to delegate writing them.

## Source

- `Testing Rules`
- `Core Tests First`
- `Adapter Tests`
- `Test Through Supported Boundaries`
- `Refactoring Rules`: only the rule on eliminating framework coupling from tests.
- `Services, Distribution, and Embedded Boundaries`: only the rule that policy is testable without the target device.
