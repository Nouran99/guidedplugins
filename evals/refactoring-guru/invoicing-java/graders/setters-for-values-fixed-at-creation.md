---
type: llm
weight: 1
---

PASS if the review flags that `Order` has public setters (`setId`, `setCreatedAt`, `setCurrency`) for values that must not change once the order exists, and proposes setting them through a constructor or the `open` factory and removing the setters. FAIL otherwise.
