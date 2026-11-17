---
type: llm
weight: 1
---

PASS if the review flags that `StockLedger` keeps the only copy of the stock counts in the cache (an eviction, flush or restart loses them and `available` then reports 0), and proposes that the database owns stock with the cache as a copy, or that the loss is stated and recoverable.
FAIL if it only mentions the gap between `decrBy` and `incrBy`.
