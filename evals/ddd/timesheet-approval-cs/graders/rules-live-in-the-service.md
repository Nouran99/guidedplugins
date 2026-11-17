---
type: llm
weight: 2
---

PASS if the review flags that the timesheet's lifecycle rules (status codes, the approver must not be the employee, the 60-hour cap) are decided in `TimesheetService` while `Timesheet` is only public properties, and proposes behavior on `Timesheet` (submit, approve) with protected state. FAIL if it only suggests naming the status values or adding an enum.
