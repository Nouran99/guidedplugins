---
name: "code-complete-performance-tuning"
description: "Use when asked to optimize or speed up, or when a change trades clarity for speed. Needs a requirement and before/after numbers. No speed goal: code-complete-refactoring-judgment or code-complete-complexity-management."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Performance tuning

The gate in front of every optimization: is there a requirement, is there evidence it is missed, and will the result be measured and kept readable? The measured loop itself is `code-complete-tune`; auditing someone else's tuning change is `code-complete-tuning-reviewer`.

## When to use

- A request says "make this faster", "reduce memory" or "optimize".
- A diff contains an optimization: caching, manual loop unrolling, a different data structure chosen for speed, inlining by hand.
- A change makes code harder to read and the reason given is performance.
- Someone proposes a rewrite for speed.

## Rules

1. **Do not tune performance until the requirement and evidence justify it.** Why: unmeasured optimization adds complexity for a benefit nobody has seen. Check: a stated requirement (latency, throughput, memory, cost) exists, and a measurement shows it is not met.
2. **When tuning is justified, measure before and after.** Check: the same workload and the same method produce a baseline number and a result number, recorded.
3. **Keep clarity unless the trade-off is explicit.** Check: if the faster version is harder to read, the code or the change description says what was gained (numbers), what was lost, and why it was worth it.
4. **Compact rule: set a target, measure current behavior, change one thing, remeasure, and document any clarity trade-off.** Check: the log shows one change per measurement.
5. **Use profilers and benchmarks to reduce error-prone manual work, not to replace understanding.** Source rule on tools, with the compact qualifier. Added judgment: choose the spot to change from profile data or a benchmark, not from intuition. Check: the change description names the measurement that pointed at the spot.
6. **Do not reach for dense, hard-to-inspect tricks when a plain change meets the requirement.** Source guidance against cleverness over clarity. Check: the optimization is the simplest one that meets the requirement.
7. Added judgment: record the environment with the numbers (data size, machine class, build mode, warm or cold); results from different conditions are not comparable.
8. Added judgment: run each measurement more than once and note the spread; one run cannot distinguish a gain from noise.
9. Added judgment: look first for the fix that removes work (a better algorithm, a data structure with the right lookup cost, fewer round trips) before micro-adjusting; measurements usually show where the cost lives.
10. Added judgment: run the tests after every tuning change; speed is worthless if behavior changed.
11. Added judgment: if a tuning step did not help by the measurement, revert it. Leftover non-improvements are pure complexity.
12. Added judgment: when you cannot measure (no benchmark, no representative data), say so. Do not claim a speedup you did not observe.

## Procedure

1. Ask for or find the requirement. If there is none, stop and report that no tuning is justified yet.
2. Find or define how to measure it (existing benchmark, timing around the call, production metric). Do not install tools.
3. Take the baseline; repeat to see the spread.
4. Run the loop of rule 4 once per change: locate the cost with a profile or targeted timing, make one change, run the tests, remeasure under the same conditions, keep the change if the number moved toward the target and revert it otherwise (rules 5, 10 and 11). Stop when the target is met. `code-complete-tune` runs this loop with a written log.
5. Document the trade-off where a future reader will find it.

## Example

```python
# Before: requirement "catalogue page p95 < 200 ms"; hypothetical measurement 640 ms on a 50k-order replay.
# Profile: most of the time is the membership test below, a linear scan per order.
def blocked_orders(orders, blocked_ids: list[str]):
    return [o for o in orders if o.customer_id in blocked_ids]

# After: one change (list -> set), same replay, remeasured at about 90 ms (hypothetical numbers for illustration)
def blocked_orders(orders, blocked_ids: list[str]):
    blocked = set(blocked_ids)
    return [o for o in orders if o.customer_id in blocked]
```

The change description records the requirement, the baseline, the result, the workload and the single change. The set conversion costs a pass over `blocked_ids`; that is worth it here because the profile showed the scan dominated.

## Anti-patterns

- **Optimization by hunch.** Changes made because something "looks slow". Detect: no profile or timing in the change description.
- **Many changes at once.** Caching, batching and a new structure in one diff. Detect: you cannot say which change produced the gain.
- **Unmeasured claim.** "About twice as fast." Detect: no numbers, no workload.
- **Clarity sacrificed silently.** Hand-unrolled loops or bit tricks with no comment on the gain. Detect: dense code where the diff description says only "perf".
- **Leftover attempt.** A tuning step that did not help stays in the code. Detect: a before and after that are within noise.
- **Wrong target.** Optimizing a path that is not on the critical path. Detect: the profile shows the routine is a small share of the cost.

## Trade-offs and exceptions

- The source allows giving up some clarity when the trade-off is explicit and measured. It does not allow it by default.
- Added judgment: some requirements are known in advance (a real-time deadline, a hard memory limit). Then a design chosen for performance up front is justified only because the requirement is written down; record it. Rule 1 is not waived, it is already satisfied.
- Added judgment: an obviously quadratic scan on large input is a strong candidate for tuning, but it is still a candidate. Record the requirement it threatens and measure before and after; "obviously slow" is a reason to look first, not a replacement for the numbers.
- Measurements in tests or CI can be noisy; prefer relative comparisons under identical conditions.

## Verification

- [ ] A requirement and a baseline measurement exist.
- [ ] The tuning log shows one change per remeasurement.
- [ ] The result is measured under the same conditions as the baseline.
- [ ] Tests passed after each change.
- [ ] The clarity trade-off, if any, is stated with the numbers.
- [ ] Changes that did not help were reverted.

## Related

`code-complete-tune` to run the loop; `code-complete-tuning-reviewer` to audit the evidence; `code-complete-complexity-management` when speed code is becoming hard to read; `code-complete-refactoring-judgment` for restructuring with no speed goal.

## Source

- `Performance, Integration, Tools, and Craftsmanship`
- `Cleverness over Clarity`
