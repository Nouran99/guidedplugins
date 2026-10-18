---
name: "legacy-code-test-points"
description: "Use when the impact of a change is unclear and you must choose where to observe it: effect sketches, test points, interception points, pinch points. A seam's place is `seams`; restructuring to understand is `legacy-code-scratch-refactoring`; the pin is `legacy-code-characterization-tests`; test level is `legacy-code-focused-tests`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Test points: where to observe the effects

Decide where tests should look before you write them. Start from the change point, trace what it can affect, and choose places where those effects are visible with useful precision. Understanding code by restructuring it is `legacy-code-scratch-refactoring`; writing the pin at the chosen place is `legacy-code-characterization-tests`; choosing a fast, narrow test once the place is known is `legacy-code-focused-tests`.

## When to use

- You know what to change but not what else the change can break.
- Several planned changes land in the same area and you want one test to protect them.
- A method has many outputs and callers, and you need the narrow place everything passes through.
- Every candidate test needs far too much setup, or the effect you care about is invisible from outside.

## Rules

1. **Use effect sketches when the impact of a change is unclear.** [MUST] Check: a sketch exists, on paper or in text, before you pick a test point.
2. **Start from the change point and trace affected values, calls, fields, outputs and collaborators outward.** [MUST] Check: the sketch begins at one named change point and each line follows an effect to something that can observe it.
3. **Choose test points where effects can be observed with useful precision.** [MUST] Check: a failure at the chosen point tells you which effect changed, not only that something did.
4. **Use interception points when several planned changes can be protected by one broader test.** [MUST] An interception point is a place downstream where the effects of several changes can be caught. Check: the sketch shows at least two planned changes whose effects reach the point.
5. **Use pinch points when many effects pass through one narrow point.** [MUST] A pinch point is a narrow place where many effects converge, which makes it a good place for a small number of tests. Check: you can name the effects that converge, and the number of paths into the point is small.
6. **Treat broad tests at interception points as a first step toward narrower tests.** [MUST] Check: the report names the narrower test that will follow and what it needs.
7. **If code is impossible to observe, expose outcomes through smaller units.** [MUST] Check: the unit you expose returns or records the outcome you could not see.
8. **Read excessive test setup as information about the design.** [SHOULD] If a test requires too much setup, the structure is telling you where the barrier is. Check: the setup list is written down and each item is a dependency or a hidden input.
9. **Mark the effects you could not confirm by reading.** [Added judgment] A traced effect is a hypothesis until a run or a probe shows it. Check: the sketch distinguishes read from run.
10. **Trace writes as well as reads.** [Added judgment] Reads show which inputs could change the result; writes show what other code can notice. Check: the sketch has both kinds of line.
11. **Prefer the test point closest to the change point that still sees the effect.** [Added judgment] Check: no closer point shows the same effect.
12. **List the effects the request does not mention.** [Added judgment] The effect nobody listed is the one that breaks. Check: for each field written, you searched for other readers.

## Procedure

1. Name the change point, and the planned changes if there are several.
2. List what the change point reads, writes, calls and returns. For each effect, search for other readers or callers.
3. Draw the sketch as indented text. Mark where lines converge (pinch points) and where one downstream point sees effects from several changes (interception points).
4. Choose the first test point. If it is broad, name the narrow follow-up and the seam it needs.
5. Hand the chosen point to `legacy-code-characterize` for pins or to `legacy-code-find-seam` if the point cannot be reached. `legacy-code-effect-sketch` runs steps 1 to 4 in a forked context.

## Example

Three planned changes (stackable promos, a promo cap, an audit note) all touch `applyPromo`.

```text
change point: Order.applyPromo(code)
 reads    lines[i].priceCents, promos.lookup(code)
 writes   lines[i].priceCents
 calls    recalculateTotals()  -> writes totalCents, taxCents
 calls    audit.record("promo", code)  -> effect leaves the object
 returns  nothing; the result is read through Order.receipt()
other writers of totalCents: addLine(), removeLine(), applyPromo()  (all call recalculateTotals)

pinch point:        recalculateTotals()  every path that changes money passes through it
interception point: Order.receipt()      totals, tax and applied codes for all three planned changes
```

First test, broad on purpose, at the interception point:

```ts
it("shows the discounted total and tax after one promo", () => {
  const order = orderWith([{ sku: "A", priceCents: 1000, qty: 2 }], { taxPercent: 10 });
  order.applyPromo("TEN"); // ten percent off
  expect(order.receipt()).toEqual({ totalCents: 1800, taxCents: 180, appliedCodes: ["TEN"] });
});
```

Follow-up, recorded in the plan: expose `recalculateTotals()` as a unit and test it narrowly, because the cap and the stacking rule both change it.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Test where it is easy | The test point is the nearest public method, chosen for convenience | Trace the effect and move to where it is visible |
| Broad test forever | A wide test with no narrower successor | Write the follow-up into the plan |
| Silent effect | A field written by the change that no sketch line mentions | Search for readers, add a line |
| Sketch by imagination | No run or probe confirms any line | Mark lines as unconfirmed and confirm the ones that decide the test point |
| Pinch-point worship | One point chosen although the effects only pass it by name | Check that the effects really converge there |

## Trade-offs and exceptions

- An interception point's test is deliberately broad; the source accepts that as a first step, not as the end state.
- Added judgment: a sketch for a one-line change in a well-protected function can be two lines; do not draw a diagram to justify a trivial edit.
- Effects through reflection, dynamic dispatch or configuration may be invisible to search; say so and confirm by running.

## Verification

- [ ] A sketch starts at a named change point.
- [ ] Reads, writes, calls and returns are all covered.
- [ ] Unconfirmed lines are marked.
- [ ] The chosen test point shows the effect precisely enough to diagnose a failure.
- [ ] A broad test names its narrower successor.
- [ ] Setup pain is recorded as a list of dependencies.

## Related

`legacy-code-effect-sketch` for the forked workflow; `legacy-code-scratch-refactoring` when you cannot read the code well enough to sketch; `legacy-code-characterization-tests` and `legacy-code-focused-tests` for the tests; `legacy-code-test-level-reviewer` to review test placement; `legacy-code-seams` once a barrier is named.

## Source

- `Test Selection and Understanding Rules`: only the rules on effect sketches, test points, interception points, pinch points and broad tests as a first step.
- `Legacy Refactoring Heuristics`: only the heuristics on setup pain and on code that is impossible to observe.
