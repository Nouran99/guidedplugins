---
type: llm
weight: 1
---

PASS if the review flags that `FeeMailer` only works when called in a fixed order (`open()`, then `setTemplate()`, then `send()`, then `close()`) that nothing enforces beyond a comment, so a forgotten step surfaces as an obscure NullPointerException, and proposes an object that is ready on construction, a single call that takes the template, or a clear failure naming the missing step. FAIL otherwise.
