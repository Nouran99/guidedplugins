---
name: "clean-architecture-persistence-independence"
description: "Use when the domain model is shaped by tables, when SQL, ORM mappings or gateway code carry business rules, or when rules need a real database. Web and injection markers belong to framework-independence, import direction to dependency-rule, port ownership and naming to ports-and-gateways."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Persistence independence

Owns the rule that the database is a detail: the domain is not shaped by tables, persistence code decides nothing, and policy runs without a real database. Web, injection and serialization markers are `clean-architecture-framework-independence`; rows appearing in a use-case signature are `clean-architecture-boundary-models`; the shape of the port is `clean-architecture-ports-and-gateways`.

## When to use

- A class has one field per column and a `save()` method, and the domain is built from such classes.
- A `where` clause, stored procedure, trigger or ORM query method encodes eligibility, pricing or state transitions.
- A gateway implementation has methods named after business actions.
- A rule can only be tested after starting a database.
- You are introducing or reviewing a repository-style class.

## Rules

1. **Do not shape the domain model around tables.** `[MUST NOT]` Check: the domain class names and fields come from the business language; a column rename or a join table changes only the adapter.
2. **Use gateways to isolate persistence.** `[MUST]` Check: the domain and use cases reach storage only through gateway interfaces.
3. **Make business rules work without a real database.** `[MUST]` Check: a unit test runs the rule with an in-memory fake of the gateway.
4. **Do not let business rules read database rows or database-bound structures directly.** `[MUST NOT]` Check: a rule's inputs are domain values.
5. **Do not leave domain rules embedded in gateway implementations or database access.** `[MUST NOT]` unless explicitly required and justified. Check: gateway code contains lookups and writes, not conditionals about business meaning. Added judgment: a filter that encodes a policy (what counts as "overdue") duplicates it; define the policy in the domain and pass its parameters (a cutoff date) to a query.
6. **Do not design domain objects primarily around persistence convenience.** `[MUST NOT]` Check: no field, relationship or class exists only to make mapping easier.
7. **Keep the domain persistence ignorant and free of database access types.** `[MUST]` Check: the domain imports no driver, no ORM type and no query builder.
8. **Let infrastructure hold the database access details, implement the gateway interface, and never dictate domain shapes.** `[MUST]` Check: replacing the storage technology would change only infrastructure files.
9. **Treat gateways as just persistence adapters.** `[MUST]` Check: methods are load, save and query by a key or criterion expressed in domain terms; none is named for a business decision (`approve`, `qualify`, `renewIfAllowed`).
10. **Preserve the option to change the database until evidence justifies commitment.** `[MUST]` Check: you can describe how the first adapter would be replaced, even if you never will.
11. **Map explicitly between storage records and domain objects.** Added judgment: when the record and the domain object are identical today, the table is dictating the model; decide knowingly, as a partial boundary (`clean-architecture-boundary-economics`), not by accident. Check: the mapping function exists, or a note explains why it does not.
12. **Use database constraints as a backstop, not as the only home of an invariant.** Added judgment: a uniqueness or foreign-key constraint is a good safety net; the rule must still exist in the domain, where it can be tested and explained. Check: for each constraint that encodes a business rule, find the matching domain check.

## Procedure

1. Read the gateway implementations and query definitions in scope; list every condition, computed column and branching clause.
2. Classify each as lookup (by key or by a parameter) or policy. Move policy into an entity or use case and leave the lookup.
3. Replace table-shaped domain classes with domain objects named in business terms; keep the table-shaped record as an adapter type with explicit mapping.
4. Narrow the gateway interface to the operations the use case calls, in domain words (`clean-architecture-ports-and-gateways`).
5. Write an in-memory fake of the gateway, and test the rules with it (`clean-architecture-testing-seams`).
6. Keep one adapter test against the real database for the mapping and the queries.

## Example

```python
# Before: the renewal policy lives inside a SQL string
class LoanStore:
    def renewable_loans(self, member_id):
        return self.db.execute(
            "SELECT * FROM loans WHERE member_id = ? AND returned_on IS NULL AND renewals < 2 "
            "AND due_on >= date('now') "
            "AND NOT EXISTS (SELECT 1 FROM holds WHERE holds.book_id = loans.book_id)",
            (member_id,),
        ).fetchall()
```

```python
# After: domain/loan.py states the policy in plain code
from dataclasses import dataclass
from datetime import date

MAX_RENEWALS = 2


@dataclass(frozen=True)
class Loan:
    loan_id: str
    book_id: str
    due_on: date
    renewals: int

    def can_renew(self, today: date, has_hold: bool) -> bool:
        return self.renewals < MAX_RENEWALS and self.due_on >= today and not has_hold


# application/list_renewable_loans.py: coordination only
class ListRenewableLoans:
    def __init__(self, loans, holds, clock) -> None:
        self._loans, self._holds, self._clock = loans, holds, clock

    def execute(self, member_id: str) -> list[str]:
        today = self._clock.today()
        return [
            loan.loan_id
            for loan in self._loans.open_loans_of(member_id)
            if loan.can_renew(today, self._holds.has_hold(loan.book_id))
        ]


# infrastructure/sqlite_loan_gateway.py: lookup by key, mapping to the domain object
class SqliteLoanGateway:
    def __init__(self, db) -> None:
        self._db = db

    def open_loans_of(self, member_id: str) -> list[Loan]:
        rows = self._db.execute(
            "SELECT loan_id, book_id, due_on, renewals FROM loans "
            "WHERE member_id = ? AND returned_on IS NULL",
            (member_id,),
        ).fetchall()
        return [Loan(r[0], r[1], date.fromisoformat(r[2]), r[3]) for r in rows]
```

The policy is now unit-testable with plain `Loan` values. If one hold lookup per loan is too slow, add a bulk method to the hold gateway (`books_with_holds(book_ids)`) in domain terms; the rule stays in `can_renew`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Table-shaped domain | One class per table with columns as fields and persistence methods on it | Model the business concept; keep a separate record type for the table |
| Rule in SQL | Eligibility, state or pricing logic in a `where`, view, trigger or procedure | Move the rule to the domain; query by parameters |
| Smart gateway | Gateway methods named for decisions | Move the decision to an entity or use case |
| ORM entity as domain | One class used for mapping and for business behavior | Split into record and domain object |
| Database-gated test | A rule test that needs a running database | Test with a fake gateway |
| Persistence convenience | Fields or relationships present only for the mapper | Remove from the domain; handle in the adapter |

## Trade-offs and exceptions

- Isolating persistence has a price: mapping code and a second type. Where the domain is trivial and the table really is the model, a thin boundary may be the right call; record it as a decision (`clean-architecture-boundary-economics`).
- Added judgment: performance can justify set-based queries and database-side aggregation. Keep the question in domain terms, keep the policy definition in one place, and note the duplication if you must copy a rule into a query.
- Reporting and analytics that never touch business invariants can read the database more directly than transactional paths do. Added judgment: keep them out of the domain so they do not reshape it.
- Database constraints stay; they are a safety net (rule 12).

## Verification

- [ ] Domain class names and fields are business terms, not table or column names.
- [ ] No domain file imports a driver, ORM type or query builder.
- [ ] Gateway methods are lookups and writes; none decides.
- [ ] Each business rule is covered by a test that needs no database.
- [ ] One adapter test exercises the real mapping and queries.
- [ ] Swapping the storage technology would touch only infrastructure files.

## Related

`clean-architecture-boundary-models` for rows crossing a signature; `clean-architecture-ports-and-gateways` for the gateway interface; `clean-architecture-entities-and-invariants` for where the rule goes; `clean-architecture-import-direction-reviewer` to review a diff.

## Source

- `Non-Negotiable Rules`: rule 4, treating the database as a detail.
- `Database Leakage`
- `Domain Layer`: only the rules that the domain is persistence ignorant and imports no database access types.
- `Infrastructure Layer`: only database access details, replaceability, and the rule not to dictate domain shapes.
- `Review Checklist`: only the item that gateways are just persistence adapters.
- `Architecture Economics and Priority`: only the rule on preserving database options until evidence justifies commitment.
- `When Tradeoffs Are Necessary`: only recording a persistence-driven compromise.
