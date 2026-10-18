---
name: "contracts"
description: "Use when a routine's assumptions live in comments or caller folklore, when adding assertions, preconditions, postconditions or invariants, or when impossible states return nonsense values. Defines the obligations; how failures travel is `$pragmatic-programmer:error-recovery`; comments and names are `$pragmatic-programmer:code-communication`."
---

# Contracts and assertions

Make what a routine expects and promises explicit in code, close to the abstraction that depends on it. This skill defines the obligations and where they are enforced. How a failure that has already happened travels, what context survives and where it is contained belong to `$pragmatic-programmer:error-recovery`.

## When to use

- A precondition is described in a comment ("callers must pass a non-empty list") and enforced nowhere.
- Several callers each check the same assumption before calling, or none do.
- A function returns `-1`, an empty string, `None` or an empty collection for a state that should never occur.
- You are adding an assertion, a validation step or a type to pin down an assumption.
- A bug turned out to be a caller and a callee disagreeing about who checks what.

## Rules

1. **Make assumptions explicit in code.** [MUST] Check: each assumption a routine relies on is visible in a check, a type or a test, not only in a comment.
2. **Use assertions or invariant checks where they clarify impossible states.** [MUST] Check: a state the design says cannot happen fails immediately and says which invariant broke.
3. **Distinguish programmer errors, contract violations and expected domain failures.** [MUST] Added judgment on the working mapping: a programmer error is a bug inside the owner (a postcondition or invariant fails) and ends in an assertion with a diagnostic; a contract violation is a caller breaking a stated precondition and is rejected at the boundary with a named error; an expected domain failure is a valid request with a business "no" and belongs in the normal result. Check: each check in the touched code falls into exactly one class.
4. **Keep contracts close to the abstraction they protect.** [MUST] Check: the check lives in the owner's constructor or method entry, not in each caller.
5. **Do not rely on comments for critical preconditions.** [MUST NOT] Check: any comment that begins "callers must" has a matching check or type.
6. **Do not hide invariant assumptions in scattered callers.** [MUST NOT] Check: removing one caller's defensive check does not change what the abstraction accepts.
7. **Do not return nonsense values for impossible states.** [MUST NOT] Check: no `-1`, empty string, `None` or empty list stands for "this cannot happen".
8. **Move hidden assumptions out of comments, caller folklore and setup rituals into code, contracts, tests, scripts or checked configuration.** [Compact checklist] Check: a new maintainer cannot violate an assumption without a failure that names it.
9. **State each contract as precondition, postcondition and invariant.** [Added judgment] The precondition is the caller's obligation, the postcondition is the callee's promise, the invariant holds between calls. Check: you can write each of the three for the routine in one line.
10. **Do not use assertions to validate external input.** [Added judgment] In several languages assertions can be disabled (Python with `-O`, Java unless enabled). Check: input from users, files and networks is validated with ordinary checks that raise.
11. **Prefer a type that cannot hold the bad value.** [Added judgment] A non-empty list type, an enum or a parsed value object turns a runtime check into a compile-time or construction-time fact. Check: a check that appears in many routines has become a type.
12. **Test the edges of the contract.** [Added judgment] Check: tests include the smallest and largest valid input and the first invalid one.

## Procedure

1. For each routine in the change, write its precondition, postcondition and invariant in one line each.
2. Find where each is checked today: in the routine, in callers, nowhere, or only in a comment.
3. Classify each check as programmer error, contract violation or expected domain failure (rule 3).
4. Move the check to the owner. Use an assertion for programmer errors, a named error for violations, a result value for domain failures.
5. Replace nonsense returns with the right class of outcome.
6. Add tests at the edges of the contract; run the tests.

## Example

```python
# Before: the contract lives in a comment; the impossible case returns a nonsense value; the remainder is lost
def split_evenly(total_cents, parts):
    # parts must be positive, total_cents must be >= 0 (callers know this)
    if parts <= 0:
        return []
    share = total_cents // parts
    return [share] * parts            # sum(shares) != total_cents when there is a remainder

# After: the obligations are checked at the owner, the promise is asserted
def split_evenly(total_cents: int, parts: int) -> list[int]:
    """Split total_cents into `parts` shares that differ by at most one cent and sum to total_cents.

    Precondition (caller): parts >= 1 and total_cents >= 0.
    Postcondition (this function): len(result) == parts and sum(result) == total_cents.
    """
    if parts < 1 or total_cents < 0:
        raise ValueError(
            f"split_evenly: need parts >= 1 and total_cents >= 0, got parts={parts}, total_cents={total_cents}")
    base, extra = divmod(total_cents, parts)
    shares = [base + 1 if i < extra else base for i in range(parts)]
    assert len(shares) == parts and sum(shares) == total_cents, "split_evenly: postcondition violated"
    return shares
```

The caller's mistake is a contract violation and raises a named error with the offending values. A failure of the assertion would be a bug in `split_evenly` itself. No caller needs its own defensive check.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Comment-only precondition | "must", "callers should" or "never call with" in a docstring with no check | Enforce at the owner |
| Nonsense sentinel | `-1`, `""`, `None` or `[]` returned for an impossible state | Raise, or return a result that models the case |
| Scattered defense | The same guard repeated before every call | Move it into the callee |
| Assertion as input validation | `assert` on a request body or file contents | Ordinary validation that raises |
| Silent "can't happen" | An `else` branch that logs and carries on | Fail with the broken invariant named |
| Vague failure | `ValueError("invalid")` | State the rule and the offending values |

## Trade-offs and exceptions

- The source asks for assertions "where they clarify impossible states", not everywhere. Added judgment: put contracts on shared abstractions and public routines first; private helpers inherit their caller's guarantees.
- Costly invariants on hot paths may be checked only in debug or test builds, and the choice should be written down (Added judgment).
- A domain "no" such as insufficient funds is not a contract violation and must not be modeled as one.
- Where a type system can express the contract, use it (rule 11); a runtime check is the fallback.
- Whether an assertion failure ends the process or is contained at a boundary is a decision for `$pragmatic-programmer:error-recovery`.

## Verification

- [ ] Each assumption the changed routines rely on is checked in code, not only described.
- [ ] Every check is classified as programmer error, contract violation or domain failure.
- [ ] No impossible state returns a nonsense value.
- [ ] No assertion guards external input.
- [ ] The edges of each contract are tested.

## Related

`pragmatic-programmer-contract-reviewer` to review a diff; `pragmatic-programmer-contract-writer` to encode assumptions; `$pragmatic-programmer:error-recovery` for how failures travel; `$pragmatic-programmer:shy-code` for call-order requirements; `$pragmatic-programmer:code-communication` for what still belongs in a comment.

## Source

- `Design by Contract and Assertions`
- `Review Rules`: only the instruction to look for unclear contracts or assumptions.
- `Code Generation Rules`: only the default of explicit contracts and assumptions.
