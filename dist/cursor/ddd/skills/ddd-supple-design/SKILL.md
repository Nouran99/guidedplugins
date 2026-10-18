---
name: "ddd-supple-design"
description: "Use when a domain API hides intent behind technical names, a method both answers and changes state, invariants live only in comments or UI checks, or named rules are combined. Vocabulary: ddd-ubiquitous-language. Creating a rule: ddd-explicit-concepts."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Supple design

Owns how the model's interface reads and behaves for the people who use it: intention-revealing operations, side-effect-free queries, explicit assertions, objects shaped around conceptual contours, and declarative rules that combine readably. Vocabulary alone is `ddd-ubiquitous-language`; creating the named rule objects is `ddd-explicit-concepts`.

## When to use

- A method name says how, not what: `process`, `handle`, `doCalc`, `setFlag`.
- A method both returns an answer and changes state ("get next number" that increments).
- A class needs a dozen collaborators to be understood, or a method's parameters form a hidden concept.
- An invariant is stated only in a comment, a UI validation or a handler.
- Business rules must be combined (and, or, not) or one rule includes another.

## Rules

1. **Design interfaces that reveal intention in domain language.** Callers should not need to read the body to know what happens. Check: the signature and name predict the result and effect.
2. **Name methods after what the business is trying to accomplish.** Check: the method name is a business goal, not a mechanism.
3. **Prefer side-effect-free functions for calculations and queries.** They can be tested, reused and combined without hidden consequences. Check: a calculation returns a value and mutates nothing.
4. **Separate commands from queries where side effects would surprise readers.** Check: no method returns domain information and also changes domain state.
5. **Make assertions and invariants explicit in the model**, and put invariant checks where invalid states enter the model. Check: the constructor or operation that could break the rule contains the check, not a comment.
6. **Shape objects around conceptual contours, not arbitrary technical convenience.** Look for cohesive concepts hidden inside long methods, conditionals or parameter groups. Check: the pieces you would change together are together.
7. **Use standalone classes where a concept can be understood without unnecessary dependencies.** Check: you can explain and test the class with few or no collaborators.
8. **Favor operations that are closed under meaningful domain types when that improves clarity.** An operation whose result has the same type as its arguments composes freely. Check: `Money + Money` returns `Money`, not a bare number.
9. **Use declarative design when it makes rules easier to read, combine and verify.** Consider a domain-specific language only when it simplifies real domain expression. Check: a reader can state the rule from the declaration without tracing control flow.
10. **Combine specifications with AND, OR or NOT only while each component's meaning remains readable.** Check: every part has a business name, and a combination reads as a sentence.
11. **Use subsumption when one specification or category includes another and that relationship matters.** Check: the relationship is stated once (a test or a method), not rediscovered by callers.
12. **Do not use technically named APIs that hide intent, methods that ask and mutate at once, invariants expressed only in comments or UI/application validation, or declarative frameworks that obscure business rules.** Check: grep the touched code for each pattern.

## Procedure

1. Pick the operations callers use most. For each, read only name and signature and write down what you expect.
2. Compare with the body. Any gap is a finding: rename, split command from query, or move the check inward.
3. Separate every method that both returns and mutates into a pure query and an explicit command.
4. Find the parameter groups and long conditionals; ask whether a named concept hides inside (`ddd-explicit-concepts`, `ddd-value-objects`).
5. Make operations on value types return the same type where it clarifies.
6. For combined rules, give each part its own name and test each part; check the combination reads aloud as a business sentence.
7. Move invariants from comments and UI code to the operation that can break them (`ddd-entities`).

## Example

```ts
// Before: the call asks and mutates at once, and the flag hides the rule
function applyLoyalty(order: Order): boolean {
  if (order.total > 100_00) {
    order.total -= order.total * 0.05;
    return true;
  }
  return false;
}

// After: a pure question, an explicit command, and money closed under its own operations
class Money {
  readonly cents: number;

  private constructor(cents: number) {
    this.cents = cents;
  }

  static cents(value: number): Money {
    if (!Number.isInteger(value) || value < 0) throw new RangeError("money is a non-negative whole number of cents");
    return new Money(value);
  }

  minus(other: Money): Money {
    return Money.cents(Math.max(0, this.cents - other.cents));
  }

  percent(rate: number): Money {
    return Money.cents(Math.round((this.cents * rate) / 100));
  }
}

interface LoyaltyDiscount {
  amountFor(subtotal: Money): Money; // side-effect-free
}

class FivePercentOverOneHundred implements LoyaltyDiscount {
  amountFor(subtotal: Money): Money {
    return subtotal.cents > 10_000 ? subtotal.percent(5) : Money.cents(0);
  }
}

class Order {
  private readonly subtotal: Money;
  private discount: Money = Money.cents(0);

  constructor(subtotal: Money) {
    this.subtotal = subtotal;
  }

  applyLoyalty(discount: LoyaltyDiscount): void { // command
    this.discount = discount.amountFor(this.subtotal);
  }

  get amountDue(): Money {
    return this.subtotal.minus(this.discount);
  }
}
```

Combining named rules stays readable while each part has a business name:

```ts
interface Specification<T> {
  isSatisfiedBy(candidate: T): boolean;
}

class And<T> implements Specification<T> {
  private readonly left: Specification<T>;
  private readonly right: Specification<T>;

  constructor(left: Specification<T>, right: Specification<T>) {
    this.left = left;
    this.right = right;
  }

  isSatisfiedBy(candidate: T): boolean {
    return this.left.isSatisfiedBy(candidate) && this.right.isSatisfiedBy(candidate);
  }
}

const needsSpecialHandling = new And(isHazardous, isHeavy); // isHazardous and isHeavy are named specifications
```

## Anti-patterns

- **Mechanism-named API.** Detect: `process`, `execute`, `handle`, `run`, `update` in the model.
- **Asking-and-mutating call.** Detect: a getter or `isX` method that changes state; a command that returns domain data the caller then uses to decide.
- **Comment-only invariant.** Detect: "must be positive" in a comment with no check.
- **Opaque combination.** Detect: nested `and`/`or`/`not` chains of anonymous lambdas.
- **Framework-declared rules.** Detect: business rules spread across annotations or configuration that cannot be read as one statement.

## Trade-offs and exceptions

- Added judgment: a command that returns a result (a created identifier, a success flag) can be practical; the rule is against methods that surprise readers by mixing a query with a hidden change.
- A DSL or declarative framework is worth it only when it simplifies real domain expression; otherwise plain code is clearer.
- Standalone classes are an aim, not a ban on collaboration; Added judgment: count a collaborator only when understanding the class requires understanding the other.

## Verification

- [ ] Names and signatures predict behavior; no body had to be read to trust them.
- [ ] Queries do not mutate; commands are named as actions.
- [ ] Each invariant is checked where an invalid state could enter.
- [ ] Combined rules read as business sentences, and each part is named.
- [ ] No technical mechanism name remains in the model's public API for the touched code.

## Related

`ddd-ubiquitous-language` for vocabulary; `ddd-explicit-concepts` for creating the named rules; `ddd-value-objects` for closed operations; `ddd-supple-design-reviewer` to review a diff.

## Source

- `Supple Design`
