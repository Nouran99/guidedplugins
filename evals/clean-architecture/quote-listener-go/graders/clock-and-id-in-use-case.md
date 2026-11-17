---
type: llm
weight: 1
---

PASS if the review flags that the use case reads the system clock (`time.Now()`) or generates the identifier (`uuid.NewString()`) itself, as volatile dependencies called directly from core code, and proposes passing the time and id in, or small ports for them.
FAIL if it only mentions the hard-coded 15 minutes, or mentions neither call.
