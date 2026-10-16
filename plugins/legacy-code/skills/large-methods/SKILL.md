---
name: large-methods
description: "Use when changing a long method, large class or tangled branches: pure computation first, side effects second, method objects, tests around extracted parts. Adding behavior beside it is `sprout-and-wrap`; layers are `policy-vs-mechanism`; throwaway restructuring is `scratch-refactoring`."
---

# Large methods

A long method cannot be reasoned about locally and cannot be tested in pieces. This skill reshapes it in a safe order: pure computation out first, side effects second, tests around each extracted part, and never many branches in one step. Adding behavior without reshaping is `/legacy-code:sprout-and-wrap`; separating layers and entry points is `/legacy-code:policy-vs-mechanism`; understanding by throwaway restructuring is `/legacy-code:scratch-refactoring`.

## When to use

- The change goes through a method whose body does not fit in your head.
- Branches share local variables that make extracting any one of them awkward.
- You must edit several branches of the same method and each edit could break the others.
- The only test of the method is a broad one, and you want narrower ones.

## Rules

1. **Carve out pure computation first.** [MUST] A pure part needs no setup and gives the cheapest tests. Check: the first extraction takes plain values and returns a value.
2. **Isolate side effects second.** [MUST] Check: after the pure parts are out, the remaining effects are in few, named places.
3. **Add tests around extracted parts.** [MUST] Check: each extracted unit has a test that fails if its logic changes.
4. **Avoid editing many branches at once.** [MUST NOT] The source says "many" and sets no number: keep a step to the branches the change needs, and split the rest into later steps. Check: no single step changes the behavior of several branches, or of more branches than the change needs.
5. **Use Break Out Method Object when a large method has local state that blocks extraction and testing.** [SHOULD] Move the method into its own class whose fields are the former locals, then extract methods inside it. Check: the locals that blocked extraction are now fields.
6. **Work near the change point, not across the whole system.** [MUST] Check: you extracted only the parts the change needs, and the rest of the method is as you found it.
7. **Extract method is a preferred first move.** [SHOULD] Check: the first structural step is an extraction, not a rename sweep.
8. **When a large method or class defeats local reasoning, sketch effects and find interception or pinch points before semantic edits.** [Compact checklist] See `/legacy-code:test-points`. Check: a sketch exists before the first behavior change.
9. **Characterize through the whole method before you extract.** [Added judgment] A broad test through the public entry point is the net under every extraction. Check: the broad pin passes before and after each step.
10. **Start from the branch you will change.** [Added judgment] Extract its condition and its computation first, with explicit parameters. Check: you can state the extracted unit's inputs and output in one line.
11. **Watch the extraction traps.** [Added judgment] Locals that are reassigned, early returns, and variables read after the block are where hand extractions change behavior. Use the tool's extract-method when it has one. Check: each trap in the block has a stated resolution.
12. **When many locals cross the boundary or are reassigned, stop extracting and break out a method object.** [Added judgment] Check: the plan says why the locals made plain extraction awkward.
13. **Keep the original signature.** [Added judgment] The method calls the extracted piece, so callers are untouched. Check: no caller changed.
14. **Name extracted parts for what they decide.** [Added judgment] `lateFee` and `mayClose` say what; `part2` says where. Check: no extracted name refers to position.
15. **One extraction per step, no behavior change in it.** [Added judgment] Check: tests are green after each step; behavior changes are separate (`/legacy-code:change-separation`).

## Procedure

1. Pin the method through its public entry point (`/legacy-code:characterize`) if it is not already protected.
2. Mark the branch the change touches and list its inputs and outputs.
3. Extract the pure computation first. Run the tests. Add direct tests for the extracted unit.
4. Isolate effects second (`/legacy-code:hard-outputs` for the collaborator).
5. If locals block steps 3 and 4, break out a method object and continue inside it.
6. Make the requested change in the extracted, tested unit. Stop; do not keep decomposing.

## Example

```python
# Before: policy and effects interleaved in one body
def settle_invoice(invoice, today, db, mailer):
    days = (today - invoice.due).days
    fee = 0
    if days > 0:
        fee = invoice.balance * 2 // 100
        if days > 30:
            fee += 1500
    invoice.balance += fee
    db.save(invoice)
    if invoice.balance > 0 and days > 0:
        mailer.send(invoice.customer_email, "Overdue", f"Balance: {invoice.balance}")
    return invoice.balance
```

```python
# After step 1: the fee rule is a pure function; settle_invoice keeps its signature and behavior
def late_fee_cents(balance, days_overdue):
    if days_overdue <= 0:
        return 0
    fee = balance * 2 // 100
    if days_overdue > 30:
        fee += 1500
    return fee

def settle_invoice(invoice, today, db, mailer):
    days = (today - invoice.due).days
    invoice.balance += late_fee_cents(invoice.balance, days)
    db.save(invoice)
    if invoice.balance > 0 and days > 0:
        mailer.send(invoice.customer_email, "Overdue", f"Balance: {invoice.balance}")
    return invoice.balance
```

```python
def test_no_fee_when_not_overdue():
    assert late_fee_cents(10_000, 0) == 0

def test_two_percent_when_overdue():
    assert late_fee_cents(10_000, 5) == 200

def test_flat_surcharge_after_thirty_days():
    assert late_fee_cents(10_000, 31) == 1700
```

The next step, separately, would put `db.save` and `mailer.send` behind collaborators if the change needs them; the fee rule can now change with a direct test.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Whole-method rewrite | The method is replaced in one patch | Extract piece by piece |
| Fragment names | `part1`, `step_b` | Name by decision |
| Effects first | Side effects extracted before pure rules | Pure first |
| Many branches at once | One step alters the behavior of several branches, or more than the change needs | Edit the branches in separate, pinned steps |
| Unpinned extraction | No broad test before the first extraction | Pin through the entry point |
| Decomposing past the need | The whole method broken up for a one-line change | Stop at the change point |

## Trade-offs and exceptions

- Break Out Method Object is for local state that blocks extraction; for a method with few locals, plain extraction is smaller.
- Added judgment: a requirement that genuinely spans two branches (one rule that both a refund path and a cancel path apply) is not a violation of rule 4. Keep the edit to those two branches, pin each, and make the edits in separate steps when they can be separated.
- Added judgment: if the method is already covered by good tests and the change is one line, edit it directly and extract nothing.
- Extraction does not remove the hidden inputs and outputs inside the body; those are the barrier skills.
- Large classes: the source's compact guidance applies the same order (sketch effects, find a seam, extract the part the change needs); split a class only as far as the change requires.

## Verification

- [ ] A broad pin existed before the first extraction.
- [ ] The first extraction was pure and has direct tests.
- [ ] Each step left the tests green and changed no behavior.
- [ ] The original signature and callers are unchanged.
- [ ] Extracted names say what they decide.
- [ ] You stopped at the change point.

## Related

`legacy-code:large-method-reviewer` to review a diff; `legacy-code:method-extractor` to make the extraction; `/legacy-code:test-points` for the sketch; `/legacy-code:hard-outputs` and `/legacy-code:hidden-inputs` for the effects and inputs; `/legacy-code:policy-vs-mechanism` for layers.

## Source

- `Large Methods`
- `Dependency-Breaking Technique Index`: only Break Out Method Object.
- `Legacy Refactoring Heuristics`: only the heuristic to work near the change point.
- `Code Generation Rules`: only the preferred first move of extracting a method.
- `Test Selection and Understanding Rules`: only the rule to use effect sketches and to find interception and pinch points.
- `Handling Risky Areas`: only the subsection on large methods.
