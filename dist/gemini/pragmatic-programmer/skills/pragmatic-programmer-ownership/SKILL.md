---
name: "pragmatic-programmer-ownership"
description: "Use when asked whether a change is good enough or finished, when a trade-off, risk or uncertainty must be reported, when a poor result is blamed on the framework or deadline, or when a ritual has no benefit. Small decay is `pragmatic-programmer-broken-windows`; repository artifacts are `pragmatic-programmer-code-communication`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Ownership of the result

Decide how far to take a change, what quality bar it needs, and what to tell the people who depend on it. This skill is about accountability and the stopping point. Which small decay to fix in touched code is `pragmatic-programmer-broken-windows`; the written artifacts that stay in the repository are `pragmatic-programmer-code-communication`.

## When to use

- Someone asks whether a change is good enough, finished or worth more polish.
- You are about to report a finished change, a plan or a recommendation, with its trade-offs, risks and uncertainty.
- You are tempted to explain a poor result with the framework, a tool, a deadline or "the existing style".
- The request does not say what quality bar applies (tests, docs, error handling, performance) or you are about to polish far past the request.
- A step is being followed only because it is customary: a checklist nobody reads, a diagram nobody uses, a ceremony with no outcome.
- You are starting small to get a decision unstuck.

## Rules

1. **Take responsibility for the quality and changeability of the code you touch.** [MUST] You are the last one to see it before it ships; "the reviewer will catch it" moves the risk without removing it. Check: you can say what changed, why it is safe and what could break without opening the diff.
2. **Do not blame tooling, framework defaults or "existing style" for avoidable bad design.** [MUST NOT] If a constraint is real, show it; if it is not, change the design. Check: no summary or comment says "the framework forces this" without naming the constraint (a version, an API, a documented limit).
3. **Surface trade-offs, risks and uncertainty explicitly.** [MUST] A reader who is not told what was traded away cannot decide. Check: the report has a line for each of what was traded, what could go wrong and what you did not verify.
4. **Communicate decisions clearly enough that others can act on them.** [MUST] Check: each decision states the options considered, the choice and what the reader must do next, if anything.
5. **Treat quality as a requirement to negotiate with users and sponsors, not as an abstract pursuit of perfection.** [MUST] Added judgment on the how: when the request is silent, choose the bar the real risk justifies and state it in one line, and ask first when the choice is costly to reverse. Check: the bar (tests, docs, error handling, performance) is named in the plan or the report.
6. **Stop polishing when the software is good enough for its real users and risks.** [MUST] Added judgment on the how: write done-criteria from the request before starting, and require every extra change to map to a user need or a named risk. Check: each hunk outside the done-criteria is justified or moved to a follow-up list.
7. **Be pragmatic, not dogmatic: do not follow style or process rituals that do not improve outcomes, and be skeptical of methods, diagrams and ceremonies that do not improve the work.** [MUST NOT] Check: for each ritual you can name the outcome it protects; if you cannot, skip it and say so.
8. **Use Stone Soup tactics only to create real progress, not to hide missing agreement.** [MUST] Starting small to get people moving is fine when the small piece is real and useful on its own; it is not a way to grow scope without asking. Check: the end state you are heading toward has been stated to the people it affects.
9. **Keep a knowledge portfolio: invest in learning and revisit stale assumptions.** [MUST] Added judgment for an agent: before relying on remembered behavior of a library or API, check the version the repository pins and read its documentation or source, and say when you could not. Check: version-sensitive claims name the version they were checked against.
10. **Take pride in code, tests, documentation and generated artifacts.** [MUST] Check: you would defend every file in the diff in a review, generated files included (`pragmatic-programmer-generators-and-dsls`).
11. **Set expectations explicitly with users and stakeholders.** [MUST] Check: a delivery claim says what is included, what is not and what is still open; an estimate carries its uncertainty (`pragmatic-programmer-tracer-bullets`).

## Procedure

1. Before starting, write two or three lines of done-criteria: the outcome, the quality bar, what is out of scope. Ask the user only if the bar changes the cost a lot.
2. While working, when you reach for a justification that points outward ("the framework", "existing style", "no time"), replace it with the named constraint or fix the design.
3. Before reporting, list decisions, trade-offs, risks and what you did not verify.
4. Run the stop check: every change beyond the done-criteria needs a user need or a named risk; otherwise remove it or list it as a follow-up.
5. Report in this order: what changed, which checks ran, trade-offs, risks, not verified, follow-ups. For trivial changes this is one line.

## Example

Request: make the CSV import faster.

```text
Before
Import is much faster now (batch inserts). Done.

After
Changed: customers import now inserts in batches (batch size 500 in this change; a starting value, not a measured optimum).
Checks: import tests pass; a 50,000-row sample took 4 s instead of 38 s on my machine.
Trade-off: a database error now fails the whole batch, not one row. Row validation still runs before insert, so malformed rows are reported individually.
Risk: lock behavior with two imports running at once is not verified; I did not run concurrent imports.
Not verified: production data volume and database settings.
Left alone: the upload form re-validates the same rows with its own rule (see pragmatic-programmer-dry-knowledge).
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Outward blame | A cause given as "the framework", "legacy" or "no time" with no named constraint | Name the constraint, or fix the design |
| Silent trade-off | A report that lists only the happy outcome | Add trade-offs, risks and unverified claims |
| Gold plating | Hunks that map to no done-criterion | Remove, or list as follow-up |
| Ritual compliance | An artifact nobody reads, produced because it is customary | State the outcome it protects, or drop it |
| Stone Soup as scope smuggling | A small first change in a series whose end state nobody agreed to | State the intended end state to the people affected |
| Memory as evidence | A claim about a library that names no version | Check the pinned version and say what you checked |

## Trade-offs and exceptions

- Repository conventions still outrank this book (see the priority rules in `pragmatic-programmer-principles`). The rule bars using a convention as an excuse for a design you could improve inside it, and asks you to say so when the convention itself is the problem.
- "Good enough" is relative to real users and risks. Added judgment: code that handles money, security or safety raises the bar, and the bar should be stated.
- For a trivial change the report is one line. Rule 7 applies to this skill: a ceremony of trade-off tables for a typo fix is the ritual it warns about.
- Asking about the quality bar costs the user's attention. Ask when the choice is expensive to reverse; otherwise choose, state the choice and move on.

## Verification

- [ ] Done-criteria existed before the work and the diff matches them.
- [ ] The report names trade-offs, risks and what was not verified.
- [ ] No cause is blamed on a tool or a convention without a named constraint.
- [ ] Every ritual followed maps to an outcome.
- [ ] Follow-ups are listed, not silently done.

## Related

`pragmatic-programmer-broken-windows` for decay in touched code; `pragmatic-programmer-code-communication` for repository artifacts; `/pragmatic-programmer:plan` to write done-criteria into a plan; `/pragmatic-programmer:mode-owner` to get the report block after every task.

## Source

- `Own the Result`
- `Named Pragmatic Habits`: the habits on negotiating quality, good enough, the knowledge portfolio, communication and Stone Soup.
- `Cargo-Cult Process`
- `Project and Team Rules`: only the rules on shared responsibility, explicit expectations, pride and skepticism toward ceremonies.
- `Primary Directive`: only the rule not to follow style or process rituals that do not improve outcomes.
