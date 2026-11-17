---
type: llm
weight: 1
---

PASS if the review flags that the private static `BackoffMillis` in `AlertGateway` is never called (the retry loops compute their own sleep), and proposes deleting it or using it in the retry code. FAIL otherwise.
