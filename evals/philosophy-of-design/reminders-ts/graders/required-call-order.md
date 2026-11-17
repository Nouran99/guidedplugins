---
type: llm
weight: 1
---

PASS if the review flags that `DigestJob` only works when the caller runs `collect()`, then `render()`, then `send()` (each step throws if the previous one was skipped, tracked by the `collected` and `rendered` flags) and proposes one operation, or a design where each step takes the previous step's result so it cannot be called out of order. FAIL otherwise.
