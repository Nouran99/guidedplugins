---
type: llm
weight: 1
---

PASS if the review flags the loop that steps a `Date` forward skipping Saturdays and Sundays (`setDate`, `getDay` 0 and 6) as copied in `labels.ts` and `summary.ts`, and proposes one shared helper for it. FAIL otherwise.
