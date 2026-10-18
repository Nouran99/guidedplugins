<!-- Clean Code: nano rules from ciembor/agent-rules-books (MIT), packaged by guided-plugins/clean-code -->
# OBEY Clean Code by Robert C. Martin

## When to use

Use when you need a small always-on bias toward readable, low-surprise code.

## Primary bias to correct

Working code is not automatically clean code.

## Decision rules

- Preserve behavior, write for the next reader, and leave touched code cleaner within scope.
- Write for local reasoning and use precise names with one term per concept.
- Split boolean flags, mixed abstraction levels, and hidden side effects out of functions.
- Separate commands from queries and keep parameters small and meaningful.
- Keep the happy path readable; make invalid states, errors, and cleanup explicit instead of implicit.
- Use comments only for rationale or contracts, not to explain confusing code.
- When touching code, remove the smell most likely to make the next change risky or unclear.

## Trigger rules

- When a function both mutates and answers, split it.
- When a comment explains the flow, simplify the code first.
- When async, concurrency, or framework quirks spread the change, reduce shared mutable state and add the right boundary instead of more branching.

## Final checklist

- Local reasoning preserved?
- Clear names?
- Clear mutation boundaries?
- One smell removed?

## Companion skills (if installed)

The Clean Code rules above are backed by skills from the `clean-code` plugin. Use `review` to review a change, `plan` before a non-trivial change, `explain-rule` to look up a rule, `checklist` before finishing, and `principles` for the full rule set and routing table. Most agents name them `clean-code-<skill>` (for example `clean-code-review`); Codex mentions them as `$clean-code:<skill>` (for example `$clean-code:review`).
