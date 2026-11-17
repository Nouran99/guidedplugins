---
type: llm
weight: 2
---

PASS if the review flags that `on_captured` adds the amount to `daily_revenue` with no deduplication key, so a redelivered message (a crash before `ack`, a redelivery after a timeout; the FIFO-queue comment is not a guarantee the handler may lean on) counts the same payment twice, and proposes recording a processed event or payment id in the same transaction, or recomputing the total from the stored facts.
FAIL if it only mentions error handling, logging or a missing row, or if it notes the FIFO comment without tying it to double counting.
