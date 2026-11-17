---
type: llm
weight: 2
---

PASS if the review notices the same `switch` on the carrier string in `rateFor`, `trackingUrl` and `withinWeightLimit` (adding a carrier means editing all three) and proposes one carrier type, enum or table that holds the rate, the URL and the limit. FAIL if it only says the switch is long or the strings are magic.
