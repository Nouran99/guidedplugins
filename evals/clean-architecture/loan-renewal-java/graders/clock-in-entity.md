---
type: llm
weight: 1
---

PASS if the review flags `LocalDate.now()` inside `Loan.isOverdue()` (the domain reads the system clock) and proposes passing today's date, or a clock, in from outside. FAIL otherwise.
