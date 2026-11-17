---
type: llm
weight: 1
---

PASS if the review flags that `EventStore.append` writes events with no expected stream version or optimistic concurrency check (the pot's `version` is never used), so two concurrent commands on one pot silently interleave or overwrite, and proposes an expected-version append that rejects a conflict. FAIL otherwise.
