---
name: "sprout-and-wrap"
description: "Use when new behavior must go into fragile code you cannot yet test: sprout method, sprout class, wrap method, wrap class, insert-beside-and-redirect. Reshaping existing code is `$legacy-code:large-methods`; removing dependencies from it is the barrier skills (start at `seams`)."
---

# Sprout and wrap

Add the new behavior beside the old code instead of inside it. The new code is written and tested on its own, and the legacy code gets a small, visible hook. This skill adds behavior without reshaping what exists; reshaping existing code is `$legacy-code:large-methods`, and removing the dependencies that block testing it is the barrier skills (start at `$legacy-code:seams`).

## When to use

- The change adds a rule, a calculation or a step to a long, untested function, and editing the middle of it is risky.
- A new responsibility does not belong in the old class, or the old class is too risky to reshape first.
- You need something to happen before or after a risky method, or you need a better place to observe what it does.
- A class is too hard to test directly and its behavior can be mediated through a new abstraction.

## Rules

1. **Use Sprout Method when new behavior can be added without deeply editing fragile code.** [SHOULD] Check: the new behavior is separable from the legacy flow, with inputs you can pass in.
2. **Extract the new behavior into a new method.** [MUST] Check: the new rule lives in a method with its own name and its own test.
3. **Keep the old code mostly untouched.** [MUST] Check: the legacy body changes only at the insertion point.
4. **Route to the new method from a small insertion point.** [MUST] Check: the insertion is a call and its arguments, with no new branching in the legacy body that you cannot name in one sentence.
5. **Use Sprout Class when a new responsibility does not fit the old class, or the old class is too risky to reshape first.** [SHOULD] Check: you can say what the new class is responsible for in one sentence.
6. **Add a focused new collaborator and delegate to it from the legacy class.** [MUST] Check: the legacy class holds the collaborator and calls it; the new class has no knowledge of the legacy class.
7. **Slowly move behavior over to the new class if later justified.** [MUST] The condition is part of the rule. Check: moves happen as separate, tested steps, not as part of the sprout.
8. **Use Wrap Method when you need pre or post behavior around a risky method, or a better way to observe effects.** [SHOULD] Check: the wrapper adds behavior before or after and does not alter what the wrapped method does.
9. **Use Wrap Class when a class is too hard to test directly and behavior can be mediated through a new abstraction.** [SHOULD] Check: callers use the wrapper's abstraction and the wrapper calls the legacy class.
10. **If the old code cannot be safely changed, insert new code beside it and redirect gradually.** [MUST] Check: the redirect moves callers in small steps, each with tests.
11. **Introduce a focused new class for new behavior.** [SHOULD] This is one of the source's preferred first moves. Check: the class does one thing and has a name that says so.
12. **Fold the temporary structure into better design when tests support it.** [Compact checklist] Check: the plan names the follow-up, or says the structure is permanent and why.
13. **Pass the sprouted unit what it needs, not the legacy object.** [Added judgment] A method that takes plain values can be tested with none of the legacy setup. Check: the new method's parameters are values or narrow interfaces.
14. **Choose by where the new behavior sits.** [Added judgment] In the middle of a flow, at one spot, for a computation: sprout method. A new responsibility with its own state or collaborators: sprout class. Before or after an existing call with the same signature: wrap method. Mediating a whole class: wrap class. Check: the plan states which of the four and why.
15. **Wrap Method mechanics.** [Added judgment] Rename the old method, give the old name to a new method that does the new behavior and calls the renamed one. Check callers that reach the old body directly by its new name: they skip the new behavior.
16. **Test the new unit directly, and cover the insertion point.** [Added judgment] Check: one test exercises the new unit alone, and one pin or characterization shows the legacy flow still reaches it.

## Procedure

1. State the new behavior in one sentence and list its inputs. If the inputs are not available at one point in the legacy flow, stop: the change needs `$legacy-code:test-points` first.
2. Choose among the four by rule 14.
3. Write the new unit test-first, with plain-value inputs.
4. Add the insertion point (a call, or the wrapper), changing as little of the legacy code as possible.
5. Pin the legacy flow around the insertion point if it is not protected (`$legacy-code:characterize`), then run all tests.
6. Record what is temporary; plan the fold-in.

## Example

A rule is added to a long, untested `checkout` function.

```ts
// legacy: orders/checkout.ts (excerpt). Hundreds of lines of unchanged flow around the one new line.
export function checkout(cart: Cart, customer: Customer): Receipt {
  // ... validation, pricing, stock reservation (unchanged) ...
  const total = computeTotal(cart);
  customer.points += loyaltyPointsFor(total, customer.tier);   // the only new line in the legacy body
  // ... payment, receipt (unchanged) ...
  return buildReceipt(cart, total);
}

// sprouted: orders/loyalty.ts. Pure, with plain-value inputs and its own tests.
export function loyaltyPointsFor(totalCents: number, tier: "basic" | "gold"): number {
  const perEuro = tier === "gold" ? 2 : 1;
  return Math.floor(totalCents / 100) * perEuro;
}
```

```ts
it("gives one point per whole euro to basic customers", () => {
  expect(loyaltyPointsFor(1999, "basic")).toBe(19);
});
it("doubles points for gold customers", () => {
  expect(loyaltyPointsFor(1999, "gold")).toBe(38);
});
it("gives nothing below one euro", () => {
  expect(loyaltyPointsFor(99, "gold")).toBe(0);
});
```

And Wrap Method for a behavior that must run before an existing call:

```ts
// the old body keeps its code under a new name; the old name now wraps it
export function postPayment(payment: Payment): void {
  auditLog.record("payment", payment.id);   // new behavior, before
  postPaymentCore(payment);
}
function postPaymentCore(payment: Payment): void {
  // legacy body, untouched
}
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Sprout that reaches back | The new method takes the legacy object and reads its fields | Pass values |
| Branchy insertion | The insertion point adds conditions and loops to the legacy body | Move them into the sprout |
| Untested sprout | New unit with no test of its own | Test it first |
| Wrapper bypass | Internal callers still call the renamed core | Update them or document |
| Permanent scaffolding | Temporary structure with no follow-up | Name the fold-in |
| Sprout as a license | Skipping pins around the insertion point | Pin the neighborhood |

## Trade-offs and exceptions

- Sprout Method applies when the behavior can be added without deep edits; when the new rule must change several branches inside the legacy flow, this skill does not fit: pin, break a dependency and change directly.
- Sprouting leaves the old code as it was, including its problems; the source accepts that and asks for gradual redirection and fold-in.
- Added judgment: wrap only when the wrapped call's order of effects does not matter to the new behavior.
- A rewrite is not a sprout of everything; see `$legacy-code:rewrite-pressure`.

## Verification

- [ ] The new behavior has a test of its own.
- [ ] The legacy body changed only at the insertion point.
- [ ] The insertion point is a call, not new logic.
- [ ] The legacy flow around it is pinned.
- [ ] Wrapped calls that bypass the wrapper are accounted for.
- [ ] Temporary structure has a named follow-up.

## Related

`legacy-code-sprouter` to make the change; `legacy-code-sprout-opportunity-reviewer` to find edits that should have been sprouts; `$legacy-code:focused-tests` for the new unit's tests; `$legacy-code:large-methods` for reshaping; `$legacy-code:change-separation` for keeping the sprout a separate step.

## Source

- `Sprout Method`
- `Sprout Class`
- `Wrap Method`
- `Wrap Class`
- `Preferred Legacy Techniques`
- `Legacy Refactoring Heuristics`: only the heuristic to insert new code beside old code and redirect gradually.
- `Code Generation Rules`: only the preferred first move of introducing a focused new class for new behavior.
