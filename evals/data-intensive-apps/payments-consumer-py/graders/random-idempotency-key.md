---
type: llm
weight: 1
---

PASS if the review flags that `on_refund_requested` builds a new `uuid4()` Idempotency-Key on every attempt, so the gateway cannot recognise a retry and a timed-out attempt that actually succeeded is refunded again, and proposes a key derived from the refund (for example the refund id) that is the same on every attempt.
FAIL if it only asks for a backoff or a different retry limit.
