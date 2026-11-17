---
type: llm
weight: 1
---

PASS if the review points out that `get_amount_due` is named like a read but updates `quoted_cents` in the database (so even a dry run writes), and proposes separating the write from the calculation or naming it honestly. FAIL if it only comments on the name, the rounding or the tax without the database write.
