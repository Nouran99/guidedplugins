---
type: llm
weight: 1
---

PASS if the review flags that every failure in `ExportInvoices` becomes the same bare "export failed" error, discarding the underlying cause and which customer or step failed, and proposes wrapping with `%w` plus the operation and identifiers. FAIL if it only says the error messages could be nicer.
