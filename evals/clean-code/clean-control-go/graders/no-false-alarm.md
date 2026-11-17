---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only suggests extra hardening that is not a style or design rule (for example limits already stated in the doc comment).
FAIL if it reports a naming, function-size, comment, error-handling-design or duplication problem that is not really in the code, presents a blocker or major problem about the structure, or asks for a rewrite or restructuring.
