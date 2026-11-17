---
type: llm
weight: 1
---

PASS if the review flags that `Invoice.getDisplayTotal()` builds a locale and currency display string inside the entity (so the JSON and the receipt mail inherit that one format) and proposes returning the raw amount and formatting it in presentation or in the mail code.
FAIL otherwise.
