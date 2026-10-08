---
name: data-and-objects
description: "Use when designing or reviewing what a type exposes: getter and setter pairs, call chains through several objects, DTOs, or types that are half data and half behavior. Decides object versus data carrier and hides representation."
---

# Data and objects

Decides, for each type, whether it is an object (behavior exposed, representation hidden) or a data carrier (representation exposed, no business behavior), and keeps that choice visible in its surface. Size and responsibility of the class are `/clean-code:class-design`; vendor types are `/clean-code:boundaries`.

## When to use

- A class has a getter and a setter for every field.
- You see `order.getCustomer().getAddress().getCountry()` or similar chains.
- A type carries both persisted fields and business rules, and callers reach into the fields anyway.
- You add a DTO, a request model, a database row type or a view model.

## Rules

1. **Separate behavior-rich objects from plain data carriers intentionally.** Decide per type which it is. Check: you can state "this type is a data carrier" or "this type is an object" in one phrase.
2. **Do not mix data containers and business behavior arbitrarily.** A hybrid with public fields and a few rules invites callers to bypass the rules. Check: if a type has rules, its fields are not freely writable from outside.
3. **Hide implementation details behind clear interfaces.** Callers depend on what the type does, not on how it stores state. Check: you could change the field layout or a collection type without touching callers.
4. **Expose behavior, not representation.** A getter and setter per field exposes the representation by another door. Check: the public methods are named after domain actions (`approve()`, `isOverdue()`), not after fields.
5. **Use DTO-like structures as simple carriers when appropriate.** At wire, storage and view boundaries a dumb record is the right shape. Check: the DTO has no business rules, no lazy loading, no hidden side effects.
6. **Avoid train-wreck call chains and unnecessary knowledge of internal structure.** If the caller navigates through several objects to make a decision, the first object should offer the question. Check: no expression of the form `a.b().c().d()` that asks and then decides; chains over plain data carriers or fluent builders are not the problem.
7. **Tell objects what you need rather than pulling their parts out.** Move the decision to the object that owns the data. Check: the caller does not branch on values it fetched from the receiver.
8. **Respect loose coupling and local boundaries.** A caller should know the types it talks to, not the types they hold. Check: the import list of the caller does not contain types it never names in its own code.
9. **Choose the shape by the likely axis of change.** Added judgment, consistent with keeping likely changes local: if new operations on a stable set of cases are likely, plain data plus functions is easier to extend; if new kinds of the same thing are likely, objects with polymorphic behavior are easier. Check: the next two requirements you can foresee do not force edits in many files.
10. **Do not let persistence, framework or third-party details obscure business behavior.** An entity carrying ORM annotations, serialization hooks and rules is hard to read. Check: business methods read without framework vocabulary; see `/clean-code:boundaries` for the adapter move.

## Procedure

1. List the types in the touched code and label each object, data carrier or hybrid.
2. For each hybrid, decide which side it belongs to. If it carries rules, move the rules in and close the fields. If it carries none, remove the pretense of behavior.
3. Replace each getter chain used for a decision with one method on the first object, named for the decision.
4. For DTOs, move any rule found in them to the object that should own it, and convert at the boundary.
5. Search for callers of each getter/setter you plan to remove; migrate one caller at a time and run the tests.

## Example

```ts
// Before: the caller digs through the structure and makes the decision itself
if (order.getCustomer().getAddress().getCountry().getCode() === "DE"
    && order.getTotal() > 5000) {
  applyDomesticFreeShipping(order);
}

// After: the order answers the question in its own terms
if (order.qualifiesForFreeDomesticShipping()) {
  applyDomesticFreeShipping(order);
}

class Order {
  qualifiesForFreeDomesticShipping(): boolean {
    return this.shipsDomestically() && this.total.isAbove(FREE_SHIPPING_THRESHOLD);
  }
  private shipsDomestically(): boolean {
    return this.customer.livesIn(HOME_COUNTRY);
  }
}
```

The caller no longer knows that customers have addresses, addresses have countries, or countries have codes. The decision lives next to the data it uses.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Train wreck | Three or more chained calls whose result is used in a condition | Ask the first object a domain question instead |
| Getter/setter mirror | One accessor pair per field, no other methods | Replace with intention-revealing methods, or accept it is a data carrier and say so |
| Hybrid | Public mutable fields and business methods on one type | Choose a side |
| Smart DTO | Rules, lazy loading or I/O on a transport or storage record | Move behavior into the domain object; keep the DTO dumb |
| Leaky collection | A getter returning the internal mutable list | Return a copy, a read-only view, or expose the operations |
| Framework-shaped entity | Business class dominated by annotations and persistence hooks | Separate the persistence mapping from the behavior |

## Trade-offs and exceptions

- Traversing a pure data structure (parsed JSON, a configuration tree, a fluent builder) is not a train wreck. The smell is a decision made across behavior-rich objects.
- A data carrier with public fields is the right design for records, value tuples and serialized messages; do not wrap them in behavior to look "object oriented".
- Procedural code over data structures is a legitimate choice when operations change more often than the set of cases. This book's rule is to choose intentionally, not to make everything an object.
- Moving a decision into an object can pull a dependency with it; if that inverts a layer, use the existing boundary instead (`/clean-code:boundaries`).

## Verification

- [ ] Each touched type is labeled object or data carrier, and its surface matches the label.
- [ ] No touched expression asks several objects in a row and then decides.
- [ ] No data carrier contains business rules and no object exposes mutable internals.
- [ ] Callers did not need new knowledge of the receiver's structure to compile.
- [ ] The tests pass after each caller migration.

## Related

`/clean-code:class-design` for size and cohesion; `/clean-code:boundaries` for vendor and framework types; `/clean-code:smells-coupling` for change that spreads; `clean-code:object-design-reviewer` to review a diff.

## Source

- `Objects, modules, and data structures`
- `Smells to detect and eliminate`: only the transitive navigation through object internals smell.
- `Class and module design`: only the rule that likely changes remain local.
