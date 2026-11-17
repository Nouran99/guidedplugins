---
type: llm
weight: 3
---

PASS if the review says the code is fine or needs no change, or raises only minor or nit-level remarks, or only hardening that is not a data-design rule (for example metric names, alert thresholds, pruning outbox rows, a poison-message path, more test cases, the relay not being in this change).
FAIL if it presents as a real problem (blocker, major or required change) missing idempotency or deduplication, a missing or wrong ordering or version rule, a notification not safely queued with the write, unknown statuses or fields not handled, a view that cannot be rebuilt, missing duplicate, late or replay tests, or `occurredAt` deciding order; or if it asks for a rewrite.
