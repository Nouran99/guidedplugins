---
name: "statements-and-loops"
description: "Use when writing or reviewing loops and straight-line code: loop start, stop and update, bloated loop bodies, statement order, negated conditions, normal-path placement. Branch shape: $code-complete:control-flow."
---

# Statements, conditions and loops

Judges how statements are ordered and how loops are built: dependencies before use, related statements together, positive conditions, the normal path easy to find, loops with a clear start, end and step. Nesting depth, compound conditions and exits are `$code-complete:control-flow`.

## When to use

- A block's statements depend on each other in an order that is not visible, or related statements are separated by unrelated ones.
- A condition is negated or double-negated, or the common case is buried in an `else`.
- A loop's termination depends on a flag set somewhere inside it, or it updates its counter in several places.
- A loop body filters, transforms, accumulates and performs I/O all at once.
- A loop uses an unusual structure (loop with `else`, labelled break, recursion where a plain loop would do).

## Rules

1. **Organize straight-line code so dependencies appear before use and related statements stay together.** Why: reading order should match data flow. Check: each statement's inputs come from lines above it; statements that work on one concept are adjacent; a setup statement is not far from its single use.
2. **Keep conditionals positive and direct when possible.** Why: `if (!isNotReady)` forces a reader to double-negate. Check: no condition tests a negated name; invert the condition and swap the branches, or rename the predicate.
3. **Put the normal path where readers can find it quickly.** Why: a reader scanning a routine should meet the common case first. Check: the common outcome is the first branch or the fall-through, and rare cases are guards or the `else`.
4. **Use loops with clear initialization, termination and update rules.** Why: unclear loops give off-by-one and non-terminating defects. Check: you can say in one sentence where the loop starts, when it stops and what changes each pass; the counter changes in exactly one place.
5. **Keep loop bodies focused; extract work when a loop hides several responsibilities.** Check: the body does one kind of work per pass; filtering, mapping, accumulating and I/O are separated or expressed with the language's iteration helpers.
6. **Avoid unusual control structures unless they are clearer than ordinary alternatives.** Check: a loop-`else`, a labelled `break`, an `iterator` hand-rolled with indices, or recursion over a plain list has a stated reason.
7. **Do not write complicated loop exits with hidden state changes.** Source anti-pattern, listed under control flow. Check: no `break` or `return` depends on a flag that another branch sets, and no loop condition is modified inside the body in a way the header does not show.
8. **Use table-driven methods when repeated branching is stable and the table can be validated.** Source rule in this section; the full treatment is `$code-complete:table-driven`.
9. Added judgment: iterate over the collection rather than over indices when the index is not needed; every index is a chance for an off-by-one and a place to reuse a variable (`$code-complete:variables`).
10. Added judgment: do not change a collection while iterating over it unless the language defines the behavior and the loop says so; collect changes and apply them after.
11. Added judgment: the places where a loop is wrong are its boundaries (empty input, one element, the last element); make sure the tests include them (`$code-complete:routine-testing`).

## Procedure

1. For each loop, write its start, stop and step as one sentence. If the sentence needs "unless" or "also", simplify first.
2. List what the body does per pass. If it is more than one kind of work, split it (extract a routine, or separate passes where cost allows).
3. Replace flag-controlled exits with a condition in the header or with an extracted routine that returns.
4. In each conditional, invert negated conditions and move the common case first.
5. Reorder straight-line statements so each input is produced just before it is used.
6. Run the tests; add a case for empty, single and last-element input if none exists.

## Example

```python
# Before: a flag and an index, two jobs per pass; `count` stops growing at the first match (probably unintended)
found = False
i = 0
count = 0
while i < len(users) and not found:
    if users[i].active:
        if users[i].email.endswith("@corp.example"):
            found = True
            admin = users[i]
        count += 1
    i += 1

# After: two questions, two statements, each with a visible meaning
CORP_DOMAIN = "@corp.example"

active_users = [u for u in users if u.active]
active_count = len(active_users)
admin = next((u for u in active_users if u.email.endswith(CORP_DOMAIN)), None)
```

The old `count` silently excluded every user after the first corporate admin; the new `active_count` counts all active users. Decide which was intended and say so in the change description.

## Anti-patterns

- **Flag-driven exit.** A loop that ends when a flag set inside it becomes true. Detect: a boolean assigned in the body and read in the header.
- **Multipurpose loop.** One pass that filters, counts, formats and writes. Detect: variable names in the body that belong to unrelated results.
- **Double negative.** `if (!disabled)` inside `else` of `if (!enabled)`. Detect: more than one `!` or `not` in a condition's chain of branches.
- **Buried happy path.** The common case lives in the deepest `else`. Detect: the first branch handles the rarest case.
- **Scattered setup.** A variable is prepared at the top and used forty lines later. Detect: a long distance between a statement and its only consumer.
- **Index juggling.** `i`, `j`, `k` updated in several places. Detect: assignments to the counter in more than one statement.

## Trade-offs and exceptions

- Some algorithms need an index or two cursors (merging, binary search); then the clarity comes from a comment on the invariant, not from removing the indices.
- Separating passes can cost a second traversal. Keep one pass when the data is large and the measured cost matters (`$code-complete:performance-tuning`), and keep the responsibilities readable inside it.
- The source's caution is about unusual control structures where an ordinary alternative is clearer. Added judgment: recursion over tree-shaped data is the ordinary alternative there, not an unusual structure.
- Inverting a condition is wrong when the positive form is longer or less natural; the rule says "when possible".

## Verification

- [ ] Each loop's start, stop and step fit in one sentence, and the counter changes in one place.
- [ ] No loop exit depends on a flag set elsewhere in the body.
- [ ] Each loop body does one kind of work per pass.
- [ ] No condition in the change is double-negated.
- [ ] The common case is the first branch or the fall-through.
- [ ] Empty, single-element and last-element inputs are covered by tests.

## Related

`$code-complete:control-flow` for nesting, compound conditions and exits; `$code-complete:table-driven` for repeated mappings; `$code-complete:variables` for loop variables; `$code-complete:routine-testing` for boundary cases; `code-complete-control-flow-reviewer` to review a diff.

## Source

- `Statement, Conditional, and Loop Rules`
- `Control Flow Rules`: only the anti-pattern on complicated loop exits with hidden state changes.
