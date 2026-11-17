---
type: llm
weight: 1
---

PASS if the review flags that `consume` uses `assert` to check a value taken from the queue message (external input; assertions are for programmer errors and can be stripped out) and proposes a real validation that raises a proper error. FAIL if it never mentions the `assert`.
