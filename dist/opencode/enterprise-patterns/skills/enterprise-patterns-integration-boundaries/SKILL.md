---
name: "enterprise-patterns-integration-boundaries"
description: "Use when code consumes a partner, vendor or legacy system: foreign field names, status codes or SDK types spread through the app, messages used as domain objects, or serialization code with rules in it. Call counts and your own remote API are remote-boundaries."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Integration boundaries

Keeps foreign systems at the edge: one gateway per external resource, translation into the application's own concepts, and no partner shapes in the core. The shape of your own remote API and the number of calls per user action are `enterprise-patterns-remote-boundaries`.

## When to use

- A partner's JSON, XML or SDK types are used outside the file that calls the partner.
- Internal names or structures were chosen to match a partner's payload.
- A message or event class carries business behavior, or a domain object is serialized straight onto a queue.
- A serializer or deserializer contains rules about business state.
- A new integration is being added and you must decide where it lives.

## Rules

1. **Access external systems through clear boundaries.** A boundary is the one place to change when the partner changes. Check: all calls to a given external system pass through one gateway module or class.
2. **Use a Gateway to isolate access to an external resource or subsystem.** Callers should not have to learn the partner's vocabulary. Check: the gateway's interface is in the application's terms ("look up a shipment"), not the partner's ("GET /v2/trk").
3. **Translate partner formats into internal concepts.** Foreign vocabulary in the core means every partner change touches the core. Check: partner field names, codes and enumerations appear only inside the translation code.
4. **Treat integration events and messages as boundary data, not as domain objects.** Messages are for transport and change on the partner's schedule. Check: message classes carry no behavior, and domain objects are not sent as-is.
5. **Do not allow integration convenience to dominate internal design.** Convenience now becomes coupling later. Check: no internal type, name or table exists only because the partner's payload looks that way.
6. **Do not shape internal code around partner API payloads.** Core logic that mirrors a payload breaks when the payload changes. Check: the core would compile and read sensibly if the partner were replaced by another with different field names.
7. **Do not use vendor DTOs across the application.** With vendor types spread through the code, replacing or upgrading the vendor is a cross-cutting edit. Check: vendor SDK and payload types are imported only inside the gateway.
8. **Do not embed business logic in serialization code.** Rules in serializers are invisible and untestable apart from the wire format. Check: (de)serializers map fields and nothing else; decisions about meaning happen after translation.
9. **Make the boundary tolerant, version-aware and failure-aware.** Compact checklist (from `mini.md`): unknown codes map to an explicit "unknown" value, the partner's version is known to the gateway, and partner errors become the application's own error types. Partners add codes and change versions, and the edge must absorb it.
10. **Put the gateway interface on the application's side.** Added judgment: callers depend on the interface so a stub can replace the real gateway in tests (see `enterprise-patterns-testing-by-responsibility`). Tests need to substitute the partner without a network.

## Procedure

1. Grep for the partner's host, SDK package and distinctive field names. List every file that touches them.
2. Define the application-side interface and types for what the application needs, in domain words.
3. Move the calls into a gateway implementing it; add translation functions for statuses, dates, units and identifiers.
4. Replace partner types in callers by the application types, one caller at a time, running the tests after each.
5. Map partner errors and unknown values at the gateway.
6. Add a test of the translation with sample payloads, including an unknown code.

## Example

```ts
// Before: the partner's payload shape and codes leak into business code
const res = await fetch(`${PARTNER}/shipments/${id}`);
const s = await res.json();                       // { trk_no, stat_cd: "DLV", eta_dt: "20260312" }
if (s.stat_cd === "DLV") order.markDelivered(parseEta(s.eta_dt));

// After: a gateway in the application's terms translates once, at the edge
type ShipmentStatus = "in_transit" | "delivered" | "unknown";
interface Shipment { trackingNumber: string; status: ShipmentStatus; estimatedArrival: Date | null }
interface ShipmentTracking { lookup(trackingNumber: string): Promise<Shipment> }

class TrackingUnavailable extends Error {}

function toStatus(code: string): ShipmentStatus {
  switch (code) {
    case "DLV": return "delivered";
    case "TRN": return "in_transit";
    default:    return "unknown";
  }
}

function toDate(yyyymmdd: string | undefined): Date | null {
  if (!yyyymmdd || !/^\d{8}$/.test(yyyymmdd)) return null;
  return new Date(Date.UTC(+yyyymmdd.slice(0, 4), +yyyymmdd.slice(4, 6) - 1, +yyyymmdd.slice(6, 8)));
}

class PartnerShipmentTracking implements ShipmentTracking {
  constructor(private baseUrl: string) {}
  async lookup(trackingNumber: string): Promise<Shipment> {
    const res = await fetch(`${this.baseUrl}/shipments/${encodeURIComponent(trackingNumber)}`);
    if (!res.ok) throw new TrackingUnavailable(`partner answered ${res.status}`);
    const body = await res.json();
    return { trackingNumber: body.trk_no, status: toStatus(body.stat_cd), estimatedArrival: toDate(body.eta_dt) };
  }
}

// business code: const shipment = await tracking.lookup(n); if (shipment.status === "delivered") order.markDelivered(shipment.estimatedArrival);
```

Timeouts and retries for the partner call are a separate concern (`release-it`); the point here is that `"DLV"` and `eta_dt` exist in one file only.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Vendor DTO everywhere | SDK types in services, models or signatures | Gateway plus internal types |
| Payload-shaped core | Internal fields named like the partner's abbreviations | Rename to domain terms; translate at the edge |
| Message as domain object | Domain class serialized onto a queue, or message class with behavior | Separate message type; map both ways |
| Rule in the serializer | `if` on business state inside (de)serialization | Move the rule after translation |
| Raw codes in conditions | `stat_cd === "DLV"` outside the gateway | Translate to an internal enumeration |
| Boundary with no failure story | Partner errors leak as raw exceptions | Map to application error types |

## Trade-offs and exceptions

- A stable, widely understood standard (a date format, a well-known protocol type) does not need wrapping; the rule targets partner- and vendor-specific shapes.
- One-off scripts that call a partner once do not need a gateway; the rule is for integrations that the application depends on.
- When the partner's model is genuinely the better one, adopting its concepts deliberately is a design choice; the failure is letting it happen by convenience.
- Message-broker semantics, ordering and delivery guarantees belong to `data-intensive-apps`.

## Verification

- [ ] Partner host, SDK and field names appear in one module only.
- [ ] The gateway interface speaks the application's language.
- [ ] Unknown partner codes map to an explicit value.
- [ ] Message types carry no behavior and are not domain objects.
- [ ] No business rule exists in serialization code.
- [ ] A translation test with sample payloads passes.

## Related

`enterprise-patterns-remote-boundaries` for your own remote API; `enterprise-patterns-testing-by-responsibility` for stubs; `enterprise-patterns-base-patterns` for Mapper; `enterprise-patterns-integration-reviewer` to review a diff.

## Source

- `Offline and Integration Rules`
- `Session State and Base Pattern Index`: only the Gateway entry.
- `Review Rules`: only the finding about missing translation between internal and remote models.
