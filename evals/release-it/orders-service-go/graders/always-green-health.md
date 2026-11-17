---
type: llm
weight: 2
---

PASS if the review flags that `/healthz` answers 200 without checking anything (the database, whether the service can really serve, whether the export job or the migration worked), so a load balancer or orchestrator keeps sending traffic to a broken instance, and proposes a health or readiness check that reflects real ability to serve. FAIL otherwise.
