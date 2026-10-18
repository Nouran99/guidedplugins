---
name: "coding-standards"
description: "Use when naming, formatting, file structure or idioms diverge from the codebase, or when reformatting and renaming noise appears in a diff that is not about style. Comment content belongs to $code-complete:comments."
---

# Coding standards and consistency

Keeps new code consistent with the code around it so readers learn each idiom once. It compares your change with its neighbors; what a comment says is `$code-complete:comments`, and whether a name is good in the first place is owned by `$code-complete:variables`, `$code-complete:data-types` and `$code-complete:routine-design`.

## When to use

- New code names, formats or structures things differently from the surrounding module.
- A diff mixes the requested change with renames, reordering or reformatting of untouched code.
- Two modules solve the same recurring problem (logging, config access, error reporting) in different ways.
- A formatter or linter exists and its output is not applied, or hand formatting fights it.
- A personal style preference is being applied to shared code.

## Rules

1. **Be consistent within the codebase.** Why: readers use one mental model per idiom. Check: new code is indistinguishable in naming, error style, file layout and ordering from its neighbors.
2. **Use formatting, naming and file structure to support readability.** Check: file organization and layout are chosen so that a reader finds things where the module's other files have them.
3. **Standardize common idioms so readers do not relearn style per module.** Check: the way the repository iterates, logs, reads configuration, builds paths and reports errors is reused, not reinvented.
4. **Prefer a shared convention over local personal taste.** Check: where you would choose differently, you follow the convention anyway; where the convention is the problem, you raise it separately.
5. **Do not make arbitrary naming and formatting changes.** Forbidden pattern. Check: untouched lines are not renamed, reordered or reformatted as part of the change.
6. **Do not create module-specific mini dialects inside one codebase.** Forbidden pattern. Check: no new naming scheme, error type family or abstraction style appears in one module only.
7. **Keep layout and style consistent enough that readers can focus on meaning.** Check: whitespace, line breaks and ordering follow the project's rules so that the diff shows semantic changes only.
8. **Use tools and scripts to reduce error-prone manual work.** Source rule in the tools section. Check: formatting is done by the project's formatter or linter, not by hand.
9. Added judgment: the repository's formatter and linter configuration are the authority on layout; if none exists, mirror the file you are editing and do not introduce a style.
10. Added judgment: when you find that a convention is poor, change it deliberately and project-wide in its own change, or propose it; do not fix it locally in the middle of a feature.
11. Added judgment: when a repository has two conventions for the same thing, follow the one used in the files you touch and the most recent code, and mention the split rather than choosing a third.

## Procedure

1. Open two or three neighboring files of the same kind and note their conventions: naming, error handling, imports, ordering, test layout.
2. Compare your new code with them and list deviations.
3. Bring the new code into line. Do not touch untouched code, except where the change makes a convention fix unavoidable.
4. Run the formatter and linter the project provides, on the files you changed only.
5. Check the diff: it should show only intended changes. Move unrelated style edits out.
6. If you found a real convention problem, write it down as a separate proposal.

## Example

```ts
// Neighbors in this repository: camelCase names, repositories throw NotFoundError, results are plain values
//   userRepo.findById(id): Promise<User>          // throws NotFoundError
//   orderRepo.findById(id): Promise<Order>         // throws NotFoundError

// Before: new code invents its own dialect
export class invoice_repo {
  async Get_Invoice(inv_id: string): Promise<{ ok: boolean; data?: Invoice }> { /* ... */ }
}

// After: same names, same failure convention, same shape as the neighbors
export class InvoiceRepo {
  async findById(id: string): Promise<Invoice> { /* throws NotFoundError when missing */ }
}
```

The second version costs the reader nothing: they already know how `findById` behaves.

## Anti-patterns

- **Local dialect.** One module with its own naming or error style. Detect: the same operation named or reported differently in one directory.
- **Drive-by reformat.** Whitespace and renames in untouched lines. Detect: diff hunks that contain no semantic change.
- **Taste override.** A preferred style applied over the shared one. Detect: a change justified by "I find this clearer" with no repository rule behind it.
- **Formatter fight.** Hand-aligned code that the formatter would undo. Detect: churn on the next format run.
- **Idiom drift.** A fourth way to read configuration. Detect: three existing helpers and a new direct environment lookup.

## Trade-offs and exceptions

- Consistency does not mean copying a bad pattern forever. When a convention causes defects (for example, a swallowed-error idiom), fix it deliberately, in its own change, with agreement.
- Legacy modules written to older conventions may stay as they are; new code in them follows the module's local style unless the project has declared a migration.
- Where a language or framework dictates names (`__init__`, `main`, lifecycle hooks), the language wins.
- The source asks for shared conventions; it does not choose which. The repository, then explicit user instruction, decide (`$code-complete:principles` priority order).

## Verification

- [ ] The new code matches its neighbors in naming, ordering and error style.
- [ ] Reused repository idioms instead of introducing new ones.
- [ ] No unrelated reformatting or renaming in the diff.
- [ ] The project's formatter and linter ran on the changed files.
- [ ] Any convention problem found is recorded as a separate proposal.

## Related

`$code-complete:comments` for comment content; `$code-complete:error-handling` for the failure convention itself; `$code-complete:refactoring-judgment` when a convention fix is a refactor; `code-complete-consistency-reviewer` to review a diff.

## Source

- `Coding Standards Rules`
- `Consistency Neglect`
- `Foundational Construction Rules`: only the rule to use conventions consistently.
- `Performance, Integration, Tools, and Craftsmanship`: only the rules on layout and style consistency and on tools that reduce manual work.
