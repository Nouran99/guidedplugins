---
type: llm
weight: 1
---

PASS if the review notes that `quote_renewal` mixes the retry loop, cache and sleep with the renewal pricing rules the business changes every quarter, so the rules are hard to find and test, and proposes separating the pricing policy (a pure function or domain object) from fetching and caching. FAIL if it only suggests hardening the loop (narrower exceptions, dropping the global cache).
