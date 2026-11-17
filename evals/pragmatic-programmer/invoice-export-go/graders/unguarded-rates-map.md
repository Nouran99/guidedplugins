---
type: llm
weight: 2
---

PASS if the review flags `rates` as a package-level mutable map that the refresh goroutine empties and refills while `ToEUR` reads it, with no lock or stated owner, so readers can see it empty or half filled (or crash), and proposes an owner with a guard or an immutable snapshot swapped in one step. FAIL otherwise.
