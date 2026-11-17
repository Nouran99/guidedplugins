---
type: llm
weight: 1
---

PASS if the review flags that `exportAll` starts one goroutine per tenant with no limit on how many run at once (each one queries the database and writes a file), so the number of tenants decides the load, and proposes a worker limit, semaphore or bounded queue. FAIL if it only discusses the start time of the schedule.
