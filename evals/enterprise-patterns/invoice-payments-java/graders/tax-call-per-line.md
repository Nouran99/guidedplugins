---
type: llm
weight: 1
---

PASS if the review flags that `taxRates.rateFor` (a call to another service) is made once per invoice line inside the loop in `pay`, so the number of remote calls grows with the number of lines, and proposes one coarse or batch lookup for all lines (or a cached one).
FAIL otherwise.
