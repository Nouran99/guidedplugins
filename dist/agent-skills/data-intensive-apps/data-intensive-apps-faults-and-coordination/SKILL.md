---
name: "data-intensive-apps-faults-and-coordination"
description: "Use when code relies on timeouts, wall-clock timestamps, locks, leases, leader election, majority votes, coordination services or consensus, or claims linearizability. Requires a fault model, monotonic clocks and fencing. Failover and replica data are replication-topology."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Faults, clocks and coordination

Writes down which faults the design tolerates, which clocks it may trust for what, and what a lock, lease or leader is worth when its holder is slow rather than dead. Ack levels and recovery of one write are `data-intensive-apps-write-acknowledgment`; data copies and failover are `data-intensive-apps-replication-topology`; atomicity of a transaction is `data-intensive-apps-transactions-and-isolation`.

## When to use

- Code measures a duration with the system clock, or compares timestamps from different machines to decide who wins.
- A lock, lease, leader election or "only one worker at a time" mechanism is added, with a TTL.
- A design depends on a coordination service (for locks, membership, configuration, leader election).
- A document claims linearizability, a global order, atomic commit or consensus, or asks for it.
- A timeout is treated as proof that the other side did not do the work, or that it is down.

## Rules

1. **Expect network delay, lost packets, partitions, duplicate messages and arbitrary process pauses as ordinary conditions of a distributed system.** A process can stop for seconds (garbage collection, a stalled virtual machine) without knowing. Check: the design lists the faults it tolerates and the ones it does not.
2. **Do not conclude that a remote call failed or succeeded merely because it timed out.** Silence has several causes. Check: a timeout leads to an unknown state with a way to resolve it (`data-intensive-apps-write-acknowledgment`).
3. **Measure elapsed time with monotonic clocks, and do not order events by wall-clock readings unless the assumptions about those clocks are stated and safe.** The wall clock can jump when it is corrected. Check: durations come from a monotonic source, and no code decides the winner of two events by comparing wall-clock times from different machines without a stated bound.
4. **Do not let correctness depend on synchronized clocks unless the design states the clock error it tolerates and what happens when that bound fails.** Check: any design that needs synchronized clocks states the maximum error and what happens when it is exceeded.
5. **Regard majority votes, leases, locks and leadership as assumptions, and give each a fault model.** A holder may believe it still holds a lease after it expired. Check: for each, you can say what happens when the holder is paused or partitioned and then resumes.
6. **Reserve linearizability for operations that truly need one current value, and only where its price in availability and latency is acceptable.** Check: each linearizable operation has the product reason that needs it.
7. **Reach for total order broadcast, atomic commit or consensus only if the coordination problem cannot be solved without it.** Check: you can say why a weaker mechanism (per-key order, idempotency, a conditional write) is not enough.
8. **Name every membership and coordination-service dependency in the design; the system relies on them as much as on its own code.** Check: the coordination service is in the architecture diagram with what depends on it and the behavior when it is unreachable.
9. **Define stale-authority behavior and fencing.** Compact rule. When a lock or lease holder can act after it expired, the resource it writes to must reject its writes, for example by checking an increasing token issued with each grant. Check: the protected resource, not the holder, enforces the token.
10. **Define quorum and session semantics for coordination services.** Compact rule. Check: you can say what happens to a client's locks and ephemeral state when its session expires or it is partitioned from the quorum.
11. Added judgment: **Treat a lease check as advisory.** Testing "do I still hold the lease" before a step does not make that step atomic with the check; only a fencing check at the resource does. Check: no correctness argument rests on a validity check made before a side effect.

## Procedure

1. List the places where the code reads a clock, sets a timeout, takes a lock or lease, or elects a leader.
2. For each clock use, classify it: elapsed time (use a monotonic clock) or ordering or expiry across machines (needs a stated bound, or replace it with a counter or version).
3. For each timeout, write what the code does while the outcome is unknown.
4. For each lock, lease or leader, write what happens when the holder pauses past the expiry and resumes. If it can still write, add fencing at the resource.
5. For each use of linearizability, atomic commit or consensus, write the requirement that justifies it; where there is none, choose the weaker tool.
6. Add the coordination service and its failure mode to the design document.

## Example

```python
# Before: elapsed time from the wall clock; it jumps when the clock is corrected, so a timeout can fire early or never
start = time.time()
do_work()
if time.time() - start > 30:
    abort()

# After: monotonic clock for durations
start = time.monotonic()
do_work()
if time.monotonic() - start > 30:
    abort()
```

```python
# Before: a lock with a 30 s TTL. The worker stalls for 40 s (long pause), the lock service gives the lock to
# another worker, and the first worker wakes up and still writes.
lease = locks.acquire("report-42", ttl_seconds=30)
data = build_report()
storage.put("report-42", data)

# After: each grant carries an increasing token, and the storage layer, not the worker, refuses stale holders.
lease = locks.acquire("report-42", ttl_seconds=30)          # lease.token grows with every grant
data = build_report()
storage.put_if_token("report-42", data, token=lease.token)

class Storage:
    def put_if_token(self, key, value, token):
        with self._mutex:
            if token < self._highest.get(key, 0):
                raise StaleLeaseError(key, token)           # a newer holder has already written
            self._highest[key] = token
            self._data[key] = value
```

The second change moves the guarantee to the resource that has to be protected. The worker cannot know it was paused.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Timeout means failed | `catch (timeout)` that undoes work or reports failure | Unknown state plus a resolver |
| Wall-clock ordering | `a.timestamp < b.timestamp` between machines decides a winner | Per-entity versions, logical counters, or stated clock bounds |
| Lock without fencing | A TTL lock protecting writes to a store that accepts anything | Token check at the store |
| Leader by TTL, no fence | Two nodes may both act as leader for a moment | Fencing token checked at the resource (the token may come from a consensus-backed store) |
| Consensus for everything | A coordination service on the hot data path | Use it for small metadata; keep data paths local |
| Invisible dependency | Everything stops if the coordination service is down and nobody planned for it | Document and test its failure |

## Trade-offs and exceptions

- Synchronized clocks with bounded, exposed uncertainty can support correctness when the design uses the bound. The rule is that the bound and the failure behavior are part of the design, not that clocks are never used.
- Short leases reduce the time a dead holder blocks others but increase the chance that a live, slow holder loses it. Pick the lease length with the pause tolerance in mind.
- Linearizable reads and writes cost latency and availability under partitions. Use them for the few values that need them (unique allocation, leader identity), not for everything.
- A coordination service is the right tool for small, critical metadata; it is not a database for the data path.

## Verification

- [ ] Durations use a monotonic clock.
- [ ] No cross-machine wall-clock comparison decides a winner without a stated bound.
- [ ] Every lock or lease protecting writes has fencing at the resource.
- [ ] Each timeout has an unknown-outcome path.
- [ ] Each linearizability, atomic commit or consensus requirement has a written justification.
- [ ] The coordination service and its failure behavior are in the design.

## Related

`data-intensive-apps-write-acknowledgment` for unknown outcomes; `data-intensive-apps-replication-topology` for failover and fencing the old leader; `data-intensive-apps-ordering-scope` for versions instead of timestamps; `data-intensive-apps-fault-model-reviewer` to review a diff.

## Source

- `Distributed Fault, Clock, and Consensus Rules`
