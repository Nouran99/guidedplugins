---
name: comments
description: "Use when adding, reviewing or deleting comments, TODO notes or commented-out code, or when a comment explains what code does. Covers the five legitimate comment categories, noise removal, comment-heavy code and TODO policy."
---

# Comments

Decides which text may stay in a source file after the code has been made as clear as it can be. Making the code clearer is the work of `/clean-code:naming` and `/clean-code:function-shape`; this skill runs after them.

## When to use

- You are about to write a comment, or a diff adds one.
- A comment explains a condition, a block, a variable or a loop.
- Code contains `TODO`, `FIXME`, banners, change logs, closing-brace markers or commented-out code.
- A comment mentions a name, a behavior or a number that no longer matches the code.

## Rules

1. **Do not use comments to compensate for bad naming or bad structure.** Check: delete the comment in your head; could a rename, a named predicate or an extracted function carry the same information?
2. **Improve the code first, then decide whether a comment is still needed.** The order matters: writing the comment first anchors you to the weak code. Check: the diff shows the code change before any comment remains.
3. **Prefer self-explanatory code.** Check: a reader who skips every comment still understands what the code does.
4. **Use comments only for information the code cannot express well.** The legitimate categories are: legal or licensing requirements; non-obvious intent; important warnings or constraints; rationale for a surprising decision; clarification of external behavior or protocol assumptions. Check: you can assign every remaining comment to one of the five.
5. **Remove redundant, obsolete, obvious, noisy and misleading comments.** Check: no comment merely repeats the next line, announces a section, records who changed what, or marks a closing brace. Delete commented-out code; version control remembers it.
6. **Do not narrate the code line by line.** A comment per line means the code is not reading as a story. Check: more than one comment inside a short function is a prompt to extract and name.
7. **Keep comments precise, and maintain them when the code changes.** Check: every identifier, unit and number in a comment still exists and still matches; a diff that changes the logic under a comment also touches or confirms the comment.
8. **Avoid TODO comments unless they are actionable, specific and necessary.** Check: the TODO says what to do, why it cannot be done now, and what would trigger doing it; the repository has a convention for linking an issue.
9. **Say why and under what constraint, not what.** Check: warnings state the consequence ("returns stale data for up to 60 seconds after a write"), and rationale states the alternative that was rejected.
10. **Write the comment where the surprise is.** A constraint belongs next to the line that would be "fixed" by a well-meaning reader. Check: the comment is adjacent to the code it protects, not at the top of the file.

## Procedure

1. List the comments in and around the touched code.
2. For each, try to remove it by improving the code: rename, extract a function, introduce a named constant or predicate.
3. Classify what remains with the five categories in rule 4. Delete what fits none.
4. Rewrite survivors to state the reason or constraint in one or two sentences.
5. Check for staleness: names, units, thresholds and behaviors mentioned in the comment.
6. Convert vague TODOs into actionable ones, or delete them. Do not invent issue numbers.

## Example

```java
// Before
// check if the member is allowed to borrow
if (m.getStatus() == 2 && m.getFines() < 500 && !m.isBlocked()) {
    // loop through the requested items
    for (Item i : items) {
        // lend it
        ledger.add(new Loan(m, i));
    }
}

// After
if (member.canBorrow()) {
    items.forEach(item -> ledger.add(new Loan(member, item)));
}

// The catalog service returns HTTP 200 with an empty body when an item is
// withdrawn, so check for emptiness before trusting the status code.
if (isWithdrawn(response)) { ... }
```

Three narrating comments are gone because names carry them. The last comment stays because it states an external behavior the code cannot express.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Translation comment | A comment precedes a condition or block and restates it in prose | Named predicate or extracted function; delete the comment |
| Noise | Banners, bylines, change logs, `// end if`, `// constructor` | Delete |
| Commented-out code | Lines of code inside `//` or `/* */` | Delete; history has it |
| Stale comment | Mentions parameters, units or defaults that differ from the code | Update or delete in the same change |
| Vague TODO | `TODO: fix this`, no condition, no owner convention | Make specific or delete |
| Section header inside a long function | Comment lines acting as chapter titles | Extract each section as a function with that title |
| Comment-heavy code | More comment lines than code in a block | Refactor until the comments are unnecessary |

## Trade-offs and exceptions

- Public API documentation comments required by the repository's tooling follow the repository convention. Keep them accurate and say what the signature cannot: units, ranges, failure behavior.
- A short comment is cheaper than a contorted rename when the real reason is an external fact (a vendor quirk, a regulatory rule). That is category four or five, and it belongs.
- License headers are a legal requirement where the project demands them; do not strip them.
- Do not mass-delete comments in files you did not otherwise change. Cleanup stays within the touched code.

## Verification

- [ ] Each remaining comment fits one of the five legitimate categories.
- [ ] No touched comment restates the line under it or compensates for a weak name.
- [ ] No commented-out code remains in the touched lines.
- [ ] Every number, unit and name mentioned in a touched comment matches the code.
- [ ] Each TODO is specific, actionable and necessary, or was removed.

## Related

`/clean-code:naming` and `/clean-code:function-shape` to remove comments by improving code; `/clean-code:smells-surprise` when the surprise itself should be fixed instead of documented; `clean-code:comment-reviewer` to review a diff.

## Source

- `Comment rules`
- `Smells to detect and eliminate`: only the comment-heavy code smell.
- `Hard rules`: only the rule against comments where better code would remove the need.
