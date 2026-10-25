---
name: "legacy-code-rewrite-pressure"
description: "Use when a rewrite, wholesale replacement, large new architecture or module-wide cleanup is proposed, or renaming and formatting are offered instead of making the change safe. Picks the next smaller verified move; work order is `legacy-code-legacy-loop`, patch shape is `legacy-code-change-separation`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Rewrite pressure

Old code looks bad, so replacing it feels cheaper than understanding it. The source says to resist: gain test leverage, make the next change cheaper, and rewrite only when it is explicitly requested or clearly safer than continued change. This skill is the decision procedure for that moment. The order of ordinary work is `legacy-code-legacy-loop`; the shape of a patch that is already small is `legacy-code-change-separation`.

## When to use

- Someone says "this module is a mess, let's rewrite it" or "start fresh".
- A plan replaces a subsystem before anyone can state what the current one does.
- A large new architecture, framework or layering is proposed before a single seam exists.
- The offered fix is renaming, reformatting or reorganizing files while the real dependency knots stay.
- You catch yourself starting a cleanup of the whole module because the requested change is hard.

## Rules

1. **Do not rewrite by reflex.** [MUST NOT] Check: the proposal states the specific change that cannot be made safely without a rewrite.
2. **Prefer targeted extraction and improvement.** [SHOULD] Check: the alternative plan names the extraction, seam or sprout that makes today's change safe.
3. **Rewrite only when explicitly requested or clearly safer than continued change.** [MUST NOT] otherwise. Check: either the user asked in terms, or the memo (Procedure step 3) shows the evidence for "clearly safer".
4. **Do not begin with a rewrite unless explicitly required.** [MUST NOT] Check: the first deliverable in the plan is a test or a seam.
5. **Do not replace a subsystem before understanding the current behavior.** [MUST NOT] Check: a description of current behavior exists, from runs or tests, not from the code's appearance.
6. **Do not rebuild instead of gaining test leverage.** [MUST NOT] Check: the plan shows which tests would exist after the first step.
7. **Do not assume old behavior is irrelevant because the code looks bad.** [MUST NOT] Check: callers and consumers were searched for dependence on the behavior you would drop.
8. **Avoid huge dependency-breaking rewrites, wholesale replacement of old modules, and large new architectures before basic seams exist.** [SHOULD] The source lists these under "Preferred avoidance" in its code-generation rules, so this is a SHOULD even though a plain "avoid" elsewhere is a MUST NOT. Check: the first dependency break touches one dependency.
9. **Do not make cosmetic refactoring the whole job.** [MUST NOT] Renaming and formatting while leaving the real dependency knots intact, and "cleanup" that does not make the next change safer, are forbidden. Check: for each cleanup hunk you can say how it makes the next change safer.
10. **Reject big rewrites and heroic cleanup when a seam and a test would do.** [MUST] Check: the plan tried a seam and a test first, and says what stopped it, if anything.
11. **When uncertain, choose the smallest change that increases understanding, increases testability, breaks one hard dependency, preserves current behavior and makes the next change cheaper.** [MUST] Check: the chosen step meets all five, or the memo says which it gives up.
12. **When rewrite pressure appears, take the smallest sprout, wrap, seam, characterization or refactoring step that makes today's change safer.** [Compact checklist] Check: you can name that step in one line.
13. **Test the claim "clearly safer".** [Added judgment] Write down: what the old behavior is, what pins it, what the incremental path would cost, and what the rewrite would cost to verify. Check: the memo contains all four lines, with evidence.
14. **If a rewrite is requested, still pin before you replace.** [Added judgment] The old behavior is the specification of what consumers rely on; characterize it, put the new code behind a seam and switch in steps (`legacy-code-sprout-and-wrap`). Check: the pins can run against both old and new.

## Procedure

1. Name the pressure: rewrite, replacement, new architecture, module-wide cleanup or cosmetic-only.
2. Name today's actual request. Everything else is out of scope unless it makes that request safer.
3. Write the decision memo (Example). If "rewrite" survives rules 3 and 13, say so and go to rule 14; otherwise choose the step from rule 12.
4. Hand off: `/legacy-code:plan` for the plan, `/legacy-code:characterize` for the first pin, `/legacy-code:find-seam` for the first seam.
5. Report what you did not do and why.

## Example

A request to rewrite a billing module, answered with a decision memo.

```text
Request: "The invoicing module is unreadable. Rewrite it."
Today's change: invoices for EU customers must show VAT per line.
Pressure: rewrite (explicitly requested? no; clearly safer? unproven)

What current behavior is pinned: nothing; one smoke test checks that an invoice renders.
What the incremental path costs: pin the line-total behavior (about the slice VAT touches), inject the tax lookup, add VAT per line as a sprouted method.
What the rewrite costs to verify: every invoice shape the old code produced, none of which is written down.
Evidence for "clearly safer": none.

Decision: do not rewrite. Smallest step: characterize line totals through InvoiceRenderer.render, then break the static TaxTable dependency.
Not doing now: renaming the module, splitting it into services, a new template engine.
Revisit when: the pins exist and a second change is blocked by structure the seams cannot fix.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Rewrite by reflex | "Mess" is the whole argument | Ask for the blocked change |
| Replacement without knowledge | New module before any description of old behavior | Characterize first |
| Architecture before seams | New layers, no test | One seam, one test |
| Cosmetic sweep | Renames and reformatting across files, same dependency knots | Revert; take one dependency break |
| Heroic cleanup | A large patch done "while we're here" | Split to the smallest step |
| Old behavior waved away | "Nobody uses that" with no search | Search consumers |

## Trade-offs and exceptions

- A rewrite is allowed when explicitly requested or clearly safer than continued change, as the source says; this skill makes the claim testable, it does not forbid the rewrite.
- Added judgment: a throwaway or generated component with no consumers is not legacy code in this sense; replacing it does not need the memo.
- Cleanup is not forbidden; cosmetic-only cleanup that leaves the dependency knots is. Rename or reformat what you touch when it supports the safe change.
- "Smallest" is relative to the request: a small step that does not help today's change is not the smallest useful one.

## Verification

- [ ] The request that is actually being served is named.
- [ ] If a rewrite is proposed, the memo shows explicit request or evidence.
- [ ] The chosen step is a test, a seam, a sprout, a wrap or a local refactoring.
- [ ] Old behavior consumers were looked for.
- [ ] Each cleanup hunk is tied to the safety of the next change.
- [ ] What was deliberately not done is reported.

## Related

`legacy-code-legacy-loop` for the work that replaces the rewrite; `legacy-code-sprout-and-wrap` for adding beside; `legacy-code-change-separation` for patch shape; `legacy-code-change-intent-reviewer` to catch cosmetic-only or rewrite-first diffs; `/legacy-code:plan` to write the alternative.

## Source

- `Rewrite as the First Move`
- `Cosmetic Refactoring Only`
- `Non-Negotiable Rules`: only the rule not to rewrite by reflex.
- `Primary Directive`: only the rule not to begin with a rewrite unless explicitly required.
- `Code Generation Rules`: only the preferred avoidance of huge dependency-breaking rewrites, wholesale replacement and early large architectures.
- `Final Instruction`
- `Forbidden Patterns`: only the rewrite-first and cosmetic-refactoring patterns.
