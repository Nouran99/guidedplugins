---
type: llm
weight: 1
---

PASS if the review flags that the `Product.save` tests mock `db.query` and only assert that certain SQL text and parameters were passed (they restate the code and cannot catch a wrong statement), and proposes a round-trip test against a real or faithful local database through the mapper or repository.
FAIL otherwise.
