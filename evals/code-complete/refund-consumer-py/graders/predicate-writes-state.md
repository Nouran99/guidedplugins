---
type: llm
weight: 1
---

PASS if the review points out that `is_refundable`, named like a question, also writes the order state (`refund_requested`), a hidden side effect, and proposes separating the check from the write or renaming it. FAIL otherwise.
