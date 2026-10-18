---
name: "change-separation"
description: "Use when shaping a legacy patch or reviewing its shape: keep behavior change, structural refactoring and cleanup apart, stay at the change point, take one small dependency break. Order of work is `$legacy-code:legacy-loop`; whether to rewrite at all is `$legacy-code:rewrite-pressure`."
---

# Change separation

A legacy patch is safe to review and safe to revert when each step has one intent. This skill sorts a patch into behavior change, dependency break, structural refactoring, cleanup and tests, and keeps them apart where practical. The sequence of work before the patch exists is `$legacy-code:legacy-loop`; the decision to go big instead is `$legacy-code:rewrite-pressure`; splitting a patch that is already mixed is `$legacy-code:split-patch`.

## When to use

- You are about to write several kinds of edit in one go (a rename, an extraction and a rule change).
- You are reviewing a diff in a module nobody understands and it touches many places.
- A patch adds a seam and changes behavior in the same hunk.
- Someone proposes checking in the restructuring you did to understand the code.

## Rules

1. **Keep behavior changes, structural refactorings and cleanup separate, where practical.** [MUST] The qualifier is part of the rule. Check: each step has one primary intent, or the report says why two could not be separated.
2. **Work near the change point, not across the whole system.** [MUST] Check: every edit is within the change point or within a direct neighbor that the change needs.
3. **Prefer one small dependency break over a broad redesign.** [SHOULD] Check: the patch breaks the one dependency that blocks the test.
4. **Treat a broad edit in a poorly understood module as a legacy-change risk, and do not make large edits with no characterization.** [MUST NOT] The prohibition comes from the no-safety-change pattern in `Forbidden Patterns`; the broad-edit half is a review-detection item in `Review Rules`, not a separate ban. Check: the diff does not touch files outside the area you could describe and test, and any large edit has pins first.
5. **Do not start by cleaning the whole module.** [MUST NOT] Check: no cleanup precedes the pins.
6. **Keep edits local to the requested change.** [MUST] Check: a reviewer can map every hunk to the request or to the safety of the request.
7. **Do not check in exploratory restructuring that was only used to learn.** [MUST NOT] Check: no hunk exists only because you were reading the code.
8. **Do not expand hidden dependencies.** [MUST NOT] Adding more globals, statics, ambient context or framework reach-through in already hard-to-test code is forbidden. Check: the diff adds none.
9. **Verify small steps.** [Compact checklist] Check: tests ran after each step, not only at the end.
10. **When repeated edits cluster across several places, remove duplication incrementally under tests instead of launching a broad redesign.** [Compact checklist] Check: each duplicate removed has a test, and the removals are separate steps.
11. **Order the steps: pins, dependency breaks, behavior change, then cleanup.** [Added judgment] The pins make the breaks safe, the breaks make the behavior change testable, and cleanup comes last because it is the first thing to drop under time pressure. When a barrier stops every pin, the first break is the enabling step: it comes before the pins and is kept conservative (signature kept, old behavior as the default). Check: the order holds in the commit plan.
12. **Label every hunk with one intent: behavior, dependency break, structure, cleanup or test.** [Added judgment] A hunk with two labels needs splitting or a justification. Check: you can produce the ledger (Example).
13. **A dependency break changes no behavior; a behavior change adds no structure.** [Added judgment] Check: after a dependency break, all previous tests pass unchanged; a behavior change touches only the code it needs.

## Procedure

1. Write the request in one sentence. Everything in the diff must serve it or serve its safety.
2. Walk the diff hunk by hunk and label each (rule 12). Mark the scope: required, enabling or out of scope.
3. List mixed hunks. For each, decide if it can be split; if not, write why.
4. Propose the order (rule 11). `$legacy-code:split-patch` produces it for a whole patch.
5. Run the tests after each step on the way to the final state.
6. Report out-of-scope hunks as "noticed, not changed" or remove them.

## Example

A patch that fixes a late-fee rule, shown as a hunk ledger before and after separation.

```text
Request: late fees must stop compounding after 90 days

Before (one commit)
 1 billing/fees.py:12     rename  calcFee -> late_fee_cents                       structure
 2 billing/fees.py:20-31  inject  `today` parameter instead of date.today()        dependency break
 3 billing/fees.py:33     change  stop compounding after 90 days                     behavior
 4 billing/*.py           reformat  all files in the directory                        cleanup  (out of scope)
 5 tests/test_fees.py     new test for the cap                                       test
 Verdict: one patch carries four intents; hunk 4 touches files the request never mentioned.

After (four steps)
 Step 1  dependency      inject `today` (hunk 2), old call as the default; the clock read blocked every pin   no behavior change
 Step 2  pins            characterize late_fee_cents behavior before the cap, with a fixed `today`            test only, passes on old logic
 Step 3  behavior        stop compounding after 90 days (hunk 3) with its test (hunk 5)                       the only red to green
 Step 4  structure       rename (hunk 1), if still wanted
 Dropped hunk 4          reported as noticed, not changed
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Mixed-intent commit | A rename, an injection and a rule change in one hunk | Split by label |
| Drive-by reformat | Formatting hunks in files outside the change point | Drop; report |
| Learning commit | Restructuring whose only purpose was reading | Discard; keep notes |
| Seam plus behavior | A new seam and a new rule in the same step | Seam first, green, then the rule |
| Broad edit, thin understanding | Many files touched in a module with no tests | Narrow to the change point |
| Hidden growth | New singleton or static reach in new code | Receive it as a parameter |

## Trade-offs and exceptions

- Separation is "where practical": sometimes a rename and the extraction it clarifies cannot be separated without a broken intermediate state. Say so.
- Added judgment: a hunk that is a mechanical consequence of another (a call site updated after a signature change) belongs to the same step as its cause.
- Cleanup inside the touched lines is allowed when it supports the safe change; the prohibition is on sweeping cleanup and on cosmetic-only work.
- Separate steps do not require separate commits unless the repository's conventions ask for them; this plugin never commits for you.

## Verification

- [ ] Each hunk has one intent label.
- [ ] Pins come before dependency breaks, breaks before behavior, cleanup last.
- [ ] No hunk is outside the change point without a reason.
- [ ] No exploratory restructuring is in the diff.
- [ ] No hidden dependency was added.
- [ ] Tests ran after each step.

## Related

`legacy-code-change-intent-reviewer` to produce the ledger for a diff; `$legacy-code:split-patch` to turn a mixed patch into ordered steps; `$legacy-code:legacy-loop` for the earlier order; `$legacy-code:rewrite-pressure` for scale; `$legacy-code:scratch-refactoring` for learning edits that must not ship.

## Source

- `Review Rules`
- `Legacy Refactoring Heuristics`: only the heuristics on working near the change point and on preferring one small dependency break.
- `Review Checklist`: only the items on local edits and on separating structural from behavior changes.
- `Hidden Dependency Expansion`
- `Forbidden Patterns`
- `Test Selection and Understanding Rules`: only the rule not to check in exploratory restructuring.
