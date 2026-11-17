---
type: llm
weight: 1
---

PASS if the review flags that the payment charge (and the receipt mail) run inside the `@Transactional` method, so a failure or rollback after a successful charge leaves the customer charged with the invoice still unpaid, or the database transaction stays open during network calls, and proposes keeping remote work out of the transaction (after the commit, or as separate steps with a recorded state between them).
FAIL if it only says the payment call needs error handling or retries, or only mentions the tax lookups.
