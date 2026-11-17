---
type: llm
weight: 1
---

PASS if the review flags that `Approve` changes the project's used hours (via `TimeEntry.Project`) and the timesheet in one `SaveChangesAsync`, so one use case spans two aggregates and an entry holds a live `Project`, and proposes referencing the project by identifier and updating its budget separately (or justifying one transaction). FAIL otherwise.
