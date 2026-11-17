---
type: llm
weight: 1
---

PASS if the review flags that every `Channel` subclass has a matching `Formatter` subclass (`EmailChannel` with `EmailFormatter`, `SmsChannel` with `SmsFormatter`) created as a pair in `ChannelFactory`, so a new channel needs two new classes, and proposes one hierarchy owning the variation (for example the channel formats its own text, or holds a formatter or format data). FAIL otherwise.
