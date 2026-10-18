---
name: "base-patterns"
description: "Use for small supporting patterns: money held in floats, repeated null checks, a global registry or service locator, a shared base class, plug-in selection, an interface beside its implementation, tabular data passed as objects. Wrapping external systems is integration-boundaries."
---

# Base patterns

Applies the small supporting patterns only where a concrete pressure calls for them: Mapper, Layer Supertype, Separated Interface, Registry, Plugin, Value Object, Money, Special Case and Record Set. Wrapping an external system (Gateway) is `$enterprise-patterns:integration-boundaries`; Service Stub is `$enterprise-patterns:testing-by-responsibility`.

## When to use

- Currency amounts are floats, or a split of 100.00 into three parts loses a cent.
- The same `if x is None` branch, with the same default behavior, appears in several callers.
- Code looks up collaborators in a global registry or static accessor.
- A base class is proposed for "all repositories" or "all entities".
- A client imports the package that holds the implementation it only needs an interface of.
- Implementations must be chosen or added without touching core code.
- A report passes lists of objects built from rows that nobody calls methods on.

## Rules

1. **Use a base pattern only for a concrete pressure.** Compact checklist (from `mini.md`): name the pressure in a sentence before adding any of these. A pattern without pressure adds types to read and nothing else. Check: no base pattern exists "for consistency".
2. **Use a Mapper to move data between objects or layers while keeping both sides independent.** Independence between two sides needs a third place that knows both. Check: neither side imports the other; the mapping lives in a third place with one function per direction.
3. **Use a Layer Supertype only when shared layer behavior is real and stable.** A base class that keeps changing forces every subclass to change with it. Check: every member of the base class is used by most subclasses. Added judgment: a base class that has changed in each of the last several features is not stable yet.
4. **Use a Separated Interface when clients should depend on an interface in a different package from implementation details.** A dependency pointing at an implementation ties clients to its details. Check: the interface sits with the client (or in its own package), and the implementation depends on it, never the reverse.
5. **Use a Registry sparingly, for well-known objects, and do not turn it into a global hidden dependency.** Hidden global dependencies hide what a class needs and make tests fragile. Added judgment on the check: business classes receive collaborators through constructors, which the source does not prescribe; it only warns against a global hidden dependency. A registry, if any, is touched only at the entry points or in the wiring.
6. **Use a Value Object for small values where equality by value and immutability simplify the code.** Equality by value and immutability remove a class of aliasing bugs. Check: equality compares fields, there are no setters, and operations return new values.
7. **Use Money for currency amounts so that rounding, currency and arithmetic rules stay explicit.** Floats lose cents, and unspecified rounding becomes a bug. Check: where currency amounts are modeled, there are no floating-point amounts, the currency travels with the amount, adding different currencies fails, and the rounding or allocation rule is named in one place.
8. **Use a Special Case to replace repeated null or exceptional handling with a named object.** One named object replaces every caller repeating the same check. Check: the repeated branch becomes methods on a `GuestCustomer`-style object that callers use without checking.
9. **Use a Plugin when implementations must be selected or extended without changing core code.** The core stays closed to change while implementations vary. Check: the core defines the interface, configuration selects the implementation, and adding one touches no core file.
10. **Use a Record Set when tabular data is the natural interchange shape and object behavior is not needed.** Objects built only to be iterated are cost without behavior. Check: report and grid code passes rows through instead of building a class per row.

## Procedure

1. Name the pressure: lost cents, repeated null branch, hidden global dependency, base class churn, a dependency pointing the wrong way.
2. Match it to one pattern above. If none matches, do not add a pattern.
3. Introduce it at the narrowest point (one value type, one interface) and migrate callers one at a time.
4. Delete what the pattern replaces: the float arithmetic, the null checks, the registry lookups.
5. Run the tests after each step.

## Example

```python
from dataclasses import dataclass

# Before: float money, and a null check repeated in every caller
def split_bill(total: float, people: int) -> list[float]:
    return [round(total / people, 2)] * people          # 100.00 / 3 -> three times 33.33 = 99.99

def label(customer):    return customer.name if customer is not None else "Guest"
def discount(customer): return customer.discount_percent if customer is not None else 0

# After: Money keeps rounding explicit; a Special Case removes the null checks
@dataclass(frozen=True)
class Money:
    cents: int
    currency: str

    def __post_init__(self):
        if not isinstance(self.cents, int):
            raise TypeError("cents must be an int")

    def plus(self, other: "Money") -> "Money":
        if other.currency != self.currency:
            raise ValueError("currency mismatch")
        return Money(self.cents + other.cents, self.currency)

    def allocate(self, parts: int) -> list["Money"]:
        base, remainder = divmod(self.cents, parts)       # the first `remainder` parts get one extra cent
        return [Money(base + (1 if i < remainder else 0), self.currency) for i in range(parts)]

class GuestCustomer:
    name = "Guest"
    discount_percent = 0

def customer_or_guest(found):
    return found if found is not None else GuestCustomer()

# callers: customer = customer_or_guest(repo.find(cid)); customer.name; customer.discount_percent
```

`Money(10000, "EUR").allocate(3)` returns 3334, 3333 and 3333 cents, which add up to the original; the float version silently dropped a cent. After the Special Case, the two `if` branches are gone and the guest behavior lives in one class.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Float money | `float` or `double` for amounts; rounding calls scattered | Money value type |
| Repeated null default | Same `None` branch in many callers | Special Case object |
| Registry as service locator | Business code calls `Registry.get(...)` | Pass dependencies in |
| Speculative supertype | Base class with one subclass or unused members | Remove it |
| Interface beside implementation | Client imports the implementation package | Separated Interface |
| Row objects nobody uses | Classes made from rows only to be iterated | Record Set |

## Trade-offs and exceptions

- The source phrases these patterns as "use X when/for ..." selection conditions, not duties. Float money and a repeated null branch are signals to consider Money and Special Case, not violations; they become findings when a concrete cost (lost cents, a missed branch) can be shown.
- A registry is acceptable for a few genuinely well-known objects at the composition points; the source says "sparingly", not "never".
- A Layer Supertype for identity fields or audit columns is common and fine when it is stable.
- Value Object and Money add types; they pay off when rules (rounding, currency, validation) would otherwise be scattered.
- A Special Case must behave correctly for the exceptional situation; it replaces checks, not decisions the caller still needs to make (for example, refusing a guest checkout is still the caller's rule).

## Verification

- [ ] The pressure for each base pattern is stated in one sentence.
- [ ] No float or double holds money, or the reason is stated; currency is carried.
- [ ] Repeated null defaults have a named object.
- [ ] Business classes get collaborators by construction, not lookup (Added judgment), and no registry is a hidden global.
- [ ] Every member of a layer supertype is used by most subclasses.
- [ ] The tests pass.

## Related

`$enterprise-patterns:integration-boundaries` for Gateway; `$enterprise-patterns:testing-by-responsibility` for Service Stub; `$enterprise-patterns:data-mapper` for the persistence Mapper; `$enterprise-patterns:relational-mapping-structure` for storing values; `enterprise-patterns-base-pattern-reviewer` to review a diff.

## Source

- `Session State and Base Pattern Index`
