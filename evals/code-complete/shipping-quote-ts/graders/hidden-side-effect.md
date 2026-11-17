---
type: llm
weight: 2
---

PASS if the review points out that `calcShipping`, named like a calculation, also changes state (it writes the module-level `quoteCache` or sets `lastQuotedAt` on the order it was given) and proposes making it pure or moving the writes into a visible, named step. FAIL if it treats the function as pure or never mentions either write.
