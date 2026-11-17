---
type: llm
weight: 2
---

PASS if the review flags that `SmsChannel` inherits members it cannot honor (`Attach` throws `NotSupportedException`, and `Subject` and `Attachment` are never used), so a caller holding a `Channel` cannot trust the base type, and proposes pushing those members down to the channel that supports them, a separate attachment contract, or delegation instead of inheritance. FAIL if it only says that throwing an exception is bad.
