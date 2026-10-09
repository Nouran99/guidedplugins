---
name: value-objects
description: "Use when a primitive or small group of fields (amount and currency, email, date range) is validated or combined in several places. Covers immutable, self-validating values. Flags and status codes: /ddd-distilled:explicit-concepts; pattern undecided: /ddd-distilled:pattern-economy."
---

# Value objects

A value object is defined by its content, not by an identity, and it carries its own rules. This skill covers data values that repeat and hide meaning in primitives. Flags, status codes and decisions hidden in control flow are `/ddd-distilled:explicit-concepts`; things with identity and lifecycle are `/ddd-distilled:entities`; whether a concept should be a value object at all is `/ddd-distilled:pattern-economy`.

## When to use

- The same pair or triple of primitives travels together through several signatures (`amount` and `currency`, `start` and `end`).
- The same regex, range check or rounding rule appears in more than one place.
- A `string` or `number` parameter has units, bounds or a format that readers must remember.
- Money, quantities, percentages, identifiers or periods are added or compared with raw operators.

## Rules

1. **Use value objects aggressively when a primitive hides meaning.** A `number` that is really a price in minor units invites errors the compiler cannot see. Check: parameters named amount, period, email, quantity or percentage are not bare primitives.
2. **Make value objects immutable by default.** A shared value that can change under you is a bug waiting for a caller. Check: no setters, and every operation returns a new value; no mutable collection or date is exposed.
3. **Make them validate themselves.** An instance that exists is valid, so nobody downstream re-checks. Check: construction rejects invalid input; no `isValid()` is called anywhere.
4. **Make them read in domain language.** The operations are named in business terms. Check: `period.overlaps(other)` and `price.reducedBy(discount)` instead of comparisons and arithmetic on raw fields.
5. **Look for a value object wherever a concept repeats.** The Review Rules treat a repeated concept with no value object as a finding, and duplicated checks diverge. Check: where the same validation or formatting appears twice, or two fields always travel together, either a value object exists or rule 9 gives the reason it does not.
6. **Test value objects for validation and behavior.** Check: each invalid input class and each operation has a test; see `/ddd-distilled:domain-tests`.
7. **Compare by value.** (Added judgment) Two values with the same content are the same value. Check: equality and hashing use the content.
8. **Put units and currency in the type.** (Added judgment) A name like `priceInCents` is a unit living in a variable. Check: the unit is part of the value, and operations on mixed units are rejected.
9. **Give a value object a reason to exist.** (Added judgment) A wrapper with only a getter is ceremony, and the Practicality Rules ask for the cheapest honest pattern; the reason is a rule, an operation, or keeping apart values that share a primitive type (typed identifiers, units), which is how a primitive hides meaning. Check: the type validates, computes something, or stops a `CustomerId` from being passed where a `ReservationId` is expected.

## Procedure

1. List primitive groups and repeated checks in the changed code.
2. For each, ask whether it has a rule (bounds, format, unit, rounding) or whether it could be confused with another value of the same primitive type (identifiers, units). If it has only shape and no such risk, leave it.
3. Create the value object at the boundary where the primitives first enter, with validation in its constructor.
4. Move the duplicated checks and arithmetic onto it as named operations.
5. Thread the type inward one call site at a time, running tests after each (`ddd-distilled:value-object-introducer` does this).
6. Delete the old checks.

## Example

```python
# Before: units and bounds are in the reader's head, checks live in the function
def quote(price_minor: int, currency: str, discount_percent: int) -> int:
    if currency not in ("EUR", "USD"):
        raise ValueError("bad currency")
    if price_minor < 0:
        raise ValueError("bad amount")
    if not 0 <= discount_percent <= 100:
        raise ValueError("bad discount")
    return (price_minor * (100 - discount_percent) + 50) // 100   # rounds half up


# After: rules live with the values
from dataclasses import dataclass


@dataclass(frozen=True)
class Percentage:
    value: int  # whole percent

    def __post_init__(self) -> None:
        if not 0 <= self.value <= 100:
            raise ValueError("percentage must be between 0 and 100")


@dataclass(frozen=True)
class Money:
    minor_units: int
    currency: str

    def __post_init__(self) -> None:
        if self.currency not in ("EUR", "USD"):
            raise ValueError(f"unsupported currency: {self.currency}")
        if self.minor_units < 0:
            raise ValueError("amount cannot be negative")

    def reduced_by(self, discount: Percentage) -> "Money":
        # rounds half up, in integer arithmetic
        reduced = (self.minor_units * (100 - discount.value) + 50) // 100
        return Money(reduced, self.currency)


def quote(price: Money, discount: Percentage) -> Money:
    return price.reduced_by(discount)
```

The checks and the half-up rounding moved onto the values unchanged. They are now stated once, in the language of the business, and an invalid percentage cannot reach `quote`.

## Anti-patterns

- **Primitive obsession.** Detect: ids, amounts and periods passed as `string` or `number`.
- **Getter-only wrapper.** Detect: a type with no validation and no behavior that also keeps no two same-typed values apart (a typed identifier is not this).
- **Mutable value.** Detect: setters, or a returned `Date`, array or list that callers can modify.
- **Validation outside.** Detect: `if x is valid` checks in callers.
- **Value with identity.** Detect: an id field on something compared by content.

## Trade-offs and exceptions

- Not every string deserves a type. A free-text note has no rule to protect.
- A hot loop that allocates millions of values may justify primitives plus a documented invariant; measure before deciding. (Added judgment)
- Frameworks may need a mutable shape for binding; keep that at the boundary and convert (`/ddd-distilled:infrastructure-isolation`).
- Immutable by default is a default: a value that is expensive to copy and is built step by step may use a builder, as long as the finished value is immutable.

## Verification

- [ ] No bare primitive stands for a validated business value in the touched signatures.
- [ ] Each value object is immutable and validates on construction.
- [ ] Operations are named in business terms.
- [ ] No duplicated validation remains in callers.
- [ ] Validation and behavior are tested.

## Related

`/ddd-distilled:explicit-concepts`; `/ddd-distilled:entities`; `/ddd-distilled:pattern-economy`; `/ddd-distilled:domain-tests`; `ddd-distilled:concept-reviewer` to find candidates; `ddd-distilled:value-object-introducer` to introduce one.

## Source

- `Value Objects`
- `Tactical Pattern Rules`
- `Review Rules`: only the primitive obsession and no-value-objects-where-concepts-repeat items.
- `Testing Rules`: only the rule to test value objects for validation and behavior.
- `Practicality Rules`: only the rule to use the least expensive pattern that honestly models the problem.
