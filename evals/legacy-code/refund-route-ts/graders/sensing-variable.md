---
type: llm
weight: 1
---

PASS if the review flags the exported mutable `lastDecision`, which the handler only writes and only the tests read, as test-only state kept in production code (also shared between requests), and proposes returning the decision or removing the variable. FAIL otherwise.
