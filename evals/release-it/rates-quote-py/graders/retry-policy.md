---
type: llm
weight: 1
---

PASS if the review flags the retry loop in `get_rate` as undisciplined for at least one of these reasons: it retries every exception, including permanent failures such as a malformed reply; it sleeps a fixed second with no growing backoff or jitter. It must also propose retrying only transient errors and/or backoff with jitter. FAIL otherwise.
