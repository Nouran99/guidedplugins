---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only extra hardening or extra test cases that are not a design rule of the book (for example overflow, idempotent awards, a failure between saving and announcing, authorization, logging, weekends in UTC).
FAIL if it reports as a real problem a hidden input, a missing seam, a class that cannot be built in a test, a static or global dependency, a rule trapped in the controller, a hard-coded collaborator, an effect not behind a collaborator, a long method, or untested rules, service or controller (they are tested); or gives a blocker or major structural finding; or asks for a rewrite.
