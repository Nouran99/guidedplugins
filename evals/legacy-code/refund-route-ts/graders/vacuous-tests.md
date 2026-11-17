---
type: llm
weight: 1
---

PASS if the review flags at least one test that proves nothing: the unknown-order test has no assertion at all, or the old-order test only checks that `lastDecision` is defined, which holds for approved and rejected alike, so the window rule is not checked. FAIL if it only asks for more tests or says coverage is low.
