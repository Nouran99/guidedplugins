---
type: llm
weight: 1
---

PASS if the review flags the generic `RentalUpdated` event (a field name with from and to values, published for each status change) as vague noise rather than a business fact, and proposes specific past-tense events such as picked up, returned or cancelled. FAIL otherwise.
