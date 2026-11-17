---
type: llm
weight: 1
---

PASS if the review flags that `Preferences` (theme, language, weekly digest) is event-sourced with one `*Changed` or `*Toggled` event per field, which stores bookkeeping instead of business facts and adds event-sourcing machinery to a plain settings record, and proposes simple state storage for it. FAIL otherwise.
