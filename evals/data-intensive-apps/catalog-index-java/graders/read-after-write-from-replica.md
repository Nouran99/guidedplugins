---
type: llm
weight: 1
---

PASS if the review flags that `update` reads the saved product back from the replica right after writing to the primary, so a lagging replica can return the old row to the editor (and push that old row into the index and cache), and proposes reading from the primary or using the values just written.
FAIL if it only says the extra query is wasteful.
