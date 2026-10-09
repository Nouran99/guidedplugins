---
name: repositories
description: "Use when writing or reviewing a repository interface or implementation: one per aggregate root, its methods, what it returns, and whether business rules or ORM rows leak through it. Persistence contract only. Client read models are client-representations; use-case code is application-services."
---

# Repositories

Owns the persistence contract of an aggregate root: how it is fetched, reconstituted and saved, in the language the use cases need. It does not shape reads for UIs and reports (`/ddd-implementing:client-representations`), orchestrate use cases (`/ddd-implementing:application-services`) or decide event persistence (`/ddd-implementing:event-sourcing`).

## When to use

- You add or change a `*Repository` interface or its implementation.
- A repository exposes `findAll`, `findBy(field, value)`, generic `save(entity)` or ORM query objects.
- A repository exists for each table, including child tables of an aggregate.
- A method returns rows, ORM entities or DTOs to domain or application code.
- A repository method contains an `if` that enforces a business rule.

## Rules

1. **[MUST] Create repositories for aggregate roots.** The root is the unit that is stored and reloaded. Check: one repository per root; none for a child entity or a value object.
2. **[MUST] Define repository interfaces in the domain or application code that needs them.** The persistence technology implements the contract; it does not dictate it. Check: the interface lives in the model's or the use case's package and imports nothing from the persistence layer.
3. **[MUST] Have repositories reconstitute and persist aggregates.** Check: a fetch returns a complete, valid aggregate root; a save persists the whole aggregate's changed state.
4. **[SHOULD] Make repository APIs reflect aggregate access needs, not generic table CRUD.** Check: each method exists because a use case asks for it, named in business terms (`openLoanForCopy`, `byId`), not `findAll`, `findBy(field, value)` or `update`.
5. **[MUST] Return domain objects or domain-oriented results, not ORM rows.** Check: return types are aggregates, value objects or small domain-named result types, never row, entity-manager or DTO types.
6. **[MUST NOT] Build giant generic repository abstractions.** `Repository<T>` with a dozen methods invites every use case to use all of them. Check: no generic base interface with `findAll`/`delete`/`update` that every repository inherits.
7. **[MUST NOT] Create a repository per table without aggregate thinking.** Check: tables that only hold an aggregate's children are not exposed as repositories.
8. **[MUST NOT] Put business rules in repository implementations.** Check: implementations contain mapping, queries and persistence concerns only; a conditional that encodes a business decision belongs in the model.
9. **[MUST NOT] Return persistence-layer entities into the domain.** Check: the mapped classes stay in the persistence package; the repository converts them.
10. **[MUST] Test repositories as infrastructure, separately from aggregate rules.** Check: repository tests run against the real or an in-memory-compatible store and check round-trip fidelity; aggregate rules are tested without a store (`/ddd-implementing:domain-tests`).
11. **[Added judgment] Keep list and search screens out of repositories.** A paged, filtered, joined listing is a read model (`/ddd-implementing:client-representations`). Check: no repository method returns a page of view data or takes filter parameters from a UI.

## Procedure

1. List the aggregate roots in the context; list the repositories. Remove or merge any repository for a non-root.
2. For each repository, list the use cases that call it and the methods they actually use. Delete the rest of a generic interface.
3. Rename remaining methods to the business question they answer; replace `update(entity)` with `save(aggregate)`.
4. Change return types to the aggregate (or a domain-named result); move mapping from row to aggregate inside the implementation.
5. Move any business conditional found in the implementation into the aggregate or a domain service and cover it with a domain test.
6. Add or adjust the repository test for round-trip persistence of the aggregate, including its child members and value objects.

## Example

```go
// Before: a generic, table-shaped contract that returns persistence rows
type Repository[T any] interface {
	FindAll(ctx context.Context) ([]T, error)
	FindBy(ctx context.Context, field string, value any) ([]T, error)
	Update(ctx context.Context, entity T) error
	Delete(ctx context.Context, id string) error
}

type LoanRow struct {
	ID     string `db:"id"`
	Status int    `db:"status"`
	CopyID string `db:"copy_id"`
}

// After: an aggregate-oriented contract in the domain package
package loans

var ErrLoanNotFound = errors.New("loan not found")

type LoanRepository interface {
	ByID(ctx context.Context, id LoanID) (*Loan, error)
	OpenForCopy(ctx context.Context, copyID CopyID) (*Loan, error)
	Save(ctx context.Context, loan *Loan) error
}

// package postgres: the rows stay here, and the repository reconstitutes the aggregate
func (r *LoanRepo) ByID(ctx context.Context, id loans.LoanID) (*loans.Loan, error) {
	var row loanRow
	err := r.db.GetContext(ctx, &row, `select id, state, copy_id, member_id, due_on from loan where id = $1`, id.String())
	if errors.Is(err, sql.ErrNoRows) {
		return nil, loans.ErrLoanNotFound
	}
	if err != nil {
		return nil, err
	}
	return row.toLoan()
}
```

`OpenForCopy` exists because "return a copy" asks for exactly that; no caller can ask for "all rows where field = value".

## Anti-patterns

- **Generic DAO.** `Repository<T>` or `CrudRepository` inherited everywhere. Detect: an interface with `findAll`, `save`, `delete` shared by all aggregates.
- **Repository per table.** A repository for `loan_line` next to `loan`. Detect: repositories whose type is a child of another aggregate.
- **Rule in the repository.** `if (status == OPEN && date.before(...))` in an implementation. Detect: conditionals on domain state inside a persistence class.
- **Row leak.** The domain imports a mapped persistence class. Detect: ORM annotations or row types in domain method signatures.
- **Query repository.** Pagination, sorting and filter parameters on a repository. Detect: methods that take `Pageable`, `Filter` or UI sort fields.

## Trade-offs and exceptions

- "Should reflect aggregate access needs" (rule 4) is a default; a small utility lookup that two use cases share is fine if it is named for the business question.
- The source requires a domain-oriented return, which may be a small result type rather than a full aggregate when a use case only needs a few fields; do not use that to reintroduce row shapes.
- Added judgment, a stricter reading than the source's ban on returning persistence-layer entities into the domain: if an ORM maps the aggregate classes directly, treat rules 5 and 9 as satisfied only when the mapping imposes no setters or no-argument constructors on the public surface, and confine mapping annotations to a configuration or package-private fields.
- Whether saving also publishes events is decided by the application service (`/ddd-implementing:application-services`), not by the repository.

## Verification

- [ ] One repository per aggregate root, none for children.
- [ ] The interface is defined by the domain or application code and imports nothing from persistence.
- [ ] Every method corresponds to a use-case question, named in business terms.
- [ ] Return types are domain objects or domain-named results.
- [ ] No business conditional in the implementation.
- [ ] A repository test checks round-trip persistence; aggregate rules have tests without a store.

## Related

`/ddd-implementing:aggregate-boundaries` for what the repository loads; `/ddd-implementing:client-representations` for read models; `/ddd-implementing:application-services` for the caller; `ddd-implementing:repository-reviewer` to review a diff.

## Source

- `Repository Rules`
- `Testing Rules`: only the rule to test repositories as infrastructure separately from aggregate rules.
