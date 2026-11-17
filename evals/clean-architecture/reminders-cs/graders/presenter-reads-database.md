---
type: llm
weight: 1
---

PASS if the review flags that `ReminderSummaryPresenter` queries `BillingDbContext` itself instead of receiving an output model from the use case, and proposes that the use case returns the data and the presenter only formats it. FAIL otherwise.
