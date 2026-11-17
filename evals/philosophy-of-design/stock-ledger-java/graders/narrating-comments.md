---
type: llm
weight: 1
---

PASS if the review flags the comments that only restate the code or stand in for clear names (`// add stock`, `// map of sku to quantity`, `// reservations`) and proposes deleting them, with better names (for example for `q` and `res`) carrying the meaning. FAIL if it never mentions these comments.
