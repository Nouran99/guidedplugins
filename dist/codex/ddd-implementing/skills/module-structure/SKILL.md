---
name: "module-structure"
description: "Use when laying out or moving folders, packages or modules: a layer-only tree, a shared or common package, or directory names that hide the model. Layout only. Which context owns a class is bounded-context; what crosses between contexts is integration-contracts."
---

# Module structure

Owns how the repository's folders and packages show the model: contexts first, then domain and use-case ownership inside each context. It does not decide which context a concept belongs to (`$ddd-implementing:bounded-context`) or how contexts relate (`$ddd-implementing:context-mapping`).

## When to use

- You create a new package, module or top-level folder.
- The tree is `controllers/`, `services/`, `models/`, `repositories/` and every domain concept is spread across them.
- A `shared`, `common`, `util` or `core` package holds entities, enums or value objects.
- A newcomer cannot tell from the tree what the system is about.
- A move of files is proposed to "organize" the code.

## Rules

1. **[MUST] Make packages and modules reflect bounded contexts first.** The top level of the source tree names the contexts. Check: each top-level package or module is a bounded context or clearly technical platform code.
2. **[MUST] Within a context, organize around domain and use-case ownership, not only technical layers.** Layers inside a context are fine; layers instead of concepts are not. Check: inside a context you find domain concepts and use cases by name before you find `controllers` or `services`.
3. **[MUST NOT] Build a giant `shared` or `common` package for domain concepts.** Check: no entity, value object, enum or domain event lives in a package used by several contexts; shared technical code (logging, HTTP server) sits outside the contexts and holds no domain terms.
4. **[MUST] Keep the model visible in the structure.** Check: the names of folders and files can be read as the context's glossary (`renewal_policy.py`, `loan.py`), not `manager.py` and `helpers.py`.
5. **[SHOULD] Prefer the shape `context/domain`, `context/application`, `context/infrastructure`, `context/interfaces`** as the starting point for each context (the source's preferred example). Check: a reader can find the aggregates in `domain`, the use cases in `application`, adapters and persistence in `infrastructure` and transport in `interfaces`.
6. **[SHOULD] Keep infrastructure outside the model** (a step of the source's Primary Directive for decisions under uncertainty, not an unqualified rule). The domain package imports no persistence, web or messaging libraries. Check: no import in `domain` reaches `infrastructure` or `interfaces` of the same or another context.
7. **[MUST NOT] Let context boundaries exist only in diagrams.** A directory boundary is the cheapest real boundary. Check: every box on the context map has a directory (`$ddd-implementing:context-mapping`).
8. **[Added judgment] Name packages in the context's language** (`lending`, `billing`), not after teams or technologies. Check: the package names appear in the glossary or the map.
9. **[Added judgment] Enforce import direction with a test or build rule** (domain imports nothing from infrastructure; contexts import only each other's published contract). Check: a violating import fails the build.

## Procedure

1. List the contexts (`$ddd-implementing:bounded-context`); create or confirm one top-level package per context.
2. Group existing files by the context whose language they use; split files that mix two contexts' concepts.
3. Inside each context, create `domain`, `application`, `infrastructure` and `interfaces`, or the subset the context needs; place concepts by role.
4. Rename generic folders and files to the glossary's words where an equivalent exists.
5. Move technical-only code to a technical package outside the contexts (the example calls it `technical/`; avoid names that shadow standard-library modules, such as `platform` or `logging`); refuse domain terms there.
6. Move files with the tooling that updates imports; run the tests after each batch; keep the moves separate from any behavior change so they can be reviewed on their own, and leave committing to the user.

## Example

```text
# Before: technical layers at the top, domain concepts scattered, a shared grab bag
src/
  controllers/   loan_controller.py  member_controller.py  invoice_controller.py
  services/      loan_service.py  member_service.py  invoice_service.py
  models/        loan.py  member.py  invoice.py  copy.py
  repositories/  loan_repo.py  member_repo.py  invoice_repo.py
  shared/        enums.py  utils.py          # LoanStatus, InvoiceState, MemberTier ...

# After: contexts first, the model visible inside each
src/
  lending/
    domain/          loan.py  copy.py  renewal_policy.py  events.py
    application/     renew_loan.py  return_copy.py
    infrastructure/  postgres_loan_repository.py
    interfaces/      http_loans.py
  billing/
    domain/          invoice.py  late_fee.py
    application/     issue_invoice.py  write_off_invoice.py
    infrastructure/  postgres_invoice_repository.py
    interfaces/      http_invoices.py
  technical/         log_setup.py  http_server.py   # technical only; no domain terms
```

`LoanStatus` now lives in `lending/domain`, `InvoiceState` in `billing/domain`; nothing in `technical` knows either.

## Anti-patterns

- **Layer-only tree.** Detect: the top level is `controllers`, `services`, `models`, `repositories`.
- **Junk-drawer package.** `shared`, `common`, `core`, `util` holding domain types. Detect: domain classes imported from several contexts out of one package.
- **Name-free folders.** `manager`, `handlers`, `helpers`. Detect: files whose names do not occur in the glossary.
- **Mirror of the database.** Directories named after tables. Detect: a folder per table.
- **Boundary in the diagram only.** Detect: the context map has more boxes than the tree has top-level packages.

## Trade-offs and exceptions

- The source's directory example is an example, not a mandated naming scheme. Use the repository's existing convention for `interfaces` (`api`, `web`, `adapters`) when one exists.
- A small context may not need all four directories; do not create empty ones.
- In frameworks that require a fixed layout (convention-over-configuration), keep the framework's files where it needs them and put the model in a context package it imports. Added judgment: keep the framework directory thin.
- Splitting a large legacy tree is a multi-step migration; do one context at a time and keep behavior unchanged during moves.

## Verification

- [ ] The top level of the source tree names contexts (or platform code).
- [ ] Inside each context, domain concepts are visible by name.
- [ ] No `shared` or `common` package holds domain concepts.
- [ ] The domain directory imports nothing from infrastructure or interfaces.
- [ ] Every context on the map has a directory.
- [ ] The moves changed no behavior and the tests pass.

## Related

`$ddd-implementing:bounded-context` for ownership; `$ddd-implementing:ubiquitous-language` for names; `$ddd-implementing:context-mapping` for relationships; `ddd-implementing-context-boundary-reviewer` to review a diff.

## Source

- `Module and Package Rules`
- `Strategic Design Rules`: only the anti-patterns on a shared domain package and on boundaries that exist only in diagrams.
- `Primary Directive`: only the step to keep infrastructure outside the model, which orders choices under uncertainty and is applied here as SHOULD.
