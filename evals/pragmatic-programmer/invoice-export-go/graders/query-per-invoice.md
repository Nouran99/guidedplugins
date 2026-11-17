---
type: llm
weight: 1
---

PASS if the review flags the tax-code query that runs once per invoice row inside the loop (a query per item, cost grows with the number of invoices) and proposes a join, a batch or a lookup loaded once. FAIL otherwise.
