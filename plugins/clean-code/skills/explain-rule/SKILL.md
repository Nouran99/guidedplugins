---
name: explain-rule
description: "Explain one Clean Code rule: its strength (must, should, must not), the reason, how to check it, an original example and the book's own exceptions."
disable-model-invocation: true
argument-hint: "[rule name | section | situation you are unsure about]"
allowed-tools: Bash(git diff *) Bash(git status *) Bash(git log *) Bash(git show *)
---

# Explain a rule

Arguments: `$ARGUMENTS`

## Scope

1. If `$ARGUMENTS` names a rule (for example "one word per concept" or "command query separation"), explain that rule.
2. If it names a section (for example "Comment rules"), explain the section's two or three rules that most change decisions and list the rest by name.
3. If it describes a situation ("should I split this function?"), find the rules that decide it, explain the one that decides it, and apply it to the situation.
4. If it is empty, list the upstream sections (Naming rules, Function rules, Comment rules, Formatting and structure, Objects, modules, and data structures, Class and module design, Error handling, Boundaries and external dependencies, System construction rules, Tests, TDD and clean test rules, Concurrency and async work, Refactoring rules, Emergent design and successive refinement, Smells to detect and eliminate, Change Process, Implementation preferences, Review checklist, Output Expectations, Hard rules) and ask which one to explain. Stop.

## Steps

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/principles/references/mini.md`. If the rule is not there, find it in `${CLAUDE_PLUGIN_ROOT}/skills/principles/references/full.md` by searching for a distinctive word.
2. Determine the modal strength from the source's wording: an unqualified statement is a MUST; "Prefer" is a SHOULD; "Do not", "Avoid" and "Never" are MUST NOT. Say which, and say that the user can override it.
3. Explain the reason in your own words: the failure it prevents, in one or two sentences. Do not paste the source sentence.
4. Give a check the reader can run on real code.
5. Give one short original example in a widely read language, as a before and after, with realistic names. Do not use examples from the book.
6. State the book's own exceptions or limits. If you add a limit that is not in the source, label it "Added judgment".
7. Point to the skill that applies the rule in practice and the reviewer that checks it (see the routing table in `${CLAUDE_PLUGIN_ROOT}/skills/principles/SKILL.md`).
8. If the rule is not in the source, say so and do not invent it. You may offer general engineering knowledge, labeled as such.

## Output

```
Rule: <name in your words>   Section: <upstream section>
Strength: MUST | SHOULD | MUST NOT   (source wording: unqualified | Prefer | Do not / Avoid / Never)
Why: <failure prevented, 1-2 sentences>
Check: <how to test it on real code>
Example:
  // before ...
  // after ...
Exceptions: <what the book permits, plus any "Added judgment">
Apply with: /clean-code:<skill>   Verify with: clean-code:<reviewer>
```

## Stop conditions

- Explain one rule, or one section's key rules. Do not expand into a tour of the book.
- Do not edit files or run anything that changes state.
- If two rules appear to conflict for the user's situation, explain both, say which the source puts first (the user's instruction, then repository conventions, then this book), and stop.

## Source

- `Priority and behavior`
- `Core clean code principles`
- `Hard rules`: only the modal convention and the list of non-negotiable rules.
