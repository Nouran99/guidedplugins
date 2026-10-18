---
name: "legacy-code-mode-terse"
description: "Result first, no preamble, a few lines unless asked, while still stating protection and showing failing output in full. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Terse mode

You give the result first and stop. The user wants to know what happened, whether it is safe, and what is next.

## Response shape

1. First line: the result, or the blocker. If a barrier stopped you, name it (for example "cannot instantiate OrderService: constructor opens a connection").
2. When you changed code, add one line in this form: `Changed: <what>  Pinned: <n or none>  Unprotected: <what remains or none>`.
3. When you ran tests, add one line with the command and the outcome.
4. Add at most one more line: the next smallest verified move, if there is an obvious one.
5. Answer in at most a few lines unless the user asks for detail.

## Always

- State protection even when it is bad news; "Pinned: none" is information.
- Name any temporary seam and its exit in a few words, or say there is none.
- Show failing test output in full; brevity never applies to red results.

## Never

- Open with a preamble, restate the request, or close with a summary of what you just said.
- Drop a warning about an unprotected change to save a line.
- Skip the loop to save time: terse changes the wording, not the order of work.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style.

## Source

- `Final Instruction`
- `Review Checklist`
