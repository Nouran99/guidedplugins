---
name: "refactoring-conditionals"
description: "Use when branching inside one function is hard to read: nested if/else, repeated or compound conditions, control flags, a tempting lookup table. Local branch structure and restraint; repetition by kind is variation-and-state, failure branches are error-paths."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "auto"
---

# Conditionals

How to make one function's branching show its intent, and when to leave a conditional alone. If the same type or status is switched on in several places, that is `refactoring-variation-and-state`; failure branches and what they mean are `refactoring-error-paths`; cutting a long function is `refactoring-function-bodies`.

## When to use

- A function has an if/else pyramid, or the normal path is buried inside nesting.
- A condition needs a comment to be understood, or the same test is repeated in sibling branches.
- Several branches end in the same result or share the same trailing code.
- A boolean or loop variable steers later control flow.
- You are tempted to introduce polymorphism or a strategy for one switch.

## Rules

1. **Decompose a conditional to make its intent visible.** Name the condition, and the branch bodies where useful. Check: you can read the branch structure aloud as a sentence.
2. **Consolidate conditional expressions that lead to the same result, and consolidate duplicate fragments that appear in every branch.** Check: the shared result or trailing code appears once.
3. **Replace nested if/else pyramids with guard clauses, extracted predicates or strategies when that reduces branching complexity.** Check: the normal path is at the left margin and exits for special cases come first.
4. **Use Replace Nested Conditional with Guard Clauses when it clarifies the normal path.** Check: after the change, each guard returns exactly what the old else-path produced.
5. **Remove Control Flag when loop or conditional state can be expressed directly.** Check: no boolean is set in one branch only to be tested later.
6. **Use lookup tables for stable mapping logic.** Check: the mapping is data, can be read at a glance, and has no branch with side effects.
7. **Keep explicit conditionals when they are simple and honest.** Check: a single `if` with two short branches is left alone.
8. **Never introduce polymorphism merely to avoid a small local conditional (Never).** Check: the justification for any class split is repetition across the code, not the existence of an `if`.
9. **Use Introduce Assertion when an assumption should be explicit during development.** Check: the assertion states an assumption the code relies on, not input validation that must run in production.
10. **When conditionals grow, decompose intent first, before reaching for polymorphism, state, strategy or a table (compact checklist).** Check: the decomposed version was tried before any structural escalation.
11. **Added judgment: guard clauses are equivalent only if nothing runs after the if/else for both paths.** Code after the original conditional (cleanup, logging, a shared return) must be preserved on every path. Check: trace each original path to its exit.
12. **Added judgment: consolidate conditions only when they have no side effects and their evaluation order does not matter.** Check: no call in the combined expression has an observable effect.

## Procedure

1. Draw the decision structure: list each path from entry to exit with its condition and its result.
2. Remove control flags and consolidate duplicate fragments first; these are the least risky.
3. Convert special cases into guard clauses, outermost first; run the tests after each.
4. Extract named predicates for conditions that need explanation.
5. If a mapping remains, consider a table; if the same switch recurs elsewhere, hand over to `refactoring-variation-and-state`.
6. Re-trace the paths and compare with the list from step 1.

## Example

```go
// Before
func shippingLabel(o Order) string {
	var label string
	if o.Paid {
		if !o.Cancelled {
			if o.Express {
				label = "EXPRESS"
			} else {
				label = "STANDARD"
			}
		} else {
			label = "VOID"
		}
	} else {
		label = "HOLD"
	}
	return label
}

// After: same four results for the same four situations
func shippingLabel(o Order) string {
	if !o.Paid {
		return "HOLD"
	}
	if o.Cancelled {
		return "VOID"
	}
	if o.Express {
		return "EXPRESS"
	}
	return "STANDARD"
}
```

An unpaid order is `HOLD` whether or not it is cancelled, in both versions; a paid, cancelled order is `VOID`; the remaining two results follow `Express`.

## Anti-patterns

- **If-pyramid.** Detect: three or more levels of nesting with the real work innermost. Treat: guard clauses.
- **Control flag.** Detect: a boolean set in a branch and tested several lines later. Treat: return or break directly, or extract.
- **Repeated tail.** Detect: the same statements at the end of every branch. Treat: consolidate duplicate fragments.
- **Strategy for one switch.** Detect: an interface and classes introduced for a single local conditional. Treat: inline it back (`refactoring-needless-abstraction`).
- **Assertion as validation.** Detect: an assertion guarding user input. Treat: real validation with real error handling.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Guard clauses are about clarifying the normal path; when both branches are equally normal, a plain if/else reads better (the source frames guard clauses as a way to clarify the normal path).
- A flat table of mappings is better as data when it is stable; if branches have different behavior, keep code.
- Early returns can conflict with a repository's single-exit convention or with required cleanup; keep cleanup on every path. (Added judgment)
- Some languages evaluate and short-circuit differently; check evaluation order before consolidating. (Added judgment)

## Verification

- [ ] Every original path maps to a path in the new structure with the same result.
- [ ] Code that ran after the old conditional still runs on every path.
- [ ] No condition with side effects was reordered or merged.
- [ ] No polymorphism or strategy was introduced for a single local branch.
- [ ] Tests passed after each change, with no changed expectation.

## Related

`refactoring-variation-and-state` for branching repeated by kind; `refactoring-function-bodies` for cutting the function; `refactoring-error-paths` for failure branches; `refactoring-conditional-reviewer` to inventory branches in a diff.

## Source

- `Rules for Working with Conditionals`
- `Switch Statements and Conditionals`: only the rule not to replace a single honest conditional with indirection.
- `Simplification Refactorings`: only guard clauses and consolidating duplicate conditional fragments.
- `Simplifying Calls and Conditionals`: Decompose Conditional, Consolidate Conditional Expression, Consolidate Duplicate Conditional Fragments, Remove Control Flag, Replace Nested Conditional with Guard Clauses and Introduce Assertion.
