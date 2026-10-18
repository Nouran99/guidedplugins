---
name: "hierarchies"
description: "Use when a subclass ignores inherited members (refused bequest), two classes do one job with different interfaces, a new subclass forces a matching subclass elsewhere, or when pulling up, pushing down, extracting a superclass or interface, collapsing or replacing inheritance."
---

# Hierarchies

Owns the shape of inheritance: three smells (Refused Bequest, Alternative Classes with Different Interfaces, Parallel Inheritance Hierarchies) and the twelve techniques in the Dealing With Generalization list (Pull Up and Push Down each count Field and Method separately) with their safety rules. Choosing to create subclasses to replace a type code is `$refactoring-guru:type-codes-and-switches`; this skill is for structure that already exists or for generalization moves.

## When to use

- A subclass overrides inherited behavior to throw, ignores inherited fields, or exposes operations that make no sense for it.
- Two classes serve the same purpose but name or shape their methods differently.
- Adding a subclass on one side requires adding a matching subclass on another side.
- Siblings duplicate fields, methods or constructor setup; or a superclass member is used by only some subclasses.
- A subclass and its parent have become practically identical, or a class delegates nearly everything to the object it really is.

## Rules

1. **For Refused Bequest, push unused methods or fields down to the subclasses that need them** (`SHOULD`), as the preferred rung. Check: after the push down, no subclass inherits a member it cannot honor.
2. **Replace inheritance with delegation when the subclass relationship is misleading** (`SHOULD`), as the fallback. Preserve inheritance only when the unused inherited behavior is harmless and does not confuse clients (`SHOULD`). Keeping inheritance only to avoid changing callers is the risky rung. Check: could a client holding the parent type use every inherited operation correctly on this subclass?
3. **For Alternative Classes with Different Interfaces, align names with Rename Method and signatures with Move Method, Add Parameter or Parameterize Method** (`SHOULD`). Check: callers could swap the two classes without changing call syntax.
4. **Extract a superclass when the duplicated behavior is only partial but real** (`SHOULD`), then delete one alternative once the common interface makes it redundant (`SHOULD`). Merging classes across library or ownership boundaries is the risky rung; you may leave alternatives separate when unification is impractical (`MAY`). Check: the shared part is behavior, not method names.
5. **For Parallel Inheritance Hierarchies, move methods and fields so one hierarchy owns the variation** (`SHOULD`), and collapse or replace structures that exist only to mirror each other (`SHOULD`). Check: a new variant requires one new class.
6. **Avoid creating new parallel hierarchies during extension work** (`MUST`). Check: the change adds no subclass whose only purpose is to pair with another.
7. **Pull Up Field, Method or Constructor Body only when sibling duplication is real and the superclass can honestly own the member** (`MUST` confirm). Do not use it for accidental duplication or when variants will diverge. Check: every subclass is verified after the move.
8. **Push Down Field or Method only after confirming the superclass no longer promises or needs the member** (`MUST` confirm). Do not push down if callers rely on the superclass member. Check: affected subtype callers still compile and behave.
9. **Extract Subclass when a subset of instances has distinct, stable behavior** (not for temporary flags or speculative categories); **Extract Superclass when classes share real behavior or data** (not for coincidental method names). Check: for each, name the behavior shared or distinct.
10. **Extract Interface only when clients need a shared subset and that subset is a real client contract** (`MUST` identify the client). Do not extract an interface only because two classes happen to share method names (`MUST NOT`). Check: a client exists that would be typed to it.
11. **Collapse Hierarchy when subclass and superclass are practically identical, after checking the remaining subclasses for substitutability and public type expectations** (`MUST` check). Check: no code relied on the removed type.
12. **Use Form Template Method when similar algorithms share structure but vary steps, and the skeleton and steps are stable.** Do not use it when algorithms are only superficially similar. Check: align step names, pull the skeleton up, push variant steps down, verify each algorithm.
13. **Replace Inheritance with Delegation when inheritance causes refused bequest or excess coupling; use Replace Delegation with Inheritance rarely,** only when the delegating class truly is a subtype, delegation is pointless and inheritance will not create refused bequest (`MUST NOT` otherwise). Check: preserve delegated behavior and update construction and forwarding paths deliberately.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Refused Bequest | Push Down Method or Push Down Field | Replace Inheritance with Delegation | Preserving inheritance only to avoid changing callers |
| Alternative Classes with Different Interfaces | Rename Method and signature alignment | Extract Superclass | Merging classes across library or ownership boundaries |
| Parallel Inheritance Hierarchies | Move methods and fields to collapse mirrored variation | Hierarchy collapse | Adding the next paired subclass without redesigning ownership |

## Procedure

1. Draw the hierarchy in text (parent, children, who overrides what). Added judgment: mark members that any child leaves unused or throws from.
2. Classify each problem: refused member, duplicated member, mirrored pair, identical pair, misleading "is-a".
3. Choose the technique from the ladder or from rules 7 to 13; confirm the precondition in the rule before editing.
4. Apply one move at a time; run the tests that exercise every subclass after each move.
5. Check public type expectations (`$refactoring-guru:public-compatibility`) before collapsing, extracting or changing what a type extends.

## Example

`Roster` extends a list type to get iteration and counting, but exposes `clear`, `insert` and `sort`, none of which the domain wants. It is a refused bequest, treated by replacing inheritance with delegation.

```python
# Before: callers can mutate the roster in ways the domain never meant
class Roster(list):
    def names(self):
        return [p.name for p in self]

roster.append(player)         # a caller
roster.insert(0, player)      # also possible; so is roster.clear()

# After: only the operations the domain needs
class Roster:
    def __init__(self):
        self._players = []

    def add(self, player):
        self._players.append(player)

    def names(self):
        return [p.name for p in self._players]

    def __iter__(self):
        return iter(self._players)

    def __len__(self):
        return len(self._players)

roster.add(player)            # callers migrated from append
```

Every call that the old code used still has an equivalent. With all writes now going through `add`, a duplicate check can be added as a separate behavior change.

## Anti-patterns

- **Is-a by convenience.** Inheriting to reuse code from a class the new type is not. Detect: the subclass hides or throws from inherited members.
- **Interface from coincidence.** An interface for two classes with matching method names and no client. Detect: no variable or parameter uses the interface type.
- **Mirror image.** `FooType` and `FooTypeEditor` hierarchies growing together. Detect: every change to one has a matching change in the other.
- **Pull-up of accident.** Moving two similar-looking methods to a superclass that cannot honestly own them. Detect: the pulled-up member needs a flag for one subclass.
- **Delegation inflation.** Delegating when the subtype relation is genuine and clients rely on substitutability. Detect: callers pass the class where the parent type is required.

## Trade-offs and exceptions

- Inheritance may stay when the unused inherited behavior is harmless and does not confuse clients.
- Alternative classes in separate external libraries may remain separate.
- Removing a subclass or changing a supertype is a public API change in many languages; apply the compatibility rules.
- Replacing delegation with inheritance is permitted rarely, and only under the three conditions in rule 13.

## Verification

- [ ] Every inherited member is usable by clients holding the parent type, or has been pushed down.
- [ ] Each extracted superclass or interface has a named shared behavior or real client.
- [ ] No new parallel subclass was introduced.
- [ ] Every subclass was exercised after each move.
- [ ] Public type expectations were checked before collapsing or retyping.

## Related

`$refactoring-guru:type-codes-and-switches` for subclass-per-variant decisions; `$refactoring-guru:behavior-ownership` for intimacy between parent and child; `$refactoring-guru:moving-features` for plain member moves; `refactoring-guru-hierarchy-reviewer` to review a diff; `$refactoring-guru:public-compatibility` before collapsing.

## Source

- `Object-Orientation Abusers`: only the Refused Bequest and Alternative Classes with Different Interfaces entries.
- `Change Preventers`: only the Parallel Inheritance Hierarchies entry.
- `Refused Bequest`
- `Alternative Classes with Different Interfaces`
- `Parallel Inheritance Hierarchies`
- `Dealing With Generalization`
- `Generalization Playbook`
- `Generalization Safety`
- `Smell-to-Treatment Priority Map`: only the Refused Bequest, Alternative Classes with Different Interfaces and Parallel Inheritance Hierarchies rows.
