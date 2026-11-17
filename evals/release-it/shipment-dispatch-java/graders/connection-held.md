---
type: llm
weight: 1
---

PASS if the review flags that the database connection stays open while `carrier.book` (a remote call) runs for every shipment, so a slow carrier ties up a pooled connection, and proposes reading first and releasing the connection, or making the remote calls outside the connection scope. FAIL otherwise.
