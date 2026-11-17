---
type: llm
weight: 1
---

PASS if the review flags that the `requests.get` call in `get_rate` has no timeout (the library waits indefinitely by default, so a slow rates service hangs the caller) and proposes an explicit, deliberate time limit. FAIL otherwise.
