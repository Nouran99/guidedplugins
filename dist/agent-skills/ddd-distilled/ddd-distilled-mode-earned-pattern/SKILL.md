---
name: "ddd-distilled-mode-earned-pattern"
description: "Tags every tactical pattern it introduces with the reason it earns its cost, defaults to plain code, and lists the patterns considered and rejected. Run only when the user asks for it by name."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "manual"
  kind: "mode"
---
Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.


# Earned-pattern mode

You make the cost of ceremony visible. A tactical pattern appears in your output only with its reason attached, and plain code is the default.

## Response shape

1. Write the plainest code that honestly models the problem first.
2. When you introduce a value object, entity, aggregate, domain event, translator or repository, tag it inline in a comment or in the prose: `[pattern: earned by <trigger>]`. Use the book's triggers: a primitive hiding meaning (value object), identity and lifecycle (entity), an invariant across objects (aggregate), a meaningful business fact someone reacts to (event), a foreign model with different meaning (translator). Added judgment: an aggregate or entity that an application service must load and save is the trigger for a repository.
3. End with one line `Considered, not used:` listing the patterns you weighed and left out, each with a phrase of why (for example "aggregate: no invariant across rows").
4. If you cannot name a trigger, do not add the pattern. If the user's request already assumes one, add it and tag it `[pattern: requested]`.

## Always

- Move up only when a rule forces it, and say what rule appeared. Added judgment: the usual order is plain data, value objects, an entity with guarded transitions, an aggregate, events; a rung may be skipped when its own trigger is present (a business fact someone reacts to can need an event without an aggregate).
- Mark any heuristic of your own as added judgment, separate from the book's triggers.
- Say so when the code needs a pattern the area has not earned yet, and suggest the cheaper form that holds the rule today.

## Never

- Add an aggregate, event, repository or translator with no trigger.
- Dismiss a pattern whose trigger is present because it feels heavy; under-modeling a complex rule is also a failure.
- Present the tags as decoration. Each must be checkable against the code.

## Unchanged

Destructive-action confirmations, failing test output and security warnings are shown in full, exactly as in your default behavior.

## Source

- `Practicality Rules`
- `Tactical Pattern Rules`
- `Primary Directive`
