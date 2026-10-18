---
name: "clean-code-refactoring-steps"
description: "Use when restructuring existing code without changing behavior, preparing for a change by cleaning first, or sequencing a cleanup. Covers small safe steps, make-it-work-then-right, rename, extract and inline moves, and stopping. Whether tests exist or come first is clean-code-tdd-discipline."
license: "MIT"
metadata:
  plugin: "clean-code"
  book: "Clean Code"
  invocation: "auto"
---

# Refactoring steps

The movement discipline: how to change structure without changing behavior, and when to stop. Which shape to aim for is `clean-code-emergent-design`; where to look for problems is the smell skills (`clean-code-smells-redundancy`, `clean-code-smells-coupling`, `clean-code-smells-surprise`).

## When to use

- You will touch code that is hard to change and want to improve it first.
- A review asks for restructuring of code that already works.
- You are about to mix a bug fix or feature with cleanup.
- A cleanup is getting bigger than the task that prompted it.

## Rules

1. **Refactor in small, safe steps.** Each step is small enough that if the tests fail you know which edit did it. Check: the tests pass after every step, and each step can be undone by reversing one edit.
2. **Preserve behavior while improving structure.** A step that changes behavior is a change, not a refactor. Check: inputs and outputs, error behavior, and side effects of public entry points are unchanged; the existing tests pass without edits to their expectations.
3. **First make it work, then make it right.** Get the behavior correct and tested; then improve names and structure with the tests as a net. Check: you did not restructure code whose behavior you had not confirmed.
4. **Remove duplication, dead code, misleading abstractions and special-case clutter.** Check: each removal is its own step with its own test run.
5. **Rename aggressively when names are weak.** A rename is the cheapest high-value step. Check: all references, strings, configs and docs were updated; public names have a compatibility story.
6. **Extract code when doing so improves cohesion and clarity.** Check: the extracted piece has a name that says what, and the caller reads better.
7. **Inline abstractions that no longer earn their cost.** Check: the abstraction has one caller, adds a jump, and its name says no more than its body does.
8. **Prefer the simplest design that passes all relevant tests.** Check: the end state has fewer concepts or clearer ones, not more.
9. **Separate structural changes from behavior changes.** Added judgment, following from rules 2 and 3: when you find a bug during a refactor, record it and fix it in its own step, with its own test, not inside a structural step. Check: no step both moves code and changes what it does.
10. **Have a safety net before you start.** If the area has no tests, add tests that pin current behavior, or limit yourself to mechanical, tool-verified changes (rename, extract with an IDE) and say so. Check: you can name the check that would catch a mistake.
11. **Stop when the requested change is safe and readable.** Keep cleanup proportional; note what remains instead of doing it. Check: a short list of "seen but not touched" exists.

## Procedure

1. Run the relevant tests and record the baseline. A failing baseline is reported, not hidden.
2. Choose one smell that most increases the cost of the requested change (compact checklist, `mini.md`).
3. Pick the smallest move that reduces it: rename, extract, inline, move, introduce parameter object, replace flag, remove dead code.
4. Apply it, run the tests, and look at the diff.
5. Repeat from step 2 until the requested change is easy to make.
6. Make the requested behavior change as a separate step.
7. Run the wider suite and review the full diff for readability, duplication and unnecessary complexity.
8. Report the steps, the tests run, and what you left alone.

## Example

```ts
// Step log for one private function (renames are tool-assisted, so every reference follows)
// 1. Rename: p -> pendingRefunds, fn -> approveRefund        (tests green)
// 2. Remove dead branch: `if (legacyMode)` is never true since v2.3 (tests green)
//    `legacyApprove` may now be unused; search before deleting it, in its own step
// 3. Extract: isWithinRefundWindow(order), still reading Date.now() (tests green)
// 4. Behavior change (separate step): refunds over 500 need a second approver (new test first)
// Not done here: dropping the now-unused `legacyMode` parameter and injecting a clock both
// change the signature, so each is its own caller-visible step with callers migrated.

// Before
function fn(o: Order, p: Refund[], legacyMode: boolean) {
  if (legacyMode) { return legacyApprove(o); }
  if ((Date.now() - o.paidAt) / 86_400_000 <= 30) { p.push(new Refund(o)); }
}

// After steps 1 to 3: same parameters, same behavior
function approveRefund(order: Order, pendingRefunds: Refund[], legacyMode: boolean) {
  if (isWithinRefundWindow(order)) {
    pendingRefunds.push(new Refund(order));
  }
}

function isWithinRefundWindow(order: Order): boolean {
  return (Date.now() - order.paidAt) / 86_400_000 <= 30;
}
```

Step 4 is a different kind of change and gets its own test before it is written.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Big-bang refactor | Hundreds of lines changed between test runs | Break into steps with runs between |
| Refactor plus feature | One commit-sized change that renames, moves and alters behavior | Separate the behavior change |
| Test-edited refactor | Test expectations changed to make a refactor pass | Revert; the refactor changed behavior |
| Speculative extraction | New abstraction with no second use and no clarity gain | Inline |
| Unbounded cleanup | Diff touches files unrelated to the task | Cut back; list as follow-up |
| Rename without search | Old name survives in strings, configs, docs | Search whole word and string forms |
| No net | Restructuring code with no test or check | Pin behavior first |

## Trade-offs and exceptions

- Preparatory refactoring that makes the requested change easy is in scope; refactoring that merely makes you happier is not.
- A rewrite is sometimes right, but the book's default is incremental refinement; propose a rewrite as a decision for the user, not as a refactor step.
- Public API changes are behavior changes for callers even when the behavior is unchanged inside; keep a compatibility layer or ask.
- Tools that perform refactors mechanically (rename, extract method) are a stronger net than hand edits; prefer them where available.
- If a failing test points to a real bug exposed by the cleanup, stop, report, and decide whether to fix it separately.

## Verification

- [ ] Tests passed after each step, and you can list the steps.
- [ ] No test expectation changed during a structural step.
- [ ] Behavior changes, if any, are separate and have their own tests.
- [ ] The diff contains nothing unrelated to the task or the cleanup of touched code.
- [ ] A list of noticed-but-untouched issues exists.

## Related

`clean-code-boy-scout` to choose the cleanup; `clean-code-extract-till-you-drop` for one function; `clean-code-successive-refinement` for rough drafts; `clean-code-refactorer` to delegate; `clean-code-scope-guard` to audit the budget.

## Source

- `Refactoring rules`
- `Change Process`
- `Priority and behavior`: only the rule to leave touched code cleaner and the instruction not to preserve bad structure merely because it exists.
- `Emergent design and successive refinement`: only the rule not to start a grand redesign when incremental refinement can recover the design safely.
