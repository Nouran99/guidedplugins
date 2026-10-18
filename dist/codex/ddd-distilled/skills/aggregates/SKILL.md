---
name: "aggregates"
description: "Use when deciding what belongs in one aggregate, reviewing its size, root access or references, or when an object graph is loaded and changed as a whole. A request changing several aggregates: $ddd-distilled:cross-aggregate-consistency; whether an aggregate is needed: $ddd-distilled:pattern-economy."
---

# Aggregates

An aggregate is a consistency boundary drawn around the objects that must satisfy an invariant together. This skill judges the shape of one aggregate: why its parts are together, how small it is, how it is reached, and how it refers to others. How many aggregates one request may change is `$ddd-distilled:cross-aggregate-consistency`; the entities inside are `$ddd-distilled:entities`.

## When to use

- You are about to add a child collection, a back-reference or another entity to an existing class.
- A class holds direct references to other business objects and loading it pulls in a large graph.
- Callers reach inside an object to change its children.
- A model's shape follows a screen layout or a database join rather than a business rule.

## Rules

1. **Use an aggregate only where an invariant requires a consistency boundary.** Without an invariant, grouping is just convenience. Check: state the invariant in one sentence naming the objects that must be consistent together at the moment of change; no invariant, no aggregate.
2. **Keep aggregates small.** Every object inside widens the loading, locking and contention footprint. Check: list the entity types inside and justify each by the invariant that needs it.
3. **Protect invariants through the aggregate root.** If callers can change inner objects directly, the invariant is advisory. Check: every change enters through a root method, and nothing outside holds an inner object for mutation.
4. **Reference other aggregates by identity.** Object references pull other aggregates into this one's boundary. Check: fields that point to other aggregates are typed as identifiers.
5. **Avoid loading large object graphs.** Check: loading one aggregate does not load others, and no deep lazy chain is walked to make a decision.
6. **Do not create large aggregates to make navigation convenient.** Convenience is not an invariant. Check: for each inner object, name the invariant that needs it; "so the screen can show it" is not one.
7. **Default to smaller boundaries.** (Added judgment: when unsure, split, because merging later is easier than untangling a large aggregate.) Check: the doubtful members are separate aggregates joined by identity.
8. **Do not design an aggregate around a screen.** Screens change with the interface, rules change with the business. Check: the aggregate corresponds to a rule the business states, not to a form.
9. **Do not let one request load and mutate a whole graph.** Check: no use case traverses from one root through several others while changing them; see `$ddd-distilled:cross-aggregate-consistency`.
10. **Do not let the root expose mutable children directly.** Check: collections are returned as copies or read-only views, or not exposed at all.
11. **Test the aggregate for valid and invalid transitions.** Check: at least one test for each invariant, trying to violate it through the root; see `$ddd-distilled:domain-tests`.

## Procedure

1. Write the invariants the business states, one sentence each.
2. For each invariant, list the objects whose state it reads and writes. That set is the candidate boundary.
3. Check each member against rules 2 and 6; move non-essential members out and replace references with identifiers.
4. Make the root the only entry for change and the only owner of the inner collection.
5. Replace exposed child collections with intention-revealing root methods and read-only views.
6. For display needs that cross boundaries, use a separate query, not a bigger aggregate.
7. Add tests that try to break each invariant through the root.

## Example

```java
// Before: the customer graph comes along; callers edit the list and skip the limit
class Shipment {
    private Customer customer;
    private List<Parcel> parcels;
    public List<Parcel> getParcels() { return parcels; }
    public void setParcels(List<Parcel> parcels) { this.parcels = parcels; }
}
// elsewhere
shipment.getParcels().add(parcel);   // the payload limit is never checked

// After: the invariant "total parcel weight never exceeds the payload limit" lives in the root
final class Shipment {
    private final ShipmentId id;
    private final CustomerId customerId;     // identity, not the customer object
    private final Weight payloadLimit;
    private final List<Parcel> parcels = new ArrayList<>();

    Shipment(ShipmentId id, CustomerId customerId, Weight payloadLimit) {
        this.id = id;
        this.customerId = customerId;
        this.payloadLimit = payloadLimit;
    }

    void addParcel(Parcel parcel) {
        Weight total = totalWeight().plus(parcel.weight());
        if (total.isGreaterThan(payloadLimit)) {
            throw new PayloadLimitExceeded(id, payloadLimit);
        }
        parcels.add(parcel);
    }

    Weight totalWeight() {
        return parcels.stream().map(Parcel::weight).reduce(Weight.ZERO, Weight::plus);
    }

    List<Parcel> parcels() {
        return List.copyOf(parcels);
    }
}
```

`Weight` (with `ZERO`, `plus` and `isGreaterThan`), `Parcel`, `ShipmentId`, `CustomerId` and `PayloadLimitExceeded` are assumed types. The customer is reached by identifier through its own aggregate.

## Anti-patterns

- **Screen-shaped aggregate.** Detect: its parts match a form or a page, not a rule.
- **Whole-graph aggregate.** Detect: one class can reach customers, products and invoices by field access.
- **Leaky root.** Detect: `getChildren()` returns the live list, or inner entities have public setters.
- **Invariant-free aggregate.** Detect: you cannot state what must be true together.
- **Everything is a root.** Detect: each table has its own repository, and nothing enforces a rule across rows that the business says must agree.

## Trade-offs and exceptions

- Small does not mean one entity. When several objects must satisfy a rule at the moment of change, they belong together.
- A root with no children is a legitimate aggregate when its invariants are internal.
- Added judgment: loading a large graph is itself a finding under rule 5. Performance numbers do not justify a bigger aggregate; they justify a purpose-made query for reads (`$ddd-distilled:cross-aggregate-consistency` rule 6).
- If the business accepts temporary inconsistency between two objects, they can sit in separate aggregates joined by identity and events (`$ddd-distilled:cross-aggregate-consistency`).
- Repository design for aggregates is not covered by this rule set; the `ddd-implementing` plugin goes deeper.

## Verification

- [ ] Each aggregate has a stated invariant that justifies its members.
- [ ] All changes go through the root; no child is mutated from outside.
- [ ] References to other aggregates are identifiers.
- [ ] The root does not expose live mutable collections.
- [ ] The boundary is not shaped by a screen or a join.
- [ ] Invalid transitions are tested through the root.

## Related

`$ddd-distilled:cross-aggregate-consistency`; `$ddd-distilled:entities`; `$ddd-distilled:pattern-economy`; `ddd-distilled-aggregate-reviewer` to review a diff.

## Source

- `Aggregates`
- `Tactical Pattern Rules`
- `Aggregate Minimalism Rules`
- `Review Rules`: only the aggregates too large item.
- `Testing Rules`: only the rule to test entities and aggregates for valid and invalid transitions.
