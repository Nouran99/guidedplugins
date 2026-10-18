---
name: "query-and-metadata-mapping"
description: "Use when SQL strings are built in several places, search filters are combined at runtime, or mapping rules are driven by configuration, annotations or reflection. Covers Query Object and Metadata Mapping. Finder interfaces are repository; table layout is relational-mapping-structure."
---

# Query objects and metadata mapping

Decides how queries are constructed (a composable Query Object instead of scattered SQL strings) and whether mapping rules should be data (Metadata Mapping) or code. The question "which queries exist" is `$enterprise-patterns:repository`; the mapper that uses them is `$enterprise-patterns:data-mapper`.

## When to use

- Search or report screens combine optional filters and the SQL is assembled with string concatenation.
- The same `where` fragments are copied between finders.
- A team proposes annotations, XML, a mapping DSL or reflection to drive load and save for dozens of types.
- A generic mapping layer has acquired many "except when" branches.

## Rules

1. **Use a Query Object when query construction needs a composable object model instead of scattered SQL strings.** Fragments concatenated in several places drift apart and are hard to review. Check: criteria that vary at runtime are expressed as calls on an object, and the SQL is assembled in one place.
2. **Do not spread SQL through business code.** The source's review rules list it as a finding. SQL in business code couples rules to the schema. Check: SQL strings appear only in data-access classes.
3. **Let the repository own its query objects.** Callers state criteria in domain terms; the repository translates them. Callers describe what they want and the repository knows how to get it. Check: no caller imports a query builder or column name.
4. **Bind values; never concatenate them into SQL.** Added judgment, general engineering practice and not in the source: every user-supplied value goes through a parameter placeholder. Concatenated values cause injection and quoting bugs.
5. **Take identifiers from an allow-list.** Added judgment: a sort field or column name that arrives from outside is mapped through a fixed dictionary, never interpolated. Interpolated identifiers allow injection that parameters cannot prevent.
6. **Use Metadata Mapping when mapping rules are regular enough to centralize safely.** Regular rules written once beat dozens of near-identical mappers. Check: many types follow the same conventions (id column, version column, naming), and the metadata is shorter than the code it replaces.
7. **Avoid Metadata Mapping when metadata obscures exceptional behavior.** Metadata full of exceptions is harder to read than the code it replaced. Check: more than occasional special cases, escape hatches or "unless" comments in the metadata mean the rules are not regular.
8. **Keep mapping explicit and testable even when it is data.** Added judgment: a test that loads every mapping definition and round-trips a sample object per type catches drift between schema and metadata. Metadata that drifts from the schema fails at runtime.
9. **Keep generated SQL inspectable.** Added judgment: log it or assert on it in a test so that a mapping change that alters a query is visible in review. A mapping change that silently changes a query is a hazard.
10. **Build the smallest query object that serves current criteria.** Added judgment, in the spirit of the source's instruction to choose the smallest set of patterns: do not design a general query language for criteria nobody uses. Unused generality is cost without use.

## Procedure

1. Collect the SQL fragments that vary: filters, sort orders, pagination.
2. Define a query object with one method per criterion in domain words (`forCustomer`, `overdueOn`, `sortedBy`).
3. Have the query object produce `(sql, params)` from a fixed template plus allow-listed identifiers and bound values.
4. Move the repository finders onto it; delete the concatenation code.
5. For metadata, first count the types it would serve and the exceptions you already know. Choose it only if the exceptions are rare.
6. Add a test that exercises each criterion alone and in combination, then run the suite.

## Example

```python
# Before: filters concatenated in the handler; values and sort field go straight into SQL
def search_invoices(conn, customer_id=None, overdue_on=None, sort="due_on"):
    sql = "select id, customer_id, due_on from invoices where 1 = 1"
    if customer_id:
        sql += f" and customer_id = '{customer_id}'"
    if overdue_on:
        sql += f" and paid = 0 and due_on < '{overdue_on}'"
    sql += f" order by {sort}"
    return conn.execute(sql).fetchall()

# After: a Query Object owns assembly; values are bound and the sort field is allow-listed
class InvoiceQuery:
    _SORTS = {"due_on": "due_on", "customer": "customer_id"}

    def __init__(self):
        self._where, self._params, self._order = [], [], "due_on"

    def for_customer(self, customer_id: str) -> "InvoiceQuery":
        self._where.append("customer_id = ?")
        self._params.append(customer_id)
        return self

    def overdue_on(self, day: str) -> "InvoiceQuery":
        self._where.append("paid = 0 and due_on < ?")
        self._params.append(day)
        return self

    def sorted_by(self, field: str) -> "InvoiceQuery":
        self._order = self._SORTS[field]          # KeyError for anything not allow-listed
        return self

    def build(self) -> tuple[str, list]:
        where = (" where " + " and ".join(self._where)) if self._where else ""
        return f"select id, customer_id, due_on from invoices{where} order by {self._order}", list(self._params)

# repository: sql, params = InvoiceQuery().for_customer(cid).overdue_on("2026-02-01").build()
#             conn.execute(sql, params).fetchall()
```

The only string interpolated into the SQL is `where` text and the order column, both assembled from the object's own fixed fragments. A value such as `x' or '1'='1` is passed as a parameter and cannot change the statement.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Concatenated SQL | f-strings or `+` building statements with values | Query object with bound parameters |
| Scattered fragments | Same `where` pieces in several finders | One query object method per criterion |
| Interpolated identifiers | Sort or column names from request parameters | Allow-list dictionary |
| Metadata with escape hatches | Mapping files full of exceptions and overrides | Replace with plain mapper code for the exceptional types |
| Query language for nobody | Operators and nesting no caller uses | Delete down to what is called |

## Trade-offs and exceptions

- A single fixed query with no variation does not need a query object; a named finder with its SQL inside the repository is enough.
- Metadata mapping pays off for regular, repetitive types; for a few exceptional types, hand-written mappers are clearer. The source says so directly: avoid it when metadata obscures exceptional behavior.
- ORMs ship query objects and metadata mapping already. Use theirs, and apply rules 2, 3 and 6 to how the project uses them.
- Parameter binding and identifier allow-lists are security hygiene on top of the book, not rules of it.

## Verification

- [ ] No SQL strings exist outside data-access classes.
- [ ] No value is concatenated into SQL; all go through bound parameters.
- [ ] Sort and column names come from an allow-list.
- [ ] Each query criterion is tested alone and in combination.
- [ ] Any metadata mapping has a test that round-trips each mapped type.
- [ ] The tests pass.

## Related

`$enterprise-patterns:repository` for the finder interface; `$enterprise-patterns:data-mapper` for mapper code; `$enterprise-patterns:loading-behavior` for shaping queries to avoid N+1; `enterprise-patterns-mapping-reviewer` to review a diff.

## Source

- `Object-Relational Mapping Pattern Index`
- `Review Rules`: only the finding about SQL spread through business code.
- `Final Instruction`: only the instruction to choose the smallest set of patterns.
