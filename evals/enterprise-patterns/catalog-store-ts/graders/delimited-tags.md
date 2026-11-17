---
type: llm
weight: 1
---

PASS if the review flags that tags are stored as a comma-separated text column, split in `hasTag` and searched with `like '%...%'`, and proposes a tags table or an association table with one row per product and tag.
FAIL otherwise.
