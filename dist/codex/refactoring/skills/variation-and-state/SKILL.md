---
name: "variation-and-state"
description: "Use when the same type code, status or mode is switched on in several places, subclasses only override constants, repeated null checks share one meaning, fields are set only on some paths, or creation needs a name. Variation across the code; one local branch is conditionals."
---

# Variation and state

When behavior varies by kind or by phase of an object's life, and the variation is repeated, model it. When it is not repeated, leave the conditional alone. This skill owns the escalation from branching to type codes, subclasses, state, strategy, null objects and factories, and the weird lifecycles that temporary fields reveal. A single local branch structure is `$refactoring:conditionals`; reshaping an existing hierarchy is `$refactoring:inheritance-moves`.

## When to use

- The same `kind`, `type` or `status` is tested by `switch` or `if` chains in two or more functions.
- Adding a new kind means editing every one of those places.
- The same null check and fallback is repeated at many call sites.
- An object has fields that are meaningful only during one operation, or only after a certain call.
- A constructor choice (which subtype to create) is spread across callers.
- Subclasses exist only to override constants or return fixed values.

## Rules

1. **Reduce repeated branching on type or mode when polymorphism, tables, strategies or better data structures fit.** The repetition is the smell, not the keyword. Check: you can list the places that switch on the same discriminator.
2. **Do not replace a single honest conditional with needless indirection.** Check: if the discriminator is switched on in one place, you leave it (and see `$refactoring:conditionals`).
3. **Use Replace Conditional with Polymorphism only when repeated type-based behavior justifies it.** Check: at least two functions branch on the same discriminator today (Added judgment on the count; the source asks for repeated behavior).
4. **Replace Type Code with Class, Subclasses or State/Strategy according to whether behavior varies by type.** A type code with no behavior becomes a class or enum; behavior that varies by fixed kind becomes subclasses; behavior that varies while the object lives becomes state or strategy. Check: you stated which of the three applies.
5. **Use Replace Subclass with Fields when subclass variation is only data.** Check: subclasses that override nothing but constants are collapsed.
6. **Use Introduce Null Object when repeated null behavior has a stable meaning.** Check: the same fallback is applied at three or more call sites (Added judgment on the count), and "absent" has a defined behavior.
7. **Use Replace Constructor with Factory Method when creation intent or subtype selection needs a name.** Check: the choice of subtype is in one named place.
8. **Use Encapsulate Downcast when callers should not own cast details.** Check: no caller casts the result of a call it could have been given in the right type.
9. **Remove fields that exist only for unusual code paths when a separate object or a clearer phase model is better.** Check: no field is null or meaningless in most states of the object.
10. **Prefer modeling states explicitly over half-initialized objects.** Check: an object is usable immediately after construction, and a phase change produces a new object or an explicit state.
11. **Never introduce polymorphism merely to avoid a small local conditional (Never).** Check: see rules 2 and 3.
12. **Added judgment: when moving a switch into classes, put the failure for an unknown kind where kinds are created, and check it preserves the old failure timing.** A late error at the first use becomes an early error at creation. Check: callers that relied on late failure are identified before the move.
13. **When repeated type codes or conditionals grow, decompose intent first (compact checklist).** Check: the local decomposition was tried (`$refactoring:conditionals`) before the modeling step.

## Procedure

1. Search for every place that tests the discriminator; list them and what each does per kind.
2. If there is one place, stop and use `$refactoring:conditionals`. If two or more, continue.
3. Decide the model: class or enum (no behavior), subclasses (fixed kinds), state or strategy (changes over life), table (data only).
4. Introduce the model beside the old code, moving one switch at a time into it; keep the old switch until the last caller is migrated.
5. Put creation in a named factory; decide where an unknown kind fails.
6. Run the tests after each moved switch; delete the type code when unused.

## Example

```python
# Before: the same discriminator is switched on in two functions
def monthly_price(plan):
    if plan.kind == "free": return 0
    if plan.kind == "team": return 12 * plan.seats
    if plan.kind == "enterprise": return plan.negotiated_price
    raise ValueError(plan.kind)

def seat_limit(plan):
    if plan.kind == "free": return 1
    if plan.kind == "team": return plan.seats
    if plan.kind == "enterprise": return None
    raise ValueError(plan.kind)

# After: one class per kind, one factory that owns the unknown-kind failure
class FreePlan:
    def monthly_price(self): return 0
    def seat_limit(self): return 1

class TeamPlan:
    def __init__(self, seats): self.seats = seats
    def monthly_price(self): return 12 * self.seats
    def seat_limit(self): return self.seats

class EnterprisePlan:
    def __init__(self, negotiated_price): self.negotiated_price = negotiated_price
    def monthly_price(self): return self.negotiated_price
    def seat_limit(self): return None

def plan_from_record(rec):
    if rec.kind == "free": return FreePlan()
    if rec.kind == "team": return TeamPlan(rec.seats)
    if rec.kind == "enterprise": return EnterprisePlan(rec.negotiated_price)
    raise ValueError(rec.kind)
```

A new kind now adds one class and one factory line instead of editing every switch. One behavior moved: an unknown kind now fails when the plan is created rather than when it is first priced; check that no caller relied on the later failure.

## Anti-patterns

- **Hierarchy for one switch.** Detect: subclasses created for a single conditional. Treat: inline back to the conditional.
- **Subclass of constants.** Detect: subclasses that override only constants. Treat: Replace Subclass with Fields.
- **Null-check confetti.** Detect: the same `if x is None: use default` at many call sites. Treat: Null Object, if the fallback is stable.
- **Phase fields.** Detect: fields assigned in the middle of a method sequence and read in a later one. Treat: split the phases into separate objects or pass the data explicitly.
- **Scattered construction.** Detect: subtype chosen by an `if` at every creation site. Treat: factory method.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- A table is better than classes when the variation is data only and stable.
- Polymorphism spreads one algorithm across classes; for a small, stable set of kinds that rarely changes, a single switch in one place can be easier to read. (Added judgment)
- A null object can hide a real absence; use it only where "absent" has a stable meaning. (Added judgment)
- Frameworks and serialization may force a type code to remain at the edge; convert at the boundary. (Added judgment)

## Verification

- [ ] The discriminator was switched on in two or more places before the change, or no model was added.
- [ ] Each migrated switch was removed once its last caller moved.
- [ ] Creation and the unknown-kind failure live in one named place, and failure timing was checked.
- [ ] No class exists only to avoid one local conditional.
- [ ] Tests passed after each switch moved; outputs are unchanged.

## Related

`$refactoring:conditionals` for one local branch; `$refactoring:inheritance-moves` for existing hierarchies; `$refactoring:primitive-obsession` for a type code that is just a loaded primitive; `refactoring-conditional-reviewer` to decide whether a branch is fine; `refactoring-conditional-refactorer` to carry out the move.

## Source

- `Switch Statements and Conditionals`
- `Temporary Fields and Weird Lifecycles`
- `Organizing Data`: Replace Type Code with Class, Subclasses or State/Strategy, and Replace Subclass with Fields.
- `Simplifying Calls and Conditionals`: Replace Conditional with Polymorphism, Introduce Null Object, Replace Constructor with Factory Method and Encapsulate Downcast.
- `Rules for Working with Conditionals`: only the rules on repeated branching on type or status and on not introducing polymorphism for a small local conditional.
