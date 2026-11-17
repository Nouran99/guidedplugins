---
type: llm
weight: 1
---

PASS if the review flags that all six hosts are stopped and replaced at the same time (background subshells), with no canary host, no batches and no health check between steps, so a bad build takes the whole fleet down at once, and proposes a staged rollout (one host or a small batch first, verify, then continue). FAIL otherwise.
