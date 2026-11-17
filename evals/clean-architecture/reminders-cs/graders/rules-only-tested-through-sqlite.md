---
type: llm
weight: 1
---

PASS if the review notes that the reminder rules are only tested through `SqlReminderGateway` against an EF Core SQLite database (`ReminderGatewayTests`), with nothing testing the use case or a domain object directly, and proposes testing the rules on a domain object or the use case with a fake gateway. FAIL otherwise.
