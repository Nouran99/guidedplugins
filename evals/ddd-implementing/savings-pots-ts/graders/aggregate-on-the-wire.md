---
type: llm
weight: 1
---

PASS if the review flags that the handlers return the `Pot` aggregate itself through `res.json(pot)`, which exposes its internal state (for example `version` and `updatedAt`) and ties the API to the aggregate's shape, and proposes a separate response representation or DTO.
FAIL otherwise.
