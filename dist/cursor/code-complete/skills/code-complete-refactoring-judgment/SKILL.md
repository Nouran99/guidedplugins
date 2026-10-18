---
name: "code-complete-refactoring-judgment"
description: "Use when deciding whether and how to refactor: structure hides intent, duplicates knowledge or raises defect risk, or refactoring mixes with behavior change or no tests. Symptoms: code-complete-complexity-management. Speed motive: code-complete-performance-tuning."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Refactoring judgment

Decides when restructuring is justified, what must be in place first, and how to keep it separate from behavior change. It does not list the moves or the symptoms: detecting complexity is `code-complete-complexity-management`, each fix is the owning skill, and the delegated agent is `code-complete-refactorer`. For code with no tests and unclear behavior, a `legacy-code` plugin comes first.

## When to use

- You are about to restructure code and need to decide whether the reason is strong enough.
- A feature change and a cleanup are in the same diff.
- The code to be refactored is poorly understood or has no tests.
- A refactoring has grown beyond the problem that justified it.
- A review comment says "while you're here, clean this up".

## Rules

1. **Refactor when structure hides intent, duplicates knowledge or raises defect probability.** Why: these are the three costs refactoring pays back. Check: you can name which of the three applies to the code you are about to change. Added judgment: if none applies, the justification is missing; do not refactor for taste.
2. **Keep refactoring separate from behavior changes when that improves reviewability.** Why: a diff that mixes both cannot be checked for "behavior unchanged". Check: structural changes and behavior changes are separate diffs, steps or commits (you do not create the commit; you keep them separable), each with its own test result.
3. **Compact rule: when refactoring poorly understood or risky code, add tests or analysis first.** Check: before restructuring, either tests pin the current behavior or you have read the code well enough to state what it does and why; otherwise stop and gather that first.
4. **Build in small, verifiable increments.** Check: each step compiles and passes the relevant tests; a failing step is undone before the next.
5. **Review and improve code as part of construction, not only after it.** Check: small improvements inside the area you are changing are made as you go, while they are cheap; a separate cleanup project is not the default.
6. **Do not make arbitrary changes.** Source guidance against arbitrary naming and formatting churn. Check: every restructuring hunk traces to the justifying problem in rule 1.
7. **Remove duplication that multiplies maintenance effort and reduce what a maintainer must keep in mind.** Check: a refactoring that adds an abstraction explains what the reader no longer has to know.
8. Added judgment: behavior is preserved if the same inputs produce the same outputs, effects and failures. If a step changes any of these, it is not a refactoring step; stop and treat it as a behavior change.
9. Added judgment: if a refactoring reveals a bug, stop, record the bug, and fix it separately with its own test (`code-complete-debugging`).
10. Added judgment: do not change public names, signatures or serialized forms inside a refactoring unless the task says to; these are contracts with callers outside the diff.
11. Added judgment: stop when the justifying problem is resolved. A second problem is a second decision.

## Procedure

1. State the problem: hidden intent, duplicated knowledge or defect risk, with the file and the line.
2. Check the safety net: tests that cover the area, or analysis that lets you state the current behavior. If neither exists, add characterization tests or stop and report.
3. Plan the steps so each is small and independently testable. Separate any behavior change into its own later step.
4. Apply one step, run the tests, look at the diff. If red and the cause is not obvious, undo that step.
5. Repeat until the problem from step 1 is resolved. List anything else you noticed without doing it.
6. Describe the change as structure-only or behavior-changing so a reviewer knows what to check.

## Example

```python
# Problem (rule 1: duplicated knowledge): the cents conversion is written twice and the two copies must agree
def invoice_total_cents(total: float) -> int:
    return int(round(total * 100))

def refund_cents(refund: float) -> int:
    return int(round(refund * 100))

# Step 1, structure only (existing tests unchanged and green): one home for the rule
def to_cents(amount: float) -> int:
    return int(round(amount * 100))

def invoice_total_cents(total: float) -> int:
    return to_cents(total)

def refund_cents(refund: float) -> int:
    return to_cents(refund)

# Step 2, behavior change in its own diff, written test-first: round half up on the decimal value
def to_cents(amount: float) -> int:
    exact = Decimal(str(amount)) * 100
    return int(exact.quantize(Decimal(1), rounding=ROUND_HALF_UP))
```

Step 1 can be reviewed by confirming that nothing observable changed. Step 2 changes results for amounts on an exact half cent (`0.125` gave 12 before, because Python rounds halves to the even neighbor, and gives 13 now), so it carries its own failing test first and its own explanation.

## Anti-patterns

- **Mixed diff.** Rename, extract, fix and feature in one change. Detect: a reviewer cannot say which hunks may change behavior.
- **Refactor in the dark.** Restructuring untested, poorly understood code. Detect: no test or written description of current behavior.
- **Cleanup creep.** The change grows past its justification. Detect: hunks that do not relate to the stated problem.
- **Taste refactor.** Rewritten because it could be nicer. Detect: no hidden intent, duplication or defect risk can be named.
- **Silent behavior change.** A "refactoring" that alters an edge case. Detect: a test expectation edited during a structural step.
- **Abstraction without payoff.** A new layer that the reader must now learn. Detect: you cannot say what a maintainer can now ignore.

## Trade-offs and exceptions

- Mixing is acceptable when separating would make the diff harder to review (a rename that must travel with the code that uses the new name); the source says to separate "when that improves reviewability". Say so in the description.
- Preparatory refactoring before a feature is justified when the existing structure hides the place where the feature belongs; keep it small and finished before the feature step.
- If the area has no tests and the change is urgent, the source still asks for tests or analysis first; the smallest acceptable analysis is a written statement of current behavior you verified by reading and, where possible, running.
- Large restructurings belong to planning (`code-complete-plan`), not to an opportunistic cleanup.

## Verification

- [ ] The justifying problem (intent, duplication or defect risk) is named.
- [ ] Tests or a written behavior description existed before the first step.
- [ ] Structural and behavioral changes are separate and labelled.
- [ ] Every step ended green, or was undone.
- [ ] Every hunk traces to the stated problem; unrelated findings are listed, not fixed.

## Related

`code-complete-complexity-management` for symptoms; `code-complete-construction-process` for increments; `code-complete-fix` to resolve named findings; `code-complete-refactorer` to carry out the steps; `code-complete-increment-reviewer` to check the finished diff.

## Source

- `Quality, Collaboration, Debugging, and Refactoring`
- `Incremental Construction Rules`
- `Complexity Management Rules`: only the rules on duplication and on reducing what a maintainer must keep in mind.
- `Consistency Neglect`: only the entry on arbitrary naming and formatting changes.
