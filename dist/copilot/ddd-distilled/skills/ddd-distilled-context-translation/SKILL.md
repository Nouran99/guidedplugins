---
name: "ddd-distilled-context-translation"
description: "Use when another team's model, API payload, event, schema or legacy status codes enter local code, or when an 'anticorruption layer' may translate nothing. Covers translators and their tests. For framework, ORM or HTTP types use ddd-distilled-infrastructure-isolation."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Context translation

The code at the edge of a context: where a foreign model becomes the local one, and where the local one becomes a published contract. This skill is about meaning (another team's terms, codes and shapes). Technology types such as ORM sessions or HTTP requests are `ddd-distilled-infrastructure-isolation`; choosing the relationship is `ddd-distilled-context-mapping`.

## When to use

- A domain function branches on a field or code that belongs to someone else's API.
- A class called an anticorruption layer returns the upstream type.
- A message or webhook payload is passed deep into application code.
- You publish events or responses by serializing internal objects.

## Rules

1. **Translate where meanings differ.** Passing the foreign meaning through makes the local model speak two languages. Check: for each foreign term crossing the edge there is a local term, or a recorded decision to adopt it unchanged.
2. **Protect the local model from foreign language.** Foreign names, codes and shapes stop at the translator. Check: search for the foreign field and code names outside the translator module; there should be no hits.
3. **Keep integration contracts separate from internal models.** An internal refactor must not break the contract, and a contract change must not rewrite the model. Check: contract types live in their own module, and domain classes are not serialized directly onto the wire.
4. **Translate transport and integration data at the boundary, once.** Check: application services receive local commands or local types, not raw payloads.
5. **Test translations at context boundaries.** A mapping is business logic about meaning. Check: each mapping rule has an example-based test, including unknown and missing values.
6. **An anticorruption layer must contain real translation.** A class that forwards upstream types unchanged is a conformist integration with a misleading name. Check: the return type of the layer is a local type.
7. **Do not share domain classes whose meanings differ across the boundary.** The translator produces local types on each side. A Shared Kernel with a small stable overlap, joint ownership and tests is the governed exception (`ddd-distilled-context-mapping`). Check: no domain type imported on both sides of the edge carries a different meaning on each side, and any deliberately shared type is recorded as a Shared Kernel.
8. **When Conformist is the deliberate choice, a translator is not required.** Adopting the upstream model can be cheaper and safer than translating it. Check: the relationship record says Conformist and the local code uses the upstream terms openly.
9. **Fail loudly on a code you do not know.** (Added judgment) A silent default turns a new upstream value into a wrong local fact. Check: the unknown-value path throws or yields an explicit "unrecognized" result that is handled and logged.
10. **Keep the translator free of I/O.** (Added judgment) A pure function from input to local type is testable with plain examples. Check: the translator needs no network, clock or database in its tests.

## Procedure

1. Find the edge: the first place foreign data enters (controller, consumer, client, repository mapping) and the last place local data leaves.
2. List the foreign terms, codes and shapes that cross it, and the local term for each.
3. Create or tighten the translator so it is the only place that knows the foreign names.
4. Change callers inward to take local types.
5. Add example tests for each mapping rule, plus unknown and missing input.
6. Check the relationship record in `ddd-distilled-context-mapping`; update it if the claim and the code now agree or differ.

## Example

```ts
// Before: a domain function knows the carrier's codes
export function isDelivered(update: { stat: string; ts: string }): boolean {
  return update.stat === "DLV" || update.stat === "POD";
}

// After: only this module knows the carrier's vocabulary
// shipping/carrier-translator.ts
export type ShipmentEvent =
  | { kind: "delivered"; at: Date }
  | { kind: "held"; at: Date };

export class UnknownCarrierStatus extends Error {
  constructor(readonly status: string) {
    super(`Unknown carrier status: ${status}`);
  }
}

export function toShipmentEvent(update: { stat: string; ts: string }): ShipmentEvent {
  const at = new Date(update.ts);
  switch (update.stat) {
    case "DLV":
    case "POD":
      return { kind: "delivered", at };
    case "HLD":
      return { kind: "held", at };
    default:
      throw new UnknownCarrierStatus(update.stat);
  }
}

// shipping/carrier-translator.test.ts
it("treats proof of delivery as delivered", () => {
  expect(toShipmentEvent({ stat: "POD", ts: "2025-03-02T10:15:00Z" }).kind).toBe("delivered");
});
it("fails loudly on a status it does not know", () => {
  expect(() => toShipmentEvent({ stat: "???", ts: "2025-03-02T10:15:00Z" })).toThrow(UnknownCarrierStatus);
});
```

Domain code now handles `ShipmentEvent`; adding a carrier status touches one file and one test.

## Anti-patterns

- **Pass-through layer.** Detect: the layer's return type is an upstream type.
- **Payload in the core.** Detect: raw JSON, DTO or schema-generated types appear in domain or application code.
- **Silent default.** Detect: a `default:` branch or fallback that maps unknown input to a valid-looking local value.
- **Serialize the entity.** Detect: published messages or responses are produced by serializing domain objects directly.
- **Translation by habit.** Detect: a mapper between two models that are identical on purpose (a deliberate Conformist).

## Trade-offs and exceptions

- Translation costs code and tests. It earns that cost when the foreign model would corrupt the local language; for a stable, well-understood upstream you have chosen to follow, Conformist is cheaper and safer.
- A translator for a tiny mapping can be a single function; a class hierarchy is not required.
- Added judgment: for an Open Host Service you own, the published contract is another translation target, so the same rules apply outbound.

## Verification

- [ ] Foreign field names and codes appear only in the translator module.
- [ ] Contract types are separate from domain classes.
- [ ] Application services take local types or commands.
- [ ] Each mapping rule, and the unknown-value case, has a test.
- [ ] The layer's name and the context map agree with what the code does.

## Related

`ddd-distilled-context-mapping`; `ddd-distilled-integration-styles`; `ddd-distilled-infrastructure-isolation` for technology types; `ddd-distilled-domain-tests`; `ddd-distilled-relationship-reviewer` to review a diff; `ddd-distilled-translation-builder` to build a translator.

## Source

- `Use Context Mapping`: only the rules to translate where meanings differ, own contracts and protect the local model, and the anti-pattern about shared domain classes with subtly different meanings.
- `Integration Style Rules`: only the rules to keep contracts separate from internal models and to test translations.
- `Architecture and Infrastructure Rules`: only the rule to translate transport and integration data at the boundary and the anti-pattern of reusing transport objects as domain objects.
- `Testing Rules`: only the rule to test context translation.
- `Context Relationship Rules`: only the Conformist and Anticorruption Layer conditions and the anti-patterns about silent conformism and name-only layers.
