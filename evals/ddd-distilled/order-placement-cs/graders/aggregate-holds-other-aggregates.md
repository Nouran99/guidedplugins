---
type: llm
weight: 2
---

PASS if the review flags that `Order` (and `OrderLine`) hold object references to other aggregates (`Customer`, which reaches `Account` and `Orders`, and `Product`) instead of identifiers, pulling a large object graph into every order, and proposes referencing them by id (for example a customer id and a SKU). FAIL if it only discusses the handler saving several things.
