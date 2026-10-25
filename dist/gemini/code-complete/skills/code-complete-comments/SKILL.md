---
name: "code-complete-comments"
description: "Use when adding, reviewing or deleting comments, or when a comment restates code, is stale, or props up unclear code. Comments keep intent, rationale, contracts. Style and layout: code-complete-coding-standards."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Comments

Decides what a comment may say and when it must go: intent, rationale, contracts and non-obvious facts stay; narration of obvious code, stale text and apologies for unclear structure do not. How code is formatted, named and arranged is `code-complete-coding-standards`.

## When to use

- You are about to write a comment that explains what the next line does.
- A comment sits above a block that would be clear with a better name or a smaller routine.
- Code changed and a nearby comment may no longer be true.
- A routine was drafted as pseudocode comments (`/code-complete:pseudocode`) and now needs pruning.
- A public routine or a tricky decision has no explanation of its contract or reason.

## Rules

1. **Explain intent, rationale, contracts and non-obvious facts.** Why: these are the things the code cannot say. Check: each comment answers "why", "what must hold" or "what is surprising", not "what does this line do".
2. **Do not comment obvious code instead of improving it.** Check: for each "what" comment, ask which rename or extraction would make it unnecessary; do that and delete the comment.
3. **Keep comments accurate or delete them.** Why: a stale comment misleads more than none. Check: every comment on a line you changed was re-read and is true, in the same change.
4. **Prefer self-documenting structure first, comments second.** Check: names, routine boundaries and types carry the meaning; comments cover what remains.
5. **After pseudocode becomes code, keep only comments that still add intent, constraints or rationale.** Check: step-by-step narration comments from the sketch are removed; a comment remains only if the code beneath it does not state the same thing.
6. **Add documentation where the code cannot express intent, constraints or usage.** Check: public routines and non-obvious modules state their purpose, assumptions, limitations and how to use them.
7. **Keep a comment close to what it describes and accurate to it.** Compact rule. Check: no comment is separated from its code by unrelated lines.
8. **Do not leave obvious comments over bad code.** Forbidden pattern. Check: no comment exists to apologize for a block that should be rewritten.
9. **Do not leave stale comments that mislead.** Forbidden pattern. Check: no comment contradicts the code beneath it.
10. Added judgment: write the contract (requires, ensures, units, failure behavior) as the routine's documentation comment; it is the information callers need and the code cannot hold (`code-complete-assertions-and-contracts`).
11. Added judgment: record the reason for a surprising choice (a workaround, a measured optimization, an ordering that matters) at the code, with enough detail to know when it is safe to remove.
12. Added judgment: do not keep commented-out code. Version control remembers it; the comment only hides what is live.

## Procedure

1. List the comments in the touched region and classify each: intent or rationale, contract, non-obvious fact, narration of the next line, stale, apology, commented-out code.
2. For each narration comment, apply a rename or extraction from the owning skill and delete the comment.
3. For each stale or contradicting comment, correct it from the code, not from memory of the code; if you cannot tell what is true, find out before keeping it.
4. Add missing contract or rationale comments where a caller or maintainer would otherwise guess.
5. Delete commented-out code.
6. Re-read: the remaining comments should be few and each should tell you something the code does not.

## Example

```ts
// Before: narration, an apology, and a stale claim
// loop through users
for (const u of users) {
  // check if the user is active (also checks admin)   <- stale: admin check was removed
  if (u.status === 2) {
    // add to list
    result.push(u);
  }
}

// After: names carry the meaning; the one comment records a decision the code cannot show
const ACTIVE = UserStatus.Active;

// Suspended users are excluded on purpose: billing must not email them (see ticket BILL-212).
const activeUsers = users.filter((u) => u.status === ACTIVE);
```

The surviving comment gives a reason and a pointer. It does not say what the line does.

## Anti-patterns

- **Narrating comment.** `// increment i`. Detect: the comment could be generated from the next line.
- **Apology comment.** `// hack, fix later` over unclear code. Detect: the comment signals discomfort without a reason or an owner; rewrite the code or state the real constraint.
- **Stale comment.** Describes behavior that was removed. Detect: names, parameters or conditions in the comment that no longer exist.
- **Commented-out code.** Blocks of dead statements. Detect: code-shaped text inside comments.
- **Distant comment.** Explains a line that is screens away. Detect: unrelated statements between the comment and its subject.
- **Missing why.** A surprising workaround with no explanation. Detect: an odd ordering, sleep, constant or special case with no reference.

## Trade-offs and exceptions

- Public API documentation (doc comments that tools extract) is a different job from inline comments; the source asks for documentation where code cannot express usage, so keep it even when the routine name is clear.
- Pseudocode comments are fine while the routine is being designed; they are scaffolding to prune, not a style to keep (`/code-complete:pseudocode`).
- Comments in languages or domains where the repository requires headers or license text follow the repository (`code-complete-coding-standards`).
- Added judgment, a caution rather than an exception to the accuracy rule: before deleting a comment you cannot verify, check it against the history or ask, because it may record a reason. A comment that stays unverified and unexplained is deleted or rewritten.

## Verification

- [ ] No comment in the touched code restates the next line.
- [ ] Every comment near a changed line was re-read and is still true.
- [ ] Each remaining comment gives intent, rationale, a contract or a non-obvious fact.
- [ ] No commented-out code remains.
- [ ] Public routines have their contract documented.

## Related

`code-complete-coding-standards` for form and layout; `code-complete-routine-design` and `code-complete-data-types` for the names that replace comments; `/code-complete:pseudocode` for pruning sketch comments; `code-complete-comment-reviewer` to review a diff.

## Source

- `Comment Rules`
- `Comment-as-Crutch`
- `Pseudocode Programming Process`: only the rule to keep comments that still add intent, constraints or rationale after conversion.
- `Performance, Integration, Tools, and Craftsmanship`: only the rule to prefer self-documenting code and add documentation where code cannot express intent.
- `Review Rules`: only the item on comments compensating for poor structure.
