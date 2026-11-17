---
type: llm
weight: 2
---

PASS if the review flags that `TicketRepository.save` and `AuditLog.record` each commit on their own, so `reassign` and `close` have no single transaction owner and a failure after the first write leaves a saved ticket without its audit row, and it proposes one commit owned by the service (or a unit of work) with helpers that do not commit.
FAIL if it only asks for error handling or a try/except.
