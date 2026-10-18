---
name: "refactoring-guru-behavior-ownership"
description: "Use when a method works mostly on another object's data (feature envy), a class holds data while clients hold the logic (data class), or two classes depend on each other's internals (inappropriate intimacy). Decides where behavior belongs; the move itself is moving-features."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Behavior ownership

Owns three smells about who owns logic and who may know whose internals: Feature Envy, Data Class and Inappropriate Intimacy. The guiding rule is to keep behavior with the data it changes unless the design deliberately separates them. Paths between objects (chains, forwarders, library gaps) are `refactoring-guru-delegation-and-gaps`; performing the move is `refactoring-guru-moving-features`.

## When to use

- A method reads three fields of another object and none of its own.
- A class is fields plus getters and setters, and its clients compute things from them.
- Two classes call each other's non-public members, or a subclass reaches into its parent's internals and vice versa.
- A review comment says "this belongs on X".

## Rules

1. **Treat a method that uses another object's data more than its own as Feature Envy, and move the behavior to the class that owns the data it mainly uses** (`SHOULD`). Move Method is the preferred rung. Check: count the reads and writes by owner; the majority is the owner.
2. **Before Move Method, inspect which class owns most of the data used by the method** (`MUST`). Check: the count is written down.
3. **When only part of a method envies another object, extract that fragment first** (`SHOULD`), then move it. Check: the moved fragment has a name that fits the target class.
4. **When a method uses several data sources for separable purposes, split it across owners** (`SHOULD`). Check: each part depends on one source.
5. **You may keep behavior separate from data when the separation is intentional, such as interchangeable strategy-like behavior** (`MAY`). Moving such behavior is the risky rung. Check: there is a second implementation or a clear reason for interchangeability.
6. **Do not move behavior away from its data if that creates feature envy in the opposite direction** (`MUST NOT`). Check: after the move, the method uses its new owner's data more than anything else's.
7. **Treat a class that only stores data and exposes crude getters or setters while clients perform the behavior as a Data Class.** Encapsulate public fields and collections first (`SHOULD`). Check: no public mutable field or mutable collection remains.
8. **Move client behavior onto the data class when the behavior operates on that data** (`SHOULD`), and remove broad setters and accessors once meaningful behavior exists (`SHOULD`). Check: callers ask the object to do things instead of reading fields to decide.
9. **Do not stop at getters and setters when the real smell is behavior living outside the data** (`MUST NOT`), and do not add trivial accessors as the final design (`MUST NOT`). Check: review the accessor callers after encapsulation; behavior may belong inside the owner (`SHOULD`).
10. **Treat classes that rely on each other's internals or spend too much time together as Inappropriate Intimacy.** Move methods and fields to reduce private knowledge crossing the boundary (`SHOULD`). Check: the number of non-public members one class touches in the other is lower after.
11. **Extract or hide delegates to reduce unnecessary knowledge of collaborator structure** (`SHOULD`), and replace inheritance with delegation when the intimacy comes from an overexposed subclass relationship (`SHOULD`). Check: the subclass no longer needs its parent's protected state, or the relationship is delegation.
12. **Do not widen visibility to preserve the intimacy** (`MUST NOT`). Check: no member became more visible in the diff unless justified.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Feature Envy | Move Method | Extract Method before moving the envying fragment | Moving behavior that was deliberately separated for interchangeable use |
| Data Class | Encapsulate Field, Encapsulate Collection | Move Method and Extract Method to bring behavior to the data | Stopping after trivial accessors |
| Inappropriate Intimacy | Move Method, Move Field | Hide Delegate; Replace Inheritance with Delegation | Widening visibility to preserve the intimacy |

## Procedure

1. For each suspect method, tally the data it touches by owner (own fields, parameter fields, collaborator fields).
2. For each data-only class, list the clients that read its fields and what they compute from them.
3. For each pair of intimate classes, list the non-public members each touches in the other.
4. Choose the preferred rung. If only a fragment is envious, extract it first.
5. Hand mechanics to `refactoring-guru-moving-features` and encapsulation steps to `refactoring-guru-organizing-data`; run tests after each move.
6. Review the result for envy in the new direction (rule 6).

## Example

Clients decide whether a withdrawal is allowed by reading the account's fields. The rule belongs with the data.

```ts
// Before: a data class, with logic in clients
class Account {
  balance = 0;
  overdraftLimit = 0;
}
function canWithdraw(a: Account, amount: number): boolean {
  return a.balance + a.overdraftLimit >= amount;
}
function withdraw(a: Account, amount: number): void {
  if (!canWithdraw(a, amount)) throw new Error("insufficient funds");
  a.balance -= amount;
}

// After: behavior moved onto the data, fields private
class Account {
  private balance: number;
  private readonly overdraftLimit: number;
  constructor(balance: number, overdraftLimit: number) {
    this.balance = balance;
    this.overdraftLimit = overdraftLimit;
  }
  canWithdraw(amount: number): boolean {
    return this.balance + this.overdraftLimit >= amount;
  }
  withdraw(amount: number): void {
    if (!this.canWithdraw(amount)) throw new Error("insufficient funds");
    this.balance -= amount;
  }
}
```

The rule `balance + overdraftLimit >= amount` now exists once, next to the fields it uses. No getters are added because no caller in this example needs to read the fields; add one only for a caller that has a reason to read it.

## Anti-patterns

- **Accessor ceremony.** Fields hidden behind getters and setters, logic still outside. Detect: every field has a getter and a setter and the class has no other methods.
- **Reverse envy.** A moved method that now reads its former home's fields. Detect: the moved body calls `this.old.get...` repeatedly.
- **Visibility inflation.** `protected` or `public` added to make a move compile. Detect: modifier changes in the diff.
- **Moving a deliberate strategy.** Pulling an interchangeable algorithm into the data holder. Detect: the algorithm has siblings or is selected at runtime.
- **Friend classes.** Two classes that cannot be understood apart. Detect: each imports the other's non-public members.

## Trade-offs and exceptions

- Behavior may stay apart from data when the design intentionally supports interchangeable behavior.
- Plain data carriers at a boundary (transfer shapes read by other systems) are legitimate; the smell is clients repeating logic over a domain class (Added judgment).
- Moving behavior can pull a dependency along with it; if the target would need a much larger collaborator, stop and choose another rung (`refactoring-guru-stop-and-defer`).

## Verification

- [ ] The data-ownership count for each moved method is recorded.
- [ ] No moved method creates envy toward its former owner.
- [ ] No public mutable field or collection remains on a former data class.
- [ ] No visibility was widened to make the move compile.
- [ ] Tests ran after each move.

## Related

`refactoring-guru-moving-features` for Move Method, Move Field and Extract Class; `refactoring-guru-organizing-data` for Encapsulate Field and Encapsulate Collection; `refactoring-guru-delegation-and-gaps` for chains and pass-through layers; `refactoring-guru-coupling-reviewer` to review a diff; `refactoring-guru-responsibility-mover` to act.

## Source

- `Couplers`: only the Feature Envy and Inappropriate Intimacy entries.
- `Feature Envy`
- `Inappropriate Intimacy`
- `Dispensables`: only the Data Class entry.
- `Data Class`
- `Smell-to-Treatment Priority Map`: only the Feature Envy, Data Class and Inappropriate Intimacy rows.
- `Moving Safety`: only the rules on data ownership, deliberate separation and visibility.
- `Encapsulation Safety`: only the rules on reviewing accessor callers and on trivial getters and setters.
- `Safety and Tradeoff Rules`: only the rule to keep behavior with the data it changes.
- `Decision Anti-Patterns`: only the rules on moving behavior away from its data and on stopping at accessors.
