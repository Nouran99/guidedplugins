---
name: "clean-architecture-boundary-economics"
description: "Use when deciding whether, where and how heavy a boundary should be, when a shortcut is proposed under deadline pressure, or when a compromise is unavoidable. Shaping a justified port is ports-and-gateways; code already crossing a process or device edge is service-and-device-edges."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Boundary economics

Owns the question "is this boundary worth its cost, and which kind". Every other skill in the plugin assumes a boundary has been justified; this one can say it should not exist. How to shape a justified port is `clean-architecture-ports-and-gateways`; code that already crosses a process, network or device edge is `clean-architecture-service-and-device-edges`.

## When to use

- You are about to add a port, a layer, a package split, a queue or a separate service.
- Someone proposes skipping a boundary to hit a date, or proposes a boundary for a three-endpoint tool.
- A rule of this plugin cannot be followed in this case and you need to record the compromise.
- A diagram or package name is the only thing "enforcing" a boundary.
- A recurring cost (cross-team edits, slow releases) suggests the architecture needs revisiting.

## Rules

1. **Treat architecture as a way to keep the cost of future change proportional to the scope of change.** `[MUST]` Check: you can state the future change this boundary makes cheaper.
2. **Do not let the noise of urgent feature work push out architectural work that matters.** `[MUST NOT]` When a shortcut would skip architecture, state the future change, test, replacement or operational cost before accepting it (compact rules). Check: the cost sentence exists in the plan or the review note.
3. **Keep framework, database, delivery-mechanism and deployment-topology choices open until evidence justifies committing to one.** `[MUST]` Check: you can say which decision is being deferred and what evidence would settle it.
4. **Choose boundaries by volatility, policy importance, substitution value, testability and cost.** `[MUST]` Check: write one line per factor for the boundary in question (see the example).
5. **Do not build a boundary that costs more than the option value it keeps.** `[MUST NOT]` Check: for a boundary with no plausible second implementation, no volatile detail and no test benefit, the entry says "do not build".
6. **Pick one of the boundary kinds and choose the lightest that preserves the needed independence.** `[MUST]` A boundary may be a source boundary, a deployment boundary, a process boundary, a service boundary or a partial boundary. Check: you considered the next lighter kind and can say why it is not enough.
7. **Use a partial boundary when a full deployment or runtime split is too expensive but future separation is valuable.** `[MUST]` The condition is part of the rule: without both halves, a full boundary or none may be the better choice. Check: the interface and the request and response models exist, so the core depends on them and not on the detail (`Keep Boundaries Visible`). Added judgment: this plugin's working definition of a partial boundary also keeps the implementation in the same module, as in the example below; the source does not define the term further.
8. **Keep the concerns of building, shipping, running and maintaining the system visible, and never let them decide business policy.** `[MUST]` Check: operational choices appear in infrastructure code and notes, and no business branch depends on them.
9. **Make the boundary enforceable through package structure, tests, dependency rules or build constraints.** `[MUST]` A diagram, a service split, a package name or a shared `common` folder is not enough (compact rules). Check: a test or build rule fails when the boundary is crossed (`/clean-architecture:enforce-boundaries`).
10. **Revisit the architecture when the shape of change, team ownership, deployment needs or operational constraints reveal rising cost.** `[MUST]` Check: there is a named trigger and a place where the decision is recorded.
11. **Settle "introduce a boundary sooner" against "do not overbuild" in a fixed order.** Added judgment: the source says both ("when in doubt, introduce a boundary sooner" and rule 5). Apply rules 4 and 5 first. If doubt remains and the cheapest partial boundary costs little, take it; if the next step is a new package, process or service, require evidence.
12. **When a compromise is forced, keep it at the outermost layer possible, document the violation in code comments or review notes, avoid normalizing it into the core, and preserve a future path to separation.** `[MUST]` Prefer the design that lowers coupling over the long run to the one that is merely quickest now. Check: a note names the rule bent, the place, the reason and the exit.
13. **Write the compromise note with four fields.** Added judgment: rule bent; where; why now; exit (what removes it, and who revisits it). Check: a stranger could remove the compromise from the note alone.

## Procedure

1. State the decision: "Should X be behind a boundary of kind K?"
2. Score the five factors in rule 4 in one line each, and name the cheapest alternative.
3. Apply rules 5, 6 and 11; write the verdict: build, build partially, defer with a named trigger, or do not build.
4. If building, decide how it is enforced (rule 9) and which sibling skill shapes it (`clean-architecture-ports-and-gateways`, `clean-architecture-component-grouping`).
5. If a rule must be bent, write the compromise note (rules 12 and 13) where the code or the review will show it.
6. Record when the decision should be revisited (rule 10).

## Example

```text
Decision: put the system clock behind a port in the loan-renewal use case?
  volatility          medium (tests need to control it)
  policy importance   high (due dates are the rule being decided)
  substitution value  high (tests need fixed dates)
  testability         without a port: wall-clock tests that fail at midnight
  cost                one parameter
Verdict: lightest boundary. Pass `today: date` into the use case from the adapter. No Clock interface yet.
  Added judgment: passing today as a value keeps the call out of the core, so the source's rule against
  calling volatile details directly is still met.
Revisit when: a second use case needs the time, or a time-zone policy appears.
```

```java
// A partial boundary: the interface and models exist and the use case depends only on them,
// but there is one implementation, in the same module, invisible outside it.
package com.example.permits.reports;

public interface PermitReportRenderer {              // owned by the use case
    byte[] render(PermitReport report);
}

final class CsvPermitReportRenderer implements PermitReportRenderer {   // package-private
    @Override
    public byte[] render(PermitReport report) { /* ... */ return new byte[0]; }
}
```

```java
// BOUNDARY COMPROMISE: this use case reads System.getenv("REGION") directly.
// Rule bent: core code must not read configuration.
// Why now: the region selects a legal text block and the settings port is not built yet (PERMIT-212).
// Exit: add `Region region` to RenewRequest, set it in main, delete this call. Revisit: next quarter.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Interface for everything | An interface for each class, each with one implementation and no volatile detail | Remove the ones that fail rule 4 |
| Layer cake | Four layers for a handful of endpoints with no rules | Collapse to the lightest boundary that protects what matters |
| Early service split | A separate service created before any independent reason to change or deploy | Keep one deployable with an internal boundary |
| Diagram-only boundary | A picture or a folder name is the whole enforcement | Add a test or build rule |
| Silent shortcut | A violation with no note | Add the four-field note, or fix it |
| Permanent temporary | A compromise with no exit or no trigger | Add the exit and a revisit date |
| Panic skip | Architecture dropped because "the feature is urgent" with no cost stated | State the cost before accepting the shortcut |

## Trade-offs and exceptions

- The source explicitly permits partial boundaries and asks for the lightest boundary. For a one-off script a boundary may have no option value at all; say that and build none.
- Rules 4 and 5 are judgments, not formulas. The five factors come from the source; the one-line-per-factor format in the example is this plugin's own, and it is a prompt for a conversation, not a score.
- Highly volatile external dependencies (a vendor API that changes often) justify a thicker boundary than stable ones.
- Added judgment (the source says to reject the conflicting change and propose a cleaner alternative; this plugin defers to the code owner): if the person owning the code instructs a violation, name the rule bent, propose the cleaner alternative once, then follow the instruction and write the compromise note (rules 12 and 13); do not argue the decision into a stalemate.

## Verification

- [ ] The decision states the future change it protects or the reason it is not built.
- [ ] All five factors were considered and the lighter alternative named.
- [ ] A boundary that was built is enforced by structure, a test or a build rule.
- [ ] Every compromise sits at the outermost layer possible and carries a note with an exit.
- [ ] Deferred decisions have a named trigger.
- [ ] No boundary was added for symmetry or habit.

## Related

`clean-architecture-ports-and-gateways` to shape a justified port; `/clean-architecture:plan` to include these decisions in a plan; `/clean-architecture:enforce-boundaries` for enforcement; `clean-architecture-boundary-cost-reviewer` to review a diff; `/clean-architecture:mode-boundary-budget` for a session that justifies every boundary.

## Source

- `Architecture Economics and Priority`
- `Boundary Cost, Deployment, and Operations`
- `Keep Boundaries Visible`
- `When Tradeoffs Are Necessary`
- `Final Instruction`
