---
name: "data-boundaries"
description: "Use when code accepts external input or reads a dependency's response (bodies, messages, files) and decides what to trust. Covers status, shape and plausibility checks, parse versus domain errors, validating before caching or enqueueing. Dead-lettering is `queues`; your contract is `$release-it:api-contracts`."
---

# Data boundaries

Anything that crosses a process boundary is untrusted until checked, including replies from your own internal services. This skill checks what arrives; declaring what you promise to callers is `$release-it:api-contracts`, and size limits as a memory defense overlap with `$release-it:resource-budgets`.

## When to use

- A handler, consumer or job reads a body, message, file or environment value and uses it.
- A client reads a dependency's response and passes the fields on.
- Parsed data is about to be stored in a cache, published to a queue or sent downstream.
- A parsing failure and a business-rule rejection are reported with the same error.

## Rules

1. **Treat all external input as untrusted.** [MUST] This includes user input, messages, files and responses from other services. Check: no external value reaches state, a query, a command line, a cache, a queue or a log line before it is checked.
2. **Validate a dependency's response by status, content type, shape and semantics before trusting it.** [MUST] A 200 with the wrong body is a failure. Check: each of the four is tested, in that order, before the data is used.
3. **Validate syntax, shape and business plausibility separately where needed.** [MUST] Well-formed JSON is not a valid order, and a valid order is not a plausible one. Check: the three checks are distinguishable in code and in the errors they produce.
4. **Keep parsing errors and domain-rule violations distinct.** [MUST] They have different owners and different reactions: a malformed message goes to quarantine, a rule violation may go back to a user. Check: separate error types or codes, and separate handling.
5. **Do not let malformed data poison caches, queues or downstream systems.** [MUST NOT] Bad data stored once is read many times. Check: validation happens before `cache.set`, before publish, before the write; a failing item is rejected or quarantined, never stored "for now".
6. **Normalize and sanitize once, at the right boundary.** [MUST] Check: one place canonicalizes (trimming, case, Unicode form, units, time zones); inner code does not re-sanitize ad hoc.
7. **Validate operational assumptions at system boundaries.** [MUST] Expected schema version, environment, region or feature state should be checked where the process meets them. Check: a mismatch fails loudly at startup or first use with a message that names what was expected.
8. **Cap sizes at the boundary.** [Added judgment, linking to the memory-guarding rule] Body bytes, array length, string length and nesting depth need limits. Check: a limit exists and exceeding it is a rejection, not an out-of-memory error.
9. **Treat an implausible reply as a dependency failure.** [Added judgment] A price of zero or a negative quantity from a dependency feeds the same breaker and metrics as a timeout. Check: implausible responses are counted as failures and surfaced, not quietly clamped.
10. **Count and sample validation failures instead of logging each.** [Added judgment, linking to the rule against log spam] Check: a malformed flood from one client cannot flood the logs.

## Procedure

1. List every boundary the change crosses: inbound requests, consumed messages, files, outbound replies you consume.
2. For each, write the three checks (syntax, shape, plausibility) and the error each produces.
3. Place validation before any side effect: cache write, publish, persistence.
4. Decide what happens to a rejected item: respond with an error, quarantine, or fail the dependency call.
5. Add size limits and counters.
6. Test with malformed, oversized and implausible inputs.

## Example

```ts
class MalformedResponse extends Error {}   // the reply is not what the contract allows
class ImplausibleResponse extends Error {} // the reply is well formed but wrong for the business

// Before: trusts whatever the tax service returns, even an error page.
// const { rate } = await (await fetch(TAX_URL)).json();
// return Math.round(subtotalCents * rate);

// After: status, content type, shape, then plausibility, each with its own error.
async function taxFor(subtotalCents: number): Promise<number> {
  const res = await fetch(TAX_URL, { signal: AbortSignal.timeout(1000) });
  if (res.status !== 200) throw new MalformedResponse(`tax service status ${res.status}`);
  if (!res.headers.get("content-type")?.startsWith("application/json")) {
    throw new MalformedResponse("tax service content type is not JSON");
  }
  const body: unknown = await res.json();
  const rate = (body as { rate?: unknown } | null)?.rate;
  if (typeof rate !== "number") throw new MalformedResponse("tax service body lacks a numeric rate");
  if (!Number.isFinite(rate) || rate < 0 || rate > 0.5) {
    // 0.5 is this business's own ceiling, an example value rather than a general rule
    throw new ImplausibleResponse(`tax rate ${rate} outside the accepted range`);
  }
  return Math.round(subtotalCents * rate);
}
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Trusting internal services | Response fields used with no status or shape check | Validate every dependency response |
| Parse-and-store | Cache or queue write directly after parsing | Validate first; reject or quarantine |
| One generic validation error | A single `ValidationError` for syntax, shape and rules | Distinct types with distinct handling |
| Defaulting on failure | `catch { rate = 0 }` | Fail the call and count it |
| Late sanitizing | The same trimming or escaping repeated in several layers | Normalize once at the boundary |
| Unbounded input | No size, depth or length limits | Limits at the edge |

## Trade-offs and exceptions

- Validating shape on every call costs CPU. Check shape always on external data; apply plausibility checks where wrong data would be expensive, and generate validators from a schema instead of hand-writing them (Added judgment).
- Be strict about the fields you use and tolerant of fields you do not know, so a dependency can add data without breaking you (Added judgment).
- Security-specific input handling (injection, authentication) goes beyond this book's scope; the source only asks for input handling to be part of readiness.
- Plausibility ranges belong to the business, not to this plugin; the number in the example is illustrative.

## Verification

- [ ] Status, content type, shape and plausibility are checked in that order for every consumed response.
- [ ] Parse errors and domain-rule violations are different errors with different handling.
- [ ] Nothing is cached, published or persisted before validation.
- [ ] Size limits exist at the boundary.
- [ ] Rejected items are rejected or quarantined, not stored.

## Related

`$release-it:api-contracts` for the promises you publish; `$release-it:caching` for stale and poisoned entries; `$release-it:queues` for quarantine and dead letters; `$release-it:logging` for sampling failures; `release-it-data-boundary-reviewer` to review a diff.

## Source

- `Data Boundary Rules`
- `Runtime State and Restart Safety Rules`: only the rules on validating external responses by status, content type, shape and semantics and on validating operational assumptions at boundaries.
