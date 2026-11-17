---
type: llm
weight: 1
---

PASS if the review compares related operations and flags at least one concrete inconsistency among them (lookup verbs `getStock`, `fetchReservation` and `loadHold`; absence reported as null, Optional or an exception; `add(sku, n)` against `remove(n, sku)`; reservation against hold) and proposes one convention. FAIL if it never compares the sibling operations.
