---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests behavior or hardening points that are not refactoring rules (for example a fee larger than the payment, overflow, the clock, provider idempotency, more tests, wording).
FAIL if it reports as a real problem a long method, a switch that needs polymorphism, duplicate code (the look-alike refund functions are explained in a comment), magic numbers or primitive obsession, a long parameter list on `Purchase`, a comment that should be a name, speculative code, a middle man or feature envy; or it presents a blocker or major problem about the structure, or asks for a rewrite.
