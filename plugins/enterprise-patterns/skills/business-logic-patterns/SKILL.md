---
name: business-logic-patterns
description: "Use when deciding where business rules live: choosing Transaction Script, Table Module or Domain Model, noticing a script growing duplicated rules, or an anemic model beside a fat service. Decisions about the business only; use-case sequencing is service-layer."
---

# Business logic patterns

Chooses how the business decisions of a feature are organized (Transaction Script, Table Module, Domain Model), keeps each pattern honest, and says when to move up. Sequencing a use case, owning its transaction and calling collaborators is `/enterprise-patterns:service-layer`.

## When to use

- A new feature needs a home for its rules and you must pick a pattern.
- The same condition appears in two request handlers or scripts, and one copy has already drifted.
- Status transitions, validity rules or calculations are spread across a service and several helpers.
- A report or calculation is naturally set-oriented and someone proposes one object per row.
- A reviewer flags either "trivial CRUD wrapped in excessive modeling" or "complex rules trapped in a script".

## Rules

1. **Choose the business logic pattern by the actual complexity**, not by habit or framework default. A pattern that does not match the complexity is paid for in duplication on one side and ceremony on the other. Check: you can say in one sentence which force (simplicity, set orientation, invariants, lifecycle, collaboration) selected it.
2. **Use Transaction Script when the logic is simple, each request is mostly independent and rich domain modeling is unnecessary.** It is the lowest-ceremony way to organize logic, and these cases need nothing more. Check: each script reads top to bottom as one use case.
3. **Keep transaction scripts short and use-case focused.** A long script hides which decisions it makes and invites copies. Check: one script, one use case; no script exists to be shared by other scripts.
4. **Do not let transaction scripts become the dumping ground for all business logic.** Scripts that call one another for shared decisions become a tangle with no owner. Check: no module of "common" decision functions that scripts import from each other.
5. **If duplication, lifecycle or invariant complexity grows, escalate to a stronger pattern.** Left alone, copies drift apart and the rule stops being one rule. Check: the same business condition in two places, status changes allowed from many callers, or a rule that spans several fields. Added judgment: notice the second copy, act on the third; the source gives no number.
6. **Use Table Module when logic is naturally organized around tabular data sets, calculations are set-oriented and object identity is not the organizing force.** Set-based logic is clearest, and cheapest, where the data already is. Check: the operations are "for all rows where ...", not "this customer's ...".
7. **Keep Table Module behavior centered on the table abstraction.** Per-object behavior mixed into a module meant for sets blurs both. Check: one module per table or view whose methods work on sets of rows.
8. **Do not fake entities if the real model is fundamentally tabular.** A wrapper per row adds objects without adding behavior. Check: row-wrapper classes that exist only to expose one getter per column.
9. **Isolate tabular logic from presentation and transport.** Transport and display concerns in a set-oriented module make it untestable on its own. Check: no formatting, HTTP or UI types inside the table module.
10. **Use Domain Model when domain complexity is significant**: rules, invariants and lifecycles matter, and identity, collaboration and behavior belong in the model. Rules and lifecycles need an owner that sits next to the data they constrain. Check: you can name an invariant or a lifecycle the model object protects.
11. **Put rich domain logic in model objects, and keep application coordination separate from domain decisions.** Decisions beside their data are found where people look, and coordination can then stay thin. Check: the object that owns the data has the method that decides; the service only calls it.
12. **Avoid anemic models in behavior-rich domains.** An anemic model leaves every rule in services, where it is easy to duplicate. Check: classes that are all getters and setters while a service holds every conditional about them. In a simple domain an anemic holder is acceptable.
13. **Avoid the domain model everywhere regardless of complexity.** Defaults from the source: simple CRUD fits a transaction script or a simple service layer; rich invariants fit a domain model with a repository and mapper; table-oriented calculations fit a table module or table gateway. A rich model for a form that saves a row costs mappers, tests and indirection for no rule.

## Procedure

1. List the business decisions in the use case: every branch whose condition is a business rule, not input parsing or flow control.
2. Mark the forces present: duplicated decisions across use cases, a lifecycle with allowed transitions, invariants across fields or objects, set-oriented calculation, or none of these.
3. Pick the lightest pattern the forces allow using rule 13's defaults. Written per area of the system: Added judgment, mixed patterns in one codebase are fine when the boundary between areas is clear.
4. If a script already exists, move only the repeated or invariant-bearing decision into a model object or table module, and leave the script as the sequence that calls it (`/enterprise-patterns:escalate-pattern` does this stepwise).
5. Choose the persistence follow-up together with the pattern: a domain model usually pulls in `/enterprise-patterns:repository` and `/enterprise-patterns:data-mapper`; a table module pairs with a table data gateway (`/enterprise-patterns:gateways-and-active-record`).
6. Run the tests after each move.

## Example

```python
from dataclasses import dataclass
from datetime import date
from typing import ClassVar

# Before: two transaction scripts each carry a copy of the refund decision, and one copy has drifted
def request_refund(db, order_id: str, today: date) -> None:
    row = db.fetch_order(order_id)
    if row["status"] == "delivered" and (today - row["delivered_on"]).days <= 30:
        db.mark_refund_requested(order_id)
    else:
        raise ValueError("order is not refundable")

def refund_preview(db, order_id: str, today: date) -> bool:
    row = db.fetch_order(order_id)
    return row["status"] == "delivered" and (today - row["delivered_on"]).days <= 29

# After: the repeated decision lives with the data it depends on; the scripts stay scripts
@dataclass(frozen=True)
class Order:
    REFUND_WINDOW_DAYS: ClassVar[int] = 30
    id: str
    status: str
    delivered_on: date | None

    def refundable_on(self, today: date) -> bool:
        return (
            self.status == "delivered"
            and self.delivered_on is not None
            and (today - self.delivered_on).days <= self.REFUND_WINDOW_DAYS
        )

def request_refund(orders, order_id: str, today: date) -> None:
    order = orders.get(order_id)
    if not order.refundable_on(today):
        raise ValueError("order is not refundable")
    orders.mark_refund_requested(order_id)

def refund_preview(orders, order_id: str, today: date) -> bool:
    return orders.get(order_id).refundable_on(today)
```

Only the decision moved. Nothing else was converted to a model, which is the point: escalation is as small as the evidence.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Dumping-ground scripts | Scripts import decision helpers from one another | Move the shared decision to the object or table module that owns its data |
| Fake entities over tabular work | Row wrappers with one getter per column feeding a report | Use a table module or table gateway and keep the set-based query |
| Anemic model, fat service | Entities without behavior; `*Service` with every `if` | Move each decision to the object it asks questions about |
| Domain model for trivial CRUD | Rules-free entities, mappers and factories for a form that saves a row | Collapse to a script or simple service |
| Rules trapped in a script | Status transitions or invariants re-checked in each script | Escalate to a model object; keep scripts as sequencing |

## Trade-offs and exceptions

- Simple logic stays simple. The source lists simple CRUD as a transaction-script or simple-service case, so choosing a script is not a smell.
- Escalation is triggered by observed duplication, lifecycle or invariant complexity, not by prediction.
- When the project has committed to domain-driven design, that plugin decides how rich the model is; this skill then only checks that coordination stays out of it.
- Table-oriented work does not need entities merely to look object-oriented.

## Verification

- [ ] The chosen pattern is named with the force that selected it.
- [ ] No business condition is duplicated across scripts, handlers or services.
- [ ] Application coordination and domain decisions are in different places.
- [ ] No row-wrapper classes exist solely to hold column getters.
- [ ] The persistence pattern was chosen with the business logic pattern.
- [ ] The tests pass after each move.

## Related

`/enterprise-patterns:service-layer` for coordination; `/enterprise-patterns:escalate-pattern` to move up stepwise; `/enterprise-patterns:choose-pattern` for a full recommendation; `enterprise-patterns:logic-placement-reviewer` to review a diff; `enterprise-patterns:logic-mover` to carry out moves.

## Source

- `Choosing the Business Logic Pattern`
- `Transaction Script`
- `Table Module`
- `Domain Model`
- `Code Generation Rules`: only the default choices and the avoid-by-default list.
- `Review Rules`: only the two findings about excessive modeling and rules trapped in scripts.
