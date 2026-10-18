---
name: "refactoring-guru-treatment-choice"
description: "Use when choosing among refactoring treatments for a diagnosed smell: smallest technique first, fallbacks, risky options, and rejecting polymorphism, wrappers, parameter objects or superclasses that do not earn their cost. Stopping and deferring are stop-and-defer."
license: "MIT"
metadata:
  plugin: "refactoring-guru"
  book: "Refactoring.Guru"
  invocation: "auto"
---

# Treatment choice

Owns the ladder that applies to every smell: preferred treatment, fallback only when blocked, risky treatment only with stronger tests, and the list of mechanical choices to reject. The per-smell rows live in the smell skills (for example `refactoring-guru-size-smells`); whether to stop is `refactoring-guru-stop-and-defer`.

## When to use

- You have a diagnosed smell and two or more catalog techniques could treat it.
- You are tempted to introduce a class hierarchy, an interface, a wrapper or a parameter object.
- A reviewer asks "why this technique?" or calls a change over-engineered.
- You need the smell-to-treatment priority for a smell, in order to explain it.

## Rules

1. **Choose the treatment from the smell, not from a preferred pattern** (`MUST`). A treatment picked first needs a smell invented afterwards. Check: the plan names the symptom before it names the technique.
2. **Diagnose before choosing.** Name the visible symptom and the maintenance cost, say whether it is local, repeated or architectural, and check that it is real rather than a style preference. Check: each of the four is written down.
3. **Pick the catalog technique that directly addresses the smell, smaller before larger,** and note the expected cleaner end state before editing (all `SHOULD`). Check: the end state is a sentence about the code, not about the technique.
4. **Reject a treatment if its own trade-off is worse than the smell.** Check: for the chosen technique, you can name what it costs (a new class, a new dependency, a new indirection) and why that is less than the smell's cost.
5. **Read the priority map as a ladder.** Start with the preferred treatment; move to the fallback only when the preferred one is blocked; treat the risky option as requiring stronger tests and explicit justification. Check: if you are on the fallback or the risky rung, the report says what blocked the rung above. The rows are in `Smell-to-Treatment Priority Map` of `../refactoring-guru-principles/references/full.md`.
6. **Prefer local simplification before hierarchy changes, names and extracted methods before comments, and deleting unused structure before extending it** (all `SHOULD`). Check: no new class or subclass appears where a rename or extraction would solve the problem.
7. **Do not introduce polymorphism, inheritance, bidirectional links or new classes when a simpler extraction or rename solves the problem** (`MUST NOT`). Check: you tried the smaller move first and can say why it was not enough.
8. **Do not remove parameters, associations or abstractions if doing so creates worse coupling or hides required variation** (`MUST NOT`). Check: after the removal, no class gained a dependency it did not have.
9. **Preserve domain meaning when replacing primitives or arrays with objects** (`SHOULD`), and keep behavior with the data it changes unless a deliberate interchangeable-behavior model is needed (`SHOULD`). Check: the new name is a term the domain uses.
10. **Apply a technique because it treats a diagnosed smell, never because its name sounds modern** (`MUST NOT` otherwise). Check: removing the technique name from the description leaves a clear problem statement.
11. **Check the decision anti-patterns below before editing.** Each is a `MUST NOT` in the source. Check: none of the fifteen applies.

### Decision anti-patterns

The detection hints are Added judgment; the prohibitions are the source's.

| Do not | Detect |
| --- | --- |
| Apply a refactoring because its name sounds modern | The plan names a technique and no smell |
| Turn a simple conditional into polymorphism unless variation is stable, repeated and owned by type or state | One switch, two branches, no second site |
| Create a parameter object from unrelated arguments just to shorten a signature | The object's name is `Options`, `Params` or `Context` and its fields share no concept |
| Introduce a superclass or interface from coincidental method names | No second client and no shared behavior |
| Replace duplication with an abstraction that has a worse name than the duplicated code | The helper is called `process`, `handle` or `doStuff` |
| Stop at getters and setters when the real smell is behavior living outside the data | Accessors added, callers still do the logic |
| Hide feature work inside a refactoring sequence | A literal or condition changes in a "refactor" hunk |
| Preserve a forwarding class merely because deleting it requires caller updates | The class only delegates and the reason is "too many callers" |
| Use bidirectional association as a shortcut when one side can receive the collaborator as a parameter or lookup | A back-reference field used in one method |
| Delete speculative or dead-looking code before generated, reflected, serialized, plugin-facing and public usages are checked | A deletion with no search evidence |
| Add assertions for normal user input, expected absence or recoverable errors | An assert on input validation |
| Use exceptions as routine tests when callers can cheaply check first | try/catch used for flow in a loop |
| Inline names that explain business intent even when the body is short | The inlined body is a one-line business rule |
| Move behavior away from its data if that creates feature envy in the opposite direction | The moved method now reads the old owner's fields |
| Continue cleanup after the diagnosed smell is fixed unless the next smell blocks the requested change | Hunks unrelated to the named smell |

## Procedure

1. Write the diagnosis: symptom, cost, scope (local, repeated, architectural), real or style.
2. List the techniques for the smell from its row in the priority map, and mark preferred, fallback, risky.
3. Take the preferred rung. If it is blocked, record what blocks it and take the fallback. Take the risky rung only with tests that cover its failure mode and a written justification.
4. Write the expected cleaner end state and what the technique costs.
5. Run the anti-pattern table against the plan.
6. Hand off to the family skill for mechanics (`refactoring-guru-composing-methods`, `refactoring-guru-moving-features` and so on), and to `refactoring-guru-stop-and-defer` for the stop line.

## Example

A pricing function branches once on the sales channel. A subclass-per-channel design is a tempting rewrite.

```ts
// Before
function discount(o: Order): number {
  if (o.channel === "web") {
    return o.couponCents > 0 ? Math.min(o.couponCents, o.subtotalCents) : 0;
  } else {
    return Math.floor(o.subtotalCents * 0.02);
  }
}

// Ladder:  smell = hard-to-read conditional (local, one site)
//   preferred: Decompose Conditional (extract the branches)      <- chosen
//   rejected : Replace Conditional with Polymorphism: one site, two branches,
//              no second switch on channel; it adds types without removing a decision

// After
function couponDiscount(o: Order): number {
  return o.couponCents > 0 ? Math.min(o.couponCents, o.subtotalCents) : 0;
}
function phoneDiscount(o: Order): number {
  return Math.floor(o.subtotalCents * 0.02);
}
function discount(o: Order): number {
  if (o.channel === "web") {
    return couponDiscount(o);
  }
  return phoneDiscount(o);
}
```

Each branch body moved unchanged, including the `couponCents > 0` guard, so no input changes its result. Simplifying that guard would be a separate step that needs its own reasoning about negative coupons.

## Anti-patterns

- **Pattern first.** A named design pattern appears in the plan before a smell does. Detect: the technique name is in the title and no symptom is.
- **Skipping the ladder.** The risky rung chosen without saying what blocked the preferred one. Detect: no mention of the preferred technique in the plan.
- **Ladder worship.** Climbing to a fallback because the preferred technique is unfamiliar. Detect: "blocked" has no concrete cause.
- **Cost blindness.** A treatment whose cost is never named. Detect: the plan lists benefits only.

## Trade-offs and exceptions

- The map says what to try first, not what is always right: the smell exception rules still apply (see `refactoring-guru-stop-and-defer`).
- Some smells have two preferred treatments (for example `Replace Parameter with Method Call` or `Preserve Whole Object` for a long parameter list); choose by which creates no new dependency.
- Added judgment: when two rungs are equally small, prefer the one whose result is easier to revert.

## Verification

- [ ] The diagnosis has symptom, cost, scope and a real-versus-style call.
- [ ] The chosen rung is stated, with what blocked any higher rung.
- [ ] The trade-off of the chosen technique is named.
- [ ] None of the decision anti-patterns applies.
- [ ] The expected cleaner end state is written down.

## Related

The smell skills hold the rows: `refactoring-guru-size-smells`, `refactoring-guru-data-smells`, `refactoring-guru-change-locality`, `refactoring-guru-dead-weight`, `refactoring-guru-behavior-ownership`, `refactoring-guru-delegation-and-gaps`, `refactoring-guru-type-codes-and-switches`, `refactoring-guru-hierarchies`, `refactoring-guru-explanatory-comments`. `refactoring-guru-smell-to-treatment` produces the card; `refactoring-guru-scope-guard` audits a diff against it.

## Source

- `Smell-to-Treatment Priority Map`
- `Safety and Tradeoff Rules`
- `Decision Anti-Patterns`
- `Technique Selection Rules`: only the principle of choosing by symptom and the smaller-before-larger ordering.
- `Diagnose, Treat, Verify, Stop`: only the diagnose and choose-treatment steps.
