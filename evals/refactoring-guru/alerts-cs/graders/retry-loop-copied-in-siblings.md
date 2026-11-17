---
type: llm
weight: 1
---

PASS if the review flags that `EmailChannel.Send` and `SmsChannel.Send` repeat the same three-attempt retry loop with the same sleep and differ only in the transport call, and proposes one shared home for it (a template method in the base class where subclasses supply the delivery step, or a shared helper). FAIL otherwise.
