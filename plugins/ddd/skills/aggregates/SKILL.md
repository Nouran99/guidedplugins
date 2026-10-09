---
name: aggregates
description: "Use when deciding what must be consistent together, when a transaction changes several domain objects, when callers mutate a collection inside an object, or when an object holds a live reference to another root. For one object use ddd:entities; for layout ddd:modules-and-associations."
---

# Aggregates

Owns consistency boundaries: an aggregate is drawn around invariants that must hold immediately, it is as small as possible, it is changed only through its root, and it refers to other aggregates by identity unless stronger consistency is truly required. Behavior of one object is `/ddd:entities`; navigation and package layout are `/ddd:modules-and-associations`; reshaping an existing boundary is done by `ddd:aggregate-reshaper`.

## When to use

- A rule spans more than one object ("the order total must stay within the approved limit").
- A service loads several domain objects and saves them in one transaction.
- Callers add to or remove from a collection inside an object, bypassing checks.
- An object holds a full reference to another root, so loading one loads half the database.
- A boundary was chosen to suit the ORM or lazy loading.

## Rules

1. **Aggregates are consistency boundaries, not just object graphs.** Check: you can name the invariant each aggregate protects.
2. **Design aggregates around invariants that must be consistent immediately.** Check: every object inside the boundary participates in one such invariant.
3. **Keep aggregates as small as possible.** Check: removing any member would break an invariant; otherwise it belongs outside.
4. **All modifications that affect aggregate invariants must go through the aggregate root.** Check: no code outside the aggregate holds a reference to an internal member for mutation.
5. **Put invariant-protecting methods on the aggregate root and keep internal members encapsulated.** Check: members are private; reading returns copies or read-only views.
6. **Reference other aggregates by identity unless stronger consistency is truly required.** Check: fields hold identifiers or value types, not live roots.
7. **Keep transactional boundaries aligned with invariants; do not expand transactions across aggregates merely for convenience.** Check: each use case changes one aggregate per transaction, or documents why more.
8. **Handle consistency across aggregate boundaries deliberately when the invariant does not belong inside one aggregate.** Check: the mechanism is chosen and named with the team. This rule set does not prescribe one; `ddd-implementing` covers implementation mechanisms.
9. **Model transactional boundaries deliberately.** Check: the code shows where a transaction starts and which aggregate it covers.
10. **Do not build large-graph aggregates for ORM convenience, expose internal collections for arbitrary external state changes, or modify many aggregates in one transaction because object references make it easy.** Check: no `getItems().add(...)` from outside the root.
11. **Do not confuse parent-child object structure with aggregate boundaries.** A parent holding children in a table does not make them one aggregate. Check: the boundary is justified by an invariant, not by a foreign key.
12. **Expose only aggregate roots to the rest of the model, and prevent partially formed objects from escaping (compact checklist).** Check: repositories return roots (`/ddd:repositories`); factories return valid roots (`/ddd:factories`).

## Procedure

1. List the business rules in the area that must hold at every moment (the invariants), in domain words.
2. Group objects by the invariants they participate in. An object in no invariant is a candidate to live outside.
3. Pick the root for each group: the object through which outside code must go.
4. Make the root's methods enforce the invariants; make members private; replace exposed collections with operations.
5. Replace references to other roots with identifiers (and values copied at the time they were needed).
6. For rules that span aggregates, decide how consistency is reached and write it down; add a test for the behavior when it lags or fails.
7. Run the tests; check that no use case saves several roots in one transaction without a stated reason.

## Example

```ts
// Before: callers push into the collection, and each caller re-checks the limit (or forgets)
order.lines.push(new OrderLine(sku, qty, unitCents));
order.customer.balanceCents -= total;      // a second aggregate changed in the same breath

// After: the root enforces its invariants; the customer is referenced by identity
class OrderLine {
  readonly sku: string;
  readonly quantity: number;
  readonly unitCents: number;

  constructor(sku: string, quantity: number, unitCents: number) {
    if (!Number.isInteger(quantity) || quantity <= 0) throw new RangeError("quantity must be a positive integer");
    this.sku = sku;
    this.quantity = quantity;
    this.unitCents = unitCents;
  }

  get totalCents(): number {
    return this.quantity * this.unitCents;
  }
}

class Order {
  static readonly MAX_LINES = 20;

  readonly id: string;
  readonly customerId: string; // another aggregate, referenced by identity
  private readonly approvedLimitCents: number;
  private readonly _lines: OrderLine[] = [];

  constructor(id: string, customerId: string, approvedLimitCents: number) {
    this.id = id;
    this.customerId = customerId;
    this.approvedLimitCents = approvedLimitCents;
  }

  get lines(): readonly OrderLine[] {
    return [...this._lines];
  }

  get totalCents(): number {
    return this._lines.reduce((sum, line) => sum + line.totalCents, 0);
  }

  addLine(line: OrderLine): void {
    if (this._lines.length >= Order.MAX_LINES) throw new Error("an order holds at most 20 lines");
    if (this.totalCents + line.totalCents > this.approvedLimitCents) {
      throw new Error("the order would exceed the approved limit");
    }
    this._lines.push(line);
  }
}
```

The two invariants (line count, approved limit) are enforced in one place. The customer's balance is now a separate use case and a separate transaction.

## Anti-patterns

- **Object-graph aggregate.** Detect: a root whose reachable graph includes other roots or most of a table family.
- **Exposed collection.** Detect: a getter returning the live internal list.
- **Convenience transaction.** Detect: a use case that saves several roots in one transaction with no stated reason, where the only visible cause is that object references make it easy.
- **Root bypass.** Detect: code that fetches a child and mutates it without going through its root.
- **ORM-shaped boundary.** Detect: a boundary that follows a join or a cascade setting instead of an invariant.

## Trade-offs and exceptions

- The rule is "by identity unless stronger consistency is truly required" and "unless direct object traversal is part of an invariant boundary". Holding a direct reference is allowed inside such a boundary; document the invariant that needs it.
- An invariant that does span roots is a design question. Options include enlarging the aggregate or accepting delayed consistency; this plugin does not choose for the team. Added judgment: prefer to re-examine whether the invariant truly needs immediate consistency before enlarging the aggregate.
- Added judgment: reading across aggregates for reports or screens is not covered by the modification rules; keep read-only queries separate from the model's modification paths.

## Verification

- [ ] Each aggregate's invariant is stated, and every member takes part in one.
- [ ] No external code mutates a member except through the root.
- [ ] References to other roots are identifiers.
- [ ] Each use case changes one aggregate per transaction, or says why not.
- [ ] Tests cover the invariants, including the rejected attempt.

## Related

`/ddd:entities` for the root's own behavior; `/ddd:repositories` for loading and saving roots; `/ddd:factories` for creating valid roots; `/ddd:modules-and-associations` for associations; `ddd:aggregate-reviewer` to review a diff; `ddd:aggregate-reshaper` to redraw a boundary.

## Source

- `Aggregates`
- `Associations and Modules`: only the rule to reference other aggregates by identity unless direct traversal is part of an invariant boundary.
- `Forbidden Patterns`: only the Invalid Construction family (partially initialized aggregates, public state changes that bypass invariants).
