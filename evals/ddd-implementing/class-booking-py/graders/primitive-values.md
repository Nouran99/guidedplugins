---
type: llm
weight: 1
---

PASS if the review flags raw primitives standing in for meaningful concepts, such as member and session ids that are both plain strings, the start and end datetimes passed and checked as a loose pair in two places, or the credit count as a bare integer, and proposes value objects (an identifier type, a time range) that validate on construction. FAIL otherwise.
