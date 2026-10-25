---
name: "code-complete-routine-design"
description: "Use when writing or reviewing a routine's body and name: unclear purpose, a name that does not fit, validation, computation and side effects mixed, hidden effects. Signatures: code-complete-routine-interface. Tangles across routines: code-complete-complexity-management."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Routine design

Judges one routine: its purpose, its name, whether its phases are separated and whether its effects are visible. Parameters, flags and return values are `code-complete-routine-interface`; tangles that span many routines are `code-complete-complexity-management`.

## When to use

- A routine is hard to name, or its name describes how it works instead of what it achieves.
- A routine validates, computes and writes in one body.
- A caller is surprised by something the routine changed.
- You are about to add one more responsibility to a routine that already does several things.

## Rules

1. **Give a routine one clear purpose.** Why: a routine with several purposes changes for several reasons and is verified against none of them. Check: you can state the purpose in one sentence without "and" or "then".
2. **Name the routine for its result or action.** Why: callers rely on the name, not the body. Check: the name stays true if the implementation is swapped; a name containing a data structure or algorithm (`loopOverUsersAndFilter`) is describing implementation.
3. **Separate setup, validation, computation and side effects when they are conceptually different.** Why: each can then be understood, tested and reused alone. Check: you can point to where one phase ends and the next begins, and the computing phase writes nothing outside its result.
4. **Prefer guard clauses and straightforward structure over deeply nested logic.** Why: the normal path stays visible. Check: preconditions and rare cases leave at the top; depth inside the body is judged by `code-complete-control-flow`.
5. **Do not hide side effects.** Anti-pattern in the source: many hidden side effects. Check: every write to state outside the routine (fields, globals, files, caches, network) is implied by the name or stated in its documentation.
6. **Do not let a routine do several unrelated things.** Source anti-pattern. Check: the routine has no two blocks that could change independently of each other.
7. **Do not name by implementation detail.** Source anti-pattern. Check: renaming the data structure or the library inside would not require renaming the routine.
8. **Keep routines reasonably small as a consequence of purpose, not as a target.** The source asks for focused routines that are "reasonably small" and gives no line count. Added judgment: a long routine with one purpose and straight-line structure can be correct, and a short routine that mixes phases is still bloated; judge purpose first, length second.
9. **Make the routine hard to misuse by what it returns and requires.** Return and parameter design are in `code-complete-routine-interface`; here check that the routine does not demand a call order that its name does not reveal.
10. Added judgment: split at the first line where a reader must switch from one level of detail to another (from "what the business step is" to "how bytes are parsed"); that line is usually a phase boundary.
11. Added judgment: for a complex routine, write the steps as pseudocode first (`/code-complete:pseudocode`); mixed phases show up in the sketch before any code exists.

## Procedure

1. Write the purpose sentence for each changed routine. If it needs "and", mark it.
2. List the phases the body contains in order (setup, validation, computation, side effects). Note any phase that appears twice or in an unexpected order.
3. List every effect outside the return value. Compare with the name and documentation.
4. Split along phase boundaries: first extract the pure computation, then the validation, leaving the effects in the outer routine. Run the tests after each extraction.
5. Rename any routine whose name no longer matches, and any whose name describes implementation.
6. Re-read the outer routine: it should read as a short sequence of named steps at one level of detail.

## Example

```ts
// Before: one routine validates, prices, stores and notifies; its name hides the last two
async function checkout(cart: Cart, user: User): Promise<void> {
  if (cart.items.length === 0) throw new Error("empty cart");
  let total = 0;
  for (const item of cart.items) total += item.unitPriceCents * item.quantity;
  if (user.isMember) total = Math.round(total * 0.9);
  await db.orders.insert({ userId: user.id, totalCents: total, items: cart.items });
  await mailer.send(user.email, "Order received", `Total: ${total / 100}`);
}

// After: the pure phase is separate; the effects are named in the routine's name and visible in its body
const MEMBER_PRICE_FACTOR = 0.9;

const formatCents = (cents: number): string => (cents / 100).toFixed(2);

function requireNonEmptyCart(cart: Cart): void {
  if (cart.items.length === 0) throw new Error("empty cart");
}

function priceCart(cart: Cart, user: User): number {
  const subtotalCents = cart.items.reduce((sum, i) => sum + i.unitPriceCents * i.quantity, 0);
  return user.isMember ? Math.round(subtotalCents * MEMBER_PRICE_FACTOR) : subtotalCents;
}

async function placeOrderAndNotify(cart: Cart, user: User): Promise<void> {
  requireNonEmptyCart(cart);
  const totalCents = priceCart(cart, user);
  await db.orders.insert({ userId: user.id, totalCents, items: cart.items });
  await mailer.send(user.email, "Order received", `Total: ${formatCents(totalCents)}`);
}
```

An empty cart is an expected business outcome, so the guard is a validation that names what it requires, not an assertion (see `code-complete-assertions-and-contracts` for the difference). The old message printed `total / 100`, which shows `12.5` for 1250 cents; moving the formatting into `formatCents` (defined above) is a visible behavior fix, so call it out in the change description.

## Anti-patterns

- **Do-everything routine.** Validates, computes, persists and notifies. Detect: a body with comments such as "now save" or "then email".
- **Implementation-named routine.** `parseWithRegexAndCache`. Detect: the name mentions a mechanism rather than a result.
- **Silent writer.** A getter or `calculate*` routine that updates a field or a cache entry. Detect: assignments to fields or globals in a routine named like a query.
- **Order-dependent pair.** Two routines that only work when called in sequence, with nothing in their names saying so. Detect: a documented "call X before Y".

## Trade-offs and exceptions

- Small orchestration routines legitimately call several phases in order; that is the purpose ("place an order"), as long as each step is a named call.
- A routine that must be one unit for performance or atomicity (a single transaction body) may keep its phases together; mark the phases with clear structure and keep the reason with the code.
- The source's "reasonably small" is a judgment, not a limit; do not split a cohesive routine into fragments whose names only restate the lines they replaced.

## Verification

- [ ] The purpose of each changed routine fits in one sentence without "and".
- [ ] The name describes the result or action, not the mechanism.
- [ ] Setup, validation, computation and side effects are separated or the reason they are not is stated.
- [ ] Every effect outside the return value is visible in the name or documentation.
- [ ] The tests ran after each extraction and before and after the change.

## Related

`code-complete-routine-interface` for parameters and returns; `code-complete-control-flow` for nesting inside the body; `code-complete-complexity-management` for tangles across routines; `/code-complete:pseudocode` to design a routine before writing it; `code-complete-routine-reviewer` to review a diff.

## Source

- `Routine Design Rules`
- `Routine Bloat`
- `Review Rules`: only the items on weak routine boundaries, hidden side effects and unclear names.
- `Review Checklist`: only the question on focused and reasonably small routines.
