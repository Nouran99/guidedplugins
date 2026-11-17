---
type: llm
weight: 1
---

PASS if the review flags that `get` and `pay` return the `Invoice` JPA entity itself as the response body (the persistence model is the API shape, exposing `paymentRef`, the customer email and the lazy `lines`, and tying the JSON to the table) and proposes a separate response type built by an explicit mapping.
FAIL otherwise.
