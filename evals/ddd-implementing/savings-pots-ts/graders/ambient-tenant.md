---
type: llm
weight: 1
---

PASS if the review flags that the event store takes the tenant from an ambient `AsyncLocalStorage` context (`currentTenant()`) instead of an explicit scope parameter, so ownership that affects access is hidden and fails at runtime when the context is missing, and proposes passing the tenant (or owner) explicitly in commands, queries and store calls. FAIL otherwise.
