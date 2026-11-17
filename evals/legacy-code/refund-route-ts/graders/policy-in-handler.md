---
type: llm
weight: 2
---

PASS if the review says the refund rules (status, window, marketplace limit, over-refund, customer cap) are decided inside the route handler together with parsing, persistence and the payment call, and proposes extracting the decision as a function of plain data (order, amount, actor, time) that can be tested without Express or a database. FAIL otherwise.
