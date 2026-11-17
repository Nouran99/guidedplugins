---
type: llm
weight: 2
---

PASS if the review says `ReminderService` only forwards each call to `ReminderStore` with the same arguments (a pass-through or shallow layer that adds a name and a hop) and proposes removing it or moving real work into it. FAIL if it never questions the service or only comments on its naming.
