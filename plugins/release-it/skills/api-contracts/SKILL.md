---
name: api-contracts
description: "Use when designing or changing an API, event schema or integration contract: error responses, retryable versus non-retryable outcomes, call granularity, versioning, and documented timeout and retry expectations. Checking incoming data is `data-boundaries`; staged rollout is `release-risk`."
---

# API and integration contracts

A contract is what a caller is allowed to rely on when things go wrong. This skill makes failure, retry, timeout and version behavior part of what you publish. Validating what arrives is `/release-it:data-boundaries`, and the staged rollout of a change to a contract is `/release-it:release-risk`.

## When to use

- A new endpoint, RPC, event type or SDK method is defined, or an existing one changes shape.
- Callers cannot tell from a response whether to retry, back off or give up.
- A client needs several sequential calls to complete one logical action.
- A change removes or renames a field, or alters an error code.

## Rules

1. **Make failure modes explicit in the contract where they matter.** [MUST, source qualifier: where they matter] Check: each operation lists the failures a caller must react to differently (unavailable, rate limited, conflict, invalid, not found).
2. **Return clear retryable versus non-retryable outcomes.** [MUST] Check: every error response says, by status and code or by a flag, whether repeating the request can help, and gives a wait hint (such as `Retry-After`) when it can.
3. **Prefer coarse-grained, resilient interactions over fragile chattiness.** [SHOULD] Each extra round trip is another chance to time out, and a multi-step exchange leaves half-finished state. Check: one logical action needs one call, or a call with defined partial-failure semantics.
4. **Use versioning and compatibility discipline for long-lived contracts.** [MUST] Check: within a version, changes are additive; removals and renames go through a new version with a published deprecation period (the mechanics are Added judgment).
5. **Document retry, timeout, version and compatibility expectations clearly.** [MUST] Check: the contract states the expected client timeout, which operations are safe to retry and how, the current version and the compatibility policy.
6. **State how repeats are made safe.** [Added judgment, following from the retry rules] For operations clients may retry, specify an idempotency key or say the operation is naturally idempotent. Check: a client author can tell, from the documentation alone, whether a repeated POST duplicates.
7. **Include overload and degraded responses in the contract.** [Added judgment, following from back pressure] Document the rejection status, the retry hint and any degraded marker a response can carry (`/release-it:back-pressure`, `/release-it:circuit-breakers`). Check: the degraded flag and overload codes appear in the specification.
8. **Use stable machine-readable error codes and a correlation identifier.** [Added judgment] Prose changes; codes should not. The identifier lets support find the request (`/release-it:logging`). Check: callers can branch on a code and quote an id.
9. **Bound the contract itself.** [Added judgment] Maximum page size, maximum body size, rate limits and long-poll durations belong in the specification. Check: no operation promises an unbounded result.
10. **Do not leak internals in errors.** [Added judgment] Stack traces and dependency names are for logs. Check: error bodies contain a code, a safe message and an id.
11. **Let consumers ignore what they do not know.** [Added judgment] For events and responses, adding a field must not break readers, and producers must not repurpose a field in place. Check: unknown fields are tolerated in consumers and the specification says so.

## Procedure

1. List the operations and the ways each can fail from the caller's point of view.
2. Map each failure to a status, a code, and a retryable flag, plus a hint where one helps.
3. Check granularity: can the caller complete a logical action in one call?
4. Write the timeout, retry, idempotency and version expectations into the specification.
5. For a change, decide whether it is additive; if not, create a version and a deprecation plan.
6. Add contract tests for error codes and the retry flag.

## Example

```ts
type ApiError = {
  code: "RATE_LIMITED" | "DEPENDENCY_UNAVAILABLE" | "INVALID_REQUEST" | "CONFLICT";
  message: string;
  retryable: boolean;
  retryAfterSeconds?: number;
  correlationId: string;
};

// Before: every failure is a 500 with prose, so a client cannot tell whether repeating the call is safe or useful.
// res.status(500).json({ error: "Something went wrong" });

// After: a small envelope that tells the caller what happened and what to do next.
function sendError(res: Response, status: number, e: ApiError): void {
  if (e.retryAfterSeconds !== undefined) res.set("Retry-After", String(e.retryAfterSeconds));
  res.status(status).json(e);
}

sendError(res, 429, { code: "RATE_LIMITED", message: "Request rate for this key is too high",
  retryable: true, retryAfterSeconds: 2, correlationId });
sendError(res, 503, { code: "DEPENDENCY_UNAVAILABLE", message: "Pricing is temporarily unavailable",
  retryable: true, retryAfterSeconds: 5, correlationId });
sendError(res, 422, { code: "INVALID_REQUEST", message: "quantity must be a positive integer",
  retryable: false, correlationId });
```

The specification then states: clients should time out after a stated period, may retry only responses with `retryable: true` after the hinted delay, and must send an idempotency key on `POST /orders`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Everything is a 500 | One status for validation, overload and outage | Distinct statuses and codes |
| Prose-only errors | Callers match on message text | Stable codes |
| Silent retry hazard | A POST that creates records with no idempotency story | Key or natural idempotence |
| Chatty protocol | A client loops N calls to assemble one object | Coarse-grained operation |
| Breaking change in place | A field renamed or removed under the same version | New version, deprecation |
| Undocumented limits | No timeout, page-size or rate expectations | Specify them |
| Leaky errors | Stack traces or hostnames in responses | Code, safe message, id |

## Trade-offs and exceptions

- The source asks for failure modes "where they matter". List the ones that change what a caller does, not every possible error.
- Coarse-grained operations enlarge payloads and complicate partial failure; define the partial-failure semantics instead of defaulting to fine-grained.
- A private API with one consumer deployed in lockstep can change in place; the compatibility discipline applies as contracts become long-lived (Added judgment).
- Idempotency, ordering and schema evolution for event streams in depth belong to a data-systems plugin such as `data-intensive-apps`.

## Verification

- [ ] Every operation documents its caller-relevant failures.
- [ ] Each error says whether retrying can help, with a hint when it can.
- [ ] One logical action is one call, or partial failure is defined.
- [ ] Timeout, retry, idempotency and version expectations are written down.
- [ ] The change is additive within its version, or a new version exists.

## Related

`/release-it:data-boundaries` for inbound validation; `/release-it:retries` for the client side; `/release-it:release-risk` for rollout; `/release-it:back-pressure` for overload responses; `release-it:contract-reviewer` to review a diff.

## Source

- `API and Contract Rules`
