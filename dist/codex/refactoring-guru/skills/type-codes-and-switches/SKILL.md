---
name: "type-codes-and-switches"
description: "Use when a switch or repeated if chain branches on a type, mode or status, a type code controls behavior, or null checks dominate a branch. Decides among explicit methods, type class, subclasses, state or strategy, polymorphism and null object. Not local rewrites (conditional-moves)."
---

# Type codes and switches

Owns the Switch Statements smell and the techniques that replace a branch on a code with structure: Replace Type Code with Class, with Subclasses, with State/Strategy; Replace Subclass with Fields; Replace Conditional with Polymorphism; Introduce Null Object. Simplifying a condition in place is `$refactoring-guru:conditional-moves`; the shape of an inheritance structure that already exists is `$refactoring-guru:hierarchies`.

## When to use

- A `switch` or an `if` chain branches on a type, mode, category or status.
- The same discriminator is switched in more than one place, and adding a case means editing all of them.
- A code (an enum, a string, an integer) selects behavior, and variants keep being added.
- Many branches exist only to handle `null` or absence.
- Subclasses differ only by a constant, or a status changes while the object lives.

## Rules

1. **Suspect missing polymorphism when adding a new case requires edits in multiple switch sites** (`SHOULD`). One site is not evidence. Check: list every site that switches on the discriminator; two or more is the signal.
2. **First isolate the decision: extract the switch and move it to the class that owns the decision** (`SHOULD`), as the preferred rung. Check: the switch is in one named method on the right owner before any type is introduced.
3. **Use Replace Type Code with Class when a code needs type safety or behavior but not polymorphic variants.** Check: no behavior branches on the code afterwards; only validity and meaning do.
4. **Use Replace Type Code with Subclasses when the code drives stable variant behavior and does not change at runtime.** Check: the variants are known and an instance never changes variant.
5. **Use Replace Type Code with State/Strategy when type or state controls behavior and may change at runtime.** Check: transitions are routed explicitly and tested.
6. **Use Replace Subclass with Fields when subclasses differ only by constant data.** Check: the subclasses have no distinct logic.
7. **Before Replace Conditional with Polymorphism, confirm the conditional varies by stable type, state or strategy** (`MUST`); otherwise prefer explicit methods or a simpler conditional. Check: you can name the stable set and the owner of the variation.
8. **Use explicit methods instead of polymorphism when there are only a few simple parameter variations** (`SHOULD`). Check: two or three one-line differences are not a hierarchy.
9. **Do not replace a simple honest conditional or a factory selection with unnecessary polymorphism** (`MUST NOT`), and do not introduce polymorphism for a conditional that is easier to read in place (`MUST NOT`). Check: after the change there are fewer decisions in the code, not the same decisions in more files.
10. **Use a null object when a branch exists only for null handling** (`SHOULD`): a neutral object that obeys the same interface. Do not use it when absence is an error that should be explicit. Check: absent and present cases behave as before for observable output.
11. **Treat replacing a type code with subclasses or state/strategy before the variation is stable as the risky rung:** it needs stronger tests and explicit justification, and the volatile-state case is explicitly not for subclasses. Check: no variant was added or removed in recent history, or the instability is accepted and recorded.
12. **Verify every variant, the dispatch, the state transitions and the construction path** after the replacement. Check: one test per variant, plus one for creation from the stored or incoming code.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Switch Statements | Extract Method and Move Method to isolate the decision | Type-code replacement | Replace Conditional with Polymorphism when the conditional is simple or not based on stable variation |

## Procedure

1. List all sites that branch on the discriminator, with file and line. Added judgment: search for the enum or the string literal, not just the `switch` keyword.
2. Classify the variation: constants only (rule 6), stable variants (rule 4), changes at runtime (rule 5), only a few simple differences (rule 8), or one-off (rule 9).
3. Isolate the decision (rule 2). Re-count the sites. If one site remains, stop unless the variants are growing.
4. If more than one site remains and the variation is stable, introduce the type with the family skill's safe steps: create the variants, move variant behavior, replace dispatch.
5. Keep one honest selection point (a factory or a mapping) where the code is first read.
6. Run the variant tests, then remove the old switch sites one by one.

## Example

The shipping fee switch appears in pricing, the checkout summary and the label printer. Adding a method means three edits. The selection stays a single, honest switch.

```ts
type Method = "standard" | "express" | "pickup";
type Parcel = { weightKg: number; subtotalCents: number };

// Before (repeated in three places)
function fee(m: Method, p: Parcel): number {
  switch (m) {
    case "standard": return 500 + 100 * Math.ceil(p.weightKg);
    case "express": return 1200 + 200 * Math.ceil(p.weightKg);
    case "pickup": return 0;
  }
}

// After: variants own their behavior
interface ShippingMethod { fee(p: Parcel): number; label: string; }
const standard: ShippingMethod = { label: "Standard", fee: (p) => 500 + 100 * Math.ceil(p.weightKg) };
const express: ShippingMethod = { label: "Express", fee: (p) => 1200 + 200 * Math.ceil(p.weightKg) };
const pickup: ShippingMethod = { label: "Pickup", fee: () => 0 };

// The one remaining switch: selection at the edge, not a decision about behavior
function shippingMethodFor(code: Method): ShippingMethod {
  switch (code) {
    case "standard": return standard;
    case "express": return express;
    case "pickup": return pickup;
  }
}
```

A fourth method is now one new object and one new `case` in the selector. If the code only ever appeared in one place, the correct stopping point would have been rule 2 (isolate the switch), not this.

## Anti-patterns

- **Polymorphism for one switch.** A hierarchy built for a two-branch conditional at one site. Detect: one site, no growth, and the new types outnumber the branches.
- **Enum of subclasses with flags.** Subclasses that still branch on a mode inside. Detect: `if (this.mode ...)` inside a variant.
- **Subclass for a changing status.** Replace Type Code with Subclasses for something that changes during an object's life. Detect: code that replaces an object to change its type.
- **Null object hiding an error.** A neutral object where absence should fail loudly. Detect: errors that used to surface now silently do nothing.
- **Selector sprawl.** The mapping from code to variant repeated in several places. Detect: more than one place constructs variants from the code.

## Trade-offs and exceptions

- A simple conditional or a factory selection is not a smell to eliminate; the source forbids replacing it with unnecessary polymorphism.
- Explicit methods beat polymorphism for a few simple variations.
- A null object preserves the same interface; where observable absence behavior matters, preserve it exactly or keep absence explicit.
- Added judgment: mark the stability assumption in a comment or the plan ("methods change at most yearly") so a later reader can re-check it.

## Verification

- [ ] Every site that switches on the discriminator was listed.
- [ ] The kind of variation (constant, stable, runtime-changing, simple) was classified.
- [ ] Polymorphism was used only for stable repeated variation owned by a type or state.
- [ ] One test per variant, plus creation from the incoming code.
- [ ] A null object, if added, keeps observable absence behavior or the absence stays explicit.

## Related

`$refactoring-guru:conditional-moves` for in-place simplification; `$refactoring-guru:hierarchies` for existing inheritance; `$refactoring-guru:organizing-data` for the non-type-code data techniques; `$refactoring-guru:data-smells` for primitives that stand for concepts; `refactoring-guru-type-switch-reviewer` to review a diff.

## Source

- `Object-Orientation Abusers`: only the Switch Statements entry.
- `Switch Statements`
- `Organizing Data`: only the Replace Type Code and Replace Subclass with Fields entries.
- `Organizing Data Playbook`: only the type-code and Replace Subclass with Fields entries.
- `Conditional and Method Call Playbook`: only the Replace Conditional with Polymorphism and Introduce Null Object entries.
- `Conditional Safety`: only the rules on polymorphism and stable variation.
- `Smell-to-Treatment Priority Map`: only the Switch Statements row and the Primitive Obsession row (type-code replacement as the fallback, and subclasses or state/strategy before the variation is stable as the risky rung).
- `Decision Anti-Patterns`: only the rule on turning a simple conditional into polymorphism.
