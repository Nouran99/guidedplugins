---
type: llm
weight: 1
---

PASS if the review flags `settings.get()`, a module-level singleton read from inside the job (constructor and `run`), as hidden global configuration that a test cannot replace, and proposes passing the values or a settings object in, or wrapping the global. FAIL if it only mentions the environment variables read in `settings.py`, or only that the constructor opens a connection.
