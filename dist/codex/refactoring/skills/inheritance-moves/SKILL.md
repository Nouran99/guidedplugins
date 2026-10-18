---
name: "inheritance-moves"
description: "Use when a hierarchy needs reshaping: duplicated or misplaced superclass members, inheritance used for reuse, empty layers, or two variation axes in one tree. Hierarchy mechanics only; constant-only subclasses are variation-and-state, forwarding layers needless-abstraction, placement ownership."
---

# Inheritance moves

The catalog of moves for hierarchies: pulling up, pushing down, extracting, collapsing, templating, trading inheritance for delegation and back, and separating tangled axes. When behavior varies by kind across the code and no hierarchy exists yet, start with `$refactoring:variation-and-state`; forwarding classes and one-implementation interfaces are `$refactoring:needless-abstraction`; where a method belongs among unrelated peers is `$refactoring:ownership`; subclasses that override nothing but constants (Replace Subclass with Fields) are `$refactoring:variation-and-state`.

## When to use

- Two subclasses repeat the same field or method.
- A superclass member is used by only some subclasses.
- A class extends another only to reuse a few methods, and inherits the rest of its API.
- A hierarchy has a layer that adds nothing, or a subclass adds no behavior and no caller depends on the distinction.
- Class names combine two dimensions (`UrgentEmailReport`, `UrgentPdfReport`, `RoutineEmailReport`, ...).
- Every new subclass in one tree forces a matching subclass in another tree.

## Rules

1. **Use Pull Up Field, Pull Up Method or Pull Up Constructor Body when duplicated superclass behavior is real.** Check: the duplicates are the same knowledge (`$refactoring:duplication`'s sameness test), not look-alikes.
2. **Use Push Down Method or Push Down Field when only some subclasses need the feature.** Check: no subclass inherits a member it never uses.
3. **Use Extract Subclass, Extract Superclass or Extract Interface only when callers or variation points justify them.** Check: you can name the caller that depends on the new type or the variation it captures.
4. **Use Collapse Hierarchy when inheritance no longer adds meaning.** Check: the subclass overrides little or nothing, and no caller depends on the distinction. A subclass that overrides only constants is a data difference: use Replace Subclass with Fields (`$refactoring:variation-and-state`).
5. **Use Form Template Method when similar algorithms differ in controlled steps.** Check: the shared skeleton is in the superclass and the varying steps are named overridable hooks.
6. **Use Replace Inheritance with Delegation when inheritance couples unrelated responsibilities.** Check: the subclass does not satisfy "is a" for every inherited operation.
7. **Use Replace Delegation with Inheritance only when the subtype relationship is genuine and stable (only).** Check: callers could use the delegating class wherever its target is used, and that will stay true.
8. **Use Tease Apart Inheritance when one hierarchy mixes multiple variation axes.** Check: subclass names combine two or more dimensions, or the count grows as a product.
9. **Use Extract Hierarchy when several types share behavior with meaningful variation.** Check: the variation is real and repeated (`$refactoring:variation-and-state`), not a single switch.
10. **Prefer composition of small focused units over god objects, and prefer to avoid introducing a large hierarchy (both Prefer).** Check: a new hierarchy was not introduced where composition would do.
11. **Added judgment: move members one at a time, and rerun tests after each, because moves along a hierarchy change what each class exposes.** Check: after each move, every subclass still compiles and passes.
12. **Added judgment: before Replace Inheritance with Delegation, list which inherited methods callers actually use.** Keep delegating methods for those; remove the rest in a later, separate step. Check: the list was made from usages, not from the superclass API.

## Procedure

1. Draw the hierarchy: classes, which members each defines or overrides, and which callers depend on which type.
2. Find the problem: duplicated members, unused inherited members, empty layers, mixed axes, or inherited API that is too wide.
3. Choose the move from the rules; do it in the smallest possible step (one member, one class).
4. Run the tests after each step; do not combine a pull-up with a rename or a push-down.
5. Re-draw the hierarchy; stop when the remaining structure is justified by callers or real variation.

## Example

```java
// Before: inherits the whole List API but uses only add and iteration
class CsvReport extends ArrayList<Row> {
    String render() {
        StringBuilder sb = new StringBuilder();
        for (Row r : this) sb.append(r.toCsvLine()).append('\n');
        return sb.toString();
    }
}
// callers: report.add(row); report.render();   and one caller: report.size()

// After: delegation; only the operations callers use, then the rest removed
class CsvReport {
    private final List<Row> rows = new ArrayList<>();

    void add(Row row) { rows.add(row); }
    int size() { return rows.size(); }

    String render() {
        StringBuilder sb = new StringBuilder();
        for (Row r : rows) sb.append(r.toCsvLine()).append('\n');
        return sb.toString();
    }
}
```

`size()` is kept because one caller uses it. A `CsvReport` can no longer be passed where a `List<Row>` is expected; the usage search in rule 12 is what shows that no caller does.

## Anti-patterns

- **Inheritance for reuse.** Detect: a subclass that is not substitutable for its parent. Treat: Replace Inheritance with Delegation.
- **Refused bequest.** Detect: subclasses that ignore or throw on inherited members. Treat: Push Down, or delegation.
- **Product-named subclasses.** Detect: one tree whose class names combine two dimensions, or whose class count grows as a product. Treat: Tease Apart Inheritance.
- **Parallel hierarchies.** Detect: every new subclass in one tree needs a sibling in another. Treat: Move Method and Move Field so one tree's instances refer to the other's, then let the redundant tree shrink (`$refactoring:ownership` for the placement test). Added judgment: the source names these moves but does not pair them with this smell.
- **Empty layer.** Detect: a class that only extends and adds nothing. Treat: Collapse Hierarchy.
- **Template by copy.** Detect: two subclasses with the same method skeleton and different inner steps. Treat: Form Template Method.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- The source asks for extractions only when callers or variation points justify them; do not add a superclass because two classes share two fields.
- Replace Delegation with Inheritance is the narrowest move in the list; the default direction is toward composition.
- Public or framework-defined hierarchies may not be reshaped without breaking others; check outside callers (`$refactoring:behavior-preservation`). (Added judgment)
- Template Method couples subclasses to their superclass's skeleton; use it where the skeleton is stable. (Added judgment)

## Verification

- [ ] Every member lives at the level of the hierarchy that all its users share.
- [ ] No subclass has an inherited member it never uses.
- [ ] No new type exists without a caller or a variation that needs it.
- [ ] A usage list justified each member kept when delegating.
- [ ] Tests passed after each move, with unchanged expectations.

## Related

`$refactoring:variation-and-state` for creating the model and for Replace Subclass with Fields; `$refactoring:ownership` for placement among peers and for Move Method and Move Field; `$refactoring:needless-abstraction` for removing layers; `refactoring-hierarchy-reviewer` to map a hierarchy and the move each smell suggests.

## Source

- `Generalization and Big Refactorings`
- `Class and Module Rules`: only the rule to prefer composition of small focused units over god objects.
- `Code Generation Rules`: only the preferred avoidance of large hierarchy introduction.
- `Moving Features`: only Move Method and Move Field, for the parallel-hierarchies anti-pattern.
