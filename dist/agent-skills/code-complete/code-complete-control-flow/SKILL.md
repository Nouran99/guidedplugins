---
name: "code-complete-control-flow"
description: "Use when branches are hard to verify: deep nesting, compound conditions, switch statements, multiple exits, dead branches, side-effecting conditions. Loops and statement order: code-complete-statements-and-loops. Repeated mappings: code-complete-table-driven."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Control flow

Judges the shape of decisions in a routine: nesting, conditions, switches, exits, unreachable paths. Loops and the order of straight-line statements are `code-complete-statements-and-loops`; a repeated mapping that should become data is `code-complete-table-driven`.

## When to use

- A routine nests conditionals deeply (Added judgment: three or more levels is a prompt to look), or the normal path is buried inside them.
- A condition combines several clauses with `and`, `or` and `not`.
- A `switch` or `case` has fallthrough, a silent default, or branches that duplicate each other.
- A routine has several `return`, `break`, `continue` or `throw` points and a reader must find them all.
- A condition calls something that changes state.

## Rules

1. **Prefer the simplest control flow that expresses the logic.** Why: every extra path is a case to test and to get wrong. Check: you can state, for each branch, the condition that selects it in plain words.
2. **Keep nesting shallow when possible.** Why: each level adds a condition the reader holds in mind. Check: preconditions and rare cases leave through guard clauses at the top (`code-complete-routine-design`), leaving the normal path at the outer level. Added judgment: three or more levels of nesting deserve a second look; the source gives no number.
3. **Replace complicated boolean logic with named predicates or clearer structure.** Why: `a || b && !c` hides its precedence and its meaning. Check: any condition mixing `and` with `or` has a named predicate or is split. Added judgment: treat a condition with three or more clauses the same way; the source gives no number.
4. **Use case or switch constructs only when they improve clarity.** Check: each case is short, none falls through unmarked, and the default either handles the remainder on purpose or fails loudly. Added judgment: a default that cannot occur should raise, not return a plausible value.
5. **Eliminate impossible paths and dead branches.** Check: every branch is reachable from some valid input; an `else` that "cannot happen" is either removed, asserted (`code-complete-assertions-and-contracts`) or proven reachable by a test.
6. **Avoid surprising exits unless they clarify the routine.** Check: each early exit is at the level where a reader expects it; a `break` or `return` buried inside a nested block is moved up or justified.
7. **Do not write control flow that depends on side effects in expressions.** Source anti-pattern. Check: no condition both tests and changes (`if (next() && ...)`, `i++` inside a test).
8. **Do not use clever one-liners that obscure the logic.** Source anti-pattern. Check: a nested ternary or a chained condition is rewritten as statements when a reader needs more than one pass.
9. **Do not write complicated loop exits with hidden state changes.** Source anti-pattern, detailed in `code-complete-statements-and-loops`.
10. **Compact rule: when branches, loops, recursion, exits or exception paths become hard to verify, simplify before adding logic.** Check: a new condition is added only after the existing shape can be explained.
11. Added judgment: keep one decision per condition. A condition that mixes validation, authorization and business rules should be three checks with three outcomes.

## Procedure

1. For each changed routine, list its exits and its deepest nesting level.
2. Move precondition checks and rare cases to guard clauses at the top. Do it one at a time; run the tests after each.
3. Name each compound condition with a predicate that states its business meaning. Add explicit parentheses first if precedence is unclear, to prove you preserve behavior.
4. Replace side-effecting conditions with a statement before the test.
5. Check each `switch` for fallthrough and default behavior; hand repeated mappings to `code-complete-table-driven`.
6. Delete branches that cannot be reached, or turn them into assertions with a message.

## Example

```python
# Before: three levels, a compound condition whose precedence is easy to misread, a None that means "no items"
def shipping_cost(order):
    cost = None
    if order.items:
        if order.destination.domestic:
            if order.weight_kg > 20 or len(order.items) > 10 and not order.prepaid:
                cost = FREIGHT_RATE * order.weight_kg
            else:
                cost = PARCEL_RATE
        else:
            cost = INTERNATIONAL_RATE
    return cost

# After: guard clauses, a named predicate with explicit precedence, same results
def needs_freight(order) -> bool:
    heavy = order.weight_kg > 20
    bulky_and_unpaid = len(order.items) > 10 and not order.prepaid
    return heavy or bulky_and_unpaid

def shipping_cost(order):
    if not order.items:
        return None
    if not order.destination.domestic:
        return INTERNATIONAL_RATE
    if needs_freight(order):
        return FREIGHT_RATE * order.weight_kg
    return PARCEL_RATE
```

The `None` return for an empty order is kept to preserve behavior. Whether it should be an error is a separate decision (`code-complete-error-handling`).

## Anti-patterns

- **Arrow code.** Nesting that marches right. Detect: indentation of the normal path increases with each precondition.
- **Precedence puzzle.** `a || b && !c` with no parentheses. Detect: a condition mixing `and` and `or` without grouping.
- **Side-effecting condition.** `if (queue.pop() != null && ...)`. Detect: a call in a test whose name is not a pure question.
- **Silent default.** `default:` returns a plausible value for input nobody planned for. Detect: a switch default with no assertion or error.
- **Phantom branch.** An `else` or `case` no valid input reaches. Detect: no test or caller can drive it.
- **Hidden exit.** A `return` or `break` deep inside nested blocks. Detect: a search for `return` finds more exits than the routine's first screen shows.

## Trade-offs and exceptions

- Several returns are fine when each is a guard clause at the top; they become a problem only when they are scattered through the body.
- A `switch` over an enum is often clearer than a table when each case runs different logic; use a table only for stable value mappings (`code-complete-table-driven`).
- A deep structure that mirrors a deep domain rule may be the clearest form; then name the levels (predicates, routines) rather than flatten at all costs.
- Language idioms (pattern matching, `?.`, early `continue`) may express a guard more compactly; use them if the repository does.

## Verification

- [ ] The normal path of each changed routine sits at the outer level of nesting.
- [ ] No condition mixes `and` and `or` without a name or explicit grouping.
- [ ] No condition changes state.
- [ ] Every `switch` default is deliberate and every fallthrough is marked.
- [ ] No branch is unreachable, or it is covered by an assertion with a message.
- [ ] Tests passed before and after, including both sides of each changed condition.

## Related

`code-complete-statements-and-loops` for loops and statement order; `code-complete-table-driven` for repeated mappings; `code-complete-routine-design` for guard clauses in a routine; `code-complete-complexity-management` for density and cleverness across code; `code-complete-control-flow-reviewer` to review a diff.

## Source

- `Control Flow Rules`
- `Cleverness over Clarity`
- `Routine Design Rules`: only the rule to prefer guard clauses.
- `Review Rules`: only the items on unnecessary nesting and confusing control flow.
