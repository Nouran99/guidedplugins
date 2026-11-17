---
type: llm
weight: 1
---

PASS if the review flags that `list_open` reads `ticket.assignee`, a lazy property that runs one query per ticket (a hidden N+1), and proposes a finder shaped for the list (a join or a batched lookup) that loads the assignee names up front.
FAIL otherwise.
