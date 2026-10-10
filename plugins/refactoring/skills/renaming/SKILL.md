---
name: renaming
description: "Use when names hide intent, describe mechanism, or disagree with domain terms, or a rename is proposed. Safe renames and how far to take them in one change. No other skill rewrites identifiers; the packaging of a large rename is patch-hygiene."
---

# Renaming

The cheapest refactoring, and the one most often done unsafely or too widely. This skill covers what to rename, in which order, how to find every use, and how far to go in one change. How a large rename is packaged for review is `/refactoring:patch-hygiene`; the decision that a name is public API is `/refactoring:behavior-preservation`.

## When to use

- A variable, function or type name hides what it does, or describes how rather than what.
- Code uses a different word than the domain does for the same thing.
- A bad name is blocking understanding of a deeper refactoring.
- A rename is proposed in review, or you are tempted to rename a lot "while here".

## Rules

1. **Rename variables to reveal intent.** Check: a reader can tell what a variable holds from its name and a glance at its scope.
2. **Rename functions to describe behavior, not mechanism.** `loopUsersAndCheckFlag` becomes `activeUsers`. Check: the name still holds if the implementation changes.
3. **Rename types and modules to align with problem-domain terminology.** Check: a domain expert would recognize the term; one concept has one name across the code.
4. **Rename before deeper refactoring when bad names block understanding.** Check: you did the rename first and the tests passed before you moved or extracted anything.
5. **Use Rename Method (and related renames) to make caller intent clearer.** Check: each call site reads better than before.
6. **Do not rename everything at once.** A wholesale rename is not a refactoring in the source's sense and defeats review. Check: the rename has a stated reason, a bounded scope, and is its own patch when large.
7. **Do not mix a rename that spans unrelated files with a feature (Do not).** Check: see `/refactoring:patch-hygiene`.
8. **Do not rename while the deeper design problem stays untouched and call it improvement.** That is refactoring theater. Check: the rename either unblocks the next step or is listed as cosmetic and kept small.
9. **Added judgment: find every use, not just the symbol references.** Search for the old name as a whole word and in strings, comments, docs, configuration, build files, tests, database column or table names, serialized keys, queue job names, routes, metrics and log formats. Check: the search results are all accounted for.
10. **Added judgment: public or persisted names are behavior.** An exported symbol, a route, a config key, a stored job name or a JSON key may be used by something you cannot see. Rename the code symbol and keep the external name, or add the new name beside the old one, deprecate, and migrate. Check: each external name is unchanged or has a compatibility step.
11. **Added judgment: prefer tool-checked renames.** A language-server or compiler-assisted rename is a stronger net than search and replace; follow it with a text search for strings. Check: you used a tool where one exists and searched the rest.

## Procedure

1. Choose names that state intent in domain words (rules 1 to 3). Prefer one name per concept; check the code and docs for the existing word before inventing one.
2. Search for the old name in all forms (rule 9). Classify each hit: code symbol, internal string, external contract.
3. Rename with a tool where possible; run the build and tests.
4. Handle external contracts (rule 10): keep, alias or migrate.
5. If the rename is large, ship it as its own patch (`/refactoring:patch-hygiene`).
6. Update docs and comments that mention the old name.

## Example

```ts
// Before: mechanism-style names; the job name is persisted in queued jobs
export function proc(i: Invoice, d: Date): Settlement { /* ... */ }
queue.register("proc", proc);

// After step 1: rename the symbol and parameters; keep the persisted job name
export function settleInvoice(invoice: Invoice, settledOn: Date): Settlement { /* ... */ }
queue.register("proc", settleInvoice);   // job name unchanged: queued jobs still resolve

// Later, separate step: register the new name beside the old, drain queued "proc" jobs,
// then remove the old registration.
queue.register("settle-invoice", settleInvoice);
```

A text search for `"proc"` found the persisted job name that a symbol-only rename would have broken.

## Anti-patterns

- **Rename everything.** Detect: hundreds of identifier changes with no stated reason. Treat: cut to the names that block understanding.
- **Symbol-only rename.** Detect: strings, config or docs still use the old name. Treat: search by text too.
- **Silent public rename.** Detect: an exported or persisted name changed. Treat: compatibility step or ask.
- **Synonym drift.** Detect: `fetch`, `load` and `get` for the same concept across modules. Treat: pick one term per concept.
- **Rename theater.** Detect: names polished while a tangled function remains. Treat: say what was left and why.

## Trade-offs and exceptions

Bullets marked Added judgment are this plugin's own; the others follow limits the source states.

- A rename in code you do not own, or in generated code, belongs upstream or in the generator. (Added judgment)
- Some codebases prefer terse names in tight local scopes; follow the repository's convention (priority order in `/refactoring:principles`). (Added judgment)
- A rename that is the entire task (the user asked for it) can be large; keep it single-purpose. (Added judgment)
- Domain words can be contested; when two terms are in use, ask the user which one the domain uses rather than choosing. (Added judgment)

## Verification

- [ ] Each new name states intent in domain terms, and one concept has one name.
- [ ] A text search for each old name found no stale uses in code, strings, config or docs.
- [ ] External and persisted names are unchanged or have a compatibility step.
- [ ] Build and tests passed after the rename, with no changed expectations.
- [ ] A large rename is in its own patch.

## Related

`/refactoring:patch-hygiene` for packaging; `/refactoring:behavior-preservation` for public names; `/refactoring:call-signatures` for Rename Method together with parameter changes; `refactoring:refactorer` to carry out renames with tests between steps.

## Source

- `Naming Refactorings`
- `Preferred Refactoring Moves`
- `What Counts as Refactoring`: only the point that renaming everything at once is not refactoring.
- `Mixed-Intent Patches`: only the point about huge unrelated renames.
- `Refactoring Theater`: only the point about renaming while deeper design problems remain.
