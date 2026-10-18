---
name: "ddd-implementing-value-objects"
description: "Use when raw primitives such as strings, numbers, dates or ids carry business meaning, when a small value class is mutable or unvalidated, or when equality of a descriptive type is by identity. Immutable, validated, value-equal types. Identity and life cycle are entities."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Value objects

Owns descriptive concepts defined by their attributes: identifiers, quantities, ranges, names and whole values. Their rules live in the type, they cannot change after construction, and two with the same attributes are equal. Concepts with identity and a life cycle belong to `ddd-implementing-entities`.

## When to use

- A function takes `(checkIn: date, checkOut: date)`, `(amount: number, currency: string)` or several identifiers of the same primitive type.
- The same validation (non-empty, positive, ordered range) is copied in several places.
- A small data class has setters, or its `equals` compares an id.
- Two different identifiers (`MemberId`, `CopyId`) are both plain strings and have been swapped in a call.
- A test builds the same group of primitives in every case.

## Rules

1. **[MUST] Use value objects aggressively where primitives hide meaning.** A bare number says nothing about unit, range or rule. Check: for each primitive in a signature or field, you can say whether it carries a rule or meaning; if it does, it has a type.
2. **[MUST] Make value objects immutable by default.** Check: no setters, no exposed mutable collections or date objects; "changes" return a new value.
3. **[MUST] Validate in construction.** An existing value is a valid value. Check: invalid input fails in the constructor or factory, and no caller checks `isValid()` afterwards.
4. **[MUST] Define equality by value, not identity.** Check: two instances with equal attributes are equal and hash alike, and a test says so.
5. **[MUST] Model local value concepts explicitly instead of passing raw primitives for meaningful identifiers, quantities, ranges, names or descriptive whole values.** Check: identifiers of different concepts have different types; amounts carry unit or currency; ranges are one object, not two parameters.
6. **[MUST] Keep invariant enforcement near the concept itself.** The rule about ordered dates belongs to the date range. Check: removing a validation call from a service does not lose the rule, because the type enforces it.
7. **[MUST] Test value object validation and behavior.** Check: tests cover accepted values, each rejected case, equality and each operation (`ddd-implementing-domain-tests`).
8. **[Added judgment] Put the operations on the value.** `range.overlaps(other)`, `money.plus(other)`, `quantity.isZero()` keep rules next to the data and return new values. Check: no static helper in a `*Utils` class takes only these values.
9. **[Added judgment] Give each value one meaning.** A `Duration` that sometimes counts minutes and sometimes days is two types. Check: the type name plus its factory names state the unit.
10. **[Added judgment] Do not wrap a primitive that carries no rule and no meaning.** The source asks for value objects where primitives hide meaning; a wrapper that only renames a free-text field adds ceremony. Check: each value type enforces a rule or offers behavior (`ddd-implementing-core-domain-focus`).

## Procedure

1. Scan the touched signatures and fields for primitives that travel together (`start`/`end`, `amount`/`currency`) and for several identifiers of one primitive type.
2. For each group or identifier, decide whether it has a rule or a meaning. If yes, name the concept in the ubiquitous language.
3. Create the type with a private constructor and a factory (or constructor) that validates; make fields read-only.
4. Move the scattered validation into it, and add the operations callers keep re-implementing.
5. Introduce the type at the boundary where the primitives enter the model, then thread it inward one signature at a time (`ddd-implementing-value-object-reviewer` lists the candidates).
6. Add the tests from rule 7 and run the full suite after each signature changed.

## Example

```python
# Before: two dates, two counts, one rule copied into every caller
def is_available(room, check_in: date, check_out: date, adults: int, children: int) -> bool:
    if not check_in < check_out:        # also checked, or forgotten, elsewhere
        raise ValueError("bad dates")
    return not room.has_booking_between(check_in, check_out) and adults + children <= room.capacity

# After: the range is a value that cannot be built wrongly
from dataclasses import dataclass
from datetime import date

class InvalidStayPeriod(ValueError):
    pass

@dataclass(frozen=True)
class StayPeriod:
    check_in: date
    check_out: date

    def __post_init__(self):
        if not self.check_in < self.check_out:
            raise InvalidStayPeriod(f"{self.check_in} must be before {self.check_out}")

    @property
    def nights(self) -> int:
        return (self.check_out - self.check_in).days

    def overlaps(self, other: "StayPeriod") -> bool:
        return self.check_in < other.check_out and other.check_in < self.check_out

def is_available(room, stay: StayPeriod, guests: "GuestCount") -> bool:
    return not room.has_booking_overlapping(stay) and guests.total <= room.capacity
```

`@dataclass(frozen=True)` gives immutability and value equality; the ordering rule is stated once, in the type.

## Anti-patterns

- **Primitive obsession.** Identifiers, amounts and ranges as bare strings and numbers. Detect: several parameters of the same primitive type in one signature.
- **Mutable value.** A "value" with setters, or one that exposes a mutable date or list. Detect: `set*` methods or public mutable fields on a descriptive class.
- **Validate-after.** Callers check `isValid()`. Detect: an `isValid` or `validate()` method on a type whose constructor accepts anything.
- **Identity equality.** Two equal values compare unequal. Detect: default `equals` on a class with no override.
- **Utility-class rules.** `DateUtils.isBefore(a, b)` instead of a method on the range. Detect: static helpers taking the same pair of values.

## Trade-offs and exceptions

- Performance-critical paths that allocate very many small values may use primitives with a documented invariant. Added judgment: keep the value object at the model's edge and unwrap inside the hot loop.
- The source says "aggressively where primitives hide meaning", not everywhere; a free-text note or a label with no rule stays a string (rule 10).
- Languages without cheap value types (older Java, some dynamic languages) pay boilerplate for each one; generate or use the language's record or dataclass feature rather than skipping the type.
- A value that grows an identity and a life cycle has become an entity; move it (`ddd-implementing-entities`).

## Verification

- [ ] Every meaningful primitive group in the touched code has a named type.
- [ ] No value type has a setter or exposes mutable state.
- [ ] Invalid input fails at construction, with a test per rejected case.
- [ ] Equality and hashing are by value and tested.
- [ ] Validation that was in callers is now in the type, and the callers no longer repeat it.
- [ ] Identifiers of different concepts are not interchangeable types.

## Related

`ddd-implementing-entities` for identity; `ddd-implementing-aggregate-boundaries` for values inside an aggregate; `ddd-implementing-domain-tests` for value tests; `ddd-implementing-value-object-reviewer` to review a diff.

## Source

- `Entity and Value Object Rules`: only the Value Objects subsection and its required behavior.
- `Value Objects`
- `Testing Rules`: only the rule to test value object validation and behavior.
