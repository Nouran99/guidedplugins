---
name: data-model-choice
description: "Use when picking or reviewing a data model or query style: relational, document, graph, key-value or analytical; schema shape; SQL versus application-side joins. Index and engine choice is storage-and-indexing."
---

# Data model and query style

Picks the shape of the data and the way it is queried from the relationships, the questions asked of it, how it is updated and how it will change. How a chosen model is laid out on disk and indexed is `/data-intensive-apps:storage-and-indexing`; whose data it is, is `/data-intensive-apps:source-of-truth`.

## When to use

- A new feature needs storage and you are choosing between a relational schema, documents, a graph, key-value or a warehouse.
- Code loops over query results to fetch related rows or documents one by one, then filters or aggregates in the application.
- A document keeps getting copies of fields from other entities and renames are painful.
- A relational design needs six joins to show one logical unit that is always read and written together.
- A traversal of unknown depth (friends of friends, dependency closure) is written as repeated queries.

## Rules

1. **Select among relational, document, graph, key-value and analytical models by the relationships in the data, the queries asked, how locally updates land and how fast the shape will change.** Check: a written reason that names at least two of those four.
2. **Derive the storage shape from how data is accessed, what consistency it needs and how it is updated.** Check: the dominant reads and writes are listed next to the choice.
3. **Do not make every workload fit a single storage pattern.** Check: if one store serves transactions, search and analytics, there is a reason beyond habit.
4. **Do not pick a document model for data whose many-to-one or many-to-many links would force duplicated copies or joins written in application code.** The copies drift and the joins move into code. Check: count the places where code resolves ids by looping over documents.
5. **Do not squeeze data that is naturally self-contained, and usually read as a unit, into a relational shape.** Check: a read or write of one logical unit touches many tables every time.
6. **Write queries declaratively wherever that states the intent more clearly and lets the engine choose how to run them.** The planner can change the plan when data changes; a hand-written loop cannot. Check: a loop that fetches, filters and aggregates could be one query.
7. **Use a graph model when the relationships are the point of the data and following them is the core query.** Check: variable-depth hops are expressed as a path pattern, not as repeated joins or loops.
8. **Regard Cypher, SPARQL, Datalog, SQL, MapReduce and plain application code as distinct ways to express a query, each with its own cost in maintainability and room for optimization.** Check: for a complex query you can say why this language: who can read it, and who can optimize it.
9. Added judgment: **Schema-on-read still has a schema.** Write down the fields the code assumes, so evolution (`/data-intensive-apps:encoding-and-evolution`) has something to be compatible with. Check: a type, validator or doc lists the assumed fields.
10. Added judgment: **When a document embeds another entity's field, record who owns it.** The embedded value is a copy. Check: the owner and the update path are named (`/data-intensive-apps:source-of-truth`).

## Procedure

1. List the entities, their relationships (one-to-many, many-to-one, many-to-many) and which are always read together.
2. List the queries by frequency: point lookups, joins, aggregations, traversals, full-text, scans.
3. Note how each entity is updated: whole unit or by field, by whom, how often, with what consistency need.
4. Choose the model that fits the dominant pattern; if the patterns differ by workload, split the workload and treat the second store as derived (`/data-intensive-apps:derived-data`).
5. Replace application-side join and aggregation loops with one declarative query where the engine supports it.
6. Record the choice, the rejected alternatives and the evidence that would make you revisit it.

## Example

```ts
// Before: N+1 queries and the aggregation happens in application memory
const customers = await db.query("SELECT id, region FROM customers");
const totals = new Map<string, number>();
for (const c of customers) {
  const orders = await db.query(
    "SELECT amount FROM orders WHERE customer_id = $1 AND placed_at >= $2", [c.id, since]);
  for (const o of orders) totals.set(c.region, (totals.get(c.region) ?? 0) + Number(o.amount));
}

// After: one declarative query; the planner chooses join order and indexes
const rows = await db.query(
  `SELECT c.region, SUM(o.amount) AS total
     FROM orders o
     JOIN customers c ON c.id = o.customer_id
    WHERE o.placed_at >= $1
    GROUP BY c.region`,
  [since]);
```

The opposite case: a "resume" that is always read and written as one unit, with its own sections, is a good fit for one document; splitting it across six tables to satisfy a style rule makes every read a join.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Application-side join | Loop over ids issuing one query per item | One join, or a batched lookup |
| Drifting embedded copies | The same name or price stored inside many documents | Reference by id, or name the owner and a repair path |
| Relational explosion | Many tables for one aggregate that is always loaded whole | Consider a document or a JSON column for the aggregate |
| Join tables standing in for a graph | Recursive self-joins of unknown depth | A graph query or a recursive query with a depth bound |
| One store for everything | Search, reporting and checkout all on the same tables | Separate workloads; feed the others as derived data |

## Trade-offs and exceptions

- Document and relational models have converged: many relational engines store JSON and many document stores support joins. Choose by workload fit, not by label.
- Document models give schema flexibility and locality of one unit; relational models give joins and declared constraints. The rule is to see which cost your workload pays.
- A second data model is an operational cost (`/data-intensive-apps:load-and-latency`, rule on accidental complexity). Prefer the model your current store supports well when the workload fits.
- Imperative code is the right tool when the logic cannot be stated declaratively; the rule is about queries that can.

## Verification

- [ ] The choice names relationships, query needs, update locality and evolution pressure.
- [ ] The dominant access patterns are listed.
- [ ] No loop issues one query per item where a single query could do the work.
- [ ] Any embedded copy of another entity's field has a named owner.
- [ ] The assumed fields of a schemaless model are written down.

## Related

`/data-intensive-apps:storage-and-indexing` for indexes and engines; `/data-intensive-apps:source-of-truth` for copies; `/data-intensive-apps:encoding-and-evolution` for changing the shape later; `data-intensive-apps:storage-reviewer` to review a diff.

## Source

- `Query Model and Data Shape Rules`
- `Data Model and Storage Rules`: only the rules on choosing storage shape from workload and not forcing one pattern onto all workloads.
