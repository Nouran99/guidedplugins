---
name: "ddd-implementing-cross-aggregate-coordination"
description: "Use when an aggregate holds or loads another aggregate, or one use case saves several aggregates in a single transaction. Identity references, one aggregate per transaction, eventual coordination. Not for the inside of one aggregate (aggregate-boundaries)."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Cross-aggregate coordination

Owns the link between aggregates: how one points at another (by identity), what a transaction may modify (one aggregate by default), and how consistency across aggregates is reached (eventually, through events, policies or process coordination). The inside of one aggregate is `ddd-implementing-aggregate-boundaries`; the events themselves are `ddd-implementing-domain-events`; reactions that cross contexts are `ddd-implementing-integration-contracts`.

## When to use

- An aggregate has a field typed as another aggregate or a list of them.
- A use case loads two or more aggregates, changes them and saves them in one transaction.
- A lazy-loaded association pulls half the database when a method touches one property.
- Someone says "we need this to be transactional across both".
- An invariant seems to span two aggregates.

## Rules

1. **[SHOULD] Prefer identities over direct object references across aggregate boundaries.** A held aggregate drags its graph, and its rules, into this one. Check: fields that point to another aggregate are its identity value object (`CustomerId`), not the object.
2. **[SHOULD NOT] Load large connected graphs by default.** Check: loading an aggregate does not load other aggregates; lazy associations across aggregates do not exist.
3. **[SHOULD] Make cross-aggregate coordination usually eventual, not transactional.** Separate transactions scale and keep aggregates independent. Check: when a use case needs a second aggregate to change, the second change happens in its own transaction, triggered by an event, a policy or a process step.
4. **[SHOULD] Modify one aggregate in one transaction unless there is a compelling reason not to.** Check: a use case that saves two aggregates carries a written reason, naming the invariant that cannot be repaired afterwards.
5. **[MUST NOT] Stretch transactions across many aggregates out of convenience, and do not update many aggregates in one transaction by default.** "It is easier in one commit" is not a reason. Check: no transaction wraps a loop over aggregates, and transaction scope is reviewed whenever a use case touches more than one repository.
6. **[MUST] Use events, policies or process coordination when consistency can be eventual.** The rule applies where the business accepts the delay (rule 9); where an immediate invariant spans the aggregates, rules 4 and 8 govern instead. Check: the reaction is a named policy ("when an order ships, remove stock") rather than inline code in the first use case.
7. **[MUST NOT] Bake direct cross-aggregate navigation into the model.** `order.customer().address().city()` ties three aggregates together. Check: a model method does not call methods of another aggregate it holds; it receives the data it needs as arguments.
8. **[Compact checklist] When one transaction wants several aggregates, list the immediate invariants that require it; otherwise coordinate by identity, events, policies, processes or application services.** Check: the list exists (run `ddd-implementing-invariant-inventory`), and it names the data each invariant spans.
9. **[Added judgment] Ask whose job it is to make the two consistent.** If the business accepts that the second aggregate is updated seconds later, the invariant is eventual. Check: the domain expert confirmed the acceptable delay in the change description.
10. **[Added judgment] Make the second step safe to repeat.** Delivery may duplicate or reorder events; a handler keyed by the event's identity, or a naturally idempotent operation, makes redelivery harmless. Check: running the handler twice with the same event changes the second aggregate once. See the sibling plugin `data-intensive-apps` for delivery mechanics.

## Procedure

1. List the aggregates the use case loads, and for each, why. Mark each as "changes" or "only read".
2. For aggregates that only supply data, pass the data (or an identity plus a query) instead of the aggregate.
3. For aggregates that change, ask the question in rule 9. If an immediate invariant spans them, stop and reconsider the boundary (`ddd-implementing-aggregate-boundaries`) rather than keeping a wide transaction.
4. Replace held aggregate fields with identity value objects; reconstitute only the root being changed.
5. Make the first aggregate's behavior return an event; let a policy handler in the application layer change the second aggregate in its own transaction (`ddd-implementing-transaction-splitter` for a large change).
6. Test the policy separately: given the event, the second aggregate changes once, and a repeated delivery changes nothing more.

## Example

```python
# Before: one transaction, three aggregates, a held Customer
class Order:
    def __init__(self, order_id, customer: "Customer", lines):
        self.customer = customer             # whole aggregate held

def ship_order(order_id):
    with db.transaction():
        order = orders.get(order_id)
        for line in order.lines:
            stock = stock_levels.get(line.sku)
            stock.remove(line.quantity)      # second aggregate, same commit
            stock_levels.save(stock)
        order.mark_shipped()
        orders.save(order)

# After: the order holds an identity and one transaction changes one aggregate
class Order:
    def __init__(self, order_id: OrderId, customer_id: CustomerId, lines,
                 state: "OrderState" = None):
        self.id, self.customer_id, self._lines = order_id, customer_id, lines
        # a new order starts packed; a repository passes the stored state back in
        self._state = state if state is not None else OrderState.PACKED

    def mark_shipped(self) -> "OrderShipped":
        if self._state is not OrderState.PACKED:
            raise NotPacked(self.id)
        self._state = OrderState.SHIPPED
        return OrderShipped(event_id=new_event_id(), order_id=self.id,
                            lines=tuple((l.sku, l.quantity) for l in self._lines))

def ship_order(order_id: OrderId) -> None:          # application service
    with unit_of_work() as uow:
        order = uow.orders.get(order_id)
        event = order.mark_shipped()
        uow.orders.save(order)
    events.publish(event)                           # after the commit

def on_order_shipped(event: OrderShipped) -> None:  # policy: remove stock per sku
    for sku, quantity in event.lines:
        remove_stock(sku, quantity, dedupe_key=(event.event_id, sku))

def remove_stock(sku, quantity, dedupe_key) -> None:  # one StockLevel, one transaction
    with unit_of_work() as uow:
        if not uow.handled.mark(dedupe_key):          # False when already handled
            return
        stock = uow.stock_levels.get(sku)
        stock.remove(quantity)
        uow.stock_levels.save(stock)
```

If publication can fail after the commit, a transactional outbox is the usual remedy; that is Added judgment, not a rule of the source.

## Anti-patterns

- **Held aggregate.** A field typed as another aggregate. Detect: a model class importing another aggregate's class.
- **Wide transaction.** `with transaction:` around a loop that saves several aggregates. Detect: a unit of work with more than one repository `save` of different aggregate types.
- **Lazy graph.** An association that triggers loads on access. Detect: ORM relation mappings between aggregates.
- **Compensation patch.** Events added to repair missing aggregate design. Detect: an event whose only consumer re-derives data the aggregate should have owned.

## Trade-offs and exceptions

- The source allows several aggregates in one transaction only for a compelling reason: a real invariant that must hold immediately and spans them. Write the reason; reconsider the boundary first.
- Eventual consistency has a cost: partial states are visible, handlers can fail, ordering needs thought. The source prefers it when the business allows; it does not claim it is free.
- A one-off data migration may touch many aggregates; it is not a use case. Keep it outside the model code.

## Verification

- [ ] Fields that point to other aggregates hold identities.
- [ ] Loading one aggregate loads no other aggregate.
- [ ] Each use case saves one aggregate, or carries a written invariant for saving more.
- [ ] Cross-aggregate reactions are named policies running in their own transactions.
- [ ] Handlers tolerate a repeated event.
- [ ] No model method navigates through another aggregate.

## Related

`ddd-implementing-aggregate-boundaries` for the inside; `ddd-implementing-domain-events` for the event design; `ddd-implementing-application-services` for where the transaction is owned; `ddd-implementing-invariant-inventory` for the proof; `ddd-implementing-transaction-reviewer` to review a diff; `ddd-implementing-identity-reference-converter` and `ddd-implementing-transaction-splitter` to make the changes.

## Source

- `Aggregate Rules of Thumb`: only the Reference Other Aggregates by Identity and One Aggregate per Transaction by Default subsections and the matching anti-patterns.
- `Reference Other Aggregates by Identity`
- `One Aggregate per Transaction by Default`
- `Final Instruction`: only the item that moves cross-boundary coordination toward events and translation.
