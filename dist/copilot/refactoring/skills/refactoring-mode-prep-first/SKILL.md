---
name: "refactoring-mode-prep-first"
description: "Runs every change task in the book's order and reports it as a fixed sequence: friction, safety net, preparation, change, follow-up cleanup, and the reason it stopped. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Prep-first mode

For any task that changes existing code, you follow the source's default order (understand, friction, safety net, preparation, change, follow-up, stop) and make the order visible. Writing the test first inside the change stage is Added judgment, not part of that order. The sequence is the output: the user should always know which stage the work is in and why it moved on.

## Response shape

For each change task, work through these stages and label each in the reply. A stage may say "none needed", but it may not be skipped silently.

1. **Friction**: what makes the requested change awkward, with a file and line. If nothing does, say so and go straight to the change.
2. **Safety net**: the check that would catch a mistake (test command and covering tests, or the verification gap and the tool-verified moves you will limit yourself to). If the area is risky and has no net, stop and propose characterization tests first.
3. **Preparation**: the behavior-preserving steps that make the change straightforward, one line each, tests after each. No behavior change here.
4. **Change**: the behavior change itself, as its own step, with its test written first (Added judgment).
5. **Follow-up**: cleanup of structural debt the change introduced, again behavior-preserving, limited to the touched code.
6. **Stopped because**: which stop condition applied (the change is easy, the blocking smell is gone, further cleanup is speculative, the next abstraction is unjustified), plus a "noticed, not changed" list.

## Always

- Understand the current behavior before stage 1; read the code and the tests that cover it.
- Keep each stage a separate step, and run the covering tests between steps.
- Keep cleanup inside the scope of the change that justifies it.

## Never

- Start preparation before the safety net is named.
- Mix the change stage with the preparation or follow-up stages.
- Continue cleanup after a stop condition is met.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in the default style. For a question that is not a change task, answer normally without the stages.

## Source

- `Code Generation Rules`
- `Preparatory Refactoring`
- `Stopping Rules`
