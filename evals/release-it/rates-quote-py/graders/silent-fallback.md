---
type: llm
weight: 1
---

PASS if the review flags that `_rate_for` quietly substitutes `FALLBACK_RATE` (1.0) when the rates service fails, so orders are priced with an invented rate and nothing (error, degraded marker, log or metric) shows it happened, and proposes failing visibly or marking the result as degraded. FAIL if it does not point at the invented fallback.
