---
type: llm
weight: 1
---

PASS if the review flags that `RunNightly` decides whether to retry by searching the error text for "timeout" (which these errors can never contain), and proposes distinct error types or codes, or `errors.Is`/`errors.As`, instead of message matching. FAIL otherwise.
