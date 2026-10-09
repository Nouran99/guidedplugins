---
name: table-driven
description: "Use when repeated if/else or switch chains map stable categories, ranges, conversions or dispatch to results, or a lookup table needs validating. Other branch problems: /code-complete:control-flow."
---

# Table-driven and data-driven logic

Replaces a long, repeated condition chain with data when the mapping is stable and explicit, and makes sure the data is obvious and validated. A branch that is not a mapping stays `/code-complete:control-flow`.

## When to use

- Several branches differ only in the values they return or the handler they call.
- A chain of range comparisons (`<= 1`, `<= 5`, `<= 20`) selects a rate, tier or label.
- The same category-to-value mapping appears in more than one routine.
- Configuration-like decisions (limits, prices, labels, feature rules) are written as code.
- A lookup table already exists and nothing checks that it is complete or consistent.

## Rules

1. **Prefer data-driven logic over long repeated condition chains when the mapping is stable and explicit.** Why: adding a row is safer than adding a branch. Check: the branches are parallel (same shape, different values) and the mapping changes by data, not by logic.
2. **Use tables or maps for configuration-like decisions.** Check: rates, limits, labels and dispatch targets live in one structure, not scattered through conditions.
3. **Keep the structure obvious and validated.** Check: the table has an explicit key domain; every legal key has an entry (a test enumerates the enum or the ranges); unknown keys fail loudly; duplicate or overlapping entries are rejected when the table is built.
4. **Do not hide complex logic in inscrutable data encodings.** Check: a reader understands a row without reading the interpreter; no bit-packed strings, positional arrays whose meaning is only in a comment, or rows that contain code in disguise.
5. **Use a table only when it is clearer, synchronized with the rules, and validated.** Compact rule. Check: there is one source of truth; the same rule is not also hard-coded as a branch elsewhere.
6. **Test data-driven logic with representative tables and edge cases.** Check: tests cover every category, both sides of every boundary and the missing-key case (`/code-complete:routine-testing`).
7. Added judgment: for range tables, state whether each bound is inclusive or exclusive, keep the rows sorted, and make the last row an explicit catch-all (`Infinity`, `MAX`) rather than an implicit fall-through.
8. Added judgment: for dispatch tables, give every handler the same signature and make a missing handler an error, not a no-op.
9. Added judgment: a chain of two or three branches that will not grow is fine as it is; reach for a table when you would add a branch to add a case.
10. Added judgment: keep logic out of the table. If a row needs a condition to interpret, that row belongs in code, or the table is a rule engine that needs its own design.

## Procedure

1. Read the chain and write, for each branch, key (or range) and result. If any branch needs more than a value or a handler, stop; this is not a mapping.
2. Decide the table's shape: map keyed by category, sorted list of range rows, or dispatch map of handlers.
3. Move the values into the table in one commit-sized step. Keep the old chain's tests unchanged.
4. Add the validation (completeness, duplicates, ordering) at construction or in a test.
5. Replace the chain with a lookup that fails loudly for an unknown key.
6. Search for the same mapping elsewhere and make it use the table.

## Example

```ts
// Before: a range chain; adding a tier means editing logic
function shippingFeeCents(weightKg: number): number {
  if (weightKg <= 1) return 500;
  else if (weightKg <= 5) return 900;
  else if (weightKg <= 20) return 1800;
  else return 4000;
}

// After: the mapping is data, sorted, with an explicit catch-all row
const SHIPPING_TIERS: ReadonlyArray<{ upToKg: number; feeCents: number }> = [
  { upToKg: 1, feeCents: 500 },
  { upToKg: 5, feeCents: 900 },
  { upToKg: 20, feeCents: 1800 },
  { upToKg: Infinity, feeCents: 4000 },
];

function shippingFeeCents(weightKg: number): number {
  const tier = SHIPPING_TIERS.find((t) => weightKg <= t.upToKg);
  if (tier === undefined) throw new RangeError(`shippingFeeCents: unsupported weight ${weightKg}`);
  return tier.feeCents;
}

// Validation (run in a test): rows ascend, so find() returns the tightest tier
console.assert(SHIPPING_TIERS.every((t, i, a) => i === 0 || a[i - 1].upToKg < t.upToKg));
```

For finite weights the results are the same as before. `NaN` used to fall into the last branch and now raises; validate weights at the boundary (`/code-complete:trust-boundaries`).

## Anti-patterns

- **Parallel branches.** Five `if` blocks that differ in constants. Detect: copy the block, change two literals.
- **Duplicated mapping.** The same category list in a `switch` and in a label function. Detect: add a category and edit two places.
- **Table of code.** Rows hold lambdas or flags that make the table a program. Detect: you must run a row to know what it does.
- **Incomplete table.** A new enum member compiles and silently maps to nothing. Detect: no test or type check enumerates the keys.
- **Positional encoding.** `["gold", 3, 0.1, true]` with meaning in a comment. Detect: a row can be read only with the comment open.
- **Overlapping ranges.** Two rows that both match a value. Detect: no test checks adjacent boundaries.

## Trade-offs and exceptions

- The source limits the technique to stable, explicit mappings. If the rules change by logic (a condition on two inputs, an exception per customer), a table hides the logic and code is clearer.
- A table moves a decision from code you can step through to data you must inspect. That is worth it when the data is validated and tested; otherwise it is a loss.
- For small closed sets with different behavior per case, a `switch` over an enum with an exhaustive check can be the clearer choice.
- Tables loaded from outside the program (files, databases) are trust boundaries and need validation on load (`/code-complete:trust-boundaries`).

## Verification

- [ ] The mapping has an explicit key domain and every legal key has a row.
- [ ] An unknown key fails loudly.
- [ ] No row needs code to be understood.
- [ ] The same rule does not also exist as a branch elsewhere.
- [ ] Tests cover each category, each boundary on both sides, and the missing key.

## Related

`/code-complete:control-flow` for branches that are not mappings; `/code-complete:data-types` for the key and value types; `/code-complete:routine-testing` for table-driven tests; `code-complete:table-reviewer` to review a diff.

## Source

- `Table-Driven and Data-Driven Rules`
- `Statement, Conditional, and Loop Rules`: only the rule on table-driven methods.
- `Testing Rules`: only the rule on testing data-driven logic with representative tables and edge cases.
