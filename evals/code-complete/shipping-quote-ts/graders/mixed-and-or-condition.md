---
type: llm
weight: 1
---

PASS if the review flags the condition `amount > 25 || order.items.length > 8 && !order.prepaid`, which mixes `||` and `&&` without parentheses (precedence is easy to misread and the business meaning is unnamed), and proposes explicit grouping or a named predicate. FAIL otherwise.
