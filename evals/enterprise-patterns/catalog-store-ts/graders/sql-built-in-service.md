---
type: llm
weight: 1
---

PASS if the review flags that `CatalogService.search` builds SQL by concatenating `term`, `tag` and `sortBy` against the raw `db` in business code, and proposes bound parameters with the query moved into a repository or query object (an allow-list for the sort field is welcome but not required).
FAIL if it only says the input is not validated.
