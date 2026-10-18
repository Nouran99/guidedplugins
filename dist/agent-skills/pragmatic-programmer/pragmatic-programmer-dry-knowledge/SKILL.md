---
name: "pragmatic-programmer-dry-knowledge"
description: "Use when the same rule, validation, status mapping, calculation or config meaning exists in more than one place (UI, API, service, database, docs, tests), or before copying logic. Picks one owner per fact. Generated code and rule languages are `pragmatic-programmer-generators-and-dsls`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# DRY at the level of knowledge

DRY means do not duplicate knowledge, not merely text. This skill decides which representation of a fact is authoritative and what every other representation becomes. Tools that produce or hide copies (code generators, macros, rule languages) are `pragmatic-programmer-generators-and-dsls`; a map of every fact across a tree is `pragmatic-programmer-knowledge-map`.

## When to use

- The same business rule, validation limit, status meaning, calculation or configuration meaning appears in the UI, the API, a service, the database, docs or tests.
- You are about to copy a block and change it "just for this one case".
- A rule change needs edits in several layers and tests fail in only some of them.
- Two implementations of one concept disagree on an edge case.

## Rules

1. **Treat DRY as duplicated knowledge, not duplicated text.** [MUST] Two similar-looking blocks that encode different facts are not a violation; two differently written blocks that encode the same fact are. Check: for each candidate pair, say what fact each encodes; if the facts differ, leave them.
2. **Give a business rule one authoritative representation.** [SHOULD] Check: you can name the file, table or schema that owns it.
3. **Do not scatter validation for the same concept.** [SHOULD] Check: search for the limit, pattern or allowed values in every layer; there is one definition and the others call it or derive from it.
4. **Do not copy status semantics, mappings and calculations across layers.** [SHOULD] Check: "what does status X allow" has one answer in code.
5. **Do not repeat configuration and schema meaning inconsistently.** [SHOULD] Check: a key or field has one meaning and its default is defined once.
6. **Avoid duplicated process steps that can be automated.** [MUST NOT] Check: a step that appears in two scripts or two README sections is one script (`pragmatic-programmer-automation`).
7. **When a fact must appear in several artifacts, choose one owner and derive, generate, validate or trace the rest.** [Compact checklist] Check: each non-owner copy names how it stays in sync: deleted in favor of a call, derived at build or run time, generated, checked by a test or tool, or linked so a change cannot miss it.
8. **Do not copy logic because "layers need it too".** [MUST NOT] A layer needs the answer, not its own copy of the rule: call the owner, receive the result in the data, or hold a derived copy covered by a sync check. Check: no layer re-implements a decision the owner already makes.
9. **Do not copy and paste with minor edits "just for this one case".** [MUST NOT] If the cases differ in knowledge, express the difference as a parameter or a data row; if they do not differ, they are the same code. Check: no pair of near-identical blocks differs only by a literal.
10. **Do not leave one concept with several partially aligned implementations.** [MUST NOT] Pick the one that is right (by tests and the domain owner), converge the others on it and record the edge-case differences as decisions. Check: the edge cases of every implementation were compared before the owner was chosen.
11. **Do not abstract a coincidence.** [Added judgment] Two rules that look alike today but change for different reasons are different facts; merging them creates a coupling the source does not ask for. Check: could the two change independently? If yes, keep both.
12. **Prefer as owner the representation that cannot be bypassed.** [Added judgment] A database constraint for uniqueness or the server for authorization beats a client check; client copies are conveniences derived from it. Check: the owner is the one place the rule is enforced.

## Procedure

1. Name the fact in one sentence ("an order may be cancelled until it ships").
2. Find every representation: grep for the constants, patterns, enum names, SQL fragments, documentation statements and test fixtures. Include non-code: docs, config, migrations, scripts.
3. Compare behavior on edge cases and list the differences.
4. Choose the owner (rule 12) and say why.
5. Choose the relation for each copy: delete and call, derive, generate, validate or trace.
6. Add a test that pins the owner's behavior, including the edge cases. Redirect one copy at a time and run the tests after each.
7. Record the decision where a maintainer will see it: a comment at the owner naming the dependent copies.

## Example

The cancellation rule lives in three places that disagree.

```ts
type OrderStatus = "pending" | "paid" | "packing" | "shipped" | "delivered" | "cancelled";

// Before
// ui/OrderRow.tsx: forgets "packing"
const showCancel = order.status === "pending" || order.status === "paid";

// api/cancelOrder.ts
const open = ["pending", "paid", "packing"];
if (!open.includes(order.status)) throw new HttpError(409, "order can no longer be cancelled");

// reports/cancellable.ts: breaks as soon as a status such as "returned" is added
const rows = orders.filter(o => o.status !== "shipped" && o.status !== "delivered" && o.status !== "cancelled");

// After: one owner
// domain/order.ts
const CANCELLABLE: ReadonlySet<OrderStatus> = new Set<OrderStatus>(["pending", "paid", "packing"]);
export const canCancel = (order: { status: OrderStatus }): boolean => CANCELLABLE.has(order.status);

// api/cancelOrder.ts
if (!canCancel(order)) throw new HttpError(409, "order can no longer be cancelled");
// the order response carries `cancellable: canCancel(order)`; ui/OrderRow.tsx reads that field
// reports/cancellable.ts
const rows = orders.filter(canCancel);
```

The UI no longer holds the rule; it renders a field the server derived. Adding a status now forces one decision in one place.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Parallel validation | The same pattern, limit or allowed-values list in UI, API and database code | Choose the enforcing layer as owner; derive or call the rest |
| Enum mirror | The same status list typed in several files | One definition, imported or generated |
| "Layers need it too" copy | A service re-implements a decision a lower layer already makes | Call the owner or carry the result in the data |
| Documentation drift | A README or comment states the rule differently from the code | Link to the owner, or generate the text |
| Partially aligned twins | Two functions for one concept with different edge cases | Converge on one, record the differences as decisions |
| Over-DRY helper | A shared function whose parameters grew one flag per caller | Split it; the callers had different facts |

## Trade-offs and exceptions

- The source defines the target as duplicated knowledge. Repeated text that encodes independent facts is not a violation, and merging it adds coupling.
- A client-side copy for responsiveness is acceptable when it is derived from, or tested against, the owner (Added judgment).
- Sharing code between independently deployed services couples their releases. Prefer a contract or schema as the owner and generated or validated copies (`pragmatic-programmer-generators-and-dsls`, `pragmatic-programmer-reversible-choices`). Added judgment.
- A test that restates a rule as concrete examples is a second witness, not duplication; it is how a change to the owner gets noticed.
- Removing a duplicate is itself a change. Do it when the fact is changing, already disagrees, or sits in code you are editing; list the rest.

## Verification

- [ ] Each fact the change touches has a named owner.
- [ ] Every non-owner copy is deleted, derived, generated, validated or traced.
- [ ] Edge cases of all copies were compared before the owner was chosen.
- [ ] A test pins the owner's behavior.
- [ ] No two rules that change for different reasons were merged.

## Related

`pragmatic-programmer-knowledge-map` for a tree-wide inventory; `pragmatic-programmer-knowledge-duplication-reviewer` to review a diff; `pragmatic-programmer-knowledge-consolidator` to carry out a consolidation; `pragmatic-programmer-generators-and-dsls` for generated copies; `pragmatic-programmer-automation` for duplicated process steps.

## Source

- `DRY Rules`
- `Knowledge Duplication`
- `Review Rules`: only the instruction to look for duplicated knowledge, not just duplicated lines.
- `Code Generation Rules`: only the default of one clear source of truth for each rule and the avoidance of copy and paste rule duplication.
