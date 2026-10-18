---
name: "gateways-and-active-record"
description: "Use when choosing a persistence pattern for simple or table-shaped work: Row Data Gateway, Table Data Gateway or Active Record, a report building objects per row, or Active Record spreading into a complex domain. Decoupled domains use data-mapper and repository."
---

# Gateways and Active Record

Chooses and polices the persistence patterns that accept coupling between the code and the table or record: Row Data Gateway, Table Data Gateway, Active Record. Where the domain must stay decoupled, use `$enterprise-patterns:data-mapper` and `$enterprise-patterns:repository`. A gateway to an external system is `$enterprise-patterns:integration-boundaries`.

## When to use

- A feature is record-oriented (maintain a row of settings, lookup data) or table-oriented (reports, set calculations, bulk updates).
- A framework offers Active Record models and you must decide how far to use them.
- A report or calculation builds an object for every row only to sum a column.
- An Active Record class has acquired relations, workflows and multi-object rules.

## Rules

1. **Use Row Data Gateway when the behavior is simple and record-oriented.** One object per row that exposes the row's fields and its own insert, update and delete. It keeps record-oriented work simple, with the row's data and its persistence in one object. Check: callers treat it as the record, with no domain workflow attached.
2. **Keep a Row Data Gateway free of business logic.** Added judgment, from the catalog's distinction between a gateway and Active Record: once decisions accumulate on it you are writing an Active Record, so decide that on purpose or move the decisions elsewhere.
3. **Use Table Data Gateway when operations are naturally table-oriented and one table interface can clearly centralize access.** Table-oriented work benefits from one interface that owns the table's statements. Check: one class per table or view; its methods return rows, record sets or identifiers; callers never write SQL for that table.
4. **Centralize all access to a table in its gateway.** Statements scattered outside the gateway defeat the centralization. Check: search for the table name outside the gateway; each hit is a finding.
5. **Use Active Record only when the domain logic is simple and persistence coupling is acceptable.** Persistence coupling is only cheap while the logic stays simple. Check: the object's behavior is validation and small calculations over its own row; no rule spans several rows or objects.
6. **Do not default to Active Record for complex domains.** Cross-object rules inside an Active Record make the persistence coupling expensive. Check: Active Record classes with associations to several tables, lifecycles or invariants across objects should move to a model plus mapper (`$enterprise-patterns:business-logic-patterns`).
7. **Keep transaction control out of gateways and Active Record objects.** The workflow owns the transaction. The source says transaction boundaries are explicit in the application workflow and not buried deep in helper classes, and an object that commits itself takes the unit of work away from the use case. Check: no `commit` inside `save`, `insert` or `update`.
8. **Avoid exposing persistence objects as the API shape by default.** The source lists exposing persistence models directly to callers as something to avoid by default, which makes this a strong default and not a prohibition. A persisted object in a response ties clients to the schema. Check: by default, handlers and remote operations return DTOs or view models, not Active Record instances; where an instance is returned on purpose, the coupling is stated and accepted (see Trade-offs).
9. **Default table-oriented calculations to a Table Module or Table Data Gateway.** The source's default choice for table-oriented calculations is exactly this pair. Added judgment on mechanics: run the calculation as a set-based query, because the database does set calculations more cheaply than an object per row. Check: calculations that are naturally "for all rows" run as one query or one pass over a record set, not as per-row objects.

## Procedure

1. Describe the feature in one sentence and mark whether it is about a record, a table or a behavior-rich object.
2. Record or table: choose the matching gateway. Behavior-rich with cross-object rules: stop and use a mapper route.
3. Write the gateway with only the operations the feature uses; keep SQL private to it.
4. Let the service own the transaction and call the gateway inside it.
5. If you adopt Active Record, write down the line that will trigger a move to a mapper (for example "when a rule needs two objects").
6. Run the tests after each step.

## Example

```python
# Before: a report builds an entity per row only to sum a column in Python
class Product:
    def __init__(self, sku, category, price_cents, stock):
        self.sku, self.category, self.price_cents, self.stock = sku, category, price_cents, stock

def stock_value_report(conn):
    products = [Product(*row) for row in conn.execute("select sku, category, price_cents, stock from products")]
    totals = {}
    for p in products:
        totals[p.category] = totals.get(p.category, 0) + p.price_cents * p.stock
    return totals

# After: a Table Data Gateway owns the table and returns a record set for a set-oriented question
class ProductGateway:
    def __init__(self, conn):
        self.conn = conn
    def insert(self, sku: str, category: str, price_cents: int, stock: int) -> None:
        self.conn.execute("insert into products (sku, category, price_cents, stock) values (?, ?, ?, ?)",
                          (sku, category, price_cents, stock))
    def stock_value_by_category(self) -> dict[str, int]:
        rows = self.conn.execute(
            "select category, sum(price_cents * stock) from products group by category").fetchall()
        return {category: total for category, total in rows}
```

The `Product` class had no behavior and no identity use; it existed to satisfy the habit of "one object per row". The gateway lets the database do the set calculation and keeps every statement about `products` in one class.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Fake entities | Row-wrapper classes feeding loops that aggregate | Table data gateway returning a record set |
| Table access everywhere | The table name appears in handlers, jobs and services | Route through one gateway |
| Active Record sprawl | Model with relations, workflows and cross-object rules | Move behavior to a domain model and persistence to a mapper |
| Committing gateway | `save()` calls `commit()` | Let the service own the commit |
| Persistence objects in responses | Handlers return Active Record instances | Map to DTOs or view models, unless the coupling is accepted and named |

## Trade-offs and exceptions

- These patterns are legitimate choices, not shortcuts, when the domain is simple. The source's complaint is about defaulting to Active Record for complex domains.
- A small Active Record model with a few validations is fine; the line is cross-object rules and lifecycle.
- If the framework makes Active Record the path of least resistance and the domain is simple, accept it, keep it thin and watch for the move-to-mapper trigger.
- A gateway is not a repository: it is shaped by the table, which is the point here and the problem in `$enterprise-patterns:repository`.
- Because the source says "avoid by default", a simple domain with accepted Active Record coupling may return the record from a handler or an internal operation. Name the cost when you do: every column rename or lazy association becomes a change to the response shape, and a serializer can trigger queries. Move to a DTO or view model at the first public or remote boundary, or when the record carries fields clients must not see.

## Verification

- [ ] The pattern chosen matches the shape of the feature (record, table or behavior-rich).
- [ ] All SQL for each table is in one gateway or model class.
- [ ] No rule spans several objects inside an Active Record class.
- [ ] No gateway or Active Record method commits.
- [ ] No handler returns a persistence object directly, or the accepted coupling is stated.
- [ ] The tests pass.

## Related

`$enterprise-patterns:data-mapper` and `$enterprise-patterns:repository` for decoupled domains; `$enterprise-patterns:business-logic-patterns` for Table Module and Domain Model; `$enterprise-patterns:base-patterns` for Record Set; `enterprise-patterns-persistence-reviewer` to review a diff.

## Source

- `Persistence Pattern Rules`
- `Row Data Gateway`
- `Table Data Gateway`
- `Active Record`
- `Transaction Boundaries`: only the points that boundaries are explicit in the application workflow and that ownership is not buried in helper classes.
- `Table Module`: only the pairing of table-oriented, set-oriented logic with a table abstraction.
- `Code Generation Rules`: only the default choice for table-oriented calculations and the avoid-by-default line about exposing persistence models directly.
