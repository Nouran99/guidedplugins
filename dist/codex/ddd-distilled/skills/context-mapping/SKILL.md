---
name: "context-mapping"
description: "Use when two contexts or systems must integrate and the relationship (Partnership, Shared Kernel, Customer/Supplier, Conformist, Anticorruption Layer, Open Host Service, Published Language, Separate Ways) is unstated or wrongly named. Not for translator code ($ddd-distilled:context-translation)."
---

# Context mapping

Make the relationship between contexts explicit, pick it on purpose, and keep its name honest. The relationship is a decision about ownership and about who pays for translation; the translator code itself is `$ddd-distilled:context-translation`, and the inside of one context is `$ddd-distilled:bounded-contexts`.

## When to use

- A new integration is being added and nobody has said who is upstream, who adapts, or who pays.
- An integration is called an "anticorruption layer", "shared kernel" or "partnership" and you doubt it.
- Two teams argue about changes to a shared model or a shared library.
- You are drawing or reviewing a context map.

## Rules

1. **Make context relationships explicit.** An unnamed relationship defaults to whichever side shouts loudest. Check: every integrated pair appears in a written map with direction (which is upstream) and relationship type.
2. **Choose each relationship deliberately, with a reason.** The choice decides who changes when something changes. Check: next to each relationship, one sentence says why it fits this pair.
3. **Partnership only when the teams can coordinate closely and share the planning burden.** If one side cannot attend the planning, it is not a partnership. Check: joint planning actually happens.
4. **Shared Kernel only for a small stable overlap, with joint ownership and tests.** A larger or looser kernel becomes the model both sides are afraid to touch. Check: the shared code is small, has an owner on each side, and has tests both sides run. Without that governance choose another relationship.
5. **Customer/Supplier when the upstream team can plan for downstream needs.** Check: downstream requests reach the upstream plan and receive an answer.
6. **Conformist when adopting the upstream model is cheaper and safer than translating it.** Check: the local code openly uses the upstream terms, and the team has accepted that upstream changes arrive unfiltered.
7. **Anticorruption Layer when a foreign model would corrupt the local language.** Check: a real translator exists; see `$ddd-distilled:context-translation`.
8. **Open Host Service when many clients need a stable protocol into one context.** Check: one documented protocol serves all clients rather than a custom endpoint per client.
9. **Published Language when several systems need a documented interchange model.** Check: the interchange schema is documented. (Added judgment) It is also versioned independently of the internal model, and Open Host Service and Published Language often travel together; either can appear alone.
10. **Separate Ways when integration costs more than the shared capability is worth.** Check: both the cost and the benefit are written down, and the answer is "do not integrate".
11. **Treat a Big Ball of Mud as a context to contain and translate around, not as a model to spread.** Check: no new code depends on its internal types.
12. **Own integration contracts deliberately, translate where meanings differ, and protect the local model from foreign language.** Check: for each edge, a named owner of the contract.
13. **Do not claim independent modeling while conforming silently.** Do not use a Shared Kernel without governance. Do not call an integration an anticorruption layer when no translation exists. Check: each claimed relationship matches what the code does (see Procedure).

### Quick table

| Relationship | Choose it when | What the code should show (Added judgment) |
| --- | --- | --- |
| Partnership | Teams coordinate closely and share planning | Joint releases or a shared plan, not just a meeting series |
| Shared Kernel | Small, stable, jointly owned and tested overlap | A tiny shared module with owners on both sides and shared tests |
| Customer/Supplier | Upstream can plan for downstream needs | Downstream requirements visible in upstream's backlog |
| Conformist | Adopting upstream's model is cheaper and safer | Upstream terms used directly in local code, on purpose |
| Anticorruption Layer | A foreign model would corrupt local language | A translator with tests; upstream types do not leave it |
| Open Host Service | Many clients need one stable protocol | One protocol, documented, versioned |
| Published Language | Several systems need a documented interchange | A schema separate from any internal model |
| Separate Ways | Integration costs more than it returns | No integration; the cost of duplicating a small capability is accepted |
| Big Ball of Mud | A tangle exists | Contained behind a boundary, nothing new built on its types |

## Procedure

1. List the contexts and every integration point between pairs: calls, shared tables, files, queues, shared libraries.
2. For each pair, state which side is upstream.
3. Classify the relationship from what the code does, before looking at what it is called.
4. Compare with the name the teams use. Silent conformism, a name-only anticorruption layer, or an ungoverned kernel is a finding.
5. For each finding choose: change the relationship, or rename it so it is honest.
6. Record the map where both teams read it.

## Example

```text
The map as the teams describe it. A -> B means A is upstream of B.

Pricing  -> Booking    Customer/Supplier   Pricing plans quarterly from Booking's requests.
Carrier  -> Booking    Anticorruption Layer in booking/carrier   (carrier codes stop there)
Booking  -> Invoicing  Open Host Service with Published Language (BookingConfirmed v2 schema)
Legacy   -- Booking    Contained: nothing new built on Legacy types
Booking  -- Marketing  Separate Ways: Marketing keeps its own small list; duplication costs less than integrating

Findings when the claims are compared with the code:
  Booking / Carrier: called "ACL", but CarrierAcl.track() returns the carrier's own
    response type. In practice this is Conformist. Either translate or rename it.
```

The last finding is the useful part: the map is only worth having if it is compared with the code.

## Anti-patterns

- **Silent conformist.** The team says its model is independent while its types are the upstream's. Detect: upstream type names appear in the local domain code.
- **Ungoverned Shared Kernel.** Detect: a shared library with no named owners and tests that only one side runs.
- **Name-only anticorruption layer.** Detect: the "ACL" class returns what it was given.
- **Everything integrated.** Detect: no pair in the map is marked Separate Ways, so integration cost was never weighed.
- **Mud spread.** Detect: new modules import the legacy tangle's internal types.

## Trade-offs and exceptions

- Conformist is a legitimate choice when it is cheaper and safer; translating by habit adds cost for no protection.
- Separate Ways is a legitimate outcome, not a failure to integrate.
- A map is a snapshot. Revisit it when teams reorganize or a vendor changes its model.
- A pair of contexts can interact at several points; it is acceptable (Added judgment) to record a different relationship per integration point when the code really behaves differently at each.

## Verification

- [ ] Every integrated pair appears in a written map with direction.
- [ ] Each relationship has a one-sentence reason.
- [ ] Each claim (kernel, anticorruption layer, partnership) matches the code.
- [ ] No Shared Kernel lacks owners on both sides and shared tests.
- [ ] Contained legacy contexts have no new dependents.

## Related

`$ddd-distilled:context-translation` for the translator; `$ddd-distilled:integration-styles` for the mechanism; `$ddd-distilled:map-contexts` to discover the as-found map; `ddd-distilled-relationship-reviewer` to review a diff.

## Source

- `Use Context Mapping`
- `Context Relationship Rules`
- `Strategic Rules`: only the anti-patterns about shared domain classes and boundaries ignored in code.
