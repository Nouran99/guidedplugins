---
name: composing-methods
description: "Use when about to perform Extract Method, Inline Method, Extract Variable, Inline Temp, Replace Temp with Query, Split Temporary Variable, Remove Assignments to Parameters, Method Object or Substitute Algorithm. Mechanics and safety checks, not diagnosis (size-smells)."
---

# Composing methods

Owns the nine techniques that reshape the inside of a method: what to check before each, the safe steps and how to verify. Deciding that a method is too long is `/refactoring-guru:size-smells`; deciding that a comment should become a name is `/refactoring-guru:explanatory-comments`; rewriting conditions is `/refactoring-guru:conditional-moves`.

## When to use

- You have chosen Extract Method (or any technique in the table below) and are about to type it.
- A temporary variable blocks an extraction, holds two meanings, or hides a simple expression.
- A method is called from one place and its name adds nothing to its body.
- A parameter is being used as scratch space.
- A confusing algorithm could be replaced by a clearer equivalent.

## Rules

1. **Before Extract Method, identify every variable the fragment reads, writes or returns** (`MUST`). A missed write is a silent behavior change. Check: write a three-column list (reads, writes, needed afterwards) before extracting.
2. **Leave variables local to the extracted method when they are declared and used only inside the fragment** (`SHOULD`), and pass prior values as parameters only when the fragment needs them (`SHOULD`). Check: no parameter is passed that the new method does not read.
3. **Double-check any variable modified inside the fragment; if later code needs the changed value, return it explicitly or choose a safer refactoring** (`MUST`). Check: each written variable that is read after the fragment appears in the return value.
4. **Use Replace Temp with Query before extracting when temporaries block a clean boundary** (`SHOULD`). Do not use it when the calculation is expensive, stateful or order-dependent without a caching policy. Check: results are equal and performance-sensitive paths were considered.
5. **Name the extracted method after its purpose, not after the mechanical steps it performs** (`MUST`), and do not extract a fragment that hides an important side effect behind a harmless-sounding name (`MUST NOT`). Check: the name could be read without the body and still not mislead about effects.
6. **Before Inline Method, confirm the method adds no useful name, abstraction, override point or public contract** (`MUST`). Check inbound callers, including dynamic dispatch, inheritance and interface calls (`SHOULD`). Check: a search for overrides and interface declarations finds none.
7. **Do not inline a method that callers depend on as part of a public or test-facing API** (`MUST NOT`), and do not inline names that explain business intent even when the body is short (`MUST NOT`). Check: the inlined body reads at least as clearly as the name did.
8. **Extract Variable when an expression needs a name to reveal intent;** introduce an immutable local close to its use and keep evaluation order. Do not use it when the variable merely repeats the expression. Check: no side effect was moved earlier or later.
9. **Inline Temp when a temporary obscures a simple expression or blocks another refactoring,** only when the expression is cheap and clear. Do not use it when the name explains a non-obvious concept or the temp prevents repeated side effects. Check: evaluation count and order are unchanged.
10. **Split Temporary Variable when one variable is assigned different meanings over time;** keep intentional accumulators. Check: each new variable has one meaning and every use points at the intended one.
11. **Remove Assignments to Parameters when a method uses a parameter as scratch space:** introduce a local and leave the parameter read-only. Do not use it where the language intentionally models output parameters and callers rely on that. Check: caller-visible behavior is unchanged.
12. **Use Replace Method with Method Object only when Extract Method cannot proceed because of entangled locals** (`SHOULD`); never for a simple long method. Check: the plan says what blocked plain extraction.
13. **Use Substitute Algorithm only after behavior is well protected,** and never to silently change semantics, performance guarantees or edge-case behavior (`MUST NOT`). Check: old and new compared on boundary inputs.

### Technique table

| Technique | Use when | Do not use when | Safe steps (short) | Verify |
| --- | --- | --- | --- | --- |
| Extract Method | A fragment has a coherent purpose, needs a comment, or repeats elsewhere | It hides required side effects or depends on too much changing local state | Account for inputs, outputs, mutations; extract; name by purpose; replace the fragment with a call | Tests around the caller; state flow of mutated variables |
| Inline Method | The name adds nothing beyond the body and the indirection obscures the caller | It is an override point, a public contract or a useful concept name | Inspect all callers; substitute the body; delete only when none remain | Dispatch and interface usage; caller tests |
| Extract Variable | An expression is hard to read in place | The variable would only repeat the expression | Immutable local near use; name the concept; keep evaluation order | Tests; no side effect moved |
| Inline Temp | A temp hides a simple expression or blocks another step | The name explains a concept or prevents repeated side effects | Replace references with the expression; delete the temp | Evaluation count and order |
| Replace Temp with Query | A temp blocks extraction or repeats a meaningful calculation | The calculation is expensive, stateful or order-dependent | Create the query; replace reads; remove the temp | Result equivalence; hot paths |
| Split Temporary Variable | One variable holds several meanings | It is an intentional accumulator | One variable per meaning; update uses | Each use reads the right value |
| Remove Assignments to Parameters | A parameter is reused as scratch | Output-parameter semantics are relied on | Introduce a local; replace assignments | Caller-visible behavior |
| Replace Method with Method Object | Locals entangle the method so extraction fails | A plain Extract Method suffices | Create the object; move locals to fields; move the algorithm; split steps | Algorithm output and side effects |
| Substitute Algorithm | A clearer equivalent exists | Semantics, performance guarantees or edge cases would change | Capture behavior; replace; compare on edge cases | Broad tests, boundary inputs |

## Procedure

1. Pick the technique and read its row, including "do not use when".
2. For extraction: write the reads, writes, needed-afterwards list; decide what is returned.
3. Make the change in the smallest compilable unit; keep the old code until the new call works.
4. Run the tests that cover the caller. Look at the diff for moved side effects or changed evaluation order.
5. Name check: read the new name without its body. If it misleads, rename before continuing.
6. Stop at the diagnosed stop condition (`/refactoring-guru:stop-and-defer`).

## Example

A report method computes totals in a loop and then derives a label from them. The loop is extracted; both variables it modifies are needed afterwards, so both are returned.

```python
# Before
def report(rows):
    total = 0
    count = 0
    for r in rows:
        if r["status"] == "paid":
            total += r["amount"]
            count += 1
    average = total / count if count else 0
    label = "high" if average > 100 else "normal"
    return total, count, label

# After
def paid_totals(rows):
    total = 0
    count = 0
    for r in rows:
        if r["status"] == "paid":
            total += r["amount"]
            count += 1
    return total, count

def average_label(total, count):
    average = total / count if count else 0
    return "high" if average > 100 else "normal"

def report(rows):
    total, count = paid_totals(rows)
    return total, count, average_label(total, count)
```

Both `total` and `count` are written inside the first fragment and read after it, which is exactly the case rule 3 targets. The names state purposes (`paid_totals`, `average_label`), and neither function hides an effect.

## Anti-patterns

- **Lost write.** An extraction that mutates a local copy while later code still reads the old variable. Detect: a variable assigned in the extracted function and read after the call without being returned.
- **Mechanical name.** `processLoop`, `step2`, `doRest`. Detect: the name describes how, not what for.
- **Hidden effect.** `calculateTotal` that also saves. Detect: writes to fields, files or collaborators inside a query-sounding method.
- **Query with a cost.** Replace Temp with Query on a database call inside a loop. Detect: the new query is called repeatedly without caching.
- **Inline of intent.** Inlining `isEligibleForRefund(order)` because it is one line. Detect: the body is a business rule with a name that carries meaning.

## Trade-offs and exceptions

- Method Object is allowed when locals are tangled, but it is the risky rung because it changes the algorithm's shape; prefer Replace Temp with Query and parameter objects first.
- Inline a method that only forwards when the indirection obscures the caller, but keep it when it is an override point.
- Do not avoid extraction because of a negligible call cost.
- Added judgment: for a hot path, measure before and after rather than trusting either intuition.

## Verification

- [ ] A reads, writes and needed-afterwards list exists for each extraction.
- [ ] Every extracted name states purpose and does not hide an effect.
- [ ] Evaluation order and count are unchanged for introduced or removed temps.
- [ ] No inlined method was an override point, a public contract or a named business rule.
- [ ] Tests covering the caller ran after each technique.

## Related

`/refactoring-guru:size-smells` for diagnosis; `refactoring-guru:method-extractor` to carry out an extraction; `refactoring-guru:method-body-reviewer` to review the result; `/refactoring-guru:conditional-moves` for conditions; `/refactoring-guru:public-compatibility` before inlining anything public.

## Source

- `Composing Methods`
- `Composing Methods Playbook`
- `Technique Playbook`: only the rule that every entry states symptom, use, avoid, steps and verification.
- `Extraction Safety`
- `Inlining Safety`: only the Inline Method rules.
- `Long Method`: only the rule not to avoid extraction because of a negligible call cost.
- `Decision Anti-Patterns`: only the rule not to inline names that explain business intent.
- `Smell-to-Treatment Priority Map`: only the Long Method row, which makes Replace Method with Method Object the risky rung and lists the fallbacks tried first.
