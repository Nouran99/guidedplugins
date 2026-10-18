---
name: "entities"
description: "Use when designing or reviewing a class that has identity and a life cycle: status fields, setters, state transitions, or an ORM-mapped class with no behavior. Covers identity, transitions and domain verbs. Outside access is aggregate-root-discipline; attribute-defined types are value-objects."
---

# Entities

Owns one entity: it has an identity that outlives its attributes, it moves through a life cycle, and its methods are the legal moves. It does not decide who outside may call those methods (`$ddd-implementing:aggregate-root-discipline`), what size the aggregate is (`$ddd-implementing:aggregate-boundaries`) or how attribute-defined types are built (`$ddd-implementing:value-objects`).

## When to use

- A class has a `status` or `state` field that callers assign.
- Business verbs (`approve`, `cancel`, `renew`) exist only as `if` chains in a service, while the class holds data.
- A class is only a mapped row: fields, getters, setters, no rules.
- You need to decide whether a concept is an entity or a value.
- A transition is allowed from the UI but should be impossible in the domain.

## Rules

1. **[MUST] Use an entity where identity and life cycle matter.** The object is the same one after its attributes change. Check: you can state what makes two instances the same thing (an identifier), and what happens to it over time; if neither holds, it is a value (`$ddd-implementing:value-objects`).
2. **[MUST] Make entities protect meaningful state transitions.** A transition table the code does not enforce is only documentation. Check: every allowed transition is a method, and every disallowed one raises inside that method.
3. **[MUST] Express domain behavior in entity methods, not generic state changes.** `loan.renew(today)` says what happened; `loan.setDueOn(date)` leaves the rule to the caller. Check: method names are business verbs from the ubiquitous language (`$ddd-implementing:ubiquitous-language`), not `set`, `update` or `change`.
4. **[MUST NOT] Leave entities as passive ORM containers in behavior-rich domains.** Check: for the entity's rules (not for plain data), a test runs against the entity itself without a database or a service.
5. **[MUST] Test valid and invalid state transitions.** Check: for each transition there is a test that it works from the right state and a test that it is rejected from each wrong state (`$ddd-implementing:domain-tests`).
6. **[Added judgment] Give the entity its identity at creation.** An identifier assigned by the domain or a generator before the first save means events, tests and references can use it from the start; an identifier that only exists after the insert makes the first minutes of the life cycle special. Check: constructors and factories take or generate the identity.
7. **[Added judgment] Compare entities by identity only.** Equality and hashing built on mutable attributes break in sets and maps. Check: `equals`/`hashCode` (or the language equivalent) use only the identifier.
8. **[Added judgment] Model the life cycle explicitly.** A small state type and a table of allowed moves make illegal states unrepresentable and give the tests their cases. Check: the allowed transitions can be listed from one place in the code.
9. **[Added judgment] Make construction produce a valid first state.** "Create empty, then fill with setters" lets an invalid entity exist. Check: after construction, every invariant of the first state holds.

## Procedure

1. List the states the business names and the moves between them. Ask which moves have preconditions.
2. Replace the state field's public setter with one method per move, named in the business's verb; put the precondition check inside.
3. Have each method return what the caller needs (an event or a result) instead of making the caller read the state back (`$ddd-implementing:domain-events`).
4. Remove setters that nothing needs; keep persistence access (reflection, mapper) out of the public surface.
5. Write the transition tests: allowed from each valid state, rejected from each other.
6. Move the `if (status == ...)` rules out of services into the methods (`ddd-implementing-root-encapsulator` for a larger job). Run all tests after each move.

## Example

```python
# Before: a mapped row; the service owns the rules
class Loan:
    def __init__(self):
        self.id = None
        self.status = "OPEN"
        self.due_on = None
        self.returned_on = None

def return_copy(loan, today):
    if loan.status == "RETURNED":
        raise ValueError("already returned")
    loan.status = "RETURNED"
    loan.returned_on = today

# After: the entity owns identity, life cycle and verbs
from datetime import date
from enum import Enum

class LoanState(Enum):
    OPEN = "open"
    RETURNED = "returned"

class Loan:
    def __init__(self, loan_id: "LoanId", member_id: "MemberId", copy_id: "CopyId", due_on: date):
        self._id, self._member_id, self._copy_id = loan_id, member_id, copy_id
        self._due_on = due_on
        self._state = LoanState.OPEN
        self._returned_on: date | None = None

    @property
    def id(self) -> "LoanId":
        return self._id

    def return_copy(self, on: date) -> "CopyReturned":
        if self._state is LoanState.RETURNED:
            raise LoanAlreadyReturned(self._id)
        self._state = LoanState.RETURNED
        self._returned_on = on
        return CopyReturned(self._id, self._copy_id, on)

    def __eq__(self, other: object) -> bool:
        return isinstance(other, Loan) and other._id == self._id

    def __hash__(self) -> int:
        return hash(self._id)
```

The test `returning_an_already_returned_loan_is_rejected` runs on `Loan` alone, with no database.

## Anti-patterns

- **Row with getters and setters.** Detect: a class with only accessors, mapped to a table, with rules in `*Service` classes.
- **Status assignment.** Detect: `entity.status = ...` or `setStatus(...)` anywhere outside the entity.
- **Generic change methods.** Detect: `update(...)`, `change(...)` or `apply(dto)` that copies a request's fields onto the entity.
- **Mutable-attribute equality.** Detect: `equals` that compares fields other than the identifier.
- **Create-then-fill.** Detect: a no-argument constructor followed by a series of setters in calling code.

## Trade-offs and exceptions

- The source ties the "no passive container" rule to behavior-rich domains. A plain reference-data row in a CRUD area may stay a data class (`$ddd-implementing:core-domain-focus`).
- Frameworks may require a no-argument constructor or field access. Keep that in the persistence mapping and do not widen the public surface because of it.
- Some transitions are legitimately free (a note can always be edited). Not every field needs a verb; only fields that take part in a rule do.
- Whether the entity is also an aggregate root is a boundary question for `$ddd-implementing:aggregate-boundaries`.

## Verification

- [ ] Every state change in the touched code goes through a named business method.
- [ ] Each method rejects the transitions its rule forbids, with a test for each.
- [ ] No public setter exists for a field that takes part in a rule.
- [ ] Equality uses the identifier only.
- [ ] A new instance is valid from construction.
- [ ] Rules that were in a service now run in the entity, and the tests pass.

## Related

`$ddd-implementing:aggregate-root-discipline` for outside access; `$ddd-implementing:value-objects` for identity-less types; `$ddd-implementing:domain-tests` for transition tests; `ddd-implementing-root-discipline-reviewer` to review a diff; `ddd-implementing-root-encapsulator` to move rules into the model.

## Source

- `Entity and Value Object Rules`: only the Entities subsection.
- `Entities`
- `Testing Rules`: only the rule to test valid and invalid state transitions.
