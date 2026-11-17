---
type: llm
weight: 1
---

PASS if the review flags `double` used for money (the invoice total, the line unit price, `splitInstalments`) and proposes `BigDecimal`, integer minor units or a Money type, ideally with the rounding or allocation rule in one place.
FAIL if it only says that floating point is imprecise, or only mentions rounding of one number, without proposing a money representation.
