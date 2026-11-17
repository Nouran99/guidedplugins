---
type: llm
weight: 1
---

PASS if the review notices that `is_active` means a payment in the last 90 days in `billing/quotes.py` but "not archived" in `support/tickets.py` (one word, two meanings) and proposes distinct names, or one definition per context on its own model. FAIL otherwise.
