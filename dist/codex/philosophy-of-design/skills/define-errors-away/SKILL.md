---
name: "define-errors-away"
description: "Use when adding validation, try/catch, null checks or error codes, or when many callers repeat the same defensive handling. Redesigns the interface or invariant so the exception case does not exist, instead of adding more checks."
---

# Define errors away

Reduces the number of exceptional cases an interface exposes by changing what the operation means, not by adding more checks around it. Rare but valid behavior that clutters the main path is `$philosophy-of-design:generality-and-special-cases`; the reliability policy for production dependencies (timeouts, retries) is outside this rule set.

## When to use

- Every caller wraps the same call in the same `try`/`catch` or null check.
- An operation throws for an input that the caller would have been happy to see handled quietly.
- Objects can exist in a half-initialized state and callers must "tiptoe".
- A new exception type or error code is proposed for a case that has an obvious harmless result.

## Rules

1. **Define APIs that make misuse hard.** Types, required constructor arguments and narrower parameters beat documentation. Check: the wrong call does not compile, or cannot be expressed.
2. **Define away invalid states and awkward cases where possible.** Check: for each invalid state, ask whether the design can make it unrepresentable or give it a defined harmless meaning.
3. **Eliminate exception cases by changing the interface or invariant, not only by adding more checks.** Check: the diff reduces the number of ways an operation can fail instead of adding a guard.
4. **Use special/general decomposition when unusual cases clutter the main abstraction.** Check: see `$philosophy-of-design:generality-and-special-cases`.
5. **Keep the normal path obvious and the exceptional path isolated.** Check: the success flow reads without the handling code.
6. **Do not make APIs that require every caller to repeat defensive ceremony.** Check: the same guard or `catch` appears at more than one call site.
7. **Do not scatter "special case" branches across many call sites.** Check: the same condition is tested before many calls to one operation.
8. **Do not expose half-valid objects and ask callers to tiptoe around them.** Check: no method that throws "not initialized" or "call setup first".
9. **Added judgment: write the postcondition the caller wanted.** If the postcondition already holds in the "error" case (removing something absent, creating something that exists, clamping an out-of-range index), the case is not an error; define the operation by its postcondition. Check: each `throw` is paired with a sentence stating what the caller needed true afterwards.
10. **Added judgment: three ways to remove an error.** Redefine the operation so the case is a valid no-op; handle the case inside the module so no caller sees it; or give several failure causes one shared handler. Keep a typed, explicit outcome when the caller must act differently (a declined payment, a missing record the user typed).

## Procedure

1. List the raise sites and error returns in the touched code, and the handlers at call sites.
2. For each, write the caller's postcondition (rule 9) and who reacts today.
3. Classify: already true (redefine as no-op); recoverable inside (handle low); shared reaction (one handler); caller must decide (keep a minimal explicit outcome).
4. Change the definition, the contract comment and the implementation. A changed contract is a behavior change: confirm it with the user or owner before applying it to a public API.
5. Delete the callers' defensive code in the same change.
6. Add tests for the new contract, including the case that used to fail.

## Example

```python
# Before: removing an absent tag is an error, so every caller guards it
class TagSet:
    def __init__(self):
        self._tags = set()

    def remove(self, tag):
        if tag not in self._tags:
            raise KeyError(tag)
        self._tags.remove(tag)

# at several call sites
try:
    tags.remove("draft")
except KeyError:
    pass

# After: the operation is defined by its postcondition
class TagSet:
    def __init__(self):
        self._tags = set()

    def remove(self, tag):
        """Ensure `tag` is absent afterwards. Removing a tag that is not present is not an error."""
        self._tags.discard(tag)

# at every call site
tags.remove("draft")
```

The caller wanted "draft is not in the set"; that was already true, so the failure condition was a property of the old definition, not of the problem.

## Anti-patterns

- **Ceremony at every call site.** The same `try`/`except` or guard repeated. Detect: identical handler code in several files.
- **Half-valid object.** Construct, then configure, then use. Detect: methods guarded by "if not initialized".
- **Error as ordinary control flow.** Exceptions for outcomes that happen routinely. Detect: `catch` blocks that are part of the normal algorithm.
- **Validation spread.** The same input rule checked by every caller. Detect: the same regex or range test in several modules (move it to the owner).
- **Silent swallowing.** Defining an error away by ignoring a real failure. Detect: an empty `catch` with no postcondition that justifies it.

## Trade-offs and exceptions

- Do not define away information a caller needs to act: a declined payment, a lookup the user typed that found nothing, data corruption. Keep an explicit, typed outcome (rule 10).
- Integrity and security failures must stay visible; masking them hides bugs (Added judgment).
- Changing what an operation means changes behavior. Public APIs need versioning or a new operation name rather than a silent change.
- Resource and I/O failures cannot be wished away; handle them low in the module that owns the resource so callers stay free of them.

## Verification

- [ ] Each remaining error case has a stated reason the caller must act on it.
- [ ] Defensive code at call sites was deleted in the same change.
- [ ] The contract comment states the postcondition, including the former error case.
- [ ] No half-valid object remains in the touched code.
- [ ] A test covers the case that used to throw.

## Related

`$philosophy-of-design:generality-and-special-cases`; `$philosophy-of-design:pull-complexity-down`; `$philosophy-of-design:comments-as-design` for stating the contract; `philosophy-of-design-exception-reviewer` to review; `$philosophy-of-design:fix` to apply a confirmed change.

## Source

- `Error Handling and Exception Elimination`
