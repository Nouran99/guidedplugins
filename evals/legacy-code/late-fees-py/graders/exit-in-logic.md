---
type: llm
weight: 1
---

PASS if the review flags `sys.exit(3)` inside `run`, below the entry point, as ending the process from logic, and proposes returning or raising a result and exiting only in the `__main__` block. FAIL otherwise.
