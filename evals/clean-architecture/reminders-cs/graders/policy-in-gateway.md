---
type: llm
weight: 1
---

PASS if the review flags that the gateway decides business policy (the three-day grace period and the three-reminder limit inside `FindOverdue` and `MarkSentIfAllowed`, a port named after a decision) and proposes moving that policy into a domain object or the use case, leaving the gateway to load and save.
FAIL if it only mentions the hard-coded numbers or the `DateTime.UtcNow` call.
