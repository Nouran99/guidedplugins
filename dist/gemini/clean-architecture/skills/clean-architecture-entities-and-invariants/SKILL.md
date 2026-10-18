---
name: "clean-architecture-entities-and-invariants"
description: "Use when a business rule needs a home, an entity can reach an invalid state, or domain code does I/O or reads configuration. A rule already sitting in a controller or job: the destination is here, judging the controller itself is interface-adapters. One action's flow is use-cases."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Entities and invariants

Owns the innermost layer: what lives there and what keeps it pure. Orchestration of one application action is `clean-architecture-use-cases`; markers from a framework are `clean-architecture-framework-independence`; a model shaped like a table is `clean-architecture-persistence-independence`.

## When to use

- A conditional on business fields (limits, statuses, eligibility) appears in a controller, scheduled job, message handler or SQL script.
- An object can be built or mutated into a state the business forbids.
- Domain code opens a file, calls a service, reads an environment variable or asks the system clock.
- You are deciding whether a rule belongs in an entity or in one use case.

## Rules

1. **Put business policy in entities and use cases.** `[MUST]` Policy left in delivery or storage code is invisible to fast tests and gets copied. Check: you can find every rule by searching the domain and application directories, not controllers or SQL.
2. **Keep critical domain rules in entities or equivalent domain objects.** `[MUST]` The source allows plain objects, functions, modules or other structures; it does not demand a modeling style. Check: you can name the module that owns the rule without opening a controller.
3. **Make entities protect their invariants and consistency.** `[MUST]` Check: there is no way to construct or mutate the object into a forbidden state: construction validates, and changes go through methods that check.
4. **Do not leave a core rule behind in a controller, job, handler or database script.** `[MUST NOT]` Check: grep those places for comparisons against business thresholds, status values and tiers; each hit is a rule in the wrong place.
5. **Keep the domain layer framework free, persistence ignorant and delivery mechanism agnostic.** `[MUST]` Check: nothing in the layer names a web, ORM or queue type, and no class exists only because storage or transport needed it.
6. **Do not let the domain import web libraries, database access types or external service clients, perform I/O, or read configuration directly.** `[MUST NOT]` Check: no file, network, environment or clock call appears in domain code. Added judgment: reading the current time counts, because the source lists clocks among the volatile dependencies; pass `now` in as a value.
7. **Avoid annotations and infrastructure imports in the domain where possible.** `[SHOULD]` Check: domain classes carry no mapping, serialization or injection markers; if one is unavoidable, it is documented (`clean-architecture-boundary-economics`).
8. **Let business rules receive plain data, never web requests, environment variables, framework context, database-bound structures or rows.** `[MUST NOT]` Check: parameters of entity methods are values and domain types.
9. **Place each piece of code in the highest-level place that matches its responsibility.** `[MUST]` Ask: is this business policy, orchestration, translation or infrastructure? Critical domain rules belong in entities. Check: each piece of code sits in the layer its answer names. Added judgment: for a rule you cannot place, ask whether a second use case would need it; if yes, it belongs in the entity, and a non-critical rule that exists only for one application action may stay in that use case.
10. **Do not demand classes.** The source says the layer may be plain objects, functions or modules, so a module of pure functions over plain records satisfies it. Check: the demand in your review comment is about independence and guarded invariants, not about syntax.
11. **Separate structural input validation from policy.** Added judgment: "the field is present and is a number" is translation and may stay in the adapter; "a permit may be extended by at most fourteen days in total" is a rule a domain expert would state, and it belongs inward. Check: ask whether the person who owns the business would recognize the check.

## Procedure

1. List the conditionals in the changed code that compare business fields. For each, apply rule 9's four-way question.
2. For a rule that belongs in an entity, find the entity (or create a small one) and move the rule behind a method named for the business action, not for the check.
3. Make the invalid state unconstructible: validate in the constructor or factory and remove setters that skip the check.
4. Replace calls to the clock, environment or I/O in domain code with values or ports (`clean-architecture-ports-and-gateways`).
5. Leave the adapter translating the entity's outcome (an exception or result) into a status code or message.
6. Add a unit test of the rule that runs with no framework and no database, then run the existing tests.

## Example

```python
# Before: parking/http_handler.py holds the rule
def extend_permit(request, db):
    permit = db.fetch_permit(request.json["permit_id"])
    days = request.json["days"]
    if permit["status"] == "revoked":
        return {"error": "revoked"}, 409
    if permit["extended_days"] + days > 14:
        return {"error": "limit"}, 422
    permit["extended_days"] += days
    db.save_permit(permit)
    return {"ok": True}, 200
```

```python
# After: parking/domain/permit.py has no framework, no I/O
MAX_EXTENSION_DAYS = 14


class PermitRevoked(Exception):
    pass


class ExtensionLimitExceeded(Exception):
    pass


class Permit:
    def __init__(self, permit_id: str, revoked: bool, extended_days: int = 0):
        if not 0 <= extended_days <= MAX_EXTENSION_DAYS:
            raise ValueError("extended_days is outside the allowed range")
        self.permit_id = permit_id
        self._revoked = revoked
        self._extended_days = extended_days

    @property
    def extended_days(self) -> int:
        return self._extended_days

    def extend(self, days: int) -> None:
        if days <= 0:
            raise ValueError("days must be positive")
        if self._revoked:
            raise PermitRevoked(self.permit_id)
        if self._extended_days + days > MAX_EXTENSION_DAYS:
            raise ExtensionLimitExceeded(self.permit_id)
        self._extended_days += days
```

Construction validates, and the only way to change the count is `extend`, so no path reaches a forbidden state. The positive-days guard and the construction check are invariants the handler never enforced; adding them is a behavior change, so agree on them separately from the move. The use case loads the permit through a port, calls `permit.extend(days)`, and saves it; the gateway reads `extended_days` through the property. The handler keeps only translation: `PermitRevoked` becomes 409, `ExtensionLimitExceeded` becomes 422.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Bag of fields | An entity with only fields and getters while rules sit in services or controllers | Move the rules onto the entity, one action at a time |
| Setter bypass | A public setter or field that skips the checks | Remove it; expose the business action |
| Rule in the handler | Comparisons with business thresholds in a controller, job or consumer | Move to an entity; keep status mapping in the adapter |
| Hidden clock | `now()`, `Date.now()` or `LocalDate.now()` called inside domain code | Pass the time in as a value |
| Domain reads config | An environment or settings lookup inside an entity | Read it in main and pass a plain value |
| SQL as policy | A `where` clause that encodes eligibility | Define eligibility in the entity; query by key (`clean-architecture-persistence-independence`) |

## Trade-offs and exceptions

- The source does not require a particular domain modeling style. Do not insist on rich objects where pure functions over plain data keep the rules independent and guarded.
- "Avoid annotations ... where possible" is a `SHOULD`. When a persistence or serialization tool forces a marker, keep it as close to the edge as possible and record the compromise.
- Not every check is policy. Rejecting a malformed request is the adapter's job; do not push syntax checks into entities just to empty the controller.
- Added judgment: a rule that is not a critical domain rule and is used by only one application action may stay in that use case; promote it to an entity when a second action needs it.

## Verification

- [ ] The rule can be found by searching domain and application code only.
- [ ] No setter, public field or constructor path creates a forbidden state.
- [ ] The domain code imports no web, database or service-client module and performs no I/O.
- [ ] Time, configuration and identifiers enter as values or ports.
- [ ] A test of the rule runs without a framework or database.
- [ ] The adapter maps outcomes to transport results and decides nothing.

## Related

`clean-architecture-use-cases` for orchestration around the entity; `clean-architecture-place-code` to classify a piece of code; `clean-architecture-persistence-independence` for table-shaped models; `clean-architecture-domain-purity-reviewer` to review a diff.

## Source

- `Domain Layer`
- `Non-Negotiable Rules`: rules 2 and 9, pure business rules and entities that guard invariants.
- `Policy vs Detail`
- `Controller-Centric Logic`: only controllers containing branching business rules or validation that belongs to business policy.
- `Create Ports for Volatile Dependencies`: only clocks and ID generators as volatile dependencies.
- `Output Expectations`: only the default of producing a domain model or entity when business invariants exist.
