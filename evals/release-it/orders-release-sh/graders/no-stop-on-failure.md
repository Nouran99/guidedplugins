---
type: llm
weight: 1
---

PASS if the review flags that the script keeps going after a failure (for example: no `set -e` or exit-status checks, a failing `psql` or host command stops nothing, `wait` hides the subshell results, and it still prints that the release finished) and proposes checking the status and halting at the first failure. FAIL otherwise.
