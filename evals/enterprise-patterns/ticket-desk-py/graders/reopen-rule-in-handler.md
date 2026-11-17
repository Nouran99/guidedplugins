---
type: llm
weight: 1
---

PASS if the review flags that the reopen decision (only a closed ticket, closed no more than 14 days ago) is made inside the `reopen` handler instead of on the ticket or in the service next to `close`, and proposes moving it out of the handler.
FAIL if it only mentions the number 14 as a magic number.
