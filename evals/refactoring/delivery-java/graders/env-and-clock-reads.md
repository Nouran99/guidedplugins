---
type: llm
weight: 1
---

PASS if the review flags that `DeliveryService` reads the environment (`System.getenv("FUEL_SURCHARGE")` in `quote`) and/or the clock (`Instant.now()` in `ship` and `reship`) inside its methods, a hidden input that makes them hard to test, and proposes passing the fuel rate and a clock or time in. FAIL if it only reports that the variable may be missing or fail to parse.
