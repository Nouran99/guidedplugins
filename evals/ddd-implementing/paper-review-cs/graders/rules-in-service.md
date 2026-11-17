---
type: llm
weight: 2
---

PASS if the review flags that the review and decision rules (status strings, the review-count and average-score conditions, the author-cannot-review rule) live in `SubmissionService` branching while `Submission` is a data-only class with public setters and a free-text status, and proposes moving the behavior onto `Submission` (for example methods to add a review, accept or reject) that guard the transitions. FAIL otherwise.
