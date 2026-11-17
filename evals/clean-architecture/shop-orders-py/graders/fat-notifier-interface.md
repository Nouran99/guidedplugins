---
type: llm
weight: 1
---

PASS if the review flags that `Notifier` forces every implementation to offer email, SMS, push and Slack, so `EmailNotifier` raises `NotImplementedError` for three of them, and proposes small interfaces by role (for example one for sending email). FAIL otherwise.
