---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests extra hardening that is not a modeling rule (for example optimistic concurrency, an outbox, constant-time code comparison, attempt limits, more tests, how the adapters under src/infra will rebuild a Deposit).
FAIL if it reports as a real problem an anemic model, rules in the service, missing value objects, unguarded transitions, wrongly shaped events, bad names or language, a missing translator, contract mapper or boundary, an oversized aggregate, or if it presents a blocker or major structural problem or asks for a rewrite.
