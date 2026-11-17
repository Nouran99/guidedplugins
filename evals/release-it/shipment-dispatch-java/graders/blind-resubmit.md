---
type: llm
weight: 1
---

PASS if the review flags that the `catch` block immediately resubmits the whole job for any exception, with no attempt limit and no delay, so a batch that keeps failing loops forever (and can book a shipment twice), and proposes an attempt cap, a growing delay and/or a dead-letter or parking place for the batch. FAIL otherwise.
