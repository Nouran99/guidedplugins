---
name: "release-it-circuit-breakers"
description: "Use when a dependency can fail slowly or for long and callers keep hammering it, when adding a breaker, fast-fail path, fallback or degraded mode, or when a fallback is silent. Reacts to observed dependency health; partitioning is `release-it-bulkheads`, precondition checks are `release-it-stability-patterns`."
license: "MIT"
metadata:
  plugin: "release-it"
  book: "Release It!"
  invocation: "auto"
---

# Circuit breakers, fast failure and degraded modes

A breaker stops callers from queuing behind a dependency that is clearly unhealthy, protects that dependency from further load, and turns a slow failure into a fast, explicit one. It does not set the wait for one call (`release-it-timeouts`), repeat calls (`release-it-retries`), or partition capacity in advance (`release-it-bulkheads`).

## When to use

- A remote dependency fails by being slow or partly down, and request threads pile up behind it.
- You are adding a breaker, a fast-fail path, a fallback value, a cached answer, or a "feature unavailable" mode.
- A fallback exists but nothing tells callers, operators or users that it is active.
- Retries keep arriving at a dependency that is plainly down.

## Rules

1. **Protect unstable dependencies with a fast-fail mechanism when appropriate.** [MUST, source qualifier: when appropriate] A call that is certain to wait for its full timeout is expensive for the caller too. Check: remote, shared dependencies with a history of slow failure have a breaker or an equivalent fast-fail check.
2. **When a dependency is clearly unhealthy, stop flooding it.** [MUST] Sending traffic to a struggling service prevents its recovery. Check: while the breaker is open, a counter at the dependency's side (or in a test) shows no calls from this caller.
3. **Surface fallback or degraded mode explicitly.** [MUST] A silent fallback hides an outage from users and operators. Check: the response carries a degraded flag or equivalent, the transition is logged, and a metric records time spent degraded.
4. **Count slow calls as failures.** [Added judgment] Slow responses are the usual way dependencies fail, and a breaker that only counts exceptions never opens. Check: the trip condition includes calls that exceeded their limit.
5. **Define trip, hold and probe behavior.** [Added judgment] State what trips it (consecutive failures or failure rate over a window), how long it stays open, and how recovery is tested (a single probe, then close on success). Check: the three values are named and configurable, and only one probe is in flight at a time.
6. **Choose honest fallbacks.** [Added judgment] A fallback is an empty result with a flag, a clearly labelled stale value, work queued for later, or an error. Check: the fallback never invents data and never calls another unprotected dependency.
7. **Expose breaker state.** [MUST, the source lists breaker state among the minimum metrics] Check: state, transitions and short-circuited call counts exist as metrics (`release-it-metrics`).
8. **Treat degraded mode as something that can last for hours.** [Added judgment, from the rule that temporary degraded states become normal] Check: someone is alerted when degraded time exceeds a stated period, and the degraded path is exercised in tests.
9. **Keep non-health errors out of the trip count.** [Added judgment] Validation failures and not-found responses say nothing about dependency health. Check: only timeouts, connection failures and server-side errors count.
10. **Keep the core service alive.** [SHOULD, source: prefer designs that preserve core service under stress] Check: with the breaker open, the main flow still completes using the degraded result.
11. **Make the fallback cost less than the call it replaces.** [Added judgment] A fallback as expensive as the failing call moves the load instead of shedding it. Check: the fallback is local or cached, makes no remote call and does no heavy computation.

## Procedure

1. Name the dependency and what the caller can still do without it.
2. Decide the fallback (rule 6) and the signal that tells the caller it is in use (rule 3).
3. Choose the trip condition, hold time and probe policy; keep them in configuration.
4. Wrap the call so the order is: breaker outside, timeout inside, retries (if any) outside the breaker but treating "open" as non-retryable now. This layering is Added judgment; the source asks for timeouts, disciplined retries and fast failure but does not prescribe how they nest.
5. Emit state, transitions and fallback counts.
6. Test: dependency slow, dependency down, dependency recovering, concurrent callers during the probe.

## Example

```ts
type Result<T> = { value: T; degraded: boolean };

// Timeouts, connection failures and 5xx say something about the dependency; a 4xx or a not-found does not.
function isHealthFailure(err: unknown): boolean {
  if (err instanceof HttpError) return err.status >= 500;
  return err instanceof TimeoutError || err instanceof ConnectionError;
}

class Breaker {
  private failures = 0;
  private openUntil = 0;
  private probing = false;

  constructor(
    private readonly maxFailures: number,
    private readonly openMs: number,
    private readonly now: () => number = Date.now,
  ) {}

  async run<T>(op: () => Promise<T>, fallback: () => T): Promise<Result<T>> {
    if (this.now() < this.openUntil) return { value: fallback(), degraded: true }; // open: no call is made
    const halfOpen = this.failures >= this.maxFailures;
    if (halfOpen) {
      if (this.probing) return { value: fallback(), degraded: true }; // one probe at a time
      this.probing = true;
    }
    try {
      const value = await op();
      this.failures = 0;
      return { value, degraded: false };
    } catch (err) {
      if (!isHealthFailure(err)) throw err;                          // the caller's error: not counted, no fallback
      this.failures += 1;
      if (this.failures >= this.maxFailures) this.openUntil = this.now() + this.openMs;
      return { value: fallback(), degraded: true };
    } finally {
      if (halfOpen) this.probing = false;
    }
  }
}

// Before: the product page awaits fetchRecommendations with no limit and no fallback.
// After: a slow recommender costs at most 800 ms, then fails fast, and the page says so.
const recommender = new Breaker(5, 10_000);
const { value, degraded } = await recommender.run(
  () => fetchRecommendations(userId, { signal: AbortSignal.timeout(800) }),
  () => [] as Recommendation[],
);
page.recommendations = { items: value, unavailable: degraded };
```

`HttpError`, `TimeoutError`, `ConnectionError` and `fetchRecommendations` stand for the project's own client types; the point is that only health signals move the failure count.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Silent fallback | `catch { return [] }` with no flag, log or metric | Return a degraded marker; count it |
| Fallback calls another fragile service | The fallback path makes a remote call without its own limit | Local or cached fallback, or an error |
| Breaker that never probes | Open state with no timer or probe, restart required to close | Hold time and single probe |
| Breaker counts everything | 4xx validation errors trip it | Count only health signals |
| Retry on breaker-open | A retry loop around a call that fails instantly with "open" | Treat open as non-retryable now |
| Invisible state | No metric or log for open and close | Emit transitions and short-circuit counts |

## Trade-offs and exceptions

- The source scopes breakers to "when appropriate". For a low-traffic dependency, or one where no honest fallback exists, a timeout plus a clear error may be enough, and a breaker adds state you must tune and watch.
- A per-process breaker needs enough traffic to learn anything; many instances each trip independently (Added judgment).
- A degraded mode that is entirely invisible to users can be correct for optional features, but it must still be visible to operators.
- Fast-failing on a missing precondition or scarce resource is the Fail Fast pattern in `release-it-stability-patterns`, not a breaker.

## Verification

- [ ] The breaker opens on slow calls as well as on errors.
- [ ] No calls reach the dependency while it is open.
- [ ] Degraded mode is visible in the response, the logs and a metric.
- [ ] Recovery is probed, and only one probe runs at a time.
- [ ] The fallback does not depend on anything that can fail slowly.

## Related

`release-it-timeouts` for the wait inside the breaker; `release-it-retries` for the layer outside; `release-it-bulkheads` for isolation; `release-it-stability-patterns` for fail fast on preconditions; `release-it-isolation-reviewer` to review a diff.

## Source

- `Circuit Breakers and Fast Failure`
- `Stability Mindset Rules`: only the rule that a temporary degraded state can last for hours.
- `Primary Directive`: only the preference for failing visibly and preserving core service.
- `Metrics`: only the minimum-metrics entry for circuit-breaker state.
