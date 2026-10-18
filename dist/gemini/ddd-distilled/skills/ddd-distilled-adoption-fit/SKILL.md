---
name: "ddd-distilled-adoption-fit"
description: "Use when deciding whether an area of business software deserves DDD modeling at all, how much effort it earns, or whether an earlier decision needs reassessing. Not for one concept's pattern (ddd-distilled-pattern-economy) or ranking areas (ddd-distilled-subdomains)."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Adoption fit

The go or no-go decision for an area, taken before any tactical pattern is chosen: does this part of the system carry enough business complexity, language ambiguity, differentiation or integration risk to justify modeling effort, and how much? It does not rank areas against each other (`ddd-distilled-subdomains`) and it does not choose between an entity and a plain record (`ddd-distilled-pattern-economy`).

## When to use

- Someone proposes "DDD for the whole service" or "no need for any of that, it is just CRUD".
- A new module is starting and the team has not said how much design it needs.
- Code and conversation have drifted apart, or supporting code has grown until it hides what the business cares about.
- A reviewer asks "why is this an aggregate?" or "why is there no model here at all?"

## Rules

1. **Use DDD when domain complexity, language ambiguity, business differentiation or integration risk justify the effort.** Effort without one of these drivers is ceremony. Check: name which driver is present, with one concrete example from the area.
2. **Do not apply full tactical DDD to simple CRUD, generic subdomains, or problems whose complexity is mainly technical.** Those areas gain little from aggregates and events. Check: no aggregate, event or translator exists for an area that only creates, reads, updates and deletes records with no invariant.
3. **Let business drivers decide where the modeling effort goes.** (Added judgment: technical interest and fashion are not drivers.) Check: every area's effort level has a business reason attached, not a technology reason.
4. **Reassess the model when the core business concern drifts, when terms stop matching code, or when supporting complexity hides the core.** A decision that was right at the start decays. Check: for each of the three triggers, say whether it fired since the last decision.
5. **Use scenarios and acceptance tests to validate that the model expresses real business behavior.** A model nobody can exercise is a guess. Check: each modeled behavior has at least one scenario worded the way the business would say it. See `ddd-distilled-domain-tests`.
6. **Reject both extremes.** No modeling in a complex domain and full ceremony in a simple one are both failures. Check: for the area, say in one sentence what is lost by modeling less and what is lost by modeling more.
7. **When uncertain, run the five steps in order:** identify the business capability or subdomain; decide whether it is core, supporting or generic; define the bounded context; use the local ubiquitous language; apply only the tactical patterns that earn their cost. Check: the answer names a step you could not complete, rather than skipping to patterns.
8. **Treat team skill and access to domain experts as limits on how much ceremony the project can sustain.** A model that no one on the team can maintain or validate will rot. Check: the chosen level matches who will own the code and whether an expert can be reached. Sizing is `ddd-distilled-estimate-work`.
9. **Do not dismiss DDD because not every module needs it, and do not over-model a generic subsystem.** Both are named anti-patterns. Check: the decision is made per area, not once for the repository.
10. **Write the decision down in one short record per area.** (Added judgment) Area, drivers present, effort level, reassessment trigger. A record turns rule 4 from an intention into something a reviewer can check.

## Procedure

1. List the areas the work touches (capabilities, not packages).
2. For each, answer rule 1: which driver is present? If none, mark it "plain" and stop for that area.
3. If a driver is present, ask `ddd-distilled-subdomains` for its class so the effort can be compared with its neighbors.
4. Set an effort level with the cheapest honest pattern from `ddd-distilled-pattern-economy`.
5. Record the decision and the trigger that would reopen it.
6. Name the scenarios an expert should confirm before the model is trusted.

## Example

A decision record for two areas of a freight-booking product:

```text
Area: country and currency reference data (admin screens)
Drivers present: none (no invariants, no lifecycle, nobody disputes the words)
Effort: plain records and one lookup function. No aggregate, no events.
Reassess when: a rule appears that depends on more than one field.

Area: surcharge calculation for oversize freight
Drivers present: complexity (stacked rules), language ambiguity ("weight" is
  measured, billed and declared), differentiation (customers choose us on price)
Effort: model it. Value objects for the three weights, one domain operation per
  surcharge rule, scenarios agreed with the pricing team.
Reassess when: a second carrier contract changes how billed weight is derived.
```

The first area is not under-modeled; the second would be under-modeled by a function over a `Map<string, number>`.

## Anti-patterns

- **DDD theater.** Aggregates, repositories and events present with no invariant, lifecycle or consumer behind them. Detect: ask what breaks if the pattern is removed.
- **Blanket dismissal.** "We are not doing DDD" applied to an area with disputed vocabulary and stacked rules. Detect: the same business word has two meanings in the code and nobody can say which.
- **One decision for the whole repository.** Detect: no per-area reasoning, only a team-wide preference.
- **Over-modeled generic subsystem.** Detect: the richest model in the repository sits in notifications, auth or reference data.

## Trade-offs and exceptions

- Simple domains may use simple services and data structures. When invariants, lifecycle and language complexity rise, strengthen the model; that is the book's own escape valve.
- A supporting or generic area can get more modeling if its own complexity proves it, but the proof comes first.
- Prefer incremental improvement over a design overhaul: raise the effort level for one area at a time.
- Added judgment: an area that is plain today but sits next to a core area deserves a one-line language note so its terms do not later collide with the core's.

## Verification

- [ ] Each touched area has a named driver or an explicit "plain" decision.
- [ ] No full tactical pattern set was applied to a CRUD or generic area.
- [ ] At least one reassessment trigger is recorded for each modeled area.
- [ ] Team skill and expert access were considered for the chosen level.
- [ ] A business-worded scenario exists for each modeled behavior.

## Related

`ddd-distilled-subdomains` to rank areas; `ddd-distilled-pattern-economy` to pick the pattern; `ddd-distilled-estimate-work` to size the effort; `ddd-distilled-subdomain-reviewer` and `ddd-distilled-ceremony-reviewer` to review a diff.

## Source

- `Adoption Fit and Modeling Investment`
- `Primary Directive`
- `Practicality Rules`: the anti-patterns about dismissing DDD and over-modeling a generic subsystem, and the rules that simple domains may stay simple and that improvement is incremental.
- `Accelerated Modeling and Project Rules`: only the rule that team skill and expert access limit how much ceremony the project can sustain.
