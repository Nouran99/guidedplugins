---
name: "relational-mapping-structure"
description: "Use when designing or reviewing how objects map to tables: keys and identity fields, object references, many-to-many links, owned child rows, small values in the parent row, serialized blob columns. Hierarchies are inheritance-mapping; queries and mapping config are query-and-metadata-mapping."
---

# Relational mapping structure

Chooses how a model's identity, references, collections and values are laid out in tables. Persisting a class hierarchy is `$enterprise-patterns:inheritance-mapping`; expressing queries and mapping configuration is `$enterprise-patterns:query-and-metadata-mapping`; the code that copies state is `$enterprise-patterns:data-mapper`.

## When to use

- A new aggregate needs tables and you must decide keys, foreign keys and child tables.
- A relationship is stored in a delimited text column, or a child row is referenced from unrelated tables.
- A small value (address, money, date range) has its own table, or an object graph is stored as one text blob.
- A reviewer asks whether a collection should be its own table or live inside its owner.

## Rules

1. **Choose each mapping by identity, lifecycle, query needs, schema shape and evolution cost.** This is the compact checklist from `mini.md`; the full rule set lists the patterns below as conditions. Mapping choices are hard to reverse once data exists. Check: for each mapping you can name the force that selected it.
2. **Use an Identity Field when in-memory objects need a stable database identity, and keep the identity mapping explicit.** Without a stable identity, objects and rows cannot be matched across loads and saves. Check: the key column and the object's identifier field are paired in one place and never inferred from position or from mutable data.
3. **Use Foreign Key Mapping when object references map to relational keys.** The database should enforce what the model already assumes. Check: every reference from one persistent object to another has a foreign key column, and a constraint where the database supports it.
4. **Avoid hiding expensive joins behind innocent traversal.** A short traversal in code may cost several joins. Check: a navigation that crosses several tables is covered by a loading plan (see `$enterprise-patterns:loading-behavior`).
5. **Use Association Table Mapping when many-to-many relationships need a separate relational table.** A separate table lets the pairs be indexed, constrained and queried. Check: the relationship is a table of pairs with a composite key, not a delimited list in a column (Added judgment on the second half; the first half is the source's condition).
6. **Use Dependent Mapping when child objects have no independent database identity outside their owner.** Children that other tables reference are entities, and treating them as dependents breaks those references. Check: children are loaded and saved only through the owner, no other table references them by key, and removing the owner removes them.
7. **Use Embedded Value when a small value object can live inside the owning row without an independent lifecycle.** A separate table for a value adds a join and an identity nobody needs. Check: the value has no identifier of its own and its columns sit in the owner's row with a clear prefix.
8. **Use Serialized LOB only when querying inside the value is not required and serialization versioning is controlled.** Data in a blob is invisible to the database and costly to evolve. Check: no query filters or joins on data inside the blob, and the serialized form carries a format version with a read path for older versions.
9. **Keep identity fields, foreign keys, association tables, dependent objects, embedded values and serialized values explicit rather than accidental.** Compact checklist (from `mini.md`): implicit mapping moves decisions into framework defaults. Check: a reader can tell from the mapper which pattern each column group follows.
10. **Prefer a key that the business cannot change.** Added judgment: an email address or a product code that can be edited makes a poor identity field because every reference must follow the edit.

## Procedure

1. List the model's relationships: references, collections and small values.
2. For each, ask the force questions: does it have its own identity, can it exist without the owner, is it queried by itself, what happens when the schema changes.
3. Pick the pattern from the rules above and write it next to the model in the design note or mapper.
4. Write the DDL with constraints, then the mapper code, then a round-trip test that includes the children and values.
5. For dependent children, decide the save strategy (replace all rows, or diff) and test an edit that removes a child.

## Example

```sql
-- Before: a many-to-many link stored as delimited text; queries need string tricks
create table products (id integer primary key, name text not null, tag_ids text not null default '');
select * from products where ',' || tag_ids || ',' like '%,7,%';

-- After: Association Table Mapping
create table products (id integer primary key, name text not null);
create table tags (id integer primary key, label text not null unique);
create table product_tags (
  product_id integer not null references products(id) on delete cascade,
  tag_id     integer not null references tags(id),
  primary key (product_id, tag_id)
);
select p.* from products p join product_tags pt on pt.product_id = p.id where pt.tag_id = 7;
```

```python
# Dependent Mapping and Embedded Value: the order mapper owns its lines and its address columns
class OrderMapper:
    def __init__(self, conn):
        self.conn = conn
    def update(self, order) -> None:
        a = order.ship_to                      # small value, no identity: columns in the orders row
        self.conn.execute(
            "update orders set ship_street = ?, ship_city = ?, ship_postcode = ? where id = ?",
            (a.street, a.city, a.postcode, order.id))
        self.conn.execute("delete from order_lines where order_id = ?", (order.id,))
        self.conn.executemany(                 # children have no identity outside the order
            "insert into order_lines (order_id, line_no, sku, qty) values (?, ?, ?, ?)",
            [(order.id, n, line.sku, line.qty) for n, line in enumerate(order.lines, start=1)])
```

Replacing all lines is the simplest save strategy for dependent children; it is acceptable while no other table points at a line and the line count is small. The pairs in `product_tags` can be reported on, indexed and constrained, which the delimited text could not do.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Delimited relationship | Ids or tags in a text column | Association table |
| Shared child | Another table references an order line directly | Give the child an identity of its own (entity), not Dependent Mapping |
| Value with a table | Address table with its own id referenced by one owner | Embedded Value in the owner's row |
| Queried blob | `where payload like '%...%'` on a serialized column | Real columns or tables for the queried parts |
| Unversioned blob | Serialized form with no format marker | Add a version and a reader for older versions |
| Mutable business key as identity | Key column editable by users | Surrogate or immutable key |

## Trade-offs and exceptions

- Serialized LOB is allowed by the source when nobody needs to query inside the value and versioning is controlled; it is not a smell in that case.
- Dependent Mapping couples the child's persistence to the owner; if children grow large or need independent updates, treat them as entities.
- Embedded Value limits reuse of a value across owners; copying the columns is the cost of avoiding a join.
- A heavy ORM may do several of these mappings by configuration; the requirement is that you know which pattern each configured mapping is.

## Verification

- [ ] Each mapping names the force that selected it.
- [ ] Every object reference has a foreign key column and, where supported, a constraint.
- [ ] No relationship is stored in a delimited column.
- [ ] Dependent children are reachable only through their owner.
- [ ] Serialized columns are not queried inside and carry a version.
- [ ] A round-trip test covers children and embedded values.

## Related

`$enterprise-patterns:inheritance-mapping` for hierarchies; `$enterprise-patterns:query-and-metadata-mapping` for queries and configuration; `$enterprise-patterns:data-mapper` for mapper code; `$enterprise-patterns:base-patterns` for Value Object and Money; `enterprise-patterns-mapping-reviewer` to review a diff.

## Source

- `Object-Relational Mapping Pattern Index`
