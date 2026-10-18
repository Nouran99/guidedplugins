---
name: "refactoring-primitive-obsession"
description: "Use when the same primitives travel together or carry rules: ids and codes as strings, parallel fields, positional arrays, magic values. Introduces named types; call shape is call-signatures, which class owns behavior is ownership."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "auto"
---

# Primitive obsession and data clumps

Recurring business concepts deserve names and, where they have rules, validation. This skill finds primitive bundles and loaded primitives and replaces them with types. Reshaping the call that carries them is `refactoring-call-signatures`; controlling who may change them is `refactoring-mutation-control`; deciding which class owns the behavior around them is `refactoring-ownership`.

## When to use

- The same group of fields (street, city, postal code, country) appears in several signatures or classes.
- A string or number carries rules: a code format, a unit, a range, an identity.
- An array or tuple is read by position (`row[0]`, `row[3]`).
- Magic numbers or strings repeat.
- A raw collection or record gains behavior around it.

## Rules

1. **Replace repeated primitive bundles with meaningful types.** Check: no group of three or more primitives travels together through more than one signature or class (the count is Added judgment; the source says only "repeated").
2. **Give recurring business concepts names and validation.** Check: each recurring concept has one definition where its rules live.
3. **Replace magic values with named constants or domain types.** Check: no repeated literal has a meaning that is not named.
4. **Use Replace Data Value with Object when a primitive carries behavior, validation or meaning.** Check: the same regex, range or parsing code is not repeated at several call sites.
5. **Use Replace Array with Object when positions in a collection have names or rules.** Check: no code reads a collection by a numeric index whose meaning is documented only in a comment.
6. **Use Replace Record with Data Class when raw records need named access and behavior can grow safely.** Check: callers use field names, not keys spelled in strings at each site.
7. **Replace raw collections with named abstractions when behavior accumulates around them.** Check: helper functions that take the collection as their first argument are now methods of it.
8. **Use Change Value to Reference when identity and shared updates matter; use Change Reference to Value when value semantics simplify ownership.** Check: you can say whether two instances with equal fields are the same thing, and the type's equality agrees.
9. **Added judgment: a type earns its existence only if it has rules or behavior.** A wrapper that only holds a value is ceremony. Check: the new type has validation, behavior or an invariant, now or in the next step of the plan.
10. **Added judgment: introduce the type at the boundary where the primitives enter and thread it inward.** Check: conversion happens once at the edge; inner code never re-parses the primitive.
11. **Added judgment: introducing validation that rejects previously accepted input is a behavior change.** First create the type with the same acceptance and normalization the callers already had; tighten the rules in a separate, tested step. Check: serialized formats, accepted values and error behavior are the same after the structural step.

## Procedure

1. Search for the repeated bundle or loaded primitive; list every signature, field or class where it appears.
2. Decide whether the bundle is a concept with rules (rule 9). If it is only coincidental, leave it.
3. Write the type with the existing acceptance and normalization (rule 11).
4. Introduce it at the boundary, change one call site, run tests, repeat inward.
5. Move behavior that used to sit around the primitive into the type (`refactoring-ownership`).
6. Only then, in a separate step, tighten validation if wanted.

## Example

```ts
// Before: the same four fields in three signatures; country normalized at each caller
function labelFor(name: string, street: string, city: string, postalCode: string, country: string): string {
  return `${name}\n${street}\n${postalCode} ${city}\n${country.trim().toUpperCase()}`;
}
function taxZoneFor(postalCode: string, country: string): string { /* ... */ return ""; }
function isDomestic(country: string): boolean { return country.trim().toUpperCase() === "DE"; }

// After: one type for the concept, built once at the boundary with the same normalization
class PostalAddress {
  private constructor(
    readonly street: string,
    readonly city: string,
    readonly postalCode: string,
    readonly country: string,
  ) {}
  static of(street: string, city: string, postalCode: string, country: string): PostalAddress {
    return new PostalAddress(street, city, postalCode, country.trim().toUpperCase());
  }
  isDomestic(): boolean { return this.country === "DE"; }
}

function labelFor(name: string, address: PostalAddress): string {
  return `${name}\n${address.street}\n${address.postalCode} ${address.city}\n${address.country}`;
}
```

The new type accepts exactly what the callers accepted. Rejecting malformed countries would be a separate behavior step with its own test.

## Anti-patterns

- **Wrapper with no rules.** Detect: a class with one field and no behavior. Treat: remove it unless a rule is planned.
- **Validation smuggled in.** Detect: a "type introduction" that now throws for input that used to pass. Treat: split into structure, then behavior.
- **Re-parsing inside.** Detect: inner code that splits or parses the same string again. Treat: carry the parsed type inward.
- **Positional record.** Detect: indexes into arrays or tuples with comments. Treat: Replace Array with Object.
- **Shared mutable value.** Detect: two owners mutating one "value". Treat: make it a value (immutable) or give it a single owner.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- A primitive with no rules and one use does not need a type; the source asks for types for recurring concepts.
- Hot paths that allocate many small objects may justify keeping primitives with a documented invariant (Added judgment).
- Language features differ: a type alias or branded type may be enough where it prevents mixing without adding a runtime class. (Added judgment)
- Serialization boundaries (JSON, database columns) keep their wire format; the type converts at the edge. (Added judgment)

## Verification

- [ ] Each introduced type has rules or behavior, and its equality matches its semantics.
- [ ] Conversion happens once at the boundary; inner code does not re-parse.
- [ ] Accepted input, normalization and serialized form are unchanged by the structural step.
- [ ] No bundle remains in more than one signature.
- [ ] Tests passed after each call site was migrated.

## Related

`refactoring-call-signatures` for the calls; `refactoring-mutation-control` for encapsulating the new type's state; `refactoring-ownership` for moving behavior into it; `refactoring-primitive-reviewer` to find missing types in a diff; `refactoring-value-type-introducer` to introduce one.

## Source

- `Data Clumps and Primitive Obsession`
- `Data Refactorings`: only the rules on magic values, parameter objects and raw collections.
- `Organizing Data`: Replace Data Value with Object, Change Value to Reference, Change Reference to Value, Replace Array with Object and Replace Record with Data Class.
