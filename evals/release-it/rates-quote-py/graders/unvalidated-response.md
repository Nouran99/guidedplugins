---
type: llm
weight: 1
---

PASS if the review flags that `get_rate` uses and caches the reply without validating it (no check of the HTTP status or content, no plausibility check on the rate such as zero, negative, not a number or absurdly large), so a bad reply is used and cached for ten minutes, and proposes validating before use or before caching. FAIL otherwise.
