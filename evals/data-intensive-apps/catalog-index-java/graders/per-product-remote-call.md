---
type: llm
weight: 1
---

PASS if the review flags that `listByCategory` calls the pricing service once per product inside a loop (a network call per item on a user-facing path, with its latency and partial-failure cost), and proposes a batch call or a local copy of prices with a stated staleness bound.
FAIL if it only mentions the SQL query.
