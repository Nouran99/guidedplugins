---
type: llm
weight: 1
---

PASS if the review flags that the Makefile targets contributors run (`make test`, `make lint`) differ from what ci.yml runs (contract tests and mypy only in CI, a different ruff scope), so green locally does not mean green in CI, and proposes one script or target that both call. FAIL otherwise.
