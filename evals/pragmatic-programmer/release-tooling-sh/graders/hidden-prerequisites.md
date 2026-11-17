---
type: llm
weight: 1
---

PASS if the review flags that release.sh assumes an environment it never states or checks (a hard-coded `/home/dana/...` checkout, an undeclared `TWINE_PASSWORD`, no check of tools, branch, clean tree or the VERSION argument) and proposes that the script declare and verify its prerequisites and fail early with a clear message. FAIL otherwise.
