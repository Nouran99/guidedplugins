---
name: "ddd-distilled-cross-aggregate-consistency"
description: "Use when one request or transaction loads or saves more than one aggregate root, when convenience builds a graph, or when a second aggregate must follow the first. Covers transaction scope, eventual consistency. Event design: ddd-distilled-domain-events; one aggregate: ddd-distilled-aggregates."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Cross-aggregate consistency

How much one transaction may change. The default in this book is one aggregate per transaction and eventual consistency between aggregates. This skill judges a use case (what it loads, what it saves, what follows); the shape of each aggregate is `ddd-distilled-aggregates`, how the follow-up messages travel safely is `ddd-distilled-integration-styles`, and what the event is called and carries is `ddd-distilled-domain-events`.

## When to use

- A handler loads two or more aggregate roots and saves them together.
- A request loads a large graph to display or to decide something, then writes to part of it.
- After one change, another part of the system must react (mark ready, notify, reserve).
- Someone proposes making an aggregate bigger so "everything is in one transaction".

## Rules

1. **Let one transaction usually change one aggregate.** Larger transactions couple aggregates through locking and failure. Check: count the roots saved per use case; more than one needs a recorded reason.
2. **Default to eventual consistency across aggregates.** Most cross-aggregate rules tolerate a short delay. Check: the second effect is triggered after the first commit by an event or message, in its own transaction.
3. **Use identifiers for references across aggregate boundaries.** An object reference invites reading and changing the other aggregate in the same call. Check: no aggregate field is typed as another aggregate; see `ddd-distilled-aggregates`.
4. **When a request wants to change several roots or load a large graph, revisit the invariant boundary and ask whether eventual consistency is acceptable.** (Compact checklist) Check: a business answer exists, in the business's own words, to "how long may these two disagree?".
5. **Do not let one request load and mutate a whole graph.** It makes every use case depend on everything. Check: no use case walks from one root across others while writing.
6. **Do not make aggregates large to buy convenient navigation.** Check: display needs spanning aggregates are met with identifiers plus a separate query.
7. **If two objects must agree at the same instant, treat that as an invariant and reshape the boundary before spanning transactions.** (Added judgment) Check: the business said "never, even briefly", and the objects are now in one aggregate or the rule was relaxed.
8. **Make the follow-up safe for lag, duplicates and ordering limits.** Eventual consistency only works if the second step tolerates delay, redelivery and out-of-order arrival (`ddd-distilled-integration-styles`). Check: the handler does not assume it runs immediately and survives a duplicate or late message. (Added judgment) The usual way to survive a duplicate is an idempotent handler.
9. **Record each deliberate multi-root transaction.** (Added judgment) The rule says "usually", so exceptions exist; an unrecorded exception looks like a mistake to the next reader. Check: a comment or decision note names the invariant that forced it.
10. **Read across aggregates with a query, not with object navigation.** (Added judgment) Check: a list or summary that spans aggregates is built by a read-only query returning a purpose-made shape.

## Procedure

1. For each use case in the change, list aggregates loaded, aggregates modified and aggregates saved.
2. For every extra root modified, write the business statement of what may be temporarily inconsistent and for how long.
3. If the business accepts the delay, split: the first aggregate records a fact; a handler applies the second change in its own transaction, idempotently.
4. If the business does not accept it, revisit the boundary with `ddd-distilled-aggregates`; either the rule really is one aggregate's invariant, or it can be relaxed.
5. Remove graph traversals; replace them with identifiers and a read query where display needs data from several places.
6. Record any multi-root transaction you decide to keep.

## Example

```python
# Before: two aggregates in one transaction; paying an invoice also edits the order
def pay_invoice(invoice_id, order_id, payment):
    with unit_of_work() as uow:
        invoice = uow.invoices.get(invoice_id)
        order = uow.orders.get(order_id)
        invoice.mark_paid(payment)
        order.mark_ready_for_dispatch()
        uow.commit()


# After: one aggregate per transaction; the order reacts to a fact
def pay_invoice(invoice_id: InvoiceId, payment: Payment) -> None:
    with unit_of_work() as uow:
        invoice = uow.invoices.get(invoice_id)
        invoice.mark_paid(payment)          # records InvoicePaid(order_id=...)
        uow.invoices.save(invoice)
        uow.commit()                        # recorded events are published after the commit


def on_invoice_paid(event: InvoicePaid) -> None:
    with unit_of_work() as uow:
        order = uow.orders.get(event.order_id)
        order.mark_ready_for_dispatch()     # marking an already-ready order has no further effect
        uow.orders.save(order)
        uow.commit()
```

The business accepted that an order may show "awaiting payment" for a few seconds after the invoice is paid. `unit_of_work`, `InvoicePaid` and the repositories are assumed.

## Anti-patterns

- **Multi-root by default.** Detect: handlers that load two or three roots every time.
- **Graph for display.** Detect: a use case loads aggregates only to read fields from them.
- **Eventual consistency without idempotence.** Detect: a handler that appends or increments with no duplicate check.
- **Unrecorded exception.** Detect: a multi-root transaction with no explanation.
- **Hidden coupling by navigation.** Detect: `order.customer.account.limit` style chains inside a use case.

## Trade-offs and exceptions

- "Usually" and "default" leave room for a deliberate exception; keep it rare and written down.
- Making the save and the publish reliable together (for example with an outbox) is a data-semantics question outside this rule set; the `data-intensive-apps` plugin covers it.
- Eventual consistency changes what users see for a moment. If the business cannot accept that, the answer is a different boundary, not a hidden shared transaction.
- A query that reads several aggregates is fine; the rule restricts what one transaction changes.

## Verification

- [ ] Each use case saves at most one aggregate, or has a recorded reason.
- [ ] Each cross-aggregate effect has a business statement of acceptable delay.
- [ ] No use case loads and mutates a whole graph.
- [ ] Follow-up handlers are safe on redelivery and late arrival.
- [ ] Cross-aggregate reads use identifiers and queries, not object navigation.

## Related

`ddd-distilled-aggregates`; `ddd-distilled-domain-events`; `ddd-distilled-integration-styles`; `ddd-distilled-application-services`; `ddd-distilled-consistency-reviewer` to review a diff.

## Source

- `Aggregate Minimalism Rules`
- `Aggregates`: only the rules to reference other aggregates by identity and to avoid loading large graphs.
- `Integration Style Rules`: only the rule that consumers must handle lag, duplicates and ordering limits.
