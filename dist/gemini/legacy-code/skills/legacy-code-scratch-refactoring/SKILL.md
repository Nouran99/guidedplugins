---
name: "legacy-code-scratch-refactoring"
description: "Use when code is too tangled to understand before a change: throwaway restructuring, marking and grouping responsibilities, keeping exploratory edits out of the commit. Choosing what to test is `legacy-code-test-points`; a real extraction under tests is `legacy-code-large-methods`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Scratch refactoring: restructure to understand, then discard

Change a copy of the code to learn what it does, write down what you learned, and throw the change away. The product is understanding: a list of responsibilities, the effects, and the open questions. Choosing where to observe effects is `legacy-code-test-points`; a real extraction that stays under tests is `legacy-code-large-methods`.

## When to use

- You have read a long method twice and still cannot say what it does.
- The code mixes loading, rules, persistence and notification in one body and you cannot tell which lines are which.
- You are about to move behavior and want to know what you would be moving.
- A reviewer asks whether the restructuring you did was only for learning.

## Rules

1. **Use scratch refactoring to understand code, but discard it unless later backed by tests and review.** [MUST] Check: the exploratory edits do not appear in the diff you hand over, unless tests and review were added afterwards.
2. **Do not check in exploratory restructuring that was only used to learn.** [MUST NOT] Check: no commit contains edits whose only purpose was to read the code.
3. **Sketch, mark or group responsibilities in large code before moving behavior.** [MUST] Check: before any behavior moves, a list of responsibilities exists with the lines that belong to each.
4. **Let excessive setup, impossible observation and repeated changes point to smaller extracted responsibilities.** [Compact checklist] Check: each responsibility you name corresponds to a pain you observed: a setup step, an effect you could not see, or a place edits keep landing.
5. **Treat the result as notes, not as code.** [Added judgment] The deliverable is a responsibility table, an effect list and open questions. Check: you can hand the notes to someone who has not seen the scratch edits.
6. **Make the scratch work trivially discardable.** [Added judgment] Work on a copy, a throwaway branch the user chose, or edits you can list and undo by hand. Do not commit them, and do not run history-rewriting or cleaning commands; if the scratch edits are in the working tree, tell the user they are scratch and let them discard them with their own commands. Check: the report states how the scratch edits were discarded or who will discard them.
7. **Re-confirm anything you learned before relying on it.** [Added judgment] A scratch restructuring can change behavior without anyone noticing. Check: each claim that drives a later change is backed by a run, a probe or a characterization test.
8. **Name each responsibility as a verb phrase and group by reason to change.** [Added judgment] "Load open entries", "apply sign rules", "decide whether closing is allowed". Check: no group is named after code structure ("loop", "helper").
9. **Mark in place, then remove the marks.** [Added judgment] Temporary marker comments are probes: they follow the same rule as sensing variables, remove after use. Check: a search for your marker finds nothing in the handed-over diff.
10. **Stop when you can state responsibilities, effects and open questions.** [Added judgment] The source gives no time limit. Check: you can stop without tidying; if you are polishing names, you are writing a patch.
11. **If the scratch pass starts to look like the change, restart from the loop.** [Added judgment] Pin first (`legacy-code-legacy-loop`), then redo the useful part as a tested step.

## Procedure

1. Choose the code to understand and say what you want to know (what it does, which lines to change, where effects go).
2. Mark responsibilities in a copy: a short tag per line group. Move lines together only if that clarifies the grouping.
3. Write the responsibility table: tag, verb phrase, inputs, outputs and effects, dependency kind (pure policy, load, persist, notify, ambient input).
4. Write the open questions, in particular behavior that looks odd.
5. Discard the scratch edits (rule 6). Keep the notes.
6. Choose the next safe move: test point (`/legacy-code:effect-sketch`), characterization (`/legacy-code:characterize`) or seam (`/legacy-code:find-seam`).

## Example

A marked scratch copy of an untested function, then the notes it produced.

```python
# SCRATCH COPY: markers added for understanding only; discard after taking notes
def close_month(ledger_id, today):
    rows = db.query("select * from entries where ledger=? and closed=0", ledger_id)  # [R1 load]
    total = 0
    for r in rows:
        if r.kind == "credit":          # [R2 balance]
            total -= r.cents
        else:
            total += r.cents
    if total != 0 and today.day < 28:   # [R3 closing rule]
        raise ClosingTooEarly(total)
    db.execute("update entries set closed=1 where ledger=?", ledger_id)  # [R4 persist]
    mail.send(owner_of(ledger_id), "Closed", f"Balance {total}")         # [R5 notify]
    return total
```

```text
Notes (kept)
R1 load open entries        in: ledger_id           out: rows              dependency: database
R2 compute balance          in: rows                out: total             pure policy (credits subtract)
R3 decide closing allowed   in: total, today        out: raise or go on    pure policy; reads today.day
R4 mark entries closed      in: ledger_id           effect: database write
R5 notify owner             in: ledger_id, total    effect: email
Open questions: why day 28? why does a zero balance close early? (R3 skips the check when total is 0)
Next safe move: characterize R2 and R3 through close_month, then extract them as pure functions
```

Nothing in the scratch copy is shipped; the table tells the next step which two parts are pure and which three are effects.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Scratch commit | A commit whose message says "restructure to understand" | Drop it; keep only the notes |
| Unverified insight | A later change relies on a claim from the scratch pass with no test | Pin it |
| Marker litter | Tags like `[R1]` left in source | Remove; search for the tag |
| Polishing | Renames and formatting in the scratch copy | Stop; take notes |
| Scratch as the change | The scratch edit is simply reused as the patch | Restart from the loop; redo under tests |

## Trade-offs and exceptions

- The source allows keeping scratch work only when later backed by tests and review; in practice that means redoing it as a tested step, not promoting the scratch diff.
- Added judgment: for code you can understand by reading and an effect sketch, do not restructure; the scratch pass is for code that defeats reading.
- Without version control a copy of the file is the only way to make scratch work discardable; say where the copy is.

## Verification

- [ ] The handed-over diff contains no exploratory edits.
- [ ] A responsibility table with verb-phrase names exists.
- [ ] Open questions are listed.
- [ ] Markers are removed.
- [ ] Claims that drive a change are confirmed by a run or a test.
- [ ] The next safe move is named.

## Related

`legacy-code-test-points` and `/legacy-code:effect-sketch` for choosing where to observe; `legacy-code-large-methods` for the real extraction; `/legacy-code:mode-explorer` for a session-long understanding mode; `/legacy-code:characterize` to pin what you learned.

## Source

- `Test Selection and Understanding Rules`: only the rules on scratch refactoring, on sketching, marking and grouping responsibilities, and on not checking in exploratory restructuring.
- `Legacy Refactoring Heuristics`: only the heuristics on excessive setup and impossible observation as information.
