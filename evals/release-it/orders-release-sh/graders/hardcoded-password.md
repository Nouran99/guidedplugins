---
type: llm
weight: 1
---

PASS if the review flags the production database password hard-coded in the script and printed by `echo "migrating ${DB_URL}"`, and proposes taking the credential from a secret store or the environment and keeping it out of the output. FAIL otherwise.
