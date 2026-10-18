---
name: "anticorruption-layer"
description: "Use when code consumes a legacy system, vendor or partner API, or another context's model, and foreign names, status codes or schemas appear in local domain code. Builds and tests the inbound translation. Outbound messages are integration-contracts; choosing the relationship is context-mapping."
---

# Anticorruption layer

Owns inbound translation: a foreign model enters, a local model comes out, and nothing foreign is visible past the translator. It does not decide the relationship between the two sides (`$ddd-implementing:context-mapping`), shape what the local context publishes (`$ddd-implementing:integration-contracts`), or shape what a UI receives (`$ddd-implementing:client-representations`).

## When to use

- A local entity has fields, enum values or status codes whose meaning is defined by another system.
- A client class generated from a partner's schema is passed into domain code.
- A legacy database, SOAP or CSV feed is read directly by a use case.
- A foreign record has to be turned into something the local model can reason about.

## Rules

1. **[MUST] Use an anticorruption layer when integrating with legacy systems or foreign models.** The layer is the place where the other model stops. Check: every call into the foreign system goes through one named adapter.
2. **[MUST] Translate foreign language into the local context's language.** The local model keeps its own words, even where the foreign one differs. Check: nothing past the translator uses a foreign term; the translator's output uses the ubiquitous language.
3. **[MUST] Keep foreign schemas and statuses out of local domain objects.** Check: no domain class has a field typed as a foreign DTO, a raw status code or a foreign enum.
4. **[MUST] Own the translation explicitly.** An implicit mapping scattered across callers has no owner. Check: one class or module per foreign system is named as the translator and appears in the context map.
5. **[MUST NOT] Let an external model, partner system or legacy system define the local model.** Check: a local invariant would still make sense if the foreign system were replaced.
6. **[MUST] Keep technical transformation, serialization, transport and persistence mapping outside the domain model.** Check: no JSON, XML or SQL shape is built or parsed inside an entity, value object or domain service.
7. **[MUST] Test anticorruption and translation layers explicitly.** The translator is where meaning can be silently lost. Check: a test per foreign value that matters, including values the local model has no word for.
8. **[Added judgment] Give the layer a narrow port written in local terms** (`MembershipDirectory.statusOf(memberId)`), and put the foreign client behind it. Check: the port's signature contains no foreign type.
9. **[Added judgment] Decide what an unknown foreign value means and make it loud.** Mapping an unrecognized code to a default hides drift. Check: an unknown code either raises a translation error or maps to an explicit local "unknown" outcome that callers handle.
10. **[Added judgment] Translate in one direction per class.** A class that maps foreign to local and local to foreign grows two reasons to change. Check: inbound and outbound mappers are separate.

## Procedure

1. List every foreign type that reaches domain code (imports, fields, parameters, return types).
2. For each, write the local concept it stands for in the ubiquitous language. If none exists, that is a modeling question for the team, not a mapping detail.
3. Define the port in local terms, then write the translator that implements it and is the only code that imports the foreign types.
4. Convert foreign values to local value objects or enums at the translator's output; move foreign status logic into the translator's table.
5. Write translation tests: one case per mapped value, one for each unknown value, one for missing or malformed fields.
6. Replace the direct callers one at a time; run the tests after each.
7. Add the translator to the context map entry (see `$ddd-implementing:context-mapping`). Use `ddd-implementing-acl-builder` for a large job.

## Example

```python
# Before: the legacy CRM's codes leak into the domain
class Member:
    def __init__(self, crm_row: dict):
        self.stat = crm_row["cust_stat"]          # "A", "S", "X"
        self.tier = crm_row["bal_cd"]              # "01", "02"
    def can_borrow(self) -> bool:
        return self.stat == "A" and self.tier != "02"

# After: a port in local language, a translator that owns the codes
from enum import Enum

class Standing(Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    CLOSED = "closed"

class UnknownCrmStatus(Exception):
    """The legacy CRM returned a status code the translator does not know."""

class MembershipDirectory:                         # port, local vocabulary only
    def standing_of(self, member_id: str) -> Standing: ...

class LegacyCrmMembershipDirectory(MembershipDirectory):   # the anticorruption layer
    _STANDING_BY_CODE = {"A": Standing.ACTIVE, "S": Standing.SUSPENDED, "X": Standing.CLOSED}

    def __init__(self, crm_client):
        self._crm = crm_client

    def standing_of(self, member_id: str) -> Standing:
        row = self._crm.fetch_customer(member_id)
        try:
            return self._STANDING_BY_CODE[row["cust_stat"]]
        except KeyError:
            raise UnknownCrmStatus(member_id, row.get("cust_stat"))   # loud, not defaulted
```

The domain asks for a `Standing`; only the translator knows that `"X"` means closed.

## Anti-patterns

- **Foreign DTO in the domain.** A generated client type used as a field or parameter. Detect: imports of a vendor or partner package under `domain/`.
- **Status-code logic in the domain.** `if member.stat == "A"`. Detect: string or numeric literals that only a foreign system defines.
- **Translator in every caller.** The same mapping repeated at five call sites. Detect: duplicate code tables across use cases.
- **Silent default.** An unknown value becomes `ACTIVE`. Detect: a mapping with a catch-all `else` and no test for it.
- **Domain-sounding mapper.** A class named after a domain concept whose body is field copying. Detect: a "service" with no decisions, only getters and setters across two schemas.

## Trade-offs and exceptions

- Added judgment, not an exception the source gives: a foreign model that is small, stable and already uses the local language may be adopted with a thin wrapper, and the relationship should then say that the local context conforms (see `$ddd-implementing:context-mapping`). The source still forbids foreign schemas and statuses inside domain objects, so the wrapper is the boundary, not a pass-through. Conformity with no wrapper conflicts with rule 5; only a thin wrapper that keeps foreign types, statuses and schemas out of domain objects is acceptable.
- The source places the layer where legacy or foreign models are integrated; it does not require one between two well-governed contexts that publish a contract. Then the downstream side still translates from the contract model, which is `$ddd-implementing:integration-contracts` seen from the receiving end.
- The test in rule 7 should not call the live foreign system. Added judgment: use recorded sample payloads.

## Verification

- [ ] Only the translator imports the foreign types.
- [ ] No domain class holds a foreign status, enum or DTO.
- [ ] The port's signature is entirely in local terms.
- [ ] An unknown foreign value is handled deliberately and tested.
- [ ] Translation tests exist for each mapped value.
- [ ] The translator appears in the context map.

## Related

`$ddd-implementing:context-mapping` for the relationship and ownership; `$ddd-implementing:integration-contracts` for the outbound mirror; `$ddd-implementing:domain-tests` for the test layer; `ddd-implementing-translation-reviewer` to review a diff; `ddd-implementing-acl-builder` to build one.

## Source

- `Context Integration Rules`: only the Anticorruption Layer subsection.
- `Anticorruption Layer`
- `Context Mapping Is a Design Artifact`: only the rule that external models, partner systems and legacy systems must not define the local model.
- `Domain and Transformation Service Rules`: only the rule that technical transformation, serialization, transport and persistence mapping stay outside the model.
- `Testing Rules`: only the rule to test anticorruption and translation layers explicitly.
