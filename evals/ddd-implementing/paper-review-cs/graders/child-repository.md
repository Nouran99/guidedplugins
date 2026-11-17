---
type: llm
weight: 1
---

PASS if the review flags that `Review` has its own repository (`ReviewRepository`) and `AddReview` adds reviews through it, although a review is part of a `Submission`, and proposes reaching and changing reviews only through the `Submission` root and its repository. FAIL otherwise.
