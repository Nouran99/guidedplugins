---
name: strategic-programming
description: "Use when a change is a quick patch, a copy-paste to meet a deadline, one more exposed detail or flag, or when recurring friction suggests reshaping an abstraction. Sizes the design investment a change deserves."
---

# Strategic programming

Decides how much design work a change deserves and refuses the patches that make the next change harder. It is about the attitude and scale of a change; structure itself is handled by the other skills. For a read-only judgment of a diff's approach, delegate to `philosophy-of-design:tactical-patch-reviewer`.

## When to use

- The quickest fix adds a special case, a flag, a copy of existing code, or one more exposed field.
- The same workaround is about to appear a third time.
- A deadline is being used to justify leaving the structure worse.
- You have just made the tests pass and must decide whether the change is finished.

## Rules

1. **Spend time reducing future complexity, not only making the current change pass.** A first working patch is not done if it makes the next change harder. Check: say what the next likely change will touch, before and after.
2. **Reshape abstractions when recurring friction appears.** Check: the same awkward workaround exists in more than one place; the repeat is the evidence.
3. **Invest in interfaces and decomposition that make future changes local.** Check: the next plausible change lands in one module.
4. **Leave behind a clearer structure after every substantial edit.** Check: name one thing in the touched area that is easier to understand than before.
5. **Avoid patching local symptoms while increasing global complexity.** Check: ask "who else now has to know about this fix?"
6. **Avoid copy and paste to meet a deadline.** Check: the diff contains a block that duplicates an existing block with small changes.
7. **Avoid exposing one more internal detail instead of designing a better boundary.** Check: the diff widens a visibility modifier or adds a getter for a field another module needs.
8. **Avoid adding flags and exceptions to dodge a better abstraction.** Check: the diff adds a parameter or branch whose purpose is to leave other code untouched (`/philosophy-of-design:flags-and-knobs`).
9. **Added judgment: size the investment to the change.** A one-line fix earns a one-line improvement; a new feature earns a boundary check; a third repetition earns the abstraction. Do not turn a small task into a redesign. Check: the extra work stays inside the files the task already touches.
10. **Added judgment: strategic is not speculative.** Reduce complexity that exists, or is about to be repeated; do not build for imagined futures, because vague generality is also complexity (`/philosophy-of-design:generality-and-special-cases`).

## Procedure

1. Write the tactical version in your head (the shortest patch) and list what it adds: a branch, a copy, a flag, an exposed detail, a new fact callers must know.
2. Ask what the strategic version would change: which boundary, which owner, which interface.
3. Pick the smallest strategic move that removes the added facts for the code this task touches.
4. If the move is larger than the task, do the tactical fix in the cleanest form available and record the larger change as a proposal with its evidence (the repeated sites).
5. Finish by naming what is now easier to understand.

## Example

```ts
// Tactical: each deadline handler gets its own copy of the workaround.
// orders.ts
const placed = new Date(row.placed.replace(" ", "T") + "Z");
// shipping.ts
const shipped = new Date(row.shipped.replace(" ", "T") + "Z");
// invoices.ts (new, today)
const due = new Date(row.due.replace(" ", "T") + "Z");

// Strategic: the third copy is the signal; one module owns the format.
// timestamps.ts
/** Parses "YYYY-MM-DD HH:MM:SS" as UTC, the form the ledger service emits. */
export function parseLedgerTimestamp(s: string): Date {
  const d = new Date(s.replace(" ", "T") + "Z");
  if (Number.isNaN(d.getTime())) throw new RangeError(`not a ledger timestamp: ${s}`);
  return d;
}
// orders.ts, shipping.ts, invoices.ts
const placed = parseLedgerTimestamp(row.placed);
```

The change touches the three files that already carried the knowledge and nothing else; the next format change lands in one place.

## Anti-patterns

- **Deadline copy.** A pasted block with edits. Detect: two blocks with the same shape in the diff or the tree.
- **One more flag.** A parameter added so the new caller does not disturb old ones. Detect: the parameter has one non-default caller.
- **One more exposed detail.** A field made public for the next module. Detect: widened visibility in the diff.
- **Tactical tornado.** High output that leaves the structure worse for the next person. Detect: each change adds branches and none removes any.
- **Rewrite creep.** Using "strategic" to justify a redesign nobody asked for. Detect: the diff touches files the task did not need.

## Trade-offs and exceptions

- In an emergency, ship the smallest safe fix and record the follow-up with the sites that prove the pattern (Added judgment). The rule is about the default, not about refusing to ever patch.
- Investment has diminishing returns. Stop when the touched area is clearer and the next likely change is local.
- Explicit user instruction and repository conventions outrank this skill; say which rule the request conflicts with.
- The book's rules do not require a refactor of untouched code; propose, do not perform.

## Verification

- [ ] The diff names what became easier to understand.
- [ ] No block was copied; repeated knowledge has one owner.
- [ ] No visibility was widened to avoid designing a boundary.
- [ ] No flag or branch was added only to avoid touching other code.
- [ ] The work stayed inside the files the task touched, or a proposal was written instead.

## Related

`/philosophy-of-design:flags-and-knobs`; `/philosophy-of-design:information-hiding`; `/philosophy-of-design:plan` to sequence the change; `philosophy-of-design:tactical-patch-reviewer` to review; `/output-style philosophy-of-design:pair` for small narrated steps.

## Source

- `Strategic Programming over Tactical Programming`
- `Strategic Programming`
- `Tactical Programming`
- `Tactical Complexity Debt`
