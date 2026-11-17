---
type: llm
weight: 1
---

PASS if the review flags that `Order` does not protect its own state: `status` is a free string that the service assigns directly (cancel, refund, label printing), and the "shipped orders cannot be cancelled or refunded" check is repeated in the service, so nothing stops an invalid transition; and it proposes putting the state changes and their guards on `Order` (for example `cancel()`, `refund()`, `ship()`, possibly with a status enum).
FAIL if it only suggests an enum or constants for the status strings, or never says the guards should live on `Order`.
