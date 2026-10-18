---
name: "infrastructure"
description: "Use when ORM annotations, table shapes, serializers or framework types appear in domain classes, or domain classes take names from tables or columns. Own technical shapes; word choice: $ddd:ubiquitous-language; repository contract: $ddd:repositories; foreign models: $ddd:context-relationships."
---

# Infrastructure stays subordinate

Owns the relationship between the model and the system's own technical representations: persistence records, wire formats, framework types, caches. Infrastructure adapts to the model; the model is not bent to suit storage or transport. Foreign models from other teams, vendors or legacy systems are `$ddd:context-relationships`; deciding which layer owns a rule is `$ddd:layers`; picking the business word that replaces a table-derived name is `$ddd:ubiquitous-language`.

## When to use

- A domain class carries ORM annotations, lazy-loading hooks, `dirty` flags or serialization attributes.
- A class is named after a table or its fields after columns, or an entity gained a method only because the persistence library needs it.
- A request DTO or a JSON shape is used as the domain object, or the same class is the API input, the database row and the message payload.
- An aggregate boundary was drawn to make lazy loading or joins convenient.
- You are asked where mapping code between the model and storage or transport should live.

## Rules

1. **Infrastructure is subordinate to the model.** Check: deleting the persistence module would leave a model that still compiles against interfaces it owns.
2. **ORM mappings, serializers, external technical clients, delivery mechanisms, messaging details, caches and framework types stay out of the domain model.** Check: domain files import none of them.
3. **Infrastructure must adapt to the model, not the reverse.** Check: every adaptation (mapper, converter, repository implementation) sits on the infrastructure side of the dependency.
4. **Persistence shape must not define the domain shape.** Check: renaming a column changes a mapper, not a domain class.
5. **Translation is usually mandatory between domain objects and transport or persistence representations.** Check: a mapper or equivalent exists, or the model is unchanged by being mapped directly (see trade-offs).
6. **Map transport representations to local commands or domain inputs, and keep persistence models and integration models outside the core domain.** Check: controllers and consumers convert the payload before calling the model.
7. **Do not reuse one representation as delivery input, persistence record, domain object and integration message.** Four jobs, four change rates. Check: no class appears in more than one of those roles.
8. **Do not name domain concepts after database tables, design aggregates around lazy loading, or add methods to entities only because the persistence mechanism needs them.** Check: each entity method has a business meaning.
9. **Keep the model persistence-ignorant: do not shape types or boundaries primarily for ORM convenience.** Check: removing the ORM would not change which classes exist.
10. **Do not let relational design dictate object identity, associations or aggregate boundaries.** Check: aggregate boundaries were chosen from invariants (`$ddd:aggregates`), not from foreign keys.
11. **Keep infrastructure tests apart from domain tests.** Check: domain tests run with no database, queue or network (`$ddd:domain-tests`).

## Procedure

1. List the framework, ORM and transport types imported by domain files in scope.
2. For each, identify the domain concept it carries and the technical concern it adds.
3. Introduce the domain type if missing (often a value object, `$ddd:value-objects`), then a mapper on the infrastructure side. Keep the old representation as the persistence record.
4. Move persistence-only methods and flags off the entity into the record or the mapper.
5. Point controllers, consumers and repositories at the mapper; leave the model untouched by their changes.
6. Run the domain tests without infrastructure, then the infrastructure tests for the mapper (round trip and unknown values).

## Example

```ts
// Before: the rule is written against the row shape and drags a persistence flag with it
interface OrderRow { order_id: string; total_cents: number; currency: string; dirty?: boolean }

function applyDiscount(row: OrderRow, discountCents: number): void {
  row.total_cents -= discountCents; // can go negative; currency ignored
  row.dirty = true;
}

// After: the model owns the rule; the mapper owns the row
class Money {
  readonly cents: number;
  readonly currency: string;

  private constructor(cents: number, currency: string) {
    this.cents = cents;
    this.currency = currency;
  }

  static of(cents: number, currency: string): Money {
    if (!Number.isInteger(cents) || cents < 0) throw new RangeError("cents must be a non-negative integer");
    return new Money(cents, currency);
  }

  minus(other: Money): Money {
    if (other.currency !== this.currency) throw new Error("currency mismatch");
    return Money.of(this.cents - other.cents, this.currency);
  }
}

class Order {
  readonly id: string;
  private total: Money;

  constructor(id: string, total: Money) {
    this.id = id;
    this.total = total;
  }

  applyDiscount(discount: Money): void {
    this.total = this.total.minus(discount);
  }

  get amountDue(): Money {
    return this.total;
  }
}

class OrderMapper {
  static toDomain(row: OrderRow): Order {
    return new Order(row.order_id, Money.of(row.total_cents, row.currency));
  }

  static toRow(order: Order): OrderRow {
    return { order_id: order.id, total_cents: order.amountDue.cents, currency: order.amountDue.currency };
  }
}
```

## Anti-patterns

- **Table-named model.** Detect: domain classes whose names or fields match table and column names, including prefixes and `_id` suffixes.
- **One class, four roles.** Detect: the same type referenced by controller signatures, repository code, domain logic and event publishing.
- **Persistence method on the entity.** Detect: `markDirty`, `setVersion`, `toRecord` on domain types, or public setters added for the ORM.
- **Lazy-loading-shaped aggregate.** Detect: a boundary that matches a join or a loading strategy instead of an invariant.
- **Infrastructure test dressed as a domain test.** Detect: a "domain" test that needs a database fixture.

## Trade-offs and exceptions

- The rule set says translation is usually mandatory, not always. A mapping tool that fills an unmodified domain class without extra attributes, flags or shape changes keeps the model persistence-ignorant; judge by whether the model was bent, not by whether a hand-written mapper exists. Added judgment: ask whether deleting the mapping library would force any change to the model files.
- The rule set allows Smart UI for simple applications (`$ddd:layers`, `$ddd:right-sizing`). Added judgment: where the persistence record is the whole story, do not add mappers to code that has no model.
- Performance tuning follows model clarity. Optimize persistence paths after the model expresses the business correctly, and keep the tuning on the infrastructure side.

## Verification

- [ ] Domain files import no ORM, serializer, queue, HTTP or framework types.
- [ ] A mapper (or equivalent) sits on the infrastructure side and has its own tests.
- [ ] No class serves as both transport DTO and domain object.
- [ ] No entity method exists only for persistence.
- [ ] Domain tests run without a database or network.

## Related

`$ddd:context-relationships` for models owned by someone else; `$ddd:repositories` for the access contract; `$ddd:ubiquitous-language` for the replacement term; `$ddd:layers` for which layer decides; `ddd-infrastructure-reviewer` to review a diff; `ddd-translation-builder` to build a translation at one boundary.

## Source

- `Infrastructure`
- `Layered Architecture and Smart UI`: only the rule on when Smart UI is acceptable.
- `Translation at Boundaries`: only the rules on mapping between domain objects and transport or persistence representations.
- `Code Generation Rules`: only the rule to keep the model persistence-ignorant.
- `Scenario Walkthroughs`: only the rule that performance tuning follows model clarity.
- `Testing Rules`: only the rule that infrastructure tests stay separate from domain tests.
