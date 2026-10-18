---
name: "bounded-contexts"
description: "Use when deciding where a model starts and stops, when one word means different things in different modules, or when domain types are shared by several contexts. Who owns a model; how two contexts relate: $ddd:context-relationships; folder layout: $ddd:modules-and-associations."
---

# Bounded contexts

Owns the inside of one context: every substantial domain area belongs to an identified context, its model is valid only there, and ownership is visible in the structure. How two contexts relate (Shared Kernel, Anticorruption Layer and the rest) is `$ddd:context-relationships`; wording inside one context is `$ddd:ubiquitous-language`; a core buried under generic mechanisms is `$ddd:distillation`; folder naming is `$ddd:modules-and-associations`.

## When to use

- A new feature touches an area and nobody can say which model it belongs to.
- `Customer`, `Product` or `Account` means something different to two teams, or two modules use the same class for different purposes.
- A `shared`, `common` or `core` package holds domain types used by several areas.
- A refactoring would merge two similar-looking models, or someone proposes a single enterprise-wide model.
- Two developers in one context keep reintroducing conflicting terms.

## Rules

1. **Every substantial domain area must belong to a clearly identified bounded context.** Check: you can name the context for each package or module in scope.
2. **A model is valid only inside its own bounded context.** Check: no claim in code or docs says a type means the same elsewhere without a translation.
3. **Do not import concepts from another context as if they were native.** Check: names from other contexts appear only at declared integration points.
4. **Translation across contexts must be explicit.** Check: a named mapper, adapter or contract exists wherever data crosses (`$ddd:context-relationships`).
5. **Shared models across multiple contexts are forbidden unless intentionally governed as a shared kernel.** Check: any shared type has a named owner set and a change process.
6. **Keep package, module or namespace ownership explicit.** Check: the context's name is a directory or package, and its owner is recorded next to it.
7. **Model `Customer` (or any term) separately in different contexts if the meanings differ.** Check: each context defines only the attributes and behavior it needs.
8. **Prefer context-specific contracts, IDs, published language or anticorruption layers over shared classes.** Check: cross-context references use identifiers or a documented exchange format, not a shared type.
9. **Prefer feature or context ownership in modules and packages; avoid generic folders that hide business boundaries.** Check: the top-level layout names business areas first.
10. **A bounded context must keep one internally consistent model, and its team members integrate terminology and model changes continuously.** Check: no concept has two competing definitions inside the context.
11. **Resolve conflicting meanings inside one context quickly through naming, tests and refactoring.** Check: a disputed term is either split, renamed or backed by a test that pins the chosen meaning.
12. **Do not build one giant company-wide domain model, a `shared/domain` package that erases boundaries, or reuse one aggregate type across unrelated contexts.** Check: no aggregate root is imported by two contexts.

## Procedure

1. Name the context you are in. If the area has no name, propose one in the experts' words and record it as provisional.
2. List the terms the context uses and note any that you also see elsewhere with a different meaning (`$ddd:language-audit` does this over a tree).
3. List the types shared with other areas. For each, decide: split into two models, move behind a shared kernel with owners, or replace by an identifier plus translation.
4. Make ownership visible: package names, a short context note beside the code, and the owning team.
5. Where two models meet, hand off to `$ddd:context-relationships` to choose the relationship.
6. Add a test that pins any disputed term's meaning inside the context (`$ddd:domain-tests`).

## Example

```text
Before                              After
src/shared/domain/customer.ts       src/sales/customer.ts      credit limit, pricing tier
                                    src/support/customer.ts    open tickets, preferred channel
```

```ts
// sales/customer.ts: only what selling needs
class SalesCustomer {
  readonly customerId: string;
  readonly creditLimitCents: number;

  constructor(customerId: string, creditLimitCents: number) {
    this.customerId = customerId;
    this.creditLimitCents = creditLimitCents;
  }

  canBuyOnCredit(orderCents: number): boolean {
    return orderCents <= this.creditLimitCents;
  }
}

// support/customer.ts: only what support needs; linked to sales by customerId, nothing else
class SupportCustomer {
  readonly customerId: string;
  private readonly openTicketIds: string[];

  constructor(customerId: string, openTicketIds: string[]) {
    this.customerId = customerId;
    this.openTicketIds = openTicketIds;
  }

  hasOpenTickets(): boolean {
    return this.openTicketIds.length > 0;
  }
}
```

## Anti-patterns

- **Company-wide model.** Detect: one `Customer` or `Product` class with fields for every department.
- **`shared/domain` package.** Detect: a directory of entities imported by more than one top-level area.
- **Foreign term copied in.** Detect: another context's status codes, field names or enum values inside local domain types.
- **Aggregate reused across contexts.** Detect: the same root imported by two contexts.
- **Implicit context.** Detect: packages organized only by technical role, so no context name is visible.

## Trade-offs and exceptions

- A shared kernel is allowed when it is small and jointly governed with named owners (`$ddd:context-relationships`). An ungoverned shared package is the thing to avoid.
- Contexts can be drawn at different sizes. Added judgment: start with the unit that one team and one vocabulary can own; split further only when a term starts meaning two things.
- Added judgment: identical-looking code in two contexts is not duplication to remove; the models change for different reasons.

## Verification

- [ ] The context of the touched code is named and its owner is known.
- [ ] No type is shared between contexts without a governed shared-kernel decision.
- [ ] Cross-context references use identifiers or a published format, with explicit translation.
- [ ] A term that differs between contexts is modeled separately in each.
- [ ] The package layout makes the context visible.

## Related

`$ddd:context-relationships` for choosing how contexts relate; `$ddd:map-contexts` for a repository-wide map; `$ddd:ubiquitous-language` for terms inside the context; `$ddd:modules-and-associations` for package layout; `ddd-context-boundary-reviewer` to review a diff.

## Source

- `Bounded Contexts`
- `Model Integrity Patterns`: only the continuous-integration rules for keeping one model consistent inside a context, and the Shared Kernel entry (small, jointly governed).
- `Code Generation Rules`: only the rule to keep bounded contexts visible in structure.
