---
name: "core-domain-focus"
description: "Use when deciding how much DDD modeling an area deserves: plain CRUD or reference data wrapped in aggregates and events, or real lifecycle and invariants kept as flat records and scripts. Rules for core-domain effort and against DDD theater. Not one service's thickness (application-services)."
---

# Core domain focus

Owns the brake and the accelerator: richest modeling where the business really is complex, plain code where it is not, and no DDD vocabulary that leaves the design unchanged. Every other tactical skill assumes the modeling is earned; this one decides whether it is. How thin an application service is in a modeled area is `$ddd-implementing:application-services`.

## When to use

- A reference-data, settings or admin screen has aggregates, repositories, events and an application service.
- A service has long `if` chains over status values and several rules that depend on the current state, and no model object owns them.
- A "domain" package contains classes with only getters, setters and an ORM mapping.
- Someone asks whether this module "needs DDD".
- A vendor or framework type (`BaseEntity<T>`, a payment SDK's `Charge`) appears in the part of the system the business competes on.

## Rules

1. **[MUST] Protect the core domain from generic abstractions and vendor terms.** The core is where wording and rules are most specific. Check: core model classes import no vendor SDK types and their names come from the domain. Added judgment: they also extend no generic framework base class beyond what persistence strictly forces.
2. **[MUST] Spend the richest modeling effort where competitive or operational complexity truly lives.** Check: you can name the one to three areas where the business differentiates or where mistakes are costly, and those areas have the most explicit models, value objects and tests.
3. **[MUST] Keep supporting subdomains simpler.** Check: each tactical pattern in a supporting area maps to a rule it carries, and the area does not copy the core's structure by default.
4. **[MUST] Do not give every subdomain full-blown DDD ceremony; use simpler patterns in supporting areas.** Check: the area's code size and layering match its rules, not the project's architecture slide.
5. **[MUST] Model invariants and lifecycle complexity honestly once they appear.** Check: state-dependent rules and multi-field invariants live in named model code, not in service branching.
6. **[MUST NOT] Use DDD vocabulary without changing the design.** An "aggregate" with only setters and a "repository" that is a DAO is CRUD with renamed classes. Check: for each pattern name in the code, you can point to the invariant, behavior or boundary it carries.
7. **[MUST NOT] Over-model trivial CRUD subdomains.** Check: a lookup table or settings page has no aggregate root, no domain events and no application service beyond what the framework needs.
8. **[MUST NOT] Refuse to model real complexity because "simple services are enough".** Check: a service with state-dependent branching, invariants and regular defects is a modeling candidate.
9. **[Compact checklist] When DDD vocabulary appears around CRUD services, generic repositories, mutable graphs or passive entities, require the real invariant and behavior or simplify the design.** Check: the pull request names the invariant that justifies each pattern, or removes the pattern.
10. **[Added judgment] Use three signals per area: rules that depend on current state (lifecycle), an invariant over more than one field or object, and the business arguing about words.** If none holds, treat it as CRUD; if any holds, model that part. The signals are a search aid, not a rule of the source.
11. **[Added judgment] Model the part, not the whole area.** One tricky state machine inside a mostly plain supporting area earns an entity; the rest of the area stays plain.

## Procedure

1. Name the area and its context (`$ddd-implementing:bounded-context`).
2. Apply the three signals from rule 10 by reading the code and the requirements: list the state-dependent rules, the cross-field invariants and the terms people argue about.
3. Decide per part: plain, or modeled. Write the decision and the evidence in one line each. For several areas at once, run `$ddd-implementing:ceremony-check`.
4. If the area is over-modeled, remove the pattern that carries no invariant (an event nobody uses, a repository over a table, an aggregate with no behavior) one at a time, with tests green.
5. If the area is under-modeled, extract the state-dependent rules into an entity or value object first (`$ddd-implementing:entities`, `$ddd-implementing:value-objects`) before adding any other pattern.
6. Keep the ubiquitous language in both modes; plain code still uses the business's words.

## Example

```ts
// Before: reference data wrapped in tactical patterns that carry no invariant
export class Country extends AggregateRoot {
  private constructor(private _id: CountryId, private _name: string, private _iso: string) { super(); }
  static create(name: string, iso: string): Country {
    const country = new Country(CountryId.next(), name, iso);
    country.addDomainEvent(new CountryCreated(country._id));
    return country;
  }
  rename(name: string): void {
    this._name = name;
    this.addDomainEvent(new CountryRenamed(this._id, name));
  }
}
export interface CountryRepository {
  save(country: Country): Promise<void>;
  byId(id: CountryId): Promise<Country | null>;
}

// After: a supporting area stays plain
export type Country = { iso: string; name: string };

export const listCountries = (db: Db): Promise<Country[]> =>
  db.query("select iso, name from country order by name");

export const renameCountry = (db: Db, iso: string, name: string): Promise<void> =>
  db.exec("update country set name = $1 where iso = $2", [name, iso]);
```

No rule depends on the country's state and no invariant spans objects, so nothing earned the aggregate, the events or the repository. The loan-renewal rules next door, which do depend on state, would earn them.

## Anti-patterns

- **DDD theater.** Tactical patterns on a table with no rules. Detect: aggregate classes whose methods are `get*`/`set*` and an `*Repository` with `findAll`, `save`, `delete`.
- **Anemic core.** The business differentiator is a service full of `if (status == ...)`. Detect: branching on a status field in a service that also loads and saves the object.
- **Vendor-shaped core.** Domain classes named after the payment or CMS provider. Detect: vendor package imports under the core domain.
- **Uniform architecture.** Every module has the same four layers regardless of content. Detect: layers with one-line pass-through methods.

## Trade-offs and exceptions

- A supporting area that is simple today may grow rules; the source asks for honest modeling once invariants and lifecycle appear, not before. Added judgment: leave the plain code easy to convert by keeping rules out of controllers and templates.
- A team convention may require a uniform layering for tooling reasons. The convention wins (user and repository first); mark the pass-through layers as such and do not add events or repositories on top.
- This plugin does not classify subdomains. Where a project needs that discussion, the sibling plugins `ddd` and `ddd-distilled` cover it.

## Verification

- [ ] The area's modeling effort matches the evidence of rules and lifecycle in it.
- [ ] Every tactical pattern in the change maps to an invariant, behavior or boundary it carries.
- [ ] Supporting and reference-data areas stayed simpler than the core, and each tactical pattern in them maps to a rule it carries.
- [ ] State-dependent rules are not hidden in service branching.
- [ ] No vendor or generic framework term entered the core model.
- [ ] The business's words are used in both modeled and plain code.

## Related

`$ddd-implementing:ceremony-check` for a keep, trim or extract plan per area; `$ddd-implementing:application-services` for thin orchestration in modeled areas; `ddd-implementing-modeling-effort-reviewer` to review the changed code of a diff; `$ddd-implementing:aggregate-boundaries` once an aggregate is justified.

## Source

- `Strategic Design Rules`: only the Core Domain Protection subsection.
- `Core Domain Protection`
- `Practical Simplicity Rule`
- `Primary Directive`: only the instruction to reject designs that sound like DDD but behave like CRUD with renamed classes.
