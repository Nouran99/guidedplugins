---
name: class-design
description: "Use when a class or module has several responsibilities, exposes internals, mixes persistence, formatting, business rules and integration, or reaches into another's internals. Covers cohesion and coupling. One routine: /code-complete:routine-design."
---

# Class and module design

Judges a class or module as a whole: one focused responsibility, a clear interface kept apart from its implementation, hidden representation, cohesion, and limited knowledge of other modules' internals. A single routine is `/code-complete:routine-design`.

## When to use

- A class changes for more than one reason, or you cannot describe it without "and".
- A class has fields that only some of its methods use.
- Public fields, getters of internal collections, counters or caches are visible to callers.
- One module reads and writes the database, formats output, applies business rules and calls another service.
- A caller navigates through several objects (`a.b().c().d`) or depends on how another class stores its data.

## Rules

1. **Give each class or module a focused responsibility.** Why: a class with several jobs is changed and broken for several reasons. Check: you can state the responsibility in one sentence without "and"; the name matches it.
2. **Separate interface from implementation.** Check: what callers may rely on (public methods and their documented contract) is distinct from fields, helpers and storage, and callers use only the former.
3. **Hide representation and incidental detail.** Check: fields are private; no method returns a mutable internal collection; callers do not know whether state is a list, a map or a cache.
4. **Keep classes cohesive.** Check: the methods work on the same core data. Added judgment: a field used by only a subset of methods marks a second class waiting to be named.
5. **Reduce coupling through clear contracts and limited knowledge of internals.** Check: collaborators interact through small, documented interfaces; no code depends on another class's field layout or iteration order.
6. **Do not create god classes.** Source anti-pattern. Check: no class that every feature edits, none named `Manager`, `Helper` or `Utils` whose methods share no data.
7. **Do not mix persistence, formatting, business logic and integration concerns in one module.** Source anti-pattern. Check: SQL, rendering, pricing rules and calls to other services live in different places, or the module's single purpose covers exactly one of them.
8. **Do not expose internal bookkeeping on a public surface.** Source anti-pattern. Check: dirty flags, retry counters, cache maps and index arrays are not part of the interface.
9. Added judgment: a constructor leaves the object valid, and every public method keeps it valid; invariants are stated and enforced where the data lives (`/code-complete:assertions-and-contracts`).
10. Added judgment: when the same field combination is passed between classes repeatedly, name the group as a type instead of exposing the parts.
11. Added judgment: ask what would change if the storage format changed; if the answer is "every caller", the representation leaks.

## Procedure

1. Write the responsibility sentence for each changed class. Mark any that needs "and".
2. List the public surface. For each member, decide if it is interface (a promise) or bookkeeping (an accident).
3. Group the methods by the fields they touch. Disjoint groups are candidate classes.
4. Separate concerns one at a time: extract the persistence, formatting or integration piece behind a small interface, and delegate. Run the tests after each extraction.
5. Make fields private and replace exposed internals with operations that express what callers need.
6. Rename the remaining class to match its single responsibility.

## Example

```python
# Before: one class prices, formats, stores and exposes its bookkeeping
class OrderService:
    def __init__(self, conn):
        self.conn = conn
        self.cache = {}          # public, callers poke it
        self.dirty = False

    def total_and_receipt(self, order_id):
        rows = self.conn.execute("select sku, qty, cents from lines where order_id = ?", (order_id,)).fetchall()
        total = sum(qty * cents for _, qty, cents in rows)
        self.cache[order_id] = total
        lines = [f"{sku} x{qty}  {cents / 100:.2f}" for sku, qty, cents in rows]
        return total, "\n".join(lines)

# After: three small responsibilities with narrow interfaces; no bookkeeping is public
@dataclass(frozen=True)
class Line:
    sku: str
    qty: int
    cents: int

class OrderLines:                       # persistence
    def __init__(self, conn): self._conn = conn
    def for_order(self, order_id) -> list[Line]:
        rows = self._conn.execute("select sku, qty, cents from lines where order_id = ?", (order_id,)).fetchall()
        return [Line(sku, qty, cents) for sku, qty, cents in rows]

def order_total_cents(lines: list[Line]) -> int:     # business rule, no I/O
    return sum(line.qty * line.cents for line in lines)

def render_receipt(lines: list[Line]) -> str:        # formatting, no I/O
    return "\n".join(f"{line.sku} x{line.qty}  {line.cents / 100:.2f}" for line in lines)
```

If a cache is still needed, it is a private detail of whoever owns the lookup (`OrderLines`), not a field every caller can edit.

## Anti-patterns

- **God class.** The class every feature touches. Detect: the file with the most commits and the most unrelated imports.
- **Mixed-concern module.** SQL, HTML and pricing in one file. Detect: imports from the database driver and the template engine in the same module.
- **Leaky surface.** Public `cache`, `dirty`, `retryCount`. Detect: members that make sense only to the class's own methods but are visible.
- **Reach-through.** `customer.address().city().name()`. Detect: call chains across three or more objects (Added judgment: a search aid, not a limit).
- **Split-personality class.** Two groups of methods that touch disjoint fields. Detect: removing half the fields breaks half the methods and nothing else.
- **Utility dumping ground.** `Utils` with unrelated statics. Detect: methods that share no data and no concept.

## Trade-offs and exceptions

- Small plain data holders (records, DTOs) legitimately expose their fields; the rules apply to classes that own behavior and invariants.
- Splitting adds names and indirection. Split when responsibilities change independently or the class is hard to hold in mind, not to hit a class-size target; the source gives no size limit.
- A module may coordinate several collaborators and still be focused; coordination is its single purpose when it contains no persistence, formatting or business rules of its own.
- Framework-mandated shapes (an ORM entity with public fields, a base class with required hooks) win over the rules at the framework boundary; keep the exposure from spreading inward.

## Verification

- [ ] The responsibility of each changed class fits in one sentence without "and".
- [ ] No internal collection, counter, cache or flag is public.
- [ ] Persistence, formatting, business rules and integration are not mixed in the changed module.
- [ ] Methods in the class share the same core data.
- [ ] Callers do not depend on how the class stores its state.
- [ ] Tests passed after each extraction.

## Related

`/code-complete:routine-design` for one routine; `/code-complete:data-types` for value types that replace exposed field groups; `/code-complete:complexity-management` for tangles that span classes; `code-complete:class-design-reviewer` to review a diff.

## Source

- `Class and Module Design Rules`
- `Review Rules`: only the item on god classes or mixed responsibilities.
