---
name: "functions-and-variables"
description: "Use when splitting a long function, extracting tiny helpers, or adding intermediate variables inside one function body: judge each by whether it hides meaningful work and captures meaning, not by line counts."
---

# Functions and variables

Judges one function body and its variables: how deep a function should be, when a split helps, and when a variable earns its name. Boundaries between larger units are `$philosophy-of-design:split-or-merge`; a function's signature is `$philosophy-of-design:interface-design`. This is where the book parts company with the "keep functions tiny" habit; see the README for how that plays against `clean-code`.

## When to use

- You are about to extract a helper from a function that is "too long".
- A reader must jump through several tiny functions to understand one operation.
- Code is full of variables assigned once and used once.
- A function returns or stores intermediate values that no caller should see.

## Rules

1. **Keep functions deep enough to hide a meaningful amount of work.** Check: the name and signature tell the caller what happens, and the caller never needs the body to use it.
2. **Avoid long functions only when they create cognitive load, not as a numeric ritual.** Check: the reason for splitting names a fact the reader must hold, never a line count.
3. **Do not chain tiny functions where readers must jump constantly to understand one idea.** Check: understanding one operation means opening several helpers that each do a few lines.
4. **Avoid pass-through variables that do not add meaning.** Check: a variable assigned from a plain expression, used once, with a name that adds nothing.
5. **Use variables to capture meaning, not to mirror syntax.** A named condition (`isRefundable`) records a decision; `const result = compute(); return result;` records nothing. Check: the name says something the expression does not.
6. **Do not introduce variables only to satisfy style rather than clarity.** Check: each variable can be justified by reader benefit, not by a lint preference.
7. **Keep local details local.** Check: loop indexes, temporaries and partial results do not leave the function or become fields.
8. **Do not expose intermediate states that should stay internal.** Check: no public function returns or requires a half-computed value.
9. **Added judgment: an extraction must be independently understandable.** The new function should be describable from its name and signature without the caller's context. Check: if the name must be `part2`, or the body leans on several of the caller's locals, inline it back.
10. **Added judgment: split at a nameable concept, not at a length.** A long function with one purpose and straight-line flow is acceptable; a short one that mixes two concepts is not. Check: each piece you would split off has a domain name.

## Procedure

1. Read the function as a reader would and list the facts needed to follow it.
2. Mark candidate seams: places where a nameable concept starts and ends.
3. For each seam, test rule 9: could the extracted piece be understood alone? If not, leave it inline.
4. Inline helpers that are called once and whose names add nothing; inline pass-through variables.
5. Keep variables that name a decision or a unit; rename them to state it.
6. Run the tests after each change.

## Example

```python
# Before: a chain of fragments and pass-through variables for one idea
def total(order):
    items = _get_items(order)
    items = _filter_items(items)
    subtotal = _sum_items(items)
    return _finish(subtotal, order)

def _get_items(order):
    return order.items

def _filter_items(items):
    return [i for i in items if i.qty > 0]

def _sum_items(items):
    return sum(i.price_cents * i.qty for i in items)

def _finish(subtotal_cents, order):
    return round(subtotal_cents * (1 + order.tax_rate))

# After: one function that hides a meaningful amount of work behind a clear name
def total(order):
    """Order total in cents: lines with a positive quantity, plus tax, rounded to the cent."""
    subtotal_cents = sum(i.price_cents * i.qty for i in order.items if i.qty > 0)
    return round(subtotal_cents * (1 + order.tax_rate))
```

Four helpers and three reassignments became two lines that read in one pass. If the tax rules grew (exemptions, rounding per line), a `tax_for(order)` function would then be a nameable concept worth extracting.

## Anti-patterns

- **Fragment chain.** `step1`, `step2`, `finish`. Detect: helper names that describe order, not meaning, each called from one place.
- **Pass-through variable.** `const items = order.items;`. Detect: assigned once from a field or call and used once.
- **Syntax-mirror variable.** `const result = ...; return result;`. Detect: a variable named after its position.
- **Intermediate leak.** A public function that returns a half-processed object. Detect: return types that only make sense to the next step.
- **Numeric ritual.** Splitting because a limit was crossed. Detect: a commit message that cites a length.

## Trade-offs and exceptions

- This is the book's own position, and it differs from guides that set small size targets. The source asks you to avoid long functions when they create cognitive load; it does not ask for a number (Added judgment: do not add one here either).
- When a repository enforces a function-length lint rule, follow the repository and extract at the most nameable seams.
- A function that mixes concepts (parsing, rules, persistence) should still be split at those concepts; depth is not an excuse for tangling.
- A named intermediate value is worth keeping when it documents a unit conversion or a business decision.

## Verification

- [ ] Every extracted function is understandable from its name and signature.
- [ ] No operation requires opening more than a couple of helpers to follow.
- [ ] No variable merely renames an expression used once.
- [ ] No intermediate state is returned, stored or passed outside the function.
- [ ] Tests pass after each inlining or extraction.

## Related

`$philosophy-of-design:split-or-merge`; `$philosophy-of-design:deep-modules`; `$philosophy-of-design:naming-and-obviousness`; `philosophy-of-design-function-depth-reviewer` to review.

## Source

- `Function and Variable Rules`
