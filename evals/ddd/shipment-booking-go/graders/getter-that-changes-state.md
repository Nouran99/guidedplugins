---
type: llm
weight: 1
---

PASS if the review flags that `GetNextSlot` reads like a query but increments the depot's slot counter (a hidden side effect), and proposes separating the question from the command or renaming it to say that it reserves a slot. FAIL otherwise.
