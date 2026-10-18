---
name: "infrastructure-isolation"
description: "Use when framework, ORM, persistence, REST or JSON types appear in domain code, when tables or API schemas drive the model, or when a domain method needs a request, session or serializer. For another team's model use $ddd-distilled:context-translation."
---

# Infrastructure isolation

Infrastructure is a detail of the business model, not its shape. This skill keeps technology types out of the domain and stops storage or transport from dictating the model. Another team's terms and codes entering your model are `$ddd-distilled:context-translation`; the thin coordinating layer is `$ddd-distilled:application-services`.

## When to use

- A domain class imports an ORM, web, serialization or messaging package.
- A domain method takes an HTTP request, a database session, a JSON node or a framework context.
- Classes were generated from tables, then given a few methods.
- A request or response object is stored in, or returned from, domain code.

## Rules

1. **Treat infrastructure as a detail.** Technology changes on a different schedule from the business. Check: ask what would change in the domain package if the database, web framework or message broker were swapped; the answer should be nothing.
2. **Keep frameworks, persistence mechanics, REST resources, transport formats and other technology concerns out of the domain model.** Check: imports in domain packages contain no ORM, HTTP, serialization or messaging packages.
3. **Persist aggregates without letting persistence define the model.** Check: model changes are driven by business rules; the tables and mappings follow the model, not the reverse.
4. **Translate transport and integration data at the boundary.** Check: controllers, consumers and persistence adapters map their data to domain types; domain code never sees a raw payload or row.
5. **Do not model persistence-first.** Check: no class was generated from a schema and then decorated with behavior.
6. **Do not reuse transport objects as domain objects.** Check: no request DTO, response DTO or generated API type is held by, or returned from, a domain method.
7. **Do not let domain methods depend on framework types.** Check: no domain method signature mentions a request, a session, a serializer node or a framework context.
8. **Isolate infrastructure at boundaries.** Check: adapters for storage, transport and external calls live in their own package, and the domain does not import it.
9. **Check the dependency direction by imports.** (Added judgment) Domain imports nothing technical; adapters import the domain. For finer layering rules use the `clean-architecture` plugin. Check: search the domain package for infrastructure imports.

## Procedure

1. List the imports of the domain files in the change; mark any that are framework, persistence, transport or serialization packages.
2. List domain method signatures that mention technical types.
3. For each leak, define the domain-shaped input or output the method really needs.
4. Move the framework-facing code into an adapter: mapping, annotations, request reading, serialization.
5. Make the adapter translate both ways and keep the domain unaware of it.
6. Run the domain tests without the framework on the classpath if you can; that proves the isolation.

## Example

```java
// Before: the domain class is a table row, a JSON shape and a request reader at once
@Entity
@Table(name = "reservations")
@JsonIgnoreProperties(ignoreUnknown = true)
public class Reservation {
    @Id @GeneratedValue private Long id;
    @Column(name = "stat") private int stat;

    public void confirm(HttpServletRequest request) {
        String actor = request.getHeader("X-User");
        if (stat != 1) throw new IllegalStateException(actor + " cannot confirm");
        stat = 2;
    }
}

// After: the domain has no framework imports
public final class Reservation {
    private final ReservationId id;
    private ReservationStatus status = ReservationStatus.REQUESTED;

    public Reservation(ReservationId id) { this.id = id; }

    public void confirm() {
        if (status != ReservationStatus.REQUESTED) {
            throw new InvalidTransition(id, status, "confirm");
        }
        status = ReservationStatus.CONFIRMED;
    }
}

// persistence adapter: knows the table and translates both ways
@Entity
@Table(name = "reservations")
class ReservationRecord {
    @Id @GeneratedValue Long id;
    @Column(name = "stat") int stat;
}
// JpaReservations implements the domain's Reservations interface and maps
// ReservationRecord to and from Reservation (mapping methods omitted)
```

The actor now arrives through the application service, which reads the header at the controller and passes a domain-level `Actor` where the rule needs one. `ReservationId`, `InvalidTransition` and `ReservationStatus` are assumed domain types.

## Anti-patterns

- **Persistence-first model.** Detect: classes mirror tables column for column, and rules appear as afterthoughts.
- **DTO as domain object.** Detect: generated API types flow into domain methods.
- **Framework in the signature.** Detect: domain methods taking request, session or context types.
- **Annotation pile-up.** Detect: a domain class carrying persistence, serialization and validation annotations for three frameworks.
- **Self-saving model.** Detect: domain objects that open connections or call HTTP clients.

## Trade-offs and exceptions

- Simple domains may use simple data structures, including persisted records used directly (`$ddd-distilled:pattern-economy`).
- Added judgment: the book asks for persistence mechanics to stay out of the model (rule 2), and this skill does not relax that. If the repository convention or the user explicitly accepts mapping annotations on domain classes, follow that (explicit user instruction and repo conventions outrank this book) and say in the review that it departs from rule 2, so the cost is a visible decision.
- Mapping costs code. Spend it where the model carries meaning, not on reference data.
- Repository design is not covered in this rule set; the `ddd-implementing` plugin goes further.

## Verification

- [ ] Domain packages import no framework, persistence, transport or serialization packages.
- [ ] No domain method signature mentions a technical type.
- [ ] No transport object is stored in or returned from the model.
- [ ] Mapping lives in adapters and runs both ways.
- [ ] The model was not shaped by the table layout.

## Related

`$ddd-distilled:context-translation`; `$ddd-distilled:application-services`; `$ddd-distilled:integration-styles`; `ddd-distilled-infrastructure-reviewer` to review a diff.

## Source

- `Architecture and Infrastructure Rules`
- `Code Generation Rules`: only the step to isolate infrastructure at boundaries.
- `Practicality Rules`: only the rule that simple domains may use simple services and data structures.
