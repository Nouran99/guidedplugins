---
name: error-handling
description: "Use when writing or reviewing exceptions, error codes, null or absent returns, error messages, or cleanup and shutdown paths in your own code. Keeps the happy path readable and failures explicit and diagnosable; vendor exceptions caught at the edge are /clean-code:boundaries."
---

# Error handling

Designs how failure is expressed and handled inside your own code: what fails, who decides, what the caller can do about it, and what gets cleaned up. Translating a foreign library's failures at the edge is `/clean-code:boundaries`; the reliability policy for production dependencies (timeouts, retries) is outside this book.

## When to use

- A function returns `null`, `-1`, `false` or an empty string to mean "failed" or "absent".
- A `try` block wraps most of a function body, or `catch` blocks are longer than the logic.
- An error message says only "failed" or "invalid input".
- Resources (files, locks, connections, temporary state) are released on some paths and not others.

## Rules

1. **Decide how failures are handled on purpose, not by accident.** For each operation, decide what counts as failure, which failures are expected, and who handles them. Check: for every `throw` or error return there is a named caller that reacts to it.
2. **Keep the main success flow easy to follow.** The success flow reads top to bottom with failure handling at the edges. Check: removing every `catch` leaves a readable sequence of steps.
3. **Keep failure handling apart from the main logic.** Put the work in one function and the `try`/`catch` policy in a thin wrapper, so neither obscures the other. Check: no function mixes more than a few lines of handling with business steps.
4. **Put enough context in each error message to diagnose the failure.** Name the operation, the entity and the reason, without secrets or full payloads. Check: reading only the log line, you can tell what was attempted and why it failed.
5. **Choose error types that let callers decide what to do.** Define a type per distinct reaction (retry, show to user, abort), not per throw site. Check: no caller parses message text to decide what to do.
6. **Prefer exceptions or explicit result types to improvised error codes**, as the language's norms suggest. Check: magic return values (`-1`, `""`, `0`) do not mean failure.
7. **Do not return `null` or another absence marker when a safer representation exists.** Return an empty collection, a special-case object, an explicit optional or an error. Check: callers do not need a null check before using the result.
8. **Do not pass `null` or another invalid state unless the API deliberately models that case.** Check: the signature or type says whether absence is allowed; otherwise the callee rejects it at the boundary.
9. **Prefer exceptions, special-case objects, empty objects or explicit optionals, whichever the language and codebase conventions favor.** Check: the choice matches what neighboring code does.
10. **Make cleanup and shutdown paths correct, and make them easy to see.** Use the language's scoped-cleanup construct (`finally`, `defer`, `with`, `using`, try-with-resources). Check: every acquire has a release on every exit path, including exceptions and cancellation.
11. **Do not swallow failures.** Added judgment, following from rules 1 and 4: an empty `catch`, or a `catch` that logs and continues as if the operation succeeded, hides a failure from the one who could decide. Check: each catch either handles, translates with the cause preserved, or rethrows.

## Procedure

1. List the failure points in the touched code: external calls, parsing, lookups, state transitions.
2. For each, write the decision: expected or exceptional, who reacts, what they do.
3. Replace absence sentinels with the chosen model. Migrate callers in small steps; keep the old return shape behind a wrapper until the last caller moves.
4. Extract the work from the handler so the main function is the happy path.
5. Rewrite messages to carry operation, subject and reason. Preserve the original cause when translating.
6. Verify each acquire/release pair and each cancellation path.
7. Add a test that triggers each distinct reaction path.

## Example

```python
# Before: None means "no such member", callers forget to check
def find_member(member_id):
    row = db.fetch_one("select * from members where id = ?", member_id)
    return Member(row) if row else None

def renew_card(member_id):
    member = find_member(member_id)
    member.card_expires = next_year()      # AttributeError when missing
    db.save(member)

# After: absence is explicit and the message carries context
class MemberNotFound(LookupError):
    """Raised when an operation names a member id that does not exist."""

def get_member(member_id):
    row = db.fetch_one("select * from members where id = ?", member_id)
    if row is None:
        raise MemberNotFound(f"get_member: no member with id={member_id}")
    return Member(row)

def renew_card(member_id):
    member = get_member(member_id)
    member.card_expires = next_year()
    db.save(member)
```

Where a missing member is routine (a guest checkout), a special-case `GuestMember` object with the same interface removes both the check and the exception.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Null return | Function returns `null`, `None` or `undefined` for a normal outcome | Empty object, special case, optional type or exception |
| Null argument | Callers pass `null` to skip behavior | Overload, separate function, or optional parameter modeled explicitly |
| Error code | Integer or string statuses that callers compare | Exception hierarchy or result type with named cases |
| Catch-all | `catch (Exception e)` that continues | Catch the specific type, or let it propagate |
| Silent swallow | Empty `catch`, or log and carry on | Handle, translate with cause, or rethrow |
| Context-free message | `"error"`, `"invalid"`, `"failed"` | Operation, subject, reason |
| Leaky cleanup | Release only on the success path | Scoped cleanup construct |
| Try-wrapped body | `try` spanning most of a function | Extract the body; wrap the call |

## Trade-offs and exceptions

- Languages differ: Go returns `(value, error)`, Rust returns `Result`, Java uses exceptions, TypeScript often uses a union with `undefined`. Use the idiom of the codebase; the rule is explicitness, not exceptions.
- Exceptions for expected, frequent outcomes can be slower and noisier than a typed result; choose the result type there.
- Some APIs legitimately accept absence (an optional filter). The rule is that the API models it.
- Retrying, timeouts and circuit breaking are reliability policies that the book does not prescribe; do not add them under this skill.
- Error messages must not leak secrets, tokens or personal data; trim context accordingly.

## Verification

- [ ] No touched function returns a sentinel for a normal outcome.
- [ ] Each failure path has a named caller reaction and a test.
- [ ] Every error message carries operation, subject and reason.
- [ ] The success path reads without the handlers.
- [ ] Every acquired resource is released on all exit paths.
- [ ] No catch block is empty or silently continues.

## Related

`/clean-code:boundaries` for translating foreign failures; `/clean-code:function-contracts` for effects of error paths; `/clean-code:tdd-discipline` for failure-path tests; `clean-code:error-handling-reviewer` to review a diff.

## Source

- `Error handling`
- `Function rules`: only the rules on error signaling and isolating error handling from main logic.
