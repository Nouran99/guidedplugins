---
type: llm
weight: 2
---

PASS if the review flags that the per-plan seat limits are defined in two places (`PLANS` and `seatLimit` in plans.ts, `MAX_SEATS` in invite-handler.ts), notes that the copies already disagree or can drift (business is 25 in one and 50 in the other), and proposes that the handler ask the single owner in plans.ts. FAIL if it only calls the numbers magic or never connects the two definitions.
