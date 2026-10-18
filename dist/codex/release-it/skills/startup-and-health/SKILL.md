---
name: "startup-and-health"
description: "Use when a process starts, reads configuration, exposes health or readiness endpoints, registers with a load balancer, or does heavy work at boot. Covers fail-fast startup, truthful health, handshaking. Rerunnable scripts are `$release-it:restartable-automation`; tests of these are `$release-it:resilience-testing`."
---

# Startup, health and readiness

A process has two jobs before it earns traffic: refuse to start on a broken foundation, and then say truthfully whether it can serve. This skill covers the process and its health signals; scripts that operators rerun are `$release-it:restartable-automation`, and the numbers on a dashboard are `$release-it:metrics`.

## When to use

- A service reads configuration, secrets or feature settings at boot.
- A health, liveness or readiness endpoint is added or changed, or a load balancer, orchestrator or discovery registration depends on one.
- Startup runs migrations, cache warm-ups, index builds or other heavy work.
- Traffic reached an instance that was not ready, or an instance that was stuck still looked healthy.

## Rules

1. **Fail startup fast on missing critical configuration.** [MUST] A process that starts with a missing setting fails later, in the middle of a request. Check: required settings are validated before the process opens ports, the error names the setting (never its value) and the exit code is non-zero.
2. **Validate critical configuration at startup.** [MUST] Auditable and reversible configuration changes are the rollout side, in `$release-it:release-risk`. Check: types and ranges are checked (a timeout of zero or a pool larger than the database allows is rejected), and the effective configuration is logged with secrets masked.
3. **Make health checks reflect actual ability to serve.** [MUST] Check: the readiness check exercises the local state and the dependencies a request needs, with its own short time limit.
4. **Do not let health checks mask deadlocks or stuck subsystems.** [MUST NOT] A running process with a dead worker loop is not healthy. Check: critical loops (workers, consumers, schedulers) publish a progress heartbeat that health reads, and a stalled loop flips the result.
5. **Do not ship a health check that is always green.** [MUST NOT] Check: remove a required dependency in a test and the probe result changes.
6. **Use handshaking so traffic reaches only ready components.** [MUST, source: USE Handshaking] Check: an instance reports ready only after configuration, warm-up and dependency connectivity succeed, and the load balancer routes on readiness rather than on an open port.
7. **Keep DNS, service discovery, routing and load balancing health-aware and current.** [MUST] Check: unhealthy and departed instances are removed promptly, cached endpoint lists have bounded lifetimes, and shutdown deregisters before it closes connections.
8. **Avoid expensive or destructive startup work in request-serving processes when possible.** [MUST NOT, source qualifier: when possible] Check: migrations and bulk warm-ups run as separate, observable jobs, or are bounded and do not block readiness for the whole fleet at once.
9. **Separate "should I be restarted" from "should I receive traffic".** [Added judgment] Liveness stays local and cheap, so a database outage does not make an orchestrator restart every healthy process. Readiness may consult dependencies. Check: the liveness probe has no remote calls.
10. **Treat a missing dependency at boot differently from a missing setting.** [Added judgment] A bad configuration should exit; a dependency that is temporarily down should leave the instance not ready and retry with backoff, otherwise a shared outage becomes a crash loop. Check: both behaviors are written and tested.
11. **Do not let readiness take the whole fleet out of rotation for something optional.** [Added judgment, following from preserving the core service] Readiness should depend on what the core path needs. Check: an outage of an optional dependency degrades the feature and leaves readiness green.
12. **Make the health probe itself safe.** [Added judgment] It has a timeout, is cheap, and caches its dependency checks for a few seconds so probes cannot become load. Check: probe cost under the orchestrator's polling rate is known.

## Procedure

1. List what the process needs to start (settings, secrets, files) and what a request needs to be served (dependencies, warmed state, running loops).
2. Validate the first list at boot; write the failing messages.
3. Express the second list as readiness checks with time limits, and add heartbeats for critical loops.
4. Decide which checks are liveness (local only) and which are readiness.
5. Make shutdown stop being ready first, finish in-flight work, then exit.
6. Test: unset a setting, stop a dependency, stall a worker, send traffic during warm-up.

## Example

```go
// Before: always green. The balancer keeps routing to an instance whose worker has stalled
// and whose database is unreachable.
http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(http.StatusOK) })

// After: critical configuration fails startup, and readiness reports real ability to serve.
var lastTick atomic.Int64 // unix nanoseconds; the worker loop stores time.Now().UnixNano() on every iteration

func mustLoadConfig() Config {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("startup: DATABASE_URL is not set") // names the setting, never prints a value
	}
	return Config{DatabaseURL: dsn}
}

func ready(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if time.Since(time.Unix(0, lastTick.Load())) > 30*time.Second {
			http.Error(w, "worker loop stalled", http.StatusServiceUnavailable)
			return
		}
		ctx, cancel := context.WithTimeout(r.Context(), 300*time.Millisecond)
		defer cancel()
		if err := db.PingContext(ctx); err != nil {
			http.Error(w, "database unreachable", http.StatusServiceUnavailable)
			return
		}
		w.WriteHeader(http.StatusOK)
	}
}
```

Until the worker loop has ticked once, `lastTick` is zero, so the instance stays not ready, which is the handshake. The 30 s and 300 ms values are examples.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Always-green health | A handler that returns 200 without reading any state | Check real local state and required dependencies |
| Healthy but stuck | Health ignores worker, consumer or scheduler progress | Heartbeat read by health |
| Silent default for a critical setting | `getenv("X", "0")`, a zero meaning infinite | Fail startup on missing or invalid values |
| Liveness depends on remote services | The restart probe calls the database | Local-only liveness |
| Ready before warm-up | Port open and ready true while caches or connections are empty | Handshake after initialization |
| Boot-time migration on every instance | Schema changes in application startup | Separate controlled job |
| Stale endpoints | Long DNS or client-side endpoint caching, no deregistration on shutdown | Bounded lifetimes, drain before exit |

## Trade-offs and exceptions

- A deep readiness check that includes optional dependencies can make every instance unready at once when one shared dependency fails, turning a degraded service into an unavailable one. Keep optional dependencies out of readiness and degrade the feature instead.
- Small internal tools may need only a simple "can start" check; the source asks for checks that reflect ability to serve, scaled to what the service does.
- Warm-up that takes long delays scaling out; weigh it against serving cold (Added judgment).
- Migrations and one-time jobs are the other half of "Deployment and Startup Rules"; see `$release-it:restartable-automation`.

## Verification

- [ ] Starting without a required setting fails with a message naming it.
- [ ] Removing a required dependency changes the readiness result.
- [ ] A stalled worker loop makes the instance unhealthy.
- [ ] Liveness makes no remote calls.
- [ ] No heavy or destructive work runs on every instance at startup.
- [ ] Shutdown deregisters or goes not-ready before closing connections.

## Related

`$release-it:restartable-automation` for migrations and rerunnable scripts; `$release-it:release-risk` for configuration change control; `$release-it:metrics` for saturation and info metrics; `$release-it:stability-patterns` for the other patterns; `$release-it:resilience-testing` for failure tests; `release-it-startup-reviewer` to review a diff.

## Source

- `Deployment and Startup Rules`
- `Production Readiness and Release Risk Rules`: only the rule to validate critical configuration at startup.
- `Additional Stability Patterns`: only handshaking between instances, load balancers and dependencies.
- `Interconnect, Routing, Security, and Chaos Rules`: only the rule that DNS, service discovery, routing and load balancing stay health-aware and current.
- `Operational Visibility Rules`: only the anti-pattern of health checks that always return green.
