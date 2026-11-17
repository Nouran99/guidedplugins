---
type: llm
weight: 2
---

PASS if the review flags that `Pot.apply`, which also runs when a stored stream is replayed, reads the clock (`new Date()`) and/or throws on a stored withdrawal (the insufficient-funds check), so replay is not deterministic and can fail on history, and proposes making the command method decide and keeping `apply` a pure state change (time, if needed, carried in the event). FAIL otherwise.
