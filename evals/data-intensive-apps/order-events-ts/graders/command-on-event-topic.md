---
type: llm
weight: 1
---

PASS if the review flags that `ReserveStock`, a request addressed to the inventory service, is published on the same `orders` topic as the facts `OrderPlaced` and `OrderShipped`, mixing commands and events, and proposes separate topics or types, or publishing the fact and letting inventory react to it.
FAIL otherwise.
