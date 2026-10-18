---
name: "caching"
description: "Use when adding or changing a cache, memoization, CDN rule or read-through store, or when a cache miss, expiry or outage would send load to the source of truth. Covers miss storms, stale data, outage behavior, dogpiles. Demand limits in general are `$release-it:back-pressure`."
---

# Caching under failure

A cache hides load until the moment it cannot. Plan for the cold cache, the stale entry, the unavailable cache and the many callers that miss the same key together. Limiting demand in general is `$release-it:back-pressure`; checking what you store is `$release-it:data-boundaries`.

## When to use

- A cache, memoized function, edge rule or read-through store is added, resized or re-keyed.
- A deploy, flush, failover or expiry could empty the cache and send the full read load to the source.
- Correctness (prices, permissions, inventory) is said to be "fine because the cache is fresh enough".
- The cache is a remote dependency (Redis, Memcached, a CDN) with no stated behavior for when it is down.

## Rules

1. **Treat the cache as an optimization, not a source of truth, unless it is explicitly designed to be one.** [MUST] Check: every read has a path to the real source, and losing the cache costs speed, not data.
2. **Plan for miss storms.** [MUST] Check: write down what the source sees if every key misses at once (cold start, flush, deployment, key-space change) and whether it can carry that.
3. **Plan for stale data.** [MUST] Check: each cache has a stated maximum age, a reason that age is acceptable to its users, and an invalidation path for the cases where it is not.
4. **Plan for cache outages and define what happens when the cache is unavailable.** [MUST] Options are going to the source with limits, serving stale, or failing. Check: the choice is made, tested, and the cache calls have time limits like any other remote dependency (`$release-it:timeouts`).
5. **Avoid dogpiles with request coalescing or appropriate expiry strategies.** [MUST NOT dogpile] Check: concurrent misses for one key trigger one load, and expiries are jittered or refreshed ahead of time.
6. **Do not assume the hit rate is always high.** [MUST NOT] Check: capacity for the source is sized for, or protected against, a low hit rate, for example by load shedding.
7. **Do not rebuild the whole cache synchronously on a miss.** [MUST NOT] Check: a miss loads one key or one bounded unit, never a table or a full index.
8. **Do not hide correctness assumptions inside cache behavior.** [MUST NOT] Check: business correctness that depends on freshness is documented and tested, not implied by a TTL.
9. **Do not cache failures or unvalidated data.** [Added judgment, linking to the boundary rules] Negative caching is a deliberate choice with a short lifetime. Check: errors and malformed responses never reach `set`.
10. **Bound the cache.** [Added judgment, following from steady state and resource budgets] Check: size and eviction are configured, and per-entry size is capped.
11. **Cap source load when the cache is down.** [Added judgment] Failing open to the source can turn a cache outage into a source outage. Check: concurrent loads against the source have a ceiling and excess is shed or served stale.
12. **Measure the cache.** [Added judgment, linking to metrics] Check: hit and miss rates, load latency, evictions and outage counts are visible.

## Procedure

1. List caches and memoization in the change, with what they protect and what the source can carry.
2. For each, write the miss, stale, outage and stampede behavior.
3. Add coalescing for hot keys and jitter to expiries.
4. Put time limits and a breaker on remote cache calls.
5. Add a ceiling on source load for the fail-open path.
6. Test with an empty cache, an unavailable cache and a thundering herd on one key.

## Example

```python
import random
import threading
from concurrent.futures import Future

_inflight: dict[str, Future] = {}
_lock = threading.Lock()


# Before: every miss queries the database. A flush or deploy sends the whole read load to it at once,
# and a cache outage surfaces as an exception to the user.
def get_profile(user_id):
    cached = cache.get(f"profile:{user_id}")
    if cached is not None:
        return cached
    profile = db.load_profile(user_id)
    cache.set(f"profile:{user_id}", profile, ttl=300)
    return profile


# After: one loader per key, jittered expiry, and a defined answer when the cache is down.
def get_profile(user_id):
    key = f"profile:{user_id}"
    try:
        cached = cache.get(key)
    except CacheUnavailable:
        cached = None
        metrics.incr("cache.unavailable")          # defined behavior: fall through to the source
    if cached is not None:
        return cached

    with _lock:
        pending = _inflight.get(key)
        leader = pending is None
        if leader:
            pending = _inflight[key] = Future()
    if not leader:
        return pending.result(timeout=1.0)          # followers wait for the one loader instead of stampeding

    try:
        profile = db.load_profile(user_id)
        try:
            cache.set(key, profile, ttl=300 + random.uniform(0, 60))   # jitter spreads expiries
        except CacheUnavailable:
            pass
        pending.set_result(profile)
        return profile
    except Exception as exc:
        pending.set_exception(exc)
        raise
    finally:
        with _lock:
            _inflight.pop(key, None)
```

This coalesces within one process. Across many instances each still loads once per key; a ceiling on concurrent source loads (rule 11) is a separate guard.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Hidden source of truth | Code that reads only the cache, with no fallback | Real source path, or design it as a store |
| Synchronized expiry | The same TTL set on every key at deploy time | Jitter or refresh-ahead |
| Full rebuild on miss | A miss that reloads a table or index | Load one key |
| No outage behavior | Cache calls with no timeout, exception reaching users | Defined fallback, limits, breaker |
| Stampede | Many concurrent loads for one key | Coalesce |
| Correctness by TTL | Permissions or prices valid "because it was recent" | Explicit freshness rule and tests |
| Caching errors | `set` after a failed or malformed load | Validate first |

## Trade-offs and exceptions

- Serving stale during a source outage trades freshness for availability. It is right for catalogs and wrong for balances; decide per cache.
- Coalescing makes followers wait on the leader; give them a time limit.
- A cache designed as the source of truth (a session store, a materialized view) needs the durability and consistency treatment of a database, which belongs to a data-systems plugin such as `data-intensive-apps`.
- The source asks for plans, not particular techniques; refresh-ahead, stale-while-revalidate and coalescing are interchangeable if the miss, stale and outage cases are answered.

## Verification

- [ ] Every read can reach the real source.
- [ ] The behavior with an empty cache is written down and fits the source's capacity.
- [ ] A cache outage has a defined, tested behavior and a time limit on cache calls.
- [ ] Concurrent misses on one key cause one load.
- [ ] Staleness bounds are stated and acceptable.
- [ ] Failures and invalid data are never cached.

## Related

`$release-it:back-pressure` for ceilings on source load; `$release-it:timeouts` and `$release-it:circuit-breakers` for the cache as a dependency; `$release-it:data-boundaries` for what may be stored; `$release-it:stability-patterns` for bounded growth; `release-it-cache-reviewer` to review a diff.

## Source

- `Cache Rules`
