---
name: "replication-topology"
description: "Use when choosing or reviewing leader-follower, multi-leader or leaderless replication, sync versus async followers, failover, quorums, replica read routing or replica conflict resolution. Freshness promises are consistency-contract; locks and leases are faults-and-coordination."
---

# Replication topology, failover and conflicts

Chooses how copies of data are kept, what happens when a node dies, and how replicas that accepted different writes are reconciled. What readers are promised is `$data-intensive-apps:consistency-contract`; leases, locks and leader election as coordination are `$data-intensive-apps:faults-and-coordination`; making a derived copy repairable is `$data-intensive-apps:derived-data`.

## When to use

- You choose or change a database topology: one leader, several leaders (regions, offline clients), or leaderless quorums.
- A design says "we replicate to N nodes" without saying how, when acknowledgments happen, or what failover does.
- Reads are routed to followers, or a client reads from "any node".
- A claim says the quorum settings guarantee the latest value.
- Two replicas can accept writes to the same record.

## Rules

1. **Pick leader-follower, multi-leader or leaderless replication from where writes originate, how many failures must be tolerated, the latency needed and how conflicts will be handled.** Check: there is a written reason for each of those four.
2. **Spell out what is gained and lost by replicating synchronously versus asynchronously.** Check: you can say which followers are synchronous, what happens to writes when one is down, and what is lost if the leader dies before asynchronous followers catch up.
3. **Specify what happens during a node outage, while a follower catches up, at failover and when the cluster is reconfigured.** Check: for loss of the leader you can say who takes over, how clients find the new leader, what becomes of writes not yet replicated, and how a stale former leader is stopped from accepting writes.
4. **Guarantee read-your-writes, monotonic reads and consistent-prefix reads only for flows that need them, and only when the design supplies the mechanism.** Check: each read path maps to the guarantee it needs and the mechanism that supplies it.
5. **Do not trust a quorum formula until it has been checked against stale reads, sloppy quorums, hinted handoff and concurrent writes.** Overlapping read and write sets help but do not by themselves give the latest value under all failures. Check: a claim that `w + r > n` yields fresh reads is accompanied by the cases it does not cover.
6. **Spell out how concurrent writes are detected as conflicting and how each conflict is resolved.** Check: for every entity that can be written on more than one replica, the detection (versions, causal metadata) and the resolution (merge, reject, last writer wins with its loss stated) are named.
7. **State how replicas converge after divergence, and how long that takes.** Compact rule (convergence needs). Check: a partition-heal scenario has a documented end state.
8. Added judgment: **Measure replication lag and let read routing consult it.** A follower beyond the tolerated lag is skipped for reads. Check: lag is a metric with an alert and the router uses it.
9. Added judgment: **Use a single leader unless you have written a reason for more.** Multi-region writes or offline clients may be that reason; the cost is conflict resolution. Check: any multi-leader design has the reason and the resolution policy in the same document.
10. Added judgment: **For monotonic reads, keep one user on one replica** (for example by hashing the user id) or carry a position token. Check: a user's two successive reads cannot go back in time.

## Procedure

1. Write the write topology: where writes originate (one place, several regions, devices) and their rate.
2. Choose the replication style that fits and note what you give up.
3. Choose synchronous and asynchronous followers and write the loss window and the availability effect.
4. Write the failover runbook: detection, promotion, client redirection, handling of unreplicated writes, fencing of the old leader.
5. Map read paths to the guarantees they need (`$data-intensive-apps:consistency-contract`) and choose the routing that provides them.
6. For multi-writer designs choose the conflict policy and implement the merge as a pure function that you can test.
7. Test a partition and a failover in a non-production environment and record the observed end state.

## Example

```python
# Before: two regional leaders accept edits to a settings document; the later wall-clock timestamp wins.
# Concurrent edits to different fields silently drop one whole edit, and clock skew can make the older edit look newer.
def merge(local, remote):
    return remote if remote["updated_at"] > local["updated_at"] else local

# After: the conflict policy is explicit and deterministic: per-field last writer wins on a logical stamp
# (counter, replica_id). Each replica sets counter = max(counter it has seen) + 1 when it writes a field.
from typing import Dict, Tuple

Stamp = Tuple[int, str]
Field = Tuple[Stamp, object]                      # (stamp, value)

def merge(a: Dict[str, Field], b: Dict[str, Field]) -> Dict[str, Field]:
    out = dict(a)
    for name, (stamp_b, value_b) in b.items():
        current = out.get(name)
        if current is None or stamp_b > current[0]:
            out[name] = (stamp_b, value_b)
    return out
# merge(a, b) == merge(b, a), and merging the same input again changes nothing, so replicas converge in any
# delivery order. Two concurrent edits of the SAME field still lose one; that loss is the stated policy.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Quorum means fresh | `w + r > n` used as a proof of linearizable reads | List the failure cases; use stronger mechanisms where needed |
| Wall-clock last writer wins | Replica merge by `updated_at` from different machines | Logical stamps or version vectors, or a single leader |
| Failover without fencing | A promotion procedure that ignores the old leader | Fence the old leader (`$data-intensive-apps:faults-and-coordination`) |
| Read from any replica | A router with no lag awareness | Lag threshold, positions or leader reads |
| Multi-leader by convenience | Several writable regions with no conflict policy | Single leader, or write the policy and test the merge |

## Trade-offs and exceptions

- Synchronous replication to every follower makes the slowest or failed follower stop writes; a common compromise is one synchronous follower with the rest asynchronous. That is Added judgment; choose by the loss window the product accepts.
- Leaderless designs favor availability and push conflict handling and read repair into the application and operations.
- Replication copies bad writes as faithfully as good ones; it is not a backup and not a substitute for repair paths (`$data-intensive-apps:derived-data`).
- Asynchronous replication may lose recent writes on leader failure. That is acceptable when the window is stated and agreed.

## Verification

- [ ] The choice of topology names write topology, failure tolerance, latency and conflict handling.
- [ ] Synchronous versus asynchronous followers and the loss window are stated.
- [ ] A failover runbook names promotion, client redirection, unreplicated writes and fencing.
- [ ] Each read path maps to a guarantee and a mechanism.
- [ ] Any quorum claim lists the failure cases it does not cover.
- [ ] Every concurrently written entity has a conflict policy with a test of the merge.

## Related

`$data-intensive-apps:consistency-contract` for the promise; `$data-intensive-apps:faults-and-coordination` for fencing and leases; `$data-intensive-apps:partitioning-locality` for placement; `$data-intensive-apps:write-acknowledgment` for ack levels; `data-intensive-apps-replication-reviewer` to review a diff.

## Source

- `Replication Rules`
