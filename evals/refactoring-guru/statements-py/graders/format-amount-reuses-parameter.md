---
type: llm
weight: 1
---

PASS if the review flags that `format_amount` reassigns its parameter `cents` twice, so one name holds three meanings (cents, a number of units, a string), and proposes separate local variables with their own names or a single expression. FAIL otherwise.
