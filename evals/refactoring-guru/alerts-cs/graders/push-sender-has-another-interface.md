---
type: llm
weight: 1
---

PASS if the review flags that `PushSender` does the same job as a `Channel` (deliver a message to a person) through a different interface (`Notify(token, title, message)` that throws, versus `Send(recipient, text)` that returns a bool), so the gateway needs a special case for it, and proposes aligning the signatures or putting push behind the common channel contract. FAIL otherwise.
