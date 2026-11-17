---
type: llm
weight: 2
---

PASS if the review flags that one executor (`pool`, 16 threads) runs everything: the carrier booking batch, the customer emails and the warehouse notifications, so a slow carrier, mail server or warehouse hook can occupy every thread and stall the rest, and proposes separate bounded pools, semaphores or workers per dependency or workload. FAIL if it only says the queue is unbounded or the pool is too small.
