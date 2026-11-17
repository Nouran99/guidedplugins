---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only correctness or hardening points that are not a design or style rule (time zones, regional holidays, a daily cap, an unknown vehicle kind inside the grace period, idempotent charges, more test cases, logging).
FAIL if it reports a design or style smell that is not in the code (duplication between the two 15 minute constants, the vehicle `switch` needing polymorphism, the adapter or interfaces being needless layers, the holiday table or `Fee` being too long, helpers being noise, naming or comments), presents a structural problem as a blocker or major, or asks for a rewrite.
