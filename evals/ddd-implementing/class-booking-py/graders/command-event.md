---
type: llm
weight: 1
---

PASS if the review flags `SendBookingReceipt` as an event that is named like a command (an instruction to send something) instead of a past-tense business fact such as a seat having been booked, or flags that its payload is database rows instead of domain identities and values, and proposes a fact-shaped event with domain data. FAIL otherwise.
