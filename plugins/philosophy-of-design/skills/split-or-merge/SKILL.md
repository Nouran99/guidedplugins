---
name: split-or-merge
description: "Use when deciding whether to extract, split or merge units larger than a function (classes, files, services, packages), or when understanding one idea means jumping through shallow fragments or a module hides two unrelated decisions."
---

# Split or merge

Decides, for any boundary between units of code, whether it reduces total complexity. The test applies in both directions: it can approve a split and it can demand a merge. Forwarding layers are the special case in `/philosophy-of-design:pass-through-layers`; function bodies and variables are `/philosophy-of-design:functions-and-variables`.

## When to use

- You are about to extract a function, class, file or service.
- Understanding one operation means opening several tiny units.
- Two units always change together, or one unit changes for unrelated reasons.
- A reviewer asks "why is this a separate module?"

## Rules

1. **Separate code only when the separation reduces complexity, hides a real design decision, or creates a stronger abstraction.** Check: you can state which of the three it does.
2. **Combine code when split pieces force readers to jump between shallow fragments to understand one idea.** Check: following one operation requires opening several units that each do little.
3. **Keep related state, behavior and invariants together when separating them would create change amplification.** Check: a plausible change touches every piece of the split.
4. **Do not preserve a boundary merely because it exists** if it exposes almost as much complexity as it hides. Check: ask what would break if the boundary were deleted today.
5. **Prefer one coherent deeper module over several tiny modules that make callers coordinate details.** Check: callers use the group together and in a fixed pattern.
6. **Do not split by execution phase when the stable concept is not temporal.** Check: the pieces are named for steps (`/philosophy-of-design:temporal-decomposition`).
7. **Do not separate normal and special cases so far apart that their shared invariant is hidden.** Check: the special case's file does not mention the rule it depends on.
8. **Do not add helper layers that distribute one design decision across many files.** Check: changing the decision means editing every helper.
9. **Added judgment: the two-sided split test.** A new unit must be understandable without the caller's context, and its interface must be simpler than what it hides. Check: write its contract using only its own vocabulary; if you cannot, do not split.
10. **Added judgment: the merge test.** Units that are always called together, always changed together and share an invariant are one unit. Check: version history shows them in the same commits.

## Procedure

1. Name the boundary and the two sides.
2. List what the boundary separates: state, behavior, invariants and decisions.
3. Apply the split test (rule 9) and the merge test (rule 10); decide keep, merge or split.
4. To merge, move the code into the unit that owns the shared invariant, narrow the interface, and delete the old boundary.
5. To split, extract along the nameable concept, write the new contract, and make the old unit call it.
6. Run the tests after each step; update callers.

## Example

```java
// Before: three tiny units cooperate, but none can be right alone
final class QuoteStripper { String strip(String s) { return s.startsWith("\"") ? s.substring(1, s.length() - 1) : s; } }
final class FieldSplitter { List<String> split(String line) { return Arrays.asList(line.split(",")); } }
// A quoted field containing a comma ("Smith, Ann") is split in the wrong place before it can be stripped.

// After: one unit owns the shared invariant (are we inside quotes?)
final class CsvLine {
    /** Splits one CSV line into fields. Commas inside double quotes do not split; a doubled quote inside a quoted field is one literal quote. */
    static List<String> parse(String line) {
        List<String> fields = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean quoted = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (quoted) {
                if (c == '"' && i + 1 < line.length() && line.charAt(i + 1) == '"') { current.append('"'); i++; }
                else if (c == '"') quoted = false;
                else current.append(c);
            } else if (c == '"') quoted = true;
            else if (c == ',') { fields.add(current.toString()); current.setLength(0); }
            else current.append(c);
        }
        fields.add(current.toString());
        return fields;
    }
}
```

The split looked tidy and was wrong: the quote state is shared knowledge, so separating the splitting from the stripping hid the invariant. Merging made the unit correct and its contract one sentence.

## Anti-patterns

- **Fragment soup.** Many units of a few lines each. Detect: units whose contracts cannot be stated without the caller.
- **Phase split.** Units named for steps. Detect: `Reader`, `Parser`, `Validator`, `Writer` for one format.
- **Invariant divorce.** A rule enforced in one file and relied on in another. Detect: a comment saying "must match X.java".
- **Boundary by habit.** A layer or package kept because it was always there. Detect: no one can say what it hides.
- **Distributed decision.** One design decision spread across helpers. Detect: a change request that edits every helper.

## Trade-offs and exceptions

- Size is a signal, not a rule. A very large unit that hides two unrelated decisions should be split along that seam; the test is what the boundary hides, not how many lines it holds.
- Ownership, deployment and release boundaries (separate teams, separate services) can justify separation that code-level complexity alone would not (Added judgment).
- Test convenience is not a reason to split; the source warns against letting tests force shallow or leaky interfaces.
- Merging is not an invitation to build a god module; merge units that share an invariant, not unrelated ones.

## Verification

- [ ] Every new unit passes the two-sided test (understandable alone, interface simpler than its contents).
- [ ] No tiny fragment is called from only one place and unusable elsewhere.
- [ ] Shared invariants sit in one unit or are named in both.
- [ ] No boundary survives only because it already existed.
- [ ] Tests pass after each merge or split.

## Related

`/philosophy-of-design:pass-through-layers`; `/philosophy-of-design:functions-and-variables`; `/philosophy-of-design:deep-modules`; `philosophy-of-design:split-merge-reviewer` to review; `/philosophy-of-design:collapse-layer` to merge a layer.

## Source

- `Combine or Separate Code`
- `Function and Variable Rules`: only the rule against chains of tiny functions that readers must jump through.
