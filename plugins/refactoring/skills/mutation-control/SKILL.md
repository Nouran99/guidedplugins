---
name: mutation-control
description: "Use when state is public or changed from many places: exposed fields or collections, needless setters, duplicated update logic, bidirectional links. What others may write; what code reads from ambient state is hidden-dependencies."
---

# Mutation control

Who is allowed to change what, and through which operations. This skill narrows write access, centralizes state transitions, and fixes exposed collections and setters. What a function silently reads from outside is `/refactoring:hidden-dependencies`; building a new type for a concept is `/refactoring:primitive-obsession`.

## When to use

- A field is public, or every field has a setter.
- A getter returns the live internal list or map.
- The same state transition (set status, recalculate totals) is coded in several places.
- Two classes reference each other and keep their references in sync by hand.
- A UI or framework requires a second copy of domain data.

## Rules

1. **Encapsulate mutation.** Check: state changes only through methods of its owner.
2. **Narrow write access to the smallest useful surface.** Check: each field's writers are listed and none is unnecessary.
3. **Replace ad hoc mutations with intention-revealing operations.** `order.status = "shipped"` becomes `order.ship()`. Check: callers state what they want, not which fields to set.
4. **Remove duplicated update logic by centralizing state transitions.** Check: each transition is implemented once.
5. **Prefer immutable intermediate values when that simplifies reasoning.** Check: values that flow between steps are not modified after creation.
6. **Use Self Encapsulate Field when direct field access blocks flexibility.** Check: inside the class, a field that subclasses or later rules need to intercept is read through its accessor.
7. **Use Encapsulate Collection when external mutation can bypass invariants.** Check: the getter returns a read-only view or a copy, and adding or removing goes through methods of the owner.
8. **Use Remove Setting Method when post-construction mutation should not be allowed, and Hide Method when the public surface exposes unnecessary operations.** Check: every public mutator has a caller that needs it.
9. **Use Duplicate Observed Data only when UI or framework synchronization forces it, and keep synchronization explicit.** Check: one side is the source of truth, and the sync code is in one named place.
10. **Use Change Unidirectional Association to Bidirectional only when traversal is needed both ways; use Change Bidirectional Association to Unidirectional when one direction is unnecessary coupling.** Check: every back-reference has a user; the code that maintains both sides lives in one place.
11. **Added judgment: moving a check from callers into the owner is only behavior-preserving if every caller had the check.** A caller that skipped it is a behavior difference to decide separately. Check: you compared all call sites before centralizing.
12. **Added judgment: expose a copy or view, and know which you chose.** A copy is safe from later changes but costs allocation and shows stale data; a read-only view shows live changes. Check: the choice matches what callers did with the list.

## Procedure

1. List the fields and collections of the class and who writes each (search for assignments and mutating calls).
2. Remove setters nobody needs; hide methods nobody outside calls.
3. For each repeated transition, create the intention-revealing method and move the logic into it.
4. For each exposed collection, make the getter read-only and add owner methods for the mutations callers perform.
5. Migrate callers one at a time; run tests after each.
6. Remove the old access path last.

## Example

```java
// Before: the invariant "at most 50 lines" is repeated by every caller
class Cart { public final List<Item> items = new ArrayList<>(); }

// call site A
if (cart.items.size() < 50) cart.items.add(item);
else throw new IllegalStateException("cart is full");
// call site B
if (cart.items.size() < 50) cart.items.add(giftItem);
else throw new IllegalStateException("cart is full");

// After: the owner enforces it once; the collection is no longer open
class Cart {
    private static final int MAX_LINES = 50;
    private final List<Item> items = new ArrayList<>();

    void add(Item item) {
        if (items.size() >= MAX_LINES) throw new IllegalStateException("cart is full");
        items.add(item);
    }
    List<Item> items() { return Collections.unmodifiableList(items); }
}
// call sites A and B: cart.add(item); cart.add(giftItem);
```

Both callers had the same check and message, so moving it into `add` preserves behavior. Had call site B lacked the check, centralizing would have changed B and would be a separate decision.

## Anti-patterns

- **Public mutable field.** Detect: a non-private field written outside the class. Treat: encapsulate behind operations.
- **Getter leaks the live list.** Detect: `return items;` of a mutable collection. Treat: Encapsulate Collection.
- **Setter by habit.** Detect: setters with no caller or called only right after construction. Treat: Remove Setting Method, take values in the constructor.
- **Transition copy-paste.** Detect: the same status change plus side steps in several methods. Treat: one operation that owns it.
- **Hand-synced pair.** Detect: two methods that must always be called together to keep a link consistent. Treat: one method that updates both sides.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Plain data carriers that exist to be filled and passed may keep public fields in languages and codebases where that is the idiom; follow the repository (priority order in `/refactoring:principles`). (Added judgment)
- Immutability is preferred where it simplifies reasoning, not at any cost; a hot loop may need an in-place update (Added judgment).
- Duplicated observed data is allowed when a UI or framework forces it; the rule is to keep the synchronization explicit.
- Frameworks that set fields by reflection may need setters or no-argument constructors; keep what the framework needs and no more. (Added judgment)

## Verification

- [ ] Every mutable field has a named owner and a known list of writers.
- [ ] No getter returns a live mutable collection unless that was a decision.
- [ ] Each state transition is implemented once.
- [ ] Every remaining public mutator has a caller that needs it.
- [ ] Tests passed after each caller migrated; behavior of every call site is unchanged.

## Related

`/refactoring:hidden-dependencies` for reads of ambient state; `/refactoring:primitive-obsession` for immutable value types; `/refactoring:ownership` for where an operation belongs; `refactoring:mutation-reviewer` to list the mutation surface of a diff.

## Source

- `Data and Mutation Rules`
- `Data Refactorings`: only the rule to encapsulate mutable state.
- `Organizing Data`: Self Encapsulate Field, Duplicate Observed Data, Encapsulate Collection and both association-direction changes.
- `Simplifying Calls and Conditionals`: only Remove Setting Method and Hide Method.
