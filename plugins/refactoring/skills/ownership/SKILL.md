---
name: ownership
description: "Use when one class changes for many reasons, one change edits many files, a method mostly works on another object's data, or domain rules sit in UI or I/O code. Where behavior lives among peers; types for concepts are primitive-obsession, hierarchies inheritance-moves."
---

# Ownership

Behavior and state belong with the concept that owns them. This skill covers the three smells about misplacement (divergent change, shotgun surgery, feature envy), the moves that relocate things between classes and modules, and the separation of domain policy from presentation. Reshaping a class hierarchy is `/refactoring:inheritance-moves`; removing forwarding classes is `/refactoring:needless-abstraction`; creating a type for a recurring concept is `/refactoring:primitive-obsession`.

## When to use

- You open the same class for unrelated reasons (pricing, formatting, persistence).
- A small change needs edits in many files, all of the same kind.
- A method reads several fields of another object and barely touches its own.
- Business rules live in a controller, a view or a query builder.
- A file mixes unrelated concerns.

## Rules

1. **If one class changes for many different reasons, split responsibilities (Divergent Change).** Check: list the last few reasons the class was edited (version history is a good source); unrelated reasons mean more than one owner.
2. **Separate business logic, formatting, transport, persistence and integration concerns.** Check: no class mixes a business rule with a wire format or a query.
3. **If one change forces edits across many files, centralize the knowledge or introduce a better boundary (Shotgun Surgery).** Check: count the files the last change of this kind touched; more than a few identical edits means the knowledge is scattered.
4. **If a method mostly manipulates another object's data, move it or reshape the model (Feature Envy).** Put behavior near the data or concept it belongs to. Check: the method mentions its own fields less than it mentions another object's.
5. **Use Move Method to put a function in the module or type where the data or concept lives, Move Field when ownership is clearer elsewhere, and move statements to group related operations.** Check: after the move, callers talk to the owner, and the old location holds no remnant logic.
6. **Use Extract Class when one class has more than one reason to change; extract a module when a file mixes unrelated concerns.** Check: each result has a narrow reason to change and a name that says what it is.
7. **Use Hide Delegate when clients know too much about an object's collaborator.** Check: callers no longer chain through an object to reach its neighbor. Remove Middle Man is the reverse and lives in `/refactoring:needless-abstraction`.
8. **Use Introduce Foreign Method only when you cannot edit the class that should own the behavior; use Introduce Local Extension when repeated foreign methods need a coherent extension point.** Check: you confirmed the class is out of your control before choosing either.
9. **Prefer composition of small focused units over god objects, and separate policy from presentation, I/O, persistence and framework details.** Check: policy code can run without the framework.
10. **Use Convert Procedural Design to Objects when data and behavior need clearer ownership, and Separate Domain from Presentation when UI and policy are tangled.** Check: the domain code has no import from the UI layer.
11. **When UI and domain behavior mix, move the rules toward the domain objects and verify any presentation synchronization that depends on them (compact checklist).** Check: the screen still updates the same way after the rule moved.
12. **Added judgment: move behavior in small steps, with the old method delegating until callers migrate.** Check: each step compiles and the tests pass.

## Procedure

1. Name the smell: many reasons (divergent), many files (shotgun), or reaching into another object's data (envy).
2. Identify the concept that should own the knowledge and whether it already exists.
3. Move one method or field at a time to the owner, leaving a delegating stub if callers are many.
4. Migrate callers; delete the stub. For a god class, repeat until each remaining class has one reason to change.
5. Run the tests after each move; stop when the next move would only shuffle things (`/refactoring:stopping-rules`).

## Example

```java
// Before: the formatter computes a credit rule from the customer's data
class StatementFormatter {
    String creditLine(Customer c) {
        int open = 0;
        for (Invoice i : c.invoices()) if (!i.isPaid()) open += i.cents();
        boolean overLimit = open > c.creditLimitCents();
        return c.name() + (overLimit ? " OVER LIMIT" : " ok");
    }
}

// After: the rule moves to its owner; the formatter formats
class Customer {
    private final List<Invoice> invoices;
    private final int creditLimitCents;
    // ...
    int openBalanceCents() {
        int open = 0;
        for (Invoice i : invoices) if (!i.isPaid()) open += i.cents();
        return open;
    }
    boolean isOverCreditLimit() { return openBalanceCents() > creditLimitCents; }
}

class StatementFormatter {
    String creditLine(Customer c) {
        return c.name() + (c.isOverCreditLimit() ? " OVER LIMIT" : " ok");
    }
}
```

A change to the credit rule now touches `Customer` only, and the formatter has one reason to change.

## Anti-patterns

- **Reaching in.** Detect: a method with many calls to one other object's getters. Treat: Move Method.
- **God class.** Detect: fields that cluster into groups used by disjoint methods. Treat: Extract Class along the groups.
- **Scattered knowledge.** Detect: the same literal or rule in many files. Treat: centralize it with one owner (and see `/refactoring:duplication`).
- **Domain in the view.** Detect: pricing, eligibility or validation inside UI code. Treat: Separate Domain from Presentation.
- **Foreign method sprawl.** Detect: many helper functions taking a library type as first argument. Treat: Introduce Local Extension.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Feature envy is sometimes right: a formatter or a mapper is meant to read another object's data. The smell is about rules, not about every method that reads fields. (Added judgment)
- Moving behavior to the data can create dependencies the other way; check the direction before moving across module boundaries (Added judgment).
- Splitting a class that changes for one reason because it is large is not justified by this skill; size alone is a prompt to look. (Added judgment)
- Data holders for transport (DTOs) legitimately have no behavior. (Added judgment)

## Verification

- [ ] Each resulting class or module can be described with one reason to change.
- [ ] No business rule remains in presentation, transport or persistence code.
- [ ] A change of the kind that used to scatter now touches one place.
- [ ] Callers migrated; no delegating stub remains unless deliberate.
- [ ] Tests passed after each move and behavior is unchanged.

## Related

`/refactoring:inheritance-moves` for hierarchies; `/refactoring:needless-abstraction` for Inline Class and Remove Middle Man; `/refactoring:primitive-obsession` for new types that attract behavior; `refactoring:ownership-reviewer` to review a diff; `refactoring:class-splitter` to split a god class.

## Source

- `Divergent Change`
- `Shotgun Surgery`
- `Feature Envy`
- `Movement Refactorings`
- `Extraction Refactorings`: only extract class and extract module.
- `Moving Features`: all moves except Inline Class and Remove Middle Man, which belong to needless-abstraction.
- `Class and Module Rules`: the rules on narrow reasons to change, separating policy from presentation, composition, and organizing by concept.
- `Generalization and Big Refactorings`: only Convert Procedural Design to Objects and Separate Domain from Presentation.
