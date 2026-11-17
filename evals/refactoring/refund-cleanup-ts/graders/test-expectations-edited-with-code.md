---
type: llm
weight: 1
---

PASS if the review flags that test expectations were changed in the same pull request as production changes described as structure only (so the tests no longer prove the behavior is the same), and/or that the refund assertion was loosened to `toBeGreaterThan(0)` so it no longer pins the amount, and asks to revert those test edits or move them into a separate behavior change. FAIL if it does not mention the test edits or the weak assertion.
