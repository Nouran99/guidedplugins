---
name: "refactoring-stopping-rules"
description: "Use when deciding whether to keep cleaning: the change is already easy, the smell is gone, the next abstraction is speculative, or cleanup looks like theater. When to stop, not how to proceed (small-steps); removing existing layers is needless-abstraction."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "auto"
---

# Stopping rules

Refactoring has an end. This skill supplies the end conditions and the test for refactoring theater (motion that looks like design work and changes nothing about how hard the next change is). Removing weight that already exists is `refactoring-needless-abstraction`; how to proceed step by step is `refactoring-small-steps`.

## When to use

- The requested change is now easy and you feel like continuing.
- You are about to introduce a pattern, an interface or a new layer "since we are here".
- A cleanup has produced more files than it removed problems.
- You are asked whether a refactoring was worth it.

## Rules

1. **Stop when the requested change is easy to implement.** That was the purpose of the preparation. Check: you can state the change in a few lines of code.
2. **Stop when the main smells blocking the change are removed.** Check: the smell you named at the start is gone, not merely rearranged.
3. **Stop when further cleanup would become speculative.** Check: the next step requires imagining a future requirement.
4. **Stop when the next abstraction is not yet justified.** Check: you cannot name a second real need for it today.
5. **Stop when readability and local changeability are clearly improved.** Check: a reader new to the code would find the touched path easier than before.
6. **Use the simplest helpful refactoring; do not introduce patterns or abstractions earlier than needed.** Prefer local simplification before large-scale abstraction. Check: the final design contains no concept that the current change does not use.
7. **Remove at least one real source of friction.** A refactoring with no friction removed was motion. Check: you can name the friction and show it is gone (a change that is now one edit instead of several, a function that now reads straight through).
8. **Do not do refactoring theater (Do not).** That is renaming while deeper design problems remain untouched, introducing patterns instead of removing complexity, and adding files, layers or wrappers without improving changeability. Check: file and layer counts did not grow without a named benefit.
9. **Added judgment: name the friction before you start and test it again at the end.** Write one line: "this change is hard because ...". At the stop check, re-read it. Check: the line is in your notes and the answer is yes or no, not "somewhat".
10. **Added judgment: record what remains instead of doing it.** Remaining smells go on a "noticed, not changed" list with a location. Check: the list exists and the diff does not contain items from it.

## Procedure

1. At the start, write the requested change and the friction that makes it hard.
2. After each structural step, ask the five questions of rules 1 to 5. If any answer is yes, stop.
3. If you are about to add something new (type, interface, module), apply rule 4: name the second need or skip it.
4. At the end, compare with the friction line (rule 9) and list leftovers (rule 10).
5. If cleanup was still happening after the change became easy, revert the surplus steps or move them to a separate, optional patch.

## Example

```ts
// Requested change: refunds are allowed within 30 days of payment.
// Friction: the window check is repeated in two functions.

// After extracting one predicate the friction is gone and the change is one line:
function isWithinRefundWindow(order: Order, today: Date): boolean {
  return daysBetween(order.paidOn, today) <= 30;
}

// Temptation: introduce RefundPolicy (interface), DefaultRefundPolicy, RefundPolicyFactory
// and inject it everywhere "for future markets".
// Stop here. There is one policy and no second market is requested.
// Leftover note: refunds.ts still uses `any` for the audit payload -> noticed, not changed.
```

The stop is justified by rule 4 (no second real need) and rule 1 (the change is now easy); the leftover is recorded, not fixed.

## Anti-patterns

- **Momentum cleanup.** Detect: steps continue after the friction line is resolved. Treat: stop and list the rest.
- **Pattern insertion.** Detect: a named design pattern appears with a single implementation. Treat: inline it, or justify the second need.
- **Rename-only refactoring.** Detect: a diff that is almost entirely identifier changes while the tangled function remains. Treat: name the deeper problem; either address it or say it was left.
- **Layer growth.** Detect: more files and wrappers than before with no shorter change path. Treat: collapse the layers that do not shorten it.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- Stopping is not the same as leaving the code bad: the rule is to stop when the next step is speculative, and the preceding rules still demand removing the friction you came for.
- If the user explicitly asks for a broader cleanup, that request is its own task with its own friction statement; apply these rules inside it. (Added judgment)
- The source's "clearly improved" is a judgment; when two reasonable reviewers might disagree, prefer stopping and listing. (Added judgment)

## Verification

- [ ] The friction was named at the start and is gone now.
- [ ] You can name no second real need for any abstraction you added.
- [ ] No new file, layer or wrapper exists without a named benefit.
- [ ] The diff contains nothing from the "noticed, not changed" list.
- [ ] The requested change is now easy, or the plan says what remains.

## Related

`refactoring-needless-abstraction` to remove existing weight; `refactoring-friction-reviewer` to judge a finished change against its friction; `/refactoring:checklist` for the full final questions; `/refactoring:mode-prep-first` for a session that ends every task with a stop reason.

## Source

- `Stopping Rules`
- `Refactoring Theater`
- `Non-Negotiable Rules`: only the rule to use the simplest helpful refactoring.
- `Review Checklist`: only the questions on friction and speculative abstraction.
