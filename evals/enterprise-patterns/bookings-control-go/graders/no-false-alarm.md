---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor points: nits, or hardening and correctness remarks that are not about structure (for example who may cancel, retrying a failed notice, a panic inside the transaction, logging, time zones, more test cases).
FAIL if it reports as a real problem a rule in the wrong layer, an unowned or misplaced transaction or commit, the notice belonging inside the transaction, a missing or misplaced version check, a store or handler that does too much, a layer that only forwards, a test at the wrong level or layers the code does not need; or it gives a blocker or major structural finding, or asks for a rewrite.
