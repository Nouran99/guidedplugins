---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests hardening that lies outside this code (for example sharing breaker state between instances, tuning the numbers, alert rules, one more test case, a cap on the reply size).
FAIL if it reports, as a problem to fix before merging, that a call has no time limit, that retries are unbounded, unsafe, unjittered or stacked, that the fallback is silent, that the breaker is missing or counts refused requests as failures, that the reply is not validated, that failures are not logged or counted, or that failure behavior is untested; or if it asks for a rewrite.
