---
type: llm
weight: 1
---

PASS if the review notices that the rounding of the weight to half kilograms (`Math.ceil(weightKg * 2) / 2`) is written out in more than one file (`fees.ts`, `labels.ts`, `summary.ts`), and proposes one function or owner for the billable weight. FAIL otherwise.
