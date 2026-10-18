---
name: "code-complete-error-handling"
description: "Use when writing or reviewing the failure path: exceptions, error codes, catch blocks, messages, fallbacks. Unknown cause: code-complete-debugging. Valid input: code-complete-trust-boundaries. Programmer errors: code-complete-assertions-and-contracts."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Error handling

Designs how a failure travels and is reported once it has happened: who handles it, what context it carries, how similar failures look alike, and how the normal path stays readable. Deciding what is invalid on entry is `code-complete-trust-boundaries`; stating internal assumptions is `code-complete-assertions-and-contracts`.

## When to use

- A `catch`, `except` or `if err != nil` block is added, widened or removed.
- A routine returns a code, `null`, an empty value or `false` to mean it failed.
- An error message says only "failed" or "invalid".
- Similar failures are reported in different ways in sibling routines.
- A fallback value is returned when something goes wrong.

## Rules

1. **Handle errors at the right level of abstraction.** Why: the level that can decide is rarely the level that detects. Check: each handler either can do something about the failure or adds context and passes it on in the vocabulary of its own layer (a repository reports "profile unavailable", not a driver code).
2. **Preserve useful context.** Check: a reader of the log or message can tell the operation, the subject and the reason, and the original cause is chained, not discarded.
3. **Do not let error handling dominate the normal path.** Check: remove every handler in your head and a readable sequence of steps remains; wide `try` blocks are replaced by a thin wrapper around a clear routine (`code-complete-routine-design`).
4. **Standardize similar failure handling.** Check: "not found", "invalid" and "unavailable" are reported the same way across the module; a new routine copies the convention of its siblings (`code-complete-coding-standards`).
5. **Prefer explicit, well-understood failure semantics over ad hoc conventions.** Check: each routine's documentation says how it can fail (exception types, error values), and callers do not need to read the body to find out.
6. **Do not silently continue from corrupted or impossible state.** Check: no fallback masks a state the contract calls impossible; the program stops or reports.
7. **Do not swallow exceptions without context.** Source anti-pattern. Check: no empty handler; a handler that logs and continues says why continuing is safe.
8. **Fail in a way that preserves diagnosability.** Check: a failure keeps the operation, location and values needed to diagnose it. Added judgment: raise errors close to their cause rather than converting them into a vague message upstream.
9. **Distinguish recoverable conditions from programming errors.** Check: a recoverable failure is returned or caught by the layer that can recover; a violated assumption is a defect and fails fast (`code-complete-assertions-and-contracts`).
10. Added judgment: log a failure once, at the level that handles it. Logging and rethrowing at every layer produces duplicate entries and hides the real one.
11. Added judgment: pick one failure mechanism per layer, following the language and the repository (exceptions, result values, error returns), and do not mix them in one module without a stated reason.
12. Added judgment: a message must not contain secrets, tokens or personal data; carry identifiers, not payloads.

## Procedure

1. List the failure points in the changed code: calls that can fail, parsing, lookups that can miss, state transitions that can be refused.
2. For each, write who reacts and how. If no one does, the failure is currently swallowed or lets the program continue wrongly.
3. Move low-level details out of the message into the cause chain; translate at layer boundaries.
4. Extract the work from wide handlers so the main routine is the normal path.
5. Align the convention with sibling routines; if no convention exists, choose one and apply it to new code (`code-complete-coding-standards`).
6. Write a test for each distinct reaction path (`code-complete-routine-testing`).

## Example

```ts
// Before: every failure becomes null, the message says nothing, the caller cannot tell "missing" from "database down"
async function loadProfile(id: string): Promise<Profile | null> {
  try {
    const row = await db.query("select * from profiles where id = $1", [id]);
    return toProfile(row);
  } catch (e) {
    console.log("error");
    return null;
  }
}

// After: the failure keeps its cause and speaks the repository layer's language; the normal path is two lines
class ProfileUnavailableError extends Error {
  constructor(readonly profileId: string, options: { cause: unknown }) {
    super(`loadProfile: could not read profile ${profileId}`, options);
    this.name = "ProfileUnavailableError";
  }
}

async function loadProfile(id: string): Promise<Profile> {
  let row;
  try {
    row = await db.query("select * from profiles where id = $1", [id]);
  } catch (cause) {
    throw new ProfileUnavailableError(id, { cause });
  }
  return toProfile(row);
}
```

Callers that relied on `null` now receive an exception. A genuinely expected "no such profile" outcome should be its own, documented result so it is not confused with an outage.

## Anti-patterns

- **Swallowed exception.** An empty `catch` or a log-and-continue. Detect: a handler with no rethrow, return of an error, or comment explaining why it is safe.
- **Message with no context.** `"error"`, `"invalid input"`. Detect: a message that does not contain the operation or the subject.
- **Catch-all at the wrong level.** `catch (Exception e)` deep in a utility. Detect: a broad handler in a routine that cannot recover.
- **Error code lottery.** Some routines return `-1`, others throw, others return `null`. Detect: three conventions in one module.
- **Handler-dominated routine.** Half the body is `try`, `catch` and cleanup. Detect: the normal steps cannot be read without scrolling past handlers.
- **Masking fallback.** `?? defaultValue` on a result that should never be missing. Detect: a default on a value the contract says is always present.

## Trade-offs and exceptions

- The source says to standardize and to prefer explicit semantics; it does not mandate exceptions over result values. Use the idiom of the language and the repository.
- Some code legitimately continues after a failure (a batch job processing independent items). Then continuing is the policy: record each failure with context and report the count, rather than hiding them.
- Retrying, timeouts and circuit breaking are production-reliability policies that the book's rule set does not prescribe; if you need them, that is the job of a `release-it` plugin.
- Translating errors at every layer adds code. Translate where the vocabulary changes (data access to domain, domain to API), not at every call.

## Verification

- [ ] Every handler in the change either handles, translates with the cause preserved, or reports.
- [ ] No empty or silently continuing handler remains.
- [ ] Messages carry the operation, the subject and the reason, and no secrets.
- [ ] Sibling routines fail in the same way for the same kind of failure.
- [ ] Removing the handlers leaves a readable normal path.
- [ ] Each distinct reaction path has a test.

## Related

`code-complete-trust-boundaries` for what counts as invalid input; `code-complete-assertions-and-contracts` for programmer errors; `code-complete-coding-standards` for matching a convention; `code-complete-error-flow-reviewer` to review a diff.

## Source

- `Error Handling Rules`
- `Defensive Programming Rules`: only the rules on diagnosable failure, not continuing from impossible state, and swallowed exceptions.
- `Defensive Vacuum`: only the entry on silent fallback from impossible state.
