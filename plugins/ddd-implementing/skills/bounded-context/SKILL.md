---
name: bounded-context
description: "Use when deciding which bounded context code belongs to, when one class or enum is used by several contexts, or when a model looks shared or global. Owns ownership and validity of a model. Folder layout is module-structure; data leaving a context is integration-contracts."
---

# Bounded context

Owns the first step of every DDD task: which context is this code in, and is the model valid only there. It does not lay out folders (`/ddd-implementing:module-structure`), choose how two contexts relate (`/ddd-implementing:context-mapping`) or translate at an edge (`/ddd-implementing:anticorruption-layer`).

## When to use

- You are about to add a class, event, endpoint or table and cannot say which context owns it.
- The same word (`Patient`, `Order`, `Product`, `Account`) appears in several modules with one shared class behind it.
- A `shared`, `common`, `core` or `domain` package is imported by more than one context.
- A reviewer says "that is Billing's concept" or "Support calls that something else".

## Rules

1. **[MUST] Name the bounded context before interpreting any term, module, service, repository, event, API, persistence or integration.** Without the context a word has no single meaning. Check: the design note or pull request starts with the context's name, and every touched file maps to exactly one context.
2. **[MUST] Make every substantial domain area belong to a named bounded context.** Unowned code drifts into whichever model is nearest. Check: a list of contexts exists in the repository and each name matches a top-level module, package or service.
3. **[MUST] Treat a model as valid only inside its bounded context.** A class that is right for scheduling is not thereby right for billing. Check: no class is used by two contexts with the same field set "because it is the same thing".
4. **[MUST] Respect that terms change meaning across contexts; do not unify them.** The same word with two meanings is normal, and merging the meanings breaks both. Check: where two contexts use one word, each has its own class with only the fields that context needs.
5. **[MUST NOT by default] Share model classes across contexts.** The default is separate models joined by identifiers and translation. Check: search each context for imports from another context's domain package (`grep -rn "from billing.domain" scheduling/`).
6. **[MUST NOT] Build one global company model.** One class that serves every team accumulates every team's fields and rules. Check: a single `Customer`, `Order` or `Product` class with fields that belong to three or more different business functions (Added judgment: a search aid, not a threshold of the source).
7. **[MUST NOT] Keep a shared domain package that crosses all contexts.** Shared packages turn into a hidden global model. Check: `shared/`, `common/` or `core/` containing entities, enums or value objects referenced by more than one context.
8. **[MUST NOT] Let context boundaries exist only in diagrams.** A boundary nobody can see in the code is not enforced. Check: each context is a module, package or service with its own domain package, and a cross-boundary import is visible in review.
9. **[MUST NOT] Integrate contexts by importing each other's domain classes.** That makes the two models one model. Check: no domain import crosses a context boundary; integration code lives at the edge (see `/ddd-implementing:integration-contracts` and `/ddd-implementing:anticorruption-layer`).
10. **[Compact checklist] When a term is reused across contexts, qualify it, split it or rename it before coding further.** The compact trigger asks for this decision first. Check: the two meanings are written down next to each context's name for the term.
11. **[Added judgment] Make a crossed boundary fail a build, not only a review.** A dependency rule in the build tool or an architecture test that rejects imports between context domain packages keeps rule 5 true after the reviewer leaves. Check: introducing a forbidden import breaks a test or the build.

## Procedure

1. Name the context. Read the module path, the package, the glossary and the nearest README; if two contexts are plausible, ask or state the assumption in one line.
2. List the domain terms in the change and which context gives each its meaning.
3. List imports the touched files take from other contexts and shared packages.
4. For every shared class, ask which context's meaning it carries. Split it into one class per context, keeping only the fields and behavior that context needs; connect the halves by a published identifier.
5. Move the integration to the edge and hand it to `/ddd-implementing:context-mapping` (relationship) and `/ddd-implementing:anticorruption-layer` or `/ddd-implementing:integration-contracts` (mechanism).
6. Run the tests after each split.

## Example

```ts
// Before: one Patient class, imported by scheduling/, billing/ and pharmacy/
export class Patient {
  id!: string;
  preferredLanguage!: string;
  availableSlots!: Slot[];     // scheduling
  insurancePlan!: string;      // billing
  balanceDue!: number;         // billing
  allergies!: string[];        // pharmacy
}

// After: each context owns the part of "patient" it needs
// scheduling/domain/scheduling-patient.ts
export class SchedulingPatient {
  constructor(readonly patientId: string, readonly preferredLanguage: string, private slots: Slot[]) {}
}

// billing/domain/account-holder.ts
export class AccountHolder {
  constructor(readonly patientId: string, private plan: InsurancePlan, private balanceDue: Money) {}
  applyPayment(payment: Money): void { this.balanceDue = this.balanceDue.minus(payment); }
}
```

`patientId` is the identifier published by the registration context; it is the only thing the three models share.

## Anti-patterns

- **The global model.** One class with fields for every team. Detect: a class whose fields are read by three or more unrelated modules (Added judgment: a search aid, not a threshold of the source).
- **The junk-drawer package.** `shared/domain`, `common/models`, `core/entities`. Detect: a package with no single owning context that several contexts import from.
- **Diagram-only contexts.** A context map in a wiki and one flat package in the code. Detect: no module boundary matches a box on the diagram.
- **Import integration.** Context A calls context B's repository or entity directly. Detect: an import path containing another context's `domain` segment.

## Trade-offs and exceptions

- A system with a single context is fine; name it anyway so the rule has an anchor and new contexts have somewhere to go.
- The source forbids sharing "by default", so a deliberately shared model is an exception that needs an explicit relationship in the context map and a named owner. Added judgment: keep it small and put its owner in the package name.
- Identifiers (a `patientId`) are the one thing contexts legitimately agree on; that agreement is a published contract, not a shared class.

## Verification

- [ ] The change states its bounded context in one line.
- [ ] No domain import crosses a context boundary.
- [ ] No class is used by two contexts with different meanings.
- [ ] No `shared` or `common` package holds domain concepts used by several contexts.
- [ ] The boundary is visible in the directory or build structure, not only in a diagram.
- [ ] Tests pass after each split.

## Related

`/ddd-implementing:module-structure` for layout inside and across contexts; `/ddd-implementing:context-mapping` for the relationship between two contexts; `/ddd-implementing:ubiquitous-language` for the words inside one; `ddd-implementing:context-boundary-reviewer` to review a diff; `/ddd-implementing:context-map` to reconstruct the map of a whole tree.

## Source

- `Strategic Design Rules`: only the Bounded Context Is Mandatory subsection and the strategic anti-patterns.
- `Bounded Context Is Mandatory`
- `Primary Directive`: only the first step of the "when uncertain" order.
