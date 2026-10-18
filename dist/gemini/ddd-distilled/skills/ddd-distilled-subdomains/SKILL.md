---
name: "ddd-distilled-subdomains"
description: "Use when ranking areas of a business system as core, supporting or generic, or when the best modeling effort seems spent on a commodity concern. Covers classification, effort allocation and signs the core has drifted. Not for the go or no-go on DDD (ddd-distilled-adoption-fit)."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Subdomains

Classify the major areas of the business, then spend design effort in proportion. This skill ranks areas against each other; whether an individual area needs modeling at all is `ddd-distilled-adoption-fit`, and where its model boundary sits is `ddd-distilled-bounded-contexts`.

## When to use

- A new product area is being broken down and nobody has said which part is the reason customers choose the business.
- A review shows the richest model in a repository sits in something any competitor also has.
- Engineering time is being estimated and every module is treated as equally deserving.
- A diff touches several areas and you must decide where to be careful and where to stay plain.

## Rules

1. **Classify major areas as core domain, supporting subdomain or generic subdomain.** The classes say where the business differentiates, where it needs custom code that is not differentiating, and where it needs a commodity capability. Check: every area in the change has one class and a one-line reason.
2. **Invest the most design effort in the core domain.** It is where model quality converts into business value. Check: the core area has the richest model, the most scenarios and the most careful review; if another area has more, ask why.
3. **Keep supporting and generic subdomains simpler unless complexity proves otherwise.** Their value is in being adequate. Check: no aggregates, events or translators in a supporting or generic area without a stated invariant, lifecycle or consumer.
4. **Do not waste the best modeling effort on commodity concerns.** Time spent perfecting authentication, notifications or reference data is time not spent on what differentiates. Check: no hand-built generic capability gets more design attention than the core area.
5. **Start from the business capability or subdomain.** This is step one of the Primary Directive. (Added judgment: a technical layer or a team name is not a capability.) Check: the classification list reads as things the business does, not as `services`, `utils` or `db`.
6. **Reassess when the core business concern drifts, or when supporting complexity hides the core.** The business moves; the classification must move with it. Check: ask whether the core of two years ago is still the core; if the answer is "partly", reclassify.
7. **A missing classification is a review finding.** Review Rules list missing subdomain classification explicitly. Check: the pull request, design note or module README states the class of the area it changes.
8. **Do not assume subdomains and bounded contexts line up one to one.** (Added judgment) The classification describes the business; the context describes where a model lives. Check: for each context, list the subdomains it serves, and for each subdomain, the contexts that serve it.
9. **Confirm "core" with a person who knows the business strategy.** (Added judgment) Code size, change frequency and test count are hints, not proof. Check: a human confirmed the core list, or the classification is marked provisional.

## Procedure

1. List capabilities (what the business does) for the area in scope.
2. Mark each as core, supporting or generic, with the reason in business terms.
3. Mark the evidence as confirmed or provisional (rule 9).
4. Compare effort with class: where is the deepest model, the most tests, the most review attention?
5. Report mismatches and suggest the smallest rebalancing: simplify the over-modeled commodity, or deepen the thin core.
6. Hand the contexts question to `ddd-distilled-bounded-contexts`.

## Example

Classification of a clinic-scheduling product, with the effort each class earns:

```text
Capability                       Class       Why                               Effort
Appointment slot optimisation    core        reason clinics pick the product   rich model, scenarios with clinic managers
Patient reminders (SMS, email)   generic     any competitor sends reminders    vendor SDK behind one small interface
Practitioner onboarding          supporting  needed, not differentiating       plain services and forms
Insurance eligibility check      supporting  integration-heavy, rules owned    translate at the boundary,
                                             by payers                         keep the rules out of the model
```

```ts
// Generic area: stays small and boring.
export interface ReminderSender {
  send(to: ContactAddress, message: ReminderMessage): Promise<void>;
}

// Core area: the model carries the business rule (types such as Slot are assumed).
export class SlotPlan {
  constructor(private readonly slots: Slot[]) {}

  assign(request: AppointmentRequest): Assignment | undefined {
    const feasible = this.slots
      .filter((s) => s.isFree() && s.practitioner.offers(request.treatment))
      .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime());
    return feasible.length > 0 ? feasible[0].reserveFor(request) : undefined;
  }
}
```

## Anti-patterns

- **Flat effort.** Every module gets the same layering and the same review depth. Detect: identical package templates for the core and for reference data.
- **Gold-plated commodity.** A custom retry, templating or user-directory framework with its own domain model. Detect: a generic capability with more classes than the core.
- **Unclassified area.** Code arrives with no statement of its importance. Detect: no class in the pull request or module notes.
- **Stale core.** The area modeled most deeply stopped being the differentiator. Detect: the core list predates the last strategy change.

## Trade-offs and exceptions

- Supporting and generic areas can earn more modeling when their own complexity proves it; the rule is "simpler unless complexity proves otherwise", not "never".
- Classification is judged on the business, so a start-up's core may be a thin slice of what exists today.
- Added judgment: when a generic capability must be built in-house because no adequate off-the-shelf option exists, keep the in-house version narrow and behind an interface your core owns.

## Verification

- [ ] Every area in scope has a class and a business reason.
- [ ] The evidence is marked confirmed or provisional.
- [ ] The deepest model and most careful review are in the core area.
- [ ] No supporting or generic area carries full tactical patterns without proof of need.
- [ ] Mismatches between class and effort are listed with a smallest fix.

## Related

`ddd-distilled-adoption-fit`; `ddd-distilled-classify-subdomains` to scan a codebase; `ddd-distilled-bounded-contexts`; `ddd-distilled-subdomain-reviewer` to review a diff.

## Source

- `Start with Subdomains`
- `Strategic Rules`
- `Adoption Fit and Modeling Investment`: only the rules that business drivers decide where effort goes and that drift triggers reassessment.
- `Review Rules`: only the missing subdomain classification item.
- `Primary Directive`: only the first two steps, identify the capability or subdomain and decide whether it is core, supporting or generic.
