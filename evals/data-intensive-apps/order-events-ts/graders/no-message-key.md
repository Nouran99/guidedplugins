---
type: llm
weight: 1
---

PASS if the review flags that messages are sent with no key to a topic that is consumed concurrently, so the events of one order can land on different partitions and be handled out of order, while `commit` assumes the reservation already exists, and proposes keying messages by order id (and tolerating or checking a missing reservation).
FAIL if it only mentions the `partitionsConsumedConcurrently` setting.
