---
type: llm
weight: 2
---

PASS if the review flags that `Summary.cshtml` computes the subtotal, the bulk discount, the free-shipping eligibility and the total itself (business rules in the template, which `OrderService` neither shares nor applies when it stores its total), and proposes computing them once in the domain or a service and passing the values to the view.
FAIL if it only mentions the magic numbers in the view.
