---
type: llm
weight: 1
---

PASS if the review flags that `exportTenant` returns silently when the query or the file creation fails (and ignores the errors from `Scan` and `WriteString`), so a failed or partial export looks like success, and proposes logging or returning the errors, ideally with a failure count. FAIL otherwise.
