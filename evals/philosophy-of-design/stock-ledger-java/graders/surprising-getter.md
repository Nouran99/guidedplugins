---
type: llm
weight: 1
---

PASS if the review points out that `getStock` also deletes expired reservations (a getter with a side effect a reader does not expect) and proposes moving the purge elsewhere or making it explicit in the name or contract. FAIL otherwise.
