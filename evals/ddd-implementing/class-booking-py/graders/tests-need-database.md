---
type: llm
weight: 1
---

PASS if the review criticizes the tests because the booking rules can only be exercised through `BookingService` with a real SQLite database (there is no direct test of the session or member rules without infrastructure, and rejection paths such as a full class or a double booking are not covered), or because the test names do not say what behavior they check, and proposes direct domain tests. FAIL if it only says to add more tests.
