---
name: "client-representations"
description: "Use when a UI, REST endpoint, report or other client needs data shaped differently from an aggregate: serializing aggregates, per-client DTOs, projections, read models, query/command split, owner scope. Clients of this application; other contexts are integration-contracts; storage is repositories."
---

# Client representations

Owns what a client of this application sees and asks for: representations built for the client, queries that do not load aggregates, and explicit scope. It does not shape messages sent to other bounded contexts (`$ddd-implementing:integration-contracts`) or the persistence contract of an aggregate (`$ddd-implementing:repositories`).

## When to use

- A controller serializes an aggregate or a mapped entity directly.
- A screen needs data from several aggregates and the code loads them all and stitches them together.
- A list page uses repository methods with sort and filter parameters.
- Two clients (web and mobile, or public and admin) need different fields of the same concept.
- Access depends on a tenant, owner or organization, and the identifier is implicit or ambient.

## Rules

1. **[MUST] Use DTOs, projections, use-case queries, rendition adapters or mediators when client needs differ from the aggregate's shape.** The aggregate serves invariants; clients serve views. Check: no endpoint or view serializes an aggregate or a persistence entity.
2. **[MUST] Expose REST resources as application-facing representations, not aggregate internals.** A resource is a thing the client can reason about, named in the ubiquitous language. Check: resource fields come from a representation type, and an internal rename of the aggregate does not change the API.
3. **[MUST] Tailor representations for different clients without changing the domain model for each client.** Check: adding a field for the mobile app touches the representation and its builder, not the aggregate.
4. **[MUST] Compose multiple bounded contexts at the application or integration layer, not by merging their models.** Check: a view that needs two contexts is assembled by a query service or mediator that calls each context's contract.
5. **[MUST] Keep command behavior separate from query models when consistency, performance or representation needs justify the split.** Check: reads that join many aggregates or need sorting and paging use a read model; writes go through aggregates (the source states a justification condition, not a blanket mandate).
6. **[MUST] Keep scope identifiers explicit where context or ownership affects invariants or access.** Check: the tenant, owner or organization identifier appears in command and query signatures and in repository lookups; it is not read from a global or thread-local.
7. **[Compact checklist] When client rendering, query speed or representation needs pressure the model's shape, use projections, DTOs, use-case queries or adapters instead of enlarging or exposing aggregates.** Check: no aggregate gained a field or a collection only so a screen could read it.
8. **[Compact checklist] Keep client, foreign, persistence and infrastructure representations outside the domain model.** The compact final checklist asks for it as one scan. Check: no DTO, view type or JSON annotation appears in a domain class.
9. **[Added judgment] Make a representation independently versionable.** A wire field can be renamed or deprecated on its own schedule. Check: the representation type is separate from the domain type and has its own tests (a stored sample, for instance).
10. **[Added judgment] Source projections from a single place.** A read model fed by events or by queries on the write store should be rebuildable. Check: dropping the read model and rebuilding it gives the same data; no use case writes to it directly.

## Procedure

1. List the client's needs as fields and queries; ignore the aggregate's shape.
2. Define the representation type in the application or interface layer, named for the client's concept (`LoanSummary`).
3. Implement a use-case query that returns it: from a projection or a read-optimized query, not by loading aggregates and mapping.
4. For a view spanning contexts, build a mediator in the application layer that calls each context's published contract.
5. Put the scope identifier into every query and command signature and repository lookup.
6. Remove the aggregate from controller signatures; add a representation test; run the suite.

## Example

```ts
// Before: the endpoint serializes the aggregate; tenant comes from ambient state
app.get("/loans/:id", async (req, res) => {
  const loan = await loanRepository.byId(new LoanId(req.params.id));
  res.json(loan);                       // exposes internal fields, state enum, nested copy
});

// After: a representation built for this client; scope is explicit
export type LoanSummary = {
  loanId: string;
  title: string;
  dueOn: string;      // ISO date
  state: "open" | "returned";
};

export class LoanSummaries {            // use-case query over a read model
  constructor(private readonly db: ReadDb) {}

  async forMember(memberId: string, scope: LibraryScope): Promise<LoanSummary[]> {
    return this.db.query<LoanSummary>(
      `select id as "loanId", title, due_on as "dueOn", state
         from loan_summary
        where member_id = $1 and library_id = $2
        order by due_on`,
      [memberId, scope.libraryId],
    );
  }
}

app.get("/members/:memberId/loans", async (req, res) => {
  const scope = LibraryScope.from(req.authenticatedUser);
  res.json(await summaries.forMember(req.params.memberId, scope));
});
```

The `loan_summary` table is a projection owned by the read side; renaming `LoanState` in the model leaves the API unchanged.

## Anti-patterns

- **Aggregate on the wire.** `res.json(entity)`. Detect: domain or persistence types passed to a serializer.
- **View fields on the aggregate.** A getter or collection that exists for one screen. Detect: aggregate members used only by view code.
- **Load-and-stitch.** A request loads several aggregates to render a table. Detect: loops over repository calls in a controller or query.
- **One DTO for all clients.** A single `LoanDto` with every client's fields. Detect: many nullable fields, per-client flags.
- **Ambient scope.** Tenant or owner read from a global. Detect: repositories that call a context holder instead of taking a scope.
- **Domain annotations for the wire.** JSON or validation annotations on domain classes. Detect: serialization annotations in `domain`.

## Trade-offs and exceptions

- The source conditions the command/query split on need ("when consistency, performance, or representation needs justify the split"). A simple CRUD area needs no separate read model (`$ddd-implementing:core-domain-focus`).
- A representation may be built by mapping an aggregate when volumes are small; the rule is about not exposing the aggregate itself, not about forbidding mapping. Added judgment: map in the application layer, not in the aggregate.
- REST design details (hypermedia, status codes) are outside this rule set.
- Event-fed projections bring eventual consistency to reads; state it in the API documentation when a client could notice (see the sibling plugin `data-intensive-apps`).

## Verification

- [ ] No endpoint, view or report serializes an aggregate or a persistence entity.
- [ ] Each client concept has its own representation type.
- [ ] A view spanning contexts is composed in the application layer.
- [ ] Reads that outgrow the aggregate use a read model; writes go through aggregates.
- [ ] Scope identifiers appear explicitly in signatures and lookups.
- [ ] No aggregate gained a member only for a screen.

## Related

`$ddd-implementing:integration-contracts` for other contexts; `$ddd-implementing:repositories` for aggregate persistence; `$ddd-implementing:application-services` for the command side; `ddd-implementing-representation-reviewer` to review a diff.

## Source

- `Client Representation and Scope Discipline`
