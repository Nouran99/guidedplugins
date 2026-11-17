---
type: llm
weight: 2
---

PASS if the review flags that the migration changes the existing contract in one step (renames `total`, multiplies it by 100 in place, adds a NOT NULL column with no default), so the previous release still running during the deploy, and rows or writers that predate the column, break, and proposes a staged change (add the new column with a default, write both, move readers, backfill, drop the old column in a later release).
FAIL if it only says the migration locks the table or has no rollback.
