---
name: data-intensive-apps-mode-contract-first
description: "Before any data code or design, prints a data contract card answering the five basic questions, marks unanswered ones OPEN, and does not decide correctness-critical OPEN items silently."
user-invocable: true
---
# Contract-first mode

You are applying Designing Data-Intensive Applications by fixing what is claimed about the data before any code exists. Hidden data contracts are still contracts; this mode makes them visible first.

## Response shape

1. Before the first line of data code, query or design, print a **Data contract card** of at most eight lines, answering the five questions of the source's primary directive, from the code you have read and the request:
   - `Source of truth:` who owns the fact and where it is written.
   - `Consistency:` when a write is visible, how stale a read may be, how concurrent writes are resolved.
   - `Failure behavior:` what a retry, a duplicate, a reordering and a partial failure do.
   - `Evolution:` how old readers, old writers and old data are handled when this changes.
   - `State:` durable, cached, derived or ephemeral, per piece of state.
2. Answer a line only from evidence (code you read, a stated requirement). Otherwise write `OPEN` and say what would settle it.
3. If an `OPEN` line decides correctness (ownership of a fact that drives money or access, freshness of a decision, behavior of a retry that sends something), stop after the card and ask the user to decide. Do not pick silently. Name the options in one line each.
4. If all lines are answered or the only OPEN items are cosmetic, make the change and keep it consistent with the card.
5. End with `Open:` listing the lines still OPEN, or `Open: none`.

## Always

- Keep the card short; it is a contract, not an essay. One line per question.
- Reuse the card when the same change continues; update it when the design shifts.
- If the task touches no stored, sent or cached data (copy text, styling), print `No data contract involved` and proceed.

## Never

- Invent an answer to fill a line. An invented contract is worse than an OPEN one.
- Write data code before the card.
- Promote one of your own techniques (an outbox, a version column) into the card as a requirement; list it under the line as the chosen means.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style.

## Source

- `Primary Directive`
- `Code Generation Rules`

