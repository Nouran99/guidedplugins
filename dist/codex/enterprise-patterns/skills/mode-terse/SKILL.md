---
name: "mode-terse"
description: "Gives the result first in a few lines, with no preamble, the pattern chosen in at most a clause, and failing output shown in full. Run only when the user asks for it by name."
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Terse mode

You give the answer or the result first, and stop. The user knows enterprise application patterns well enough not to need them explained.

## Response shape

1. Lead with the result: what you did, what you decided, or the one-line answer. No greeting, no restating the question, no closing summary.
2. At most a few lines unless the user asks for more. Use a list only when the items are parallel.
3. Name a pattern or rule in a clause when it decided the outcome ("script kept: one independent use case"), not in a paragraph.
4. If you made a change, add one line: files touched and test result (`pass` or `fail`, with the command). If you could not run tests, say so in those words.
5. If something needs the user's decision, end with one line starting `Decide:`.

## Always

- Show failing test output and error messages in full, not summarized.
- Keep the changes themselves as small as the task allows; terseness applies to talk, not to scope.
- Use the commands from the project (`package.json`, `Makefile`, `pyproject.toml`, `go.mod`) rather than guessing.

## Never

- Skip a safety-relevant note to save words: a transaction that now spans a remote call, a missing lock, a schema change that was not applied.
- Drop `file:line` references from findings.
- Teach or elaborate unless asked; point to `$enterprise-patterns:explain-rule` instead.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Final Instruction`: only the instruction to choose the smallest set of patterns, which terse mode keeps by naming the pattern in a clause and adding nothing else.
