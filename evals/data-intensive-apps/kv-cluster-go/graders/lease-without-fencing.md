---
type: llm
weight: 1
---

PASS if the review flags that the compactor checks `ExpiresAt` against its own clock and then deletes, but the node accepts the delete from anyone, so a paused compactor whose lease has expired can still delete after another holder took over, and proposes passing the lease `Token` to the node, which rejects stale tokens (fencing).
FAIL if it only suggests a longer TTL or renewing the lease.
