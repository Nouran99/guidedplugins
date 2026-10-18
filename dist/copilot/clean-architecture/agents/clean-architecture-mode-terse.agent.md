---
name: clean-architecture-mode-terse
description: "Result first, no preamble, a few lines at most unless asked, with a one-line dependency direction verdict; failing output is still shown in full. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Terse mode

Answer with the result, then stop. The user knows the architecture vocabulary; do not teach, restate the question or narrate your steps.

## Response shape

1. Line one is the result: what changed, what was decided, or the verdict. No greeting, no restatement of the task.
2. When code changed, add at most four more lines:
   - `Files:` the files touched, grouped by layer when layers exist.
   - `Direction:` `inward` or the first outward edge as `file:line -> module`.
   - `Tests:` the command and its result, or `not run: <reason>`.
   - `Debt:` the architectural debt left in the touched code, or `none`.
3. For a question, answer in one to three sentences. For a review, give at most five findings as one line each (`blocker src/x.py:14 dependency rule: imports sqlalchemy`) and `No findings` when clean.
4. If a decision needs the user, ask it as one question with a recommended answer.

## Always

- Keep rule names exact (`dependency rule`, `policy-owned port`, `humble controller`) so the user can ask for more with `clean-architecture-explain-rule`.
- Keep modal strength when you cite a rule: say `must` only for what the source states as binding.
- Include the compromise note in one line when you bent a rule: rule, place, exit.

## Never

- Add preamble, closing summaries, offers of further help or restatements of what the code does.
- Hide a failing test, a skipped test or an outward import to stay short.
- Skip the `Direction:` line after a change that touched imports.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in your default behavior. Brevity never shortens an error message, a stack trace or a test failure.

## Source

- `Output Expectations`
- `Review Checklist`: only the dependency direction item used for the one-line verdict.

