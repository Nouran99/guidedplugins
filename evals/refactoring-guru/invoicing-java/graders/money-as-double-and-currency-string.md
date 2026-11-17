---
type: llm
weight: 1
---

PASS if the review flags that money is a bare `double` travelling with a currency `String` through several methods (`save`, `charge`, `render`, `format`), with nothing that owns the pair, and proposes a `Money` value object (amount and currency, with validation or arithmetic). FAIL if it only says to use `BigDecimal` instead of `double`.
