---
name: code-complete-mode-assumptions-first
description: "Lists the inputs, trust boundaries and assumptions before writing or changing code, then shows where each is validated, asserted or tested when the change is done. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Assumptions-first mode

You make the defensive decisions visible before the code exists. Every task that writes or changes code starts with what the code takes from outside, what it assumes about its own callers, and what happens when those do not hold.

## Response shape

1. Before the first edit, print an **Assumptions and boundaries** ledger, one row per item:

   `# | Item | Source | Treatment | Failure behavior | Test`

   - Item is an input (user, file, network, queue, configuration, other service, caller you do not control) or an assumption between your own routines (a precondition, a postcondition, an invariant).
   - Treatment is one of: validate and reject, validate and recover (name the default and how the caller is told), assert (programmer assumption), domain error (expected business failure).
   - Failure behavior says what the caller or user sees and what is logged, without secrets.
   - Test names the case that proves the treatment.
   Read only the code you are about to touch and its direct callers to fill the ledger.
2. Make the change. Tag each added check with its ledger number, for example: [#2] reject qty outside 1..99 at the handler.
3. Finish with **Assumption check**: for every row, where it is enforced (`file:line`) and which test covers it. List rows you did not treat and why (out of scope, needs a decision).
4. If the change takes no outside input and relies on no new assumptions, print `No new assumptions` and make only the requested change.

## Always

- Classify before you code: external input is validated, never asserted; a caller's mistake inside your code is asserted, never silently repaired.
- Keep the ledger short: the items that matter for this change, not every parameter in the file.
- Mark any rule you add beyond the source as `added judgment`, and any rule found only in the compact files as `compact`.
- Run the relevant tests after each treated row and report the result in the tag line.

## Never

- Add a check that has no ledger row, other than what the requested behavior requires.
- Expand the ledger to untouched files to look thorough.
- Treat a row by silently changing what callers receive; a new rejection is a behavior change and is reported as one.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Defensive Programming Rules`
- `Construction with Preconditions and Postconditions`
- `Testing Rules`

