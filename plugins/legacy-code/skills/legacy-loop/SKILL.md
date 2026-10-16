---
name: legacy-loop
description: "Use when starting a change in untested code and you need the order of work: state the delta, check protection, seam, break one dependency, change, refactor locally. Pinning is `characterization-tests`; patch shape is `change-separation`; rewrites are `rewrite-pressure`; routing is `principles`."
---

# The legacy-change loop

The sequence for one change in code you cannot yet trust: understand, protect, make a seam, break one dependency, change, refactor locally. This skill owns the order and the entry criteria. How to pin behavior is `/legacy-code:characterization-tests`, how to judge the shape of the patch is `/legacy-code:change-separation`, and whether to go big at all is `/legacy-code:rewrite-pressure`.

## When to use

- A request touches a function, class or module and you cannot name a trusted test that would fail if you broke it.
- You are about to edit code you only partly understand because the change "looks small".
- You are planning the order of steps for a legacy change, or checking that an existing plan respects the order.
- A change keeps stalling because you cannot run the code in a test.

## Rules

1. **Treat any area without trustworthy tests as legacy code.** [MUST] The cost of a wrong edit is highest where nothing would catch it. Check: for each function you will edit, you can name a test that fails if its behavior breaks, and you trust that test; if not, the loop applies to that function.
2. **State the requested behavior change and the current behavior that must remain, before you edit.** [Compact checklist] Check: a delta list and a preserve list exist before the first production edit, and the preserve list names observable behavior (outputs, effects, error cases), not code structure.
3. **Understand what the code does now before changing it.** [MUST] Check: you can predict its result for the inputs the change touches, and a run or a test confirmed the prediction.
4. **Determine whether trusted tests already protect the behavior, and add characterization tests around current behavior where possible when they do not.** [MUST] Characterize the gap, not the whole module. Check: every item on the preserve list maps to an existing trusted test or a new characterization test.
5. **Identify the dependency that makes the change difficult, introduce or exploit a seam, then break the blocking dependency.** [MUST] Check: you can name the barrier, the seam and the dependency you broke in one line each (`/legacy-code:find-seam` produces exactly that).
6. **Make the functional change only after the earlier steps, and as its own step.** [MUST] Check: the behavior change has its own test and its own diff, with no unrelated structure change in it.
7. **Refactor for clarity afterwards, locally, and keep the seam or new structure only if it still pays for itself.** [MUST] Check: every seam you added is either used by a test you kept, or has a stated cleanup path.
8. **Use the short form as a summary of rules 3 to 7: identify change points, find test points, break dependencies, write tests, make changes, then refactor.** [SHOULD] The source gives it as a one-line summary of the workflow, not as a separate imperative. Its literal order (dependencies before tests) differs from the long form's characterize-first (rule 4); rule 15 reconciles the two. Check: the plan names change points and test points before any dependency break, the change comes after both, and where a pin is possible it comes before the break.
9. **Do not begin with a rewrite unless explicitly required.** [MUST NOT] Check: the first edit in the plan is not a replacement module; a test, a seam, an extraction or a wrapper all qualify.
10. **Do not start by cleaning the whole module.** [MUST NOT] Check: no rename, reformat or reorganization touches code outside the change point before the change is protected.
11. **Leave the touched area more testable than before; ideally also easier to see and more modular.** [MUST] for testability, [SHOULD] for visibility and modularity. The source gives no measure of "easier to test", so the Check is Added judgment. Check: the touched area is no harder to test than before and a seam or a test now exists where none did; mark it n/a with a stated reason when the code was already easy to test.
12. **Carry suspicious current behavior to the user as a question; do not fix it silently as a side effect of your change.** [MUST] Check: every surprising result you saw while characterizing appears in the report with its location.
13. **When the change is already protected, still name the protecting test in the plan.** [Added judgment] Skipping a step silently makes the plan look the same as a plan that forgot it. Check: the plan says "protected by <test>" instead of omitting the step.
14. **Run one pass of the loop per change point.** [Added judgment] A request with three change points has three preserve lists. Check: each change point has its own card.
15. **Reconcile the two forms of the workflow when the barrier is what stops every pin: make the first dependency break without a pin, in its most conservative form, and pin straight after.** [Added judgment] The long form characterizes before it breaks dependencies "where possible"; the short form (rule 8) breaks dependencies before it writes tests. When no pin is possible, follow the short form. Conservative means: keep the signature, default to the old behavior, change one site at a time, lean on the compiler or type checker, and edit by hand only what the break needs. Check: the enabling break changes no result for existing callers, and the next step in the plan is the pin.

## Procedure

1. Write the loop card (below) for the change point. Name the change point first; if you cannot, read until you can.
2. Protection check: search the test directories for callers of the change point, run those tests if the project's test command is known, and judge trust. Added judgment: tests that assert nothing, are skipped, only check that the call did not throw, or restate the implementation do not count as protection.
3. If the preserve list has unprotected items, pin them with `/legacy-code:characterize` or delegate to `legacy-code:characterization-writer`.
4. If you cannot write a pin because the code cannot be run, use `/legacy-code:find-seam` to name the barrier, then use the implementer for that barrier (`legacy-code:boundary-wrapper`, `legacy-code:collaborator-injector`, `legacy-code:global-encapsulator`, `legacy-code:method-extractor`). This first break is the one production edit allowed before a pin (rule 15), and the pin follows at once.
5. Make the behavior change with its own test. For new behavior in fragile code, `/legacy-code:sprout-and-wrap` and `legacy-code:sprouter`.
6. Refactor locally, then stop. Report what changed, which tests ran, what remains unprotected and which temporary seams carry a cleanup path.

## Example

A filled card for a request. The decision it records is the order: the two barriers block every pin, so the first step is two conservative dependency breaks that keep the old behavior as the default, then the pins, then the rule.

```
Request: members with a subtotal of 5000 cents or more get free standard shipping
Change point: ShippingCalculator.shipping_for(order) in billing/shipping.py
Delta: members at or above 5000 cents pay 0 standard shipping
Preserve: non-members unchanged; members under 5000 pay 499; the express surcharge of 1500 is unchanged; an empty cart pays 0
Protection: nothing calls shipping_for; tests/test_checkout.py only checks that checkout returns 200 (not trusted)
Gap: all 4 preserve items
Barrier: shipping_for calls datetime.now() for a holiday surcharge, and __init__ opens rates.Client()
Seam: parameter `now` (separation); constructor parameter `rates` (separation)
Technique: Parameterize Method for `now`, Parameterize Constructor for `rates` (see hidden-inputs, construction-barriers)
Order: 1 two dependency breaks, signatures kept, old behavior as default  2 pins  3 free-shipping rule with its own test  4 local cleanup, then stop
Cleanup obligations: none if both seams stay as explicit parameters
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Edit and pray | Production lines changed, no test changed, no protection statement | Write the card; pin first |
| Cleanup first | Renames or reformatting across the module before the first test exists | Revert the sweep; start at the change point |
| Seam without a pin | A refactoring "for testability" that adds no test, or a break with no pin after it | Add the pin the seam was for, or drop the seam |
| Structural preserve list | "Keep the strategy classes" instead of "express stays 1500" | Rewrite the list in observable behavior |
| Rewrite as step one | First deliverable is a new module that replaces the old | `/legacy-code:rewrite-pressure` |

## Trade-offs and exceptions

- If trusted tests already protect the behavior, skip characterization; the source's step is conditional.
- A rewrite the user explicitly asks for is allowed (the source forbids starting one unless required). Added judgment: pin what consumers rely on first, so the replacement can be compared.
- Added judgment: a pure documentation or comment edit has no behavior to preserve; say so in one line instead of filling the card.
- Visibility and modularity improvements are "ideally"; testability is not optional.

## Verification

- [ ] A delta list and a preserve list were written before the first production edit.
- [ ] Every preserve item maps to a trusted test.
- [ ] The behavior change is in its own step with its own test.
- [ ] At least one hard dependency was reduced, and none was added.
- [ ] Suspicious current behavior is reported, not silently changed.
- [ ] Tests ran after each step.

## Related

`/legacy-code:plan` writes the card for a requested change; `/legacy-code:characterize` and `/legacy-code:find-seam` perform steps 3 and 4; `/legacy-code:change-separation` judges the finished patch; `legacy-code:protection-reviewer` checks the protection claim; `legacy-code:lead` routes.

## Source

- `Primary Directive`
- `Default Workflow for Legacy Changes`
- `Non-Negotiable Rules`
- `Purpose`: only the aims of safe change, characterization before redesign and incremental improvement over heroic rewrites.
- `Characterization Tests`: only the rule on marking suspicious current behavior for clarification.
