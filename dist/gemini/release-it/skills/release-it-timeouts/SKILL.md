---
name: "release-it-timeouts"
description: "Use when code makes an outbound call or waits on something outside the process (HTTP, RPC, database, queue, lock, future) and you must decide how long one attempt may take. Covers explicit limits, per-dependency budgets, deadlines. Repeating is `release-it-retries`; ceasing to call is `release-it-circuit-breakers`."
license: "MIT"
metadata:
  plugin: "release-it"
  book: "Release It!"
  invocation: "auto"
---

# Timeouts

Every wait on something you do not control needs a deliberate upper bound. This skill decides the bound for one attempt; repeating a failed attempt belongs to `release-it-retries`, and stopping calls to a dependency that keeps timing out belongs to `release-it-circuit-breakers`.

## When to use

- A new HTTP, RPC, database, cache, queue or lock call is written, or an existing client is constructed from library defaults.
- A `get()`, `join()`, `await`, `acquire()` or blocking read has no deadline.
- Threads or workers pile up behind one slow dependency, or a request "hangs" under load.
- A caller has a deadline of its own and the calls it makes do not inherit it.

## Rules

1. **Give every outbound call an explicit time limit.** [MUST] Without one, the dependency decides how long your thread, connection and caller wait. Check: each client construction or call site names a timeout or deadline in code or configuration.
2. **Choose the value on purpose; do not inherit a library default.** [MUST] Defaults are chosen for the library's convenience, and some clients wait indefinitely unless told otherwise (verify your client and its version). Check: the number is visible in the repository and has a name that says what it bounds.
3. **Forbid infinite waits on something outside the process or outside the caller's control.** [MUST NOT] This includes `future.get()`, `thread.join()`, `lock.acquire()`, a queue `take()` made while a request, lock or lease is held, a pool checkout and an `await` with no race against a deadline. Check: search for these calls and confirm each has a bounded variant or a surrounding deadline. Added judgment on the scope: an idle consumer waiting on its own in-process queue for the next item, holding nothing, is not waiting on a dependency and is not a finding; a poll interval there is still good for shutdown (`release-it-queues`).
4. **Give different dependencies different budgets when their behavior differs.** [SHOULD] The source says they "may need" different budgets. A cache lookup and a report generator should not share one number. Check: limits are per dependency or per operation, not one global constant.
5. **Derive the number from evidence.** [Added judgment] Start from the dependency's observed latency distribution (above its normal tail, below what the caller can afford) or from the caller's service target; if neither exists, put the value in configuration with a named default and flag it as unconfirmed. Check: the review note says where the number came from.
6. **Separate connection, response and total limits where the client distinguishes them.** [Added judgment] A connect limit bounds an unreachable host; a total limit bounds a peer that trickles bytes. Check: the total deadline includes reading the body, not only receiving headers.
7. **Never give a callee more time than the caller has left.** [Added judgment, following from "every timeout can cascade"] Pass the caller's remaining deadline down and take the smaller value. Check: no inner limit is larger than the outer limit that wraps it (`/release-it:call-chain-budget` does this arithmetic).
8. **Stop the work when the limit fires.** [Added judgment] A timeout that only abandons the wait leaves the work running and holding its resources. Check: cancellation reaches the thread, request or query, and the connection returns to its pool.
9. **Decide the failure behavior of a fired timeout.** [SHOULD] Prefer visible failure over silent hanging: return a contextual error, a labelled fallback, or queue the work, and never a fabricated success. Check: the caller's handling of the timeout error is written and tested.

## Procedure

1. List every wait in the changed code: network calls, database calls, lock and pool acquisition, queue reads made while holding a request or lease, joins, sleeps that wait for a condition.
2. For each, find the effective limit: explicit in code, set by configuration, a library default, or none.
3. Find the limit of whoever calls this code. The inner limit must fit inside it.
4. Pick the value (rule 5), set it at the layer that can enforce it, and make sure cancellation propagates.
5. Write what the caller sees when it fires, and record the timeout in metrics (`release-it-metrics`).
6. Prove it with a stalled peer, not a mock that returns an error (`release-it-resilience-testing`).

## Example

```go
// Before: http.Get uses http.DefaultClient, which has no overall timeout.
// A rates service that accepts the connection and never answers holds this goroutine forever.
func fetchRate(currency string) (float64, error) {
	resp, err := http.Get("https://rates.internal/v1/" + currency)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	return decodeRate(resp.Body)
}

// After: a named budget for this dependency, tied to the caller's context so cancellation propagates.
var ratesClient = &http.Client{Timeout: 800 * time.Millisecond} // covers connect, headers and reading the body

func fetchRate(ctx context.Context, currency string) (float64, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		"https://rates.internal/v1/"+url.PathEscape(currency), nil)
	if err != nil {
		return 0, fmt.Errorf("rates: build request for %s: %w", currency, err)
	}
	resp, err := ratesClient.Do(req) // fails at the earlier of ctx's deadline and 800 ms
	if err != nil {
		return 0, fmt.Errorf("rates: get %s: %w", currency, err)
	}
	defer resp.Body.Close()
	return decodeRate(resp.Body)
}
```

The 800 ms is an example. In real code it comes from the dependency's measured latency and the caller's budget.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Library default | A client built with no timeout option, or `http.Get`, `requests.get(url)` with no `timeout` | Construct the client with a named limit |
| Unbounded blocking primitive | `future.get()`, `join()`, `lock.acquire()`, or `queue.get()` with no argument while a request, lock or lease is held | Use the bounded variant and handle the expiry |
| One number everywhere | The same constant used for a cache, a payment gateway and a batch export | Per-dependency limits from evidence |
| Inner limit longer than outer | A 30 s client call inside a 10 s request handler | Pass the remaining deadline down |
| Wait abandoned, work continues | Timeout fires but the query or thread keeps running | Propagate cancellation, close the connection |
| Timeout swallowed | `except TimeoutError: pass` | Surface, fall back visibly, or fail with context |

## Trade-offs and exceptions

- The source asks for intentional limits, not short ones. A long limit that was chosen and written down is compliant; an inherited one is not.
- A limit that is too tight turns healthy slowness into failures, and combined with retries it adds load (Added judgment). Check the number against measured latency before shipping it.
- Long-running jobs and streaming calls need a bounded wait per step with progress visibility rather than one total limit; see `release-it-scheduled-work`.
- Pure in-process calls have no remote peer and need no timeout. That includes a worker thread idling on its own queue between items (Added judgment); the same `get()` inside a request handler is a wait someone else is blocked behind and needs a limit.

## Verification

- [ ] Every outbound call and wait in the change has an explicit, named limit.
- [ ] No inner limit exceeds the limit of the layer that wraps it.
- [ ] A fired timeout cancels the work and releases its resources.
- [ ] The caller's behavior on timeout is defined and tested.
- [ ] Timeouts are counted in a metric.

## Related

`release-it-retries` for repeating a failed attempt; `release-it-circuit-breakers` for stopping calls; `/release-it:call-chain-budget` for arithmetic across layers; `release-it-timeout-reviewer` to review a diff; `release-it-call-hardener` to apply the change.

## Source

- `Timeouts Are Mandatory`
- `Dependency Protection Rules`: only the anti-pattern of remote calls with no timeout.
- `Stability Mindset Rules`: only the rule that every timeout can cascade.
- `Code Generation Rules`: only the default of an explicit timeout for every remote dependency and the ban on infinite waits.
