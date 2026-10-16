---
name: conditional-moves
description: "Use when about to perform Decompose Conditional, Consolidate Conditional Expression, Consolidate Duplicate Conditional Fragments, Remove Control Flag, guard clauses or Introduce Assertion. Checks side effects and order; polymorphic dispatch is in type-codes-and-switches."
---

# Conditional moves

Owns the six techniques that simplify a condition in place: what must be true before each, the safe steps and how to verify. Replacing a branch on a type with structure (polymorphism, null object, type codes) is `/refactoring-guru:type-codes-and-switches`; deciding that a comment should become an assertion is `/refactoring-guru:explanatory-comments`.

## When to use

- A condition or its branches take mental parsing to read.
- Several checks lead to the same action.
- Every branch of a conditional repeats the same statements.
- A variable exists only to break out of a loop or steer a branch.
- Special cases bury the normal path under nesting.
- Code silently relies on a state assumption.

## Rules

1. **Decompose Conditional when the condition or branches are hard to read:** extract the condition and each branch into named methods. Do not use it if extraction hides side effects. Check: the name of each extracted piece states the business meaning, and the branches' effects are still visible at the call.
2. **Before Consolidate Conditional Expression, verify that the conditions are free of side effects** (`MUST`). Do not use it if the checks differ in timing or side effects. Check: write the truth table for the old and the new form and compare.
3. **Extract a consolidated condition into a named query when the expression is complex** (`SHOULD`). Check: the query name reads as a question about the domain.
4. **Consolidate Duplicate Conditional Fragments only when moving the common code before or after the conditional preserves execution order** (`SHOULD`). Do not use it if branch-specific side effects change the ordering. Check: each branch's outputs and effect order match the original.
5. **Remove Control Flag when a variable only directs loop or branch flow:** replace flag checks with direct break, return or continue. Do not use it if the flag represents durable domain state. Check: loop exit behavior, including the last iteration and empty input.
6. **Before Replace Nested Conditional with Guard Clauses, identify the normal path and preserve special-case behavior** (`MUST`). Put special cases first and the normal path last. Do not use it when nesting communicates a required transaction or cleanup scope. Check: every branch still returns the same value and releases the same resources.
7. **Introduce Assertion to make a hidden state assumption explicit;** put it at the boundary of the assumption. Check: a deliberate violation fails the test with a clear message.
8. **Do not use assertions for normal validation or recoverable errors** (`MUST NOT`; the source forbids them for normal user input, expected absence and recoverable errors). Check: the assertion could only fail by a programming mistake.
9. **Do not introduce polymorphism for a simple conditional that is easier to read in place** (`MUST NOT`). Check: if the only change you consider is moving a branch into a class, return to rule 1.
10. **Keep evaluation order and count where conditions have costs or effects.** Added judgment: short-circuit evaluation order is behavior; a rewritten `a && b` that evaluates `b` first changes it. Check: if any operand can throw, mutate or be expensive, keep its relative order.

### Technique table

| Technique | Use when | Do not use when | Verify |
| --- | --- | --- | --- |
| Decompose Conditional | Condition or branches are hard to parse | Extraction would hide side effects | Branch behavior |
| Consolidate Conditional Expression | Several checks lead to one action | The checks differ in timing or side effects | Truth table |
| Consolidate Duplicate Conditional Fragments | All branches repeat code | Branch effects change the ordering | Branch outputs and order |
| Remove Control Flag | A variable only steers loop or branch flow | The flag is durable domain state | Loop exit behavior |
| Replace Nested Conditional with Guard Clauses | Special cases hide the normal path | Nesting expresses a required transaction or cleanup scope | All branches |
| Introduce Assertion | Hidden assumptions about state | Normal validation or recoverable errors | Tests fail clearly on violation |

## Procedure

1. Name the technique and read its "do not use when" cell.
2. List the conditions in the old form with their effects; mark any with side effects.
3. For consolidation, write the truth table over the inputs, including absent and boundary values.
4. Apply the change; keep the old form in version control, not as a comment.
5. Compare outcomes over the truth table inputs with a test (parameterized if the framework allows).
6. Stop when the normal path reads straight through (`/refactoring-guru:stop-and-defer`).

## Example

A shipping function nests its special cases. The two "free" conditions are side-effect free and lead to the same result, so they consolidate into a named query; the special cases become guard clauses.

```python
# Before
def shipping(order):
    if order.get("cancelled"):
        result = 0
    else:
        if order.get("virtual"):
            result = 0
        else:
            if order.get("total", 0) >= 100:
                result = 0
            else:
                result = 6
    return result

# After
def qualifies_for_free_shipping(order):
    return order.get("virtual") or order.get("total", 0) >= 100

def shipping(order):
    if order.get("cancelled"):
        return 0
    if qualifies_for_free_shipping(order):
        return 0
    return 6
```

Truth table check: for each combination of `cancelled` (absent, false, true), `virtual` (absent, false, true) and `total` (absent, 99, 100, 150) the old and new functions return the same fee. The two zero results were not merged into one condition with `cancelled` because the cancelled case is a different reason for the same fee, which keeps each rule independently editable (Added judgment).

## Anti-patterns

- **Consolidating effects.** Merging checks where one has a side effect. Detect: a call to a function that logs, mutates or reads a clock inside a merged condition.
- **Reordered short-circuit.** A rewritten condition that evaluates an expensive or fallible operand first. Detect: operand order differs between old and new.
- **Guard clause that drops cleanup.** An early return skipping a close or unlock. Detect: resources acquired before the first guard and released at the end.
- **Flag that is state.** Removing a flag that other code reads later. Detect: the flag variable is read outside the loop or branch it controls.
- **Assertion as input check.** `assert` on request data. Detect: the assert's operand comes from outside the program.

## Trade-offs and exceptions

- Nested conditionals may stay when nesting communicates transaction or cleanup scope.
- Merged conditions stay readable only if the name of the query is good; if you cannot name it, leave the checks separate.
- A control flag that models a durable domain state is not a control flag.
- Polymorphism over a repeated conditional is a different decision (`/refactoring-guru:type-codes-and-switches`).

## Verification

- [ ] A truth table or equivalent test compares old and new conditions.
- [ ] Merged conditions are side-effect free.
- [ ] Early returns do not skip cleanup.
- [ ] Evaluation order of costly or fallible operands is unchanged.
- [ ] Assertions guard invariants only.

## Related

`/refactoring-guru:type-codes-and-switches` for polymorphism and null object; `/refactoring-guru:composing-methods` for extracting the pieces; `refactoring-guru:method-body-reviewer` to review the result; `/refactoring-guru:explanatory-comments` for comments that mark assumptions.

## Source

- `Simplifying Conditional Expressions`: only the entries other than polymorphism and null object.
- `Conditional and Method Call Playbook`: only the Decompose Conditional, Consolidate Conditional Expression, Consolidate Duplicate Conditional Fragments, Remove Control Flag, guard clause and Introduce Assertion entries.
- `Conditional Safety`
- `Decision Anti-Patterns`: only the rule on assertions for normal input.
