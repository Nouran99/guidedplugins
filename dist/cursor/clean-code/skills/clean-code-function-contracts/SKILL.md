---
name: "clean-code-function-contracts"
description: "Use when a function takes many parameters, a boolean flag or an output argument, writes state while answering a question, or must be called in a hidden order. Judges signatures and declared effects, not the body (clean-code-function-shape) or behavior against the name (clean-code-smells-surprise)."
license: "MIT"
metadata:
  plugin: "clean-code"
  book: "Clean Code"
  invocation: "auto"
---

# Function contracts

Judges what crosses a function boundary: what goes in, what comes out, and what changes besides the return value. Length, nesting and abstraction levels are `clean-code-function-shape`. Failure behavior is `clean-code-error-handling`.

## When to use

- A signature has more than two or three parameters, or a call site reads `render(page, true, false)`.
- A function named like a question (`isValid`, `getSession`, `checkPassword`) writes somewhere.
- A caller must remember to call `init()` before `run()` or the second call silently misbehaves.
- An argument is modified by the callee and the caller reads it afterwards.

## Rules

1. **Minimize the number of parameters.** Fewer arguments mean fewer call-site mistakes and easier tests. Check: count them; if three or more travel together through several signatures, they are a concept without a name. Added judgment: zero to two is the comfortable range, three needs a reason.
2. **Avoid boolean flag parameters; split the behavior into separate functions.** A flag announces that the function does two things. Check: call sites pass literal `true` or `false`, or the body starts with `if (flag) {...} else {...}`.
3. **Avoid output parameters unless language conventions make them necessary.** Results go out through the return value. Check: no argument is assigned or mutated inside the callee for the caller's benefit. Conventions such as a `TryParse`-style `out` or a Go `(value, ok)` pair are part of the language, not output parameters in this sense.
4. **Model grab-bag argument lists as a concept (compact checklist: `mini.md` only; the full rules say only to minimize the number of parameters).** When the same group of values appears in several signatures, give the group a type with a name and, if it has rules, validation. Check: the same three parameter names recur in two or more signatures.
5. **Eliminate hidden side effects.** What a function changes must be visible from its name and signature. Check: search the body for writes to fields, globals, caches, files, the clock or the network that the name does not mention.
6. **Separate commands from queries.** A function either changes state or answers a question, not both. A function that answers should not also mutate state. Check: every function can be labeled "command" or "query"; a function that needs both labels is a finding.
7. **Do not mix querying with mutation without a strong reason.** Strong reasons exist and should be written down: an atomic compare-and-set, `INSERT ... RETURNING`, or a pop on a concurrent queue cannot be split without a race. Check: the function has a comment naming the atomicity or concurrency reason.
8. **Make logical dependencies on call order explicit.** If `finalize()` is only valid after `load()`, make the second take the output of the first, or have one function own both. Check: no call sequence exists that compiles but fails at runtime.
9. **Name the effect when it cannot be removed.** A function that may create what it asks for is `getOrCreateSession`, not `getSession`. Check: the verb in the name matches every effect found in the body.
10. **Prefer returning a new value to mutating an input.** Added judgment, following from rules 3 and 5: a changed argument is a side effect the signature does not show. Check: parameters are treated as read-only in the body; collections passed in are copied before change.

## Procedure

1. List the signatures in the touched code. For each, label it command, query or mixed.
2. For mixed ones, decide whether the mixing is an atomicity requirement (rule 7). If not, split.
3. For each flag, find all call sites. If every caller passes a literal, create two named functions and make the old one a thin wrapper until callers are migrated, then delete it.
4. For repeated parameter groups, introduce the type at the boundary where the values first appear together, then thread it inward one call site at a time.
5. For order dependencies, change the signature so the data flow enforces the order.
6. Run the tests after each signature change.

## Example

```ts
// Before: a flag selects behavior, and the "next" function mutates when not peeking
function nextTicketNumber(queue: TicketQueue, peek: boolean): number {
  if (peek) return queue.lastIssued + 1;
  queue.lastIssued += 1;
  return queue.lastIssued;
}
const upcoming = nextTicketNumber(queue, true);
const mine = nextTicketNumber(queue, false);

// After: one query, one command
function peekNextTicketNumber(queue: TicketQueue): number {
  return queue.lastIssued + 1;
}
function issueTicketNumber(queue: TicketQueue): number {
  queue.lastIssued += 1;
  return queue.lastIssued;
}
const upcoming = peekNextTicketNumber(queue);
const mine = issueTicketNumber(queue);
```

`issueTicketNumber` still returns a value and mutates; that is acceptable only if issuing and reading must be atomic. If they need not be, return nothing and read the counter separately.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Boolean control flag | Literal `true`/`false` at call sites; body forks on the parameter | Two named functions |
| Long parameter list | Four or more parameters, or positional values of the same type | Argument object with a name, or split the function |
| Output argument | Callee assigns into a parameter the caller reads later | Return the value (or a small result type) |
| Mutating query | Name starts with `is`, `get`, `has`, `check`; body writes state | Split into query plus command, or rename to disclose the effect |
| Hidden order dependency | Method that fails unless another was called earlier | Pass the earlier result in, or merge the steps |
| Disguised side effect | A function named `validate` that also normalizes or saves | Do one, or rename; surface the other effect at the caller |

## Trade-offs and exceptions

- Booleans are fine where they are the data (`enabled`) rather than a switch for behavior.
- Language conventions for result-plus-status returns, builders and callbacks are not flagged as output parameters.
- Splitting a flag into two functions can duplicate code; extract the shared part so duplication does not replace the flag.
- Atomic operations are the main legitimate command/query hybrid; do not "fix" them into a race.
- Public API signature changes are breaking changes. Keep the old signature as a wrapper and migrate callers in a separate step.

## Verification

- [ ] Every touched function can be labeled command or query, or has a written atomicity reason.
- [ ] No call site passes a literal boolean to select behavior.
- [ ] No parameter is mutated for the caller's benefit.
- [ ] Parameter groups that travel together now have a name.
- [ ] No valid-looking call sequence fails because of an order the signature does not enforce.
- [ ] The tests pass after each signature change.

## Related

`clean-code-function-shape` for the body; `clean-code-smells-surprise` when an effect surprises callers in other ways; `clean-code-naming` for effect-disclosing names; `clean-code-contract-reviewer` to review a diff.

## Source

- `Function rules`
- `Hard rules`: only the rule against mixing querying with mutation.
- `Smells to detect and eliminate`: only the hidden side effect, boolean control flag, long parameter list and hidden logical dependency smells.
