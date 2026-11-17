---
type: llm
weight: 1
---

PASS if the review flags that `OrderService.Place` (and `OrderManager.Place`) take the ASP.NET `IFormCollection`, so the application layer depends on the web framework and parses form fields, and proposes a plain command or parameters that the controller builds from the request.
FAIL otherwise.
