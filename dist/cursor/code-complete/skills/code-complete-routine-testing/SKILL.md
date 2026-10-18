---
name: "code-complete-routine-testing"
description: "Use when writing or reviewing tests for a routine: normal, boundary and invalid inputs, defensive checks, contract alignment, table-driven cases. A failure of unknown cause: code-complete-debugging."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Routine testing

Designs and judges tests at the level of a routine: which inputs, which boundaries, which invalid cases, which defensive checks, and whether the tests verify the contract rather than the implementation. Diagnosing a failing test or a reported bug is `code-complete-debugging`; deriving the case list as a table is `code-complete-test-matrix`.

## When to use

- You are adding or changing a routine and need its tests.
- A test file covers only the happy path.
- A routine validates input or asserts conditions and nothing tests the rejection.
- A table-driven routine has tests for one or two rows.
- A test breaks whenever the implementation is refactored although behavior did not change.

## Rules

1. **Test routine behavior around normal, boundary and invalid inputs.** Why: defects cluster at the edges and at inputs the author did not plan for. Check: for each routine there is at least one typical case, the cases at and next to every boundary, and the inputs the contract excludes.
2. **Test defensive checks where boundary validation matters.** Check: each validation rule has a test with an input that violates it and a test that the error is the specified one (`code-complete-trust-boundaries`).
3. **Keep tests aligned with routine contracts.** Why: tests for the contract survive a rewrite; tests for the implementation do not. Check: each assertion follows from a stated postcondition, and swapping the algorithm without changing the contract keeps the tests green (`code-complete-assertions-and-contracts`).
4. **Test complex data-driven logic with representative tables and edge cases.** Check: for a table or range mapping, every category is exercised, each range boundary is tested on both sides, and the missing-key case is covered (`code-complete-table-driven`).
5. **Do not rely on happy-path tests alone.** Compact rule from the trigger on tests that prove only happy paths. Check: the number of tests for failure and boundary behavior is not zero for any routine that has them.
6. **Match test effort to defect risk.** Source guidance on risk-matched quality practices. Check: the riskiest routines (money, parsing, state transitions, boundaries) have the most cases; a trivial accessor does not need a table.
7. **Add tests around defects.** Check: every fixed bug leaves a test that failed before the fix (`code-complete-debugging`).
8. Added judgment: the standard boundary set for a numeric or sized input is: below the minimum, the minimum, a typical value, the maximum, above the maximum; for collections: empty, one element, many, and the last element.
9. Added judgment: name each test for the scenario and the expected outcome; a failure should be understandable from its name.
10. Added judgment: keep one behavior per test case (or one table row) so a failure points to one cause.
11. Added judgment: never weaken or delete a failing test to make a change pass; if the test is wrong, correct it for a stated reason.

## Procedure

1. Write the routine's contract: what it requires, what it returns or changes, how it fails.
2. List the input classes: normal, each boundary (just below, at, just above), invalid, and any state it depends on.
3. List the defensive checks and the failure each one raises.
4. For mappings and tables, list every key or range and its boundaries.
5. Turn the list into cases (a table in the test file if the language supports it). Run them: confirm each new test can fail by breaking the behavior once.
6. Remove any assertion that only restates the implementation.

## Example

```go
// Contract: weightKg must be positive. Fee in cents by tier; upper bounds inclusive: <=1 kg 500, <=5 kg 900, <=20 kg 1800, above 4000.
func ShippingFeeCents(weightKg float64) (int, error) {
	switch {
	case math.IsNaN(weightKg) || weightKg <= 0:
		return 0, fmt.Errorf("ShippingFeeCents: weight must be positive, got %v", weightKg)
	case weightKg <= 1:
		return 500, nil
	case weightKg <= 5:
		return 900, nil
	case weightKg <= 20:
		return 1800, nil
	default:
		return 4000, nil
	}
}

func TestShippingFeeCents(t *testing.T) {
	cases := []struct {
		name    string
		kg      float64
		want    int
		wantErr bool
	}{
		{"light parcel", 0.1, 500, false},
		{"upper edge of first tier", 1, 500, false},
		{"just over first tier", 1.01, 900, false},
		{"upper edge of second tier", 5, 900, false},
		{"just over second tier", 5.01, 1800, false},
		{"upper edge of third tier", 20, 1800, false},
		{"just over third tier", 20.01, 4000, false},
		{"zero weight is invalid", 0, 0, true},
		{"negative weight is invalid", -3, 0, true},
		{"NaN is invalid", math.NaN(), 0, true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, err := ShippingFeeCents(c.kg)
			if (err != nil) != c.wantErr {
				t.Fatalf("error = %v, wantErr %v", err, c.wantErr)
			}
			if err == nil && got != c.want {
				t.Fatalf("got %d, want %d", got, c.want)
			}
		})
	}
}
```

The cases cover both sides of every tier boundary and every excluded input; none depends on how the tiers are stored.

## Anti-patterns

- **Happy-path suite.** Only typical inputs. Detect: no test name mentions empty, invalid, boundary or error.
- **Implementation mirror.** The test repeats the algorithm to compute the expectation. Detect: the expected value is produced by the same expression as the code under test.
- **Untested guard.** A validation branch no test reaches. Detect: coverage shows the rejection line never runs.
- **Mid-range-only table.** Rows far from the boundaries. Detect: no row sits at or next to a limit.
- **Brittle internals test.** Asserts on private state or call order that the contract does not mention. Detect: a refactor with unchanged behavior turns the test red.
- **Vague name.** `test1`, `testFee`. Detect: you must read the body to know what failed.

## Trade-offs and exceptions

- Exhaustive boundary testing of every routine is not asked for; the source matches effort to risk. Cover the risky routines thoroughly and keep trivial ones light.
- Some defensive checks (assertions that cannot be triggered through the public surface) are covered indirectly; say so rather than breaking encapsulation to reach them.
- Table-driven tests trade readability of each case for compactness; when cases need different setup, separate tests are clearer.
- Floating-point and time inputs have boundaries that depend on the representation; use the project's tolerance and clock conventions instead of exact equality.

## Verification

- [ ] Every routine in the change has normal, boundary and invalid-input cases, or a stated reason.
- [ ] Every validation rule has a violating test.
- [ ] Assertions follow from the contract, not from the implementation.
- [ ] Table-driven logic is tested at every category and both sides of each boundary.
- [ ] Each new test was seen to fail when the behavior was broken.

## Related

`code-complete-test-matrix` to derive the cases first; `code-complete-test-writer` to write them; `code-complete-test-case-reviewer` to review existing tests; `code-complete-debugging` for failing tests; `code-complete-assertions-and-contracts` for the contract itself.

## Source

- `Testing Rules`
- `Defensive Programming Rules`: only the rule that boundary validation is a defensive check worth testing.
- `Quality, Collaboration, Debugging, and Refactoring`: only the rules to match practices to risk and to add tests around defects.
