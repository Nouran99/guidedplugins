---
name: size-smells
description: "Use when a method needs scrolling or comments to follow, a class carries several responsibilities, or fields are valid only in some situations (long method, large class, temporary field). Diagnoses and picks the treatment; mechanics are in composing-methods and moving-features."
---

# Size smells

Owns three smells where one unit carries more than one concept's worth of state or steps: Long Method, Large Class and Temporary Field. It decides whether the smell is real and which treatment comes first. Performing Extract Method and its relatives is `/refactoring-guru:composing-methods`; performing Extract Class and Move Method is `/refactoring-guru:moving-features`.

## When to use

- A method has to be scrolled, needs comments to explain its phases, or forces you to keep several local values in your head.
- A class has many fields, many methods or several reasons to change.
- An object has fields that are empty or meaningless except while one particular operation runs.
- A review comment says "this does too much".

## Rules

1. **Ask questions once a method is noticeably long** (`MUST`). Ten lines is a warning threshold, not a mechanical limit. Check: you can state what the method does in one sentence without "and"; if not, there are several things to name.
2. **Extract a method when a code fragment needs a comment to say what it does** (`SHOULD`). The comment is the missing name. Check: the comment text became (or is close to) the method name.
3. **Extract loops, conditional branches and coherent phases into named methods** (`SHOULD`). Check: the original method now reads as a short sequence of purpose-named calls at one level.
4. **When locals block extraction, use Replace Temp with Query, Introduce Parameter Object or Preserve Whole Object** (`SHOULD`). Check: after the fallback, the fragment's inputs and outputs are few enough to name.
5. **Use Replace Method with Method Object only when extraction is blocked by many locals or a tightly coupled algorithm** (`SHOULD`). It is the risky rung: it creates a new object and changes the shape of the algorithm. Check: a simple long method that Extract Method can handle is not on this rung.
6. **Do not avoid extraction only because a method call might have negligible performance cost** (`MUST NOT`). Check: the objection to extracting is measured or the cost is plainly more than negligible; otherwise extract.
7. **Split a class that wears multiple functional hats** (`SHOULD`). Use Extract Class when a subset of fields and methods forms a separate responsibility. Check: you can name the extracted responsibility and list the fields and methods that move with it.
8. **Use Extract Subclass for rare or variant behavior that bloats the main class, and Extract Interface when clients need only a stable subset** (both `SHOULD`, both fallbacks). Check: the variation is stable and meaningful, and the interface has a real client.
9. **Move domain data out of GUI-held classes into domain classes** (`SHOULD`) when interface objects carry business state. Check: no business rule can be answered only by asking a widget.
10. **Do not split a class only because it is large when the extracted part has no stable responsibility** (`MUST NOT`). Broad hierarchy extraction before responsibilities are stable is the risky rung. Check: the new class has a name that is not `Helper`, `Utils` or `Part2`.
11. **For a Temporary Field, extract the algorithm and its temporary state into a separate class** (`SHOULD`); use a method object when fields only carry intermediate values between steps, and a null object when checks around absent state dominate. Do not normalize half-initialized objects as ordinary design (`MUST NOT`). Check: every remaining field is meaningful in every state the object can be in.
12. **Confirm the smell is real before treating it** (`MUST NOT` treat mechanically). Added judgment: a long method that reads as one flat sequence with no local state to track and no phase comments is a candidate for leaving alone; length alone is a symptom, not the diagnosis. Check: you can name the cost (scrolling, mental bookkeeping, several reasons to change).

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Long Method | Extract Method | Replace Temp with Query, Introduce Parameter Object, Preserve Whole Object when locals block extraction | Replace Method with Method Object |
| Large Class | Extract Class | Extract Subclass for variant behavior; Extract Interface for a client-facing subset | Broad hierarchy extraction before responsibilities are stable |
| Temporary Field | Extract Class, or Replace Method with Method Object | Introduce Null Object for absence checks | Spreading optional half-state through more conditionals |

## Procedure

1. Mark the phases of the method (blank-line groups, phase comments, loops). Added judgment: also mark locals that live across phases; those are what blocks extraction.
2. List fields by the methods that use them. Added judgment: groups of fields used by disjoint sets of methods mark the seam for Extract Class.
3. Check whether any field is valid only during one operation (Temporary Field).
4. Choose the preferred rung from the ladder; take a fallback only if it is blocked, and say what blocked it.
5. Hand the mechanics to `/refactoring-guru:composing-methods` or `/refactoring-guru:moving-features`, run the check after each step, and stop when the named symptom is reduced (`/refactoring-guru:stop-and-defer`).

## Example

A long method with three commented phases. Extraction keeps behavior identical; the intermediate local `subtotal` is threaded through return values instead of mutation.

```python
# Before
def invoice_total(order):
    # sum line items
    subtotal = 0
    for line in order.lines:
        subtotal += line.unit_price * line.quantity
    # apply loyalty discount
    if order.customer.years > 5:
        subtotal -= subtotal * 0.05
    # add shipping
    shipping = 0 if subtotal > 100 else 7.5
    return subtotal + shipping

# After
LOYALTY_YEARS = 5
LOYALTY_RATE = 0.05
FREE_SHIPPING_ABOVE = 100
FLAT_SHIPPING = 7.5

def line_subtotal(order):
    return sum(l.unit_price * l.quantity for l in order.lines)

def apply_loyalty_discount(amount, customer):
    if customer.years > LOYALTY_YEARS:
        return amount - amount * LOYALTY_RATE
    return amount

def shipping_fee(amount):
    return 0 if amount > FREE_SHIPPING_ABOVE else FLAT_SHIPPING

def invoice_total(order):
    amount = apply_loyalty_discount(line_subtotal(order), order.customer)
    return amount + shipping_fee(amount)
```

Shipping is still decided on the discounted amount, as before. Each comment became a function name, and no method hides a side effect.

## Anti-patterns

- **Fragment soup.** Extracted methods named after mechanics (`step2`, `doLoop`) or after the lines they hold. Detect: the name restates the code, or contains a digit. The source requires naming by purpose.
- **Method object by reflex.** A new class for a long method that plain extraction could split. Detect: the object has one public method and was introduced before any extraction was tried.
- **Split by size.** Half the methods moved to `FooHelper` with no responsibility of its own. Detect: the new class's fields and methods share nothing but their old home.
- **Normalized half-state.** `initialized` or `isSet` flags that guard fields of a live object. Detect: methods that begin with a check for whether a field was populated.
- **Hidden effect behind a harmless name.** An extraction that mutates shared state under a read-only-sounding name. Detect: the extracted method assigns to fields or arguments.

## Trade-offs and exceptions

- A simple honest length is acceptable when extraction would only split a linear sequence into names that restate it; the smell exception rule asks you to confirm the treatment improves clarity here (Added judgment on what "linear" means).
- A small class may stay when it communicates a real extension point or boundary.
- Method objects are legitimate when locals genuinely block extraction; the source lists them as the risky rung, not a forbidden one.
- Performance: the source rejects negligible-cost objections only; a measured hot path is a separate decision.

## Verification

- [ ] The smell was named with a cost, and a real-versus-style call was made.
- [ ] The first treatment tried was the preferred rung, or the blocker is stated.
- [ ] Every extracted name states a purpose.
- [ ] No extracted method hides a side effect behind a harmless name.
- [ ] Tests ran after each extraction and after each move.

## Related

`/refactoring-guru:composing-methods` and `refactoring-guru:method-extractor` for extraction; `/refactoring-guru:moving-features` and `refactoring-guru:responsibility-mover` for splitting a class; `refactoring-guru:bloat-reviewer` to review a diff; `/refactoring-guru:type-codes-and-switches` when the null checks around absent state dominate.

## Source

- `Bloaters`: only the Long Method and Large Class entries.
- `Long Method`
- `Large Class`
- `Temporary Field`
- `Smell-to-Treatment Priority Map`: only the Long Method, Large Class and Temporary Field rows.
- `Smell Exception Rules`: only the rule not to treat smells mechanically and the rule that a small class may stay when it communicates a real extension point or boundary.
- `Extraction Safety`: only the rule to name an extracted method after its purpose and not hide an important side effect.
