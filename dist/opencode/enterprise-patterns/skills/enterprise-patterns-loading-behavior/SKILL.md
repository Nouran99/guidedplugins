---
name: "enterprise-patterns-loading-behavior"
description: "Use when objects are loaded: the same row appears as two live objects, an association is lazy-loaded inside a loop, serializer or template, or a list endpoint issues one query per row (N+1). Reads and identity; commit scope is transactions-and-unit-of-work."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Loading behavior

Covers how objects come into memory: one object per identity within a scope (Identity Map), and loading related data deliberately (Lazy Load) so that a loop, a serializer or a template cannot silently trigger a stream of queries. Write timing and commit scope are `enterprise-patterns-transactions-and-unit-of-work`.

## When to use

- A list endpoint takes much longer with more rows, and the query log shows one query per row.
- Two variables hold different objects for the same database row and both are modified.
- A JSON serializer or template touches an association that is loaded on first access.
- You add a lazily loaded field or a navigation property to an existing model.

## Rules

1. **Preserve one in-memory representation per identity per scope, where it is needed.** Two objects for one row can be changed independently, and the later save silently wins. Check: loading the same id twice inside one unit of work returns the same object, or the code does not rely on identity.
2. **Define the scope of the identity map as a logical unit of work.** Added judgment, from the source's wording about duplicates "inside one logical unit of work": a map that outlives the request becomes a cache with staleness rules, which is a separate decision.
3. **Avoid duplicate object instances fighting each other inside one logical unit of work.** The failure is quiet because both copies look valid. Check: no code path loads one row twice and then saves both copies, where the later save silently overwrites the earlier.
4. **Use Lazy Load deliberately, not everywhere.** Lazy loading trades surprise for savings, so it pays only for data that is rare or expensive. Check: every lazily loaded association has a reason (large, rarely used, expensive) written near it.
5. **Know where lazy loading may trigger remote or database chatter.** Without a list of triggers, a harmless-looking property read becomes a query. Check: for each lazy association, list the places that touch it; loops, serializers, templates and logging statements are the usual triggers.
6. **Avoid lazy-loading surprises in loops and serialization paths.** A loop multiplies a hidden query by the number of rows. Check: no property access inside a loop, mapper, serializer or template can start a query; the data was loaded up front.
7. **Do not allow invisible N+1 behavior.** The cost appears only with production-sized data. Check: for a list of N rows the number of queries does not grow with N; a test or the query log proves it for list endpoints.
8. **Do not hide expensive joins behind innocent-looking traversal.** The source warns about this for foreign-key associations. A short traversal can hide several joins and their cost. Check: a chain like `order.customer.address.city` that crosses several tables is covered by an explicit loading plan.
9. **Keep loading assumptions visible to maintainers.** A maintainer reads the finder, not the ORM defaults. Check: the use case, repository finder or query names what it loads (`ordersWithCustomerNames`), instead of relying on the model's lazy defaults.
10. **Load what the use case needs before leaving the unit of work.** Added judgment: touching a lazy association after the session or connection is closed fails in some stacks and silently opens a second connection in others; prefer loading inside the unit of work.

## Procedure

1. Find the loop, serializer or template that reads the association.
2. Count queries for N=1 and N=10 rows (a counting wrapper, the ORM's debug log or the database log). If the count grows with N, you have N+1.
3. Add a finder shaped for the use case (a join or a batched `in` query) and return exactly what the use case reads.
4. Make the model's default fetch plan the cheap one; make the expensive load an explicit call.
5. For duplicates: find the second load of the same identity and route both through the identity map, or pass the object instead of the id.
6. Add a query-count assertion for list use cases, then run the tests.

## Example

```python
# Before: the lazy property issues one query per order (N+1)
class Order:
    def __init__(self, id, customer_id, loader):
        self.id, self.customer_id, self._loader, self._customer = id, customer_id, loader, None
    @property
    def customer(self):
        if self._customer is None:
            self._customer = self._loader(self.customer_id)
        return self._customer

def recent_orders(conn, limit):
    load_customer = lambda cid: conn.execute("select id, name from customers where id = ?", (cid,)).fetchone()
    rows = conn.execute("select id, customer_id from orders order by id desc limit ?", (limit,)).fetchall()
    return [Order(r[0], r[1], load_customer) for r in rows]

# caller: for o in recent_orders(conn, 50): print(o.id, o.customer[1])    # 1 + 50 queries

# After: a finder shaped for the use case loads what the list needs in one query
def recent_order_summaries(conn, limit):
    rows = conn.execute(
        "select o.id, c.name from orders o join customers c on c.id = o.customer_id "
        "order by o.id desc limit ?", (limit,)).fetchall()
    return [{"order_id": r[0], "customer_name": r[1]} for r in rows]

# caller: for s in recent_order_summaries(conn, 50): print(s["order_id"], s["customer_name"])   # 1 query
```

The fix is not "turn lazy loading off". Lazy loading stays available for the case where the customer is rarely read; the list use case simply does not depend on it. For identity, a minimal map keyed by type and id, consulted before each `find`, gives one object per row inside the unit of work.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Invisible N+1 | Query count grows with rows; association read in a loop | Use-case-shaped finder; explicit fetch plan |
| Serializer-triggered loading | JSON or template access starts queries | Load before serializing; map to a DTO |
| Lazy everything | Every association is lazy by default | Make cheap, commonly used data eager; lazy only the rare or large |
| Twin objects | Same id loaded twice, both mutated | Identity map or pass the object |
| Hidden deep traversal | Long navigation chains in view code | Load and pass the needed values explicitly |

## Trade-offs and exceptions

- Lazy loading is a tool for large or rarely used data; the source does not forbid it, only its use "everywhere" and its surprises.
- An identity map costs memory and bookkeeping. When the framework already provides one, use it; when scopes are tiny (one query, one object) it is unnecessary.
- Eager loading of everything is the opposite failure; load what the use case reads.
- Cross-request caching and invalidation are separate design problems; do not smuggle them in as an identity map.

## Verification

- [ ] The number of queries for a list use case does not grow with the number of rows.
- [ ] Every lazy association has a stated reason and a known set of trigger points.
- [ ] No serializer, template or loop touches an unloaded association.
- [ ] Within one unit of work, one identity maps to one object.
- [ ] Loading choices are visible in finder or query names.
- [ ] The tests pass.

## Related

`enterprise-patterns-transactions-and-unit-of-work` for write timing; `enterprise-patterns-relational-mapping-structure` for how associations are stored; `enterprise-patterns-query-and-metadata-mapping` for shaping queries; `enterprise-patterns-loading-reviewer` to review a diff.

## Source

- `Identity, Caching, and Unit-of-Work Rules`
- `Identity Map`
- `Lazy Load`
- `Object-Relational Mapping Pattern Index`: only the warning about hiding expensive joins behind traversal.
- `Review Rules`: only the finding about accidental N+1 loading.
- `Review Checklist`: only the item about keeping loading assumptions visible.
