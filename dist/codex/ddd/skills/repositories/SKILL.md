---
name: "repositories"
description: "Use when adding or reviewing a repository: one per table, generic CRUD or query-builder interfaces, persistence records returned instead of domain objects, rules in repository code. The access contract; for new objects use $ddd:factories, for ORM or table shapes in domain classes $ddd:infrastructure."
---

# Repositories

Owns access to existing aggregates as part of the model: repositories exist for aggregate roots, their contract is defined by the model that uses them, and they return domain objects. Creating a new valid object is `$ddd:factories`; the mapping tools underneath are `$ddd:infrastructure`; deciding what is a root is `$ddd:aggregates`.

## When to use

- You add a data-access class or interface and need to decide what it should expose.
- There is a repository per table, or a generic `Repository<T>` with `findAll`, `findBy(criteria)` and raw query access.
- A repository returns rows, ORM entities or DTOs into domain code.
- Business conditions are being written inside repository implementations or in query strings.
- Client code needs to know how objects are stored.

## Rules

1. **Repositories exist for aggregate roots, not for every table.** Check: each repository's type is a root; child tables have no repository.
2. **Repository interfaces must be defined by the domain or application model that uses them.** Check: the interface lives with the model, and the implementation lives in infrastructure.
3. **Repositories must return domain objects or domain-oriented results.** Check: no row, record, DTO or ORM entity appears in a return type.
4. **Repository contracts must reflect intent where useful.** Check: method names say what the model asks (`overdueAsOf(date)`), not how storage answers.
5. **Repositories must not become universal query utilities.** Check: no method accepts an arbitrary query string or exposes a query builder.
6. **Use repositories to reconstitute and persist aggregates, and keep infrastructure mapping hidden behind the implementation.** Check: only the implementation imports the ORM or driver.
7. **Prefer focused repository methods over giant generic CRUD interfaces when domain intent matters.** Check: each method has a caller that needs exactly that question answered.
8. **Keep reconstitution paths separate from normal creation paths when that protects invariants.** Check: loading a stored object does not call the creation rules and creating one does not look like loading (`$ddd:factories`).
9. **Make client code independent of repository implementation details, while repository implementers understand those details.** Check: swapping the implementation for an in-memory one requires no client change.
10. **Express query criteria as specifications or model concepts when the criteria are domain rules.** Check: a rule like "overdue" is defined once in the model and the repository uses it (`$ddd:explicit-concepts`).
11. **Return domain objects or collections without exposing database structure.** Check: nothing in the result reveals column names, join shapes or pagination internals that the model did not ask for.
12. **Do not put business rules into repository implementations, create generic repositories that erase domain meaning, or let relational design dictate identity, associations or aggregate boundaries.** Check: the repository implementation contains no domain condition beyond what its query needs to translate.

## Procedure

1. List the repositories and their methods. Mark each by the root it serves; flag those serving non-roots.
2. For each caller, write the question it asks in domain words ("claims that have been quiet for 30 days").
3. Redefine the interface in the model's package with intention-revealing methods. Express any domain rule as a model concept the implementation can translate.
4. Move row and record types behind the implementation, with a mapper (`$ddd:infrastructure`).
5. Move business conditions found in the implementation into the model.
6. Provide an in-memory implementation for tests of the model (`$ddd:domain-tests`).
7. Run the tests; check that no client imports persistence types.

## Example

```python
# Before: a generic gateway leaks storage into the domain
class Repository(Generic[T]):
    def find_by(self, **criteria) -> list[dict]: ...
    def execute(self, sql: str) -> list[dict]: ...

stale = repo.execute("select * from claims where last_activity < now() - interval '30 days'")

# After: the model defines what it asks, and gets domain objects back
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Protocol

@dataclass(frozen=True)
class ClaimId:
    value: str

class Claim:
    def __init__(self, claim_id: ClaimId, last_activity: date):
        self.id = claim_id
        self.last_activity = last_activity

    def is_stale(self, as_of: date, grace: timedelta = timedelta(days=30)) -> bool:
        return as_of - self.last_activity > grace

class ClaimRepository(Protocol):
    def get(self, claim_id: ClaimId) -> Claim: ...
    def add(self, claim: Claim) -> None: ...
    def stale_as_of(self, as_of: date) -> list[Claim]: ...
```

The staleness rule lives on `Claim`. A SQL implementation translates it into a query under infrastructure; an in-memory implementation calls `is_stale` directly, and a test can check that both agree.

## Anti-patterns

- **Repository per table.** Detect: repository classes whose names match table names, including child tables.
- **Generic CRUD interface.** Detect: `Repository<T>` with `findAll`, `findBy`, `save` used for every type.
- **Universal query utility.** Detect: methods that take SQL, query strings or criteria bags.
- **Record leak.** Detect: return types that are rows, records or DTOs.
- **Rule in the implementation.** Detect: domain conditions in the repository's query-building code.

## Trade-offs and exceptions

- A generic repository base class is acceptable as an implementation helper under infrastructure when the public contracts remain focused and domain-defined (Added judgment).
- Added judgment: when a rule must run in the database for performance, the project is deliberately providing a translation (the source separates specifications from query concerns unless it does). Keep the domain definition as the single source of truth, keep the query translation beside it, and test the two against each other.
- Added judgment: read-only screens and reports often need joins across roots. The rules above govern the repository that loads roots for modification; do not distort the model to serve reporting.

## Verification

- [ ] Each repository serves one aggregate root and is defined in the model's package.
- [ ] Return types are domain objects.
- [ ] No arbitrary query surface is exposed.
- [ ] Domain rules used in queries are defined in the model.
- [ ] An in-memory implementation exists for model tests.

## Related

`$ddd:factories` for creation; `$ddd:aggregates` for what a root is; `$ddd:infrastructure` for mapping; `$ddd:explicit-concepts` for query criteria as specifications; `ddd-lifecycle-reviewer` to review a diff.

## Source

- `Repositories`
- `Explicit Concepts and Specifications`: only the rule to keep persistence querying separate from domain specifications unless the project deliberately provides translation.
