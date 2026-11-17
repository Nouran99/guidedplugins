---
type: llm
weight: 1
---

PASS if the review flags that the `userId|dueAt|text` encoding is known to both `ReminderStore` and `DigestJob` (the store hands out raw encoded strings and the digest splits them on `|`) and proposes that the store return `Reminder` objects or own the encoding. FAIL if it only reports that a `|` in the text would break parsing without saying that two modules share the format.
