---
type: llm
weight: 2
---

PASS if the review flags that `Put` stamps `UpdatedAt` with the client's `time.Now()` and `Get` picks the newest by that stamp, so clock skew between clients lets an older write win and silently drops a newer one, and proposes versions or logical clocks (or a stated conflict rule) instead of wall-clock time.
FAIL if it only mentions time zones or monotonic time inside one process.
