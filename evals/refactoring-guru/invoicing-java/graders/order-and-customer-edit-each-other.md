---
type: llm
weight: 1
---

PASS if the review flags that `Order` and `Customer` reach into each other's fields (`Order.cancel` edits `customer.orders` and `customer.openBalance`; `Customer.addOrder` sets `order.customer` and `order.status`) and proposes moving those updates behind the methods of one side, or dropping the back reference. FAIL otherwise.
