---
type: llm
weight: 2
---

PASS if the review flags that the `ReceiptMailer` constructor connects to the mail relay (host from an environment variable) and reads configuration, so the class cannot be created in a test without a mail server, and proposes passing the client in (constructor parameter or factory). FAIL otherwise.
