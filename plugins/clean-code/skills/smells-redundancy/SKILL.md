---
name: smells-redundancy
description: "Use when code repeats itself, contains unused code, or has layers that only forward calls. Smell family for duplicated logic, dead code and unused abstractions, unnecessary indirection and accidental complexity, with detection recipes and treatments."
---

# Redundancy smells

The general-design family about things that can simply be removed: duplicated logic, dead code, unused abstractions, indirection that carries nothing, and complexity the problem did not ask for. Dependency placement and change spread are `/clean-code:smells-coupling`; code that surprises is `/clean-code:smells-surprise`. The decision rule for choosing between designs is `/clean-code:emergent-design`.

## When to use

- The same condition, formula, query or parse appears in two places.
- A search for a function, flag, class or config key finds no caller.
- A method body is one call to another method with the same arguments.
- An interface has one implementation and no test uses it as a seam.
- Understanding a feature needs ten files for what is a ten-line idea.

## Rules

1. **Do not keep duplicated logic without a strong reason.** The same knowledge in two places means every change must be made twice and one will be forgotten. Check: change the rule mentally; count the places that must change.
2. **Eliminate duplication aggressively, matching the treatment to the shape.** A repeated expression becomes a named function; a repeated type or flag switch becomes polymorphism or a lookup table; a repeated sequence with variations takes the variation as a parameter; repeated test setup becomes a helper. Check: the second copy is gone, not hidden behind a copy-pasted wrapper.
3. **Tell duplicated knowledge from similar-looking code.** Added judgment: two blocks that look alike but change for different reasons are not duplication, and merging them couples what should be independent. A strong reason to keep two copies is that they evolve separately; write that reason where a reader will find it. Check: ask what would make each copy change; if the answers differ, leave them.
4. **Remove dead code.** Unreachable branches, unused functions, parameters, flags, exports and commented-out code only cost attention. Check: a repository-wide search, compiler or linter report, or coverage data shows no reference.
5. **Remove unused abstractions.** Interfaces with a single implementation and no seam purpose, factories that build one type, options nobody sets. Inline abstractions that no longer earn their cost. Check: you can name the change the abstraction makes cheaper.
6. **Avoid unnecessary indirection.** Pass-through methods, wrappers that only delegate, and layers that rename without translating make readers jump with nothing gained. Check: the method body is a single call that forwards its arguments unchanged.
7. **Avoid accidental complexity.** Complexity that comes from the tools or the author's cleverness rather than from the problem: custom frameworks for plain tasks, reimplementing standard functions, over-general code. Check: for each moving part, name the requirement that needs it.
8. **Delete with evidence and in separate steps.** Before removing exported or reflective code, check external consumers, serialized names, dynamic lookups and docs. Keep deletions out of behavior-changing diffs. Check: the deletion diff contains only deletions and the tests still pass.
9. **Do not replace duplication with a flag-laden super-function.** A merge that needs four booleans to describe the differences is worse than two clear copies. Check: the merged function has no parameter whose only job is to choose which copy it is.

## Procedure

1. Pick the touched code and a ring around it: callers, callees, siblings.
2. Run the detection recipes below. List candidates; do not delete yet.
3. For duplication, write the knowledge once in a sentence ("a late fee is 2% after 14 days"). If you can, one function should own it.
4. For dead code, confirm absence of use: searches for the name as a string, in config, in templates, in tests and in documentation.
5. For indirection, inline one layer at a time and run the tests.
6. Apply one treatment per step; run the tests after each.
7. Record candidates you did not act on.

Detection recipes (read-only):

- Duplication: search for distinctive literals, regular expressions, SQL fragments and long conditions; look for functions with the same shape and different names.
- Dead code: search for each exported name outside its file; look for commented-out code; check coverage for never-hit branches; look for flags always passed the same value.
- Indirection: search for methods whose body is a single `return other(...)` with the same arguments.
- Accidental complexity: count files touched by a typical small feature; list abstractions with one implementation.

## Example

```ts
// Before: the same rule in two places, a forwarding wrapper, and a dead branch
function lateFee(invoice: Invoice): number {
  return daysOverdue(invoice) > 14 ? invoice.total * 0.02 : 0;
}
function reminderText(invoice: Invoice): string {
  const fee = daysOverdue(invoice) > 14 ? invoice.total * 0.02 : 0;
  return `Pay ${invoice.total + fee} now`;
}
class InvoiceFacade {
  calcLateFee(i: Invoice) { return lateFee(i); }
}
if (config.legacyFees) { /* flag removed from every environment last year */ }

// After: one owner of the rule, no wrapper, no dead branch
const LATE_FEE_RATE = 0.02;
const GRACE_DAYS = 14;

function lateFee(invoice: Invoice): number {
  return daysOverdue(invoice) > GRACE_DAYS ? invoice.total * LATE_FEE_RATE : 0;
}
function reminderText(invoice: Invoice): string {
  return `Pay ${invoice.total + lateFee(invoice)} now`;
}
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Copy-paste logic | Same literal, regex, SQL or condition in two files | Extract and name; one owner |
| Parallel switches | Same discriminator switched in several places | Polymorphism or lookup table (see `/clean-code:smells-coupling`) |
| Dead function or parameter | No references outside its definition | Delete |
| Dead flag | Always the same value in every environment | Remove the flag and the losing branch |
| Commented-out code | Code inside comment markers | Delete |
| Single-implementation interface | One class implements it, no test double | Inline unless a seam is needed |
| Forwarding wrapper | Body is one call with the same arguments | Inline |
| Over-general framework | Generic machinery used by one caller | Replace with the specific code |
| Reimplemented standard function | Hand-written version of a library routine | Use the standard one |

## Trade-offs and exceptions

- Duplication across independent modules or services, kept so they can change separately, is a legitimate choice with a written reason.
- Some indirection is the boundary itself (`/clean-code:boundaries`) or a test seam; it earns its cost by protecting a change.
- Public and exported code may have users you cannot see. Deprecate before deleting.
- Generated code and vendored code are not cleaned here.
- Removing dead code is in scope only in the touched area, unless the user asks for a sweep.

## Verification

- [ ] Each rule or formula in the touched code has one owner.
- [ ] Every deleted item had no references by search, linter or coverage, and external consumers were considered.
- [ ] No forwarding wrapper or single-use abstraction remains that carries no meaning.
- [ ] Deletions are in a separate step from behavior changes.
- [ ] The tests pass after each removal.

## Related

`/clean-code:refactoring-steps` for the movement discipline; `/clean-code:emergent-design` for the decision rule; `clean-code:simplicity-reviewer` to review a diff; `clean-code:smell-scanner` for raw counts.

## Source

- `Smells to detect and eliminate`: the duplicated logic, dead code and unused abstraction, unnecessary indirection and accidental complexity smells.
- `Refactoring rules`
- `Hard rules`: only the rule against keeping duplicated logic without a strong reason.
