---
name: patch-hygiene
description: "Use when shaping a diff, commit series or pull request that mixes renames, code motion, redesign and logic changes, or is too big to review. Packaging and intent per patch; whether behavior actually changed is behavior-preservation."
---

# Patch hygiene

How a change is cut for review: one intent per patch, structure apart from behavior, code motion apart from edits. This skill is about the diff and the commit series, not about whether behavior changed (`/refactoring:behavior-preservation`) or how big each edit step is while you work (`/refactoring:small-steps`). Turning an existing mixed diff into a sequence is `/refactoring:split-patch`.

## When to use

- A diff renames, moves, redesigns and changes logic in the same patch.
- Reviewers cannot tell which lines are mechanical and which are decisions.
- You are about to commit a feature together with cleanup of the code around it.
- A pull request description needs more than one sentence of intent.

## Rules

1. **Separate structural edits from behavior changes whenever practical.** A reviewer can approve a pure restructuring quickly and a behavior change carefully, but not both at once. Check: every patch is labelled structure or behavior, and no patch is both.
2. **Group related refactorings together.** A reader follows one theme at a time. Check: each patch has a one-sentence theme ("extract shipping calculation"), not a list.
3. **Avoid giant mixed commits that rename, move, redesign and change logic all at once (Avoid).** Check: no patch contains more than one of those four activities (Added judgment: the source rules out doing all four at once; one activity per patch is this plugin's stricter check).
4. **Prefer reviewable sequences of transformations.** Check: each patch in the series builds and passes tests by itself, and can be reviewed without reading the later ones.
5. **Do not mix feature work with huge unrelated renames (Do not).** The rename buries the feature. Check: a rename that touches files the feature does not touch is its own patch.
6. **Do not hide behavior changes inside cleanup.** Check: the cleanup patch changes no test expectation and no output.
7. **Do not let code motion make review impossible.** Check: a moved block appears in a patch that contains only the move.
8. **Added judgment: move first, edit second.** Move a function in one patch with no edits, and change it in the next, so the diff shows a pure move followed by a small edit. A viewer that detects moved lines (for example `git diff --color-moved`) makes the first patch quick to verify. Check: no hunk both relocates and rewrites a block.
9. **Keep test updates with the behavior they describe (compact checklist, following from the preserved-behavior rules).** Check: structural patches contain no changed expectations; the behavior patch contains the test change that explains it.
10. **Split a patch that mixes intents unless context makes that impractical (compact checklist).** When splitting is impractical, label the hunks in the description by intent. Check: either the patch is single-intent, or the description says which hunks are which.

## Procedure

1. Read the diff and tag each hunk: rename, move, extract or inline, behavior, test, formatting, unrelated.
2. Count the distinct intents. One intent: the patch is fine. More: propose an order, structure first and behavior last, preparation before the feature it enables.
3. Check each proposed patch for independence: does it build and pass alone? If not, merge the minimum hunks needed.
4. For each patch, write the one-sentence theme and whether it is structure or behavior.
5. If you are the author, apply the split (stage by hunk, or redo the work in order). If you are reviewing, ask for the split or label the hunks yourself.

## Example

```text
One patch as submitted (about 600 changed lines):
  - rename `proc` -> `settleInvoice` across 14 files
  - move invoice helpers from billing/util.ts to billing/settlement.ts
  - add a 30-day grace period to the late-fee rule (behavior)
  - update 3 test expectations

Series after splitting:
  1. rename proc -> settleInvoice                       structure, mechanical, tests unchanged
  2. move invoice helpers to billing/settlement.ts      structure, move only
  3. extract lateFee(invoice, today) from settleInvoice structure, tests unchanged
  4. add 30-day grace period to lateFee                 behavior, failing test first, 3 expectations updated here
```

Patches 1 to 3 can be approved by reading; only patch 4 needs a decision about the rule. Putting the failing test first in patch 4 is Added judgment; the source asks only that behavior stay apart from structure.

## Anti-patterns

- **Rename avalanche.** Detect: most of the changed files differ only by an identifier (the proportion is Added judgment). Treat: separate it and ship it first or last.
- **Cleanup-with-a-fix.** Detect: a "cleanup" patch with a changed condition or boundary. Treat: lift the fix into its own patch with a test.
- **Move-and-tweak.** Detect: a hunk where a block moves and several of its lines change. Treat: split into a move and an edit.
- **Test churn in a structural patch.** Detect: expectation edits next to structural changes. Treat: move the expectation edit to the behavior patch or revert it.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- The source says "whenever practical" and "where practical": a tiny rename next to the line a feature touches does not need its own commit.
- Some changes cannot be split without a red intermediate state; keep them together, label the hunks, and keep the patch small. (Added judgment)
- If the user or the repository prefers squash-merged pull requests, the series still matters inside the branch and in the description. (Added judgment)

## Verification

- [ ] Each patch states one intent and is labelled structure or behavior.
- [ ] Each patch builds and passes tests on its own.
- [ ] No patch both moves code and rewrites it.
- [ ] Test expectation changes appear only in the behavior patch.
- [ ] Any mixed patch has its hunks labelled in the description.

## Related

`/refactoring:split-patch` to produce the series; `refactoring:patch-intent-reviewer` to classify the hunks of an existing diff; `/refactoring:behavior-preservation` for the meaning of the change; `/output-style refactoring:two-hats` to label every edit while you work.

## Source

- `Commit and Patch Discipline`
- `Mixed-Intent Patches`
