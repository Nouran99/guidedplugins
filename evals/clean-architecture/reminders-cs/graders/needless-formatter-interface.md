---
type: llm
weight: 1
---

PASS if the review flags `IAmountFormatter` and `AmountFormatter` as an unnecessary abstraction (one implementation of a pure function with nothing volatile behind it, injected into two classes for no benefit) and proposes a plain helper or removing the interface. FAIL if it asks for more interfaces or does not mention it.
