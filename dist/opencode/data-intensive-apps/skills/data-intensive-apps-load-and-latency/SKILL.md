---
name: "data-intensive-apps-load-and-latency"
description: "Use when someone claims a design will scale, proposes more nodes, caches or sharding for speed, or reports slowness. Demands load parameters, percentile latency and a named bottleneck first. Skewed keys are partitioning-locality."
license: "MIT"
metadata:
  plugin: "data-intensive-apps"
  book: "Designing Data-Intensive Applications"
  invocation: "auto"
---

# Load, latency and operability

Stops architecture changes that rest on adjectives. Before a design is called scalable, fast or simple, the load is written as numbers, performance is stated in percentiles, and the bottleneck is named. Choosing a partition key or fixing skew is `data-intensive-apps-partitioning-locality`; index and engine fit is `data-intensive-apps-storage-and-indexing`.

## When to use

- A proposal says "this will scale", "we need to shard", "add a cache" or "move to a faster database" with no workload numbers.
- A bug report says "the page is slow" or "the API times out sometimes".
- A benchmark reports an average, or a node count, as the evidence.
- A new component, store or technology is added and nobody has said who will operate it.

## Rules

1. **Before changing the architecture, express the load as concrete, measurable parameters.** Requests per second per endpoint at peak and on average, read/write mix, record sizes, data volume and growth, fan-out per request, number of concurrent clients. Check: the proposal contains numbers with units, not "high traffic".
2. **Report performance as latency, throughput, percentiles and tail behavior, wherever those affect the outcome.** Users feel the slow requests, and averages hide them. Check: each user-facing operation has a median and a high percentile (for example the 99th); an average alone is not accepted as evidence.
3. **Do not argue that a system scales merely because it has many nodes; find the bottleneck, the access pattern and the point of contention.** More nodes only help if the saturated resource scales with them. Check: you can name the saturated resource (CPU, disk, memory, lock, single partition) and the access pattern that saturates it.
4. **Design for operability, simplicity and evolvability from the start, not as afterthoughts.** A system that is fast on day one and opaque on day ninety costs more. Check: for each proposed component, someone can say how it is run, how its health is seen, and how it is changed.
5. **Prefer designs whose behavior in production can be inspected and changed over designs built on clever but opaque mechanisms.** Check: the new path emits the metrics and logs needed to answer "what is it doing right now", and its configuration can be changed without a rewrite.
6. **Avoid complexity the problem does not call for: distribution without a reason, mixing technologies too early, and coupling nobody can see.** Each added store or service is a new failure mode and a new contract. Check: every additional store, queue or service has a written workload reason that the existing ones cannot meet.
7. Added judgment: **Measure tail latency where the user waits, including fan-out.** When one request waits on several backend calls, the slowest call sets the response time, so a backend's 99th percentile shows up in far more than 1 percent of requests. Check: end-to-end percentiles are measured or computed from the call graph.
8. Added judgment: **Re-measure with the same workload after the change.** A change that cannot be compared with a baseline is an opinion. Check: the replayed traffic or load script is recorded next to the before and after numbers.
9. Added judgment: **Write down the load you are not designing for.** "Sized for 10x of today, not 100x" turns a limit into a decision that can be revisited. Check: the design note states the planned headroom and the signal that triggers the next step.

## Procedure

1. Write the workload sheet: operations, rates (peak and average), read/write ratio, data size and growth, fan-out, concurrency.
2. Write the performance targets in percentiles for the operations users wait on, and the current measured values.
3. Find where the time or capacity goes (traces, profiles, resource saturation), not where it is easiest to add hardware.
4. Name the bottleneck and the contention point. If you cannot, the next step is measurement, not a design.
5. Propose the smallest change that moves the bottleneck, and say what you expect to see in the numbers.
6. Apply it, replay the same workload, compare. Record the result.
7. Add the metrics and alerts that would show the same problem next time, then check operability: who runs it, how it is observed, how it is changed.

## Example

```text
Before: "Search is slow. Shard the index over 8 nodes."

After:
  Load        : 400 queries/s at peak, 85% reads; 12 M documents of about 3 KB (36 GB), growing 2% a month.
  Latency now : p50 80 ms, p99 1.9 s for /search?q=; target p99 under 500 ms.
  Bottleneck  : 70% of the time is the "sort by popularity" step, which reads one stored field per hit;
                the working set is 4 GB and the node caches 2 GB. Not CPU, not network.
  Change      : precompute popularity into the index and give the node enough memory to hold it.
  Evidence    : replay last Tuesday's peak hour before and after; compare p50, p99 and cache hit rate.
  Headroom    : the replayed traffic, scaled up, held p99 under 500 ms to about 1,200 queries/s on one node
                (3x today's peak); revisit at 800 queries/s sustained on one node.
  Operability : p99 and cache hit rate on the dashboard with an alert; index rebuild is a documented job.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Adjective load | "high traffic", "large data" with no numbers | Rates, sizes, growth, fan-out |
| Average-only latency | A report whose only latency figure is a mean | Add median and a high percentile per operation |
| Scale by node count | "We will add nodes" with no bottleneck named | Name the saturated resource and the access pattern |
| Unmeasured fix | A change shipped with no before/after on the same workload | Replay the baseline workload |
| Resume-driven infrastructure | A new store or service with no workload argument | State the workload the existing stack cannot meet |

## Trade-offs and exceptions

- Early in a product there is no production data. Estimate from similar systems, state the assumptions, and revisit when real traffic exists; do not skip the sheet.
- For offline jobs the figures that matter are throughput and total run time, not tail latency per request.
- Simplicity can beat headroom. A single well-understood database that handles the load with a margin is a legitimate answer to "how will it scale".
- Percentile targets are product decisions. This skill requires that they exist, not what they are.

## Verification

- [ ] The workload sheet has numbers with units for rate, size, growth and mix.
- [ ] Latency is stated as a median and a high percentile for each user-facing operation.
- [ ] The bottleneck and contention point are named, with evidence.
- [ ] A before and after measurement on the same workload is recorded.
- [ ] Each new component has an owner, a health signal and a way to change it.

## Related

`data-intensive-apps-partitioning-locality` for skew and hot keys; `data-intensive-apps-storage-and-indexing` for engine and index fit; `data-intensive-apps-derived-data` when the proposal is a cache; `data-intensive-apps-capacity-reviewer` to review a claim.

## Source

- `Scalability and Maintainability Rules`
