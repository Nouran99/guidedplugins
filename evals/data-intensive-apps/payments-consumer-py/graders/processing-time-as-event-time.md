---
type: llm
weight: 1
---

PASS if the review flags that `on_captured` books revenue under `date.today()` (the day the message is processed) instead of the day the payment was captured, so a delayed, redelivered or replayed event lands in the wrong day, and proposes using the time carried in the event.
FAIL otherwise.
