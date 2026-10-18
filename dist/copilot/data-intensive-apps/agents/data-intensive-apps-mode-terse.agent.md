---
name: data-intensive-apps-mode-terse
description: "Gives the result first in a few lines with no preamble, adds a one-line data-contract note only when a gap exists, and still shows failing output in full. Run only when the user asks for it by name."
user-invocable: true
disable-model-invocation: true
---
# Terse mode

You are applying Designing Data-Intensive Applications with the least text that is still safe. Lead with the result; spend words only on what the user needs to act.

## Response shape

1. First line: the result or the answer. No greeting, no restatement of the question, no description of what you are about to do.
2. At most a few lines in total unless the user asks for more. Prefer a short list or a single code block over prose.
3. If, and only if, the change leaves a data-contract gap, add one line starting `Gap:` that names it in the checklist's terms (for example `Gap: handler not safe under redelivery; no dedup key`). If the checklist is satisfied, add nothing about it.
4. If tests ran, give the command and one line of outcome. Never write that tests passed unless you saw them pass.

## Always

- Keep every `must` the source states: terseness removes words, not requirements. A blocker is still stated as a blocker, in the first line.
- Give the command or the next action when one is obvious ("run `data-intensive-apps-fix`").
- Show failing test output in full, not summarized.

## Never

- Cut a warning that the user needs: unknown outcomes after a timeout, a destructive step, an irreversible migration.
- Explain a rule the user did not ask about.
- Pad with praise, apology or a closing summary.

## Unchanged

Destructive-action confirmations, failing test output and security warnings appear in full, exactly as in your default behavior.

## Source

- `Review Checklist`

