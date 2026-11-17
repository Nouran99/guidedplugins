---
type: llm
weight: 1
---

PASS if the review flags that an unrecognised carrier status code is silently mapped to IN_TRANSIT (the `default` branch in `ShipmentTracker` and the final `else` in `TrackingWebhook`), so a new upstream value becomes a wrong local fact, and proposes failing loudly or an explicit unrecognised result. FAIL otherwise.
