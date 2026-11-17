---
type: llm
weight: 2
---

PASS if the review says the business decisions (pickup eligibility, the deposit rule, the late fee, the cancellation fee) are made in `RentalService` while `Rental` is only data (an anemic model, a service that owns the rules), and proposes moving them onto `Rental` or a named policy. FAIL if it only mentions style or naming, or never says where the rules should live.
