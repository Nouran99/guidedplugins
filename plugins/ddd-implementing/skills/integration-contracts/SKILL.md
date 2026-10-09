---
name: integration-contracts
description: "Use when data leaves a bounded context for another: a message, event payload, API response, identifier, or another context reading its tables. Shapes the outbound contract model. Inbound is anticorruption-layer; who owns a class is bounded-context; UI and API clients are client-representations."
---

# Integration contracts

Owns what leaves a context: explicit identifiers, integration messages and a contract model that is separate from the local model. Its mirror is `/ddd-implementing:anticorruption-layer` (what comes in). Events as facts inside the model are `/ddd-implementing:domain-events`; what a UI or REST client receives is `/ddd-implementing:client-representations`.

## When to use

- A domain event or aggregate is serialized and sent to a message broker or another service.
- Two contexts reference the same enum, status type or table.
- A downstream context needs data from an aggregate and you are tempted to pass the aggregate or its repository.
- A published payload has to survive a local rename.

## Rules

1. **[MUST] Use explicit identifiers and integration messages across contexts.** The other side needs to point at things and be told facts; it does not need your objects. Check: cross-context data is an identifier or a message, never a live reference to a domain object.
2. **[MUST NOT] Pass a local aggregate directly across a context boundary.** The receiver would depend on, and could mutate, internals. Check: no method parameter, queue payload or return type crossing a boundary is an aggregate or entity class.
3. **[MUST] Keep contract models separate from local models.** The contract changes when partners need it to; the local model changes when understanding improves. Check: the published type lives in its own module or package and has no behavior of the local model.
4. **[MUST NOT] Share enums across contexts that give them different semantics.** Check: no enum imported from another context's domain; each side maps the published code to its own type.
5. **[MUST NOT] Couple contexts through the database.** Check: no context queries or maps another context's tables, and no foreign key crosses a context's schema.
6. **[MUST NOT] Import another context's domain package.** Check: only the contract package may be imported across the boundary.
7. **[MUST] Compose multiple bounded contexts at the application or integration layer, not by merging their models.** Check: a screen or API that shows data from two contexts is assembled by an application-level query or mediator that calls each context's contract.
8. **[MUST] Use events to coordinate across contexts when immediate consistency is not required.** A synchronous call into another model couples release and failure. Check: coordination that tolerates delay travels as a published event or message, a named policy or a process step, not as a synchronous call into the other context's model (`/ddd-implementing:cross-aggregate-coordination` rule 6 for the in-context counterpart).
9. **[Added judgment] Publish a mapped message, not the raw domain event.** The source keeps domain event payloads local to the model and requires contract models to be separate from local models (rule 3), so the broker payload is produced by a mapper from the event, with no exception for events whose fields look like the contract. Check: the type on the wire is not the type raised inside the aggregate, and a mapper sits between them.
10. **[Added judgment] Make the contract versionable.** Carry an explicit schema version or a type name per version and keep old fields until consumers have moved. Check: a field can be added or deprecated without breaking an existing consumer's tests.
11. **[Added judgment] Name the contract in the receiver's world when you own both sides.** A message called `LoanOverdueNotice` states what the receiver needs better than the local `LoanBecameOverdue` event's internal shape. Check: the contract's field names make sense without knowing the publisher's model.

## Procedure

1. List what the other context actually needs: which facts, which identifiers. Do not start from the aggregate's fields.
2. Define the contract type in its own package: identifiers as plain values, amounts with units, times with zones, no behavior of the local model.
3. Write a mapper from the local model or domain event to the contract, placed in the application or infrastructure layer of the publishing context, not in the domain. Do not skip this step when the contract's fields happen to mirror the event's; a field-for-field copy is still a mapper.
4. Replace shared enums with published codes mapped on each side.
5. Cut direct database access: expose the data through a contract and let the owning context serve it.
6. Add a contract test that serializes a sample and compares it with a stored example, so accidental changes break a test.
7. Update the map entry (`/ddd-implementing:context-mapping`).

## Example

```java
// Before: the broker payload is the domain event, which holds a Loan aggregate
public record LoanBecameOverdue(Loan loan, Instant occurredAt) {}
// consumers import loans.domain.Loan and read loan.copy().shelfMark()

// After: the domain event stays local; a separate contract goes out
// loans/domain
public record LoanBecameOverdue(LoanId loanId, MemberId memberId, CopyId copyId,
                                LocalDate dueOn, Instant occurredAt) {}

// loans/published
public record LoanOverdueNotice(int schemaVersion, String loanId, String memberId,
                                String dueOn, String occurredAt) {}

// loans/infrastructure
final class LoanOverdueNoticeMapper {
    LoanOverdueNotice from(LoanBecameOverdue e) {
        return new LoanOverdueNotice(1, e.loanId().value(), e.memberId().value(),
                e.dueOn().toString(), e.occurredAt().toString());
    }
}
```

A consumer reads strings and a version; it never imports `loans.domain`.

## Anti-patterns

- **Aggregate on the wire.** An entity serialized to the broker. Detect: a message class with a domain type in a field, or a framework serializer pointed at an aggregate.
- **Shared status enum.** `OrderStatus` imported by billing and shipping. Detect: one enum file referenced from two context packages.
- **Table-sharing.** Two contexts read and write the same table. Detect: SQL or ORM mappings that name another context's table.
- **Leaky identifiers.** An internal surrogate key published as the identity. Detect: a published `id` that changes if the data is re-imported. Added judgment: publish a stable business identifier.

## Trade-offs and exceptions

- Inside one deployable with a single team, a published contract may be a plain class in a `published` package rather than a wire schema. The separation from the local model still applies.
- The source states no exception to rule 3: contract models stay separate from local models, and event payloads stay local to the model. Added judgment: when a team owns both sides and the local event already carries only identifiers and facts, the mapper may be a trivial field-for-field copy. The published type still sits in its own contract package, the mapper is still written, and the copy is re-checked whenever a payload field is renamed.
- Contract versioning and delivery guarantees (retries, duplicates, ordering) are not rules of this rule set. Added judgment: treat them as part of the contract and see the sibling plugin `data-intensive-apps` for the mechanics.

## Verification

- [ ] No aggregate or entity class crosses a context boundary.
- [ ] The published type sits in its own package and has no local behavior.
- [ ] No enum is shared between contexts with different semantics.
- [ ] No context touches another's database tables.
- [ ] Composition of several contexts happens in an application-level query or mediator.
- [ ] A contract test fails when the published shape changes.

## Related

`/ddd-implementing:anticorruption-layer` for the receiving side; `/ddd-implementing:domain-events` for the event inside the model; `/ddd-implementing:client-representations` for UI and API clients; `/ddd-implementing:context-mapping`; `ddd-implementing:translation-reviewer` to review a diff.

## Source

- `Context Integration Rules`: only the Identity Across Contexts subsection and its anti-patterns.
- `Identity Across Contexts`
- `Client Representation and Scope Discipline`: only the rule to compose several bounded contexts at the application or integration layer.
- `Domain Event Rules`: only the rules to use events across contexts when immediate consistency is not required and to keep event payloads local to the model.
