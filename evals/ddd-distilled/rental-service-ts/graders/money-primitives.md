---
type: llm
weight: 1
---

PASS if the review flags that money is carried as bare `number` fields (`dailyRate`, `deposit`, `fee`) next to a separate `currency` string, with per-currency amounts and rounding repeated in the service, and proposes a Money value object that validates and carries its currency. FAIL otherwise.
