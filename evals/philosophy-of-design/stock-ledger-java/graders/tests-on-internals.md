---
type: llm
weight: 1
---

PASS if the review flags that the tests read the ledger's internal collections (`ledger.q`, `ledger.res`), which are package-private only so tests can reach them, and proposes asserting through public behavior and making the fields private. FAIL otherwise.
