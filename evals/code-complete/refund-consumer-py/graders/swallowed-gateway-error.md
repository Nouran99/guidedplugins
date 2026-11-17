---
type: llm
weight: 1
---

PASS if the review flags the broad `except Exception` in `issue_refund` that logs a message without the order, charge or cause and returns False (a swallowed failure with its context lost) and proposes keeping the cause and context or propagating the error. FAIL otherwise.
