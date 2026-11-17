---
type: llm
weight: 1
---

PASS if the review flags the public mutable fields (such as `Lines`, `PendingSave`, `SendAttempts`) as exposed representation or internal bookkeeping and proposes encapsulating them (private state, a read-only view, methods that express the intent). FAIL otherwise.
