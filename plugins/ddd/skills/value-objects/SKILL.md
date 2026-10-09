---
name: value-objects
description: "Use when raw strings, numbers or dates stand for money, ranges, codes or measurements, when one value's validation repeats across handlers, or when a descriptive concept is mutable. Attribute-only concepts; for identity use ddd:entities, for a rule over several values ddd:explicit-concepts."
---

# Value objects

Owns concepts defined by their attributes: immutable, valid from construction, equal by value, carrying their own validation and side-effect-free operations. Objects with identity are `/ddd:entities`; introducing a value type across a large codebase is done by `ddd:value-object-introducer`.

## When to use

- A concept is defined by its attributes rather than identity: a money amount, a date range, a quantity with a unit, an address.
- The concept has validation rules or behavior.
- Passing a primitive would hide meaning: a `string` that is really an email, a `number` that is really a percentage.
- The same check appears in several handlers.
- A "descriptive" class has setters and is mutated after it is shared.

## Rules

1. **Value objects must be immutable by default.** A shared mutated value is action at a distance. Check: no setters and no exposed mutable collections; "change" returns a new value.
2. **Construction must guarantee validity.** An object that exists is valid. Check: invalid input fails in the constructor or factory; no `isValid()` callers.
3. **Equality must be by value, not by identity.** Check: two instances with equal attributes compare equal and hash equally.
4. **Validation for the concept should live inside the value object.** Check: the same rule appears in one place.
5. **Replace primitive obsession aggressively where the concept matters.** Check: signatures carry the named type, not two raw primitives that always travel together.
6. **Use value objects for descriptive concepts whose attributes together carry domain meaning.** Check: you can state what the whole value means in a sentence.
7. **Name value objects after the domain concept, not the primitive representation.** Check: `Percentage`, not `DecimalWrapper`.
8. **Keep validation and side-effect-free operations for the value near the value itself.** Check: arithmetic, comparison and formatting of the concept live in its type.
9. **Replace raw primitives when a named quantity, range, code, measurement or whole value matters to the model**, including raw strings for meaningful identifiers. Check: grep for the same regex or range check finds one definition.
10. **Do not repeat the same value validation across handlers.** Check: handlers call the constructor and handle its failure.
11. **Do not let invalid values exist temporarily without an explicit model for incompleteness.** If a half-filled form is a real state, model it (a draft type); do not smuggle it through a half-valid value. Check: no value type has an "uninitialized" state that callers must remember to check.
12. **Use primitives only when they truly carry no domain meaning.** Check: each remaining primitive in a domain signature has a reason you can state.

## Procedure

1. List primitive parameters, fields and return values in the touched domain code. Group those that always travel together (amount and currency, start and end).
2. For each group or meaningful primitive, ask what the experts call it and what rules it obeys. No rules and no name: leave it a primitive.
3. Write the value type with private construction and validation, equality by value and the operations the callers already perform on the raw data.
4. Introduce it at the boundary where the primitives enter (parse once), then thread it inward one call site at a time.
5. Delete duplicated validation at the call sites.
6. Test construction (valid and invalid), equality and each operation (`/ddd:domain-tests`). Run the whole suite after each type.

## Example

```python
# Before: two datetimes, rules checked in three handlers
def book(room_id, check_in, check_out):
    if check_out <= check_in:
        raise ValueError("bad dates")
    ...

# After: the rule and the operations live in the value
from dataclasses import dataclass
from datetime import date

@dataclass(frozen=True)
class StayPeriod:
    check_in: date
    check_out: date

    def __post_init__(self):
        if self.check_out <= self.check_in:
            raise ValueError("check-out must be after check-in")

    @property
    def nights(self) -> int:
        return (self.check_out - self.check_in).days

    def overlaps(self, other: "StayPeriod") -> bool:
        return self.check_in < other.check_out and other.check_in < self.check_out

def book(room_id: str, stay: StayPeriod):
    ...
```

`StayPeriod` is immutable (`frozen=True`), invalid periods cannot exist, and equality compares both dates.

## Anti-patterns

- **Primitive obsession.** Detect: `str`, `int`, `Decimal` or `datetime` in domain signatures for named quantities, ranges, codes and identifiers.
- **Wrapper with no rules.** Detect: a type that only holds a field and adds neither validation nor behavior; it renames, it does not model.
- **Mutable value.** Detect: setters or a returned internal list or `Date`.
- **Validate-later.** Detect: an `isValid()` or `validate()` call that callers must remember.
- **Repeated check.** Detect: the same regex, range or format test in several files.

## Trade-offs and exceptions

- Primitives are fine when they carry no domain meaning (a page number in a UI layer, a counter).
- Allocation-heavy hot paths may justify primitives with a documented invariant; that is a performance decision, so measure first and keep the value type at the boundary. Added judgment.
- Added judgment: equality by value applies to the concept's attributes; keep non-descriptive technical fields (cache keys) out of the type.

## Verification

- [ ] The value type cannot be constructed invalid, and tests prove it.
- [ ] It has no setters and no exposed mutable parts.
- [ ] Equality and hashing follow the attributes and have a test.
- [ ] The same validation no longer appears elsewhere.
- [ ] The type's name is a domain term.

## Related

`/ddd:entities` for objects with identity; `/ddd:explicit-concepts` for rules that become specifications rather than values; `/ddd:supple-design` for operations that return values of the same type; `ddd:value-object-reviewer` to review a diff; `ddd:value-object-introducer` for a large rollout.

## Source

- `Value Objects`
- `Code Generation Rules`: only the rule to use primitives only when they carry no domain meaning.
