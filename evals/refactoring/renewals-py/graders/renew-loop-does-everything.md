---
type: llm
weight: 2
---

PASS if the review says the loop body of `renew_due` mixes levels and phases (card lookup SQL, charging with a retry, recording the payment, moving the renewal date, formatting and mailing) and proposes extracting named steps or separating the rule from the I/O. FAIL if it only mentions the commented-out lines or the reused `total`.
