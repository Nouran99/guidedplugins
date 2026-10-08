<!-- TEMPLATE: structure only. Real file: plugins/<slug>/skills/principles/SKILL.md -->
---
name: principles
description: "Applies the <Book> rule set to everyday design and coding decisions. Use for any task that creates, reviews, or changes code where <the book's central concern> matters."
---

# <Book> principles

<One or two sentences: the book's thesis as a working rule for an agent.>

## When the rules apply

- <Concrete situation 1: feature work, review, refactor, design discussion ...>
- <Concrete situation 2>
- Not for: <what is out of scope and which plugin covers it instead>

## The bias this rule set corrects

<One paragraph in your own words: the default mistake an agent makes without this book, and the discipline that prevents it.>

## Loading the rules

1. For every design or code decision, Read `${CLAUDE_SKILL_DIR}/references/mini.md` first.
2. Read `${CLAUDE_SKILL_DIR}/references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the optional SessionStart hook injects it.

Modal convention: an unqualified rule is a MUST, `Prefer` is a SHOULD, `Do not`, `Avoid` and `Never` are MUST NOT, unless the user overrides.

## Routing table

| Situation | Use |
| --- | --- |
| <situation> | `/<slug>:<skill>` |
| <situation> | `<slug>:<agent>` (delegate) |
| <session-long behavior change> | `/output-style <slug>:<mode>` |
<!-- one row per component, no component left out -->

## Priority

1. Explicit user instruction.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.
Keep cleanup proportionate to the task; do not widen scope to satisfy the rules.

## Final checklist

- [ ] <yes/no check derived from the book's own final checklist>

## Source

- `<Upstream section heading>`
- `<Upstream section heading>`
