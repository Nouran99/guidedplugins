---
type: llm
weight: 1
---

PASS if the review flags that `listPage` calls `categories.findBy` once per product row in a loop (a query per row, N+1), and proposes a join or a single batched query that returns the category names with the page.
FAIL otherwise.
