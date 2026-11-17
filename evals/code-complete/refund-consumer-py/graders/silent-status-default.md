---
type: llm
weight: 1
---

PASS if the review flags `REFUND_STATES.get(result["status"], "refunded")`, where an unknown gateway status is silently recorded as a completed refund, and proposes failing or reporting on a status that is not in the table. FAIL otherwise.
