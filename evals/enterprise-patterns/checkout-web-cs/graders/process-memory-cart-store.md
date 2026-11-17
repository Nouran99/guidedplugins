---
type: llm
weight: 1
---

PASS if the review flags the static in-memory `CartSession` dictionary because it lives in one process (carts are lost on restart and not shared across instances) or never expires (abandoned carts and the empty ones created by `Get` pile up), and proposes a shared or database store with an expiry and cleanup, or keeping only identifiers in the session.
FAIL if it only mentions thread safety.
