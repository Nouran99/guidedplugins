---
type: llm
weight: 1
---

PASS if the review flags that the service runs its schema migration (the DDL, including the index build) in `main` at startup, on every instance, and proposes moving it to a separate, controlled step or job (or at least guarding it so that it cannot hold up or repeat across a rolling restart or scale-out). FAIL otherwise.
