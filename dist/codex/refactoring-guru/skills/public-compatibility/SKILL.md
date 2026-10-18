---
name: "public-compatibility"
description: "Use before deleting, renaming, inlining, hiding or changing the signature, constructor, visibility or type hierarchy of anything other code may reach: public, generated, reflected, serialized, plugin-facing or test-facing. Transition paths; candidates come from dead-weight."
---

# Public compatibility

Owns the question "is it safe to touch this?" for every technique that removes, renames, hides or reshapes something with outside users. Finding candidates is `$refactoring-guru:dead-weight`; answering the question for one symbol is `$refactoring-guru:reachability-check`.

## When to use

- You are about to delete a method, field, class, file or parameter that looks unused.
- You rename a method, change a signature, restrict a constructor or reduce visibility.
- You inline a method or class, collapse a hierarchy or change what a type extends.
- You move a member and the move would only compile if you widened access.

## Rules

1. **Preserve public compatibility, or provide a transition path, when refactoring public interfaces** (`MUST`). Callers you cannot see break first. Check: every changed public name, signature, constructor or visibility is either unchanged or has a documented path.
2. **Do not delete public, serialized, reflected or plugin-facing code without checking external compatibility** (`MUST NOT`). Check: for each deletion, the usages in those four channels are checked and recorded.
3. **Do not delete speculative or dead-looking code until generated, reflected, serialized, plugin-facing and public usages are checked** (`MUST NOT`). Compiler silence is not evidence of no users. Check: the deletion note lists what was searched.
4. **Delete unused code and files when no compatibility reason remains** (`MUST`). Once checked and clear, leave nothing behind "just in case". Check: no commented-out copy remains.
5. **Check tests before deleting a member that exists only for test access** (`MUST`). A test that needs the member may be the only user. Check: the tests referencing it were read, and either moved to the public behavior or removed with the member.
6. **Keep a framework extension point only when real users need it** (`MAY`). Check: you can name a user, or the point is removed.
7. **Remove a parameter only after confirming it is unused or no longer changes behavior** (`MUST`), and keep a compatibility path if the signature is public. Check: searches for callers that pass it, including named arguments and reflection.
8. **When callers are numerous or public, create a new method or transition path before deleting the old signature** (`SHOULD`). Check: old and new coexist while callers migrate, or the owner of every caller has agreed to the removal. Added judgment: for a published API, keep both for at least one released version; the source sets no period.
9. **Do not inline a method that is part of a public or test-facing API, an override point, or a useful concept name** (`MUST NOT`). Inspect all callers, including dynamic dispatch, inheritance and interface calls (`SHOULD`). Check: no subclass overrides it and no interface declares it.
10. **Hide a method only after checking its callers, and not when external callers need it.** Reduce visibility, then update tests. Check: no caller outside the owning scope remains.
11. **Rename a method by changing the definition and every caller together** (atomic), and verify references and public compatibility. Do not rename for churn unrelated to the change. Check: a whole-word search for the old name finds nothing except an intended alias.
12. **Preserve visibility intentionally when moving members** (`MUST`): do not widen access just to make the move compile. Check: the moved member is no more visible than before, or the widening is justified in the report.
13. **Before collapsing a hierarchy, check the remaining subclasses for substitutability and public type expectations** (`MUST`). Check: code that accepts the removed type still compiles or has been migrated.

## Procedure

1. List what you intend to change or remove and classify each item as private, internal or externally reachable. Default to externally reachable when unsure.
2. Added judgment: check each reach channel in order, and write down the result for each:
   - language-level references (compiler or IDE find-usages);
   - generated code and build outputs that mention the name;
   - reflection and string lookups (names in strings, annotations, dependency-injection or routing configuration);
   - serialization (field and property names in stored data, wire formats, schemas);
   - plugin or extension manifests and documented extension points;
   - tests, examples and documentation;
   - other repositories or packages that depend on this one (published API).
3. If any channel is externally reachable or unknown, plan the transition path: new form alongside the old, old delegating to new, deprecation notice, migration, removal in a later change.
4. For deletions with no external reach, delete in its own step with its own test run.
5. Report the channels checked, the evidence, and the decision per item.

## Example

A parameter that was never read is removed from a published function. Callers may still pass it, so the first release keeps it.

```python
import warnings

# Before: `locale` is accepted but never used
def total_price(cart, locale=None):
    return sum(unit * qty for unit, qty in cart)

# After (transition release): same signature, one visible warning when the argument is used
def total_price(cart, locale=None):
    if locale is not None:
        warnings.warn(
            "locale is ignored and will be removed in 3.0",
            DeprecationWarning,
            stacklevel=2,
        )
    return sum(unit * qty for unit, qty in cart)

# Next major release: def total_price(cart): ...
```

Behavior is unchanged for every existing call; callers learn about the removal before it breaks them.

## Anti-patterns

- **Compiler-clean deletion.** Deleting because the project builds. Detect: no search for strings, config, serialization or other repositories is recorded.
- **Silent signature change.** A parameter reordered or removed on a public function. Detect: a changed signature in an exported module with no overload, alias or deprecation.
- **Visibility inflation.** Making a member public so the move compiles. Detect: a `private` to `public` change in a "move" diff.
- **Test-only survivor.** A member kept alive only by its own test. Detect: references exist only under `test`.
- **Alias forever.** A deprecated alias never removed. Detect: no removal date or version. Added judgment: name the release that removes it.

## Trade-offs and exceptions

- A repository-private application (no published API, no plugins, no reflection) can use the compiler as strong evidence; say so in the report rather than skipping the check silently. Added judgment.
- Framework extension points are allowed only when real users need them; if the framework itself needs the hook, it is a user.
- A transition path costs a release cycle; when all callers are in the same change and owned by the same team, changing them together is the transition.

## Verification

- [ ] Each changed or removed item is classified private, internal or externally reachable.
- [ ] The reach channels checked are listed for every deletion.
- [ ] Public names and signatures are unchanged or have a transition path.
- [ ] No member was made more visible only to compile a move.
- [ ] Tests that referenced a removed member were handled deliberately.

## Related

`$refactoring-guru:dead-weight` to find candidates; `$refactoring-guru:reachability-check` for a single-symbol verdict; `refactoring-guru-compatibility-reviewer` to review a diff; `refactoring-guru-dead-code-remover` to delete after proof; `$refactoring-guru:method-call-moves` for signature techniques.

## Source

- `Safety and Tradeoff Rules`: only the rule to preserve public compatibility.
- `Dead Code`
- `Speculative Generality`
- `Decision Anti-Patterns`: only the rule on deleting speculative or dead-looking code.
- `Method Call Safety`
- `Inlining Safety`
- `Moving Safety`: only the rules on callers and visibility.
- `Generalization Safety`: only the rule on collapsing a hierarchy.
- `Conditional and Method Call Playbook`: only the Rename Method, Remove Parameter and Hide Method entries.
