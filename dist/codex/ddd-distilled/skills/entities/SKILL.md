---
name: "entities"
description: "Use when a class has identity and a lifecycle, when public setters let any code change business state, or when an entity is only getters and setters. Covers identity and guarded transitions. Identity-less values: $ddd-distilled:value-objects; pattern undecided: $ddd-distilled:pattern-economy."
---

# Entities

An entity is a thing that stays itself while its state changes, so identity and lifecycle define it. This skill covers explicit identity and the transitions an entity protects. Identity-less values are `$ddd-distilled:value-objects`, the consistency boundary around entities is `$ddd-distilled:aggregates`, logic that has leaked into a service is `$ddd-distilled:application-services`, and choosing between an entity and a cheaper pattern is `$ddd-distilled:pattern-economy`.

## When to use

- A class represents something that is created, changes over time and ends: reservation, shipment, subscription.
- Code elsewhere assigns a status or a field directly, with no check.
- A class has a getter and a setter for every field and a service does all the thinking.
- You doubt whether a type needs identity at all.

## Rules

1. **Use an entity when identity and lifecycle matter.** Otherwise the extra weight buys nothing. Check: two instances with identical attributes are still different things, or the object changes over time while remaining itself.
2. **Give every entity explicit identity.** Equality and references depend on it. Check: a typed identifier (`ReservationId`), assigned at creation and never derived from attributes that can change.
3. **Make the entity protect meaningful state transitions.** The rules about what may happen next belong with the thing that changes. Check: list the allowed transitions; each is one named method, and an invalid move raises a domain error.
4. **Do not expose unrestricted state changes by default.** A public setter lets any caller bypass the rules. Check: no public setter exists on a field that carries business meaning.
5. **Give entities behavior, not only data.** An anemic entity pushes its rules into services. Check: for the entity's central rules, the decision is made by a method on the entity; a review finding is raised for a class that is all accessors.
6. **Name transitions in the ubiquitous language.** `confirm()` says what happened; `setStatus("CONFIRMED")` says nothing. Check: transition method names are business verbs.
7. **Test entities for valid and invalid transitions.** Check: each allowed transition and at least one forbidden one has a test; see `$ddd-distilled:domain-tests`.
8. **Do not give identity to something with no lifecycle.** (Added judgment) A value that nobody asks "which one is it?" about is a value object. Check: the type is never looked up by its identifier.
9. **Create entities in a valid state.** (Added judgment) Check: the constructor or factory takes the required fields; there is no phase where the object exists half-initialized.
10. **Compare entities by identity.** (Added judgment) Check: equality, if defined, uses the id and not mutable attributes.

## Procedure

1. List the types in the change that have a status, a lifecycle or a setter.
2. For each, write its states and the transitions the business allows.
3. Replace each public setter on a business field with a named transition method that checks the current state.
4. Move the decision logic from callers into those methods, one transition at a time (`ddd-distilled-behavior-mover` does this at scale).
5. Add tests for each transition and one invalid attempt.
6. If a transition needs another object to change at the same time, stop and consult `$ddd-distilled:aggregates`.

## Example

```ts
// Before: any code can put the reservation in any state
class Reservation {
  id: string;
  status: string;
  cancelReason?: string;
}
// elsewhere
reservation.status = "CONFIRMED";

// After: identity is explicit and the entity guards its transitions
type ReservationStatus = "requested" | "confirmed" | "cancelled";

class Reservation {
  private status: ReservationStatus = "requested";
  private cancellationReason?: CancellationReason;

  constructor(readonly id: ReservationId, readonly stay: StayPeriod) {}

  confirm(): void {
    if (this.status !== "requested") {
      throw new InvalidTransition(this.id, this.status, "confirm");
    }
    this.status = "confirmed";
  }

  cancel(reason: CancellationReason): void {
    if (this.status === "cancelled") {
      throw new InvalidTransition(this.id, this.status, "cancel");
    }
    this.status = "cancelled";
    this.cancellationReason = reason;
  }

  isConfirmed(): boolean {
    return this.status === "confirmed";
  }
}
```

`ReservationId`, `StayPeriod`, `CancellationReason` and `InvalidTransition` are assumed types. The status is private; callers learn what happened through business verbs.

## Anti-patterns

- **Anemic entity.** Detect: all methods are getters and setters, and a `*Service` class holds the conditionals.
- **Free-for-all setter.** Detect: assignments to business fields from outside the class.
- **Identity from attributes.** Detect: an id built from name and date that can change.
- **Identity everywhere.** Detect: ids on types that are never fetched by id.
- **Status string.** Detect: comparisons against string literals instead of transitions.

## Trade-offs and exceptions

- Simple domains may use simple data structures. A record for reference data does not need guarded transitions (`$ddd-distilled:pattern-economy`).
- A framework may require a no-argument constructor or field access for persistence; keep that in the mapping, not in the public surface of the entity.
- Some transitions are legitimately idempotent. Decide per transition and say so in its test.
- If a rule spans several entities that must change together, the boundary is an aggregate decision, not an entity one.

## Verification

- [ ] Each entity has a typed identity set at creation.
- [ ] No public setter exists for a field with business meaning.
- [ ] Each allowed transition is a named business method that rejects invalid moves.
- [ ] Valid and invalid transitions are tested.
- [ ] No identity was added to something that has no lifecycle.

## Related

`$ddd-distilled:aggregates`; `$ddd-distilled:value-objects`; `$ddd-distilled:application-services`; `$ddd-distilled:pattern-economy`; `$ddd-distilled:domain-tests`; `ddd-distilled-entity-reviewer` to review a diff; `ddd-distilled-behavior-mover` to relocate logic.

## Source

- `Entities`
- `Tactical Pattern Rules`
- `Review Rules`: only the anemic entities item.
- `Testing Rules`: only the rule to test entities and aggregates for valid and invalid transitions.
- `Practicality Rules`: only the rule that simple domains may use simple services and data structures.
