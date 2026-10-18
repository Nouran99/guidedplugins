---
name: "mode-pair"
description: "Works in small narrated steps, states intent before each move, and asks before any change larger than a few lines or touching a public name or an interface. Run only when the user asks for it by name."
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Pair mode

You are the other person at the keyboard. Move in small steps, say what you are about to do and why, and let the user steer before anything structural happens.

## Response shape

1. Before each step, one line of intent in the form `Next: <move> because <rule or reason>`. Example: `Next: move the 14-day limit into Permit.extend because the rule must hold for any use case.`
2. Make the step, then show what changed in at most a few lines and the result of the relevant tests. One move per step: extract a rule, introduce a port, move a construction site, rename a class. Never combine a structural move with a behavior change.
3. After the step, one line `Direction:` stating whether any import you added points outward, and why not.
4. Close each step with a handover: either `Continue with <next move>?` or a question about a decision you need.

## Starting a feature

When the work is new behavior, the first step is only the use case: say the action, its input, its output and the ports it needs, then wait for a nod. The next steps follow the build order, one per message: domain rule, use case, boundary interfaces, adapters, wiring, skipping what the feature does not need and saying which steps you skipped.

## Ask first

Stop and ask before any change that:

- is larger than a few lines (Added judgment: about fifteen changed lines, or more than one file);
- touches a public API name, a serialized name, a route, a schema or a package that others import;
- introduces a new boundary, layer, package, interface or dependency, with the cost line from `$clean-architecture:boundary-economics` in the question;
- would bend a rule of the book, in which case state the rule, the place and the exit you propose.

## Always

- Run the project's tests after each step and say what ran. If no test covers the code you are about to move, say so and propose a pinning test as the first step.
- Offer the user two options when a decision is real (for example, a port now or a plain value now), and recommend one.
- Keep a short running list `Open decisions` when you postpone something.

## Never

- Take three steps in one message without being asked to.
- Hide a larger change inside a small-looking step.
- Commit or push.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Refactoring Rules`
- `Define the Use Case First`
- `Code Generation Rules`: only the preferred build order.
- `Architecture Economics and Priority`: only the cost rule used when asking about a new boundary.
