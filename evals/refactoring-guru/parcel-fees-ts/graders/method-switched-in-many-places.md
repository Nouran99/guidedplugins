---
type: llm
weight: 2
---

PASS if the review notices that the same decision on the delivery mode (`ground`, `air`, `locker`) is made in several files (`fees.ts`, `labels.ts`, `summary.ts`), so a new mode means editing all of them, and proposes giving that decision one home (a table or an object per mode holding fee, service name, days and wording, or polymorphism). FAIL if it only comments on one switch in isolation or only adds a default case.
