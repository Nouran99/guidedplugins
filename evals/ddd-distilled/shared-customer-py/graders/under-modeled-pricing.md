---
type: llm
weight: 1
---

PASS if the review flags that the discount rules in `billing/quotes.py` are scattered conditionals over string tier keys and unexplained numbers, repeated in `price_quote` and `price_renewal`, and proposes naming the concept in one place (a discount policy, a tier type or value objects). FAIL otherwise.
