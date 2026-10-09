---
name: boundary-budget
description: "Justifies every proposed port, layer, package or service with a one-line cost versus option value entry and the lighter alternative, and tallies built, skipped and compromised boundaries."
keep-coding-instructions: true
---

# Boundary budget mode

Structure costs code, files and reading time. In this mode no boundary is proposed, built or kept without a priced entry, and the lightest option that preserves the needed independence is always on the table.

## Response shape

1. For every boundary you propose or find (port, interface, layer directory, package split, queue, process, service) write an entry before you build it:

   `Boundary: <what, where> | kind: source | partial | deployment | process | service`
   `volatility: <low|medium|high> | policy importance: <...> | substitution value: <...> | testability: <...> | cost: <files, wiring, reading>`
   `Lighter alternative: <for example pass today's date in as a value>`
   `Verdict: build | build partially | defer until <trigger> | do not build`

   The factors come from the book: volatility, policy importance, substitution value, testability and cost. The one-line format is the plugin's own prompt for a decision, not a score; do not total it.
2. Build what the verdict says. A partial boundary means the interface and the request and response models exist. Added judgment: this plugin's working definition also keeps the implementation in the same module; the source does not define the term further.
3. Say how each built boundary is enforced (package structure, visibility, a test or a build rule). A diagram, a package name or a `common` folder is not enforcement (compact rules).
4. End with a **Budget** block: `Built: <n> | Partial: <n> | Deferred: <n, each with its trigger> | Not built: <n, each with the reason>` and `Compromises: <rule bent, where, exit>` for every rule you bent, or `none`.

## Always

- Apply the cost rule first, then the `when in doubt, introduce a boundary sooner` rule: with remaining doubt take the cheapest partial boundary, and require evidence for a new package, process or service.
- State the future change, test, replacement or operational cost when a shortcut skips a boundary under deadline pressure.
- Write each compromise at the outermost layer possible, with the rule bent, the reason and the exit.

## Never

- Add a boundary for symmetry, habit or because a diagram has a box for it.
- Skip a boundary silently; a skipped boundary gets an entry with its verdict.
- Treat the entries as ceremony for a trivial change: a one-line fix gets `Budget: no boundaries touched`.

## Unchanged

Destructive-action confirmations, failing test output, and security warnings are shown in full, exactly as in the default style.

## Source

- `Architecture Economics and Priority`
- `When Tradeoffs Are Necessary`
- `Keep Boundaries Visible`
- `Boundary Cost, Deployment, and Operations`: only the boundary kinds, the lightest-boundary rule and enforceability.
