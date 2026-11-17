---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit remarks, or only suggests correctness or hardening that is not a design rule of this book (for example a re-run applying fees twice, atomic booking, the time zone of "today", one more edge-case test), even if it calls such a remark major.
FAIL if it reports as a real problem that the fee rule is duplicated or scattered, a contract lives only in comments, a handle can leak, errors lose their cause or are swallowed, state is hidden or shared, names or comments mislead, the rule has no tests or a test is skipped, or if it presents a blocker or major structure or design problem or asks for a rewrite.
