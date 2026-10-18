---
name: refactoring-guru-mode-treatment-card
description: "Prints a smell, cost, technique, check and stop card before every edit and a one-line result after it, so no change happens without a diagnosis. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Treatment-card mode

The source's loop is diagnose, treat, verify, stop. In this mode the loop is written down before each edit. No edit happens without a card, and the card comes first in the response.

## Response shape

1. Before each edit, print a card:

   ```
   Smell:     <catalog name> at <file:line>
   Cost:      <what it makes slower or riskier>   Scope: local | repeated | architectural
   Technique: <preferred technique>   (fallback: ... | risky: ...)
   Check:     <test or check to run> after <which step>
   Stop:      <condition> | new diagnosis needed if <trigger>
   ```

2. Make the edit the card describes, and nothing else.
3. After the edit, print a result line: `Result: <technique> done | check: <command> -> <result> | stop: reached | not reached (next card: ...)`.
4. A card is needed for each smell, not for each file touched. A card for a rename that enables an extraction is written as an enabling step: `Smell: Long Method (enabling rename)`.
5. At the end, print **Not treated**: smells you noticed that have no card, each with the reason (not blocking, needs a decision, the source allows leaving it).

## Always

- Read the smell's row in the priority map and use its preferred rung first; say what blocked it if you use a lower rung.
- Weigh the source's exceptions when writing the card; a card may conclude "leave it, because ...", in which case no edit follows.
- Write the check before the edit. If no check exists, the first card is for pinning the behavior.
- Keep behavior changes out of cards: if the work needs one, say so and ask.
- When the user wants a card for one smell and no edit, point to `refactoring-guru-smell-to-treatment` instead of switching the whole session into card-before-edit mode.

## Never

- Edit without a card, or edit beyond what the card names.
- Write a card for a smell you have not confirmed by reading the code.
- Continue with a new card just because another smell is visible and does not block the requested change.
- Merge two smells into one card to save space.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Diagnose, Treat, Verify, Stop`
- `Smell Detection Process`
- `Smell-to-Treatment Priority Map`: only the preferred, fallback and risky rungs.
- `Smell Exception Rules`: only the cases where a card concludes to leave the smell.

