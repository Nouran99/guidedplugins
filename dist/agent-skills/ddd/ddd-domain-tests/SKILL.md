---
name: "ddd-domain-tests"
description: "Use when writing, reviewing or ordering tests for domain behavior: invariants, allowed and forbidden transitions, invalid construction, specifications, application orchestration, and translations at context boundaries. Tests of the model; infrastructure tests stay separate."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Domain tests

Owns what tests of the model contain and what they are named: they read in the ubiquitous language, prove valid behavior and block invalid states, and stay apart from infrastructure tests. Documents and diagrams as living documentation are in `ddd-model-driven-design`; writing a missing test is delegated to `ddd-domain-test-writer`.

## When to use

- You change an invariant, a lifecycle transition, a specification, an orchestration step or a context translation.
- A test is named after an endpoint, a table or a message queue instead of a business situation.
- Tests cover getters and mappers while the core policy has none.
- A domain test needs a database, a container or a network.
- You must decide which tests to write first for new model code.

## Rules

1. **Tests must read in the ubiquitous language.** Names and setup use domain words, so the test can be read to an expert. Check: replace code with its names and the test reads as a sentence.
2. **Tests must verify allowed and forbidden state transitions.** Check: for each transition there is a test that it works and a test that the wrong source state is rejected.
3. **Tests must verify that invalid objects cannot be created through supported paths.** Check: each construction rule has a rejecting test through the factory or constructor.
4. **Tests must verify translation behavior where anticorruption layers exist.** Check: each foreign-to-local mapping, including unknown values, has a test.
5. **Infrastructure tests must stay separate from domain tests.** Check: domain tests import no database, queue or HTTP library (`ddd-infrastructure`).
6. **Tests for the core domain should read like executable examples of the model.** Check: the core's tests tell scenarios about business situations.
7. **Test context boundaries so translations preserve the intended meaning, and test that one context does not silently break another context's assumptions.** Check: a boundary test exists for each integration (`ddd-context-relationships`).
8. **Prioritize tests for entity invariants, value-object validity, aggregate behavior, domain services, specifications and explicit constraints, application-layer orchestration, and context translation.** Check: new model code is covered in roughly that order before generic checks.
9. **Prefer executable examples and scenario tests over disconnected documentation.** Check: a documented rule has a test that would fail if it stopped being true.
10. **Do not name tests in transport or delivery vocabulary, verify persistence details instead of domain meaning, omit tests for invalid transitions and invariant protection, or test generic plumbing while core policy goes untested.** Check: scan test names for `controller`, `endpoint`, `table`, `payload`.
11. **Added judgment:** treat the absence of a rejecting test for a stated invariant as a missing test, not as a passing suite.

## Procedure

1. List the rules the change touches: invariants, transitions, creation rules, specifications, translations.
2. For each, write the situation in a sentence of domain words. That sentence is the test name.
3. Write a positive test and a negative test per rule. Keep setup in domain terms with small builder functions.
4. Use in-memory repositories and fakes for collaborators the model owns (`ddd-repositories`); keep real infrastructure for separate tests.
5. For each translation, test known values, unknown values and the direction of mapping.
6. Run the suite; confirm domain tests pass without any infrastructure available.

## Example

```python
import unittest
from datetime import datetime

from rental import Rental, RentalError


def a_rental_due(day: int) -> Rental:
    return Rental("r-1", "drill-42", due_at=datetime(2026, 5, day, 17))


class RentalLifecycleTest(unittest.TestCase):
    def test_a_reserved_rental_can_be_picked_up(self):
        rental = a_rental_due(3)
        rental.pick_up(datetime(2026, 5, 1, 9))
        self.assertFalse(rental.is_overdue(datetime(2026, 5, 2)))

    def test_a_rental_that_is_out_cannot_be_picked_up_again(self):
        rental = a_rental_due(3)
        rental.pick_up(datetime(2026, 5, 1, 9))
        with self.assertRaises(RentalError):
            rental.pick_up(datetime(2026, 5, 1, 10))

    def test_equipment_cannot_come_back_before_it_went_out(self):
        rental = a_rental_due(3)
        rental.pick_up(datetime(2026, 5, 2, 9))
        with self.assertRaises(RentalError):
            rental.return_equipment(datetime(2026, 5, 1, 9))

    def test_a_rental_that_is_out_past_its_due_time_is_overdue(self):
        rental = a_rental_due(3)
        rental.pick_up(datetime(2026, 5, 1, 9))
        self.assertTrue(rental.is_overdue(datetime(2026, 5, 4)))

    def test_a_returned_rental_is_never_overdue(self):
        rental = a_rental_due(3)
        rental.pick_up(datetime(2026, 5, 1, 9))
        rental.return_equipment(datetime(2026, 5, 4, 8))
        self.assertFalse(rental.is_overdue(datetime(2026, 5, 9)))
```

The test names are sentences about rentals. Nothing here imports a database. The `Rental` class is the entity from `ddd-entities`.

## Anti-patterns

- **Delivery vocabulary.** Detect: test names such as `test_post_returns_201` for a domain rule.
- **Persistence-detail test.** Detect: assertions about column values or SQL where the rule is about meaning.
- **Happy-path-only suite.** Detect: no test that expects an error for an invariant.
- **Plumbing-heavy suite.** Detect: many tests of mappers, serializers or wiring; none for the core policy.
- **Infrastructure in the domain test.** Detect: a fixture that starts a database to test a business rule.

## Trade-offs and exceptions

- Application-layer orchestration is on the source's list of test priorities. Added judgment: such tests may use a fake repository; they are still domain-language tests as long as they assert business outcomes.
- Added judgment: translation tests sit at the edge of the model and may touch serialization formats; keep them free of real network and storage.
- Tests that pin a persistence mapping are valuable, but they belong with infrastructure tests (`ddd-infrastructure`), not in the domain suite.

## Verification

- [ ] Each test name is a business sentence.
- [ ] Every touched transition has an allowed and a forbidden case.
- [ ] Every construction rule has a rejecting test.
- [ ] Every translation has tests for known and unknown values.
- [ ] The domain suite runs with no infrastructure.

## Related

`ddd-model-driven-design` for tests as living documentation; `ddd-entities` and `ddd-value-objects` for what is under test; `ddd-domain-test-reviewer` to review tests; `ddd-domain-test-writer` to write them.

## Source

- `Testing Rules`
- `Communication Artifacts`: only the rule to prefer executable examples and scenario tests as living documentation.
