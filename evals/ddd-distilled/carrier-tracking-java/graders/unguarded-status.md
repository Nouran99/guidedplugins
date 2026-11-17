---
type: llm
weight: 1
---

PASS if the review flags `Shipment.setStatus(String)` (and `setPodAt`) as unrestricted setters with free-text statuses that any caller can set to any value, with no guarded transitions, and proposes named transitions on `Shipment` (or at least a typed status with the setters removed). FAIL otherwise.
