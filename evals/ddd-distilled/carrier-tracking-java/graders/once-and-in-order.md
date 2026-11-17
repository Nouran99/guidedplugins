---
type: llm
weight: 1
---

PASS if the review flags that `TrackingWebhook.onCarrierMessage` is not safe against redelivery or out-of-order delivery (it appends an event and increments `deliveredToday` on every call with no duplicate check, or a late message overwrites a newer status) and proposes an idempotency check, a message id, or a timestamp or sequence comparison. FAIL otherwise.
