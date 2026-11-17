---
type: llm
weight: 1
---

PASS if the review flags that the `update` handler writes the submitted fields back to the ticket row with no version or other check, so two people editing the same ticket silently overwrite each other (a lost update), and proposes an optimistic check (a version column with a conditional update, an ETag or an equivalent) that fails with a named conflict instead of overwriting.
FAIL if it only mentions input validation.
