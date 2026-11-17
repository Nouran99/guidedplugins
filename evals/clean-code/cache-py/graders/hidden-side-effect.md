---
type: llm
weight: 2
---

PASS if the review points out that `get_data` is misleadingly named because it deletes expired entries (a hidden side effect, a command mixed with a query) AND proposes a concrete fix such as splitting removal from lookup or a clearer name. FAIL if it only comments on the parameter names or misses the deletion.
