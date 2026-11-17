---
type: llm
weight: 2
---

PASS if the review flags `BaseRepository<T>` (`findAll`, `findBy(criteria)`, `query(sql)`, `save` and `remove` for every table, with subclasses that add nothing) as a generic, table-shaped repository that makes each caller write its own queries, and proposes a repository per aggregate with finders named for the questions the application asks.
FAIL if it only mentions that `findBy` interpolates column names.
