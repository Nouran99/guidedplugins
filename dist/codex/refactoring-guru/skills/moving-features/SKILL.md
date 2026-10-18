---
name: "moving-features"
description: "Use when about to perform Move Method, Move Field, Extract Class, Inline Class, Hide Delegate, Remove Middle Man, Introduce Foreign Method or Local Extension. Mechanics and safety checks, not diagnosis (behavior-ownership, delegation-and-gaps, size-smells)."
---

# Moving features

Owns the eight techniques that change where members live: what to check before each, the safe steps and how to verify. Deciding that a method belongs elsewhere is `$refactoring-guru:behavior-ownership`; deciding that a layer should go or stay is `$refactoring-guru:delegation-and-gaps`; deciding that a class is too large is `$refactoring-guru:size-smells`.

## When to use

- You have decided to move a method or a field to another class.
- You are splitting a class (Extract Class) or folding one back (Inline Class).
- You are adding or removing a delegating method (Hide Delegate, Remove Middle Man).
- You are adding a helper or an extension type for a library class.

## Rules

1. **Before Move Method, inspect which class owns most of the data the method uses** (`MUST`). Moving toward the wrong owner creates envy in the other direction. Check: the tally is written down.
2. **When only part of a method belongs elsewhere, extract that fragment first** (`SHOULD`). Check: the method you move has a single owner of its data.
3. **Update all callers when moving, and preserve visibility intentionally; do not widen access just to make the move compile** (`MUST`). Check: no member became more visible, and no caller still uses the old home.
4. **Before Move Field, migrate reads and writes through accessors or direct replacements in a small sequence** (`MUST`). Do not use it when the move creates circular knowledge or breaks lifecycle ownership. Check: construction, serialization, persistence and mutation behavior are unchanged.
5. **Do not move behavior away from its data when the separation is deliberate and supports interchangeable behavior** (`MUST NOT`). Check: no second implementation or runtime selection exists for the logic you are moving.
6. **Use Extract Class when one class has a stable, separable responsibility;** never for arbitrary size reduction. Create the class, move data and behavior together, delegate temporarily, update clients gradually. Check: the new boundary is clearer, and the new class has a name that is a domain or technical concept.
7. **Before Inline Class, move all useful behavior and data to the target class and update all references** (`MUST`). Do not use it when the class marks a real boundary or extension point. Check: nothing useful remains in the shell.
8. **Delete the emptied class only after references, construction sites, tests and documentation no longer require it** (`MUST`). Check: a whole-word search finds no remaining mention.
9. **Hide Delegate: add a forwarding method that carries meaning or policy, update clients, keep the collaborator private.** Do not use it if it creates a pure pass-through that reduces no knowledge. Check: clients no longer know the path.
10. **Remove Middle Man: replace forwarding calls with direct calls, remove the forwarding methods, then reassess the class.** Do not use it when the layer protects volatility or policy. Check: callers still depend on an appropriate collaborator.
11. **Introduce Foreign Method for one narrow missing operation on a class you cannot change:** a local helper near the usage, named as if it belonged to the library type. Check: behavior against the library's edge cases.
12. **Introduce Local Extension when a library class repeatedly lacks substantial behavior:** create the extension type, move the repeated behavior, migrate callers deliberately. Do not use it for one small helper. Check: compatibility with library construction and updates.

### Technique table

| Technique | Use when | Do not use when | Safe steps (short) | Verify |
| --- | --- | --- | --- | --- |
| Move Method | A method uses another class more than its own | The separation is deliberate for interchangeable behavior | Inspect data use; extract part if needed; add to target; redirect callers; remove old | Callers; visibility |
| Move Field | A field is used more by another class or concept | It creates circular knowledge or breaks lifecycle ownership | Add to target; migrate reads and writes; keep initialization; delete old | Construction, serialization, persistence, mutation |
| Extract Class | One class holds separable responsibilities | The only reason is size | Create; move data and behavior together; delegate temporarily; update clients gradually | Behavior; boundary clearer |
| Inline Class | A class no longer earns its cost | It marks a real boundary or extension point | Move members to target; replace references; delete the empty class | Construction and public API usage |
| Hide Delegate | Clients navigate collaborator structure | It becomes a pure pass-through | Add a meaningful forwarding method; update clients; keep collaborator private | Clients no longer know the path |
| Remove Middle Man | A class mostly forwards | The layer protects volatility or policy | Replace forwarding calls with direct calls; remove forwarders; reassess | Callers' dependencies |
| Introduce Foreign Method | A library class lacks one small operation | Many operations are missing | Local helper near usage; named as if on the type; replace duplicates | Library edge cases |
| Introduce Local Extension | A library class repeatedly lacks substantial behavior | One small helper suffices | Extension type; move repeated behavior; migrate callers | Library construction and upgrades |

## Procedure

1. Pick the technique and read its "do not use when" cell.
2. Write the tally or the member list that justifies the move.
3. Move in two phases: add at the target and delegate from the source, then redirect callers one at a time, then remove the delegate.
4. Run the tests after the add, after each redirected caller group, and after the removal.
5. Search for stale references (strings, configuration, docs) before deleting a source.
6. Re-read the result for the opposite smell (envy toward the old home, a new middle man).

## Example

A customer class carries address fields and address logic. The address concept is extracted; the old methods and the four old attributes delegate temporarily so callers can migrate in steps.

```python
# Before
class Customer:
    def __init__(self, name, street, city, postal_code, country):
        self.name, self.street, self.city = name, street, city
        self.postal_code, self.country = postal_code, country

    def format_address(self):
        return f"{self.street}, {self.postal_code} {self.city}"

    def is_domestic(self, home_country):
        return self.country == home_country

# After (step 1 and 2: new class, temporary delegation)
class Address:
    def __init__(self, street, city, postal_code, country):
        self.street, self.city = street, city
        self.postal_code, self.country = postal_code, country

    def format(self):
        return f"{self.street}, {self.postal_code} {self.city}"

    def is_domestic(self, home_country):
        return self.country == home_country

class Customer:
    def __init__(self, name, address):
        self.name = name
        self.address = address

    # Temporary delegates; delete once callers use customer.address directly
    @property
    def street(self):
        return self.address.street

    @property
    def city(self):
        return self.address.city

    @property
    def postal_code(self):
        return self.address.postal_code

    @property
    def country(self):
        return self.address.country

    def format_address(self):
        return self.address.format()

    def is_domestic(self, home_country):
        return self.address.is_domestic(home_country)
```

The constructor signature changed and cannot be delegated, so construction sites migrate in this step. The delegating methods and read-only properties are the transition path for readers of the old API (`customer.city` still works). Code that assigns to the old attributes fails with `AttributeError`, so it moves to `customer.address.city = ...` in the same step, or the properties get setters. The last step (delete the delegates, then reassess whether `Customer` still earns its methods) is a separate commit.

## Anti-patterns

- **Wrong-way move.** The moved method now reads its old home's fields. Detect: the body repeats `self.old.` after the move.
- **Compile-driven visibility.** Making a member public to finish the move. Detect: access modifiers widened in the diff.
- **Extract Class by size.** A new class that is half the old one's methods without a concept. Detect: the name is `Part`, `Helper` or `Data`.
- **Orphan shell.** An emptied class left in place. Detect: a class with no members or only delegates after Inline Class.
- **Forwarders forever.** Temporary delegates that were never removed. Detect: methods marked temporary with no callers needing them. Added judgment: record the removal step in the plan.

## Trade-offs and exceptions

- Do not move behavior away from its data when the separation is deliberate and supports interchangeable behavior; leave it where it is and say why.
- Inline Class does not apply to a class that marks a boundary, even if it is small.
- Temporary delegation costs a short-lived extra layer; the source asks for it so callers can be updated gradually.

## Verification

- [ ] The data-ownership tally for each moved method is recorded.
- [ ] All callers, construction sites, tests and documentation were updated or intentionally left.
- [ ] No visibility was widened to compile.
- [ ] Temporary delegates have a planned removal.
- [ ] Tests ran after the add, the redirects and the removal.

## Related

`$refactoring-guru:behavior-ownership` and `$refactoring-guru:delegation-and-gaps` for the decisions; `$refactoring-guru:size-smells` for Large Class; `refactoring-guru-responsibility-mover` to carry out a move; `refactoring-guru-coupling-reviewer` to review the result; `$refactoring-guru:public-compatibility` before moving anything public.

## Source

- `Moving Features Between Objects`
- `Moving Features Playbook`
- `Moving Safety`
- `Inlining Safety`: only the Inline Class rules.
