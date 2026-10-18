---
name: "ddd-implementing-domain-services"
description: "Use when a domain operation needs several domain objects and fits no single entity or value object, or when a class with a domain-sounding name only maps between schemas. Domain layer only; load-call-save use-case code is application-services; a rule on one entity belongs on that entity."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Domain services

Owns the narrow case where a domain decision genuinely belongs to no single entity or value object, and the related case of transforming domain information without putting behavior on the wrong object. Use-case orchestration (load, call, save, publish) is `ddd-implementing-application-services`; the decision about where a rule sits in an existing diff is `ddd-implementing-rule-placement-reviewer`.

## When to use

- An operation compares or combines two or more domain objects (a parcel and the couriers that could carry it).
- A `*Service` or `*Manager` class holds domain rules that only read other objects' fields.
- A class named like a domain concept (`PricingService`) actually maps between JSON and database rows.
- Domain information has to be transformed and neither object should own the conversion.

## Rules

1. **[MUST] Use a domain service for a domain-significant operation that requires multiple domain objects and fits no single entity or value object.** Check: you tried placing it on each participant first and can say why each fails (it would need the other's internals, or it is not that object's responsibility).
2. **[MUST] Name domain services in the ubiquitous language.** Check: the name is a business activity or policy (`CourierMatching`, `RenewalPolicy`), not `*Manager`, `*Helper` or `*Processor` (`ddd-implementing-ubiquitous-language`).
3. **[MUST] Use transformation services when domain information must be transformed without assigning behavior to the wrong object.** Check (Added judgment, a reading of the rule): the information is domain information that no single object should own, and putting the conversion on either object would make that class depend on the other.
4. **[MUST] Keep technical transformation, serialization, transport and persistence mapping outside the domain model.** Check: no domain service builds or parses JSON, XML, rows or DTOs.
5. **[MUST NOT] Move behavior into services to avoid modeling entities or value objects.** A service full of rules over an entity's fields is the entity's behavior in the wrong place. Check: for each service method, the data it reads belongs to one object whose class has no such method (`ddd-implementing-entities`).
6. **[MUST NOT] Hide technical mapping behind a domain-sounding service name.** Check: a class named `QuoteService` that only copies fields between schemas is a mapper in infrastructure, not a domain service.
7. **[Added judgment] Keep a domain service stateless and expressed over domain objects.** It receives entities, values or identities and returns domain results; it does not hold a database handle or request data. Check: constructor arguments, if any, are other domain collaborators (for example a policy), not clients.
8. **[Added judgment] Leave per-object rules on the object and put only the cross-object decision in the service.** Check: the service calls `courier.canCarry(parcel)` rather than re-implementing the courier's constraints.
9. **[Added judgment] Test it as pure domain code** with in-memory objects, no application service and no database (`ddd-implementing-domain-tests`).

## Procedure

1. State the operation in the business's words. Name the domain objects it needs.
2. Try each participant as the owner. If one fits, put the method there and stop.
3. If none fits, create the service in the domain package with a business name and a single public operation.
4. Put each participant's own rules on that participant (a `canCarry` on the courier), and keep only the combining decision in the service.
5. Move any JSON, SQL or DTO handling out to the infrastructure or interface layer.
6. Test the service with in-memory domain objects; run all tests after the move.

## Example

```java
// Before: rules about couriers and parcels live in a service that also serializes
class ParcelService {
    Courier assign(ParcelDto parcel, List<CourierDto> couriers) {
        Courier best = null;
        for (CourierDto c : couriers) {
            if (parcel.getType().equals("COLD") && !c.isRefrigerated()) continue;
            if (parcel.getWeightGrams() > c.getMaxLoadGrams()) continue;
            if (best == null || c.distanceKm(parcel.getPickup()) < best.distanceKm(parcel.getPickup())) {
                best = toCourier(c);
            }
        }
        audit.write(json.toJson(parcel));      // transport detail inside the "domain" service
        return best;
    }
}

// After: per-courier rules sit on Courier; the cross-object decision is a domain service
public final class CourierMatching {
    public Optional<Courier> bestFor(Parcel parcel, Collection<Courier> available) {
        return available.stream()
                .filter(courier -> courier.canCarry(parcel))
                .min(Comparator.comparing(courier -> courier.distanceTo(parcel.pickupPoint())));
    }
}
// Courier.canCarry(Parcel) holds the cold-chain and load rules.
// Distance implements Comparable<Distance>.
// The audit record is written by the application service, in infrastructure terms.
```

`CourierMatching` has no state and no JSON; the cold-chain rule can be tested on `Courier` alone.

## Anti-patterns

- **Behavior parking.** A service with `if (order.getStatus() ...)` rules about one entity. Detect: service methods whose parameters are one entity plus primitives.
- **Domain-named mapper.** `PricingService` that only converts schemas. Detect: a "service" whose body is field assignments between two types.
- **God domain service.** One service for the whole context. Detect: dozens of unrelated methods and a large constructor.
- **Stateful service.** A domain service holding the last result or a connection. Detect: mutable fields on a class named like a policy.

## Trade-offs and exceptions

- The source asks for the service only when the operation fits nothing else. Prefer an entity or value method first; a service that survives that attempt is the exception.
- Added judgment: the source does not say which shapes a transformation service converts or where it lives. This plugin keeps it in the domain for transformation of domain information that no single object should own, and sends translation of a foreign model to `ddd-implementing-anticorruption-layer`. Converting to and from wire formats or rows is outside the model (rule 4).
- Added judgment: loading and saving are the application service's work, so pass loaded objects into a domain service instead of giving it a repository.

## Verification

- [ ] Each service method needs several domain objects and fits none of them.
- [ ] The service name is a business term.
- [ ] No technical mapping or transport code appears in domain services.
- [ ] Per-object rules stayed on their objects.
- [ ] The service has no mutable state.
- [ ] Tests exercise it with in-memory domain objects.

## Related

`ddd-implementing-application-services` for orchestration; `ddd-implementing-entities` and `ddd-implementing-value-objects` for the first place to try; `ddd-implementing-anticorruption-layer` for mapping foreign models; `ddd-implementing-rule-placement-reviewer` to review a diff.

## Source

- `Domain and Transformation Service Rules`
