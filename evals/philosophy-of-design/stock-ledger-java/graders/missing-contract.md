---
type: llm
weight: 1
---

PASS if the review says the public API, especially `reserve`, has no real contract (the class comment says almost nothing) although callers need to know how long a hold lasts, that held units reduce what is available, and that a shortage throws `IllegalStateException`, and proposes writing that contract. FAIL if it only calls the 900 a magic number or asks for comments in general.
