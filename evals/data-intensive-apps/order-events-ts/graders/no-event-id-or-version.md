---
type: llm
weight: 1
---

PASS if the review flags that the events carry no event id and no order version or sequence, so the consumer cannot recognise a redelivered or older event, and that `reserve` and `commit` therefore add to and subtract from the stock counters again on every delivery, and proposes event ids or versions with a dedup record or version check.
FAIL if it only says the stock updates are not in a transaction.
