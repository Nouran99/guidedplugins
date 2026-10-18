---
name: "ddd-distilled-integration-styles"
description: "Use when choosing or reviewing how contexts talk: RPC, REST resources or asynchronous messaging, and whether a domain event carries its data or makes consumers query back. For converting the foreign model use ddd-distilled-context-translation."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Integration styles

The mechanism that crosses a context boundary. This skill chooses between RPC, REST and messaging from business coupling and failure semantics, and decides what an event payload promises. What gets converted on arrival is `ddd-distilled-context-translation`; what the event is called and whether it is a fact is `ddd-distilled-domain-events`; production failure handling such as timeouts and retries belongs to the `release-it` plugin.

## When to use

- A new service-to-service call, endpoint, queue or webhook is being added.
- A REST resource is a thin serialization of an aggregate, or a message consumer assumes it sees every message once and in order.
- A team is debating whether an event should carry the changed data or only an identifier.
- You review an integration for coupling and failure behavior.

## Rules

1. **Use RPC only when request/response coupling, latency, versioning and failure semantics are acceptable.** The caller is coupled to the callee's availability and shape. Check: the caller's design says what happens when the callee is slow, down or changed.
2. **Use REST resources as application-facing representations, not as leaked aggregate internals.** A resource shaped by the aggregate's fields couples every client to the model. Check: resource fields are designed for the client's task, and no endpoint edits an aggregate's inner objects directly.
3. **Use messaging when asynchronous coordination fits the business process and consumers can handle lag, duplicates and ordering limits.** Delivery guarantees are weaker than a call's. Check: the business has accepted the delay, the consumer is safe on redelivery, and a late message cannot overwrite newer state.
4. **Decide whether domain events carry enough information for consumers or require them to query back.** Either is acceptable; (Added judgment) leaving it unstated is not. Check: each event type has a written decision. (Added judgment) Carrying data keeps consumers independent at run time but ties them to the payload shape and risks stale data; querying back returns fresh data but makes the producer's availability and query interface part of the contract.
5. **Keep integration contracts separate from internal models.** Check: contract types are in their own module, and internal refactoring does not change them.
6. **Test translations wherever meanings cross a boundary.** Check: there is an example test for each mapping; see `ddd-distilled-context-translation`.
7. **Select the style from business coupling and failure semantics.** (Compact checklist) (Added judgment) Habit and tooling are not reasons. Check: the decision record cites the business reason, not a technology preference.
8. **State the versioning promise for any contract that other teams consume.** (Added judgment) Check: each consumed contract names its version and what changes are allowed without a new version.
9. **Give every published event an identifier and an occurrence time.** (Added judgment) Consumers need them to detect duplicates and reason about order. Check: both fields exist on each event type.

## Procedure

1. Name the two contexts and the business interaction between them. Say whether the caller needs an answer now.
2. If an immediate answer is required and coupling is acceptable, consider RPC; write down the failure behavior.
3. If the interaction is a business process that tolerates delay, consider messaging; write down how duplicates and ordering are handled.
4. If clients need a representation of a context's data, design a REST resource for their task, not for the aggregate.
5. For events, decide carry-data or query-back and record it.
6. Write the contract in its own module, and add translation tests.

## Example

```python
# Before: assumes every message arrives exactly once and in order
def on_payment_received(msg: dict) -> None:
    invoice = invoices.get(msg["invoice_id"])
    invoice.status = "PAID"                 # a late duplicate rewrites state
    invoice.paid_amount += msg["amount"]    # a redelivery counts the payment twice
    invoices.save(invoice)


# After: the contract is typed, and the aggregate makes redelivery harmless
def on_payment_received(msg: PaymentReceivedV1) -> None:
    invoice = invoices.get(InvoiceId(msg.invoice_id))
    invoice.record_payment(
        payment_id=PaymentId(msg.payment_id),
        amount=Money(msg.amount_minor, msg.currency),
    )
    invoices.save(invoice)


class Invoice:
    def record_payment(self, payment_id: PaymentId, amount: Money) -> None:
        if payment_id in self._recorded_payments:
            return                          # the same payment delivered again has no effect
        self._recorded_payments[payment_id] = amount
```

Payments are recorded by identifier, so arrival order does not change the outcome. `PaymentReceivedV1`, `InvoiceId`, `PaymentId` and `Money` are assumed types.

## Anti-patterns

- **Chatty RPC across a context edge.** Detect: one use case makes many synchronous calls to another context.
- **Aggregate as resource.** Detect: a REST response is the serialized aggregate, or clients PUT inner objects.
- **Exactly-once assumption.** Detect: a consumer that increments or appends without an identity check.
- **Unstated payload contract.** Detect: consumers query the producer's database or API for fields no event documents.
- **Internal model on the wire.** Detect: contract types are the domain classes.

## Trade-offs and exceptions

- RPC is acceptable when the coupling, latency and failure behavior are acceptable to the business; the rule is a condition, not a ban.
- Messaging adds moving parts. Do not use it for an interaction that needs an immediate answer.
- Carrying data in events is not forbidden because it can go stale; it is a decision to be made and recorded.
- Timeouts, retry budgets, circuit breakers and overload behavior are production-failure concerns outside this rule set; use the `release-it` plugin when they dominate.

## Verification

- [ ] The chosen style is justified by business coupling and failure semantics.
- [ ] RPC callers state what happens when the callee fails.
- [ ] Message consumers survive duplicates, lag and reordering.
- [ ] No REST resource exposes aggregate internals.
- [ ] Each event type records carry-data or query-back.
- [ ] Contracts are separate from internal models and tested at the boundary.

## Related

`ddd-distilled-context-translation`; `ddd-distilled-domain-events`; `ddd-distilled-cross-aggregate-consistency` for the eventual consistency a message creates; `ddd-distilled-integration-reviewer` to review a diff.

## Source

- `Integration Style Rules`
- `Architecture and Infrastructure Rules`: only the rules to keep REST resources and transport formats out of the model and to translate at the boundary.
