---
type: llm
weight: 1
---

PASS if the review flags that the legacy system's vocabulary (`POL_STS_CD` with "A"/"L"/"X", `PREM_AMT`, `VEH_YR`) is used directly in the pricing rules because `PolicyAdapter` returns raw JSON, and proposes translating at the boundary (a mapper or anticorruption layer returning local types or states). FAIL if it only calls the codes magic strings or the adapter thin.
