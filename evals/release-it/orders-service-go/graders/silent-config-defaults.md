---
type: llm
weight: 1
---

PASS if the review flags that critical settings are not validated at startup: `DATABASE_URL` silently falls back to a local development database, or the `DB_POOL_SIZE` parse error is ignored (zero means unlimited connections), instead of failing fast with a message that names the setting. It must propose validating the configuration at startup. FAIL otherwise.
