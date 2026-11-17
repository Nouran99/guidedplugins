---
type: llm
weight: 1
---

PASS if the review flags `currentRate`, set by `quote` and read later by `ship` and `reship`, as hidden coupling between calls (shipping without a quote, or after quoting another parcel, uses the wrong rate; the service cannot be shared) and proposes returning the rate and passing it in, or keeping it on the parcel. FAIL otherwise.
