---
name: "ddd-context-relationships"
description: "Use when integrating with another team's model, a legacy system or a vendor API, choosing among Shared Kernel, Customer/Supplier, Conformist or Anticorruption Layer, or phasing out a legacy system. The edge between models; for one context's inside use ddd-bounded-contexts."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Context relationships and translation

Owns the edge between two models: pick the relationship deliberately, make it visible in code, and translate at the boundary so foreign terms do not enter the local language. The inside of one context is `ddd-bounded-contexts`; the system's own persistence and transport shapes are `ddd-infrastructure`.

## When to use

- You integrate with a service, library, schema or legacy application whose model is not yours.
- A code review asks "is this an anticorruption layer, or just a client?"
- Two teams share a package, a database or a library and nobody governs it.
- A new system is to replace an old one gradually.
- A vendor's status codes, IDs or field names appear in domain code.

## Rules

1. **Integration relationships must be visible in code.** Check: for each integration, a package, adapter name, document or test states which relationship applies.
2. **Ownership of translation must be explicit.** Check: one named module translates; no caller converts foreign values ad hoc.
3. **Upstream and downstream influence must be reflected in adapters and contracts.** Check: the downstream side's adapter and tests reflect what the upstream promises and what it does not.
4. **Use Shared Kernel only for a small, jointly governed model subset.** Check: owners from both sides are named, and a change needs both.
5. **Use Customer/Supplier when an upstream team commits to downstream needs.** Check: a standing way to request and schedule downstream needs exists, not just goodwill.
6. **Use Conformist only when adopting the upstream model is cheaper than translating it.** Check: the decision is written down; the foreign terms are knowingly accepted in the local core.
7. **Use an Anticorruption Layer when protecting the local model from a foreign or legacy model.** Check: it preserves the local model rather than mirroring the foreign one, and it contains real translation.
8. **Use Separate Ways when integration cost is higher than the shared capability is worth.** Check: the duplication is accepted explicitly.
9. **Use an Open Host Service when a context exposes a stable integration protocol, and a Published Language when contexts need a documented exchange language.** Check: the protocol or language is documented and versioned independently of internals.
10. **Move between relationships deliberately.** From Separate Ways to Shared Kernel only when the overlap is small, valuable and worth coordination; from Shared Kernel to Continuous Integration only when teams are ready to share one model frequently; evolve Open Host Service toward Published Language when interchange stability is needed beyond one service. Check: each move cites the condition it satisfies.
11. **Phase out legacy systems by protecting the new model and replacing responsibilities incrementally through translations.** Check: no big-bang cutover; each step moves one responsibility behind the translation.
12. **Translation is mandatory at context boundaries.** Translate external IDs, statuses and vocabularies explicitly, and map transport representations to local commands or domain inputs. Check: no foreign enum value or ID format appears past the adapter.
13. **Keep foreign model terms out of the local core unless deliberately accepted as conformist, and do not let upstream APIs silently define downstream language.** Check: grep for foreign field names finds only adapter code.
14. **Do not call every integration an anticorruption layer without translation, create accidental shared kernels with no ownership, or treat context mapping as documentation only.** Check: relationship names in code match what the code does.
15. **Before writing boundary code, decide the relationship, the translation strategy, the published language or protocol, and the boundary tests (compact checklist).** Check: all four are stated in the pull request or the adapter's header.

## Procedure

1. Name both contexts and say who owns each side.
2. Describe what the foreign side offers: its terms, IDs, statuses, stability, who can ask it for changes.
3. Choose the relationship with rules 4 to 9. Write the sentence "We are the downstream side of X; we choose Y because Z."
4. Design the translation: foreign term to local term table, failure behavior for unknown values.
5. Put the adapter in a place that names the relationship; keep foreign types inside it (`ddd-translation-builder` for a larger build).
6. Test the translation with boundary tests, including values the foreign side may add later (`ddd-domain-tests`).
7. If replacing a legacy system, list responsibilities in the order they will move and the translation each needs.

## Example

```python
# Before: the legacy status code leaks into domain logic
def renew(policy):
    if policy.legacy_status == "A":   # what does "A" mean here?
        ...

# After: the anticorruption layer is the only code that knows the legacy codes
from enum import Enum

class UnknownLegacyStatus(Exception):
    pass

class CoverageState(Enum):
    IN_FORCE = "in force"
    LAPSED = "lapsed"
    CANCELLED = "cancelled"

_LEGACY_STATUS = {
    "A": CoverageState.IN_FORCE,
    "L": CoverageState.LAPSED,
    "X": CoverageState.CANCELLED,
}

class LegacyPolicyTranslator:
    def to_coverage_state(self, legacy_status: str) -> CoverageState:
        try:
            return _LEGACY_STATUS[legacy_status]
        except KeyError:
            raise UnknownLegacyStatus(legacy_status) from None
```

The failure on an unknown code is a choice: it makes new legacy values visible at the boundary instead of silently mapping them.

## Anti-patterns

- **Mirror layer.** Detect: an "anticorruption layer" whose classes copy the foreign model field for field.
- **Accidental shared kernel.** Detect: a package or database table edited by two teams with no stated owners.
- **Silent conformism.** Detect: the upstream API's names throughout local code with no decision recorded.
- **Foreign vocabulary in the core.** Detect: vendor status codes, IDs or field names past the adapter.
- **Map on the wall only.** Detect: a context map document with no matching package, adapter or test.

## Trade-offs and exceptions

- Conformist is a legitimate choice when translating costs more than adopting the upstream model; the rule is to choose it knowingly, not to avoid it.
- Separate Ways is legitimate when integration costs more than the shared capability is worth.
- A Shared Kernel stays small. If it grows, the cost of coordination rises; revisit it.
- Added judgment: for a one-off integration of a stable, simple foreign value (a currency code), a lightweight value object at the edge is enough; reserve a full layer for models with their own vocabulary and lifecycle.

## Verification

- [ ] Each integration names its relationship in code, documentation or tests.
- [ ] A single module owns translation, and foreign terms do not pass it.
- [ ] Shared kernels have named owners from every side.
- [ ] Unknown foreign values are handled deliberately and tested.
- [ ] The chosen relationship matches what the code actually does.

## Related

`ddd-bounded-contexts` for the inside of a context; `ddd-infrastructure` for the system's own technical shapes; `ddd-map-contexts` for a repository-wide map; `ddd-context-boundary-reviewer` to review a diff; `ddd-translation-builder` to build a translation.

## Source

- `Strategic Design`: only the context-mapping rules.
- `Model Integrity Patterns`
- `Translation at Boundaries`: only the rules on translation between contexts and the anticorruption layer.
