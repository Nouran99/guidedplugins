---
type: llm
weight: 1
---

PASS if the review flags that the release version is written in several places (pyproject.toml, the package `__init__.py` and docs/conf.py, patched by `sed` in release.sh, plus the image tag in the Makefile that nothing updates), one fact with several owners that can drift, and proposes a single source the others read or derive from. FAIL if it only criticizes the `sed` quoting or the missing `-u` flags.
