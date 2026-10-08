<!-- TEMPLATE: structure only. Real file: plugins/<slug>/skills/<name>/SKILL.md -->
---
name: value-objects
description: "Use when a class models a measurement, identifier, or money-like value, or when equality and mutation bugs involve small data carriers. Covers immutability, equality, and validation at construction."
---

# Value objects

<Scope in one or two sentences, and what this skill deliberately leaves to a sibling skill.>

## When to use

- A type is compared by its fields but mutated in place.
- The same primitive pair (`amount`, `currency`) travels together through many signatures.

## Rules

1. **Make value types immutable.** A mutated value that is shared across callers turns into an action-at-a-distance bug. Check: no setters, no exposed mutable collections.
2. **Define equality by content.** Two values with the same fields are the same value. Check: `equals` and `hashCode` (or the language equivalent) agree with the fields.
3. **Validate once, at construction.** An object that exists is valid. Check: no `isValid()` callers.
4. **Prefer the value type over a primitive when the primitive has rules.** Check: the same regex or range check appears twice.
<!-- at least 8 rules; each = instruction, why in one clause, how to check -->

## Procedure

1. List the primitive groups that always travel together in the changed code.
2. For each, decide whether it has rules or only shape. Only rules justify a type.
3. Introduce the type at the boundary where the primitives enter, then thread it inward.
4. Run the tests after each type introduced.

## Example

```ts
// Before: two primitives, rules scattered
function charge(amount: number, currency: string) { /* ... */ }

// After: rules live with the value
class Money {
  private constructor(readonly cents: number, readonly currency: Currency) {}
  static of(cents: number, currency: Currency): Money {
    if (!Number.isInteger(cents) || cents < 0) throw new RangeError("cents must be a non-negative integer");
    return new Money(cents, currency);
  }
  plus(other: Money): Money { this.assertSame(other); return Money.of(this.cents + other.cents, this.currency); }
  private assertSame(o: Money) { if (o.currency !== this.currency) throw new Error("currency mismatch"); }
}
```

## Anti-patterns

- **Wrapper with getters only.** A type that adds no rules is ceremony. Detect: no validation, no behavior.
- **Mutable "value".** Detect: any setter or `Date`/array field exposed.

## Trade-offs and exceptions

- Hot paths that allocate millions of values may justify primitives plus a documented invariant.

## Verification

- [ ] No setters on the new type.
- [ ] Equality is covered by a test.
- [ ] Construction rejects invalid input in a test.
- [ ] No behavior change outside the touched call sites.

## Related

`/<slug>:<sibling-skill>` for <what it covers>; `<slug>:<sibling-reviewer>` to review the result.

## Source

- `<Upstream section heading>`
