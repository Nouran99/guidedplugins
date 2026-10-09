---
name: layers
description: "Use when controllers, handlers, jobs or application services decide business outcomes, or when choosing a rich domain layer or Smart UI. Which layer decides; ORM shapes in the model: ddd:infrastructure; an entity's setters and transitions: ddd:entities; whether modeling is earned: ddd:right-sizing."
---

# Layers and the application layer

Owns the question "which layer makes this decision": business rules live in the domain layer, application code coordinates one task at a time, and a Smart UI is acceptable only for simple applications. It does not cover technical representations inside the model (`/ddd:infrastructure`) or operations that need a domain service (`/ddd:domain-services`).

## When to use

- A controller, request handler, batch job or script contains an `if` that expresses a business rule.
- An application service loads an entity, branches on its fields and writes the fields back.
- Someone proposes putting everything in the UI layer, or in stored procedures, "because it is only a form".
- Two entry points (API and a nightly job) must apply the same rule and one of them copied it.
- You are reviewing what an application service is allowed to contain.

## Rules

1. **Keep the domain layer as the place where the model and business rules live.** A rule outside it cannot be reused or tested with the model. Check: for each business `if` in the diff, name the domain object that owns it.
2. **Separate presentation, application coordination, domain behavior and infrastructure when the domain is complex enough to need model-driven design.** Check: the four responsibilities are in distinguishable modules, or the domain is documented as simple (rule 9).
3. **Let application code coordinate tasks without owning domain decisions.** Check: an application service reads as load, call, save, publish; no branching on domain state.
4. **Application services load aggregates, call domain behavior, persist results and coordinate side effects.** Check: each operation can be described with those four verbs.
5. **Application services must not hold core business invariants that belong in the domain.** Check: deleting the service would not remove a rule; the rule would still be enforced by the model.
6. **Application services must speak the ubiquitous language.** Check: method names are business actions (`approveClaim`), not `update`, `process` or `handleRequest`.
7. **Application services may coordinate transactions and integration publication, but should not become procedural god classes.** Check: one operation per application action, and no service with dozens of unrelated methods (`/ddd:domain-services`).
8. **Keep each application operation focused on one application action; keep orchestration distinct from business rules.** Check: the operation's name is one verb phrase and its body has no domain vocabulary beyond calls into the model.
9. **Use Smart UI only for simple applications where rich domain abstraction, reuse, integration and deep business rules are not important.** Check: you can state why this application has none of those needs (`/ddd:right-sizing`).
10. **Keep infrastructure services and framework concerns outside domain objects.** Check: domain files import no web, ORM, queue or serialization framework.
11. **Do not let screens, tables or framework annotations define the domain vocabulary, and do not leave domain objects passive while UI, jobs or scripts carry the rules.** Check: the rule's tests run without a UI, a database or a scheduler.
12. **Do not choose Smart UI when the business behavior needs reuse or abstraction.** Check: a rule needed from a second entry point is the signal. Added judgment: treat the second copy of a rule as the trigger to move it into the domain layer.

## Procedure

1. List the business decisions in the touched code: conditions on domain state, calculations, validity checks, transitions.
2. For each, find where it lives (UI, controller, job, application service, repository, domain). Mark those outside the domain layer.
3. Move each into the domain object that owns the data it decides on, or into a domain service when no object fits (`/ddd:domain-services`). Use `ddd:behavior-mover` for a large move.
4. Reduce the application service to load, call, save, publish. Keep transactions and side effects there.
5. Check the language: rename application operations to business actions.
6. Run the tests; add a model-level test for each moved rule (`/ddd:domain-tests`).

## Example

```python
# Before: the endpoint decides refund eligibility
def refund_endpoint(order_id, today):
    order = db.load(order_id)
    if order.status == "SHIPPED" and (today - order.shipped_on).days <= 30 and not order.is_final_sale:
        order.status = "REFUNDED"
        db.save(order)

# After: the model decides; the application service coordinates
from datetime import date, timedelta

class RefundNotAllowed(Exception):
    pass

class Order:
    REFUND_WINDOW_DAYS = 30

    def __init__(self, order_id: str, shipped_on: date | None, final_sale: bool):
        self.order_id = order_id
        self._shipped_on = shipped_on
        self._final_sale = final_sale
        self._refunded = False

    def can_be_refunded_on(self, today: date) -> bool:
        return (
            not self._refunded
            and not self._final_sale
            and self._shipped_on is not None
            and today - self._shipped_on <= timedelta(days=self.REFUND_WINDOW_DAYS)
        )

    def refund(self, today: date) -> None:
        if not self.can_be_refunded_on(today):
            raise RefundNotAllowed(f"order {self.order_id} cannot be refunded on {today}")
        self._refunded = True

class RefundOrder:
    def __init__(self, orders):
        self._orders = orders

    def execute(self, order_id: str, today: date) -> None:
        order = self._orders.get(order_id)
        order.refund(today)
        self._orders.save(order)
```

## Anti-patterns

- **Transaction-script service.** Detect: an application service that branches on entity fields and then assigns them.
- **Rule in the handler.** Detect: business conditions in controllers, jobs, serializers or SQL.
- **Rule copied per entry point.** Detect: the same condition in the API handler and the batch job.
- **Overlapping enforcement.** Detect: repository, UI handler and application service each checking the same rule differently.
- **Smart UI beyond its means.** Detect: a form-driven design acquiring integrations, reports and scheduled jobs that all need the same rules.

## Trade-offs and exceptions

- Smart UI is legitimate for simple applications; the rule set says to use it only when rich abstraction, reuse, integration and deep rules do not matter.
- Added judgment: application services may validate input shape (required fields, formats) at the edge. The line is that a domain invariant is enforced by the model; an input-shape check can duplicate it for a friendlier error.
- Application services may coordinate transactions and integration publication (rule 7). Added judgment: coordination that spans several aggregates or an external call also belongs in the application layer even when it looks like business flow; the decision at each step still belongs to the model.

## Verification

- [ ] Every business condition in the diff is in a domain object or domain service.
- [ ] Application service methods are load, call, save, publish, with names in business language.
- [ ] Domain classes import no UI, ORM, queue or HTTP types.
- [ ] A model-level test exists for each rule that moved.
- [ ] If Smart UI was kept, the reason is written down and no second entry point repeats a rule.

## Related

`/ddd:infrastructure` for technical shapes inside the model; `/ddd:domain-services` for operations without a natural home; `/ddd:right-sizing` for when a simple design wins; `ddd:layer-reviewer` to review a diff; `ddd:behavior-mover` to relocate rules.

## Source

- `Layered Architecture and Smart UI`
- `Application Layer`
