---
type: llm
weight: 1
---

PASS if the review flags `OrderManager` as a layer whose methods only forward to `OrderService` with the same arguments (it adds nothing), and proposes removing it so the controller calls the service, or giving it a real responsibility.
FAIL otherwise.
