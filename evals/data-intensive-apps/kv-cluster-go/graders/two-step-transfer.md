---
type: llm
weight: 1
---

PASS if the review flags that `Transfer` reads both balances and then writes the two accounts with two separate Puts (usually on different nodes), so a crash between them destroys money and concurrent transfers can overdraw, and proposes one atomic mechanism (a conditional or transactional update, an intent record with recovery, or both accounts under one partition key).
FAIL if it only suggests retrying the second Put.
