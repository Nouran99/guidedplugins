---
name: "legacy-code-characterization-tests"
description: "Use when current behavior is uncertain and must be captured before a change: pinning actual outputs, ugly behavior consumers rely on, suspicious results, probes. New-requirement tests are `legacy-code-focused-tests`; where to test is `legacy-code-test-points`; the order of work is `legacy-code-legacy-loop`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Characterization tests

A characterization test records what the code does today, whether or not that is right, so a later change can be checked against it. This skill covers pinning current behavior. Deciding the level and speed of tests, and writing tests for the new requirement, is `legacy-code-focused-tests`; choosing where to observe is `legacy-code-test-points`.

## When to use

- You do not know whether a branch, a rounding rule or an error case is intentional.
- Real callers may depend on behavior that looks wrong.
- You must change a function and nothing trustworthy would fail if you broke it.
- A path is hard to prove, and you need some explicit way to observe that a test reaches it.

## Rules

1. **Use characterization tests when you do not yet know whether the current behavior is intentional.** [MUST] Check: for each pinned case you can say "this is what it does", and you did not write "this is what it should do".
2. **When current behavior is uncertain, capture it before you redesign.** [MUST] Check: the pins exist and pass before the first structural edit.
3. **Test externally visible behavior first.** [MUST] Return values, written output, raised errors and observable effects come before internal fields. Check: the first pins call the public entry point and assert on its results.
4. **Prefer narrow tests around the slice you are about to modify.** [SHOULD] Check: the pins exercise the branches and inputs the change touches, not the whole module.
5. **Capture ugly behavior if real consumers rely on it.** [MUST] Check: for each pin that looks wrong, you looked for callers or consumers before deciding whether to keep it.
6. **Mark suspicious current behavior for clarification instead of silently "fixing" it during characterization.** [MUST] Check: every surprising result has a marker in the test and an entry in your report; no production line changed because of it.
7. **Once behavior is protected, improve structure safely.** [MUST] Check: the structure change comes after the pins and runs against them.
8. **Use sensing variables or temporary probes only to confirm that a test reaches the intended path, and remove them after use.** [MUST] Check: a search for your probe names in production code finds nothing.
9. **Do not change legacy code with no tests or observation strategy, and do not make large edits with no characterization.** [MUST NOT] Relying on manual reasoning alone for risky behavior is the same failure. Check: the plan names the observation strategy for every risky edit.
10. **When a path is hard to prove, add an explicit observation path before changing semantics.** [Compact checklist] Check: you can show that the test fails if the path is not taken.
11. **Let the code tell you the expected value.** [Added judgment] Write the assertion, run it, read the actual result, then record that result as the expectation and label the test as characterized. Check: no expected value came from your reading of the code alone.
12. **Make output repeatable before you pin it.** [Added judgment] A value that depends on the clock, randomness or the environment cannot be pinned; route to `legacy-code-hidden-inputs` first. Check: running the pin twice gives the same result.
13. **Choose inputs by the code's own boundaries.** [Added judgment] Include the value on each side of every condition the change touches, an empty or zero case, and one case per error path. Check: each condition in the slice has a pin on both sides.
14. **Name pins by the behavior they record.** [Added judgment] "returns 0 for zero weight even when express" tells the next reader what to question. Check: no pin is named `test1` or `works`.

## Procedure

1. Pick the slice: the function or branch the change touches. Find its externally visible entry point.
2. List the inputs from rule 13. Run the code with each, with a throwaway script or test, and write down the actual results.
3. Write one test per recorded behavior. Mark suspicious results with a marker comment (for example `CHARACTERIZATION: unclear if intended`) and a one-line question.
4. Confirm each pin reaches the path you meant. Added judgment: temporarily alter the line the pin should exercise, or add a probe, watch the pin fail, then undo the alteration by hand; leave nothing behind (rule 8).
5. Run the pins; they must pass against unchanged code.
6. If the code cannot be called in a test, stop and hand the barrier to `/legacy-code:find-seam`. Do not change production code to make a pin possible inside this skill.

## Example

```python
# legacy: billing/shipping.py (unchanged)
def shipping_cents(weight_kg, country, express):
    base = 500
    if weight_kg > 2:
        base += int((weight_kg - 2) * 120)
    if country != "DE":
        base += 900
    if express:
        base = base * 2
    if weight_kg == 0:
        base = 0
    return base
```

```python
# tests/test_shipping_characterization.py
import pytest
from billing.shipping import shipping_cents

@pytest.mark.parametrize("weight, country, express, expected", [
    (1.0, "DE", False, 500),    # under the 2 kg threshold
    (2.0, "DE", False, 500),    # exactly 2 kg: the surcharge starts above it
    (2.5, "DE", False, 560),    # 0.5 kg over: int(0.5 * 120) = 60
    (3.75, "DE", False, 710),   # 1.75 kg over: 210
    (1.0, "FR", False, 1400),   # outside DE adds 900
    (1.0, "FR", True, 2800),    # express doubles the surcharge too
])
def test_shipping_cents_current_behavior(weight, country, express, expected):
    assert shipping_cents(weight, country, express) == expected

def test_zero_weight_ships_free_even_express_abroad():
    # CHARACTERIZATION: unclear if intended. Ask the owner before changing.
    assert shipping_cents(0, "FR", True) == 0
```

Every expected value was obtained by running the function, not by reading the intent. The zero-weight case is pinned and marked, not fixed.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Idealized assertion | The expected value contradicts the output and the test "fails, so fix the code" | Record the actual value, mark it, ask |
| Silent fix | A production line changed in the same diff that adds the pins | Revert it; make it a separate, tested change |
| Leftover probe | Print statements, counters or flags in production code from a pin session | Remove; search for the probe name |
| Mirror test | The test recomputes the answer with the same formula as the code | Pin concrete values from a run |
| Characterize everything | Pins for branches the change never touches | Narrow to the slice |
| Unstable pin | Passes today, fails after midnight or on another machine | Fix repeatability first (`legacy-code-hidden-inputs`) |

## Trade-offs and exceptions

- Ugly behavior is captured only if real consumers rely on it; if nobody does, it is still marked and reported, and changed only as a deliberate, separately tested change.
- Where a written requirement defines the behavior, write a normal test against the requirement instead of a characterization.
- Characterization proves the code still does what it did; it does not prove the behavior is right. Say so in the report.
- Added judgment: if getting a code path under test needs invasive change, accept a broader pin at a higher level first (see `legacy-code-test-points`) and narrow it later.

## Verification

- [ ] Every pinned value came from a run.
- [ ] Suspicious results are marked in the test and listed in the report.
- [ ] The pins pass against unchanged production code.
- [ ] No probe or sensing variable remains in production code.
- [ ] No production behavior changed in the same step.
- [ ] Each condition in the slice has a pin on each side.

## Related

`/legacy-code:characterize` for the workflow on one target; `legacy-code-characterization-writer` for an unattended batch; `legacy-code-protection-reviewer` to check honesty; `legacy-code-hidden-inputs` when output is not repeatable; `/legacy-code:find-seam` when the code cannot be called.

## Source

- `Characterization Tests`
- `Testing Strategy Rules`
- `Non-Negotiable Rules`: only the rule to characterize before you redesign.
- `No-Safety Change`
- `Testing Rules`: only the rule to use characterization tests to lock current behavior before deeper edits.
