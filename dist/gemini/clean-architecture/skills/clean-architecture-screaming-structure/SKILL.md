---
name: "clean-architecture-screaming-structure"
description: "Use when creating or reorganizing folders, packages, modules or class names, or when the tree shows only controllers, services and models. Covers feature and use-case first layout, role-based naming and the default feature shape. What ships or changes together is component-grouping."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Screaming structure

Owns what the folder tree and the names announce. A newcomer reading the top two levels should learn what the application does, not which framework it uses. What is released or changed together is `clean-architecture-component-grouping`; a class that accumulates actions is `clean-architecture-service-sprawl`; a shared junk drawer is `clean-architecture-shared-code-coupling`.

## When to use

- You create the folders for a new feature or a new application.
- A tree lists `controllers`, `services`, `repositories`, `models` and `utils` at the top.
- You name a class, package or module and the candidates are `Manager`, `Handler`, `Processor` or `Service`.
- A reviewer asks which use case a file belongs to and nobody can tell from its path.

## Rules

1. **Prefer a feature and use-case oriented structure over generic technical buckets.** `[SHOULD]` Check: the top-level folders are business capabilities, not framework roles.
2. **Let the architecture scream the domain and application intent.** `[SHOULD]` Check: show someone only the top two levels of the tree and ask what the system does; the answer is not "a web app".
3. **Do not let generic technical buckets dominate the codebase; the tree should reveal use cases and business purpose.** `[MUST NOT]` Check: no single bucket (`services`, `helpers`, `models`) holds the majority of files.
4. **Use technical subfolders only where they do not obscure use-case ownership.** `[MUST]` Check: from any file's path you can tell which feature or use case owns it.
5. **Name modules and packages after business capabilities or use cases.** `[MUST]` Check: `permits`, `loan-renewal`, `shipping-quotes`; not `core`, `common`, `base`.
6. **Name use cases with action verbs from the application's own use cases.** `[MUST]` Check: `RenewPermit`, `QuoteShipping`; not `PermitProcessor`.
7. **Name ports by the role they play for the use case, and adapters by the external detail or delivery mechanism they adapt.** `[MUST]` Check: see `clean-architecture-ports-and-gateways`.
8. **Do not use a vague technical name where a precise role name exists: use case, policy, boundary, presenter, controller, gateway or entity.** `[MUST NOT]` Check: no `Manager`, `Helper`, `Util`, `Processor` or `Handler` remains where a role name fits.
9. **Justify any class named `Service`.** `[MUST]` Say why it is not a use case, an adapter or a domain object. Check: the justification fits in one sentence; if it does not, split the class (`clean-architecture-service-sprawl`).
10. **Use the preferred feature shape.** `[SHOULD]` Per feature or for the whole application: domain, application, adapters and infrastructure; with features: `feature/domain`, `feature/application`, `feature/adapters`, `feature/infrastructure`. Check: each directory's content matches its layer's responsibilities.
11. **Size the structure to the application.** Added judgment: a tool with one capability and a few files needs no four-layer tree per feature; create a directory when it holds something, and say what you skipped (`clean-architecture-boundary-economics`). Check: no layer directory contains only a single trivial file created for symmetry.

## Procedure

1. Write down the application's use cases in a sentence each, using the business's words.
2. Group them into capabilities; those become the top-level folders.
3. Inside a capability, create layer directories only for the layers that have content, in the order domain, application, adapters, infrastructure.
4. Place the main component (composition root) at the top level, outside the capabilities.
5. Move files with the language's refactoring tools, one capability at a time; update imports and run the tests after each move.
6. Rename vague classes to their role or use-case names; list any `Service` you keep with its justification.

## Example

```text
# Before: the tree announces the framework
src/
  controllers/   PermitController.ts   ReportController.ts
  services/      PermitService.ts      ReportService.ts
  repositories/  PermitRepository.ts   ReportRepository.ts
  models/        Permit.ts             Report.ts
  utils/         dates.ts              format.ts

# After: the tree announces the application
src/
  permits/
    domain/            Permit.ts  ExtensionPolicy.ts
    application/       RenewPermit.ts  RevokePermit.ts  PermitStore.ts   (port)
    adapters/          RenewPermitController.ts  PermitPresenter.ts
    infrastructure/    PostgresPermitStore.ts
  reports/
    domain/            ...
    application/       GenerateOccupancyReport.ts  ReportArchive.ts       (port)
    adapters/          ...
    infrastructure/    ...
  main.ts                                                                 (composition root)
```

The names `RenewPermit` and `GenerateOccupancyReport` are the use cases; `PermitStore` is a port named by role; `PostgresPermitStore` is the adapter named by the detail it adapts. `dates.ts` and `format.ts` went to the capability that actually uses them, or into the entity they describe.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Framework-shaped tree | Top-level folders named after framework roles | Regroup by capability and use case |
| Junk drawer | `utils`, `helpers`, `common`, `shared` growing by the week | Return each piece to its owner (`clean-architecture-shared-code-coupling`) |
| Vague class names | `Manager`, `Processor`, `Handler`, `Helper` | Rename by use case or role |
| Hidden ownership | A file whose path does not reveal its feature | Move it under the capability that uses it |
| Layer folders by symmetry | Empty or one-file layer directories created "for completeness" | Delete them until there is content |
| Service by default | A `*Service` for every entity | Split by use case |

## Trade-offs and exceptions

- Technical subfolders are fine when they do not obscure use-case ownership, for instance `adapters/web` and `adapters/postgres` inside a capability.
- Frameworks that dictate directories (a routes folder, a controllers folder, a pages folder) are details. Keep their required folders as the outermost adapter layer and put use cases beside them; the framework folder then contains thin files that call use cases. Added judgment.
- Renaming and moving files breaks imports, history and external references. Do it as its own step with the tests green, and propose renames of public packages rather than making them silently.
- Layer-first is acceptable for a small single-capability tool; the preferred shapes list both forms.

## Verification

- [ ] The top two levels of the tree name business capabilities.
- [ ] Every file's path reveals its capability, and its layer when layers exist.
- [ ] Use cases are named with action verbs; ports by role; adapters by detail.
- [ ] No `utils`, `common` or `base` package holds policy.
- [ ] Every class named `Service` has a one-sentence justification or was split.
- [ ] The tests pass after the moves and renames.

## Related

`clean-architecture-component-grouping` for what ships together; `clean-architecture-service-sprawl` for splitting a service; `/clean-architecture:new-feature` to build a feature into this shape; `clean-architecture-structure-reviewer` to review a tree.

## Source

- `Non-Negotiable Rules`: rule 7, organizing by use case.
- `Feature First Structure`
- `Naming Rules`
- `Preferred feature shape`
- `Review Checklist`: only the item that the project structure reflects the domain and use cases.
- `Utility Dumping Grounds`: only generic utility, shared, base or core folders as escape hatches.
