---
type: llm
weight: 1
---

PASS if the review flags that `ToEUR` returns 0 for a currency missing from the table (including before the first refresh), so the CSV silently contains zero amounts, and proposes returning an error or an `ok` result for an unknown currency. FAIL otherwise.
