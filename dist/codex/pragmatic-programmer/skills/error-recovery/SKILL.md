---
name: "error-recovery"
description: "Use when writing or reviewing how failures travel: where an error is detected, what context survives, whether callers can tell retryable, recoverable and permanent failures apart, and where it stops. Expectations are `contracts`; cleanup is `$pragmatic-programmer:resource-discipline`; a defect's cause is `debugging`."
---

# Error handling and recovery

Decide how a failure that has already happened travels through the code: where it is noticed, what it carries, who can recover, and where it stops. What counts as a violation in the first place is `$pragmatic-programmer:contracts`; guaranteeing cleanup on failure paths is `$pragmatic-programmer:resource-discipline`; production policies such as time limits and circuit breakers belong to a Release It! plugin.

## When to use

- A `catch`, `except` or error return is written or reviewed.
- An error is wrapped, rethrown or logged, and you must decide what it keeps.
- Callers cannot tell a failure worth retrying from one that never will succeed.
- One bad item (a row, a message, a request) could stop the whole job or process.

## Rules

1. **Detect errors close to their source.** [MUST] Check: the bad value is rejected where it enters or is produced, not several frames later where the symptom appears.
2. **Do not discard useful error context.** [MUST NOT] Check: when an error is wrapped or translated, the original cause travels with it (`raise ... from`, `%w`, a `cause` argument).
3. **Let callers distinguish retryable, recoverable and permanent failures where relevant.** [MUST] Check: the distinction is in a type, a code or a field, and no caller parses message text.
4. **Fail loudly enough to diagnose, but with boundaries that prevent system-wide collapse.** [MUST] Check: you can name the boundary (request, job item, message, worker) that absorbs the failure and what it reports.
5. **At each boundary, decide who can recover, what context survives and who owns cleanup.** [Compact checklist] Check: the three answers are written down or evident from the code.
6. **Put the operation, the key identifiers and the cause in the error.** [Added judgment] Leave out secrets and personal data. Check: reading only the error, you can tell what was attempted, on what, and why it failed.
7. **Choose the containment boundary on purpose.** [Added judgment] A boundary absorbs failures of the unit inside it and reports them; failures it does not recognize still end the unit visibly. Check: the boundary catches specific, known failures, not everything.
8. **A contained failure must still be visible.** [MUST] The source asks to fail loudly. Check: the failure leaves a log with its cause, a counter or a status in the result, never silence.
9. **Do not swallow errors.** [Added judgment] Each catch does one of three things: handles the failure, translates it with the cause preserved, or lets it propagate. Check: no empty catch, and no catch that logs and continues as if the operation had succeeded.
10. **Classify with types or codes, never with message text.** [Added judgment] Check: no `if "timeout" in str(err)`.
11. **Repeat an operation only if it is safe to repeat.** [Added judgment] The source asks that callers can tell which failures are retryable; whether and how to retry (limits, delays, budgets) is production reliability policy that this book does not set. Check: a retry exists only for an operation shown to be safe, and it is not added here without that evidence.

## Procedure

1. List the failure points in the changed code: parsing, lookups that can miss, calls to other systems, state transitions that can be refused.
2. For each, write the class: programmer error (a bug), contract violation (bad input), expected domain failure, transient failure, permanent failure.
3. Decide where it is detected, what it carries and who reacts. Move detection toward the source.
4. Give transient and permanent failures distinct types or codes.
5. Choose the containment boundary and what it reports.
6. Read each message as a stranger would, then add the operation, identifiers and cause.
7. Test one path per distinct reaction.

## Example

```python
# Before: every failure is silently skipped, so bad data and an outage look the same
def import_customers(rows):
    imported = 0
    for row in rows:
        try:
            save_customer(parse_row(row))
            imported += 1
        except Exception:
            pass
    return imported
```

```python
# After: failures are classified, the cause travels, and the batch boundary reports instead of hiding
class RowRejected(Exception):
    """Permanent: this row will never import as it is."""

class StoreUnavailable(Exception):
    """Transient: the store failed; the same row may succeed later."""

def parse_row(row) -> Customer:
    try:
        return Customer(email=row["email"].strip().lower(), name=row["name"])
    except (KeyError, AttributeError) as err:
        raise RowRejected(f"parse_row: missing or malformed field in {row!r}") from err

def import_customers(rows) -> ImportReport:
    report = ImportReport()
    for n, row in enumerate(rows, start=1):
        try:
            save_customer(parse_row(row))            # save_customer raises StoreUnavailable when the store is down
            report.imported += 1
        except RowRejected as err:                   # permanent: record it and move on
            report.rejected.append((n, str(err)))
        except StoreUnavailable as err:              # transient: stop here, keep what was done, say where
            report.stopped_at, report.cause = n, err
            break
    return report                                    # any other exception is a bug and propagates
```

Bad rows are listed with their position and reason, an outage stops the batch at a known row instead of discarding the rest, and unexpected exceptions still fail loudly.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Silent swallow | Empty `catch`/`except`, or `pass` after a broad catch | Handle, translate with cause, or let it propagate |
| Lost cause | A new error created from only a message string | Chain the original error |
| Everything is one type | Callers branch on message text | Distinct types or codes for retryable, recoverable and permanent |
| Boundary too wide | A top-level catch that keeps a corrupt process running | Contain per unit of work; let invariant failures end the unit |
| Boundary too narrow | One bad row aborts a ten-thousand-row import | Contain per item and report |
| Context-free message | `"error"`, `"failed"`, `"invalid"` | Operation, identifiers, cause |
| Log and continue | An error logged, then success reported | Return or raise the failure |

## Trade-offs and exceptions

- The source says "where relevant": a small script may need only one failure class. Do not build a hierarchy of error types for a single call.
- Failing loudly and containing failure pull against each other. The source asks for both: loud enough to diagnose, bounded enough not to collapse the system. Added judgment: contain at the unit of work, end the unit on anything unrecognized.
- Languages differ: Go returns an error value, Rust a `Result`, Java uses exceptions. Use the idiom of the codebase; the rules are about classification, context and containment.
- Retries, time limits, circuit breakers and similar defenses are outside this book's rules for this section; a Release It! plugin owns them.

## Verification

- [ ] Each failure point is detected at or near its source.
- [ ] Wrapped errors keep their cause.
- [ ] Retryable, recoverable and permanent failures are distinguishable without reading message text.
- [ ] The containment boundary is named and reports what it absorbed.
- [ ] No catch is empty, and none logs and continues as though the operation succeeded.

## Related

`$pragmatic-programmer:contracts` for defining violations; `$pragmatic-programmer:resource-discipline` for cleanup on failure paths; `$pragmatic-programmer:debugging` for explaining a failure that already happened; `pragmatic-programmer-failure-path-reviewer` to review a diff.

## Source

- `Error Handling and Recovery`
- `Design by Contract and Assertions`: only the rule to distinguish programmer errors, contract violations and expected domain failures.
