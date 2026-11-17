---
type: llm
weight: 1
---

PASS if the review flags that `calcShipping` returns `-1` to mean "cannot quote" (and callers compare with the literal) and proposes an absence type (null, undefined, a result type) or at least a named constant. FAIL otherwise.
