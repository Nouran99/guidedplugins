---
type: llm
weight: 2
---

PASS if the review flags that `consume` trusts the queue message: the fields it uses are neither parsed nor validated at entry (for example an `order_id` that matches no order makes `load_order` return None and a later `order[...]` fail, and `amount_cents` and `reason` are never type or range checked), and it proposes validating the message once at the boundary and rejecting bad ones with a diagnosable error. FAIL if its only point about the message is the `assert`.
