---
type: llm
weight: 1
---

PASS if the review notes that `renew_due` (charging, retry, recording the payment, moving the renewal date, mailing) has no real test, because its only test passes an empty list and checks none of those effects, and asks for tests that pin that behavior before the code is restructured or merged. FAIL otherwise.
