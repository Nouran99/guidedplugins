---
type: llm
weight: 1
---

PASS if the review flags the `urgent` and `plainText` boolean parameters of `DigestJob.send` (the call in `sendDigest` passes bare `false, true`) as mode switches and proposes deciding inside the module or splitting into named operations. FAIL otherwise.
