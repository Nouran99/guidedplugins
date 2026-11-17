---
type: llm
weight: 1
---

PASS if the review flags that the tests of the quoting rules need real infrastructure (a Kafka broker, a database, the carrier sandbox, the wall clock with `time.Sleep`) instead of exercising the use case or the rules with fakes, and proposes fast tests with fakes for the carrier, the store and the time.
FAIL if it only says the tests are slow, flaky or incomplete without tying that to the missing fakes or seams.
