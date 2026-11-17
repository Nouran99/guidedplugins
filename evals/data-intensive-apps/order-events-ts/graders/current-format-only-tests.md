---
type: llm
weight: 1
---

PASS if the review notes that the tests feed only today's message shapes, once each, to a mocked database that only counts calls, and asks for tests of at least one hard case: an older payload, an unknown field or type, a duplicate delivery or an out-of-order pair.
FAIL if it only asks for more tests or higher coverage in general.
