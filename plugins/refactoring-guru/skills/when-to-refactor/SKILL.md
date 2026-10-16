---
name: when-to-refactor
description: "Use when deciding whether to refactor now or later: third occurrence of duplication, before or after a feature, during a bug fix or review, or when debt slows the current change. Not for how to do it (refactoring-process) or how to treat duplication (change-locality)."
---

# When to refactor

Owns the timing decision: which moments justify structural work, and how technical debt is prioritized. The way to perform the work is `/refactoring-guru:refactoring-process`; the treatment of duplicated logic is `/refactoring-guru:change-locality`.

## When to use

- You see a second or third copy of similar logic and have to decide whether to abstract.
- You are about to add a feature to code that is hard to read, or you have just added one and left clutter behind.
- A bug fix reveals hidden complexity or unclear ownership around the faulty line.
- You are reviewing a change and find a smell in it.
- Someone proposes a dedicated cleanup project, or argues that a shortcut is harmless.

## Rules

1. **Rule of Three: write the first occurrence directly, tolerate the second when the abstraction is uncertain, and consider refactoring at the third** (`MAY` / `SHOULD` / `MUST` consider). Check: you can list the three occurrences and say what they share.
2. **Do not abstract coincidental similarity before the repeated responsibility is clear** (`MUST NOT`). Two fragments that look alike but change for different reasons will force the abstraction to grow flags. Check: for each pair, name the single reason both would change; if there are two reasons, leave them separate.
3. **Refactor first when existing code is too dirty to understand the change safely** (`SHOULD`), and reshape the local structure so the feature becomes straightforward (`SHOULD`). Check: after the preparatory step, the feature diff is smaller or plainly local.
4. **Keep preparatory refactoring separate from the feature behavior** (`MUST`). Check: the preparatory commit or section passes the old tests unchanged.
5. **Use the feature as an opportunity to pay down the specific debt that blocks it** (`SHOULD`), not debt elsewhere. Check: every cleanup hunk is on the path of the feature.
6. **Fixing a bug: inspect the area around it for hidden complexity, duplication and unclear ownership** (`SHOULD`), and clean the structure that let the bug hide when the cleanup is small and local (`SHOULD`). Check: the cleanup is a few hunks, not a rewrite of the module.
7. **Preserve the bug fix as a behavior change separate from the supporting refactor** (`MUST`). Check: the fix is visible as its own change with its own test.
8. **Use code review as the last chance to catch smells before the code becomes public** (`SHOULD`). Fix simple smells immediately when review context and ownership allow it (`SHOULD`); estimate and isolate larger smells instead of smuggling them into the reviewed change (`SHOULD`); collaborate with the author when a smell needs judgment about intent (`SHOULD`). Check: findings are sorted into fix now, isolate and schedule, and ask the author.
9. **Treat technical debt as a cost that compounds by slowing future development.** Do not justify patches, kludges, missing tests or unclear structure as harmless when they make later changes slower or riskier (`MUST NOT`). Check: for each shortcut you can name the future change it makes slower.
10. **Expose where debt comes from** (`SHOULD`): business pressure, missing tests, weak modularity, delayed refactoring, poor documentation, isolated branches, or inconsistent standards. Check: each debt item in a report has a named source.
11. **Prioritize debt that affects current change speed, correctness or team understanding** (`MUST`), and reduce debt incrementally through ordinary feature and bug work (`SHOULD`). Check: the item you chose is in the path of the change at hand.
12. **Do not delay all refactoring to a future cleanup project unless the current change cannot safely absorb it** (`MUST NOT`). Check: if you defer, the reason is that the change cannot safely absorb the work, and the deferral is recorded.

## Procedure

1. Name the moment: third occurrence, before a feature, after a feature, bug fix, review, or debt discussion.
2. For repeated logic, run rules 1 and 2 first and stop if the answer is "not yet".
3. For a feature or bug, look at the code the change will touch and list what blocks it. Only blockers justify preparatory work.
4. Decide order (before, after, separate) and write it in the plan or the pull request description.
5. For review findings, sort into fix now, isolate and schedule, and ask the author. Do not widen the reviewed change.
6. Record deferred items with the reason; hand them to `/refactoring-guru:debt-triage` when there are several.

## Example

Three report formatters repeat the same money formatting. The decision is made at the third.

```ts
type Line = { sku: string; cents: number; currency: string };

// Second occurrence appears: tolerate it. The format may differ per channel.
const invoice = (l: Line) => `${l.sku}: ${(l.cents / 100).toFixed(2)} ${l.currency}`;
const receipt = (l: Line) => `${(l.cents / 100).toFixed(2)} ${l.currency} - ${l.sku}`;

// Third occurrence appears: all three change when the currency display changes.
const email = (l: Line) => `Total ${(l.cents / 100).toFixed(2)} ${l.currency}`;

// Refactor: the shared responsibility is "show an amount"; the surrounding text stays separate.
function formatMoney(cents: number, currency: string): string {
  return `${(cents / 100).toFixed(2)} ${currency}`;
}
const invoice2 = (l: Line) => `${l.sku}: ${formatMoney(l.cents, l.currency)}`;
```

Not extracted: the three surrounding sentences. They have different owners (billing, support, marketing) and change for different reasons, which is the coincidental part.

## Anti-patterns

- **Abstract on sight.** A helper created at the first duplicate. Detect: a shared function with one caller, or with flags added within a week.
- **Tidy while passing.** Unrelated cleanup in a feature diff. Detect: hunks in files the feature does not need.
- **Review smuggling.** A large refactoring pushed into a small reviewed change. Detect: the review diff is mostly moves.
- **The cleanup project.** All structural work postponed to an unscheduled future. Detect: a TODO backlog of smells that already block current features.
- **"It works" as a defense.** Detect: a debt item is justified only by "nobody has complained".

## Trade-offs and exceptions

- The Rule of Three is a default, not a law: the source lets the first occurrence be written directly and the second be tolerated, and says to consider, not to mandate, refactoring at the third. If the repeated responsibility is already clear and the copies are identical, extracting at the second is allowed by judgment (Added judgment).
- When the change cannot safely absorb a needed refactoring (no tests, release freeze), defer it explicitly and record why.
- Review context matters: fix simple smells yourself only when you own the code.

## Verification

- [ ] The moment that triggered the refactoring is named.
- [ ] Repeated logic was checked for a single reason to change before abstracting.
- [ ] Preparatory refactoring and the feature or fix are separate changes.
- [ ] Debt items have a source and an effect on change speed, correctness or understanding.
- [ ] Anything deferred has a recorded reason.

## Related

`/refactoring-guru:change-locality` for treating duplication; `/refactoring-guru:debt-triage` to rank several debt items; `/refactoring-guru:plan` to order refactoring around a feature; `/refactoring-guru:refactoring-process` to carry it out.

## Source

- `When to Refactor`
- `Rule of Three`
- `While Adding a Feature`
- `While Fixing a Bug`
- `During Code Review`
- `Technical Debt Rules`
