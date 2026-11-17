---
type: llm
weight: 1
---

PASS if the review flags that the public export functions are named after one screen (`..._for_finance_screen`) although the concept is an export and the nightly archive also calls `export_for_finance_screen`, and proposes names (and a shape) for the concept, for example an invoice export and a credit note export for a tenant and month. FAIL if it never questions the screen-specific names.
