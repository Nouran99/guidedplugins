---
type: llm
weight: 1
---

PASS if the review flags that `SalesReport` runs full aggregations over `orders` and `order_lines` on the primary (transactional) database for a dashboard that refreshes every ten seconds on every screen, and proposes moving the analytics to a replica or warehouse, or serving a precomputed or cached aggregate.
FAIL if it only suggests adding an index.
