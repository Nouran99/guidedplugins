---
name: "enterprise-patterns-data-mapper"
description: "Use when storage knowledge leaks into domain objects (SQL, column names or ORM base classes in the model), mapping code is repeated in callers, or you must decide if a Data Mapper is worth it. Interface shape is repository; coupled options are gateways-and-active-record."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Data Mapper

Decides whether a mapper layer is warranted and keeps mapping code outside the domain objects, explicit and testable. The interface that callers use to get objects is `enterprise-patterns-repository`; the coupled alternatives are `enterprise-patterns-gateways-and-active-record`.

## When to use

- A domain class contains `save(conn)`, column names, `cursor` or record-format handling.
- A domain class must extend an ORM base class, has fields that exist only because the table has them, or needs a public no-arg constructor for the framework.
- The same row-to-object conversion is written in several places.
- You must choose between a mapper and Active Record for a new area.

## Rules

1. **Use a Data Mapper when the domain model should stay decoupled from the database structure, the object-relational mismatch is real, or persistence logic deserves isolation.** The mapper is a cost, so it should buy an independence you can name. Check: you can name the mismatch (nested value objects versus flat columns, a hierarchy, many-to-many, derived fields).
2. **Put mapping code outside the domain objects.** Domain code that carries mapping cannot be used or tested without storage. Check: no domain class imports a driver, row type or cursor, and none contains SQL.
3. **Do not force domain objects to know SQL, record formats or mapping mechanics.** Domain objects that know SQL change whenever the schema does. Check: the domain package compiles and its tests run with no database installed.
4. **Keep mapping explicit and testable.** Mapping bugs are common, and otherwise visible only through the whole stack. Check: a test builds an object, writes it through the mapper, reads it back and compares, with no service or web layer involved.
5. **Do not let ORM convenience dictate all design decisions.** A model shaped by the ORM's needs rather than the domain's carries the framework everywhere. Check: the shape of domain classes (nullable fields, public setters, parameterless constructors, table-mirroring fields) is there because the domain wants it, or because you recorded a deliberate concession.
6. **Do not collapse aggregates, services and DTOs into one persistence model.** One class doing four jobs changes for four reasons and exposes internals to all four audiences. Check: no single class serves as table row, domain object, request body and response body at once.
7. **Do not default to Active Record for complex domains.** Complex domains with cross-object rules fight the one-row-one-object coupling. Check: if objects have cross-object rules, lifecycles or invariants, the mapper route is the one to take (see `enterprise-patterns-gateways-and-active-record` for the simple case).
8. **Keep one place for each type's mapping.** Added judgment: one mapper per type or aggregate, sharing small helpers for value types, so a column rename touches one file.
9. **A mapper copies state; it does not decide.** Added judgment: validation and business rules stay in the model; a mapper that rejects or repairs data is hiding a rule.
10. **If the ORM requires annotations on domain classes, treat that as a recorded trade-off.** Added judgment: annotations are mapping metadata inside the model. Prefer the ORM's external or imperative mapping when it exists; otherwise accept the annotations deliberately and keep them free of query logic.

## Procedure

1. List what the domain class knows about storage: SQL, column names, row types, framework base classes, lazy proxies.
2. For each, decide whether it is a real mismatch handled by a mapper or accidental coupling to delete.
3. Create the mapper beside the data-access code with `find`, `insert` and `update` (or the project's equivalent), moving the SQL and conversions out of the domain class.
4. Write the round-trip test first if none exists, then move code in small steps, running it after each.
5. Update callers to reach the mapper through the repository or the unit of work, not directly from handlers.
6. Delete the persistence members from the domain class.

## Example

```python
# Before: the domain object knows its table and SQL
class Customer:
    def __init__(self, id, name, credit_limit_cents):
        self.id, self.name, self.credit_limit_cents = id, name, credit_limit_cents
    def can_charge(self, cents):
        return cents <= self.credit_limit_cents
    def save(self, conn):
        conn.execute("update customers set name = ?, credit_limit_cents = ? where id = ?",
                     (self.name, self.credit_limit_cents, self.id))

# After: the domain class knows nothing about storage
class Customer:
    def __init__(self, id: str, name: str, credit_limit_cents: int):
        self.id, self.name, self.credit_limit_cents = id, name, credit_limit_cents
    def can_charge(self, cents: int) -> bool:
        return cents <= self.credit_limit_cents

class CustomerMapper:
    def __init__(self, conn):
        self.conn = conn
    def find(self, customer_id: str) -> Customer | None:
        row = self.conn.execute(
            "select id, name, credit_limit_cents from customers where id = ?", (customer_id,)).fetchone()
        return None if row is None else Customer(row[0], row[1], row[2])
    def insert(self, c: Customer) -> None:
        self.conn.execute("insert into customers (id, name, credit_limit_cents) values (?, ?, ?)",
                          (c.id, c.name, c.credit_limit_cents))
    def update(self, c: Customer) -> None:
        self.conn.execute("update customers set name = ?, credit_limit_cents = ? where id = ?",
                          (c.name, c.credit_limit_cents, c.id))
```

A round-trip test needs only an in-memory database: insert a `Customer`, `find` it, and compare the three fields. The domain tests for `can_charge` need no database at all.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Self-saving domain object | `save`, `load` or `to_row` methods on model classes | Move to a mapper; delete from the model |
| Schema-shaped model in a rich domain | Fields mirror columns, setters for everything | Reshape the model; let the mapper absorb the difference |
| One class for everything | Same class is row, entity, request and response | Separate the four; map explicitly at each edge |
| Rule-bearing mapper | Mapper methods with `if` on business state | Move the rule to the model |
| Mapping scattered | Row-to-object code in handlers and jobs | Centralize in the mapper |

## Trade-offs and exceptions

- A mapper is a cost. For simple, record-oriented work with accepted coupling, a gateway or Active Record is the better fit; the source says to use Active Record only when the domain logic is simple and persistence coupling is acceptable.
- Mapping metadata and generic mappers can reduce boilerplate when mapping rules are regular (`enterprise-patterns-query-and-metadata-mapping`), but not when they obscure exceptional behavior.
- Where the project has committed to an ORM that offers a unit of work and identity map, use them; the requirement stays the same: domain code does not depend on storage mechanics.

## Verification

- [ ] No domain class contains SQL, column names or driver types.
- [ ] A round-trip test exists for the mapper and runs without web or service layers.
- [ ] No single class is simultaneously row, domain object and transport shape.
- [ ] The mapper contains no business conditions.
- [ ] Callers reach the mapper through a repository or unit of work.
- [ ] The tests pass after each move.

## Related

`enterprise-patterns-repository` for the interface callers use; `enterprise-patterns-gateways-and-active-record` for the coupled alternatives; `enterprise-patterns-relational-mapping-structure` for how associations and values are laid out; `enterprise-patterns-persistence-reviewer` to review a diff; `enterprise-patterns-persistence-extractor` to carry out the extraction.

## Source

- `Persistence Pattern Rules`
- `Data Mapper`
- `ORM-Driven Everything`
- `Active Record`: only the rule not to default to it for complex domains.
