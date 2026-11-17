---
type: llm
weight: 1
---

PASS if the review flags the generic `OrderUpdated` event (a field name with old and new strings, published by the handler for status and quantity changes) as vague noise rather than a business fact, and proposes specific past-tense facts such as an order placed event. FAIL otherwise.
