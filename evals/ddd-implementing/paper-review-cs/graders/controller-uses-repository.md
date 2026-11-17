---
type: llm
weight: 1
---

PASS if the review flags that `SubmissionsController` works directly with the aggregate: it returns the `Submission` entity (with all its reviews) to API clients and/or reads it from the repository and tests its status itself, and proposes a response type or view model with the controller calling an application service or query.
FAIL if it only says the controller is long or lacks validation.
