---
type: llm
weight: 2
---

PASS if the review flags that the use case depends on the concrete carrier SDK (`QuoteShipping` holds a `*fedex.Client` and/or `Offer` exposes the SDK's `*fedex.RateReply`) and proposes a port owned by the core and named for the capability (for example shipping rates), with the SDK confined to an adapter.
FAIL if it only mentions error handling or naming.
