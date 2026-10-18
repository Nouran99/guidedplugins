---
name: "refactoring-guru-data-smells"
description: "Use when primitives, arrays or magic numbers stand in for concepts, a signature has more than three or four parameters, or the same group of values travels together (primitive obsession, parameter list, data clumps). Diagnosis and choice; mechanics are in organizing-data and method-call-moves."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Data smells

Owns three Bloaters that concern how data is represented and passed: Primitive Obsession, Long Parameter List and Data Clumps. The decision it makes is whether a concept exists and which smallest treatment names it. Performing the type or signature change is `refactoring-guru-organizing-data` or `refactoring-guru-method-call-moves`.

## When to use

- Strings, numbers, constants or arrays carry domain meaning: an identifier, an amount with a currency, a status code, a record whose fields are positional.
- A method needs more than three or four parameters, or callers must memorize the order.
- The same group of values appears in several signatures, several classes' fields, or repeated call sites.
- A review comment says "this should be a type" or "what is the third argument?".

## Rules

1. **Replace repeated primitive values with small objects that carry meaning and validation** (`SHOULD`). A value checked in many places will be checked wrongly in one. Check: the validation that used to be repeated now exists once, at construction.
2. **Use Replace Data Value with Object for a single primitive that has domain behavior or constraints** (`SHOULD`). Check: you can list the constraint or behavior that justifies the type.
3. **Use Replace Array with Object when array positions have named meaning** (`SHOULD`), and Replace Magic Number with Symbolic Constant when a literal carries domain meaning (`SHOULD`). Check: no reader needs to know that index 2 means "currency".
4. **When a code controls behavior, use Replace Type Code with a class, subclasses or state/strategy** (`SHOULD`), as the fallback rung. Doing so before the variation is stable is the risky rung. Decisions among those options are in `refactoring-guru-type-codes-and-switches`. Check: you can name the stable set of variants.
5. **Do not wrap primitives in new types when the wrapper adds no name, validation, behavior or error prevention** (`MUST NOT`). Check: the new type has at least one rule or behavior that the primitive could not carry.
6. **Treat a signature as a long parameter list when it needs more than three or four parameters, or when callers must memorize argument order.** Check: count, and read three call sites aloud.
7. **If a parameter can be derived by the callee, use Replace Parameter with Method Call; if several values come from one object, use Preserve Whole Object** (both `SHOULD`, both the preferred rung). Check: after the change, callers pass less and the callee depends on nothing new that is surprising.
8. **Introduce a parameter object only when the parameters form a recurring concept** (`SHOULD`), as the fallback rung. Check: the object has a name from the domain and at least two call sites.
9. **Do not remove parameters when doing so creates an unwanted dependency between classes** (`MUST NOT`). Check: no class gained a reference to a collaborator it did not know before.
10. **For Data Clumps, test whether the values still make sense if one member is removed; if not, model the group** (`SHOULD`). Use Extract Class for repeated field groups and Introduce Parameter Object for repeated parameter groups. Check: the test was applied to each candidate group and its result is stated.
11. **Move behavior that uses the clump onto the new object when appropriate** (`SHOULD`), and pass the whole object when methods keep receiving pieces of the same concept (`SHOULD`). Do not pass a whole object if that creates an undesirable dependency on a much larger collaborator (`MUST NOT`). Check: the receiving methods now depend on the small new type, not on a big owner.
12. **Do not create a parameter object from unrelated arguments just to shorten a signature** (`MUST NOT`). Check: the object's name is not `Options`, `Params`, `Args` or `Context`, and its fields share one concept.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Primitive Obsession | Replace Data Value with Object, Replace Magic Number with Symbolic Constant, Replace Array with Object | Type-code refactorings when behavior varies by code | Type code to subclasses or state/strategy before variation is stable |
| Long Parameter List | Replace Parameter with Method Call, Preserve Whole Object | Introduce Parameter Object | Removing parameters by creating hidden object dependencies |
| Data Clumps | Extract Class, Introduce Parameter Object | Preserve Whole Object | Passing a large owner object merely to avoid a parameter list |

## Procedure

1. Collect candidates: primitives with domain meaning, signatures over the threshold, groups that repeat. Added judgment: search for the same two or three parameter names appearing together in several signatures.
2. For each, apply the matching test (rules 1 to 3, 6, 10) and discard those that are only shape.
3. Pick the preferred rung; check that it creates no new dependency (rules 9, 11).
4. For a new type, hand off to `refactoring-guru-organizing-data` (define meaning, equality, validation first) or to `refactoring-guru-method-call-moves` for the signature change.
5. Run the tests after each type introduced; migrate call sites one at a time.

## Example

`check_in` and `check_out` travel together through two functions and the ordering rule is checked nowhere. The group fails the removal test: a stay without an end is not a stay.

```python
from dataclasses import dataclass
from datetime import date

# Before
def nightly_total(check_in, check_out, rate):
    return (check_out - check_in).days * rate

def overlaps(a_in, a_out, b_in, b_out):
    return a_in < b_out and b_in < a_out

# After
@dataclass(frozen=True)
class StayPeriod:
    check_in: date
    check_out: date

    def __post_init__(self):
        if self.check_out <= self.check_in:
            raise ValueError("check_out must be after check_in")

    @property
    def nights(self) -> int:
        return (self.check_out - self.check_in).days

    def overlaps(self, other: "StayPeriod") -> bool:
        return self.check_in < other.check_out and other.check_in < self.check_out

def nightly_total(stay: StayPeriod, rate: float) -> float:
    return stay.nights * rate
```

The type adds a name, a validation and behavior, so it passes rule 5. Note the validation is new behavior for inputs that were previously accepted silently; introduce it as its own step if any existing caller passes equal dates.

## Anti-patterns

- **Wrapper without meaning.** `UserId(str)` with no validation or behavior. Detect: the type is only constructed and unwrapped.
- **Bag of options.** One object for unrelated knobs. Detect: fields change for different reasons; the type name is generic.
- **Owner-object smuggling.** Passing `order` into a function that needs two numbers. Detect: the callee imports a far larger type than it uses.
- **Premature type code.** Subclasses introduced for a status that changes at runtime or has not stabilized. Detect: a variant added or removed in the last few changes.
- **Positional record.** A list or tuple with fixed meaning by index. Detect: `row[3]` outside a loop over homogeneous items.

## Trade-offs and exceptions

- A long parameter list may stay temporarily when removing parameters would create stronger unwanted dependencies; record the reason (see `refactoring-guru-stop-and-defer`).
- Obvious local literals do not need constants; the source's own condition is that the literal carries domain meaning.
- A wrapper type is justified by error prevention alone (two ids of different entities that must not be mixed up).

## Verification

- [ ] Each new type adds a name, validation, behavior or error prevention.
- [ ] No parameter object bundles unrelated arguments.
- [ ] No class gained a new dependency to shorten a signature.
- [ ] Equality, validation and boundary conversion of any new value type were considered before migration.
- [ ] Tests ran after each migrated call site.

## Related

`refactoring-guru-organizing-data` for value types and arrays; `refactoring-guru-method-call-moves` for signature techniques; `refactoring-guru-type-codes-and-switches` for type codes; `refactoring-guru-data-modeling-reviewer` to review a diff; `refactoring-guru-type-introducer` to carry it out.

## Source

- `Bloaters`: only the Primitive Obsession, Long Parameter List and Data Clumps entries.
- `Primitive Obsession`
- `Long Parameter List`
- `Data Clumps`
- `Smell-to-Treatment Priority Map`: only the Primitive Obsession, Long Parameter List and Data Clumps rows.
- `Decision Anti-Patterns`: only the rule on parameter objects built from unrelated arguments.
