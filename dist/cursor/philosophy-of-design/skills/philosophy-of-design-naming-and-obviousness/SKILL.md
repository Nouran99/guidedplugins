---
name: "philosophy-of-design-naming-and-obviousness"
description: "Use when naming or renaming modules, methods, parameters and variables, when related operations differ in naming or argument order, or when code surprises a reader. Names reveal the abstraction; surprise counts as complexity."
license: "MIT"
metadata:
  plugin: "philosophy-of-design"
  book: "A Philosophy of Software Design"
  invocation: "auto"
---

# Naming and obviousness

Treats names, conventions and obviousness as design information. Prose in comments is `philosophy-of-design-comments-as-design`; the shape of the whole signature is `philosophy-of-design-interface-design`.

## When to use

- You are naming a new module, method or parameter.
- A name is vague (`data`, `handle`, `process`), names the mechanism, or is hard to choose.
- Sibling operations differ in verbs, argument order or failure behavior.
- A reader (or a reviewer) was surprised by what a call did.

## Rules

1. **Names must reveal the abstraction, not the internal mechanism.** Check: the name would still be true if the implementation were replaced.
2. **Use consistent names, argument order, error behavior and interface conventions for related operations.** Check: put sibling signatures side by side; verbs, order and failure mode match.
3. **Prefer obvious code, where a reader can infer behavior from local structure and names.** Check: ask a reader unfamiliar with the code what a call does; their guess should be right.
4. **Remove non-obvious behavior unless it is hidden behind a clear contract.** Check: each surprising behavior either goes away or is stated in the contract.
5. **Treat code that surprises a reader as complexity, even if it is short.** Check: a review question starting with "wait, does this also ...?"
6. **When naming is vague, mechanism-focused, inconsistent or surprising, reconsider the abstraction boundary instead of accepting a near miss.** Check: if three candidate names are all poor, the unit probably does two things or hides nothing.
7. **Use names and method shapes that reveal the abstraction (not the mechanism) at every public boundary.** Check: no public name contains a data structure, a protocol verb or a vendor name unless that is the abstraction.
8. **Follow existing conventions unless new information justifies changing them.** Compact checklist rule: it comes from the final checklist in `../philosophy-of-design-principles/references/mini.md`, not from a section of `full.md`. Check: grep for how the repository already names this concept before inventing a term.
9. **Added judgment: a name that needs `And`, `Or`, `Handle`, `Process` or `Manager` is a design signal.** It often means a function does two things or a module hides nothing. Check: try to name it as a noun-and-verb pair from the domain.
10. **Added judgment: one concept, one term across the repository.** Check: search for synonyms (`fetch`, `get`, `load`, `find`) used for the same kind of lookup.

## Procedure

1. List the names and signatures in the diff; for each, write what it promises in one sentence without reading the body.
2. Compare each against sibling operations: verb, parameter order, failure behavior.
3. Search the repository for existing terms for the same concept and reuse them.
4. For each hard-to-name unit, reconsider the boundary (`philosophy-of-design-split-or-merge`) before settling on a near miss.
5. For each surprising behavior, remove it or put it in the contract.
6. Rename in small steps with the tests passing; search for the old name in strings, configs and docs.

## Example

```ts
// Before: one concept (look up a record by id), three spellings: getUser, fetchOrder and loadInvoice.
// One returns null, one throws, one returns undefined. processData is separately vague.
function getUser(db: Db, id: string): User | null { /* ... */ }
function fetchOrder(orderId: string, db: Db): Order { /* throws when missing */ }
function loadInvoice(db: Db, id: string): Invoice | undefined { /* ... */ }
function processData(rows: Row[]): Row[] { /* drops duplicate postings, sums per account */ }

// After: same verb, same argument order, same absence behavior; outcome-revealing name
function findUser(db: Db, id: string): User | undefined { /* ... */ }
function findOrder(db: Db, id: string): Order | undefined { /* ... */ }
function findInvoice(db: Db, id: string): Invoice | undefined { /* ... */ }
function consolidateByAccount(rows: Row[]): Row[] { /* ... */ }
```

A reader who has seen `findUser` can predict `findOrder` without opening it; `processData` said nothing, `consolidateByAccount` states the outcome.

## Anti-patterns

- **Mechanism name.** `hashMapLookup`, `insertRowAndHash`. Detect: the name contains a structure or step, not an outcome.
- **Inconsistent siblings.** Same job, different verbs or argument order. Detect: parallel signatures that do not line up.
- **Surprising accessor.** `getBalance()` that performs a network refresh. Detect: a getter or query name on code with side effects or cost.
- **Vague container.** `data`, `info`, `result2`. Detect: names that would fit any variable.
- **Near-miss acceptance.** Keeping `ProcessManager` because nothing better came to mind. Detect: a name with a weak noun and a weak verb.

## Trade-offs and exceptions

- Existing conventions win unless new information justifies a change (rule 8, compact checklist); a consistent but imperfect name is better than a better name used in one place (Added judgment).
- Domain terms may look mechanical (`checksum`, `index`) and still be the abstraction; the rule is about hiding mechanism callers do not care about.
- Renaming a public name breaks callers; add the new name, deprecate the old.
- Short loop variables and well-known idioms are fine; obviousness is judged by the reader, not by length.

## Verification

- [ ] Every new public name still holds if the implementation changes.
- [ ] Sibling operations match in verb, argument order and absence/error behavior.
- [ ] No name in the diff is a vague container or a near miss.
- [ ] Every surprising behavior was removed or documented in a contract.
- [ ] The repository uses one term per concept in the touched area.

## Related

`philosophy-of-design-comments-as-design`; `philosophy-of-design-interface-design`; `philosophy-of-design-split-or-merge`; `philosophy-of-design-naming-reviewer` to review.

## Source

- `Naming, Consistency, and Obviousness`
- `Interface Design Rules`: only the rule on names and method shapes that reveal the abstraction.
