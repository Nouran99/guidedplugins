---
type: llm
weight: 2
---

PASS if the review says `InvoiceController.pay` runs the whole payment use case itself (loads the invoice, decides whether it may be paid, totals the lines, charges, saves, sends the mail and owns the transaction) instead of only translating HTTP, and proposes moving that coordination into an application service or use-case class, with the invoice rules on the invoice or in that service.
FAIL if it mentions only one detail of the method (only the mail, only the entity or only the number handling) or only says the method is long.
