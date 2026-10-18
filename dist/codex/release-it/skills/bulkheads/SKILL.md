---
name: "bulkheads"
description: "Use when workloads or dependencies share a thread pool, connection pool or worker capacity, when one slow integration could starve the rest, or when mapping single points of failure and fan-out. Partitions capacity in advance; stopping calls to a sick dependency is `$release-it:circuit-breakers`."
---

# Bulkheads and isolation

Split shared capacity so that one failing integration or one noisy workload cannot take the whole service with it. Sizing a single resource and releasing it correctly is `$release-it:resource-budgets`; reacting to a dependency that has already turned unhealthy is `$release-it:circuit-breakers`.

## When to use

- One executor, thread pool, connection pool or worker group serves unrelated dependencies or request types.
- A slow third party has previously made unrelated endpoints slow.
- Heavy or risky work (exports, reports, imports, webhooks) runs on the same threads as interactive requests.
- You are drawing or reviewing a topology and need to find shared fate, single points of failure or unbounded fan-out.

## Rules

1. **Give unrelated workloads separate resource pools where failure isolation matters.** [MUST, source qualifier: where isolation matters] Pools are where a failure of one dependency becomes a failure of all. Check: each outbound dependency or risk class has its own pool, semaphore or worker group.
2. **One failing integration must not consume all threads, connections or worker capacity.** [MUST] Check: stall the slowest dependency in a test and confirm an unrelated endpoint still answers within its normal time.
3. **Do not use one shared pool for all outbound work.** [MUST NOT] A single pool is a single point of failure for every caller of it. Check: no global executor, default common pool or single client pool carries unrelated dependencies.
4. **Isolate slow or risky work from core request paths.** [MUST] Check: exports, reports, bulk imports, image processing and third-party webhooks run outside the request-serving pool.
5. **Bound each partition and its queue, and pair it with a timeout.** [Added judgment, following from the rules on queues and timeouts] A bulkhead whose slots are held by stalled calls still fills; a bulkhead with an unbounded queue hides the overflow. Check: each pool has a fixed size, a bounded queue, a rejection behavior, and calls inside it have time limits.
6. **Partition by failure behavior, not by package.** [Added judgment] Group dependencies by criticality and by how they fail, so critical flows get their own capacity. Check: the checkout path does not share a partition with recommendations or analytics.
7. **Design interconnects to avoid hidden single points of failure.** [MUST] Shared fate hides in shared database pools, a single-thread executor or event loop, a single instance of a dependency, shared DNS or discovery, shared quota and shared disk. Check: for each box in the topology, write what happens to the others when it is slow and when it is gone.
8. **Do not allow uncontrolled fan-out.** [MUST NOT] A request that calls N downstreams multiplies load by N, and a loop that calls a service per item multiplies it again. Check: parallelism and calls per request have a cap, and per-item calls use a batch operation or a bounded window.
9. **Make partition saturation visible.** [MUST, the source lists saturation signals] Check: in-use, queued and rejected counts exist per partition (`$release-it:metrics`).
10. **Escalate to separate processes when threads are not enough.** [Added judgment] Work that can exhaust memory, crash the process or leak file descriptors needs a process or instance boundary. Check: such work does not run inside the process that serves critical traffic.

## Procedure

1. Inventory shared pools, executors, client connections and event loops used by the changed code.
2. For each, list the workloads sharing it and which one is the slowest or least trusted.
3. Split by failure behavior (rule 6), size each partition, bound its queue, choose the rejection response.
4. Add per-call limits inside each partition.
5. Draw the shared-fate map: resource, who shares it, effect of its slowness, effect of its absence.
6. Test with one dependency stalled and confirm the others are unaffected.

## Example

```java
// Before: one pool for every outbound call. Executors.newFixedThreadPool also uses an unbounded queue,
// so a stalled recommender fills all 64 threads and then the queue, and payments wait behind it.
private final ExecutorService outbound = Executors.newFixedThreadPool(64);

// After: one small pool per dependency, a bounded queue each, and rejection instead of waiting forever.
private static ExecutorService pool(String name, int threads, int queueSize) {
    AtomicInteger n = new AtomicInteger();
    return new ThreadPoolExecutor(threads, threads, 0L, TimeUnit.MILLISECONDS,
        new ArrayBlockingQueue<>(queueSize),
        r -> new Thread(r, name + "-" + n.incrementAndGet()),
        new ThreadPoolExecutor.AbortPolicy());
}

private final ExecutorService payments = pool("payments", 16, 32);
private final ExecutorService recommendationsPool = pool("recommendations", 4, 8);

public Recommendations recommend(String userId) {
    try {
        return CompletableFuture
            .supplyAsync(() -> recommender.fetch(userId), recommendationsPool) // fetch carries its own timeout
            .orTimeout(800, TimeUnit.MILLISECONDS)                             // does not stop a running task
            .join();
    } catch (RejectedExecutionException saturated) {
        return Recommendations.unavailable("recommendations pool saturated");
    } catch (CompletionException failed) {
        return Recommendations.unavailable("recommendations failed: " + failed.getCause());
    }
}
```

The pool sizes are examples. Real values come from each dependency's measured concurrency and the service's thread budget.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| One pool for all outbound work | A single `ExecutorService`, `ThreadPool`, `HttpClient` or connection pool injected everywhere | Pool per dependency or risk class |
| Unbounded executor queue | `newFixedThreadPool`, `newCachedThreadPool`, `LinkedBlockingQueue()` with no capacity | Bounded queue and rejection policy |
| Blocking I/O on a shared default pool | `parallelStream()` or `supplyAsync` without an executor around remote calls | Dedicated executor |
| Heavy work on request threads | Export or report generation inside a controller | Move to a separate pool, queue or process |
| Per-item remote calls | A loop calling a service once per element | Batch call or capped parallel window |
| Hidden shared fate | One database pool behind every feature, one instance of a critical dependency | Separate pools, replicas, or an explicit accepted risk |

## Trade-offs and exceptions

- Partitions strand capacity: one pool can sit idle while another is saturated. The source applies isolation "where failure isolation matters", so do not split a service whose dependencies fail together.
- In small services a semaphore per dependency is cheaper than a thread pool per dependency (Added judgment).
- Too many tiny pools make tuning and monitoring harder; group dependencies with the same criticality and failure pattern.
- Reserving capacity for critical traffic at the entry point is `$release-it:back-pressure`; this skill covers outbound and internal partitions.

## Verification

- [ ] No single pool carries unrelated dependencies.
- [ ] Every partition has a fixed size, a bounded queue and a rejection path.
- [ ] Heavy or risky work is off the request path.
- [ ] A test with one dependency stalled leaves unrelated endpoints healthy.
- [ ] Saturation of each partition is observable.
- [ ] Fan-out per request is capped.

## Related

`$release-it:circuit-breakers` to stop calls to an unhealthy dependency; `$release-it:resource-budgets` for sizing and release; `$release-it:queues` for the buffers; `$release-it:back-pressure` for the entry point; `release-it-isolation-reviewer` to review a diff.

## Source

- `Bulkheads and Isolation`
- `Blast-Radius Amplification`
- `Dependency Protection Rules`: only the anti-pattern of one shared pool for all outbound work.
- `Interconnect, Routing, Security, and Chaos Rules`: only the rule on hidden single points of failure and uncontrolled fan-out.
