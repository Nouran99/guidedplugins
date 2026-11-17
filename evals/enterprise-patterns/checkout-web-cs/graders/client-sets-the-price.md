---
type: llm
weight: 1
---

PASS if the review flags that `Add` takes `unitPrice` (and the product name) from the request, so the client decides what the order costs, and proposes looking the price up on the server from the SKU.
FAIL otherwise.
