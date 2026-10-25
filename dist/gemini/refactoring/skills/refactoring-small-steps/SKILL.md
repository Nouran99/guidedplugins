---
name: "refactoring-small-steps"
description: "Use when planning or doing a structural change and tempted to rewrite or change a lot at once: step size, reversibility, runnable states, order of work. Not meaning (behavior-preservation), when to stop (stopping-rules) or the moment before a feature (preparatory-steps)."
license: "MIT"
metadata:
  plugin: "refactoring"
  book: "Refactoring"
  invocation: "auto"
---

# Small steps

The general discipline of movement: many small, reversible, buildable edits instead of one big transformation, in a fixed default order, with a brake for the rewrite urge. The one moment right before a feature is `refactoring-preparatory-steps`; deciding when to stop is `refactoring-stopping-rules`; deciding whether a step preserved meaning is `refactoring-behavior-preservation`.

## When to use

- You are about to change several files, or a signature used in many places.
- The code is ugly and replacing it wholesale looks faster than reshaping it.
- A step failed and you do not know which edit did it.
- You need an order for a multi-part structural task.

## Rules

1. **Prefer many small safe edits over one large transformation (Prefer).** A small edit that fails points at its own cause. Check: after every edit the project builds and the covering tests pass.
2. **Make each step understandable and reversible.** If you cannot describe it in one line or undo it by hand, it is too big. Check: write the one-line description before you edit.
3. **If a patch is too large to reason about locally, split it (MUST).** Reasoning that spans many files at once is where behavior slips. Check: you can explain every hunk without reading the others.
4. **Keep the system running.** Do not leave code in a broken intermediate state unless a draft was explicitly requested; keep a runnable, buildable state where practical. Check: build and tests run between steps.
5. **Follow the default order when changing existing code.** Understand current behavior; find the friction for the requested change; add or improve the safety net if needed; do the preparatory refactoring; make the behavior change; do follow-up cleanup; stop when the design is clearly better. Check: you can name which of the seven you are in.
6. **Prefer these first moves.** Rename badly named things; extract coherent functions; isolate side effects; split mixed responsibilities; move behavior closer to its owner; remove duplication; simplify conditionals. Check: the first edit in a messy file is one of these, not a redesign.
7. **Prefer to avoid** unnecessary framework migrations, gratuitous API redesign, large hierarchy introduction, and replacing old code wholesale because it is ugly. Check: none of these appears in the plan unless the user asked.
8. **Do not generate or keep a big-bang rewrite unless explicitly required and justified.** That means replacing a working subsystem wholesale to clean it up, rewriting before understanding current behavior, or changing structure and behavior in one giant move. Check: the plan never contains a step called "rewrite X".
9. **When uncertain, or tempted to rewrite, choose the next small behavior-preserving transformation** that recovers control. Check: the next step you name fits in one line and one test run.
10. **Added judgment: when a change cannot be made in one buildable step, put the new form beside the old.** Add the new function or signature, make the old delegate to it, migrate callers in batches, delete the old one last. Check: every intermediate commit builds and passes.

## Procedure

1. Run the covering tests and record the baseline. A failing baseline is reported, not hidden.
2. Write the plan as numbered one-line steps. Mark which steps are structural and which one is the behavior change.
3. Do one step. Run the tests. Look at the diff. Only then start the next.
4. If a test fails and the cause is not obvious, revert that one step by hand and re-slice it smaller. Do not stack edits on a red state.
5. Stop at the stated end of the plan; list anything noticed but not done.

## Example

```go
// Step 0: callers everywhere use positional strings
func SendEmail(to, subject, body string) error { /* ... */ return nil }

// Step 1 (tests green, nothing else changed): new form beside the old; the old delegates
type Message struct{ To, Subject, Body string }

func Send(m Message) error { /* the moved body */ return nil }

func SendEmail(to, subject, body string) error {
	return Send(Message{To: to, Subject: subject, Body: body})
}

// Steps 2..n: migrate callers one package per step, tests after each.
// Last step: delete SendEmail when no caller remains.
```

Each step is buildable and reversible, and no step changes what an email contains.

## Anti-patterns

- **Hundred-file step.** Detect: hundreds of changed lines between two test runs. Treat: re-slice by package or by caller.
- **Red-state stacking.** Detect: edits piled on a failing build. Treat: revert the last step by hand.
- **Rewrite by renaming.** Detect: a new module that duplicates an old one "temporarily" with no deletion step. Treat: add the deletion step to the plan or do not start.
- **Ceremony plan.** Detect: ten steps for a two-line change. Treat: do it as one step; steps exist to localize failures.

## Trade-offs and exceptions

- "Where practical" is the source's own hedge for runnable intermediate states: some framework-level changes cannot be done in a green state. Say so in the plan and keep the red window as short as possible.
- A rewrite can be the right decision; it is the user's decision to make explicitly, not a step to slip into a refactoring.
- A draft that is explicitly requested may be left in a broken state; say that it is one.

## Verification

- [ ] The plan is a list of one-line steps with the behavior change marked.
- [ ] The build and tests ran after each step, and you can name the results.
- [ ] No step was too large to describe or revert by hand.
- [ ] No unrequested framework migration, API redesign or hierarchy appeared.
- [ ] Things noticed but not done are listed.

## Related

`refactoring-preparatory-steps` for the moment before a feature; `refactoring-stopping-rules` for the end; `/refactoring:plan` to produce a plan; `/refactoring:fix` and `refactoring-refactorer` to carry one out; `/refactoring:mode-pair` for a session of small narrated steps.

## Source

- `Primary Directive`
- `Non-Negotiable Rules`
- `Big-Bang Rewrite`
- `Code Generation Rules`
- `Final Instruction`
