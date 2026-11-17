---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests extra hardening that is not a modeling rule (for example concurrency control, an outbox for publishing, time-zone handling of the arrival day, input validation, more test cases, rounding documentation).
FAIL if it reports as a real problem that the model is anemic, that rules sit in the service, that primitives need value objects, that transitions are unguarded, that events are wrong, that names are off, that the subdomain or context is unclear, that a translator or boundary is missing, or if it presents a blocker or major structural problem or asks for a rewrite.
