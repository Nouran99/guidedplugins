---
type: llm
weight: 1
---

PASS if the review flags that `Entry.is_overdue` is named like a pure question but also writes `reminded_on`, so merely asking changes the data, and proposes separating the check from the update (a pure check and a separate method that records the reminder). FAIL otherwise.
