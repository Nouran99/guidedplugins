---
name: modules-and-associations
description: "Use when organizing packages or directories, adding a field that references another domain object, or finding models, services, utils or helpers folders dominating the layout. Folder layout only; shared types: ddd:bounded-contexts; consistency: ddd:aggregates; hidden core: ddd:distillation."
---

# Modules and associations

Owns how the model is laid out and navigated: modules named for domain concepts and context ownership, concepts kept together when they change together, and associations only where they carry behavior or meaning. What must be consistent in one transaction is `/ddd:aggregates`; the boundary between models, including a package of domain types shared by several contexts, is `/ddd:bounded-contexts`; a core buried under generic code is `/ddd:distillation`.

## When to use

- You create a package, directory or namespace in a domain area.
- The top-level layout is `models/`, `services/`, `utils/`, `helpers/` or `controllers/` and no domain concept is visible.
- A domain concept's files are scattered across several technical folders.
- You add a reference between domain objects, or find a fully connected graph where everything reaches everything.
- Two-way references exist between objects and nobody can say why.

## Rules

1. **Model associations only when they support behavior or meaning.** Check: each association is used by a behavior or a rule that needs it.
2. **Prefer simpler, more navigable associations over fully connected object graphs.** Check: for each association, one direction of traversal is the common one and the other is a query.
3. **Reduce bidirectional associations unless the domain requires them.** Check: each two-way link states the rule that needs both directions.
4. **Reference other aggregates by identity unless direct traversal is part of an invariant boundary** (`/ddd:aggregates`). Check: fields to other roots are identifiers.
5. **Modules must communicate domain concepts and bounded context ownership.** Check: the name of each top-level module is a domain term or a context name.
6. **Organize modules around model meaning, not only technical layers.** Check: a feature or concept is in one place, with layers inside it if needed.
7. **Keep related concepts together when they change together, and split modules when different concepts evolve independently.** Check: a typical change touches one module; the version history shows two modules that never change together living in one.
8. **Use package names that match the ubiquitous language, and keep model concepts discoverable from the directory structure.** Check: a newcomer finds the code for a named business concept by listing directories.
9. **Avoid infrastructure-driven packaging that hides the domain.** Check: persistence, web and framework code sits beside or beneath the concept, not above it.
10. **Do not let `models`, `services`, `utils` and `helpers` be the dominant structure.** Check: none of them is a top-level directory in the domain area.
11. **Do not create associations only because the persistence mechanism supports them, or object graphs that make aggregate boundaries invisible.** Check: removing a persistence-only association breaks no behavior.
12. **Do not group modules by technical artifact while domain concepts are scattered.** Check: the concept-to-files map has few files per module boundary crossed.

## Procedure

1. Draw the top-level layout and name each module as a domain concept, a context or a technical role.
2. For each technical-role module, list the domain concepts whose files it holds. Group by concept instead.
3. Check what changes together using recent history (`git log --name-only`); keep those files in one module (Added judgment: a heuristic for finding seams, not a rule of the source).
4. For each association in scope, find the behavior that traverses it. Delete those with none; keep one direction where both exist; replace links to other roots with identifiers.
5. Rename modules to the language of the context. Move files in a separate step from other changes so the history is readable.
6. Run the tests after each move; check imports for cycles introduced by the move.

## Example

```text
Before                        After
src/models/claim.ts           src/claims/claim.ts
src/models/policy.ts          src/claims/claim-repository.ts
src/models/invoice.ts         src/claims/reserve-policy.ts
src/services/claim-service.ts src/billing/invoice.ts
src/services/billing-svc.ts   src/billing/invoice-schedule.ts
src/utils/dates.ts            src/policies/policy.ts
```

```ts
// Before: both directions, everything reachable from everything
class Customer { orders: Order[] = []; }
class Order    { customer!: Customer; lines: OrderLine[] = []; }
```

```ts
// After: the common traversal is kept; the other direction is a query on the repository
class Order {
  readonly id: string;
  readonly customerId: string;
  private readonly lines: OrderLine[] = [];

  constructor(id: string, customerId: string) {
    this.id = id;
    this.customerId = customerId;
  }
}

interface OrderRepository {
  ordersOf(customerId: string): Promise<Order[]>;
}
```

## Anti-patterns

- **Layer folders as the architecture.** Detect: `models`, `services`, `utils`, `helpers` at the top of the domain area.
- **Scattered concept.** Detect: one domain concept's files in four directories.
- **Association by ORM.** Detect: relationship fields whose only users are mapping annotations.
- **Fully connected graph.** Detect: a chain `a.b.c.d` used to reach data across several aggregates.
- **Infrastructure-first packaging.** Detect: top-level directories named `jpa`, `rest`, `kafka` containing domain classes.

## Trade-offs and exceptions

- Added judgment: technical layers inside a domain module are fine; the rule is that they must not be the dominant top-level structure.
- A bidirectional association is allowed when the domain requires both directions; say why in the code or the test.
- Added judgment: a shared utilities module for truly generic helpers (string handling, date arithmetic with no domain meaning) can exist outside the domain area; domain rules must not live there.
- Moving files is cheap in the model and expensive for history and merges; Added judgment: batch moves into one commit with no behavior changes.

## Verification

- [ ] Each top-level module name is a domain concept or a context.
- [ ] A domain concept's files are together.
- [ ] Every association has a behavior that traverses it.
- [ ] Links to other roots are identifiers.
- [ ] No `utils`/`helpers`/`models`/`services` directory holds domain rules.

## Related

`/ddd:aggregates` for consistency boundaries; `/ddd:bounded-contexts` for context ownership; `/ddd:distillation` for a core buried under generic code; `/ddd:ubiquitous-language` for module names; `ddd:module-reviewer` to review a diff.

## Source

- `Associations and Modules`
- `Code Generation Rules`: only the rule to prefer feature or context ownership in modules and packages.
