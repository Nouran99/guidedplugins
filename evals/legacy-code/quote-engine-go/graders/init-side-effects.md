---
type: llm
weight: 1
---

PASS if the review flags the package-level `ratePerKg` filled by an `init()` that reads `/etc/shipping/rates.json` and exits on failure, so merely loading the package (including in tests) needs the file, and proposes loading the rates explicitly and passing them in. FAIL otherwise.
