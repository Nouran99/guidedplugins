---
type: llm
weight: 2
---

PASS if the review flags that `_rows`, `_total` and `_overdue` on `StatementBuilder` start as `None` and hold meaningful values only while one `build` call runs, so methods such as `_body`, `_footer` or `late_fee` work only when called after `build` has filled them, and proposes passing the values as parameters or moving the working state into a separate object created per statement. FAIL if it only mentions the `None` initialization or naming.
