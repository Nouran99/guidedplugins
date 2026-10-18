---
name: "error-paths"
description: "Use when error handling hides the main path, or a refactoring touches validation, cleanup, recovery, error codes or exceptions. Keeps failure behavior identical while making it readable. Ordinary branching is conditionals; cutting a function is function-bodies."
---

# Error paths

Failures are behavior. A refactoring may reshape how error handling reads, but not what it does: which error, when, with what partial effects and cleanup. This skill makes the main path visible while keeping error semantics equal. Ordinary branching is `$refactoring:conditionals`; what a function reads or does silently is `$refactoring:hidden-dependencies`.

## When to use

- The happy path is buried under nested checks, try blocks or cleanup code.
- The same validation, cleanup or recovery structure appears in several functions.
- A change moves, merges or reorders validation or cleanup.
- Code returns error codes where exceptions fit, or throws where a test would do.

## Rules

1. **Refactor error handling to make the main path visible.** Check: the normal sequence of steps reads top to bottom with error exits beside it, not around it.
2. **Keep cleanup, validation and recovery logic from drowning core behavior.** Check: the core operation is not interleaved with handling for every step.
3. **Standardize similar error paths when they duplicate structure.** Check: three or more copies of the same try, catch and wrap pattern are one helper or one structure (the count is Added judgment; the source says only "similar").
4. **Preserve existing error semantics unless intentionally changing behavior (MUST).** Check: use the semantics list in rule 5.
5. **Added judgment: error semantics are these six things.** Which error type or code is produced; the message when callers match on it; when it is produced relative to side effects; what is cleaned up or rolled back; what is logged or reported; whether a retry or fallback occurs. Check: for every changed error path, each of the six is the same before and after.
6. **Use Replace Error Code with Exception or Replace Exception with Test according to the expected failure model.** An expected, checkable condition is a test the caller makes; an unexpected failure is an exception; a code that callers must remember to check is a candidate for an exception. Check: the model was stated before the move, and both signatures and callers were updated together.
7. **Do not move validation across side effects.** Validation moved earlier can prevent writes that used to happen before the failure; moved later can allow them (Added judgment). Check: the sequence of effects before the first possible failure is identical.
8. **Do not widen or narrow what is caught.** A wider catch swallows errors that used to propagate; a narrower one lets some escape (Added judgment). Check: the set of error types handled is identical.
9. **Keep error context.** When wrapping, preserve the cause and the message callers depend on (Added judgment). Check: the wrapped error contains the original, and any matching on it still works.
10. **Consolidate duplicate validation, cleanup, recovery and error structures without merging different recoveries (compact checklist).** Check: two handlers are merged only if they do the same thing.

## Procedure

1. List each error exit in the function: condition, error produced, effects done before it, cleanup performed.
2. Choose the structure that shows the main path: early returns for failures, a single cleanup mechanism (`defer`, `finally`, `using`, context manager), a helper for repeated wrapping.
3. Restructure one exit at a time. After each, compare to the list from step 1.
4. If a code-versus-exception or exception-versus-test change is wanted, treat it as a signature change: update callers in steps (`$refactoring:call-signatures`).
5. Run the tests, including those that exercise failure.

## Example

```go
// Before: the main path is the innermost branch
func importFile(path string) error {
	f, err := os.Open(path)
	if err == nil {
		defer f.Close()
		rows, err := parse(f)
		if err == nil {
			err = store(rows)
			if err == nil {
				return nil
			}
			return fmt.Errorf("store: %w", err)
		}
		return fmt.Errorf("parse: %w", err)
	}
	return err
}

// After: same errors, same wrapping, same order of effects
func importFile(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	rows, err := parse(f)
	if err != nil {
		return fmt.Errorf("parse: %w", err)
	}
	if err := store(rows); err != nil {
		return fmt.Errorf("store: %w", err)
	}
	return nil
}
```

The open error is returned unwrapped, parse and store errors are wrapped with the same prefixes, the file is closed on every path after a successful open, and `store` runs only after a successful `parse`.

## Anti-patterns

- **Reordered validation.** Detect: a check moved above or below a write. Treat: restore the order, or treat it as a behavior change.
- **Catch-all merge.** Detect: two handlers with different recovery merged into one. Treat: split them back.
- **Swallowed error.** Detect: an empty handler introduced or a returned error dropped. Treat: restore propagation.
- **Lost cause.** Detect: a wrapped error that no longer contains the original. Treat: wrap with the cause.
- **Code and exception mixed.** Detect: callers both check a return code and catch an exception from the same function. Treat: choose one model and migrate.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Replace Error Code with Exception and Replace Exception with Test change the contract callers see; they are structural only when all callers move together and the failure behavior is the same. Otherwise they are behavior changes. (Added judgment)
- Languages without exceptions or with result types have their own idioms; follow the repository (priority order in `$refactoring:principles`). (Added judgment)
- Cleanup mechanisms differ in timing between languages (`defer` runs at function exit, `finally` at block exit); check the timing before swapping one for another. (Added judgment)
- If the current error semantics are plainly wrong, do not fix them inside the restructuring; record and treat separately (`$refactoring:behavior-preservation`). (Added judgment)

## Verification

- [ ] The main path reads straight through the function.
- [ ] For each error exit: the same error, same effects before it, same cleanup, same logging.
- [ ] The set of caught error types did not widen or narrow.
- [ ] Merged handlers perform identical recovery.
- [ ] Tests that exercise failures passed, and no failure test was changed.

## Related

`refactoring-error-path-reviewer` to compare error behavior before and after in a diff; `$refactoring:conditionals` for non-failure branching; `$refactoring:safety-net` for pinning failure behavior with characterization tests; `$refactoring:function-bodies` for splitting phases.

## Source

- `Error Handling Rules`
- `Simplifying Calls and Conditionals`: only Replace Error Code with Exception and Replace Exception with Test.
