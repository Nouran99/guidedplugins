---
name: smells-surprise
description: "Use when code does not do the obvious thing its name promises, edge inputs behave wrongly, checks are disabled or suppressed, or behavior depends on hidden defaults and magic. Smell family for surprising behavior, boundaries and overridden safeties."
---

# Surprise smells

The general-design family about code that behaves differently from what a reader expects: unimplemented obvious behavior, wrong behavior at the boundaries, and safeties that someone switched off. Structural smells are `/clean-code:smells-redundancy` and `/clean-code:smells-coupling`; the hidden effects of a function are `/clean-code:function-contracts`.

## When to use

- A function handles the main case but not the case any caller would try next (lowercase input, trailing whitespace, empty list, zero).
- An off-by-one, inclusive versus exclusive end, or time-zone bug is reported.
- You see `@SuppressWarnings`, `eslint-disable`, `# type: ignore`, `--no-verify`, `unsafe`, a broad cast, or a test skipped to get green.
- Behavior depends on a default nobody states: locale, time zone, encoding, timeout, ordering.
- A magic mechanism (reflection, monkey-patching, auto-wiring by name, implicit conversion) makes the flow impossible to follow by reading.

## Rules

1. **Avoid surprising behavior.** The behavior a name, a type and nearby code promise is the behavior the function delivers. Check: write down what a reasonable caller would expect from the name; the code does that.
2. **Implement the obvious behavior or fail loudly.** If a case is unsupported, say so with a specific error instead of a wrong or default result. Check: every input class a caller would plausibly try either works or raises a precise error.
3. **Get boundary behavior right and tested.** Boundaries are where correct-looking code is wrong: empty, one, many, first, last, equal to the limit, one past it, negative, null, overflow, and, for dates, month ends, daylight-saving shifts and time zones. Check: the code and a test agree on whether each end is inclusive.
4. **Eliminate overridden safeties in the code you touch.** Compiler warnings, linters, type checks, assertions, validation and hooks exist to catch mistakes, and switching one off is a smell to remove. Check: no blanket suppression remains in the touched code. Added judgment: where a suppression is genuinely required, keep it to the narrowest scope and give the reason in a comment of the kind `/clean-code:comments` allows.
5. **Prefer explicit intent over implicit magic.** A reader should be able to see why something happens. Check: behavior that arises from names, annotations, reflection or global patches is documented where it takes effect, or replaced with an explicit call.
6. **State defaults at the boundary.** Added judgment, following from explicit intent: time zone, locale, encoding, timeouts and sort order are chosen on purpose and stated. Check: the code does not depend on the machine's environment for any of these.
7. **Keep state transitions obvious.** Every change of state is a named operation with a visible trigger. Check: you can list the legal transitions of the touched object.
8. **Make hidden ambient inputs explicit.** Current time, environment variables and global configuration read mid-function make results depend on the world. Check: they enter through a parameter, a constructor argument or a small provider.
9. **Treat the surprise as the bug, not the documentation.** If the right fix is to change behavior, do that rather than writing a warning. Check: a comment that says "note: this actually does X" is a prompt to change the code (see `/clean-code:comments`).

## Procedure

1. List the public functions in the touched code. For each, state the reasonable expectation from its name and types.
2. Try the four nearest inputs: empty, one, the limit, one past the limit. Try the obvious variants: case, whitespace, sign, unicode where relevant.
3. Compare results with expectations. Every difference is a finding: fix it, or make the function reject the input explicitly.
4. Search the touched files for suppressions and disabled checks. For each, confirm scope, reason and that the underlying warning is not real.
5. Find hidden inputs (time, environment, locale) and make them explicit.
6. Add tests on both sides of every boundary you touched.

## Example

```python
# Before: the check-out day is counted as a night, and a reversed range returns a plausible number
def nights(check_in: date, check_out: date) -> int:
    return (check_out - check_in).days + 1

# 2025-03-03 to 2025-03-04 -> 2 (wrong, one night); 03-03 to 03-03 -> 1 (no stay at all)

# After: the boundary is defined (check-out day is not a night) and bad ranges fail loudly
def nights(check_in: date, check_out: date) -> int:
    if check_out <= check_in:
        raise ValueError(f"nights: check_out {check_out} must be after check_in {check_in}")
    return (check_out - check_in).days

def test_one_night_stay():
    assert nights(date(2025, 3, 3), date(2025, 3, 4)) == 1

def test_same_day_range_is_rejected():
    with pytest.raises(ValueError):
        nights(date(2025, 3, 3), date(2025, 3, 3))
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Unimplemented obvious case | Main path works; sibling input returns default, `None`, or throws a generic error | Implement it, or raise a specific error |
| Off-by-one | Comparisons with `<`/`<=` near limits; integer division of counts; loop bounds | Test both sides of the edge; define inclusivity |
| Blanket suppression | File-wide `eslint-disable`, `@SuppressWarnings("all")`, global `# type: ignore` | Narrow to the line, explain, or fix the warning |
| Disabled check | `--no-verify`, `skip` on a failing test, assertion removed to pass | Restore; fix the cause |
| Silent default | Fallback value used on any error | Fail loudly, or log and surface |
| Environment-sensitive result | Uses machine time zone, locale or encoding | State explicitly |
| Magic wiring | Behavior comes from a naming convention or a patch applied elsewhere | Make it explicit or document at the effect site |
| Time bomb | Code that works only until a date, a size or a count | Make the limit explicit and tested |

## Trade-offs and exceptions

- "Obvious" is relative to the audience; consult neighboring code and the domain, and do not invent features. Implementing every conceivable input is gold plating, which the book warns against; fail loudly for the rest.
- Added judgment: some safeties are wrong for a given case (a lint rule that cannot understand generated code). A narrow suppression with a reason is the right answer there, not a ban.
- Frameworks rely on conventions and annotations by design. Follow them, and keep your own code from adding more magic.
- Do not change behavior silently to remove a surprise that callers depend on; treat it as a behavior change with tests and a note.

## Verification

- [ ] Each touched public function behaves as its name and types suggest for the obvious inputs.
- [ ] Both sides of each touched boundary have a test, and inclusivity is explicit.
- [ ] No new suppression is broader than one line, and each has a reason.
- [ ] No check, hook or test was disabled to make the change pass.
- [ ] Defaults and ambient inputs are stated or injected.
- [ ] Unsupported inputs raise a specific error.

## Related

`/clean-code:tdd-discipline` for boundary tests; `/clean-code:function-contracts` for hidden effects; `/clean-code:error-handling` for failure design; `clean-code:contract-reviewer` to review a diff.

## Source

- `Smells to detect and eliminate`: the unimplemented obvious behavior, incorrect boundary behavior and overridden safety smells.
- `Core clean code principles`: the rules against surprising behavior and implicit magic.
- `Implementation preferences`: only the rule to keep state transitions obvious.
