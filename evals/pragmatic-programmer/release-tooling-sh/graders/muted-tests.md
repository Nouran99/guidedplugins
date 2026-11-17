---
type: llm
weight: 1
---

PASS if the review flags `pytest -q tests/unit || true` in release.sh, which lets a release go on after failing tests, and proposes removing the `|| true` and fixing or separately quarantining whatever fails. FAIL otherwise.
