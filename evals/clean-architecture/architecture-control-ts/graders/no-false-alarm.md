---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only extra hardening that is not an architecture rule (concurrent saves, more test cases, a real-Postgres test or contract suite for the store, expiry checks, authorization, database errors, logging).
FAIL if it reports as a real problem that an inner layer depends on an outer layer or a framework, a rule sits in the controller or the store, the entity is unguarded, a port is missing or misplaced, wiring or configuration is misplaced, the folders should differ, or tests need the framework or database; or it presents a blocker or major structural problem, or asks for a rewrite.
