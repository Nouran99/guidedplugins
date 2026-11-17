---
type: llm
weight: 1
---

PASS if the review flags that the consumer throws on a message type it does not know, so a producer that starts sending a new event type (during a rolling deploy) makes the consumer fail or stall on that message, and proposes ignoring or skipping unknown types, with a counter or a dead-letter path.
FAIL otherwise.
