---
name: explicit-concepts
description: "Use when a boolean, status code, enum, flag, magic string or helper method carries a business decision, or code could belong to any business. Promotes hidden concepts to named ones. For repeated data values use /ddd-distilled:value-objects; for names alone, /ddd-distilled:ubiquitous-language."
---

# Explicit concepts

Find the business idea hiding behind a flag, a status number, a boolean parameter, an enum switch or a `Utils` method, and give it a name and a home. This skill changes structure; the words themselves are `/ddd-distilled:ubiquitous-language`, and repeated data values that need validation are `/ddd-distilled:value-objects`.

## When to use

- A function takes a boolean whose `true` and `false` stand for different business situations.
- A numeric or short-string status carries meaning and the legend lives in someone's head.
- The same `switch` on a type field appears in several places, each with different business behavior.
- A helper or service holds a rule that the business would call by a name.
- The code is generic enough to belong to any company.

## Rules

1. **Prefer code that teaches the model to a reader.** A reader should learn the business from the code. Check: ask a newcomer what a function does and why; the answer should come from the names alone.
2. **Make domain assumptions explicit in names, tests and events.** An assumption that lives only in a comment or a head is silently broken later. Check: each non-obvious business assumption has a named place in code and a test that states it.
3. **Where a concept is fuzzy, do not hide the ambiguity behind a technical abstraction.** A generic `Rule` or `Handler` that "can do anything" postpones the question. Check: the unclear concept is named as unresolved, put to a person who knows the business, or recorded as modeling debt (`/ddd-distilled:modeling-debt`).
4. **Do not leave unexplained status codes and flags with domain meaning.** Check: no bare integer or short string stands for a business state without a named type or constant set.
5. **Do not use enums and booleans where a richer concept is needed.** Check: a boolean flips between two business situations; an enum is switched on in several places with different behavior per value; two booleans combine into states of which some are invalid.
6. **Do not write generic code that could belong to any business.** Check: a class or function name contains nothing from this domain and its parameters are untyped bags.
7. **Promote primitives, flags, status codes, enums and booleans that carry domain rules to a richer concept or a value object.** (Compact checklist) Check: the rule that used to sit next to the flag now sits on the concept.
8. **When a controller, helper or service holds a business decision, name the missing concept and move the decision onto it.** (Compact checklist) Check: the decision has a name, lives in one place, and can be tested without the surrounding code.
9. **Choose the smallest form that fits.** (Added judgment) A value with rules is a value object; a state that changes over time is a lifecycle on an entity; a decision over data is a named policy or specification; a repeated lookup is a named query. Check: you did not default to a class hierarchy.
10. **Model combined booleans as states.** (Added judgment) Two booleans give four combinations; if only three are legal, name the three. Check: no impossible combination can be constructed.

## Procedure

1. Search the change for boolean parameters, `status`, `type`, `kind`, `flag` fields, `switch` on them, and `Utils`/`Helper` methods with business logic.
2. For each, say what business decision it carries in one sentence a domain expert would accept. If you cannot, treat it as a fuzzy concept (rule 3).
3. Pick the smallest form (rule 9) and name it with a business word.
4. Move the decision onto the new concept, update the callers, and delete the flag when nothing reads it.
5. Add a test in the concept's own language.

## Example

```ts
// Before: three hidden concepts in one function
function canBorrow(
  member: { active: boolean; kind: number; unpaidFines: number },
  copiesOnLoan: number,
): boolean {
  if (!member.active) return false;
  if (member.kind === 2) return copiesOnLoan < 10 && member.unpaidFines < 50;
  return copiesOnLoan < 5 && member.unpaidFines < 20;
}

// After: standing, kind of membership and lending allowance are named
type MembershipKind = "standard" | "scholar";

class LendingAllowance {
  constructor(
    private readonly maxCopiesOnLoan: number,
    private readonly maxUnpaidFines: Money,
  ) {}

  permits(member: Member, copiesOnLoan: number): boolean {
    return (
      member.isInGoodStanding() &&
      copiesOnLoan < this.maxCopiesOnLoan &&
      member.unpaidFines().isLessThan(this.maxUnpaidFines)
    );
  }
}

const ALLOWANCES: Record<MembershipKind, LendingAllowance> = {
  standard: new LendingAllowance(5, Money.of(20, "EUR")),
  scholar: new LendingAllowance(10, Money.of(50, "EUR")),
};

// caller: ALLOWANCES[member.kind].permits(member, copiesOnLoan)
```

`active` became `isInGoodStanding()`, `kind: number` became a named union, and the two limits per kind sit in one place. `Member` and `Money` are assumed types.

## Anti-patterns

- **Boolean trap.** Detect: call sites pass a bare `true` or `false` whose meaning needs the signature.
- **Magic status integer.** Detect: comparisons with numeric or string literals that have no named constant.
- **Scattered type switch.** Detect: the same field is switched on in several files.
- **Decision drawer.** Detect: a `Utils` or `Helper` class with conditionals about business rules.
- **Flexible framework for three rules.** Detect: a generic rule engine whose configuration is longer than the rules.

## Trade-offs and exceptions

- A plain boolean is fine when it really is a yes or no with no further meaning, such as a feature toggle.
- Do not build a type for every flag. Stay with the cheapest form that carries the rule; `/ddd-distilled:pattern-economy` is the brake.
- When the concept is genuinely fuzzy and nobody can name it yet, record it as modeling debt rather than inventing a name.

## Verification

- [ ] Every flag, status or enum in the touched code either has a business name or is purely technical.
- [ ] No decision about a business rule remains in a helper or utility.
- [ ] No boolean parameter selects between business behaviors.
- [ ] The new concept has a test written in its own language.
- [ ] The smallest form was used, not a hierarchy by default.

## Related

`/ddd-distilled:value-objects`; `/ddd-distilled:entities` for lifecycle states; `/ddd-distilled:ubiquitous-language`; `/ddd-distilled:application-services`; `ddd-distilled:concept-reviewer` to review a diff.

## Source

- `Collaboration Rules`
- `Value Objects`: only the rule that value objects make code read in domain language.
- `Review Rules`: only the primitive obsession, services containing all behavior and no-value-objects-where-concepts-repeat items.
- `Ubiquitous Language Rules`: only the rule to avoid generic helper or utility names that carry domain decisions.
- `Accelerated Modeling and Project Rules`: only the rule to track modeling debt when code and language are known to be imperfect but deferred.
- `Practicality Rules`: only the rule to use the least expensive pattern that honestly models the problem.
