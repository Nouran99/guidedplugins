---
type: llm
weight: 1
---

PASS if the review flags that `Rental.status` is a bare string that the service compares with and assigns as literals ('booked', 'active', 'returned', 'cancelled'), so any code can set any status, and proposes a named status type and/or transition methods on `Rental` that reject invalid moves. FAIL otherwise.
