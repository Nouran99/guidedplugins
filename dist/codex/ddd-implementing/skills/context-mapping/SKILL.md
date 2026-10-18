---
name: "context-mapping"
description: "Use when two bounded contexts, a legacy system or a partner exchange data or terms, or when no one can say who translates between them. Decides the relationship, influence and translation ownership. The translator is anticorruption-layer; the outgoing message shape is integration-contracts."
---

# Context mapping

Treats the context map as a design artifact that decides code: for each pair of interacting contexts, which relationship holds, who has influence over whom, and who owns the translation. It stops before building the translator (`$ddd-implementing:anticorruption-layer`) or shaping the outbound message (`$ddd-implementing:integration-contracts`), and it does not decide which context owns a class (`$ddd-implementing:bounded-context`).

## When to use

- A new call, event subscription, file import or shared table connects two contexts or a context and an external system.
- A downstream team keeps absorbing upstream renames, and nobody owns the adaptation.
- A design review asks "who is upstream here?" and the room cannot answer.
- A legacy or partner model is about to be used directly as the local model "to save time".

## Rules

1. **[MUST] Give every context interaction an explicit relationship.** An interaction without a stated relationship is a hidden dependency. Check: for every pair of contexts that call, subscribe or share data, one line states the relationship and the direction of influence.
2. **[MUST] Make translation responsibility visible.** The party that translates is the one that bears the cost of the other's model. Check: each relationship names the translator (a class or module) and the context that owns it.
3. **[MUST] Account for upstream and downstream influence.** The upstream side can change what the downstream side must absorb. Check: the downstream context has a way to insulate itself (a translator, a pinned contract), or the map says it deliberately conforms through a thin wrapper at the boundary (Added judgment; see Trade-offs).
4. **[MUST NOT] Let an external model, partner system or legacy system define the local model.** The local model follows local language and invariants. Check: no local class is named, shaped or constrained after a foreign schema or status code.
5. **[MUST NOT] Let context boundaries exist only in diagrams.** The map must be visible in code. Check: each arrow on the map has a corresponding port, adapter, subscriber or published contract in the repository.
6. **[MUST NOT] Integrate through direct imports of another context's domain classes.** Check: no import of another context's domain package; the integration code lives at the edge.
7. **[Compact checklist] Show the relationship, translation responsibility and influence before sharing data, terms, models or integration code.** The compact rule fixes the order: map first, code second. Check: the pull request that adds an integration also adds or updates the map entry.
8. **[Added judgment] Name the relationship with the vocabulary the team already uses** (for example customer-supplier, conformist, partnership, separate ways). A name is shorthand for who adapts to whom; if the team uses different words, use theirs.
9. **[Added judgment] Keep the map next to the code** (a `docs/context-map.md`, a table in each context's README, or code comments on the adapter) and update it in the same change that adds an integration. A map in a wiki goes stale unnoticed.
10. **[Added judgment] Record the mechanism per arrow** (synchronous call, event subscription, file drop, shared database) and the contract model that crosses. Rule 6 and the database-coupling anti-pattern are easier to spot when each arrow names its mechanism.

## Procedure

1. Name the two parties and which is upstream (its changes force the other to react).
2. Choose and write the relationship in one line, in the team's words, with the direction of influence.
3. Decide who translates: normally the downstream context, in its own adapter, so the upstream vocabulary stops at the edge. If the upstream team publishes a contract for consumers, say so and let the downstream map from it.
4. Choose the mechanism and name the contract model that crosses. Hand inbound translation to `$ddd-implementing:anticorruption-layer` and outbound messages to `$ddd-implementing:integration-contracts`.
5. Write the entry in the map next to the code and link the adapter.
6. Reconstruct the whole map from an unfamiliar repository with `$ddd-implementing:context-map` before changing several integrations at once.

## Example

```ts
// Before: Shipping reaches into Billing's domain to decide whether to ship.
import { Invoice, InvoiceState } from "../../billing/domain/invoice";

export function canShip(invoice: Invoice): boolean {
  return invoice.state === InvoiceState.SETTLED || invoice.state === InvoiceState.WRITTEN_OFF;
}

// After: Shipping states the relationship and owns the translation.
// Context map: Shipping is downstream of Billing and conforms to its published
// "payment-status" contract; Shipping translates in this adapter.
export interface PaymentGate {                       // port, in Shipping's language
  isReleasedForShipment(orderId: OrderId): Promise<boolean>;
}

export class BillingPaymentGate implements PaymentGate {
  constructor(private readonly billing: BillingPaymentStatusApi) {}
  async isReleasedForShipment(orderId: OrderId): Promise<boolean> {
    const status = await this.billing.paymentStatus(orderId.value);   // contract model
    return status.code === "SETTLED" || status.code === "WRITTEN_OFF";
  }
}
```

Shipping now depends on a published status contract and its own port; Billing can rename `InvoiceState` without touching Shipping.

## Anti-patterns

- **The unspoken arrow.** Two contexts talk and no one wrote down who adapts. Detect: an integration class with no entry in the map and no owner.
- **Foreign-led model.** A local class whose fields mirror a partner's schema. Detect: field names or status codes that only make sense in the other system.
- **Wiki-only map.** Detect: the map has boxes that match no package, service or module.
- **Shared-database integration.** One context reads another's tables. Detect: SQL or an ORM mapping that names another context's table.

## Trade-offs and exceptions

- Upstream/downstream influence is a fact, not a flaw, but the source states no exception to rule 4: external, partner and legacy models must not define the local model. Added judgment: a downstream context may still choose to conform to a stable upstream model, only through a thin wrapper at the boundary that keeps foreign types, statuses and schemas out of domain objects, and only when the map says so. Conformity is cheapest when the upstream model is small, stable and close to the local language. Conformity with no wrapper conflicts with rule 4 (Added judgment: only a thin wrapper that keeps foreign types, statuses and schemas out of domain objects is acceptable).
- Small systems may keep the map as a short table in one README. The rule is that it exists and tracks the code, not that it is elaborate.
- The source does not prescribe a catalog of relationship types; the names in rule 8 are common vocabulary, not rules of this rule set.

## Verification

- [ ] Every interaction between contexts has a one-line relationship in the map.
- [ ] Each relationship names the translator and the context that owns it.
- [ ] The direction of influence (upstream, downstream) is stated.
- [ ] Every arrow on the map corresponds to code at the edge.
- [ ] No local class takes its shape from a foreign model.
- [ ] The map entry was added or updated in the same change as the integration.

## Related

`$ddd-implementing:bounded-context` for ownership; `$ddd-implementing:anticorruption-layer` for inbound translation; `$ddd-implementing:integration-contracts` for outbound messages; `$ddd-implementing:context-map` to reconstruct a map; `ddd-implementing-translation-reviewer` to review a diff.

## Source

- `Strategic Design Rules`: only the Context Mapping Is a Design Artifact subsection and the anti-patterns on diagram-only boundaries and direct imports.
- `Context Mapping Is a Design Artifact`
- `Context Integration Rules`: only the anti-pattern on integrating through another context's domain classes.
