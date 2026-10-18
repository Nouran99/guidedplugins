---
name: "code-complete-construction-process"
description: "Use before a non-trivial change: work starting from a proposed solution, unsettled decisions, or slicing into verifiable increments with early integration. Written plan: code-complete-plan. One routine: code-complete-routine-design."
license: "MIT"
metadata:
  plugin: "code-complete"
  book: "Code Complete"
  invocation: "auto"
---

# Construction process

Decides what must be clear before large implementation work starts, how to proceed when it is not, and how to cut the work into increments that stay verifiable and integrated. The plan artifact is produced by `code-complete-plan`; reviewing the shape of a finished diff is `code-complete-increment-reviewer`.

## When to use

- The request arrives as a solution ("add a cache here", "use a queue") and the requirement behind it is not written down.
- Error policy, data representation, reuse, integration or testing approach is undecided and the change is more than a few routines.
- A change will take several steps and you need to choose the order, or a branch has been diverging for a while.
- An early decision (public API shape, stored format, error contract) will be expensive to reverse.

## Rules

1. **Do not treat construction as isolated typing.** Verify that requirements, architecture, major risks and coding conventions are clear enough for this change. Check: you can state in two sentences what must be true when the change is done and which module owns it.
2. **Compact rule: when coding starts from a proposed solution, restate the requirement, architecture fit, risks, conventions and success constraints first.** Check: the restatement names a requirement that is not just the solution reworded.
3. **Resolve major construction decisions before large implementation work:** language constraints, error policy, data representation, reuse strategy, integration approach and testing approach. Check: each has an answer, or an explicit "follows the convention in <file>".
4. **Use upstream uncertainty as a reason to build a small validated slice, not as an excuse for speculative code.** Check: the slice runs through real code paths and has a test; nothing generic was added "for later".
5. **Keep the software metaphor or design model only if it helps make concrete construction decisions.** Check: the model has already produced a decision (a name, a boundary, a data shape); if it only supplies vocabulary, drop it.
6. **Measure twice before cutting when an early decision will be expensive to reverse.** Check: for each such decision the alternatives and the reason for the choice are written down. Added judgment: two alternatives in writing is a workable minimum.
7. **Build in small, verifiable increments.** Check: after each increment the build and the relevant tests pass and the system still does what it did.
8. **Integrate frequently enough to surface conflicts and misunderstanding early.** Check: nothing you depend on, or that depends on you, has been left diverged long enough to make merging a project of its own.
9. **Keep partial work from rotting in long-lived isolation.** Check: no unfinished branch, stash or local work has gone long without integrating or being rebased on the shared line (the source gives no interval; match the team's practice). Added judgment: unfinished work may be integrated early behind a clearly named switch that something reads; what to avoid is code that is neither reachable through such a switch nor owned by anyone.
10. **Review and improve code as part of construction, not only after it.** Check: you re-read your own diff and fix what you find before starting the next increment.
11. **Optimize for the option that lowers defect probability when uncertain.** The tie-breaker order is in `code-complete-principles`. Check: when you chose between two designs, you can say which of the five criteria decided it.
12. Added judgment: when a prerequisite cannot be settled now, write the assumption in the plan or the pull request description and choose the smallest slice that would show the assumption is wrong.

## Procedure

1. Restate the requirement in your words, then the solution that was proposed, as two separate items.
2. Walk the six decisions (language constraints, error policy, data representation, reuse, integration, testing). Mark each settled, inherited from the codebase, or open.
3. For each open decision that is cheap to reverse, pick the simplest option and note it. For each that is expensive to reverse, compare alternatives (rule 6).
4. If uncertainty remains about whether the approach works, define the smallest end-to-end slice that would settle it, and build only that first.
5. Order the remaining work as increments, each ending in a runnable, tested state. Name the integration point for each.
6. After each increment, run the tests, re-read the diff and integrate before starting the next.

## Example

A request: "add a Redis cache in front of the price lookup".

```text
Requirement (restated): price lookups for the catalogue page must stay under 150 ms at peak;
  today p95 is unknown. The cache is a proposed solution, not the requirement.
Open decisions:
  error policy      -> cache failure must not fail the page: fall back to the database lookup
  data representation -> cache key is sku + currency; value is integer cents (matches Price.cents)
  testing approach  -> unit tests with a fake cache; one test where the cache throws
  reuse             -> PriceRepository already exists; wrap it, do not edit its callers
Expensive to reverse: the cache key format (shared with another service) -> compared two forms, chose sku:currency
Slice 1: measure current p95 on the catalogue endpoint (settles whether a cache is needed)
Increment 2: CachedPriceRepository with fake cache, fallback test, behind a config switch
Increment 3: real cache client, wired through the switch, integrated to main after tests pass
```

## Anti-patterns

- **Solution-first coding.** The proposed fix is built without restating the requirement. Detect: the plan or pull request description names the technology but no measurable need.
- **Speculative generality.** Hooks and options added "in case". Detect: parameters or classes with no caller in the change.
- **Big-bang integration.** One large step at the end. Detect: a diff that cannot be reviewed in one sitting, or a branch with no merge for a long time.
- **Rotting partial work.** A branch or work item that has diverged for long and keeps drifting from the shared line. Detect: a branch with no merge or rebase for a long stretch, a half-done migration that exists only in someone's working copy.
- **Orphaned partial code (Added judgment).** Unfinished code that was integrated with no switch, no caller and no owner. Detect: code paths that nothing calls, flags that nothing reads, `TODO: finish` without an owner. Work integrated behind a named switch that is read is not this.
- **Metaphor worship.** A design analogy defended after it stopped producing decisions. Detect: the analogy appears in names but changes no behavior.

## Trade-offs and exceptions

- For a small, local change the whole procedure is one sentence per step; do not write a document.
- The source asks for a small validated slice under uncertainty instead of speculative code. Added judgment: keep the slice in the codebase with a test, so it is neither a throw-away prototype nor a separate design phase.
- Integration frequency is a strong default, not a number: the source gives no interval, so match the team's practice.
- Expensive-to-reverse decisions justify more deliberation; cheap ones do not.

## Verification

- [ ] The requirement is stated separately from the proposed solution.
- [ ] Each of the six decisions is settled, inherited or listed as open with an owner.
- [ ] Any remaining uncertainty is covered by a small slice, not by speculative code.
- [ ] Every increment ends in a runnable, tested state.
- [ ] No unfinished branch or local work has gone long without integrating.
- [ ] Any unfinished code already on the shared line sits behind a named switch that is read, or has a note and an owner.

## Related

`code-complete-plan` for the written plan; `code-complete-pseudocode` for one complex routine; `code-complete-increment-reviewer` to review the shape of the finished diff; `code-complete-refactoring-judgment` when the increment is a refactor.

## Source

- `Construction Prerequisites and Decisions`
- `Incremental Construction Rules`
- `Primary Directive`: only the tie-breaker order.
- `Performance, Integration, Tools, and Craftsmanship`: only the rule to integrate frequently.
