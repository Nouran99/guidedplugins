---
type: llm
weight: 1
---

PASS if the review flags that `RenewLoan` itself constructs the concrete mail sender (`new SmtpNotifier(System.getenv("SMTP_HOST"), 587)`) and/or reads the SMTP host from the environment inside the use case, and proposes depending on a notification abstraction that the application owns and that is supplied from outside (constructor injection, with construction and configuration at the edge).
FAIL if it never says that the use case creates the notifier or reads configuration itself.
