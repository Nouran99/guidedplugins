---
name: "call-signatures"
description: "Use when a function has many parameters, boolean flags that switch behavior, an argument order callers must memorize, or repeated argument groups. Reshapes the call, not the types behind it (primitive-obsession) or the function body (function-bodies)."
---

# Call signatures

How a call looks and what it asks of its callers: parameter count and grouping, flags, order, and which side supplies a value. The types that a parameter object should become are `$refactoring:primitive-obsession`; the inside of the function is `$refactoring:function-bodies`.

## When to use

- A call site reads `f(a, true, false, 3, null)` and needs the definition open to be understood.
- The same two or three arguments travel together through several functions.
- A function has a flag that makes it do one of two different things.
- Callers extract several fields from one object just to pass them on.

## Rules

1. **Replace repeated clumps with parameter objects or richer domain objects where appropriate.** Repeated groups are a missing concept. Check: the same group of parameters does not appear in more than one signature (three or more is the usual size worth a type; the count is Added judgment, the source says only "repeated").
2. **Remove boolean flags that switch behavior.** A flag means two functions share a name. Check: no caller passes a literal `true` or `false` to select behavior.
3. **Avoid signatures that require callers to memorize argument order.** Check: swapping two adjacent arguments of the same type would compile; if so, group them or name them.
4. **Introduce parameter objects for repeated argument groups.** Check: the object is built once and passed through, not rebuilt at every layer.
5. **Use Preserve Whole Object when callers pass several values from the same object.** Check: no call site unpacks an object field by field only to pass the fields on.
6. **Use Replace Parameter with Method when the receiver can obtain the value itself without hidden coupling.** Check: the callee can reach the value through its own state, and the reach does not add a global or ambient dependency (`$refactoring:hidden-dependencies`).
7. **Use Rename Method, Add Parameter, Remove Parameter, Parameterize Method or Replace Parameter with Explicit Methods to make caller intent clearer.** Check: each call site reads as an intention.
8. **Added judgment: change a signature in compatible steps.** Add the new form beside the old, make the old delegate, migrate callers, then delete the old (`$refactoring:small-steps`). Check: every intermediate state compiles.
9. **Added judgment: pick Parameterize Method for near-duplicates that differ by a value, and Explicit Methods when the parameter selects a different action.** Check: the choice is stated for each case.
10. **Added judgment: do not pass a whole object where it would couple the callee to an unrelated type.** Preserve Whole Object trades fewer parameters for a dependency on the object's type. Check: the callee is in the same module or conceptually about that object.
11. **Avoid reassigning parameters inside the body (compact checklist); where reassignment obscures what the input meant, use Remove Assignments to Parameters (owned by `$refactoring:function-bodies`, rule 10).** Check: no parameter is reassigned in a way that hides what the caller passed in; a working copy has its own name.

## Procedure

1. List parameters of the changed signatures and look for flags, repeated groups and same-typed neighbors.
2. For each flag, list its callers' literal values. If callers use constants, split into explicit methods.
3. For each repeated group, decide whether it is a concept (introduce an object, `$refactoring:primitive-obsession`) or incidental (leave it).
4. Apply the smallest move, with the old signature delegating during migration.
5. Run the tests after each migrated caller.

## Example

```ts
// Before: flag selects behavior; from/to travel together
function exportOrders(from: Date, to: Date, includeRefunds: boolean): Row[] {
  const rows = salesBetween(from, to);
  return includeRefunds ? rows.concat(refundsBetween(from, to)) : rows;
}
const sales = exportOrders(start, end, false);
const all = exportOrders(start, end, true);

// After: a range object and two explicit functions
interface DateRange { readonly from: Date; readonly to: Date }

function exportSales(range: DateRange): Row[] {
  return salesBetween(range.from, range.to);
}
function exportSalesAndRefunds(range: DateRange): Row[] {
  return exportSales(range).concat(refundsBetween(range.from, range.to));
}
const range = { from: start, to: end };
const sales = exportSales(range);
const all = exportSalesAndRefunds(range);
```

Both call sites now state their intent, and the results are the same rows in the same order as before.

## Anti-patterns

- **Flag argument.** Detect: a boolean parameter that selects a branch at the top of the body. Treat: Replace Parameter with Explicit Methods.
- **Positional soup.** Detect: five or more parameters (the count is Added judgment), or several of the same type. Treat: parameter object.
- **Unpack-and-pass.** Detect: `f(o.a, o.b, o.c)` repeated. Treat: Preserve Whole Object when coupling is acceptable.
- **Options bag that hides nothing.** Detect: a parameter object created at each call with every field set. Treat: ask whether the group is a concept; if not, leave the parameters.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- A boolean that is data (for example `visible: boolean` set from a field) is not a behavior-switching flag; leave it. (Added judgment)
- Parameter objects hide the order problem but can create a catch-all type; name them for a concept (`DateRange`), not for the function. (Added judgment)
- Public signatures are behavior for outside callers; use the compatible-steps approach or ask (`$refactoring:behavior-preservation`).

## Verification

- [ ] No call site passes a literal flag to select behavior.
- [ ] No signature has the same group of three or more parameters as another (the count is Added judgment).
- [ ] No call requires the definition to be understood.
- [ ] Old and new forms coexisted during migration, and the old one is gone or deliberately kept.
- [ ] Tests passed after each migrated caller.

## Related

`$refactoring:primitive-obsession` for the type behind a parameter object; `$refactoring:function-bodies` for body moves; `$refactoring:renaming` for Rename Method; `refactoring-signature-reviewer` to review a diff.

## Source

- `Long Parameter Lists`
- `Simplifying Calls and Conditionals`: only the call-oriented moves (Rename Method, Add Parameter, Remove Parameter, Parameterize Method, Replace Parameter with Explicit Methods, Preserve Whole Object, Replace Parameter with Method).
- `Data Refactorings`: only the rule on parameter objects.
- `Composing Methods`: only Remove Assignments to Parameters.
