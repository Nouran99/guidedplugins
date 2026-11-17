---
type: llm
weight: 1
---

PASS if the review flags that `CreditGrade.fromBureauBand` quietly sends every band letter it does not recognise (anything but A, B, D, E, so also a garbage band) to NEAR_PRIME instead of refusing it, and proposes failing on or explicitly handling unknown bands. FAIL if it only notes that band C or the other bands lack tests.
