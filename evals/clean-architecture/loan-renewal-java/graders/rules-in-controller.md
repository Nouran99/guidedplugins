---
type: llm
weight: 1
---

PASS if the review flags that `LoanController` decides the renewal rules (at most two renewals, no renewal when overdue) and proposes moving them into `Loan` (for example a `renew` method that guards its own state) or into the use case, leaving the controller to translate. FAIL if it only mentions the magic numbers or the status codes.
