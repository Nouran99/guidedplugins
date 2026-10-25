---
name: "clean-architecture-component-grouping"
description: "Use when deciding which classes ship, version or change together, or how to split a codebase into packages, modules or deployables. Covers cohesion and release pressure. Cycles and stability belong to component-coupling, folder names and layout to screaming-structure."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Component grouping

Owns which classes belong inside one component. Arrows between components, cycles and stability are `clean-architecture-component-coupling`; what the folder names announce is `clean-architecture-screaming-structure`; whether a component should be a separate deployable at all is `clean-architecture-boundary-economics`.

## When to use

- You split a codebase into packages, modules, libraries or deployables.
- A single change keeps touching three packages, or one package changes for unrelated reasons.
- Packages are named after technical layers and each contains policy for several unrelated capabilities.
- A consumer of a library must pull in a lot it never uses.

## Rules

1. **Group components by cohesion and release pressure.** `[MUST]` Things that change together and ship together belong together. Check: look at the last commits (`git log --name-only`) and see which files change together; they should share a component.
2. **Do not put unrelated policy in one component merely because it sits in the same technical layer.** `[MUST NOT]` Check: a package named after a layer (all controllers, all models) holds policy for several unrelated capabilities.
3. **Name each component for the business capability or use case it serves.** `[MUST]` Check: the component name is a capability (`invoicing`, `dunning`), not a mechanism (`models`, `handlers`).
4. **Choose the lightest boundary that preserves the needed independence.** `[MUST]` A component starts as a source-level grouping; it becomes a separately released or deployed unit only when something requires independent release or deployment. Check: every separately deployed component has a stated reason to be deployed alone.
5. **Make the component's boundary enforceable.** `[MUST]` Use package structure, visibility, tests, dependency rules or build constraints. Check: another component cannot import its internals without a failure.
6. **Do not put unrelated use cases in one component because operational wiring is easier.** `[MUST NOT]` Check: the component's use cases serve one capability or actor.
7. **Revisit the grouping when the shape of change, team ownership, deployment needs or operational constraints reveal rising cost.** `[MUST]` Check: a recurring pain (cross-component edits, waiting for another team's release) has an owner and a decision.
8. **Release together what is reused together.** Added judgment (the book's reuse/release principle, not stated in the vendored rule set): a component should have a release story. Check: you can say what a new version of it means to its consumers.
9. **Put classes that change for the same reason into one component.** Added judgment (the book's common-closure principle): a change should land in one place. Check: for a typical change in the recent history, the number of components touched is one.
10. **Do not force users of a component to depend on what they do not use.** Added judgment (the book's common-reuse principle, close to ISP): if half a package serves one client and half another, split it. Check: each client of the component uses most of its public classes.
11. **Expect the three grouping pressures (8 to 10) to pull against each other, and decide by the one dominant now.** Added judgment: early in a project, keeping change cheap usually matters more than broad reuse; shift as consumers appear. Check: the decision and its trigger for revisiting are written down.

## Procedure

1. List the packages or modules in scope and, for each, the capabilities whose code it holds.
2. Read recent history (`git log --name-only -n 50`) and note which files change together.
3. Draw the grouping that would put co-changing files in one component and unrelated policy in different ones (rules 1 and 2).
4. For each proposed split, state the reason it needs a separate boundary at all (rule 4); if the only reason is tidiness, keep one component with an internal boundary.
5. Name each component for its capability, and decide how its boundary is enforced (rule 5).
6. Move code in small steps, running the tests after each, and update the dependency checks (`/clean-architecture:enforce-boundaries`).

## Example

```text
# Evidence from `git log --name-only` over the last 33 billing commits
invoice-calculator.ts   changed with   invoice-template.ts    in 31 commits
invoice-calculator.ts   changed with   dunning-schedule.ts    in 2 commits
models/*.ts             changed with   no single other file

# Before: grouped by technical layer; every feature touches all three, and all three always ship together
billing-models/   billing-services/   billing-controllers/

# After: grouped by what changes and ships together
invoicing/   calculator, template, Invoice entity, RenderInvoice use case, its ports and adapters
dunning/     schedule, reminder policy, SendDunningNotice use case, its ports and adapters
             (depends on invoicing only through InvoiceLookup, a port that dunning declares)
```

The split follows the evidence: the calculator and the template change together, dunning rarely changes with them. The layer packages gave neither independent change nor independent release, which is what a component boundary is for.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Layer-first components | Packages named models, services, controllers shared by all features | Regroup by capability |
| Shotgun change | One feature edits many components | Merge the pieces that always change together |
| Everything-app | One component holding unrelated use cases because deployment is easy | Split by capability; keep one composition root |
| Reuse by hope | A shared library no second consumer uses, forcing release coordination | Merge it back into its only consumer |
| Class-count grouping | Components split by file count or team habit | Split by change and release |
| Orphan release unit | A deployable that cannot be explained without naming its neighbors | Merge, or define its independent purpose |

## Trade-offs and exceptions

- The source says to group by cohesion and release pressure, and to choose the lightest boundary. A small application is rightly one component with internal layers; do not split it to look architectural.
- The vendored rule set backs rules 1 to 7. Rules 8 to 10 are the book's component-cohesion principles and rule 11 is how to weigh them; all four are labelled Added judgment, so treat them as heuristics and weigh them against your project's history.
- Independent deployment is a separate decision with a separate cost; see `clean-architecture-boundary-economics` and `clean-architecture-service-and-device-edges`.
- Technical grouping inside a component is fine when it does not obscure use-case ownership.

## Verification

- [ ] Files that changed together recently live in the same component.
- [ ] No component is named after a technical layer while holding unrelated policy.
- [ ] Every separately released or deployed component has a stated reason.
- [ ] Each component's boundary is enforced by structure, visibility or a check.
- [ ] A typical change touches one component.
- [ ] The grouping decision and its revisit trigger are recorded.

## Related

`clean-architecture-component-coupling` for the arrows between the components; `clean-architecture-screaming-structure` for names; `clean-architecture-boundary-economics` for whether to split; `clean-architecture-structure-reviewer` to review a tree.

## Source

- `Paradigm and Component Rules`: rule 9, grouping by cohesion and release pressure rather than technical layer.
- `Naming Rules`: only the rule naming modules and packages after business capabilities or use cases.
- `Boundary Cost, Deployment, and Operations`: only the kinds of boundary, the lightest-boundary rule, enforceability, and not combining unrelated use cases for wiring.
- `Architecture Economics and Priority`: only the rule on revisiting architecture when change shape, ownership, deployment or operations reveal rising cost.
