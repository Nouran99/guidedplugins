---
type: llm
weight: 1
---

PASS if the review flags that the migration renames `handling_fee` while old application versions still run (during the rollout they query a column that no longer exists, and rolling the code back does not bring it back), and proposes an expand-then-contract sequence (add the new column, write both, backfill, switch reads, drop the old column in a later release) or another compatible order. FAIL if it only discusses the row rewrite or its lock.
