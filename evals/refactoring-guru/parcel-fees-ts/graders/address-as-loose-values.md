---
type: llm
weight: 1
---

PASS if the review flags that `street`, `city`, `postcode` and `country` travel together through several signatures (`quoteFee`, `isDeliverable`, `buildLabel`, `summarize`) and proposes one object for the address (or passing the whole request). FAIL if it only says there are many parameters without seeing the repeated group.
