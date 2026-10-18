---
name: "right-sizing"
description: "Use when a change adds repositories, factories, aggregates or services to simple CRUD, when DDD vocabulary is applied without a model change, or when deciding how much modeling an area deserves. Brake on ceremony; for the core use $ddd:distillation, for which layer decides $ddd:layers."
---

# Right-sizing

Owns the brake: Domain-Driven Design here means building around business concepts and protecting invariants, not adding layers, patterns or vocabulary. This skill decides how much of the rule set a given change earns, and recognizes Fake DDD. Locating the core domain across the system is `$ddd:distillation`; Smart UI as a layering choice is also in `$ddd:layers`.

## When to use

- A change adds a repository, factory, domain service or aggregate to a table of settings, tags or lookups.
- A "domain" layer exists with the same fields as the database and no behavior.
- Classes were renamed to DDD terms (`Service`, `Aggregate`, `Factory`) without any rule moving into them.
- You are unsure whether a feature deserves a rich model or a plain handler.
- A pull request is large because patterns were applied "for consistency".

## Rules

1. **When uncertain, prefer the option that makes the domain model clearer.** Not the shorter, the more generic or the more framework-friendly one. Check: the alternative chosen can be defended in a sentence about the domain.
2. **Do not optimize primarily for fewer files, generic reuse, CRUD convenience, ORM convenience, delivery-layer convenience, framework conventions or short-term speed at the cost of model clarity.** Check: none of these is the stated reason in the pull request for a model decision.
3. **Do not add layers for ceremony, rename service classes to sound sophisticated, or wrap CRUD in verbose abstractions.** Check: each new layer or wrapper carries a rule or a translation.
4. **Do not turn every concept into an aggregate or introduce every DDD pattern everywhere.** Check: each aggregate names its invariant; each repository serves a root.
5. **Do not add repositories, factories or services without a real domain need (Fake DDD), and do not rename CRUD layers without changing the model.** Check: remove the new class; if the code still works with nothing lost, it was ceremony.
6. **Do not over-model simple supporting subdomains; simplify aggressively outside the core domain.** Check: supporting areas use the simplest design that works (`$ddd:distillation`).
7. **Use Smart UI only for simple applications** where rich domain abstraction, reuse, integration and deep business rules are not important (`$ddd:layers`). Check: no second entry point needs the same rule.
8. **Do not leave a behavior-rich domain as entities with only fields and setters.** Ceremony and passivity are two failures of the same rule set. Check: in a complex area, the rules are in the model.
9. **Do build code around business concepts, express rules in domain language, make context boundaries explicit, protect invariants with the model and translate explicitly across boundaries.** Check: each of these is visible in any area claimed to be modeled.
10. **Do not use patterns that make the domain language harder to see, DSLs or frameworks that make simple rules harder to verify, or large-scale structures that prevent model evolution (Pattern-Driven Obscurity).** Check: a reader sees the business rule faster after the change than before.
11. **Added judgment, tiers.** Decide the tier per area, state it in the plan, and revisit it when a rule appears.
    - Tier 0, plain CRUD: no business rules beyond required fields and uniqueness. Use the framework's normal path.
    - Tier 1, light: a few rules. Named types for meaningful values, invariants in constructors, domain words in names.
    - Tier 2, rich: lifecycle, invariants across objects, or rules that change often. Entities with transitions, aggregates, repositories for roots, factories where creation has rules, specifications.
    - Tier 3, strategic: several models meet or the area is the core. Add explicit contexts, relationships and translation (`$ddd:context-relationships`).

## Procedure

1. State what business rule the change must protect or express. If there is none, the area is Tier 0.
2. For each proposed DDD element (repository, factory, aggregate, service, layer), write the real need it satisfies. Drop those without one.
3. Check whether the area is core, supporting or generic (`$ddd:distillation`); simplify supporting and generic areas.
4. Pick the tier (rule 11) and the smallest set of elements that protects the rules at that tier.
5. If rules exist but live in handlers (the opposite failure), move them into the model rather than adding more layers (`$ddd:layers`).
6. Record the decision and the trigger that would change it, for example "revisit if cancellation rules appear".

## Example

```python
# Before: ceremony around a lookup table; every class only forwards
class TagFactory:
    def create(self, name): return Tag(name)

class TagRepository(ABC):
    @abstractmethod
    def add(self, tag): ...

class TagDomainService:
    def create_tag(self, name):
        tag = TagFactory().create(name)
        self.repository.add(tag)

class CreateTagCommandHandler:
    def handle(self, command):
        self.service.create_tag(command.name)

# After: a lookup table is a lookup table
def create_tag(db, name: str) -> Tag:
    cleaned = name.strip().lower()
    if not cleaned:
        raise ValueError("a tag needs a name")
    return db.tags.get_or_create(name=cleaned)
```

A rental with pickup, return and fee rules earns something different: an entity with transitions (`$ddd:entities`), a repository for its root (`$ddd:repositories`) and a factory only if creation itself has rules (`$ddd:factories`). The pure-forwarding service and handler stay ceremony in both cases. The difference is the rule the model must protect.

## Anti-patterns

- **Fake DDD.** Detect: classes renamed to DDD terms where the code moved nothing; interfaces with one implementation and no rule.
- **Pattern everywhere.** Detect: every table has an entity, repository, factory and service.
- **Over-modeled periphery.** Detect: a notification-preferences screen modeled more richly than the pricing logic.
- **Pattern-named domain.** Detect: types named after patterns (`OrderStrategyFactory`) instead of business concepts.
- **Passive model by default.** Detect: the opposite failure, a rule-heavy area with data classes and procedural services.

## Trade-offs and exceptions

- The rule set is explicit that simple applications may use Smart UI and that supporting subdomains deserve simpler models; this is the rule set applying itself, not a loophole.
- Added judgment: a trivial area can become core or complex later. Migrate when a rule appears; do not pre-build.
- When a team already uses a pattern consistently, follow the repository convention (priority 2 in `$ddd:principles`) unless it is the problem being fixed.

## Verification

- [ ] The business rule each new element protects is stated.
- [ ] Every new repository serves a root; every factory carries creation rules; every aggregate names an invariant.
- [ ] Supporting and generic areas stayed simple.
- [ ] No class exists only to forward calls.
- [ ] The tier of the touched area is recorded with a trigger for revisiting it.

## Related

`$ddd:distillation` for where effort belongs; `$ddd:layers` for Smart UI and the application layer; `$ddd:pattern-fit` for imported patterns; `ddd-ceremony-reviewer` to review a diff; `$ddd:mode-terse` when the answer must stay short.

## Source

- `What DDD Means in This Repository`
- `Primary Directive`
- `Forbidden Patterns`: only the Fake DDD, Pattern-Driven Obscurity and Passive Domain Model families.
- `Layered Architecture and Smart UI`: only the rule on when Smart UI is acceptable.
