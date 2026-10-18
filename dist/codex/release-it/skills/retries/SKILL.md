---
name: "retries"
description: "Use when code repeats a failed call, redelivers a message, or sits behind a client or gateway with automatic retries. Covers eligibility, bounded attempts and time, backoff with jitter, permanent failures, retries stacked across layers. Wait limits are `$release-it:timeouts`; job schedules are `$release-it:scheduled-work`."
---

# Retries

A retry multiplies load on a dependency that is already struggling. This skill decides whether a failed call may be repeated and how; the wait limit of each attempt is `$release-it:timeouts`, the decision to stop calling is `$release-it:circuit-breakers`, and the start times of periodic jobs are `$release-it:scheduled-work`.

## When to use

- A loop, decorator, library option or message-redelivery setting repeats a failed operation.
- A client, SDK, gateway or service mesh retries on its own and the application adds retries on top.
- A burst of errors is followed by a larger burst of traffic to the same dependency.
- A new write operation is called "safe to retry" without saying why.

## Rules

1. **Retry only where repeating is safe for the caller and for the provider.** [MUST] A repeated non-idempotent write duplicates its effect, and a repeat against an overloaded provider deepens the overload. Check: the operation is idempotent or carries a deduplication key the provider honors, and a rejection that says "slow down" is not retried at once.
2. **Bound the number of attempts and the total retry time.** [MUST] Unbounded persistence turns a short outage into a long one. Check: both an attempt cap and a time budget exist as named values, and the budget fits inside the caller's remaining deadline.
3. **Add backoff and jitter.** [MUST] Callers that fail together retry together, and synchronized pulses re-create the overload. Check: the delay grows between attempts and includes randomness; no fixed-interval retry loop.
4. **Do not retry validation errors or permanent failures.** [MUST NOT] A malformed request or a rejected credential fails the same way every time. Check: the retry condition is an allowlist of transient conditions (timeouts, resets, explicit "unavailable"), not "any exception".
5. **Do not treat all failures as transient.** [MUST NOT] Classification belongs where the error is understood, usually the client wrapper, and the caller receives a retryable versus non-retryable distinction (see `$release-it:api-contracts`). Check: the error type or flag distinguishes the two.
6. **Retry at one layer.** [MUST NOT nest retries at multiple layers] Nested retries at several layers multiply: three layers with three attempts each reach the dependency nine times per failure. Check: trace the call path and list each layer that retries (application code, SDK, proxy, job runner); exactly one owns it.
7. **Make library retries explicit.** [SHOULD, source: avoid implicit library retries by default] Know the client's built-in retry policy, configure it to match this skill, or disable it. Check: the retry configuration is visible in the repository.
8. **Respect hints from the provider.** [Added judgment] Honor `Retry-After` or equivalent, and do not retry while a breaker for that dependency is open. Check: breaker-open and rate-limited outcomes are handled differently from timeouts.
9. **Keep retry noise out of the logs.** [MUST NOT spam] Avoid log spam loops under retry storms: log the final outcome with the attempt count and count retries in a metric. Check: no log line per attempt at full volume.
10. **Cap retries as a share of traffic.** [Added judgment] A retry budget (retries allowed as a fraction of recent requests) stops retries from amplifying a wide failure. Check: when most requests fail at once, retry volume is capped.

## Procedure

1. Find every place a failed operation is repeated, including implicit ones in clients, proxies and job runners.
2. For each, answer in writing: why is a repeat safe, which errors qualify, how many attempts, how long in total, what delay.
3. Collapse stacked layers to one owner; disable or align the others.
4. Add the attempt count to the final error and to a counter.
5. Test with a dependency that fails transiently, then permanently, then not at all (`$release-it:resilience-testing`).

## Example

```python
# Before: retries every exception, immediately, ten times, including a non-idempotent write.
def charge(card_token, cents):
    for _ in range(10):
        try:
            return gateway.post("/charges", json={"token": card_token, "cents": cents})
        except Exception:
            continue

# After: transient errors only, three attempts, jittered backoff, a time budget, and a key that makes repeating safe.
import random
import time

RETRYABLE = (ConnectTimeout, ReadTimeout, ServiceUnavailable)

def charge(order_id, card_token, cents, *, budget_s=6.0):
    started = time.monotonic()
    attempts = 0
    last_exc = None
    for attempt in range(1, 4):                                   # at most 3 attempts
        remaining = budget_s - (time.monotonic() - started)
        if remaining <= 0:
            break
        attempts = attempt
        try:
            return gateway.post(
                "/charges",
                json={"token": card_token, "cents": cents},
                headers={"Idempotency-Key": f"charge-{order_id}"},  # safe only if the gateway honors the key
                timeout=min(2.0, remaining),
            )
        except RETRYABLE as exc:
            last_exc = exc                                        # keep the cause for the final error
            if attempt == 3:
                break
            delay = random.uniform(0, min(1.0, 0.25 * 2 ** attempt))  # full jitter, capped
            time.sleep(min(delay, max(0.0, budget_s - (time.monotonic() - started))))
        # CardDeclined and ValidationError are not in RETRYABLE and propagate at once.
    raise ChargeUnavailable(order_id, attempts=attempts) from last_exc  # one final error: attempt count plus the underlying cause
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Nested retries | A retry decorator around a client whose SDK also retries, behind a gateway that retries | One owning layer; disable the rest |
| Retry on any exception | `except Exception: continue`, `retry_on=all` | Allowlist of transient conditions |
| Fixed-interval or immediate retry | `sleep(1)` in a loop, no growth, no randomness | Exponential growth with jitter |
| Unbounded loop | `while True` around a remote call | Attempt cap and time budget |
| Unsafe repeat | Retried POST that creates a record, sends an email or moves money | Idempotency key or no retry |
| Per-attempt logging | An error log inside the retry loop | Log the outcome once with the attempt count |

## Trade-offs and exceptions

- The source allows retries only where they are safe. For a user-facing call with a tight deadline, or an operation with no deduplication, the right number of retries is zero.
- When a client library retries and cannot be configured, do not add a second layer; wrap with a breaker or a timeout instead.
- Retrying a message consumer is redelivery, not a loop in code: bound it with a delivery limit and send the message to dead-letter handling (`$release-it:queues`).
- Backoff helps only if there is somewhere to wait; in a request path the total budget, not the backoff curve, is what protects the user.

## Verification

- [ ] Each retried operation has a written reason it is safe to repeat.
- [ ] Attempts and total time are both capped, and the cap fits the caller's deadline.
- [ ] Delays grow and are jittered.
- [ ] Validation and permanent errors are not retried.
- [ ] Only one layer on the path retries.
- [ ] Retries are counted, not logged per attempt.

## Related

`$release-it:timeouts` for the per-attempt wait; `$release-it:circuit-breakers` to stop flooding; `$release-it:call-chain-budget` to compute amplification across layers; `$release-it:scheduled-work` for jobs; `release-it-retry-reviewer` to review a diff; `release-it-call-hardener` to apply the change.

## Source

- `Retries Must Be Disciplined`
- `Retry Storms`
- `Dependency Protection Rules`: only the anti-patterns on nested retries and on treating all failures as transient.
- `Code Generation Rules`: only the default of explicit retry policy where safe and the ban on implicit library retries.
- `Operational Visibility Rules`: only the rule to avoid log spam loops under retry storms.
