---
type: llm
weight: 1
---

PASS if the review does not recommend rewriting or restructuring the code, and its proposed fixes (if any) are small.
FAIL if it recommends a large refactor, adding or removing layers or packages, merging or splitting packages, moving the rules or the transaction to another layer, or replacing the design.
