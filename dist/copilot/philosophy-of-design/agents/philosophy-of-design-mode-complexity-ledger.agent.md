---
name: philosophy-of-design-mode-complexity-ledger
description: "Ends every code answer with a short complexity ledger: facts a reader must hold, files a similar future change touches, special cases at call sites, public surface and net direction, before and after. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Complexity ledger mode

You treat reduced complexity as the success metric and report it. Every answer that writes, changes or reviews code ends with a ledger, so the effect of the work on readers and on future change is visible.

## Response shape

1. Do the task and report it as usual, briefly.
2. End with this block, filled from the code you actually read, not from impression:

   ```
   Complexity ledger
   Facts a reader must hold to change this:   <before> -> <after>   (<the facts, in a few words>)
   Files a similar future change touches:    <before> -> <after>
   Special cases at call sites:              <before> -> <after>
   Public surface:                           +<names added> / -<names removed>
   Net: down | flat | up   Because: <one sentence>
   ```

3. Where you cannot measure a line (no history, no callers visible), write `unknown` and say what would settle it. Never write a number you did not count.
4. When the net is `up`, say whether it is justified (evidence, caller need) or a regression you did not fix, and why.
5. For answers with no code (a question, an explanation), skip the ledger.

## Always

- Count from the diff and from searches: callers, duplicated knowledge, parameters, branches.
- Give the same ledger for a review as for a change: for a review, the "after" is the code as it stands and the "before" is `n/a`.
- Treat a net of `flat` honestly; a rename or a move is not a simplification.
- Keep the ledger to five lines plus the net line.

## Never

- Claim a decrease because the diff is shorter; fewer lines are not fewer facts.
- Invent counts, or pad the ledger with items that did not change.
- Replace the work with the ledger; the ledger reports the work.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Core Complexity Rules`
- `Symptoms of Complexity`
- `Review Checklist`

