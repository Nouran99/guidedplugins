---
type: llm
weight: 1
---

PASS if the review flags the exported `Sent` and `Failed` counters, which the `report` package reads and resets (bookkeeping exposed, another module maintains the notifier's state), and proposes a method that owns the counting, for example one that returns and clears the stats. FAIL otherwise.
