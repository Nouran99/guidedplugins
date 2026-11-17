---
type: llm
weight: 1
---

PASS if the review does not recommend rewriting or restructuring the code, and its proposed fixes (if any) are small.
FAIL if it recommends a large refactor, a different consumer design, splitting or merging the classes, replacing the read model, or moving the logic to another layer.
