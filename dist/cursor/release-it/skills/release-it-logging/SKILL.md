---
name: "release-it-logging"
description: "Use when adding or reviewing log statements, catch blocks, error handlers or retry loops, or when an incident left no usable trail. Covers structured context, correlation identifiers, failure logging, secrets, log spam and silent failure. Counts and timings are `release-it-metrics`."
license: "MIT"
metadata:
  plugin: "release-it"
  book: "Release It!"
  invocation: "auto"
---

# Logging for diagnosis

A log line is for the person who is reading it during an outage. This skill makes failures leave a trail with context and correlation; the numbers that say how often and how slowly are `release-it-metrics`, and health endpoints are `release-it-startup-and-health`.

## When to use

- A `catch`, `except`, `recover` or error callback is written or changed.
- A new boundary appears: outbound call, queue consumer, scheduled job, admin action.
- A retry loop or tight loop logs on each iteration.
- Reading an incident's logs, you could not tell which request, which dependency or what was attempted.

## Rules

1. **Emit meaningful logs at boundaries and failure points.** [MUST] Check: each outbound call failure, rejected request, breaker or health transition and startup configuration summary produces a record.
2. **Include the identifiers needed for correlation and diagnosis.** [MUST] Request or trace id, the entity involved, the dependency and the operation. Check: from one failure line you can find the request that caused it and the dependency it touched.
3. **Log structured context, not just prose.** [MUST] Use key-value or JSON fields with stable names and a constant message. Check: fields can be filtered and counted without parsing sentences.
4. **Log failures with the dependency, operation and outcome.** [MUST] Add elapsed time and attempt count. Check: a failure line has `dependency`, `operation`, `outcome` and enough to tell a timeout from a bad response.
5. **Do not log secrets.** [MUST NOT] Tokens, passwords, keys, full card numbers and personal data stay out of fields, messages and URLs. Check: redaction is applied in the logging layer and logged URLs strip credentials and query secrets.
6. **Avoid log spam loops under retry storms.** [MUST NOT] A failing dependency multiplied by retries multiplied by callers is a log flood that hides the signal and costs money. Check: log the final outcome with the attempt count, and rate-limit identical errors.
7. **Do not swallow exceptions.** [MUST NOT] An empty catch, or a catch that logs and carries on as if the operation succeeded, is a silent failure. Check: each catch handles the error, translates it with the cause preserved, or rethrows.
8. **Do not log only stack traces, and do not write generic "something went wrong".** [MUST NOT] A trace shows where, not what was being attempted. Check: the message names the operation and the subject.
9. **Carry correlation across boundaries.** [MUST, missing correlation information is a listed silent failure] Pass the identifier in headers or message attributes and log it in consumers. Check: a request can be followed from entry through every service it called.
10. **Log where the error is handled, once.** [Added judgment] Logging and rethrowing at every layer prints one failure many times. Check: one record per failure, at the layer that decides what to do.
11. **Keep log volume bounded.** [Compact checklist, mini.md lists log streams among the things to bound] Use levels, and avoid per-item logging inside hot loops. Check: the worst-case line rate under failure is known and acceptable.
12. **Make build and configuration state visible at startup.** [MUST, source: make version, build, configuration and dependency state visible enough to diagnose a live instance] Check: a startup record carries version, build id, effective configuration (secrets masked) and dependency addresses.

## Procedure

1. List the boundaries and catch blocks in the change.
2. For each, decide the record: level, constant message, fields (correlation id, dependency, operation, outcome, elapsed, attempts).
3. Remove swallow patterns and duplicate log-and-rethrow.
4. Check that no field can hold a secret.
5. Count rather than log inside retry and hot loops.
6. Trigger each failure in a test and read the output as a stranger at 3 a.m.

## Example

```go
// Before: the failure is swallowed, the log says nothing a stranger can use, and the caller gets nil.
if err != nil {
	log.Println("error:", err)
	return nil
}

// After: one structured record with the context needed to diagnose it, and the error goes to the caller.
if err != nil {
	slog.Error("dependency call failed",
		"dependency", "rates",
		"operation", "GetRate",
		"outcome", classify(err), // "timeout", "unavailable" or "bad_response"
		"attempts", attempts,
		"elapsed_ms", time.Since(start).Milliseconds(),
		"request_id", reqID,
		"currency", currency,
		"error", err,
	)
	return fmt.Errorf("rates: get %s: %w", currency, err)
}
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Swallowed exception | Empty `catch`, `except: pass`, error assigned to `_` | Handle, translate with cause, or rethrow |
| Generic message | `"something went wrong"`, `"error"`, `"failed"` | Name the operation, subject and outcome |
| Trace only | `printStackTrace()` or `log.error(e)` with no message | Add structured context |
| Correlation missing | Consumers or downstream calls that do not log or forward the id | Propagate and log it |
| Log in the loop | A log call inside a retry or per-item loop at full volume | Count; log the outcome once |
| Secrets in logs | Authorization headers, tokens in URLs, full request bodies | Redact at the logger |
| Log and rethrow everywhere | The same failure at every layer | Log once where it is handled |

## Trade-offs and exceptions

- More context is not always better: payload dumps can leak data and cost money. Log identifiers and outcomes, not bodies.
- Some failures are expected and frequent (a not-found lookup). Count them and log at a low level; the rule is about failures someone must diagnose.
- Sampling and rate limiting can hide the first occurrence of a new error; keep the first of each kind (Added judgment).
- Tracing systems carry correlation for you if the project has one; the rule is that correlation exists, not that you build it.

## Verification

- [ ] Every catch handles, translates with cause, or rethrows.
- [ ] Failure records carry dependency, operation, outcome and a correlation id.
- [ ] No secret can reach a field, message or logged URL.
- [ ] Loops and retries do not log per attempt at full volume.
- [ ] Startup logs version, build and effective configuration.

## Related

`release-it-metrics` for counts and timings; `release-it-retries` for retry loops; `release-it-data-boundaries` for sampling validation failures; `release-it-startup-and-health` for health signals; `release-it-observability-reviewer` to review a diff.

## Source

- `Logging`
- `Observability Is Part of the Design`
- `Silent Failure`
- `Operational Visibility Rules`: only the anti-pattern of logging stack traces without context.
- `Production Readiness and Release Risk Rules`: only the rule to make version, build, configuration, dependency and runtime state visible.
