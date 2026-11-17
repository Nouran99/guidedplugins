---
type: llm
weight: 1
---

PASS if the review flags that `seatLimit` returns -1 for a plan it does not know while its precondition ("must be one of the keys") is only a comment, so a bad plan flows on as an ordinary number (for example into the paid-seat arithmetic of the nightly sync), and proposes failing fast (throw or validate where the plan enters) or a `Plan` type that cannot hold a bad value. FAIL otherwise.
