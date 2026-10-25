---
name: "ddd-ubiquitous-language"
description: "Use when naming or renaming domain types, methods, tests or modules, or when synonyms or one word with two meanings inside one context appear. One term per concept; names copied from tables or columns: ddd-infrastructure; stale docs and diagrams: ddd-model-driven-design."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Ubiquitous language

Owns the vocabulary inside one bounded context: the business terms experts use are the names in code, tests and modules, with one name per concept and one concept per name. Whether documents and diagrams match the code is `ddd-model-driven-design`; names that cross a context edge are `ddd-context-relationships`; classes and fields shaped by tables and columns are `ddd-infrastructure`.

## When to use

- You introduce a type, method, test or module for a business concept.
- Two names exist for one concept (`Booking`, `Reservation`, `Order`), or one name carries two meanings.
- A name comes from a table, a column, a DTO or a vendor field rather than from the business. Choose the business term here; cutting a table or DTO shape loose is `ddd-infrastructure`, and a vendor's field is `ddd-context-relationships`.
- Domain understanding improved and the code still uses the older, vaguer term.
- A name from another context has been imported into this one unchanged.

## Rules

1. **Use the exact business terms domain experts use inside the bounded context.** Check: each domain type name appears in the experts' own material (tickets, regulations, conversation notes) or is on the question list.
2. **One concept must have one name inside a bounded context.** Check: a concept-to-term table has no concept with two terms.
3. **One name must not mean different concepts inside a bounded context.** Check: the table has no term with two meanings. If it does, give the second meaning its own term, or recognize that two contexts are involved (`ddd-bounded-contexts`); do not tell the meanings apart with a comment.
4. **Method names, test names and modules use the same vocabulary as the domain.** Check: test names read as sentences an expert would accept.
5. **Rename code when the domain understanding improves.** A better word that lives only in conversation is a second vocabulary. Check: the rename is done in the same change that records the new understanding.
6. **Prefer names from the active bounded context.** Terms that matter to the context should appear directly in its types. Check: top-level types of the context are domain nouns, not roles like `Manager` or `Processor`.
7. **Prefer operation names that express the domain action** (a decision, a transition, a check) over generic `update`, `process` or `handle`. Check: the verb is one an expert would say aloud.
8. **Avoid technical placeholders when a precise domain term exists** (`Item`, `Record`, `Data`, `Info`). Check: if an expert can name it, the code can.
9. **Avoid names imported from another bounded context without translation.** The same word may mean something else there. Check: foreign names appear only inside translation code (`ddd-context-relationships`).
10. **Do not use technical names where the business has precise names, do not reuse a term for a different meaning for convenience, and do not keep a bad name because it already exists in the database.** Check: the database name is mapped in the persistence layer, not exposed in the model.

## Procedure

1. List the concepts in the touched code and the term currently used for each.
2. Look for the expert's term in tickets, specs, regulations, UI copy and test names. Where none exists, write the question and use the best current candidate, marked provisional.
3. Build or update the concept-to-term table for the context (`/ddd:language-audit` does this for a tree).
4. Rename with the language tooling or whole-word search; then check strings, serialized names, SQL, configuration, docs and tests for the old term.
5. Treat renames of public API, wire formats, events and database columns as decisions, not edits: propose them or keep the old name behind a translation.
6. Run the tests after each batch of renames.

## Example

```ts
// Before: three words for one thing; "cancel" hides two different business actions
class Booking {
  cancel(reason: string): void { /* guest and hotel both call this */ }
}
function createOrder(reservation: Booking): void { /* ... */ }

// After: one term, and the two actions experts distinguish get their own names
class Reservation {
  private state: "held" | "cancelled" | "withdrawn" = "held";

  cancelByGuest(): void {
    if (this.state !== "held") throw new Error("only a held reservation can be cancelled");
    this.state = "cancelled";
  }

  withdrawByHotel(reason: string): void {
    if (this.state !== "held") throw new Error("only a held reservation can be withdrawn");
    if (reason.trim() === "") throw new Error("a withdrawal needs a reason");
    this.state = "withdrawn";
  }

  get isHeld(): boolean {
    return this.state === "held";
  }
}
```

The two distinct actions are an assumption about this example's domain; in a real context the experts decide whether they differ.

## Anti-patterns

- **Synonym pair.** Detect: two type names or two verbs that experts treat as one concept.
- **Overloaded term.** Detect: one class used for two meanings, separated by a type field or a comment.
- **Schema-driven name.** Detect: identifiers carrying table prefixes, suffixes like `_flg`, or vendor field names. Pick the business term here; remove the table-shaped class or field with `ddd-infrastructure`.
- **Technical stand-in.** Detect: `Manager`, `Handler`, `Helper`, `Data` for a concept with a business name.
- **Imported foreign term.** Detect: a name from another context's API in domain code without a translation point.
- **Dual vocabulary.** Detect: meetings use a term the code lacks, and the code uses a term meetings never do.

## Trade-offs and exceptions

- Naming rules are per bounded context. The same word may legitimately mean different things in two contexts (`Customer`); the fix is explicit context ownership, not one shared definition.
- Added judgment: a provisional name is acceptable while a question to an expert is open; mark it and track it.
- Added judgment: technical operations that have no business meaning (a retry wrapper, a serializer) may use technical names, outside the model.

## Verification

- [ ] Each changed concept has exactly one term in this context, and each term one meaning.
- [ ] Method and test names use the context's vocabulary.
- [ ] No database, DTO or vendor name leaks into model types.
- [ ] A text search for the old term finds no stale references.
- [ ] Public API, event and column renames were not made silently.

## Related

`/ddd:language-audit` for a tree-wide term table; `ddd-language-reviewer` to review a diff; `ddd-model-driven-design` for documents and diagrams; `ddd-bounded-contexts` for where a term stops being valid; `ddd-infrastructure` for table-shaped classes and column-named fields; `ddd-supple-design` for how the named operations behave.

## Source

- `Ubiquitous Language`
