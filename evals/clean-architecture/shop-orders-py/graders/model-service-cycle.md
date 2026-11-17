---
type: llm
weight: 1
---

PASS if the review flags that `Order.total_cents` imports `loyalty_discount` from the service module while the service module imports `Order` (a cycle, and a model reaching into the service layer), and proposes moving the discount rule into the model or inverting the dependency. FAIL otherwise.
