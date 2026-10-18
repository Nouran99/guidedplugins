---
name: "ddd-explicit-concepts"
description: "Use when a flag, status string, repeated condition over several values, rule in a comment or script-like process hides a business concept, or a named rule (specification, policy) is needed. Whole model: ddd-deep-models. One value's validation: ddd-value-objects. Rule shape: ddd-supple-design."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Explicit concepts and specifications

Owns the local move: find the hidden constraint, policy, process or rule in one piece of code and give it a name in the model, usually as a specification or policy. The whole-model judgment is `ddd-deep-models`; how the resulting object's interface reads and combines is `ddd-supple-design`.

## When to use

- The same boolean condition appears in more than one service, handler or query.
- A boolean flag or a `type` string selects between behaviors, or a comment explains a business rule next to code.
- A multi-step business process exists only as a script or a transaction handler, while the business talks about it as a thing.
- An awkward API forces callers to pass the same group of values or to know rules that the callee should own.
- A rule needs to be evaluated for validation, selection or compatibility and then reused.

## Rules

1. **Listen for domain language that is not represented in code.** The experts' nouns and verbs that have no counterpart are missing concepts. Check: list phrases from the conversation with no matching identifier.
2. **Scrutinize awkward APIs, repeated branches and contradictory names.** They are the visible symptoms. Check: each repeated branch is either named or has a stated reason to stay anonymous.
3. **Read domain references, policies, regulations and prior art when they are available.** Existing formal descriptions beat reinvention. Check: the source of each non-obvious rule is named in the test or the type.
4. **Try several model shapes before settling on one for a complex concept.** Check: two candidates were written down and one was chosen with a reason.
5. **Name the concept before choosing the implementation form.** Check: the name exists in domain words before you decide whether it is a value object, a policy, a specification or a service.
6. **Promote hidden constraints, policies and processes into explicit domain concepts, and prefer clear domain objects over anonymous helpers when behavior has business meaning.** Check: no `utils` function holds a business rule.
7. **Extract repeated conditionals into named domain concepts.** Prefer named concepts such as a free-shipping policy or an allocation rule over anonymous boolean expressions. Check: the same business condition has exactly one definition.
8. **Use specifications for named, combinable business rules that answer whether something satisfies a criterion.** They serve policy, validation, selection and compatibility. Check: the rule is testable on its own with candidate objects, with no database.
9. **Keep specifications in domain language, not query language.** Keep persistence querying separate from domain specifications unless the project deliberately provides a translation. Check: the specification imports no query builder or ORM type.
10. **Model a domain process as a domain object when the process has business meaning.** Check: the business has a word for it and the code has a type with that word.
11. **Do not treat a contradiction as an edge case, and do not keep a vague technical flag after the real concept is known.** Check: no flag remains whose true values the code cannot name in business words.
12. **Reach for established formalisms and analysis patterns when the domain already has mature concepts, but adapt them to the context and validate them against local language** (the rule set's Analysis Patterns slice; `ddd-pattern-fit` runs the full fit test). Check: the imported structure uses the local term for every part.

## Procedure

1. Mark the candidate: a flag, a branch that appears twice, a rule in a comment, or a process in a script.
2. Write what the business would call it and the question it answers ("Does this order qualify for free shipping?").
3. Decide its shape: a value object if it describes, a specification if it answers yes or no about a candidate, a policy if interchangeable behavior varies by case, a domain object if it is a process with its own lifecycle.
4. Move the logic into it, give it tests in domain language, and replace every duplicate caller.
5. Delete the flag, comment or duplicate condition. Added judgment: if the concept appears only once and has no business name, leave the code alone and say so.

## Example

```ts
// Before: the same condition lives in checkout, the invoice mailer and a report
if (order.customer.tier === "gold" && order.total > 500 && !order.items.some((i) => i.restricted)) {
  shippingFee = 0;
}

// After: the rule has a name, one definition and its own tests
interface Specification<T> {
  isSatisfiedBy(candidate: T): boolean;
}

class QualifiesForFreeShipping implements Specification<Order> {
  private readonly threshold: number;

  constructor(threshold: number) {
    this.threshold = threshold;
  }

  isSatisfiedBy(order: Order): boolean {
    return (
      order.customer.tier === "gold" &&
      order.total > this.threshold &&
      !order.items.some((item) => item.restricted)
    );
  }
}

if (new QualifiesForFreeShipping(500).isSatisfiedBy(order)) {
  shippingFee = 0;
}
```

## Anti-patterns

- **Rule in a comment.** Detect: a comment that states a business rule above a conditional.
- **Anonymous boolean.** Detect: a compound condition duplicated across files, or a function `check`/`validate` with no domain noun.
- **Flag that hides a concept.** Detect: a boolean parameter or `type` string whose values the business names differently.
- **Specification as query builder.** Detect: a specification that returns a SQL fragment or ORM criteria.
- **Process as script.** Detect: a handler with ten sequential steps that the business describes as one named activity.

## Trade-offs and exceptions

- The source asks to extract repeated conditionals into named concepts. Added judgment: do not extract a condition that appears once and carries no business meaning; extraction needs a concept, not only a repetition.
- The source keeps persistence querying separate from domain specifications unless the project deliberately provides translation. Added judgment: when it does, keep the domain rule and the query-side translation distinct and test them against each other (`ddd-repositories`).
- Combining specifications with `and`, `or`, `not` is allowed only while each part stays readable (`ddd-supple-design`).

## Verification

- [ ] The new name is a business word, written before the implementation form was chosen.
- [ ] Every duplicate of the old condition now calls the one definition.
- [ ] The concept has tests that use candidates, not infrastructure.
- [ ] No query-language type appears in the specification.
- [ ] The flag, comment or branch it replaced is gone.

## Related

`ddd-deep-models` for the whole-model stance; `ddd-supple-design` for combining and reading specifications; `ddd-pattern-fit` before importing a pattern; `ddd-concept-reviewer` to review a diff; `ddd-behavior-mover` to relocate rules that already have an owner.

## Source

- `Making Implicit Concepts Explicit`
- `Explicit Concepts and Specifications`
- `Analysis and Model Patterns`: only the analysis-pattern and established-formalism rules.
- `Supple Design`: only the rule to combine specifications with AND, OR or NOT while each component stays readable.
