---
type: llm
weight: 1
---

PASS if the review flags `/admin/purge` as an unsafe control and names at least two gaps among: no authorization, no audit record of who purged what, destructive by default (no dry run, narrow default scope or confirmation), no cap or batching of the delete, no way to stop it. It must propose safeguards. FAIL if it names only one gap or only the input handling of `before`.
