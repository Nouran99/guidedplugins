---
name: "refactoring-process"
description: "Use when carrying out a refactoring: keeping it separate from feature or bug-fix edits, working in small steps, choosing and running checks, and judging whether the code got cleaner. Not for deciding whether to refactor now (when-to-refactor)."
---

# Refactoring process

Owns the shape of the work once a refactoring has been decided: separation from behavior changes, step size, verification, and the test that it was worth doing. Timing and triggers belong to `$refactoring-guru:when-to-refactor`; stopping and deferring belong to `$refactoring-guru:stop-and-defer`.

## When to use

- You are about to edit existing code for structure and have not yet written down what stays the same.
- A diff mixes renames or moves with a new rule, a changed default or a bug fix.
- A refactoring broke a test and you must decide whether the code or the test is wrong.
- You are asked whether a refactoring "really improved" the touched area.

## Rules

1. **Give every refactoring four things: a specific smell or cost, a bounded transformation, a verification path, and no hidden feature change** (`MUST`). A cleanup without a named smell has no stop condition. Check: you can say the smell, the transformation and the check in one sentence each before editing.
2. **Do not mix feature development and refactoring in one indistinguishable edit** (`MUST NOT`). Reviewers cannot tell structural noise from new behavior. Check: every hunk can be labeled refactor or behavior without argument; prefer separate commits, patch sections or clearly labeled steps (`SHOULD`).
3. **Preserve existing behavior during refactoring** (`MUST`), and call any behavior change feature work or bug fixing, never refactoring (`MUST`). Check: inputs, outputs, side effects, error cases and ordering are unchanged for the touched code, or the difference is named and isolated.
4. **Refactor before feature work when dirty code blocks understanding or makes the feature awkward; refactor after when the feature leaves duplication, awkward names or unneeded structure** (both `SHOULD`). Check: the order you chose is stated in the plan, and the preparatory part is kept separate from the feature behavior.
5. **Apply refactoring as a sequence of small changes** (`MUST`), keeping the program in working order after each meaningful step when practical (`MUST`). Prefer several named transformations over one broad rewrite (`SHOULD`). Check: each step has a name from the catalog and can be reverted alone.
6. **Stop and reduce scope when a refactoring becomes too large to reason about locally** (`MUST`), and never use refactoring as cover for uncontrolled redesign (`MUST NOT`). Check: you can explain the current step without referring to the end state.
7. **Identify the relevant test or check before a risky refactoring** (`MUST`) and run all relevant existing tests after it (`MUST`); run tests after each risky structural change (`SHOULD`). Check: the command, and the result before and after, appear in your report. The source accepts tests, characterization checks, type checks or repeatable manual checks. Added judgment: when none exists, say so and consider `refactoring-guru-characterizer` before moving code.
8. **When a test fails, decide whether the refactoring changed behavior or the test was coupled to implementation details** (`MUST`), and fix refactoring mistakes before continuing (`MUST`). Check: you can state which of the two it was, with the line that shows it.
9. **Replace or lift brittle low-level tests that block a behavior-preserving structural change** (`SHOULD`), but never delete a failing test to make a refactoring look successful (`MUST NOT`). Check: the behavior the test protected is still protected, at a higher level if necessary.
10. **A refactoring succeeds only if the touched area is cleaner** (`MUST`): do not perform one that leaves the code just as unclear, duplicated or bloated (`MUST NOT`). When a chain of small edits does not improve clarity, pause and re-diagnose (`SHOULD`). Check: name what is now simpler, in the vocabulary of the smell you started with.
11. **Treat clean code as the target** (definition from the purpose of the rule set): obvious to other programmers, free of duplicated knowledge and control flow, with a minimal number of moving parts, passing the relevant tests, and cheaper to maintain than what it replaced. Check: you can argue each of the five for the touched area.
12. **Consider a planned rewrite only when the code is extremely sloppy, tests exist or are added first, and enough time is explicitly allocated** (`SHOULD` consider). A rewrite without those three is uncontrolled redesign. Check: all three conditions are written down; otherwise continue with small steps.

## Procedure

1. State the goal in one line and whether it is refactoring, a feature or a bug fix. If it is more than one, plan one step per kind.
2. Name the smell, its cost and the smallest technique (see `$refactoring-guru:treatment-choice`).
3. Find the check: tests that cover the touched code, type checks, or a manual check you can repeat. Record the baseline result.
4. Perform one named step. Run the check. Look at the diff for anything that is not the named step.
5. If the check fails: decide behavior change versus coupled test (rule 8) and fix before the next step.
6. Repeat until the stop condition holds, then review the whole diff once for hidden behavior changes.
7. Report: technique used, stop condition reached, validation performed, and any behavior change as a separate item.

## Example

A pull request "tidy the bulk discount" changes the code below. Splitting it shows what is refactoring and what is behavior.

```python
# Original
def price(items):
    t = sum(i.price * i.qty for i in items)
    if t > 100:
        t = t * 0.9
    return t

# Step 1 [refactor, behavior unchanged, tests unchanged and green]
BULK_THRESHOLD = 100
BULK_RATE = 0.9

def subtotal(items):
    return sum(i.price * i.qty for i in items)

def price(items):
    total = subtotal(items)
    if total > BULK_THRESHOLD:
        total = total * BULK_RATE
    return total

# Step 2 [behavior change, its own commit and test]
#   if total >= BULK_THRESHOLD:       # exactly 100 now gets the discount
#   new test: a basket worth exactly 100 pays 90
```

Step 1 carries the names and the extraction; a reviewer can accept it by reading, because no input changes its result. Step 2 is one visible line plus one new test.

## Anti-patterns

- **The cleanup pass.** Edits with no named smell. Detect: the description says "tidy", "clean up" or "modernize" and no smell is named.
- **The disguised feature.** A changed default, threshold or error message inside a rename or move. Detect: a hunk changes a literal or a branch condition inside a "refactor" commit.
- **The big bang.** Dozens of files changed before the first test run. Detect: no intermediate state compiles or passes.
- **The convenient deletion.** A failing test removed or loosened during a structure change. Detect: assertions or test files disappear in the diff.
- **The treadmill.** Many small edits that never make anything simpler. Detect: the final diff is no easier to read than the starting code.

## Trade-offs and exceptions

- "Keep the program working after each step" is stated as "when practical": a move across many call sites may need a short intermediate state. Keep it as short as possible and say so in the report.
- Separation may be a commit, a patch section or a labeled step; a single commit with explicitly labeled steps satisfies the source when the repository does not split commits.
- Rewrites are permitted only under the three conditions in rule 12.
- Added judgment: for a very small change (a rename in one private function) the baseline run can be the nearest test file rather than the full suite.

## Verification

- [ ] The change is labeled refactoring, feature or bug fix, and no hunk is ambiguous.
- [ ] The check was identified before the first edit and run after the last.
- [ ] No test was deleted, skipped or weakened.
- [ ] The touched area is cleaner by a stated criterion.
- [ ] Any behavior change is reported separately from the structural steps.

## Related

`$refactoring-guru:when-to-refactor` for timing; `$refactoring-guru:stop-and-defer` for stopping; `$refactoring-guru:classify-change` to split a mixed patch; `refactoring-guru-intent-reviewer` and `refactoring-guru-safety-net-reviewer` to review the result; `$refactoring-guru:fix` to act on findings.

## Source

- `Primary Directive`
- `Refactoring Process`
- `Keep Refactoring Separate`
- `Work in Small Steps`
- `Verify Continuously`
- `Keep the Result Cleaner`
- `Purpose`: only the definition of clean code.
