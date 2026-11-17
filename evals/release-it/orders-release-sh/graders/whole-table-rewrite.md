---
type: llm
weight: 1
---

PASS if the review flags that the migration rewrites every row of `orders` with one UPDATE in one transaction (a long lock and a huge transaction on a live table) and proposes a batched, paced and resumable backfill. FAIL if it only discusses the column rename.
