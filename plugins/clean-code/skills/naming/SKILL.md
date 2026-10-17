---
name: naming
description: "Use when naming or renaming variables, functions, types or constants, or when a reader cannot tell what an identifier means. Covers intention-revealing names, one word per concept, magic numbers and name smells. A comment that props up a weak name is fixed here first (/clean-code:comments)."
---

# Naming

Owns the names family of the smell catalog: vague or misleading names, functions whose name cannot be trusted without reading the algorithm, and magic numbers. Comments that exist only because a name is weak belong to `/clean-code:comments`; synonym drift across a whole tree belongs to `/clean-code:vocabulary-audit`.

## When to use

- You introduce a new identifier, or touch one that made you stop and think.
- A review comment says "what is this?" or a comment sits next to an identifier to explain it.
- Two functions do the same kind of thing under different verbs (`fetch`, `get`, `load`, `retrieve`).
- A literal such as `86400`, `3` or `"A"` carries business meaning.

## Rules

1. **Use intention-revealing names.** The name says why the thing exists and what it stands for, so the reader does not need a comment or the definition. Check: cover the right-hand side of the assignment; can you still say what the variable holds?
2. **Do not use misleading names, overloaded meanings or confusable identifiers.** A name that claims a type or behavior the code does not have is worse than a vague one. Check: `userList` is not a map, `isActive` does not mutate, no `l`/`1`/`O` lookalikes.
3. **Make distinctions meaningful.** Do not create names that differ only cosmetically (`orderData` and `orderInfo`, `copy1` and `copy2`, `theAccount` and `account`). Check: state in one sentence how the two things differ; if you cannot, they should be one thing or have honest names.
4. **Use pronounceable, searchable names.** You must be able to say it in a review and find every use with a text search. Check: grep for the name returns the concept and little else; a one-letter or number-like name that matches half the file fails.
5. **Avoid abbreviations unless they are established domain or platform standards.** `url`, `id`, `http`, `sku` are fine when the team uses them; `cstmrAddr` is not. Check: the abbreviation appears in the team glossary or the platform documentation.
6. **Avoid encodings.** No type prefixes, no implementation hints, no Hungarian notation (`strName`, `arrItems`, `ImplUserStore`). Check: changing the declared type would not make the name wrong. Added judgment: where a platform convention requires a marker (for example an `I` prefix on interfaces in a language whose whole ecosystem uses it), the repository convention wins.
7. **Avoid unnecessary context; add necessary context through the enclosing module, class, namespace or type.** `ShippingAddress.line1` beats `shippingAddressLine1` inside a class named `ShippingAddress`. Check: the prefix repeats the name of the enclosing scope.
8. **Use one word per concept and never use synonyms for the same operation.** Pick `fetch` or `get` or `load` for "obtain from elsewhere" and use it everywhere. Do not reuse a familiar word for a different meaning: if `add` means "insert into a collection", do not also use it for "concatenate two strings". Check: write a concept-to-term table; no concept has two terms and no term has two concepts.
9. **Name types and modules with nouns or noun phrases and functions with verbs or verb phrases.** Check: `Invoice`, `RetryPolicy`; `sendReminder`, `isOverdue`. A function named like a noun hides what it does.
10. **Use problem-domain names for domain concepts and solution-domain names for technical ones.** A billing rule is `LateFee`, not `FeeHandler2`; a queue consumer may honestly be a `Dispatcher`. Check: could a domain expert recognize the domain names?
11. **Do not use cute, funny, cryptic or private-joke names.** `nukeStaleRows()` becomes `deleteExpiredSessions()`. Check: would someone who joined last week guess the meaning?
12. **Give numbers and literals with meaning a name.** A magic number gets a constant, enum or small value type whose name carries the meaning and the unit. Check: no literal other than 0, 1 and obvious identities appears in a condition or calculation without a name.
13. **Rename or restructure a function when its name cannot be trusted without reading its body.** If you must understand the algorithm to believe the name, either the name is wrong or the function does more than it says. Check: read only the signature and the name, predict the effect, then compare with the body.

## Procedure

1. List every identifier in the touched lines that is new, renamed or confusing.
2. For each, run rules 1 to 3 first; they catch most real problems.
3. Search the repository for the existing term for the same concept before inventing one (`grep -rn` the verb or noun). Reuse it.
4. Rename with the language tooling or an exact whole-word search, then check strings, reflection, serialized field names, SQL, config keys, docs and tests for the old name.
5. Treat renames of public API, wire formats and database columns as behavior changes: do not make them silently. Propose them, or keep the old name as a deprecated alias.
6. Run the tests after each batch of renames.

## Example

```ts
// Before
const DAYS = 3;
function chk(u: User, t: number): boolean {
  // true if the trial ran out and they did not pay
  return t - u.ts > DAYS * 86400 && !u.flg;
}

// After
const TRIAL_GRACE_DAYS = 3;
const SECONDS_PER_DAY = 86_400;

function hasTrialLapsed(user: User, nowEpochSeconds: number): boolean {
  const graceEndsAt = user.trialEndedAt + TRIAL_GRACE_DAYS * SECONDS_PER_DAY;
  return nowEpochSeconds > graceEndsAt && !user.hasPaid;
}
```

The comment is gone because the name now carries it, and the unit is part of the constant and parameter names.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Noise-word pairs | Two identifiers differing by `Data`, `Info`, `Item`, `Manager`, a digit or an article | Merge, or rename each to state its difference |
| Type in the name | Prefix or suffix repeating the declared type | Drop it; add context through the enclosing type |
| Synonym drift | `get`/`fetch`/`load`/`retrieve` or `user`/`account`/`member` for one concept | Choose one term, rename the rest, record it in the glossary |
| Overloaded word | Same verb inserts in one class and concatenates in another | Give the second meaning its own word |
| Magic number | Numeric or string literal inside a condition, index or formula | Named constant with unit, or an enum |
| Trust-by-reading name | A name like `process`, `handle`, `doWork` on a function whose effect varies by branch | Rename to the actual effect, or split the function |
| Metaphor or joke | Names borrowed from outside the domain with no shared meaning | Rename in domain or technical terms |

## Trade-offs and exceptions

- Short names are acceptable in a tiny scope when the repository does it (a loop index, a lambda argument, a receiver such as `r` in Go). Added judgment: make the name more descriptive as the scope grows.
- Established abbreviations and domain jargon are allowed; the rule is against invented ones.
- Rename aggressively inside private code. Be careful at published boundaries: public API, serialized names, database columns, event names and configuration keys have consumers you cannot grep.
- When the repository's naming convention is itself the problem, fix new and touched code and note the convention; do not rename the whole tree in a feature change.

## Verification

- [ ] Every new or renamed identifier can be explained without opening its definition.
- [ ] No two touched identifiers differ only cosmetically.
- [ ] Each concept in the touched code uses one term, and the term matches the rest of the repository.
- [ ] No literal with business meaning remains unnamed in the touched lines.
- [ ] No comment remains whose only job was to translate a weak name.
- [ ] A text search for the old names finds no stale references, and the tests pass.

## Related

`/clean-code:comments` for text that remains after names are fixed; `/clean-code:function-contracts` when a name hides an effect; `/clean-code:vocabulary-audit` for tree-wide synonym drift; `clean-code:naming-reviewer` to review a diff.

## Source

- `Naming rules`
- `Smells to detect and eliminate`: only the name, trust-by-reading and magic number smells.
- `Refactoring rules`: only the rule to rename aggressively.
