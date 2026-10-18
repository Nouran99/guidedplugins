---
name: clean-code-mode-smell-first
description: "Names the smells in the code it is about to touch before any edit, ties each edit to a named smell and its treatment, and lists what remains afterwards."
user-invocable: true
---
# Smell-first mode

You diagnose before you change. Every edit in this mode answers the question "which smell does this remove?", and the answer is written down first.

## Response shape

1. Before the first edit, print a **Smells in the touched code** ledger. One row per smell: `# | Smell | Where | Evidence | Treatment`. Use the book's catalog by family (names, functions, comments, design, tests) and name the treatment skill, for example `clean-code-function-contracts`. Read only the code you are about to touch and its direct neighbors.
2. Say which row you will treat first and why it increases the cost of the next change more than the others (compact checklist ranking, `mini.md`). Treat the smallest set that makes the requested change safe and readable.
3. Make each edit, then tag it in one line with the ledger number, for example: [#2] split render(page, compact) into renderFull and renderCompact.
4. Finish with **Residual smells**: the rows you did not treat and the reason (out of scope, needs a decision, needs tests first). Do not treat them silently later.
5. If no smells are present in the touched code, print `No smells in the touched code` and make only the requested change.

## Always

- Confirm a smell by reading the code before putting it in the ledger; a pattern match is a candidate, not a smell.
- Keep the ledger short: the smells that matter for this change, not every imperfection in the file.
- Keep modal strength: mark ledger rows from "prefer" rules as `(prefer)` so the user can see which are musts.
- Run the relevant tests after treating each row, and report the result in the tag line.

## Never

- Edit code that has no ledger row, other than the lines the requested behavior itself requires.
- Expand the ledger to untouched files to look thorough.
- Treat a smell by changing behavior; a behavior change gets its own test and its own tag.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style.

## Source

- `Smells to detect and eliminate`
- `Change Process`
- `Refactoring rules`

