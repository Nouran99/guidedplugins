---
name: preparatory-steps
description: "Use when a requested feature or bug fix is awkward to add in the current structure: ask what makes it awkward, reshape locally first, then change behavior, then clean up. Bound to one upcoming change; general step discipline is small-steps."
---

# Preparatory steps

Refactor before and after a behavior change, around one specific change: make the change easy, then make the easy change, then tidy what it left. This skill is about that one moment; general step size and the rewrite brake are `/refactoring:small-steps`, and executing the preparation is `/refactoring:prepare`.

## When to use

- You are about to implement a feature or bug fix and the first line you would write has nowhere natural to go.
- A new branch would land inside a function that already does several things.
- A fix needs a value that is trapped inside code you do not yet understand.
- You are choosing between "bolt it on" and "restructure first".

## Rules

1. **Before implementing, ask what makes this change awkward.** Name the first place the change does not fit. Check: you can point at a file and line, not at "the code in general".
2. **Ask what local structural change would make it straightforward.** Check: the answer is a small move (rename, extract, move, split, inline), not a redesign.
3. **Ask whether you can rename, extract, move, split or inline first.** These are the cheapest preparations. Check: you considered each before inventing a new abstraction.
4. **Do the preparatory refactoring before the feature change (MUST).** Mixing them hides which edit did what. Check: the preparation is complete and tested before the first behavior edit.
5. **If code is hard to change, first reshape it; after the feature lands, clean the structural debt the change introduced.** Check: both a before and an after step exist, or the plan says why one is unnecessary.
6. **Refactor before the feature only when it makes the feature safer or simpler (compact checklist).** Check: you can say in one sentence how the preparation helps the change.
7. **When fixing a bug in unclear code, characterize the current failure and refactor only enough to make the fix visible before changing behavior (compact checklist).** Check: a test reproduces the failure before any structural edit.
8. **Use the simplest helpful refactoring; prefer local simplification before large-scale abstraction.** Check: the preparation touches only the path the change enters.
9. **Added judgment: write the preparation as one sentence.** "To add X, first make Y separable from Z." If you cannot write it, you are not ready to prepare, you are exploring. Check: the sentence exists in your plan or commit message.
10. **Refactor the smell that blocks the current change, not every smell in sight (compact checklist).** Added judgment on how to apply it: leave alone what the change does not enter; smells elsewhere in the file are noted, not fixed. Check: the smell you named as blocking is the one the preparation removes, and the preparation diff does not touch code paths the feature will not call.

## Procedure

1. Read the code the change will touch and the tests that cover it. Record the baseline.
2. Write down the awkward point (rule 1) and the one-sentence preparation (rule 9).
3. Make the preparation in small steps, tests after each. Do not change behavior.
4. Make the behavior change as its own step, with its own test first (test first is Added judgment; the source says to implement the change after the preparation).
5. Clean up anything the change introduced (duplicated branch, leftover parameter), again behavior-neutral.
6. List what you noticed and left alone.

## Example

```ts
// Request: domestic orders of 100 or more ship free.
// Awkward point: shipping is computed inline, mixed with subtotal work.
function checkout(order: Order): Receipt {
  let subtotal = 0;
  for (const line of order.lines) subtotal += line.qty * line.unitPrice;
  const shipping = order.destination === "DE" ? 5 : 12;
  return { subtotal, shipping, total: subtotal + shipping };
}

// Step 1, preparation (tests green, behavior unchanged): extract what the feature will change.
function shippingCost(destination: string): number {
  return destination === "DE" ? 5 : 12;
}
function checkout(order: Order): Receipt {
  let subtotal = 0;
  for (const line of order.lines) subtotal += line.qty * line.unitPrice;
  const shipping = shippingCost(order.destination);
  return { subtotal, shipping, total: subtotal + shipping };
}

// Step 2, the feature (failing test written first):
function shippingCost(destination: string, subtotal: number): number {
  if (destination === "DE" && subtotal >= 100) return 0;
  return destination === "DE" ? 5 : 12;
}
// ... and the call site passes `subtotal`.
```

Step 1 is reviewable on its own because it changes no output; step 2 is a three-line behavior change. Writing the failing test first in step 2 is Added judgment.

## Anti-patterns

- **Preparation that is the feature.** Detect: the "preparation" diff changes a computed value. Treat: split the behavior out.
- **Grand preparation.** Detect: the prep touches files the feature never calls. Treat: cut it back to the path the feature enters.
- **No follow-up.** Detect: the feature left a duplicated branch or a leftover parameter and nobody tidied it. Treat: schedule the follow-up step now.
- **Prepare-by-rewrite.** Detect: the prep replaces the function wholesale. Treat: find the smaller move.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Sometimes the feature is already easy; then no preparation is needed. The compact checklist says to refactor before the feature only when it makes the feature safer or simpler (rule 6); the full rule set asks the three questions and puts the preparation before the change.
- If there are no tests and the area is risky, the safety net comes first (`/refactoring:safety-net`); preparation on unverified code is untested structural surgery.
- A one-line fix in clear code needs no ceremony. (Added judgment)

## Verification

- [ ] The awkward point is named with a file and line.
- [ ] The preparation was done and tested before any behavior edit.
- [ ] The behavior change is a separate step with its own test.
- [ ] Debt introduced by the change was cleaned, or consciously left and listed.
- [ ] Nothing outside the path the change enters was restructured.

## Related

`/refactoring:plan` to sequence the whole change; `/refactoring:prepare` to carry out the preparation; `/refactoring:safety-net` when tests are missing; `/refactoring:stopping-rules` to end cleanly; `/output-style refactoring:prep-first` for a session that works this way.

## Source

- `Preparatory Refactoring`
- `Primary Directive`
- `Non-Negotiable Rules`
- `Code Generation Rules`
