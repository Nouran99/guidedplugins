---
name: orthogonality
description: "Use when one change forces edits in many unrelated places, two modules share a responsibility, or policy, mechanism, data, presentation, orchestration and computation are tangled. Shared mutable state is `shared-state`; reach-through calls and call order are `shy-code`."
---

# Orthogonality

Keep components independent so that changing one thing does not force changes elsewhere. This skill judges module boundaries and the ripple of a change. How one object reaches into another and the order of calls belong to `/pragmatic-programmer:shy-code`; mutable state, globals and ambient context belong to `/pragmatic-programmer:shared-state`.

## When to use

- A small change needs edits in many unrelated places.
- Two modules both seem responsible for the same thing (both parse the date, both decide the discount).
- One function mixes what to do (policy) with how it is done (mechanism), or a calculation with the I/O that feeds it.
- A shared `utils`, `common` or `helpers` module is imported everywhere and keeps growing.

## Rules

1. **Keep components independent so one change does not force unrelated changes elsewhere.** [MUST] Check: for a planned change, list the files that must change; any file with no reason in the owner's responsibility is a coupling.
2. **Avoid overlapping responsibilities between modules.** [MUST NOT] Check: state each module's responsibility in one sentence; if two sentences share a verb and an object, one module is doing the other's job.
3. **Separate policy from mechanism.** [MUST] Policy is the decision that changes with the business (limits, rates, who qualifies); mechanism is the machinery that carries it out (a loop, a queue, an HTTP call). Check: a policy change touches data or a policy module only.
4. **Separate data from presentation.** [MUST] Check: display formatting (currency strings, labels, colors) is not in domain or storage code, and display code does not compute business values.
5. **Separate orchestration from computation.** [MUST] Check: the computation runs on plain values with no fakes; the orchestrator holds the sequence and the I/O.
6. **Do not let one module know too much about the internals of another.** [MUST NOT] Check: callers use only the public surface; none reaches into fields or private helpers.
7. **Do not let shared utility modules create sideways coupling.** [MUST NOT] Check: each utility file has one stated purpose, and no feature imports a utility that itself imports features.
8. **When one change needs edits in many unrelated places, repair the missing boundary before it spreads.** [Compact checklist] Check: after the repair, the same kind of change touches one place.
9. **Keep interfaces narrow.** [Compact checklist] Check: every public function and type is used outside its module; unused surface is made private or removed.
10. **Find hidden coupling by looking at what changes together.** [Added judgment] Use read-only history (`git log --name-only` over recent commits): files that change together without an import link between them are candidates. Check: each pair has an explanation or a boundary.
11. **Do not split a module for tidiness when the halves always change together.** [Added judgment] Orthogonal means independent change; a split pair that co-changes is worse than one module. Check: after a split, a typical change touches one half.

## Procedure

1. State the change you are making.
2. List everything that had to change or would have to. Mark each as the owner's responsibility or as ripple.
3. For each ripple, name its kind: duplicated knowledge (`/pragmatic-programmer:dry-knowledge`), overlapping responsibility, policy tangled with mechanism, presentation tangled with data, orchestration tangled with computation, or a global (`/pragmatic-programmer:shared-state`).
4. Choose the smallest boundary that removes the ripple: move a function, lift a policy into a table, split calculation from I/O.
5. Check that the next likely change of the same kind touches one place.
6. Run the tests after each move.

## Example

Adding a tax rate for a new country meant editing the function that loads invoices, saves them and formats the amount.

```python
from decimal import Decimal

# Before: policy, computation, persistence and presentation in one function
def finalize_invoice(invoice_id):
    inv = db.fetch_invoice(invoice_id)
    subtotal = Decimal("0")
    for line in inv.lines:
        subtotal += line.qty * line.unit_price
    rate = Decimal("0.20") if inv.country in ("DE", "FR") else Decimal("0")   # tax policy inline
    inv.total = (subtotal * (1 + rate)).quantize(Decimal("0.01"))
    db.save(inv)
    return f"{inv.total:,.2f} {inv.currency}"                                 # presentation returned with the save

# After
TAX_RATE_BY_COUNTRY = {"DE": Decimal("0.20"), "FR": Decimal("0.20")}          # policy: data owned by finance

def invoice_total(lines, country):                                            # computation: values in, value out
    subtotal = sum((l.qty * l.unit_price for l in lines), Decimal("0"))
    rate = TAX_RATE_BY_COUNTRY.get(country, Decimal("0"))
    return (subtotal * (1 + rate)).quantize(Decimal("0.01"))

def finalize_invoice(invoice_id):                                             # orchestration
    inv = db.fetch_invoice(invoice_id)
    inv.total = invoice_total(inv.lines, inv.country)
    db.save(inv)
    return inv

def format_money(amount, currency):                                           # presentation
    return f"{amount:,.2f} {currency}"
```

Callers that used the returned string now call `format_money(inv.total, inv.currency)`. A new country is a dictionary entry, `invoice_total` is tested with plain values, and the display format changes in one function.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Shotgun change | A one-line business change touches many unrelated files | Find the fact or boundary that is missing (`/pragmatic-programmer:dry-knowledge`, or a new boundary) |
| Policy in mechanism | Business constants inside loops, handlers or clients | Lift them into data or a policy module |
| Calculation welded to I/O | A calculation you cannot test without a database or network fake | Split a pure function out of the orchestrator |
| Presentation in the domain | Domain or storage code that builds display strings | Move formatting to the display layer |
| God utility | `utils` or `common` imported by unrelated features and growing | Give each function to the module that owns its concept |
| Twin owners | Two modules both normalize or decide the same thing | Pick one owner and delete the other |
| Over-splitting | Pieces that always change together live in different modules | Merge them back |

## Trade-offs and exceptions

- The source asks for pragmatism: orthogonality is a means to cheap change. Do not add layers for a change that touches one place.
- Some coupling is intended: a module and its tests, the parts of one feature, a schema and its migration. Added judgment: judge by whether they change for the same reason.
- A boundary costs indirection and files. Add one when a real change rippled (rule 8), not in anticipation; volatility you can already name belongs to `/pragmatic-programmer:reversible-choices`.
- Dependency direction between architectural layers is the territory of a Clean Architecture plugin; this skill only asks that changes not ripple.

## Verification

- [ ] The change touches only files within one owner's responsibility, or each extra file has a stated reason.
- [ ] Each touched module's responsibility fits one sentence and does not overlap a neighbor's.
- [ ] Policy, presentation and computation can each change without editing the others.
- [ ] No new `utils` or `common` function was added where a domain owner exists.
- [ ] The tests pass after each boundary move.

## Related

`/pragmatic-programmer:shy-code` for reach-through and call order; `/pragmatic-programmer:shared-state` for globals and ambient context; `/pragmatic-programmer:dry-knowledge` when the ripple is a copied fact; `pragmatic-programmer:coupling-reviewer` to review a diff.

## Source

- `Orthogonality Rules`
- `Non-Orthogonal Design`
- `Review Rules`: only the instruction to look for hidden couplings.
- `Code Generation Rules`: only the default of orthogonal responsibilities and the avoidance of tangled modules.
