---
type: llm
weight: 1
---

PASS if the review flags that `QuoteShipping.Run` takes the raw `kafka.Message` and decodes the JSON itself (the transport type and the wire format reach the core), and proposes decoding in the listener and passing a plain request model. FAIL otherwise.
