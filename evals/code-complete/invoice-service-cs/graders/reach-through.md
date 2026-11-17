---
type: llm
weight: 1
---

PASS if the review flags the long navigation chains `customer.Account.Contact.Email.Address` or `customer.Account.Address.Country.Code` (coupling to the internals of other objects) and proposes hiding them behind a method of the customer or passing the email and country in. FAIL otherwise.
