---
type: llm
weight: 1
---

PASS if the review says `late_fee` mostly reads the account's and plan's data (`grace_days`, `late_rate`, `minimum_fee`, `balance`) instead of the builder's own, so the fee rule belongs on `Plan` or `Account`, and proposes moving it there. FAIL otherwise.
