---
name: "enterprise-patterns-testing-by-responsibility"
description: "Use when writing or placing tests for enterprise code: a business rule tested only through HTTP or a database, mappers or repositories mocked away, transaction or locking behavior untested, remote mapping uncovered, or a real remote service needed to run tests."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Testing by responsibility

Decides at which layer each behavior is tested, so that every test sits with the responsibility that owns the behavior. How to write a good individual test is a testing plugin's subject, not this book's.

## When to use

- A pricing or eligibility rule can only be exercised through a web request or a seeded database.
- Repository, mapper or gateway code is tested with mocks that merely repeat the code.
- A service's commit, rollback or call order is not tested.
- Locking, version checks or conflict paths have no test.
- DTO or facade mapping changes without any test noticing.
- Tests need a live external service.

## Rules

1. **Test each behavior at the level that owns it.** Compact checklist (from `mini.md`): the question for every test is which responsibility owns the behavior being checked. A test at the wrong level is slow, brittle and does not point at the cause. Check: no business-rule assertion needs an HTTP client or a database.
2. **Test domain logic independently from presentation and persistence when possible.** Domain logic that needs a database to test has coupled itself to persistence. Check: domain tests construct objects and call methods, with no framework, request or connection.
3. **Test repositories, mappers and gateways separately as data-access infrastructure.** Mocks of the data layer only restate the code, while the real engine is where it can be wrong. Check: they have their own tests for round trips, queries and constraints, and those tests run against the storage engine the code targets or a faithful local equivalent (the second half is Added judgment).
4. **Test service and application workflows for transaction and orchestration behavior.** Atomicity and ordering bugs appear only when a step fails. Check: tests prove the unit of work commits once, that a late failure leaves nothing partially saved, and that outbound calls happen after commit when that is the design.
5. **Test concurrency behaviors where optimistic or pessimistic locking matters.** Lost updates appear only when two edits interleave. Check: a test interleaves two edits and asserts the designed outcome.
6. **Test DTO and remote facade mapping at the boundaries.** Contracts break silently when a mapping changes. Check: assemblers are tested in both directions, and the shape of the contract is asserted.
7. **Use a Service Stub to test or run without a real remote service.** Tests must be able to run without a network. Check: each gateway interface has an in-memory stub, and translation code is also tested with recorded sample payloads.
8. **Read a wrongly placed test as a design signal.** Added judgment: if a rule can be tested only through the web layer, it probably lives in the web layer; fix the placement, then the test. Difficulty placing a test is information about the design.
9. **Keep the slow tests few and aimed.** Added judgment: a handful of tests that exercise a use case end to end through real components is enough to confirm the wiring; the rules are covered below it. A few end-to-end tests confirm wiring, while many make suites slow and vague.
10. **Test presentation by what it translates.** Added judgment: a handler test checks that input becomes the right application call and that outcomes become the right response, not that business rules hold. A handler's value is translation.

## Procedure

1. List the behaviors in the change: rules, data access, workflow, locking, boundary mappings, presentation translation.
2. Assign each to a responsibility and a test level using the rules.
3. Write or move the tests so each behavior is checked once at its owner; delete the duplicate high-level assertion once the lower one exists.
4. Provide stubs for remote gateways and fakes for persistence at workflow level; keep a real-engine test for the data-access layer.
5. Add the failure-injection test for each transaction and the interleaved-edit test for each lock.
6. Run the suites from fast to slow.

## Example

```python
# Wrong level: a pricing rule reachable only through the web layer and a seeded database
def test_free_shipping_over_http(client, db):
    seed_orders(db, user="u1", count=11)
    response = client.get("/cart?user=u1&total=20000")
    assert response.json()["freeShipping"] is True

# Right level 1: the rule is a pure function; no web, no database
def qualifies_for_free_shipping(previous_orders: int, cart_total_cents: int) -> bool:
    return previous_orders > 10 and cart_total_cents > 10_000

def test_free_shipping_needs_more_than_ten_orders_and_over_100_dollars():
    assert qualifies_for_free_shipping(previous_orders=11, cart_total_cents=10_001)
    assert not qualifies_for_free_shipping(previous_orders=10, cart_total_cents=20_000)
    assert not qualifies_for_free_shipping(previous_orders=11, cart_total_cents=10_000)

# Right level 2: the workflow commits once and notifies only after the commit
class RecordingUnitOfWork:
    def __init__(self, events): self.events = events
    def commit(self): self.events.append("commit")

class RecordingNotifier:
    def __init__(self, events): self.events = events
    def order_confirmed(self, order_id): self.events.append(f"notify:{order_id}")

def confirm_order(orders, uow, notifier, order_id):
    orders[order_id]["status"] = "confirmed"
    uow.commit()
    notifier.order_confirmed(order_id)

def test_confirm_order_commits_then_notifies():
    events = []
    confirm_order({"o1": {"status": "draft"}}, RecordingUnitOfWork(events), RecordingNotifier(events), "o1")
    assert events == ["commit", "notify:o1"]
```

The first test is not wrong because it uses HTTP; it is wrong as the only place the rule is checked. Mapper, lock and DTO tests follow the same logic and have examples in `enterprise-patterns-data-mapper`, `enterprise-patterns-offline-locking` and `enterprise-patterns-remote-boundaries`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Rule tested via UI | Business assertions need a client or a browser | Test the rule on the domain object; keep one wiring test |
| Mocked-away persistence | Mapper tests assert that SQL strings were passed | Test against a real engine or faithful substitute |
| Untested workflow | No test for rollback or call order | Failure-injection and ordering tests |
| Untested lock | Version column with no conflict test | Interleaved-edit test |
| Live-service tests | Tests call real partners | Service Stub plus sample payloads |
| Pyramid inverted | Mostly end-to-end tests, few unit tests | Move assertions down to the owner |

## Trade-offs and exceptions

- "When possible" in the source matters: some legacy code cannot be tested at its owning level without restructuring. State that, test at the level you can, and plan the move (`legacy-code` covers getting such code under test).
- Trivial pass-through code does not need its own test at every level.
- Mapping tests against a real database are slower; a small number of focused ones is the intended cost.
- Test style, naming and structure are covered by a clean-code or testing plugin, not here.

## Verification

- [ ] Every behavior in the change is checked at the level that owns it.
- [ ] No business-rule test needs HTTP or a database.
- [ ] Data-access classes have their own tests.
- [ ] Workflows have commit, rollback and ordering tests.
- [ ] Locks have interleaved-edit tests.
- [ ] Boundary mappings and gateway stubs are tested.

## Related

`enterprise-patterns-test-alignment-reviewer` to review test placement; `enterprise-patterns-test-writer` to write tests at the right level; `enterprise-patterns-transactions-and-unit-of-work` and `enterprise-patterns-offline-locking` for the behaviors under test.

## Source

- `Testing Rules`
- `Session State and Base Pattern Index`: only the Service Stub entry.
