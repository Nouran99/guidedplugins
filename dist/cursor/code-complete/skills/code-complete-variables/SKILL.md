---
name: "code-complete-variables"
description: "Use when a variable is vaguely named, declared far from use, reused for a second meaning, uninitialized or mutable without need. Types, constants, units, sentinels: code-complete-data-types."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Variables

Judges the life of a variable: its name, where it is declared, how it starts, whether it changes, and whether it keeps one meaning. What a value is and means (type, unit, constant, sentinel) is `code-complete-data-types`.

## When to use

- A local has a generic name (`data`, `tmp`, `result`, `flag`) in a scope longer than a few lines.
- Variables are declared in a block at the top of a routine and used much later.
- One variable is assigned for two different purposes, or a loop index is reused after the loop.
- A variable may be read before it is assigned on some path, or relies on a default value by accident.
- A value never changes after initialization but is declared mutable.

## Rules

1. **Use names that reveal purpose and meaning.** Why: the next reader reconstructs intent from names. Check: you can say what the variable holds and why it exists without reading its assignments.
2. **Keep variable scope as small as practical.** Why: a variable that is visible everywhere can be wrongly changed from anywhere. Check: each variable is declared in the narrowest block that contains all its uses, close to its first use.
3. **Initialize variables deliberately.** Why: an unintended default is a silent defect. Check: on every path the first read of a variable follows an assignment you can point to; declaration with the intended value is the default, not declaration and later assignment.
4. **Prefer named constants or stable values where a variable is not meant to change.** Why: immutability states intent and removes a class of bugs. Check: prefer `const`, `final`, `readonly` or the language's equivalent for every variable that is never reassigned.
5. **Do not reuse loop, index or temporary variables beyond their purpose.** Source anti-pattern. Check: no variable is assigned for two different concepts; a loop index is not read after the loop for another reason.
6. **Do not keep long-lived mutable locals that carry many meanings.** Source anti-pattern. Check: an accumulator that later becomes a result (`total` turns into `average`) is two variables.
7. **Do not leave values whose units or semantics are unclear.** Source anti-pattern; the repair (names, units in types, constants) is in `code-complete-data-types`. Check: the name or type says "seconds", "cents" or "index" where it matters.
8. **Avoid magic numbers and unexplained sentinel values.** Source rule shared with `code-complete-data-types`, which owns the fix. Check: no bare literal with business meaning appears in an expression you touched.
9. Added judgment: a generic name is acceptable for a tiny scope (`i` in a three-line loop, `err` after a call); it is a smell when the scope is long or the meaning is not obvious from the line that assigns it.
10. Added judgment: when you reassign a parameter, give the new value its own name; a parameter that changes meaning mid-routine is the same defect as a reused local.
11. Added judgment: compute a value once into a well-named local when the expression hides a concept or is repeated; do not create a local that is used once and says nothing the expression did not.

## Procedure

1. List the variables in the changed routines. For each, note declaration line, first use, last use and the number of distinct meanings.
2. Move declarations next to first use and into the narrowest block. Initialize with the real value at that point.
3. Split any variable with two meanings into two named variables. Rename generic names where the scope is long.
4. Prefer immutable declarations for never-reassigned variables.
5. Hand sentinel values, unit-less names and magic literals to `code-complete-data-types`.
6. Run the tests after the split; a reused variable often hid a branch that the old code only appeared to share.

## Example

```python
# Before: `t` is a sum, then an average (two meanings), and `i` is a count under an index-style name
def summarize(orders):
    t = 0
    i = 0
    for o in orders:
        t = t + o.total
        i = i + 1
    t = t / i          # t now means "average"; ZeroDivisionError when orders is empty
    return t, i

# After: one meaning per variable, immutable result, the empty case is decided on purpose
def summarize(orders: list[Order]) -> tuple[Decimal, int]:
    order_count = len(orders)
    if order_count == 0:
        raise ValueError("summarize: at least one order is required")
    total = sum((o.total for o in orders), Decimal(0))
    average = total / order_count
    return average, order_count
```

The empty-list decision is a behavior change (the old code failed with `ZeroDivisionError`); say so in the change description, or keep the old failure if callers depend on it.

## Anti-patterns

- **Recycled temp.** One `tmp` or `i` used for unrelated work. Detect: two assignments to one variable that feed different later uses.
- **Top-of-routine declaration block.** All locals declared first, used pages later. Detect: more than a few lines between declaration and first read.
- **Phantom default.** A variable relies on a zero value nobody chose. Detect: a read on a path where no assignment is visible.
- **Everything mutable.** Variables declared mutable that are never reassigned. Detect: no assignment after the declaration.
- **Shifting meaning.** An accumulator turned into a result. Detect: the same name is used in a sentence before and after with different nouns.

## Trade-offs and exceptions

- "As small as practical" is a judgment: a variable shared by two phases of a routine may legitimately live across both; splitting the routine (`code-complete-routine-design`) often removes the need.
- Languages that require declarations at the top of a block (older C style) or that hoist declarations constrain scope; follow the language and keep the use close.
- Initializing a variable to a dummy value just to silence a compiler or linter hides the real defect; restructure so that every path assigns a meaningful value.
- Short conventional names in tiny scopes are fine and match the repository's style (`code-complete-coding-standards`).

## Verification

- [ ] Each variable has one meaning and a name that states it.
- [ ] Each variable is declared at first use in the narrowest practical scope.
- [ ] Every read follows a deliberate assignment on all paths.
- [ ] Variables that are not meant to change are declared immutable where the language allows.
- [ ] Unit, sentinel and literal questions were handed to `code-complete-data-types`.

## Related

`code-complete-data-types` for value meaning; `code-complete-routine-design` when a long-lived local is a sign of a routine that does too much; `code-complete-statements-and-loops` for loop variables; `code-complete-data-reviewer` to review a diff.

## Source

- `Variable and Data Rules`
- `Review Rules`: only the item on unclear names.
