---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only nit-level remarks, or only correctness or hardening points that are not a design rule of this book (for example idle clients never leave the dictionary, a spoofable forwarded header, lock contention, TimeProvider, more test cases).
FAIL if it reports as a real problem that a class is shallow or only forwards, that an option switches behavior, that special cases pollute the core path, that comments are missing, narrate or are excessive, that names mislead, that callers must follow a hidden order, or that tests reach into internals; or if it presents a blocker or major structural problem or asks for a rewrite.
