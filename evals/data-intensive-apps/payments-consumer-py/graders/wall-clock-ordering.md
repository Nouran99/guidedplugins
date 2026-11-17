---
type: llm
weight: 1
---

PASS if the review flags that `on_status_changed` decides which status is newer by comparing `occurred_at` values stamped by different services, whose clocks can disagree, so an older status can overwrite a newer one or a newer one be discarded, and proposes a per-payment version or sequence assigned by the owner of the status (or a stated clock bound) instead.
FAIL if it only notes the missing row, the type or string comparison of the timestamps or the read-then-write gap.
