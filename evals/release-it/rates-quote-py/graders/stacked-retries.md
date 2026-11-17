---
type: llm
weight: 2
---

PASS if the review notices that the retry loop in `_rate_for` (quote_service.py) wraps `get_rate`, which already retries internally, so the layers multiply (up to 3 x 5 = 15 attempts per lookup, each without a time limit), and proposes one layer that owns retries or a single attempt and time budget. FAIL if it criticizes each loop separately without noticing that they compound.
