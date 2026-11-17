---
type: llm
weight: 2
---

PASS if the review says no test covers the rejected inputs (zero, negative or NaN hours returning `ErrInvalidStay`), for instance noting that the error is discarded with `_`, and proposes tests for them. FAIL otherwise.
