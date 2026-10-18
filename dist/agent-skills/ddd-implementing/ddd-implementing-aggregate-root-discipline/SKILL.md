---
name: "ddd-implementing-aggregate-root-discipline"
description: "Use when code outside an aggregate sets its fields, mutates child entities, receives its child collections or navigates through its internals. Judges the access surface; where the deciding code lives is application-services or domain-services. Size is aggregate-boundaries; life cycle is entities."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Aggregate root discipline

Owns the door of the aggregate: only the root is held from outside, every invariant-changing operation goes through it, and it speaks in business intentions. It does not size the aggregate (`ddd-implementing-aggregate-boundaries`), design one entity's transitions (`ddd-implementing-entities`) or decide where a branching business rule belongs when it sits in a service (`ddd-implementing-rule-placement-reviewer`).

## When to use

- A controller, handler or service calls `getX()` on an aggregate, branches, then calls `setY()`.
- A root returns its internal list or map of child entities.
- A repository, report or event handler holds a reference to a child entity of an aggregate.
- An aggregate has public setters for status, dates or quantities.
- A review comment says "the root is not protecting its invariants".

## Rules

1. **[MUST] Reference only the aggregate root directly from outside.** Child entities are reached through the root. Check: no repository, handler or other aggregate stores or passes a child entity; lookups return the root.
2. **[MUST] Route every invariant-changing operation through the root.** The root is the only place all rules are checked. Check: each mutation of a child's state is invoked by a root method.
3. **[MUST NOT] Mutate internal members directly from external code.** Check: no statement outside the aggregate modifies a field or collection of a child (`root.items.add(...)`, `line.setQuantity(...)`).
4. **[MUST] Expose intention-revealing behavior, not arbitrary setters.** `approve()`, `addLine(sku, quantity)`, `cancel(reason)` name what the business does; `setStatus` names what the database holds. Check: no public setter for status, dates, amounts or counts that participate in an invariant.
5. **[MUST NOT] Expose mutable child collections from the root.** A returned list is a back door. Check: accessors return copies, read-only views or immutable value objects, never the backing collection.
6. **[MUST] Have the root protect the invariants.** Check: constructing and changing the aggregate through its public methods cannot produce a state a written invariant forbids.
7. **[Compact checklist] When external code reads internals to decide a state change, move the operation behind root behavior.** Check: no caller reads a root's state to decide what to write back; the root exposes the decision as a method or a query result.
8. **[Added judgment] Use visibility to enforce the door.** Package-private or module-private child classes and constructors, `internal` in .NET or Kotlin, or an unexported field in Go make rules 1 to 3 compile errors instead of review comments. Check: a child entity cannot be constructed or mutated from another package.
9. **[Added judgment] Return outcomes, not state, from root methods when the caller needs to react.** A method that returns the event or result (`SeatTaken`, `Receipt`) spares the caller from inspecting the aggregate afterwards. Check: callers of root methods do not re-read the root to learn what happened.

## Procedure

1. List the public surface of the root: setters, public fields, getters that return collections or child entities.
2. Search callers outside the aggregate for the pattern read, branch, write (`grep` for `.get...()` followed by `.set...()` or `.add(`).
3. For each pattern, write the business intention in one verb phrase and give it to the root as a method; move the branch and the write into it.
4. Replace returned collections with copies or read-only views, and make child element types immutable or inaccessible.
5. Remove the setter or reduce its visibility once no caller uses it.
6. Add a test per rule on the new method (`ddd-implementing-domain-tests`) before deleting the old code path; run all tests after each step. Use `ddd-implementing-root-encapsulator` for a larger job.

## Example

```java
// Before: callers manage the aggregate's state
class CheckoutController {
    void checkOut(Basket basket) {
        basket.getLines().add(new BasketLine(sku, quantity));   // back door
        if (basket.getLines().size() > 20) throw new IllegalStateException("too many lines");
        basket.setStatus(Status.CHECKED_OUT);
    }
}

// After: the root owns the rules and exposes intentions
public final class Basket {
    private static final int MAX_LINES = 20;
    private final List<BasketLine> lines = new ArrayList<>();
    private boolean checkedOut;

    public void add(Sku sku, Quantity quantity) {
        requireOpen();
        int at = indexOf(sku);
        if (at >= 0) {
            lines.set(at, lines.get(at).plus(quantity));
        } else {
            if (lines.size() == MAX_LINES) throw new BasketFull(MAX_LINES);
            lines.add(new BasketLine(sku, quantity));
        }
    }

    public Receipt checkOut() {
        requireOpen();
        if (lines.isEmpty()) throw new EmptyBasket();
        checkedOut = true;
        return new Receipt(List.copyOf(lines));
    }

    public List<BasketLine> lines() { return List.copyOf(lines); }

    private int indexOf(Sku sku) {
        for (int i = 0; i < lines.size(); i++) if (lines.get(i).sku().equals(sku)) return i;
        return -1;
    }
    private void requireOpen() { if (checkedOut) throw new BasketClosed(); }
}

public record BasketLine(Sku sku, Quantity quantity) {
    BasketLine plus(Quantity more) { return new BasketLine(sku, quantity.plus(more)); }
}
```

The limit and the "open basket" rule are enforced in one place, and `lines()` hands out a copy of immutable records.

## Anti-patterns

- **Setter façade.** Public setters on every field. Detect: `set*` methods on classes that appear in an invariant.
- **Leaky collection.** A getter that returns the backing list. Detect: `return this.items;` or a getter returning a mutable `Map`/`List`.
- **Read-decide-write outside.** A service reads state, branches, writes. Detect: `if (x.getStatus() == ...) x.setStatus(...)` in a non-model class.
- **Child escapes.** A child entity stored in another class. Detect: a field or parameter typed as a member of another aggregate.
- **Constructor bypass.** A public constructor on a child that lets callers create it outside the root. Detect: `new BasketLine(...)` outside the aggregate's package.

## Trade-offs and exceptions

- Read access is not forbidden: root queries and immutable snapshots are fine (rule 5 is about *mutable* collections). Reading internals to *decide a write* is the problem (rule 7).
- The source's ban on passive ORM containers is stated for behavior-rich domains. A genuinely passive record in an area that stays plain CRUD (`ddd-implementing-core-domain-focus`) is not a violation of this skill.
- Frameworks sometimes need a no-argument constructor and field access for persistence. Keep that reflective access inside the persistence mapping and do not add public setters for it.

## Verification

- [ ] The root has no public setter for any field that appears in an invariant.
- [ ] No accessor returns a mutable child collection.
- [ ] No code outside the aggregate holds a child entity.
- [ ] No caller reads state to decide a write back to the aggregate.
- [ ] Each new root method has a test for its rule and its rejection.
- [ ] All pre-existing tests pass.

## Related

`ddd-implementing-aggregate-boundaries` for what belongs inside; `ddd-implementing-entities` for the behavior of each member; `ddd-implementing-application-services` for keeping use-case code thin; `ddd-implementing-root-discipline-reviewer` to review a diff; `ddd-implementing-root-encapsulator` to make the change.

## Source

- `Aggregate Rules of Thumb`: only the Aggregate Root Discipline subsection and the anti-pattern on exposed mutable child collections.
- `Aggregate Root Discipline`
- `Review Rules`: only the items on roots not protecting invariants and external code mutating aggregate internals.
