---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests extra hardening that is not a style or design rule (for example overflow for very large prices, the discount rounding, what the number parser accepts).
FAIL if it reports as a real problem something the code already does right (a magic number where the limit is a named constant, missing parsing where `parsePoints` is the boundary, an unchecked table that is validated when built, missing edge tests, a missing or stale comment), presents a blocker or major structural problem, or asks for a rewrite.
