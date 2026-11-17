---
type: llm
weight: 1
---

PASS if the review flags `Ioc.Resolve<IMailer>()` inside `OrderService.Place` as a hidden global dependency (a static lookup of a collaborator that is not in the constructor) and proposes receiving the mailer through the constructor, with any container lookup kept at the wiring point.
FAIL otherwise.
