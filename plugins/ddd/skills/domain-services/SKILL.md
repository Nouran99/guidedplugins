---
name: domain-services
description: "Use when a domain operation fits no single entity or value object, when a *Service class collects unrelated rules, or when behavior is moved out of entities only to keep them thin. Services that hold domain decisions; for application orchestration use ddd:layers."
---

# Domain services

Owns the narrow case where a domain-significant operation has no natural home on an entity or value object, and the opposite failure: god services and services that only wrap technical clients. Orchestration of an application task is `/ddd:layers`; moving a rule onto the object that owns it is `ddd:behavior-mover`.

## When to use

- An operation involves two or more objects and belongs to none of them (a transfer, an allocation, a conversion between models).
- A class called `SomethingService` or `Manager` holds many rules about one area.
- Behavior was pulled out of an entity "to keep it thin".
- A "domain service" turns out to wrap a repository or an HTTP client.
- You must decide between an entity method, a value-object operation and a service.

## Rules

1. **Use a domain service only when the behavior is domain-significant, does not naturally belong on one entity or value object, and the operation still belongs to the ubiquitous language.** Check: all three can be answered in one sentence each.
2. **A domain service must express a domain concept, not a technical convenience.** Check: the name is something an expert would say.
3. **If behavior clearly belongs to an entity or value object, keep it there.** Check: the service does not read an object's fields in order to decide something that object could decide.
4. **Do not move behavior into services merely to keep entities thin.** Check: no entity in the touched code is a bag of data because its rules were exported.
5. **Domain services should sound like the business.** Check: `PointsTransfer`, `CoverageAllocation`, not `ProcessingService`.
6. **Domain services should coordinate domain concepts, not infrastructure details.** Check: parameters and results are domain types; no repository or client is used inside the decision.
7. **Do not keep a single `*Service` containing all rules for a model area, or a service with dozens of unrelated policies.** Check: each service holds one cohesive operation family; no service's methods split into groups that never share state or vocabulary.
8. **Do not make "domain services" that only wrap repositories or external technical clients.** Check: remove the wrapper; if nothing domain-related is lost, it was not a domain service.
9. **Do not extract behavior from entities prematurely.** Check: extraction happens when a second object truly participates, not on the first long method.
10. **Added judgment:** keep a domain service free of business state of its own; the state belongs to the objects it operates on. Check: two calls with the same arguments do not depend on earlier calls.

## Procedure

1. List the operation's participants and the rule it enforces, in domain words.
2. Test each candidate home: can one participant decide it using only its own data? If yes, it is a method there (`/ddd:entities`, `/ddd:value-objects`).
3. If the rule needs several participants, name the operation as the experts do and check that it is part of the language (`/ddd:ubiquitous-language`).
4. Write the service with domain types in and out. Let the participants do their own part (each checks its own invariants); the service owns the rule that involves both.
5. Have the application layer call it after loading the objects and before saving them (`/ddd:layers`).
6. Test the service with in-memory objects, no infrastructure (`/ddd:domain-tests`).

## Example

```python
# Before: one MemberService owns every rule about members
class MemberService:
    def transfer_points(self, db, from_id, to_id, amount):
        a, b = db.member(from_id), db.member(to_id)
        if a.household_id != b.household_id: raise Exception("no")
        a.points -= amount
        b.points += amount
        db.save(a, b)
    # ... 30 more unrelated methods

# After: members decide their own part; the rule that spans two members has a name
class TransferNotAllowed(Exception):
    pass

class Member:
    def __init__(self, member_id: str, household_id: str, points: int):
        self.member_id = member_id
        self.household_id = household_id
        self._points = points

    @property
    def points(self) -> int:
        return self._points

    def withdraw(self, amount: int) -> None:
        if amount <= 0:
            raise ValueError("amount must be positive")
        if amount > self._points:
            raise TransferNotAllowed("not enough points")
        self._points -= amount

    def deposit(self, amount: int) -> None:
        if amount <= 0:
            raise ValueError("amount must be positive")
        self._points += amount

class PointsTransfer:
    MAX_PER_TRANSFER = 5_000

    def transfer(self, source: Member, target: Member, amount: int) -> None:
        if source.household_id != target.household_id:
            raise TransferNotAllowed("points move only within a household")
        if amount > self.MAX_PER_TRANSFER:
            raise TransferNotAllowed("above the per-transfer limit")
        source.withdraw(amount)
        target.deposit(amount)
```

The household rule needs both members, so it lives in the service. The per-transfer limit concerns only the amount and is part of the named `PointsTransfer` concept, not of `Member`. The loading and saving moved to an application service that calls `PointsTransfer`.

## Anti-patterns

- **God service.** Detect: a `*Service` with many methods about one area and no cohesive operation.
- **Anemic split.** Detect: entities with fields and getters next to services that contain every decision.
- **Repository wrapper.** Detect: a "domain service" whose body is calls to a repository or client.
- **Technical name.** Detect: `Processor`, `Handler`, `Helper` where an expert has a word.
- **Premature extraction.** Detect: a service created from a single entity's method with no second participant.

## Trade-offs and exceptions

- Services are the exception, not the default; the rule set keeps behavior on entities and values wherever it clearly belongs.
- Orchestration (load, call, save, publish) is allowed and expected in the application layer; keep it out of domain services (`/ddd:layers`).
- Added judgment: a service may take a specification or policy object as a parameter when the rule is configurable (`/ddd:explicit-concepts`).

## Verification

- [ ] The service's name is a domain term and the operation is part of the ubiquitous language.
- [ ] No participant could have decided the rule alone.
- [ ] Parameters and results are domain types; no infrastructure is called inside.
- [ ] Each participant still enforces its own invariants.
- [ ] The service is tested without a database or network.

## Related

`/ddd:layers` for application services; `/ddd:entities` and `/ddd:value-objects` for where behavior normally lives; `ddd:service-reviewer` to review a diff; `ddd:behavior-mover` to move rules.

## Source

- `Domain Services`
- `Application Layer`: only the rule that loading, calling, persisting and publishing belong to application services.
