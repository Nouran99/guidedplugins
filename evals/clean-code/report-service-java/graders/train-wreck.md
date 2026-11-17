---
type: llm
weight: 1
---

PASS if the review flags the long call chain `c.getAddress().getCity().getName()` (a Law of Demeter or train-wreck problem) and proposes asking the customer for the city name. FAIL otherwise.
