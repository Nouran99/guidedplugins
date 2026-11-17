---
type: llm
weight: 1
---

PASS if the review flags that `SubmissionRepository.Update` applies a business rule (three reviews move the status to "ready") inside persistence code, and proposes keeping that rule in the `Submission` model and leaving the repository to persistence. Noticing that `SubmissionService.Decide` re-checks the same review count is a plus, not required.
FAIL otherwise.
