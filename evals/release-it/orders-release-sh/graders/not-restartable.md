---
type: llm
weight: 2
---

PASS if the review flags that the script cannot be rerun or resumed safely after a partial failure: it records no progress, does not check what a host already runs, and a rerun repeats the migration and every host from the start. It must propose idempotent steps with a probe and/or a durable per-host checkpoint. FAIL otherwise.
