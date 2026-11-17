---
type: llm
weight: 1
---

PASS if the review flags what the handler pulls from its surroundings, the actor from `currentActor()` (request-scoped storage) and/or the clock reads (`Date.now()`, `new Date()`), as hidden inputs, and proposes passing the actor and the time in explicitly. FAIL otherwise.
