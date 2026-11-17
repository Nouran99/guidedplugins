---
type: llm
weight: 1
---

PASS if the review flags that an amount in cents and its currency travel as separate loose primitives through `format_amount`, `charge_card` and `record_payment`, and/or that the `"EUR"` literal is repeated in `renew_due`, and proposes a money value type or at least a named currency constant. FAIL if it only discusses float arithmetic or rounding of the amounts.
