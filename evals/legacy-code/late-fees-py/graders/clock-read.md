---
type: llm
weight: 1
---

PASS if the review flags `date.today()` read inside `run` (more than once) as a hidden input that makes the result depend on the day the job runs, and proposes passing the date or a clock in from the entry point. FAIL otherwise.
