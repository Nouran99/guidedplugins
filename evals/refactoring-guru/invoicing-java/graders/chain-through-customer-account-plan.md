---
type: llm
weight: 1
---

PASS if the review flags the calls that walk from the order through customer, account and plan (`order.getCustomer().getAccount().getPlan().getDiscountRate()`, and the one to the account id), so `InvoiceService` knows the shape of the object graph, and proposes asking the order or customer a question with a domain name (for example `order.discountRate()`). FAIL otherwise.
