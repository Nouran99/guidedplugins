---
type: llm
weight: 1
---

PASS if the review flags that `ExportInvoices` reads hidden inputs inside the function (the `EXPORT_DIR` environment variable and/or the clock from `time.Now()`), which the signature does not show and a test cannot control, and proposes passing the directory and time (or a clock) in. FAIL otherwise.
