---
type: llm
weight: 1
---

PASS if the review flags the branches keyed on specific tenants (`acme-gmbh`, `northwind`) or on country and date (`DE` before 2024-01) inside the main export loop, and proposes isolating those rules in a named place or as data so the core path stays general. FAIL otherwise.
