---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests hardening that is not a modeling rule (for example time zones, concurrency control, more test cases, logging).
FAIL if it reports as a real problem an anemic model, rules outside the entity, primitives that need value objects, unguarded transitions, wrong aggregate boundaries or references, inconsistent names, a missing or too thin legacy translation, or a missing repository, factory or domain service; or if it gives a blocker or major structural finding or asks for a rewrite.
