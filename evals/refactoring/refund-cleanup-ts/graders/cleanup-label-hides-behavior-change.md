---
type: llm
weight: 2
---

PASS if the review says the pull request is presented as a pure refactoring with no behavior change, yet it also changes behavior (orders older than 30 days are now rejected instead of going to manual review, and the fee rounding changed), and asks for the behavior changes to be split into their own change or the description to be corrected. FAIL if it accepts the no-behavior-change claim, or lists the behavior changes without pointing out the conflict with that claim.
