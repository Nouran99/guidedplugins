---
name: "ddd-implementing-domain-tests"
description: "Use when writing or reviewing tests of domain code: aggregate invariants, state transitions, value objects, domain events, repositories, translators and application services. Says what each layer's test asserts and what it leaves out."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Domain tests

Owns the content of tests for a DDD codebase, layer by layer: what each asserts, what it must not need, and what belongs to a neighboring layer's test. Finding missing tests in a diff is `ddd-implementing-test-coverage-reviewer`; writing them is `ddd-implementing-domain-test-writer`.

## When to use

- You add or change an invariant, a state transition, a value type, an event, a repository, a translator or a use case.
- A domain test needs a database, a container or a web framework to run.
- A service test lists every business rule combination.
- A bug fix touched domain behavior without a test.
- A test name describes mechanics ("sets status to 2") instead of behavior.

## Rules

1. **[MUST] Test aggregate invariants directly.** The invariant is the aggregate's reason to exist. Check: each written invariant has a test on the aggregate root, constructed without a repository or framework.
2. **[MUST] Test valid and invalid state transitions.** Check: for each transition, a test from every state where it is allowed and one from every state where it is rejected, asserting the rejection type.
3. **[MUST] Test value object validation and behavior.** Check: accepted values, each rejected case, equality, and each operation (`ddd-implementing-value-objects`).
4. **[MUST] Test domain events as outcomes of domain behavior.** Check: the test performs the behavior and asserts the event (or no event) that results (`ddd-implementing-domain-events`).
5. **[MUST] Test repositories as infrastructure, separately from aggregate rules.** Check: repository tests check round-trip persistence of an aggregate with a real or equivalent store; they do not re-test the aggregate's rules (`ddd-implementing-repositories`).
6. **[MUST] Test anticorruption and translation layers explicitly.** Check: one test per mapped foreign value, per unknown value and per malformed input (`ddd-implementing-anticorruption-layer`).
7. **[MUST] Test application services for orchestration, not for all domain decisions.** Check: the test asserts load, call, save, publish, with fakes for ports, and has no rule matrix (`ddd-implementing-application-services`).
8. **[MUST] Use the ubiquitous language in tests.** Tests, events, commands, repositories and services all speak the same language. Check: test names read as business sentences (`ddd-implementing-ubiquitous-language`).
9. **[Added judgment] Keep aggregate, value and domain-service tests free of infrastructure.** No database, network, clock or framework. Check: they run in milliseconds in a plain unit-test process, with time passed in as a value.
10. **[Added judgment] Assert the events, not only the state.** A rejected call should leave the state unchanged and produce no event. Check: transition tests also check that no event came out of a rejection (with behavior that returns events, the raise is the proof; with behavior that records events, assert the recorded list is empty). Use one convention per codebase.
11. **[Added judgment] Prefer one failing reason per test.** A test named for one rule fails for that rule only. Check: no test asserts two unrelated invariants.

## Procedure

1. Name the layer of the change: aggregate, value, event, repository, translator, application service.
2. Write the test for that layer from the rules above, naming it as a business sentence.
3. For an aggregate, list its invariants and transitions and write one test per rule and per illegal move.
4. For a value, list accepted, rejected and equal pairs.
5. For an application service, build fakes for the ports that record their calls in one journal, assert the order (`load`, `save`, `publish`) and the event that results from the domain call; do not add rule cases.
6. Run the new tests first to see them fail for the right reason (or pass, for characterization), then run the suite.
7. Move any rule assertion found in a service or repository test down to the model's test.

## Example

```python
import pytest
from datetime import date

# aggregate invariant and transition, no database
def test_renewing_an_open_loan_extends_the_due_date_and_records_loan_renewed():
    loan = a_loan(due_on=date(2026, 3, 1), renewals=0)

    event = loan.renew(today=date(2026, 3, 1), copy_is_reserved=False)

    assert loan.due_on == date(2026, 3, 15)
    assert event == LoanRenewed(loan.id, new_due_on=date(2026, 3, 15))

def test_renewing_a_reserved_copy_is_rejected_and_records_nothing():
    loan = a_loan(due_on=date(2026, 3, 1), renewals=0)

    with pytest.raises(CopyIsReserved):
        loan.renew(today=date(2026, 3, 1), copy_is_reserved=True)

    assert loan.due_on == date(2026, 3, 1)      # unchanged; the call raised, so it returned no event

# value object
def test_a_stay_ends_after_it_starts():
    with pytest.raises(InvalidStayPeriod):
        StayPeriod(check_in=date(2026, 5, 3), check_out=date(2026, 5, 3))

# application service: orchestration only, with fakes that share one call journal
def test_renew_loan_loads_saves_then_publishes_loan_renewed():
    calls = []
    loans = FakeLoanRepository(a_loan(loan_id="L-1"), journal=calls)   # appends "load", "save"
    bus = RecordingBus(journal=calls)                                   # appends "publish"

    RenewLoan(loans, AlwaysFree(), FixedClock(date(2026, 3, 1)), bus).execute("L-1")

    assert calls == ["load", "save", "publish"]
    assert [type(e) for e in bus.published] == [LoanRenewed]
```

The rule about reserved copies is tested once, on `Loan`; the service test never mentions it.

## Anti-patterns

- **Infrastructure in a domain test.** A test that starts a database to check an invariant. Detect: container or ORM setup in aggregate tests.
- **Rule matrix in the service test.** Twenty branches tested through the application service. Detect: parametrized rule cases in a test that uses fakes for ports.
- **Mechanical names.** Test names about fields and codes. Detect: "sets status", "returns 2".
- **Repository re-testing rules.** Detect: repository tests that assert business outcomes.
- **State-only assertion.** Detect: a rejection test with no check of events or unchanged state.
- **Mock-heavy aggregate tests.** Detect: mocks of the aggregate's own children.

## Trade-offs and exceptions

- A repository test needs a real or compatible store; that is the point of testing infrastructure separately. The rule is not "avoid databases" but "do not need one to test rules".
- In an event-sourced aggregate, tests take the form given events, when command, then events (`ddd-implementing-event-sourcing`).
- A translator test may use recorded foreign payloads; it should not call live external systems. Added judgment.
- Tests for areas that stay plain CRUD can be thin integration tests; the layering above applies to modeled areas.

## Verification

- [ ] Every invariant in the change has a root-level test.
- [ ] Each transition is tested from allowed and from rejected states.
- [ ] Each value type has validation, equality and operation tests.
- [ ] Events are asserted as outcomes, including the "no event on rejection" case.
- [ ] Repository, translator and service tests stay within their own concerns.
- [ ] Test names use the context's language.

## Related

`ddd-implementing-entities`, `ddd-implementing-value-objects` and `ddd-implementing-aggregate-boundaries` for the rules under test; `ddd-implementing-test-coverage-reviewer` to find gaps; `ddd-implementing-domain-test-writer` to write them.

## Source

- `Testing Rules`
- `Ubiquitous Language Rules`: only the rule that tests speak the same language as the model.
