---
name: "change-locality"
description: "Use when one change forces edits across many classes (shotgun surgery), one class changes for unrelated reasons (divergent change), or the same logic is repeated (duplicate code). Decides how to centralize or leave duplication; timing of the third copy is when-to-refactor."
---

# Change locality

Owns three smells about where knowledge lives: Divergent Change (one place, many reasons), Shotgun Surgery (many places, one reason) and Duplicate Code (many places, same knowledge). Which class should own a given piece of logic is `$refactoring-guru:behavior-ownership`; when the third copy has arrived is `$refactoring-guru:when-to-refactor`.

## When to use

- A single requirement (a new field, a rule change, a new status) means small edits in many files.
- The same class appears in your diff for unrelated requirements, for example SQL, display and an integration call all in one class.
- Two fragments are identical or do the same job under different wording.
- A review comment says "this logic is also in X".

## Rules

1. **Treat Divergent Change as one class that must change for many unrelated reasons, and use Extract Class** (`SHOULD`). Check: list the last few reasons the class changed; if they group into two or more independent groups, each group is a responsibility.
2. **Separate product behavior, display behavior, persistence behavior and integration behavior when they evolve independently** (`SHOULD`). Check: a change to a report layout does not require touching pricing code.
3. **Use superclass or subclass extraction for Divergent Change only when the shared behavior is genuine** (`SHOULD`). Inheritance used to avoid a clear responsibility split is the risky rung. Check: the shared part is real behavior or data, not a common prefix of names.
4. **Treat Shotgun Surgery as one conceptual change forcing many small edits across many classes, and centralize the scattered responsibility** (`SHOULD`). Check: count the files touched by the last change of this kind; after centralizing, the count drops.
5. **Move methods and fields to the owner of the changing concept** (`SHOULD`), using Inline Class or Extract Class where that puts related changes in one place. Check: the next change of this kind has one main edit site.
6. **Do not leave knowledge scattered after the pattern is visible** (`MUST NOT`). Adding forwarding layers without reducing edit sites is the risky rung. Check: the new code removed edit sites instead of adding hops.
7. **For Duplicate Code in one class, use Extract Method** (`SHOULD`); for sibling classes, pull up or extract a superclass; when the duplicate behavior belongs to a separate concept, use Extract Class. Check: the shared code has one home and a purpose-stating name.
8. **Remove accidental duplication even when the fragments are not textually identical** (`SHOULD`). Check: two fragments that do the same job under different wording were compared on behavior, not on text.
9. **Do not merge duplicates that are only coincidentally similar and likely to diverge for different reasons** (`MUST NOT`); you `MAY` leave duplication when merging would make the code less intuitive or create the wrong abstraction. Check: you can name the single reason both fragments change.
10. **Do not replace duplication with an abstraction that has a worse name than the duplicated code** (`MUST NOT`). Check: reading the call site is easier than reading the two fragments were.
11. **Respect the Rule of Three for timing** (see `$refactoring-guru:when-to-refactor`): tolerate a second similar occurrence when the abstraction is uncertain, consider refactoring at the third. Check: the number of occurrences is stated.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Divergent Change | Extract Class | Extract Superclass or Extract Subclass for genuine shared behavior | Inheritance used to avoid clear responsibility splits |
| Shotgun Surgery | Move Method and Move Field to centralize ownership | Inline Class or Extract Class | More forwarding layers without fewer edit sites |
| Duplicate Code | Extract Method | Pull up or Extract Superclass for siblings; Extract Class for a separate concept | Merging coincidental similarity |

## Procedure

1. Write the change story: "to add X, edit these files". Added judgment: use `git log --stat` on a past change of the same kind to see the real edit sites.
2. For a class that appears in unrelated changes, list its reasons to change from history or from the methods.
3. For duplicates, put the two fragments side by side and answer: same reason to change? same name possible?
4. Pick the preferred rung; centralize in one step; migrate the scattered sites one at a time, running tests after each.
5. Stop when the edit-site count for the change story is down to the owner (`$refactoring-guru:stop-and-defer`).

## Example

The free-shipping rule is written out in three files. Adding a second tier would touch all three.

```ts
// Before
// cart.ts
const banner = subtotal >= 50 ? "Free shipping" : `Add ${50 - subtotal} more for free shipping`;
// checkout.ts
const shipping = subtotal >= 50 ? 0 : 6;
// emails.ts
const line = subtotal >= 50 ? "Shipped free" : "Shipping: $6";

// After: one owner for the rule
// shipping-policy.ts
const FREE_SHIPPING_FROM = 50;
const FLAT_SHIPPING_FEE = 6;
export const shippingPolicy = {
  fee: (subtotal: number): number => (subtotal >= FREE_SHIPPING_FROM ? 0 : FLAT_SHIPPING_FEE),
  remainingForFree: (subtotal: number): number => Math.max(0, FREE_SHIPPING_FROM - subtotal),
};
// cart.ts
const banner = shippingPolicy.fee(subtotal) === 0
  ? "Free shipping"
  : `Add ${shippingPolicy.remainingForFree(subtotal)} more for free shipping`;
// checkout.ts
const shipping = shippingPolicy.fee(subtotal);
```

The email line keeps its own wording (it is presentation) but asks `shippingPolicy.fee` instead of repeating the numbers. The threshold and the fee now change in one place.

## Anti-patterns

- **Forwarding layer.** A new `ShippingService` that only calls the three old places. Detect: the edit-site count for the change story did not drop.
- **Coincidence merge.** One helper for two rules that happen to share a formula. Detect: the helper grows a boolean or mode parameter within weeks.
- **God owner.** Everything about a concept moved into one class that now changes for many reasons. Detect: the new class appears in unrelated changes (Divergent Change).
- **Inheritance as glue.** A shared superclass created to hold duplicated code. Detect: the superclass has methods that no subclass honestly "is".
- **Weak name.** The extracted function is `process` or `handle`. Detect: the call site reads worse than the original code.

## Trade-offs and exceptions

- Duplication may stay when the shared abstraction would be less obvious than the duplication, or would be the wrong abstraction.
- Divergent Change and Shotgun Surgery pull in opposite directions; centralizing too far produces the first, scattering too far produces the second. Added judgment: decide by the reasons each piece changes, not by file count or class size.
- Cross-sibling duplication under inheritance can be treated by pull-up only when the superclass contract can honestly own the member (see `$refactoring-guru:hierarchies`).

## Verification

- [ ] The change story or reasons-to-change list was written down.
- [ ] The edit-site count for the story is lower after the change, or the class has fewer reasons to change.
- [ ] Merged duplicates share a single reason to change.
- [ ] The new name states a purpose.
- [ ] No forwarding layer was added without reducing edit sites.

## Related

`$refactoring-guru:when-to-refactor` for the Rule of Three; `$refactoring-guru:behavior-ownership` for who owns logic; `$refactoring-guru:moving-features` and `$refactoring-guru:composing-methods` for mechanics; `refactoring-guru-change-locality-reviewer` to review a diff.

## Source

- `Change Preventers`: only the Divergent Change and Shotgun Surgery entries.
- `Divergent Change`
- `Shotgun Surgery`
- `Dispensables`: only the Duplicate Code entry.
- `Duplicate Code`
- `Rule of Three`: only the timing rule referenced in rule 11.
- `Smell-to-Treatment Priority Map`: only the Divergent Change, Shotgun Surgery and Duplicate Code rows.
- `Decision Anti-Patterns`: only the rule on abstractions with a worse name than the duplication.
- `Generalization Safety`: only the pull-up precondition mentioned in the trade-offs.
