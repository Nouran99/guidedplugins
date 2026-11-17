---
type: llm
weight: 1
---

PASS if the review flags that `InvoiceBroadcaster` serializes the internal `Invoice` object itself (including internals such as `ledgerRef`) as the broker message, so the published contract is the internal model, and proposes a separate message type or a mapper that publishes a stable contract. FAIL otherwise.
