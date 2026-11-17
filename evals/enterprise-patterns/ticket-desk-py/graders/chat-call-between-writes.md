---
type: llm
weight: 1
---

PASS if the review flags that `reassign` calls the chat webhook (`requests.post`) between saving the ticket and writing the audit entry, so a slow or failing call leaves the ticket changed and unaudited, and proposes doing the call after both writes (after the commit) or behind a notifier that runs once the work is done.
FAIL if it only says the HTTP call lacks retries or error handling, or proposes only a try/except around it.
