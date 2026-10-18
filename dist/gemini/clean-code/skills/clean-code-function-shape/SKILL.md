---
name: "clean-code-function-shape"
description: "Use when a function is long, deeply nested, mixes levels of detail, or needs a comment to separate its phases. Judges the body: size, one abstraction level, nesting, negative conditionals. Signatures and effects are clean-code-function-contracts; which comments may stay is clean-code-comments."
license: "MIT"
metadata:
  plugin: "clean-code"
  book: "Clean Code"
  invocation: "auto"
---

# Function shape

Judges the body of a function: how long it is, how many things it does, how deeply it nests, and whether it reads top-down. The signature and what a function changes are `clean-code-function-contracts`; the order of functions across a file is `clean-code-formatting`.

## When to use

- A function needs scrolling, or you cannot summarize it without the word "and".
- Raw detail (byte masks, string slicing, SQL fragments) sits next to calls to high-level helpers.
- Indentation goes three or four levels deep, or `else` branches stack up.
- Blank-line-separated blocks inside one function each have a natural title.

## Rules

1. **Keep functions small.** A reader should hold the whole function in mind. Check: every block of the function can be named; no part of it is "the rest". Added judgment: a function that does not fit one screen is a prompt to look, not a violation by itself.
2. **Each function does one thing and has one clear reason to change.** Check: describe it in a sentence without "and" or "then"; if two stakeholders could ask you to change it for different reasons, it has two jobs.
3. **Keep every statement in a function at one level of abstraction.** `validateOrder(order)` and `buf[i] & 0x7F` do not belong in the same body. Check: underline each statement; if the underlines are at different depths of detail, extract the lower ones.
4. **Organize top-down.** The first function a reader meets states the story; details follow below it. Check: the caller appears before its helpers where the language permits, and the top function reads like an outline.
5. **Prefer descriptive names over short names for extracted functions.** A long accurate name is cheaper than a short one that sends the reader to the body. Check: the name says what the block achieves, not how.
6. **Refactor deep nesting into clearer structure.** Use guard clauses for preconditions, extract the inner block, or return early. Check: the happy path is not indented under a pyramid of `if`s.
7. **Prefer straightforward control flow over clever control flow.** Avoid flag variables that steer later branches, `break`/`continue` mazes, nested ternaries and loops that mutate their own bounds. Check: you can trace one input through without keeping a state table.
8. **Isolate conditions and state them positively.** Move a compound boolean into a named predicate (`isEligibleForRefund`) and avoid negative conditionals that obscure intent (`if (!isNotReady)`). Check: no `!` applied to a name that already contains "not", "no" or "un".
9. **Split phases when a function mixes setup, validation, computation and side effects (compact checklist: `mini.md` only; the full rules ask for one thing per function and one level of abstraction).** Check: each phase can be tested without running the others.
10. **Do not let error handling interleave with the main steps.** Move the `try` body into its own function so the steps read in order; the failure design itself is `clean-code-error-handling`. Check: removing the `try`/`catch` leaves a readable sequence.

## Procedure

1. Read the function once without editing. Write a one-line summary in your head; mark every place you hesitated.
2. Mark the abstraction level of each statement (high, middle, low). Group consecutive statements of the same level.
3. Convert preconditions into guard clauses first; this usually removes the deepest nesting without extracting anything.
4. Extract the lowest-level group that has a meaningful name. Run the tests. Repeat until the top function is one level.
5. Reorder so each caller sits above the functions it calls.
6. Stop when a new extraction would only restate the code in a name. Inline anything that earned no benefit (see Trade-offs).

## Example

```python
# Before
def register(att, ws, today):
    if att.email and "@" in att.email:
        if ws.seats_taken < ws.capacity:
            fee = ws.price
            if att.is_member:
                fee = fee * 0.8
            elif (ws.starts_on - today).days > 30:
                fee = fee * 0.9
            db.insert("registrations", att.id, ws.id, fee)
            mailer.send(att.email, "Registered", f"Fee: {fee}")
            return True
        else:
            return False
    else:
        raise ValueError("bad email")

# After
MEMBER_RATE = 0.8
EARLY_BIRD_RATE = 0.9
EARLY_BIRD_LEAD_DAYS = 30

def register_for_workshop(attendee, workshop, today):
    require_contact_email(attendee)
    if workshop.is_full():
        return False
    fee = workshop_fee(workshop, attendee, today)
    save_registration(attendee, workshop, fee)
    send_confirmation(attendee, fee)
    return True

def workshop_fee(workshop, attendee, today):
    if attendee.is_member:
        return workshop.price * MEMBER_RATE
    if (workshop.starts_on - today).days > EARLY_BIRD_LEAD_DAYS:
        return workshop.price * EARLY_BIRD_RATE
    return workshop.price
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Oversized function | Several blank-line-separated blocks with natural titles; section comments inside the body | Extract each titled block under that title |
| Mixed abstraction levels | A high-level call next to arithmetic, string slicing or raw I/O | Extract the low-level run behind a named function |
| Deep nesting | Arrow-shaped indentation; `else` after `return` | Guard clauses, early return, extract inner block |
| Negative conditional | `!` on a name containing a negation; `if (not disabled)` | Rename to the positive and flip the branches |
| Flag-steered flow | A boolean set in one branch and read many lines later | Return from the branch, or extract so the flag disappears |
| Fragment confetti | Ten helpers of two lines called once each, whose names restate the code | Inline the ones that carry no meaning |

## Trade-offs and exceptions

- Inline abstractions that no longer earn their cost. An extraction that adds a jump for the reader without a meaningful name is unnecessary indirection (`clean-code-smells-redundancy`).
- Some code is honestly one level and long, such as a flat table of field mappings or a state-machine transition list. Splitting it by size alone makes it harder to scan; split it only if the parts have meaning.
- Hot paths measured as slow justify keeping a block inline, but only with evidence and a comment that says why.
- A project that favors fewer, deeper functions (a software-design plugin) may arbitrate module boundaries; this skill still governs local readability inside the touched function.

## Verification

- [ ] The top function reads as an outline at one level of abstraction.
- [ ] No block inside any touched function can still be given a separate name.
- [ ] Maximum nesting in touched functions went down or stayed the same.
- [ ] No extracted function is a pass-through or a restatement of its own body.
- [ ] Behavior is unchanged: the tests pass after the last extraction.

## Related

`clean-code-function-contracts` for parameters and effects of the new functions; `clean-code-extract-till-you-drop` for the guided loop; `clean-code-function-extractor` to delegate large jobs; `clean-code-function-reviewer` to review a diff.

## Source

- `Function rules`
- `Formatting and structure`: only vertical ordering from high level to low level.
- `Smells to detect and eliminate`: only the oversized function, mixed abstraction level, deep nesting and negative conditional smells.
