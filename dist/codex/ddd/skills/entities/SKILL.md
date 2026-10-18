---
name: "entities"
description: "Use when an object has identity and a lifecycle, when setters or public fields let callers edit state, or when it lacks methods for its valid transitions. The entity class itself; for rules in controllers or jobs use $ddd:layers, for values $ddd:value-objects, for cross-object rules $ddd:aggregates."
---

# Entities

Owns objects distinguished by "which one" rather than "what value": explicit stable identity, a lifecycle, protected transitions and intention-revealing behavior. Objects defined only by attributes are `$ddd:value-objects`; consistency across several objects is `$ddd:aggregates`; moving existing rules into an entity is done by `ddd-behavior-mover`.

## When to use

- Identity matters over time: the same thing persists while its attributes change.
- A lifecycle exists (reserved, active, closed) and rules depend on which state the thing is in.
- Business rules depend on "which one", for example which rental, which claim.
- An entity class is a bag of fields with setters, and services or handlers decide what may change.
- Application code writes `entity.status = ...` or edits several fields in a row.

## Rules

1. **Entities must have explicit identity**, and identity stays stable and explicit. Check: an identifier exists as a named field or type, is assigned at creation and never reassigned.
2. **Entities must protect their own valid state transitions.** Check: invalid transitions fail inside the entity with an error that names the rule.
3. **Entities must expose intention-revealing behavior, not arbitrary state changes.** Check: public methods are business verbs (`pickUp`, `approve`), not `setStatus`.
4. **Prefer methods that tell an entity which domain action to perform.** Changing a destination or adding an event to a history is a model operation, not a procedural edit of fields. Check: callers say what happened, not which fields to overwrite.
5. **Hide direct state changes behind methods that encode domain meaning.** Check: fields are private or read-only to callers.
6. **Entities must not be treated as passive records in behavior-rich domains.** Check: the rules about the entity's own data are in the entity.
7. **Do not add public setters for every field.** Check: setters, if any, exist for a stated reason and still validate.
8. **Do not let application services manually edit all entity state, and do not let UI or application code decide which transitions are valid.** Check: removing the application service would leave the transitions enforced.
9. **Do not use entities only as persistence shells.** Check: methods exist that the database layer does not call.
10. **Added judgment:** define equality on identity, not on attributes. That follows from the rule that "which one" is what distinguishes an entity. Check: two instances with the same identifier compare equal even if other fields differ.

## Procedure

1. List the entity's fields and who assigns each. Mark fields written from outside the class.
2. For each outside write, ask what business event it represents and name it as a verb in the experts' words (`$ddd:ubiquitous-language`).
3. Create the method on the entity with the checks for the transition. Move the conditions from callers into it.
4. Make the fields private; remove setters whose only caller was the code you just replaced.
5. Add tests for each allowed transition and each forbidden one (`$ddd:domain-tests`).
6. Keep the identity assignment explicit; if the persistence layer generates it, make the entity's use of it explicit too (`$ddd:infrastructure`).

## Example

```python
# Before: a record that callers edit
rental.status = "RETURNED"
rental.returned_at = now

# After: the entity owns its lifecycle
from datetime import datetime
from enum import Enum

class RentalError(Exception):
    pass

class RentalState(Enum):
    RESERVED = "reserved"
    OUT = "out"
    RETURNED = "returned"

class Rental:
    def __init__(self, rental_id: str, item_tag: str, due_at: datetime):
        self._id = rental_id
        self._item_tag = item_tag
        self._due_at = due_at
        self._state = RentalState.RESERVED
        self._picked_up_at: datetime | None = None
        self._returned_at: datetime | None = None

    @property
    def id(self) -> str:
        return self._id

    def pick_up(self, at: datetime) -> None:
        if self._state is not RentalState.RESERVED:
            raise RentalError(f"rental {self._id} is {self._state.value}; only a reserved rental can be picked up")
        self._picked_up_at = at
        self._state = RentalState.OUT

    def return_equipment(self, at: datetime) -> None:
        if self._state is not RentalState.OUT:
            raise RentalError(f"rental {self._id} is {self._state.value}; only a rental that is out can be returned")
        if self._picked_up_at is not None and at < self._picked_up_at:
            raise RentalError("equipment cannot be returned before it was picked up")
        self._returned_at = at
        self._state = RentalState.RETURNED

    def is_overdue(self, now: datetime) -> bool:
        return self._state is RentalState.OUT and now > self._due_at

    def __eq__(self, other: object) -> bool:
        return isinstance(other, Rental) and other._id == self._id

    def __hash__(self) -> int:
        return hash(self._id)
```

## Anti-patterns

- **Setter soup.** Detect: a setter or public writable field for every attribute.
- **Service-edited entity.** Detect: application code that assigns two or more fields of an entity in sequence.
- **Status string.** Detect: a `status` field compared with string literals by callers; this is also an `$ddd:explicit-concepts` signal.
- **Persistence shell.** Detect: the only callers of the entity's methods are mappers and tests.
- **Rule in the UI.** Detect: a button enabled by a condition computed in the UI layer from entity fields.

## Trade-offs and exceptions

- In simple domains a data record is acceptable (`$ddd:right-sizing`); the rule is aimed at behavior-rich domains.
- Not every entity needs a state machine. Added judgment: add transition checks where a wrong transition would cause a business error, not for every field.
- The entity protects transitions that concern only itself. A rule spanning several objects belongs to the aggregate root (`$ddd:aggregates`) or a domain service (`$ddd:domain-services`).

## Verification

- [ ] The entity has an explicit identity that is never reassigned.
- [ ] Every change of state goes through a method named for a business action.
- [ ] Forbidden transitions raise a descriptive error and have tests.
- [ ] No caller assigns the entity's fields directly.
- [ ] Equality follows identity.

## Related

`$ddd:layers` for deciding which layer owns a rule found in a controller, job or application service; `$ddd:value-objects` for identity-less values; `$ddd:aggregates` for consistency across objects; `$ddd:domain-services` for behavior with no natural owner; `ddd-entity-reviewer` to review a diff; `ddd-behavior-mover` to move rules in.

## Source

- `Entities`
