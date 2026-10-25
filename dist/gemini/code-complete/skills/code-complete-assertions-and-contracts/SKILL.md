---
name: "code-complete-assertions-and-contracts"
description: "Use when a routine relies on assumptions about inputs, state or results: write preconditions, postconditions, invariants; choose assertion, validation or domain error. External input: code-complete-trust-boundaries. Expected failures: code-complete-error-handling."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Assertions and contracts

Makes the assumptions between your own routines explicit and chooses how each one is enforced: an assertion for a programmer mistake, validation for external input, a domain error for an expected business failure. Data that arrives from outside is `code-complete-trust-boundaries`; how an error is propagated is `code-complete-error-handling`.

## When to use

- A routine only works if its caller did something first, and nothing says so.
- A class has a rule that must always hold (a balance never negative, a list always sorted) and several methods can break it.
- A result is computed by a long routine and nobody checks it is in range before it is used.
- A `default` branch, an `else` or a "can't happen" comment guards a state that is supposed to be impossible.
- You are deciding between `assert`, an exception for bad input, and a returned business error.

## Rules

1. **Be explicit about routine assumptions.** Why: an assumption nobody wrote down is violated by the next caller. Check: for each changed routine you can state its preconditions (what the caller must guarantee), postconditions (what it guarantees back) and any invariant it relies on.
2. **Encode important invariants close to the code they protect.** Why: a check far from the data it guards is easy to bypass. Check: an invariant of a type is enforced in its constructor and mutators, not in each caller.
3. **Keep contracts simple and testable.** Why: a condition nobody can state in a line or test is wishful. Check: each contract is a short predicate, and a test exists that makes it hold and one that violates it where the violation is observable.
4. **Use assertions for programmer mistakes, validation for external input, and domain errors for expected business failures.** Check: for every check ask "can a correct program ever see this?" If yes, it is not an assertion.
5. **Use assertions or invariant checks where programmer assumptions matter.** Check: assumptions after a complex computation, at the end of a state transition, and on a branch that is supposed to be unreachable are asserted.
6. **Distinguish recoverable conditions from programming errors.** Check: a recoverable condition is handled or returned; a violated assumption stops the routine with a message that says which assumption failed.
7. **Do not silently continue from corrupted or impossible state.** Check: no "if this ever happens, just return the default" for a state the contract calls impossible.
8. **Make a failed assertion tell you what was assumed.** Added judgment: include the condition and the offending values in the message (`f"percent out of range: {percent}"`).
9. **Do not put required work inside an assertion.** Added judgment: in many languages and build modes assertions can be disabled; a statement that must run (a call, an increment) must not live in one.
10. **Do not assert on external input.** Added judgment: a user can produce any value, so an assertion that "this is valid" turns bad input into a crash and, when disabled, into silent corruption.
11. **Write the contract where callers will see it.** Added judgment: put preconditions and postconditions in the routine's documentation comment, since they are exactly the facts the code cannot express (`code-complete-comments`).

## Procedure

1. For each changed routine, write the contract as three short lines: requires, ensures, keeps (invariants).
2. Classify each requirement: caller's job (assert), external data (validate at the boundary), expected business outcome (domain error).
3. Put the check where it protects the data: constructors and mutators for invariants, the top of the routine for preconditions, the end for postconditions that are cheap to check.
4. Write the message so that it names the assumption and shows the values.
5. Keep the tests aligned with the contract: add a test for the violation where it is observable, and a test that the happy path still passes.
6. Remove "can't happen" fallbacks that return a plausible value; replace them with an assertion or an error.

## Example

```python
# Before: the assumptions live in the caller's head; a bad percent produces a negative price
def apply_discount(price_cents, percent):
    return price_cents - price_cents * percent // 100

# After: contract stated, enforced by assertions for programmer errors, validation kept at the boundary
def apply_discount(price_cents: int, percent: int) -> int:
    """Return price_cents reduced by percent.

    Requires: price_cents >= 0 and 0 <= percent <= 100 (the caller's responsibility).
    Ensures:  0 <= result <= price_cents.
    """
    assert price_cents >= 0, f"price_cents must be >= 0, got {price_cents}"
    assert 0 <= percent <= 100, f"percent out of range: {percent}"
    result = price_cents - price_cents * percent // 100
    assert 0 <= result <= price_cents, f"postcondition broken: {result} for {price_cents}, {percent}"
    return result


def parse_percent(text: str) -> int:
    """Boundary: user input is validated, never asserted."""
    try:
        value = int(text)
    except ValueError:
        raise ValueError(f"percent must be an integer, got {text!r}") from None
    if not 0 <= value <= 100:
        raise ValueError(f"percent must be between 0 and 100, got {value}")
    return value
```

Python removes `assert` statements when run with `-O`; that is why `parse_percent` raises instead of asserting.

## Anti-patterns

- **Unstated precondition.** "Don't call this before `init()`." Detect: a documented or remembered call order with no check.
- **Assertion on user input.** `assert request.age >= 0`. Detect: an assertion whose argument comes from a boundary.
- **Silent fallback.** `else: return 0  # should never happen`. Detect: a comment that says "never" above a normal-looking return.
- **Work in an assertion.** `assert queue.pop() is not None`. Detect: a call with side effects inside the asserted expression.
- **Scattered invariant.** The same range check repeated in each caller of a setter. Detect: duplicated validation of one field across files.
- **Untestable contract.** A postcondition that cannot be checked without redoing the work. Detect: no way to state it as a predicate.

## Trade-offs and exceptions

- Added judgment (the source says nothing about assertion cost): assertions cost time. Keep cheap checks on; move expensive ones (re-sorting to verify order) to tests or debug builds, deciding per routine and saying so.
- Some languages have no assertion facility or compile it out; use the language's invariant mechanism, a dedicated "illegal state" exception, or a type that makes the state unrepresentable (`code-complete-data-types`).
- Library code whose callers you cannot see must validate parameters like a boundary; the line between "caller's job" and "external input" is the same trust question (`code-complete-trust-boundaries`).
- Contracts need to stay simple and testable. Added judgment: a routine whose contract takes a paragraph is usually two routines (`code-complete-routine-design`).

## Verification

- [ ] Each changed routine has stated preconditions, postconditions and relied-on invariants.
- [ ] Every check is classified as assertion, validation or domain error, and the classification matches the source of the data.
- [ ] Invariants are enforced in the type that owns them.
- [ ] No assertion carries required side effects or checks external input.
- [ ] A test exercises at least one violation where the failure is observable.

## Related

`code-complete-trust-boundaries` for external input; `code-complete-error-handling` for expected failures; `code-complete-data-types` for types that make invalid states unrepresentable; `/code-complete:test-matrix` to derive contract-based cases; `code-complete-contract-reviewer` to review a diff; `code-complete-boundary-hardener` to add missing checks.

## Source

- `Construction with Preconditions and Postconditions`
- `Defensive Programming Rules`: only the rules on assertions, recoverable versus programming errors, and silently continuing.
- `Testing Rules`: only the rule to keep tests aligned with routine contracts.
