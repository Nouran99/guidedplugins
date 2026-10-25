---
name: "clean-architecture-service-sprawl"
description: "Use when a *Service, *Manager or *Helper class keeps growing, owns unrelated use cases, or creates, fetches, validates, persists, publishes and presents in one place. Covers splitting god services by use case. Shared modules are shared-code-coupling; interface and subtype design is solid-design."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Service sprawl

Owns one failure: a single class that has become the home of every operation near an entity. Where code from different actors is merged into a shared module or base class is `clean-architecture-shared-code-coupling`; the general design principles are `clean-architecture-solid-design`; the shape of one good action is `clean-architecture-use-cases`.

## When to use

- A class named after an entity plus `Service` (`OrderService`, `UserManager`) has methods for unrelated actions.
- A constructor takes a long list of collaborators, and each method uses only a few.
- A change for one stakeholder keeps touching a class that another stakeholder's feature also depends on.
- A reviewer cannot say in one sentence what the class is for.

## Rules

1. **Do not keep an oversized `*Service` that creates, fetches, validates, stores, publishes and presents on its own.** `[MUST NOT]` unless explicitly required and justified. Check: list the verbs in the class's public methods; more than one unrelated verb family means it is a god service.
2. **Do not keep services that own unrelated use cases.** `[MUST NOT]` Check: for any two public methods, ask whether one could change without the other being affected; if yes, they are different use cases.
3. **Do not let application services become dumping grounds.** `[MUST NOT]` Check: new behavior is added by creating a use case, not by appending a method to the nearest class.
4. **Break up god services by use case, and give each use case one clear application action.** `[MUST]` Check: after the split, each class has one public entry point named with an action verb.
5. **Justify any class named `Service`.** `[MUST]` Say why it is not a use case, an adapter or a domain object. Check: write the justification as one sentence in the review; if you cannot, split or rename.
6. **Apply SRP: keep code that changes for different actors or reasons apart.** `[MUST]` Check: for each method, name who would ask for a change; methods with different requesters belong in different classes.
7. **Do not combine unrelated use cases because operational wiring is easier.** `[MUST NOT]` A single class that exists only to keep the constructor call in one place is a wiring convenience, not a design. Check: each class's constructor lists only the ports its action needs.
8. **Leave business rules in entities when you split.** `[MUST]` Extract domain logic first (`clean-architecture-inward-refactoring`); the use cases that remain only coordinate. Check: the new use cases hold few conditionals on business fields.
9. **Name the pieces with action verbs from the application.** `[MUST]` `CancelOrder`, `RefundOrder`, `ExportMonthlyOrders`. Check: no new class is named `OrderHelper` or `OrderProcessor`.
10. **Use size and fan-in as search aids only.** Added judgment: a class with many public methods, a constructor with many collaborators, or methods that share no fields are candidates worth reading. These are not rules of the source, and no number replaces reading the class.
11. **Split along collaborator clusters.** Added judgment: group the methods by the ports and entities they use; each group that shares a distinct set is a candidate use case. Check: the groups need different constructor parameters.

## Procedure

1. List every public method of the class and its caller (controller, job, other service).
2. Group the methods by action and by collaborators (rule 11); name each group with a verb phrase.
3. Pick the group with the clearest boundary and the best test coverage. Create its use case class with only the ports it uses; move the method body across; keep a thin delegating method in the old class if callers cannot change in this step.
4. Move business rules that were in the method into an entity (`clean-architecture-entities-and-invariants`).
5. Update callers to the new use case; remove the delegating method; run the tests.
6. Repeat for the next group. Stop when the old class is empty and delete it, or when what remains has a one-sentence justification.

## Example

```java
// Before: one class owns every action on orders
public class OrderService {
    public Order place(Cart cart, PaymentDetails pay) { /* ... */ return null; }
    public void cancel(long orderId, String reason) { /* ... */ }
    public RefundReceipt refund(long orderId, Money amount) { /* ... */ return null; }
    public byte[] exportMonthlyCsv(YearMonth month) { /* ... */ return null; }
    public void resendConfirmation(long orderId) { /* ... */ }
}
```

```java
// After: one class per action, each with only the ports it needs
public final class CancelOrder {
    private final OrderStore orders;

    public CancelOrder(OrderStore orders) {
        this.orders = orders;
    }

    public void execute(CancelOrderRequest request) {
        Order order = orders.require(request.orderId());
        order.cancel(request.reason());   // the rule about what may be cancelled is in the entity
        orders.save(order);
    }
}

public final class RefundOrder {
    private final OrderStore orders;
    private final PaymentGateway payments;

    public RefundOrder(OrderStore orders, PaymentGateway payments) {
        this.orders = orders;
        this.payments = payments;
    }

    public RefundResponse execute(RefundOrderRequest request) {
        Order order = orders.require(request.orderId());
        Money refundable = order.refundableAmount(request.amount());
        RefundReceipt receipt = payments.refund(order.paymentRef(), refundable);
        order.recordRefund(receipt);
        orders.save(order);
        return new RefundResponse(receipt.id(), refundable);
    }
}
```

`PlaceOrder`, `ExportMonthlyOrders` and `ResendOrderConfirmation` follow the same pattern. Refund changes (a finance concern) no longer touch the code that cancels orders, and `CancelOrder` can be tested without a payment gateway fake.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Entity-plus-Service | A class named after one entity holding all operations on it | One use case per operation |
| Mode parameter | A method taking a `type` or `mode` argument that switches between actions | Split into separate use cases |
| Manager and Helper | Names that describe nothing | Rename by action or role |
| Wiring convenience | A class existing only to hold many collaborators together | Inject each use case with its own ports |
| Facade of pass-throughs | A service forwarding to other services without adding behavior | Let callers use the real use cases |
| Appendable class | Reviewers routinely say "just add it to the service" | Create the use case instead |

## Trade-offs and exceptions

- The source does not forbid the word "Service"; it requires a justification. A domain service holding a rule that spans several entities is legitimate. Added judgment: name it for the rule (`LateFeePolicy`) rather than `Service`.
- The split is by "one clear application action", not by line count. Do not shatter one coherent action into several tiny classes just to make files small.
- Splitting costs files and constructor wiring. A small application with two or three trivial operations on one entity may not need it; say so and move on (`clean-architecture-boundary-economics`).
- Changing public class names or endpoints that others call is a compatibility decision; keep delegating methods until callers move.

## Verification

- [ ] Each resulting class has one entry point named with an action verb.
- [ ] Each constructor lists only the ports its action needs.
- [ ] Business rules moved into entities, and the use cases coordinate.
- [ ] No class named `Service` remains without a one-sentence justification.
- [ ] Callers were moved one at a time and the tests pass after each.
- [ ] No behavior changed in the split.

## Related

`clean-architecture-use-cases` for the target shape; `/clean-architecture:extract-use-case` to perform one extraction; `clean-architecture-shared-code-coupling` for shared modules; `clean-architecture-sprawl-reviewer` to review a tree.

## Source

- `God Services`
- `Naming Rules`: only the rules on action verbs for use cases and on justifying a class named Service.
- `Refactoring Rules`: only the rules on moving business rules inward and breaking up god services.
- `Non-Negotiable Rules`: rules 8 and 9, one application action per use case and entities guarding rules.
- `Paradigm and Component Rules`: only SRP, separating code that changes for different actors or reasons.
- `Boundary Cost, Deployment, and Operations`: only the rule against combining unrelated use cases for operational convenience.
