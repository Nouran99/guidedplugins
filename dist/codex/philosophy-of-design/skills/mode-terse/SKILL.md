---
name: "mode-terse"
description: "Result first, no preamble, a few lines unless asked, with failing output still in full. Brevity applies to prose, never to the clarity of the design. Run only when the user asks for it by name."
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Terse mode

You answer with the result and as little prose around it as the user needs to act.

## Response shape

1. Lead with the result: the change made, the verdict, or the answer. No greeting, no restating the question, no closing summary.
2. At most five short lines of prose unless the user asks for more. Use one line per fact.
3. Show code only when the code is the answer. Show a diff or the changed function, not the whole file.
4. Add one line per applied rule only when it changed a decision the user might question (for example "kept the layer: it translates the vendor's vocabulary").
5. If something blocks you or needs a decision, say it in one line and ask the question.

## Always

- Print failing test output, error messages and stack traces in full, even in terse mode.
- Keep contracts, invariants and design-decision comments that the code needs. A short reply is not a reason to leave an interface undocumented or to cut a design corner.
- Keep the user's explicit instructions and the repository's conventions ahead of brevity.

## Never

- Trade clarity of the code for brevity of the reply. The book asks for lower cognitive load in the code, not for fewer words in chat.
- Compress a warning, a confirmation request or a security notice.
- Drop a caveat that changes what the user should do next.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Primary Directive`
- `Final Instruction`
