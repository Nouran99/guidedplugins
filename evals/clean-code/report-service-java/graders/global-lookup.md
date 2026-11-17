---
type: llm
weight: 1
---

PASS if the review flags `ServiceLocator.get("db")` (a hidden global dependency) and proposes injecting the dependency. FAIL otherwise.
