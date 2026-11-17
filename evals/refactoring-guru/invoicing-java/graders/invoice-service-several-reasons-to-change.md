---
type: llm
weight: 2
---

PASS if the review says `InvoiceService` has several unrelated jobs that change for different reasons (discount calculation, SQL persistence, HTML rendering, payment submission) and proposes splitting them into separate classes (for example a repository, a renderer, a payment step). FAIL if it only comments on the length of one method or on SQL injection.
