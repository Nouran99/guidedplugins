---
type: llm
weight: 1
---

PASS if the review flags the call chains that reach through other objects, such as `getCustomer().getBilling().getRegion().getTaxRate()` (or `getCustomer().getContact().getEmail()`), and proposes asking the account or customer for the value directly (for example `account.taxRate()`). FAIL otherwise.
