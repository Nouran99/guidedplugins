---
type: llm
weight: 1
---

PASS if the review notes that the tests only deliver each message once and in order, against a mocked database and bus (asserting call counts), and asks for tests of at least one hard case: a duplicate delivery, a stale or reordered status event, a refund call that times out, or a replay.
FAIL if it only asks for more tests or higher coverage in general.
