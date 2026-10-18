---
name: "refactoring-guru-organizing-data"
description: "Use when about to perform Replace Data Value with Object, change value to reference or back, Replace Array with Object, encapsulate a field or collection, change association direction, or replace a magic number. Identity and mutability decisions, then safe steps; not diagnosis (data-smells)."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Organizing data

Owns the eleven data-representation techniques that are not about type codes: what to decide before each, the safe steps and how to verify. Deciding that a primitive stands for a concept is `refactoring-guru-data-smells`; type-code replacement and conditional polymorphism are `refactoring-guru-type-codes-and-switches`; the signature change that follows a new type is `refactoring-guru-method-call-moves`.

## When to use

- You are turning a string, number or array into a small object.
- Many equal objects should be one shared entity, or a heavy shared object should become a plain value.
- A field is public, a collection is exposed, or direct field access blocks validation.
- A relation between two classes is navigable in one or both directions, and you are changing that.
- A literal with meaning needs a name.
- Domain data lives in a UI class.

## Rules

1. **Before Replace Data Value with Object, define the object's meaning, equality, validation and allowed behavior** (`MUST`). A type without these is a wrapper (`refactoring-guru-data-smells` rule 5). Check: each of the four is written in one line, and tests cover equality and validation.
2. **Before changing value or reference semantics, decide identity, mutability, sharing and lifecycle management** (`MUST`). Check: you can say whether two instances with equal fields are the same thing.
3. **Make value objects immutable before replacing references with values** (`SHOULD`). Check: no setter remains on the type that now has value semantics.
4. **Use factory creation when replacing values with references,** so callers receive the canonical object (`SHOULD`). Check: two lookups for the same key return the same instance; a missing key has defined behavior.
5. **Before changing association direction, identify which side owns updates and how consistency is maintained** (`MUST`). Check: add and remove are performed in one place on the owning side.
6. **Remove a bidirectional association when one side does not need navigation** (`MUST`), and do not add one unless both sides genuinely need it and the consistency logic is explicit (`MUST NOT` otherwise). Do not add it as a shortcut when a parameter or lookup would do. Check: every reverse reference is read somewhere.
7. **Use Replace Array with Object when array positions have named meaning,** not for true homogeneous sequences. Check: all index uses were replaced and no index semantics were lost.
8. **Use Replace Magic Number with Symbolic Constant when a literal carries meaning;** skip obvious local literals. Check: no unrelated literal with the same value was captured by the replacement.
9. **Encapsulate Field: add access methods, migrate all direct readers and writers, then make the field private** (`SHOULD`). Then review accessor callers, because behavior may belong inside the owner (`SHOULD`); do not add trivial getters and setters as the final design (`MUST NOT`). Check: the field is private and callers do not recompute the owner's decisions.
10. **Encapsulate Collection: callers must not mutate the internal collection directly** (`MUST`). Return a read-only view or copy, and expose add and remove operations that preserve invariants rather than a settable collection (`SHOULD`). Check: a caller attempting to append to the returned collection fails or has no effect on the owner.
11. **Self Encapsulate Field only when access may need validation, lazy behavior or overriding;** keep direct access where it is intentionally simple. Check: no recursion or initialization-order breakage.
12. **Duplicate Observed Data only when domain state lives in a UI class;** split it into a domain object with synchronization, and do not use it for UI-only state. Check: two-way updates are tested.
13. **Preserve domain meaning when replacing primitives or arrays with objects** (`SHOULD`). Check: the new names come from the domain's vocabulary.

### Technique table

| Technique | Use when | Do not use when | Verify |
| --- | --- | --- | --- |
| Self Encapsulate Field | Direct access blocks validation, laziness or override | Direct access is intentionally simple and local | No recursion; initialization |
| Replace Data Value with Object | A primitive has meaning, validation or behavior | The wrapper adds nothing | Equality, serialization, boundary conversion |
| Change Value to Reference | Many equal objects represent one mutable entity | The object is naturally immutable | Identity sharing; missing-object handling |
| Change Reference to Value | Lifecycle management costs more than the object deserves and immutable semantics fit | Identity or shared mutation matters | Comparisons; update flows |
| Replace Array with Object | Array positions carry meaning | The array is a true homogeneous sequence | All index semantics preserved |
| Duplicate Observed Data | UI classes hold domain data | The state is UI-only | Two-way update behavior |
| Unidirectional to Bidirectional | Both classes genuinely navigate | Convenience only | Add and remove consistency |
| Bidirectional to Unidirectional | One side does not use the other | Behavior needs reverse navigation | Navigation callers |
| Replace Magic Number with Symbolic Constant | A literal has hidden meaning | The literal is obvious and local | No unrelated captures |
| Encapsulate Field | A public field exposes representation | Stopping at trivial accessors | Callers; invariants |
| Encapsulate Collection | Callers mutate an internal collection | Exposing a settable mutable collection instead | Every mutation path |

## Procedure

1. Pick the technique and write its prerequisite decisions (rules 1, 2, 5 as applicable).
2. Introduce the new form beside the old; migrate reads, then writes, one call site at a time.
3. Keep serialization, persistence and boundary conversion in view: names and shapes that other systems store or read do not change silently (`refactoring-guru-public-compatibility`).
4. Run the tests after each migrated site and after removing the old form.
5. Review the callers of any new accessor for behavior that should move inside.

## Example

A playlist exposes its list. Callers append and remove directly, so any rule about what a playlist may contain has no single place to live.

```python
# Before
class Playlist:
    def __init__(self):
        self.tracks = []          # callers do playlist.tracks.append(t) and playlist.tracks.remove(t)

# After
class Playlist:
    def __init__(self):
        self._tracks = []

    @property
    def tracks(self):
        return tuple(self._tracks)    # read-only view; an append on it raises AttributeError

    def add(self, track):
        self._tracks.append(track)

    def remove(self, track):
        self._tracks.remove(track)
```

Callers migrate from `playlist.tracks.append(t)` to `playlist.add(t)`, and reads keep working. Behavior is unchanged: `add` is unrestricted, as appending was. The owner now has one place for a later invariant such as a capacity limit, which is a behavior change and should arrive as its own step with its own test.

## Anti-patterns

- **Getter leak.** A getter that returns the internal mutable list. Detect: `return this.items` on a mutable collection.
- **Accessor-only encapsulation.** Private fields, public getters and setters, logic outside. Detect: setters without validation.
- **Silent identity change.** Value-izing an entity (or the reverse) without deciding equality. Detect: `==` semantics changed with no test.
- **Convenience back-reference.** A bidirectional link used in one place. Detect: a reverse field with one reader.
- **Positional constant.** A constant that names the number but not the unit or meaning (`TEN = 10`). Detect: the name repeats the digit.

## Trade-offs and exceptions

- Value or reference semantics depend on identity needs: a customer is usually an entity, a money amount a value; decide per concept, not per technique.
- Bidirectional associations are allowed when both sides genuinely need navigation and consistency is explicit.
- Encapsulating a field can wait when direct access is intentionally simple and local (Self Encapsulate Field's own condition).
- Added judgment: for a first step, the read-only view can be a copy; optimize later if profiling asks.

## Verification

- [ ] For a new value type: meaning, equality, validation and allowed behavior are defined and tested.
- [ ] For value or reference changes: identity, mutability, sharing and lifecycle are decided.
- [ ] For association changes: the owning side and the consistency logic are explicit.
- [ ] No exposed mutable collection or public field remains where encapsulation was the goal.
- [ ] Tests ran after each migrated call site.

## Related

`refactoring-guru-data-smells` for diagnosis; `refactoring-guru-type-codes-and-switches` for type codes; `refactoring-guru-behavior-ownership` for behavior that should join the data; `refactoring-guru-type-introducer` to introduce a type; `refactoring-guru-data-modeling-reviewer` to review the result.

## Source

- `Organizing Data`: only the entries other than the type-code and Replace Subclass with Fields entries.
- `Organizing Data Playbook`: only the entries other than the type-code and Replace Subclass with Fields entries.
- `Data Reorganization Safety`
- `Encapsulation Safety`
- `Safety and Tradeoff Rules`: only the rule to preserve domain meaning when replacing primitives or arrays.
