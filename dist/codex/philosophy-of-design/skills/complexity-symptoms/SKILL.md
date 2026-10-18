---
name: "complexity-symptoms"
description: "Use when a change feels awkward, one edit touches many files, a reader must reconstruct hidden dependencies, or you must judge whether a design got simpler. Names the symptom and asks the default-response questions before any edit."
---

# Complexity symptoms

Diagnoses why a design is hard to understand or hard to change, and names the symptom precisely enough to choose a treatment. It treats nothing itself: the sibling skills linked at the end do that. Gathering the evidence with history commands is `$philosophy-of-design:symptom-trace`.

## When to use

- A small change forced edits in many files.
- Someone asked "what else does this affect?" and the code could not answer.
- A reviewer says "I cannot follow this" but cannot point at a long function.
- You must say whether a refactor made the design simpler or only shorter.
- A feature "should be easy" and is not.

## Rules

1. **Define complexity by its effect, not its look.** Complexity is anything that makes the software hard to understand or hard to change; short, tidy, familiar code can be complex. Check: finish "this is hard to understand or change because ..." with a concrete cost to a named reader.
2. **Treat change amplification as an architectural warning.** A small conceptual change that needs edits in many places means one decision lives in many places. Check: list the files of the last similar change (`git log --stat`) and mark which edits repeated the same decision.
3. **Treat cognitive load as an architectural warning.** Count what a reader must know at once to change one thing safely: types, call order, hidden invariants, conventions. Check: write that list for the function you are editing; every item that belongs to another module is load that leaked.
4. **Treat unknown unknowns as an architectural warning.** The worst case: it is unclear which code must change or which facts matter. Check: ask "if I change X, what else must change?" and see whether the answer is visible from types, names and tests, or only from memory.
5. **Treat hidden dependencies as an architectural warning.** Two pieces of code must agree (a format, an ordering, a unit, a key) and nothing in the interface says so. Check: search for the same literal, key or format in more than one module.
6. **Treat information spread across many places as an architectural warning.** One idea that has to be assembled from several files. Check: after reading a single module, can you explain the idea?
7. **Treat temporal coupling that readers must reconstruct as an architectural warning.** Check: is there an "A before B" rule that is written nowhere in the code's structure? (`$philosophy-of-design:temporal-decomposition`)
8. **Before editing a feature that feels awkward, answer the default-response questions.** Is the interface too wide? Is the behavior scattered? Are details leaking that should be hidden? Are there too many special cases? Are we solving a tactical local problem while raising global complexity? Check: each answer cites a file and line.
9. **Prefer the design that lowers future cognitive load, not present typing effort.** Do not optimize for shorter files, fewer lines or clever compactness if complexity rises. Check: a change that deletes lines also deletes facts the reader must hold; if it does not, it is cosmetic.
10. **Added judgment: weigh a symptom by who pays and how often.** A hidden dependency in a module that every feature touches outranks the same dependency in a leaf. Check: count distinct callers or editors affected.

## Procedure

1. State the complaint in the reader's words ("I had to open seven files to add a currency").
2. Collect evidence: for amplification, the recent related commits; for cognitive load, the list of facts; for unknown unknowns, the question you cannot answer from the code.
3. Name the dominant symptom from rules 2 to 7. Two symptoms often share one cause; name both.
4. Answer the five questions of rule 8.
5. Route to a treatment (Added judgment, the plugin's own mapping):

| Symptom | Usual cause | Treat with |
| --- | --- | --- |
| Change amplification | One decision known by many modules | `$philosophy-of-design:information-hiding`, `$philosophy-of-design:pull-complexity-down` |
| Cognitive load | Wide or shallow interfaces, special cases in the core path | `$philosophy-of-design:deep-modules`, `$philosophy-of-design:generality-and-special-cases` |
| Unknown unknowns | Hidden dependencies, surprising behavior | `$philosophy-of-design:naming-and-obviousness`, `$philosophy-of-design:comments-as-design` |
| Hidden dependencies | Implicit agreement between modules | `$philosophy-of-design:information-hiding` |
| Temporal coupling | Phase-shaped decomposition | `$philosophy-of-design:temporal-decomposition` |

6. After the change, repeat the same measurement and report before and after.

## Example

```ts
// Before: amount formatting is decided in three places (change amplification).
// invoice.ts
const label = "$" + (totalCents / 100).toFixed(2);
// receipt.ts
const line = "$" + ((priceCents * qty) / 100).toFixed(2);
// email.ts
const body = `Amount due: $${(dueCents / 100).toFixed(2)}`;
// Supporting euros means finding and editing every one of them.

// After: one module owns how an amount is written.
// money.ts
/** Formats an amount given in cents, the minor unit of a two-decimal currency. Digits are grouped by locale: 123456 is "$1,234.56". */
export function formatMoney(amountCents: number, currency: string, locale = "en-US"): string {
  return new Intl.NumberFormat(locale, { style: "currency", currency }).format(amountCents / 100);
}
// invoice.ts, receipt.ts, email.ts
const label = formatMoney(totalCents, order.currency);
```

The symptom was change amplification; the cause was one decision (how money is written) repeated; the treatment moved the decision to one owner. The output changed slightly (thousands separators now appear), and a currency with a different number of decimals, such as JPY or KWD, needs a minor-unit lookup inside `formatMoney` only; both are decisions that now have exactly one home.

## Anti-patterns

- **Line-count proxy.** Judging by file or function length instead of reader cost. Detect: a finding that cites length and names no fact the reader must hold.
- **Symptom whack-a-mole.** Fixing each occurrence without moving the decision. Detect: the third copy of the same workaround.
- **Label without a fact.** Calling something "tightly coupled" without naming the shared fact. Detect: a finding that cannot finish "these two must agree on ...".
- **Diagnosis by feel.** Starting the edit before answering the five questions. Detect: no evidence in the plan, only adjectives.

## Trade-offs and exceptions

- The source calls these warnings, not defects: investigate each, do not treat every multi-file edit as a design failure. A public API rename touches its callers by definition (Added judgment).
- Inherently hard domains carry cognitive load that cannot be deleted; the aim is to place it in one module so callers do not share it.
- A symptom with a small, one-time cost may be left alone when fixing it is out of scope; record it instead of widening the task.

## Verification

- [ ] The complaint is stated as a cost to a named reader.
- [ ] At least one piece of evidence (history, fact list or unanswerable question) backs the diagnosis.
- [ ] The five default-response questions were answered with file and line.
- [ ] The treatment targets a cause, not one occurrence.
- [ ] The same measurement was repeated after the change.

## Related

`$philosophy-of-design:symptom-trace` for gathering evidence; `philosophy-of-design-complexity-reviewer` for a net-complexity ledger of a diff; `$philosophy-of-design:information-hiding`, `$philosophy-of-design:pull-complexity-down` and `$philosophy-of-design:temporal-decomposition` for the usual treatments.

## Source

- `Core Complexity Rules`
- `Symptoms of Complexity`
- `Default Response`
- `Primary Directive`
