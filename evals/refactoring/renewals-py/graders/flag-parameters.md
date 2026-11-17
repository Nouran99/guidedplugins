---
type: llm
weight: 1
---

PASS if the review flags the boolean parameters `notify`, `dry_run` and `retry` of `renew_due` (a call like `renew_due([], True, False, False)` cannot be read without the definition) as switches that make one function do several jobs, and proposes explicit functions, separate steps or named (keyword-only) options. FAIL if it only says `renew_due` is long.
