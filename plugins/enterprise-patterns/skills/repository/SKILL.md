---
name: repository
description: "Use when defining or reviewing the interface domain or application code uses to read and store objects: a generic CRUD repository, finders shaped by columns, callers building queries. Mapping code is data-mapper; gateways and Active Record are gateways-and-active-record."
---

# Repository

Judges the collection-like interface that domain and application code use to get and store objects. How objects are copied to and from rows is `/enterprise-patterns:data-mapper`; choosing a gateway or Active Record is `/enterprise-patterns:gateways-and-active-record`; the shape of queries is `/enterprise-patterns:query-and-metadata-mapping`.

## When to use

- You write the interface a service will call to load or save an aggregate or entity.
- A repository has one method per table column, `findBy(field, value)`, or accepts SQL or a query builder from callers.
- One `Repository<T>` base class is used for every type "to save boilerplate".
- A repository method returns a DTO or an API response shape.

## Rules

1. **Make repositories speak in domain terms.** Parameters and return types are domain objects, identifiers and domain concepts. Domain callers should not need to know how storage is laid out. Check: no method signature mentions a table, column, SQL fragment or row type.
2. **Shape repository interfaces by domain access needs rather than table shape.** Each method answers a question the application asks (`overdueFor(customer, today)`), (a should-level rule in the source). A finder that answers a real question is one place to optimize, while a column finder pushes the question onto every caller. Check: every method has a caller in a use case; methods named `findByColumnX` for a column no use case queries are a finding.
3. **Hide query, mapping and storage details in the implementation.** Callers stay unchanged when storage changes. Check: swapping the storage engine would not change a caller.
4. **Do not let a repository become a generic gateway to everything.** The source forbids one CRUD abstraction for all domain and data access. A generic gateway turns every caller into a query writer and removes the domain vocabulary. Check: no `Repository<T>` with `findAll`, `findBy(map)` and `save` used for every type, and no `query(sql)` method.
5. **Do not shape repository APIs by tables instead of use cases.** A table-shaped interface carries every schema change into its callers. Check: the interface of an aggregate does not mirror its tables one to one.
6. **Do not return transport shapes.** A repository must not return HTTP-shaped DTOs or view models (see `/enterprise-patterns:layering`). A transport shape in a repository couples every caller to one delivery channel. Check: return types come from the domain.
7. **Present a collection-like interface over domain object access.** Added judgment: prefer `get`, `add` and intent-named finders; leave "save changes" to the unit of work when one exists (`/enterprise-patterns:transactions-and-unit-of-work`). A collection-like surface is the one that reads naturally in domain code.
8. **Use repositories where there is a domain model.** Added judgment: a table-oriented module or a report is better served by a table data gateway or a plain query, not by pretending to be a collection of domain objects.

## Procedure

1. List the questions the use cases ask of storage, in the words of the domain.
2. Write one finder per question, plus `get` by identity and `add`. Do not write finders no use case calls.
3. Make the interface a type in the domain or application layer; put the implementation in the data-access layer.
4. In the implementation, keep SQL and mapping private. If the same mapping is needed by two repositories, share it through a mapper (`/enterprise-patterns:data-mapper`).
5. Replace each use of a generic or table-shaped repository call by the named finder, one caller at a time, running the tests after each.

## Example

```python
from dataclasses import dataclass
from datetime import date
from typing import Protocol

@dataclass(frozen=True)
class Invoice:
    id: str
    customer_id: str
    due_on: date
    paid: bool

# Before: a generic repository; callers know the table and filter in memory
class Repository:
    def __init__(self, conn, table): self.conn, self.table = conn, table
    def find_by(self, **columns):
        where = " and ".join(f"{c} = ?" for c in columns)
        return self.conn.execute(f"select * from {self.table} where {where}", tuple(columns.values())).fetchall()

# caller: unpaid = Repository(conn, "invoices").find_by(customer_id=cid, paid=0)
#         overdue = [r for r in unpaid if r["due_on"] < today.isoformat()]

# After: the interface asks the domain question; the table stays private
class InvoiceRepository(Protocol):
    def get(self, invoice_id: str) -> Invoice: ...
    def overdue_for(self, customer_id: str, today: date) -> list[Invoice]: ...
    def add(self, invoice: Invoice) -> None: ...

class SqlInvoiceRepository:
    def __init__(self, conn): self.conn = conn
    def get(self, invoice_id: str) -> Invoice:
        row = self.conn.execute("select id, customer_id, due_on, paid from invoices where id = ?", (invoice_id,)).fetchone()
        if row is None:
            raise KeyError(invoice_id)
        return self._to_invoice(row)
    def overdue_for(self, customer_id: str, today: date) -> list[Invoice]:
        rows = self.conn.execute(
            "select id, customer_id, due_on, paid from invoices where customer_id = ? and paid = 0 and due_on < ?",
            (customer_id, today.isoformat())).fetchall()
        return [self._to_invoice(r) for r in rows]
    def add(self, invoice: Invoice) -> None:
        self.conn.execute("insert into invoices (id, customer_id, due_on, paid) values (?, ?, ?, ?)",
                          (invoice.id, invoice.customer_id, invoice.due_on.isoformat(), int(invoice.paid)))
    @staticmethod
    def _to_invoice(row) -> Invoice:
        return Invoice(row[0], row[1], date.fromisoformat(row[2]), bool(row[3]))
```

The before version also interpolates a table name and column names into SQL; the after version has no such surface. The date comparison compares ISO strings, which sort correctly; in a real schema use the database's date type.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Generic repository everywhere | One `Repository<T>` with `findBy(map)`, used for all types | Replace with one interface per aggregate or access area, with named finders |
| Table-shaped API | One method per column; interface mirrors the schema | Replace with the questions the use cases ask |
| Leaky query | Callers pass SQL, specifications of table columns or a query builder | Provide named finders, or a query object owned by the repository |
| Transport-shaped result | Returns response DTOs or view models | Return domain objects; map at the edge |
| Repository per table with no model | Domain is table-oriented | Use a table data gateway instead |

## Trade-offs and exceptions

- The source forbids the generic repository as the single abstraction for everything; a small shared base class for plumbing inside implementations is not what it forbids.
- A very small system may have a repository with three methods. That is not theater; the interface still states the questions.
- If the project uses Active Record or a gateway on purpose (simple domain, accepted coupling), do not add a repository on top of it.
- Under a committed domain-driven design, which objects have repositories is that plugin's call; this skill only checks the interface style.

## Verification

- [ ] No signature names a table, column, SQL or row type.
- [ ] Every finder has a use-case caller.
- [ ] No generic `Repository<T>` serves unrelated types, and no `query(sql)` method exists.
- [ ] No repository returns a transport shape.
- [ ] Storage details live only in the implementation.
- [ ] The tests pass after each replaced call.

## Related

`/enterprise-patterns:data-mapper` for the mapping code; `/enterprise-patterns:gateways-and-active-record` for coupled alternatives; `/enterprise-patterns:query-and-metadata-mapping` for query construction; `enterprise-patterns:persistence-reviewer` to review a diff; `enterprise-patterns:persistence-extractor` to extract data access.

## Source

- `Persistence Pattern Rules`
- `Repository`
- `Generic Repository Everywhere`
- `Layering`: only the rule against repositories returning HTTP-shaped DTOs.
