---
name: smells-coupling
description: "Use when one requirement edits many files, a base class mentions its subclasses, unrelated concepts share a type or constant, or the same type switch repeats. Judges dependencies between classes and files; one class's size or cohesion is /clean-code:class-design."
---

# Coupling smells

The general-design family about where things are placed and what depends on what: coupling that spreads change, artificial coupling, base classes that know their derivatives, code at the wrong level of abstraction, and conditionals that should be isolated or polymorphic. Waste that can simply be deleted is `/clean-code:smells-redundancy`; the size and cohesion of a single class is `/clean-code:class-design`.

## When to use

- A small requirement forces edits in five or more places.
- A shared enum, constants file or utility class is imported everywhere and grows with each feature.
- A base class refers to a subclass by name, or tests the runtime type of `this`.
- A high-level policy sits in a low-level class, or low-level detail sits in a high-level one.
- The same `switch` or `if` chain on a type or kind appears in several functions.

## Rules

1. **Organize code so likely changes remain local.** Take a plausible next requirement and list the files it would touch. Check: the list is short and each file's change is for one reason.
2. **Avoid coupling that spreads change broadly.** Dependencies should point at stable concepts. Check: a change to one module's internals does not force recompiling or editing unrelated modules; shared constants are scoped to their users.
3. **Do not create artificial coupling between unrelated concepts.** Putting a general-purpose constant or enum inside a specific class because it was handy ties unrelated code to that class. Check: every import has a reason in the importer's own domain.
4. **A base class must not depend on its derivatives.** The parent should work without knowing which children exist. Check: search the base file for subclass names, downcasts or runtime type tests.
5. **Keep code at the right level of abstraction.** General rules and policy go up; specific details go down. Check: each method in a base type makes sense for every subtype; details that apply to one subtype live in that subtype.
6. **Isolate excessive conditionals, and make repeated ones polymorphic.** Give a compound condition a named predicate. When the same discriminator is switched in several places, put the behavior with the type, or in a lookup table. Check: adding a new kind edits one new class or one table row, not every switch.
7. **Respect loose coupling and local boundaries.** Depend on the narrowest thing you need. Check: parameters are the smallest type that offers what the function uses.
8. **Prefer composition over complex inheritance unless inheritance is clearly the simpler and more stable model.** Check: shared behavior reaches subtypes through a collaborator when the hierarchy would otherwise need overrides that disable behavior.
9. **Make dependencies explicit.** Added judgment, following from local reasoning: reach for the collaborator through the constructor or parameters, not through globals or ambient singletons, so the coupling is visible in the signature. Check: no function uses a dependency that does not appear in its signature or its object's fields.

## Procedure

1. Choose one or two realistic next changes in the touched area.
2. For each, list every file and function that would change. That is your coupling map.
3. Look for the cause: a repeated switch, a leaked detail, a shared constant, a base that knows its children, a misplaced responsibility.
4. Pick the smallest move that localizes the change: move a method to the type that owns the data, replace a switch with polymorphism or a table, move a constant next to its only user, push a specific detail down.
5. Apply one move per step; run the tests after each.
6. Recompute the coupling map; stop when the next change is local.

Detection recipes (read-only):

- Spread: `git log --stat` for past changes of the same kind; count files touched per feature.
- Base-on-derivative: search the base class file for subclass names and `instanceof`/`is`/type switches on `this`.
- Repeated conditionals: search for the same enum or string constant across files in `case` or `==` positions.
- Artificial coupling: list imports whose importer does not otherwise use that module.

## Example

```ts
// Before: three functions switch on carrier; adding a carrier edits all three
function shippingLabel(s: Shipment): string {
  switch (s.carrier) {
    case "post":  return `POST ${s.zip}`;
    case "courier": return `CRR ${s.zip}-${s.slot}`;
    default: throw new Error(`unknown carrier ${s.carrier}`);
  }
}
function trackingUrl(s: Shipment): string { switch (s.carrier) { /* ... */ } }
function maxWeightKg(s: Shipment): number { switch (s.carrier) { /* ... */ } }

// After: one place per carrier; one lookup remains, at the point of selection
interface Carrier {
  label(s: Shipment): string;
  trackingUrl(s: Shipment): string;
  maxWeightKg: number;
}
const carriers: Record<CarrierKind, Carrier> = {
  post:    { label: s => `POST ${s.zip}`, trackingUrl: s => postUrl(s), maxWeightKg: 20 },
  courier: { label: s => `CRR ${s.zip}-${s.slot}`, trackingUrl: s => courierUrl(s), maxWeightKg: 30 },
};
const carrierFor = (s: Shipment): Carrier => carriers[s.carrier];
```

A new carrier is one more entry. The table is also a data-driven alternative to class-per-kind polymorphism when the behaviors are small.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Shotgun change | One requirement touches many files | Move the scattered rule to one owner |
| Repeated type switch | Same discriminator in several functions | Polymorphism or lookup table; keep one selection point (a creating switch or a table lookup) |
| God constants | One file of constants imported everywhere | Move each constant beside its users |
| Base knows children | Base file names subclasses or tests runtime type | Move the behavior down; use an abstract method |
| Misplaced detail | A base or high-level type contains a rule only one subtype uses | Push down |
| Inappropriate import | Importer uses nothing else from the module | Move the symbol to a neutral place or its true owner |
| Ambient dependency | Function reads a global or singleton not in its signature | Pass it in |
| Deep inheritance | Several levels with overrides that disable behavior | Composition |

## Trade-offs and exceptions

- A single switch or table lookup that selects or creates the right object is acceptable: the conditional is isolated at the edge and hidden behind polymorphism.
- Some coupling is the design: a feature module is allowed to know its own helpers.
- Polymorphism has a cost in navigation; for two or three small cases a table or a plain `if` may be clearer. Weigh reading cost against the chance of new kinds.
- A software-design plugin may prefer fewer, deeper modules over extra types for each case; keep the table or the type only if it localizes change.
- Do not restructure beyond the touched area just to complete a coupling map; record the finding instead.

## Verification

- [ ] The next plausible change touches one place in the touched area.
- [ ] No base type mentions a derivative.
- [ ] No discriminator is switched in more than one function without a recorded reason.
- [ ] Every import in touched files has a reason in its domain.
- [ ] Dependencies appear in signatures or fields.
- [ ] The tests pass after each move.

## Related

`/clean-code:class-design` for responsibilities; `/clean-code:data-and-objects` for chains and exposure; `/clean-code:smells-redundancy` for waste; `clean-code:class-design-reviewer` to review a diff.

## Source

- `Smells to detect and eliminate`: the coupling that spreads change, artificial coupling, base class depending on derivatives, wrong abstraction level and excessive conditional smells.
- `Class and module design`
- `Objects, modules, and data structures`: only the rule to respect loose coupling and local boundaries.
