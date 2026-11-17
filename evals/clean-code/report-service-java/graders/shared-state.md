---
type: llm
weight: 2
---

PASS if the review flags the public static mutable `counts` map as shared mutable state that is not protected against concurrent use (thread safety), and proposes a safe alternative. FAIL otherwise.
