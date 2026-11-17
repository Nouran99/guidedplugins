---
type: llm
weight: 2
---

PASS if the review flags that `ProductService.update` writes the search index and the cache directly after the database write and only logs a warning when that fails, so they can silently drift from the database with nothing to retry, repair or rebuild them, and proposes feeding them from the committed change (an outbox, a change feed or a retried job) or adding a repair or rebuild path.
FAIL if it only asks for a better log message or a different catch.
