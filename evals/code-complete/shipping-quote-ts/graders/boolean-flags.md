---
type: llm
weight: 1
---

PASS if the review flags the boolean parameters `express` and `insured` of `calcShipping` as flag arguments (call sites such as `calcShipping(order, true, false)` say nothing) and proposes separate named functions, named alternatives or an options object. FAIL otherwise.
