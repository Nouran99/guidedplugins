---
name: method-call-moves
description: "Use when about to change a method's name or signature: Add or Remove Parameter, Separate Query from Modifier, Parameterize Method, explicit methods for a flag, Preserve Whole Object, Parameter Object, factory method, error code versus exception. Not diagnosis (data-smells)."
---

# Method call moves

Owns the fourteen techniques that change how a method is named, parameterized, constructed or reports failure: what to check first, the safe steps and how to verify. Deciding that a parameter group is a concept is `/refactoring-guru:data-smells`; defining a new value type is `/refactoring-guru:organizing-data`; checking that a public signature change is safe is `/refactoring-guru:public-compatibility`.

## When to use

- A method name hides what it does, or a method both answers a question and changes state.
- A signature needs another argument, or has one that no longer matters.
- Several methods differ only by a literal, or a parameter selects between different behaviors.
- Callers pass several values taken from one object, or values the callee could obtain itself.
- A field should not change after construction, a method should not be public, or construction needs a name.
- Failure is reported by a status code, or exceptions are used to test a condition.

## Rules

1. **Before Add Parameter, check whether the method should own the data as a field or obtain it through an existing collaborator** (`MUST`). Use Add Parameter only when occasional data must come from the caller and a field would be worse. Check: you can say why a field or lookup is worse.
2. **Preserve compatibility by creating a new method or transition path before deleting the old signature when callers are numerous or public** (`SHOULD`). Check: both forms work during the migration (see `/refactoring-guru:public-compatibility`).
3. **Before Remove Parameter, confirm the parameter is unused or no longer changes behavior** (`MUST`). Check: callers that pass it are listed and migrated.
4. **Before Separate Query from Modifier, split the mutation from the returned information and update callers to use the right method for each intent** (`MUST`). Do not use it when atomic read-and-modify is the public contract. Check: each caller that needed both now calls both, in the right order.
5. **Before Replace Parameter with Explicit Methods, confirm the parameter selects distinct behavior rather than ordinary data** (`MUST`). Check: each value of the parameter has its own method with its own name.
6. **Use Parameterize Method when several similar methods differ only by values,** not when the parameter selects different behavior. Check: every old method's behavior is a call with specific values.
7. **Before Introduce Parameter Object, confirm the grouped parameters represent one concept and not an arbitrary bag** (`MUST`). Check: the object has a domain name (`/refactoring-guru:data-smells` rule 12).
8. **Use Preserve Whole Object when callers pass several values from one object and the callee naturally depends on the whole concept;** do not use it if it creates an oversized dependency. Use Replace Parameter with Method Call when the callee can obtain the value; do not use it if it hides an expensive or surprising dependency. Check: no class gained a dependency it did not have.
9. **Do not simplify a method call if the simplification creates hidden dependencies between classes** (`MUST NOT`). Check: the dependency graph before and after has no new edge.
10. **Remove Setting Method when a field should not change after initialization:** set it through the constructor or factory. Do not use it when mutation is valid domain behavior. Check: object creation covers every case that used the setter.
11. **Hide Method when a public method is not part of the intended interface:** check callers, reduce visibility, update tests. Do not use it if external callers need it. Check: no caller outside the owning scope remains.
12. **Replace Constructor with Factory Method when construction needs naming, selection, caching or controlled creation;** not for simple construction. Check: all creation paths use the factory, and the constructor is restricted if safe.
13. **Replace Error Code with Exception when callers should not manually inspect status codes for exceptional failure; do not use it for ordinary expected branch choices.** Check: callers' failure handling was updated and the code checks removed.
14. **Replace Exception with Test when callers can cheaply check a condition before the call;** keep the exception for true violations. Do not use it when the failure is race-prone. Check: normal and failure paths are both tested. Exceptions must not be routine tests when a cheap check exists (`MUST NOT`).
15. **Rename Method when the name does not reveal behavior,** changing the definition and callers atomically; skip renames unrelated to the change. Check: whole-word search for the old name.

### Technique table

| Technique | Use when | Do not use when | Verify |
| --- | --- | --- | --- |
| Rename Method | The name hides intent | Rename churn unrelated to the change | References; public compatibility |
| Add Parameter | The method lacks data it needs for its job | The method should own or derive the data | Callers |
| Remove Parameter | A parameter no longer affects behavior | It is part of public compatibility | Callers |
| Separate Query from Modifier | A method returns data and mutates state | Atomic read-and-modify is the contract | State changes; return values |
| Parameterize Method | Methods differ only by values | The parameter selects different behavior | All value cases |
| Replace Parameter with Explicit Methods | A parameter selects distinct behavior | The parameter is ordinary data | Each behavior |
| Preserve Whole Object | Callers pass several values from one object | It creates an oversized dependency | Dependency direction |
| Replace Parameter with Method Call | The callee can obtain the data | It hides an expensive or surprising dependency | Lookup behavior |
| Introduce Parameter Object | Parameters repeatedly travel together | They are a random bag | Construction and validation |
| Remove Setting Method | A field is fixed after initialization | Mutation is valid domain behavior | Object creation |
| Hide Method | A public method is not intended for clients | External callers need it | Public API |
| Replace Constructor with Factory Method | Creation needs a name, selection, caching or control | Construction is simple | Creation paths |
| Replace Error Code with Exception | Failure should interrupt normal flow | Branch choices are ordinary | Failure handling |
| Replace Exception with Test | A cheap pre-check exists | The failure is truly exceptional or race-prone | Normal and failure paths |

## Procedure

1. Pick the technique; read the "do not use when" cell and the matching must-check rule.
2. List all callers with a search, including tests, reflection and configuration.
3. Introduce the new form beside the old; migrate callers in groups; run the tests after each group.
4. Remove the old form only when no caller remains (or after the agreed transition period for public API).
5. Run a final search for the old name or signature.

## Example

`isOverQuota` is named like a query but also sends a warning email, so any code that merely asks the question triggers mail.

```ts
// Before
function isOverQuota(user: User): boolean {
  const over = user.usedBytes > user.quotaBytes;
  if (over) mailer.sendQuotaWarning(user.email);
  return over;
}
// caller: if (isOverQuota(user)) { blockUpload(); }

// After (behavior-preserving: every existing caller now makes both calls)
function isOverQuota(user: User): boolean {
  return user.usedBytes > user.quotaBytes;
}
function sendQuotaWarning(user: User): void {
  mailer.sendQuotaWarning(user.email);
}
// caller: if (isOverQuota(user)) { sendQuotaWarning(user); blockUpload(); }
```

The refactoring step keeps every caller's observable behavior, email included. Afterwards a caller that never needed the email can drop `sendQuotaWarning`, and that is a behavior change to report separately. A mutating accessor such as `queue.pop()` is the opposite case: atomic read-and-modify is its contract, so the technique does not apply.

## Anti-patterns

- **Flag parameter.** `render(page, true)`. Detect: boolean literal at call sites. Treat with Replace Parameter with Explicit Methods when the flag selects behavior.
- **Options bag.** A parameter object with unrelated fields. Detect: the type name is `Options` or `Params`.
- **Exception as branch.** `try { find(id) } catch (NotFound) { create(id) }` in a loop. Detect: exceptions on the normal path.
- **Hidden dependency by whole object.** Passing an aggregate to avoid two parameters. Detect: the callee needs two fields of a large owner.
- **Orphaned signature.** The old form left in place after migration. Detect: no callers, still exported.

## Trade-offs and exceptions

- Atomic read-and-modify methods (take-next, compare-and-set) keep their combined contract.
- Parameter lists may stay temporarily when removing parameters would create stronger unwanted dependencies.
- A factory method is only worth it when construction needs a name, selection, caching or control.
- Added judgment: when callers are in several repositories, treat a signature change as a public API change by default.

## Verification

- [ ] All callers were found, including tests and string-based references.
- [ ] Separated query and modifier callers each call the right one.
- [ ] No parameter object is a bag; no whole-object parameter adds a large dependency.
- [ ] A transition path exists for public signatures.
- [ ] Normal and failure paths are covered for error-handling techniques.

## Related

`/refactoring-guru:data-smells` for whether a group is a concept; `/refactoring-guru:public-compatibility` for transition paths; `/refactoring-guru:organizing-data` for the value type; `refactoring-guru:call-contract-reviewer` to review a diff.

## Source

- `Simplifying Method Calls`
- `Conditional and Method Call Playbook`: only the method-call entries (Rename Method through Replace Exception with Test).
- `Method Call Safety`
- `Decision Anti-Patterns`: only the rules on parameter objects built from unrelated arguments and on exceptions used as routine tests.
