---
type: llm
weight: 2
---

PASS if the review flags that the `LateFeeJob` constructor opens a real database connection, so the job cannot be built in a test without a database, and proposes passing the connection (or a repository or factory) in. FAIL otherwise.
