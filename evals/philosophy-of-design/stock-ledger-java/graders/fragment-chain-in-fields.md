---
type: llm
weight: 2
---

PASS if the review flags that `reserve` is cut into tiny private steps (`computeAvailable`, `checkAvailable`, `book`) that hand their data over through the instance fields `currentSku`, `wanted` and `available`, and proposes one method with local variables (or otherwise merging the steps). FAIL if it never mentions these fields or the chain of steps.
