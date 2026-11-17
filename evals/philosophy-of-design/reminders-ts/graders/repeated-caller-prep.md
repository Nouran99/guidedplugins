---
type: llm
weight: 1
---

PASS if the review notices that the three `createFrom...` handlers repeat the same preparation (default zone, trim and 280-character cut, conversion to UTC) before calling `create`, and proposes moving it into the reminders module so callers pass raw values. FAIL otherwise.
