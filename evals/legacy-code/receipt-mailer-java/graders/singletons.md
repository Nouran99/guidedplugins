---
type: llm
weight: 1
---

PASS if the review flags `OrderRepository.instance()`, a process-wide singleton reached from inside `handleResend`, as a hidden global dependency that a test cannot replace, and proposes injecting the repository or putting a wrapper in front of the singleton. FAIL if it only mentions thread safety or initialization order, or only the `Config` lookups.
