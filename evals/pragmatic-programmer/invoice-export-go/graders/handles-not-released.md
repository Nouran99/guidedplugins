---
type: llm
weight: 1
---

PASS if the review flags that the output file and the `rows` cursor in `ExportInvoices` are closed only at the end of each loop iteration, so a later error `return` leaves them open (and a partial file behind), and proposes `defer` or a per-customer function that releases on every path. FAIL otherwise.
