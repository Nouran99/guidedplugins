---
type: llm
weight: 1
---

PASS if the review does not ask for extra mechanisms before merging: a separate dedup table, exactly-once processing, a distributed transaction or lock, consensus, event sourcing for the view, a stream-processing framework or a second store. It may mention them as optional ideas.
FAIL if it asks for any of them as a change to make.
