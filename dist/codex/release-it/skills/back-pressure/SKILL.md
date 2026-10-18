---
name: "back-pressure"
description: "Use when an endpoint, consumer or job accepts work and nothing says what happens at overload, or when adding rate limits, concurrency caps, rejection, load shedding or reserved capacity, or limiting abusive or malformed traffic. The contents and monitoring of a buffer are `$release-it:queues`."
---

# Back pressure, demand control and load shedding

Decide, at the door, what the system does when more work arrives than it can finish. The goal is to keep the core service alive by refusing, deferring or dropping on purpose. What a queue stores and how it is watched is `$release-it:queues`; limits on one resource inside the process are `$release-it:resource-budgets`.

## When to use

- A new endpoint, consumer, webhook receiver or batch trigger accepts work with no stated ceiling.
- Latency climbs under load and everything slows together instead of some requests being refused.
- You are adding a rate limit, a concurrency cap, a 429 or 503 path, a priority lane or a feature kill switch.
- Abusive clients, scrapers, malformed or oversized requests are part of the traffic.

## Rules

1. **Have a strategy for overload.** [MUST] Without one, the strategy is whichever component falls over first. Check: for each entry point, one sentence states what happens at twice the expected load.
2. **Reject, defer, queue or degrade intentionally.** [MUST] Check: the chosen response is coded (a status and body, a deferral, a bounded queue, a reduced response), not left as a side effect of timeouts.
3. **Never accept unbounded work.** [MUST NOT] Unbounded acceptance is forbidden, including accepting work forever while falling behind. Check: each accepting component has a concurrency or rate limit and a bounded backlog.
4. **Prefer early rejection to total collapse.** [SHOULD] Reject at the cheapest point, before parsing large bodies, taking a connection or calling a downstream. Check: the limit check runs before the expensive work in the request path.
5. **Protect scarce resources with limits.** [MUST] Check: concurrent requests, concurrent expensive operations and per-client rates each have a cap.
6. **Reserve capacity for critical traffic when appropriate.** [MUST, source qualifier: when appropriate] A flood of low-value requests must not use up checkout, login or health traffic. Check: critical flows have reserved slots or a separate lane.
7. **Define which work is optional under stress, and shed low-value work first.** [MUST] Check: the list of sheddable features exists, its order is in code or configuration, and the core functions are not on it.
8. **Do not let best-effort tasks crowd out critical work.** [MUST NOT] Check: background, analytics and prefetch work run in their own capacity or pause under load.
9. **Treat hostile traffic, abusive users and malformed requests as load cases.** [MUST] Check: limits are keyed by client identity as well as global, body and parameter sizes are capped, and cheap validation runs first.
10. **Tell the caller what happened.** [Added judgment, following the contract rules] A rejection should be fast, small and carry a retry hint, distinguishing "try again shortly" from "do not retry". Check: overload responses use a retryable status with a hint, and clients that receive them back off (`$release-it:retries`).
11. **Count each accepted request by what it triggers.** [Added judgment] One request that fans out to ten internal calls is ten units of demand. Check: limits sit at the point where the amplified work happens, not only at the edge.
12. **Make rejection and shedding visible.** [MUST, saturation and queue signals are in the minimum metrics] Check: rejected, shed and in-flight counts exist per lane (`$release-it:metrics`).

## Procedure

1. List the entry points and consumers the change adds or modifies.
2. For each, write the overload answer: limit, response when over the limit, who is protected, what is shed first.
3. Place the check as early as the information allows.
4. Add per-client or per-tenant limits where the caller can be hostile or careless.
5. Add the metrics, then test at saturation (`$release-it:resilience-testing`).

## Example

```ts
// Before: every request is accepted, so at saturation every request is slow, including checkout.
app.post("/reports", async (req, res) => res.json(await buildReport(req.body)));

// After: a concurrency ceiling at the door, with slots reserved for the critical routes.
const TOTAL_SLOTS = 200;            // example numbers; real ones come from measured capacity
const RESERVED_FOR_CRITICAL = 40;
let inFlight = 0;

// Register the limiter before the routes it protects: Express runs middleware in registration order,
// so a limiter added after app.post("/reports", ...) never sees that route.
app.use((req, res, next) => {
  const critical = req.path.startsWith("/checkout") || req.path.startsWith("/payments");
  const ceiling = critical ? TOTAL_SLOTS : TOTAL_SLOTS - RESERVED_FOR_CRITICAL;
  if (inFlight >= ceiling) {
    metrics.increment("requests_rejected_overload", { critical: String(critical) });
    res.set("Retry-After", "2").status(503).json({ error: "overloaded", retryable: true });
    return;
  }
  inFlight += 1;
  res.once("close", () => { inFlight -= 1; });
  next();
});

app.post("/reports", async (req, res) => res.json(await buildReport(req.body)));  // now behind the ceiling
```

Non-critical routes are refused once 160 requests are in flight, while the critical routes can still use up to all 200 slots.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Unbounded acceptance | No concurrency limit, rate limit or backlog bound on an entry point | Add a ceiling and a rejection path |
| Timeouts as the only strategy | Overload handled only by calls eventually failing | Explicit rejection before work starts |
| Rejection after expensive work | The limit check sits after parsing, authentication lookups or downstream calls | Move the check earlier |
| Global limit only | One client can use all slots | Per-client or per-tenant limits as well |
| Best-effort work shares capacity | Prefetch, analytics or exports on the request pool | Separate lane that yields under load |
| Silent shedding | Work dropped with no counter or log | Count and expose |

## Trade-offs and exceptions

- Refusing a request is a visible failure. The source prefers it to collapse, but a service with ample headroom and trusted callers needs only a coarse ceiling.
- Reserved capacity strands slots when critical traffic is low. The source says "when appropriate"; reserve only for flows that must survive.
- Per-client limits can block many legitimate users behind one address; key by authenticated identity where you can (Added judgment).
- Queueing is a legitimate overload response only if the queue is bounded and aged; see `$release-it:queues`.

## Verification

- [ ] Every entry point has a stated overload response.
- [ ] No component accepts work without a limit and a bounded backlog.
- [ ] Limits are checked before expensive work.
- [ ] Critical flows keep capacity when optional work is shed.
- [ ] Rejections carry a retry hint and are counted.

## Related

`$release-it:queues` for the buffer; `$release-it:resource-budgets` for resources inside the process; `$release-it:bulkheads` for outbound partitions; `$release-it:api-contracts` for how rejections are documented; `release-it-overload-reviewer` to review a diff; `release-it-overload-hardener` to apply the change.

## Source

- `Back Pressure`
- `Demand Control`
- `Load Shedding`
- `Load and Capacity Rules`: only the anti-patterns on unbounded queues, accepting work with no plan to finish it, and best-effort tasks crowding out critical work.
- `Collapse by Queue`: only the rule against taking work forever while falling behind.
- `Interconnect, Routing, Security, and Chaos Rules`: only the rule to treat hostile traffic, abusive users and malformed requests as production load cases.
