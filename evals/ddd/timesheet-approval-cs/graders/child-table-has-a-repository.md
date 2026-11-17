---
type: llm
weight: 1
---

PASS if the review flags that `TimeEntryRepository` is a repository for a child table and that the controller adds entries through it without going through `Timesheet`, so the root cannot guard its own rules for entries (for example no entries once the sheet is submitted, the weekly hour cap), and proposes a repository for the timesheet root only, with entries added through a method on the root. FAIL if it only says the repository is redundant or the controller is thick.
