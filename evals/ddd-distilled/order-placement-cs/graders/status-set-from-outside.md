---
type: llm
weight: 1
---

PASS if the review flags that `Order.Status` (and `PlacedAt`) have public setters that the handler assigns, so any code can move an order to any state, and proposes named guarded transitions on `Order` such as place or cancel. FAIL otherwise.
