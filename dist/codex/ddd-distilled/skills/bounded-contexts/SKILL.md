---
name: "bounded-contexts"
description: "Use when one class or model is shared across billing, identity, catalog, fulfillment or support, when the same word has different rules in different modules, or when module layout ignores context boundaries. Inside one context; for links between two use $ddd-distilled:context-mapping."
---

# Bounded contexts

A bounded context is the boundary inside which one model and one language hold. This skill covers the inside: what a context owns, how its code is laid out, and what must not be shared. How two contexts relate is `$ddd-distilled:context-mapping`; the translator code at an edge is `$ddd-distilled:context-translation`; naming and renaming inside one context is `$ddd-distilled:ubiquitous-language`.

## When to use

- A class such as `Customer` or `Product` is imported by many modules and gains a field for every new concern.
- Two teams use the same word and mean different things, or ask for "one more column" that only matters to them.
- A boundary diagram shows separate contexts, but the import graph shows one tangle.
- A new area is starting and nobody has said where its model lives.

## Rules

1. **Give every meaningful model a bounded context.** A model without a home is shared by default and drifts. Check: for any class in the change, you can name its context; if two people name different ones, the model has no home.
2. **A context owns its language, rules and model semantics.** The words and rules are only reliable inside the boundary that defines them. Check: a rule about what "overdue" means is implemented in exactly one context.
3. **Make the code structure reflect the boundaries.** Boundaries that exist only on a diagram do not protect anything. Check: one top-level directory, package or module per context, and imports between them pass only through a declared contract or translator.
4. **Treat the same term in two contexts as two concepts until someone translates it.** A shared word hides a difference in rules. Check: write the one-line definition of the word in each context; any difference means separate types.
5. **A context also owns its tests and its integration contracts.** (Compact checklist) A rule tested in another context's suite is not owned. Check: the tests for a context's rules live with that context.
6. **Do not reuse one model across billing, identity, catalog, fulfillment and support.** One class serving all of them accumulates every consumer's fields and none of their meanings. Check: no class is imported as a domain type by three or more contexts. (Added judgment) The count of three is a search aid, not a rule of the book.
7. **Do not share domain classes that have subtly different meanings.** Check: when a shared class gains a field that only one consumer reads, split it.
8. **Do not leave context boundaries documented but ignored in code.** Check: compare the boundary diagram with the import graph; every crossing not on the diagram is a finding.
9. **Avoid giant shared domain packages.** A `shared` or `common` package full of domain types is a hidden second model. Check: such packages hold utilities only, and each domain type has one owner.
10. **Define the contexts early.** The earlier a model has an address, the less it drifts. Check: before the first class of a new area, the context has a name. (Added judgment) The minimum to write down is the name, a one-sentence purpose, the owner and its three most important terms; refine later.

## Procedure

1. Name the contexts the change touches. Propose names if none exist and mark them provisional.
2. Assign every type in the change to a context. A type that cannot be assigned is a finding.
3. List imports that cross a context boundary. Each must be a contract type or a translator; anything else is context bleeding.
4. For each word used in more than one context, write the definition per context.
5. When a shared class carries diverging meanings, split it into local types and link them by a plain identifier.
6. Update the context notes (name, purpose, owner, key terms) where the team will see them.

## Example

```ts
// Before: one Customer for the whole company
// shared/customer.ts
export class Customer {
  id!: string;
  creditLimit!: number;      // billing reads this
  paymentTerms!: string;     // billing reads this
  supportTier!: string;      // support reads this
  marketingOptIn!: boolean;  // campaigns read this
}

// After: each context models what it needs; the account number is the only link
// billing/payer.ts
export class Payer {
  constructor(
    readonly accountNumber: string,
    private readonly creditLimit: Money,
    readonly paymentTerms: PaymentTerms,
  ) {}
  canBeInvoicedFor(amount: Money): boolean {
    return amount.isLessThanOrEqualTo(this.creditLimit);
  }
}

// support/requester.ts
export class Requester {
  constructor(readonly accountNumber: string, private readonly tier: SupportTier) {}
  responseDeadline(openedAt: Date): Date {
    return this.tier.deadlineFrom(openedAt);
  }
}
```

`Money`, `PaymentTerms` and `SupportTier` are assumed value types. Neither file imports the other, and a change to support tiers no longer touches billing.

## Anti-patterns

- **Universal entity.** One `Customer`, `Product` or `Order` used by every concern. Detect: the class is imported from many places (three or more contexts, the same search aid as rule 6) and has fields no single reader uses together.
- **Diagram-only boundaries.** Detect: the architecture picture and the import graph disagree.
- **The `common/domain` package.** Detect: a package named shared, common or core that contains entities.
- **Same word, two meanings.** Detect: a grep for the term finds different rules in different modules.

## Trade-offs and exceptions

- A small, stable overlap may be shared on purpose under the Shared Kernel relationship, with joint ownership and tests. That is a decision made in `$ddd-distilled:context-mapping`, never a default.
- Do not split every noun into its own context. The test is a difference in language or rules, not a difference in file location.
- A small system can have one context. It still needs to be named and its language stated.
- A legacy tangle that cannot be split yet is treated as a context to contain, not as a model to spread.

## Verification

- [ ] Every type in the change has a named context.
- [ ] Imports across context boundaries are contracts or translators only.
- [ ] Each shared word has a definition per context.
- [ ] No domain class serves unrelated concerns of several contexts (three or more importing contexts is the search aid).
- [ ] The boundary diagram and the module layout agree.

## Related

`$ddd-distilled:context-mapping` for the relationship between contexts; `$ddd-distilled:ubiquitous-language` for words inside one context; `$ddd-distilled:map-contexts` to discover the as-found map; `ddd-distilled-context-boundary-reviewer` to review a diff.

## Source

- `Define Bounded Contexts Early`
- `Strategic Rules`
- `Use Context Mapping`: only the anti-patterns about one reused model, shared classes and boundaries ignored in code.
- `Code Generation Rules`: only the default avoidance of giant shared domain packages.
- `Review Rules`: only the missing bounded context ownership and context bleeding items.
- `Context Relationship Rules`: only the Shared Kernel condition and the rule to contain a Big Ball of Mud, used in the trade-offs.
