---
type: llm
weight: 1
---

PASS if the review flags that `order.paid` is published after the transaction has committed, inside a try/except that only logs, so a crash or a bus failure loses the event for good (the order is paid and nobody downstream hears), and proposes recording the event in the same transaction (an outbox) or another durable, retried step.
FAIL if it only asks for a better log message.
