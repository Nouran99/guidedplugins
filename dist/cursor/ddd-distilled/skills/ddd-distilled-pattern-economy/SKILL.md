---
name: "ddd-distilled-pattern-economy"
description: "Use when deciding which pattern a concept needs (record, value object, entity, aggregate, service, event) or when a module is over- or under-modeled. Shaping a chosen one: ddd-distilled-value-objects, ddd-distilled-entities, ddd-distilled-aggregates. Area go or no-go: ddd-distilled-adoption-fit."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Pattern economy

Inside an area that has earned modeling, pick the least expensive pattern that honestly models each concept, and move up only when a rule appears that the cheaper form cannot hold. This skill chooses per concept, before a pattern is settled; the area-level decision is `ddd-distilled-adoption-fit`, and once a pattern is chosen its own rules are in `ddd-distilled-entities`, `ddd-distilled-value-objects`, `ddd-distilled-aggregates` and `ddd-distilled-domain-events`.

## When to use

- You are about to create an aggregate, event, repository, or translator and want to be sure it is needed.
- A module has more classes than rules, or a complex rule lives in a bag of fields.
- A reviewer says "this is over-engineered" or "this is just a data holder".
- A simple module is growing rules, and you must decide when to strengthen it.

## Rules

1. **Use the least expensive pattern that honestly models the problem.** Every pattern costs code, tests and reading time. Check: for each pattern in the change, say what would break without it.
2. **Let simple domains use simple services and data structures.** Check: a create-read-update-delete area has no aggregates, events or translators.
3. **Strengthen the model once invariants, lifecycle and language complexity rise.** Check: the trigger for each strengthening is named (a rule appeared, a state machine emerged, a word became disputed).
4. **Prefer incremental improvement over massive design overhauls.** Check: the change moves one concept up one step, not a module up five.
5. **Decide whether each concept is an entity, value object, aggregate, service, repository or event, and then choose the smallest tactical pattern that fits.** Check: the decision is written down with its reason.
6. **Use each pattern only for its trigger.** Entities when identity and lifecycle matter, value objects when a primitive hides meaning, aggregates only where invariants require a consistency boundary, domain events for meaningful facts. Check: each pattern in the diff has its own trigger, not a shared "this is DDD" reason.
7. **Do not dismiss DDD because not every module needs it.** **Do not over-model a generic subsystem.** **Do not introduce aggregates and events before knowing why.** Check: the decision is per concept, and the "why" exists in words.
8. **Avoid service-centric fake DDD, full tactical DDD in trivial modules, giant shared domain packages, and technical names that replace domain language.** Check: none of these four appears in the diff.
9. **Look both ways in review.** Excessive ceremony in a simple module and no modeling in a complex one are both findings. Check: the review states which direction, if any, applies.
10. **Climb a ladder with named triggers.** (Added judgment) See the table below; a rung without its trigger is ceremony, and a trigger without its rung is under-modeling.

### Ladder (Added judgment)

| Rung | Pattern | Climb here when |
| --- | --- | --- |
| 0 | Plain record and a function | Default for CRUD, reference data and generic areas |
| 1 | Value objects, domain names | A validated value repeats, or a primitive hides a unit or format |
| 2 | Entity with guarded transitions | Identity and lifecycle matter, and the business forbids some moves |
| 3 | Aggregate | A rule spans several objects and must hold at the moment of change |
| 4 | Domain events | Another part of the system must react to a business fact |
| 5 | Translator at a boundary | A foreign model with different meaning crosses into the context |

## Procedure

1. List the concepts the change creates or modifies.
2. For each, find the lowest rung that holds its rules honestly.
3. Compare with what the change introduces. Above that rung needs a named trigger from the table; below it is under-modeling.
4. Remove or defer the unearned pattern; add the missing one with a test.
5. Write the one-line reason next to any pattern kept.

## Example

```go
// Before: reference data dressed as a domain model
type CountryAggregate struct {
	id     CountryID
	name   string
	events []DomainEvent
}

func (c *CountryAggregate) Rename(n string) {
	c.name = n
	c.events = append(c.events, CountryRenamed{c.id, n})
}

type CountryRepository interface {
	Save(*CountryAggregate) error
	ByID(CountryID) (*CountryAggregate, error)
}

// After, concept 1 (rung 0): shipping countries have no rule and no lifecycle
type Country struct {
	Code string // ISO 3166-1 alpha-2
	Name string
}

func CountryName(countries []Country, code string) (string, bool) {
	for _, c := range countries {
		if c.Code == code {
			return c.Name, true
		}
	}
	return "", false
}

// After, concept 2 (rung 3): the limit is an invariant across all redemptions,
// so the object that holds the redemptions enforces it
type PromoCode struct {
	code       PromoCodeID
	maxUses    int
	redeemedBy map[CustomerID]bool
}

func NewPromoCode(code PromoCodeID, maxUses int) *PromoCode {
	return &PromoCode{code: code, maxUses: maxUses, redeemedBy: map[CustomerID]bool{}}
}

func (p *PromoCode) Redeem(by CustomerID) error {
	if p.redeemedBy[by] {
		return ErrAlreadyRedeemed
	}
	if len(p.redeemedBy) >= p.maxUses {
		return ErrExhausted
	}
	p.redeemedBy[by] = true
	return nil
}
```

The country list lost the aggregate, the repository interface and the event; the promo code kept its rule where the data is. `DomainEvent`, `CountryRenamed`, `CustomerID`, `PromoCodeID` and the two errors are assumed. The aggregate root is an entity, so it carries an explicit identity (`ddd-distilled-entities` rule 2). `NewPromoCode` initializes the map, so `Redeem` never writes to a nil map.

## Anti-patterns

- **DDD theater.** Aggregates, repositories and events in a module with no invariant. Detect: remove the pattern and see whether any rule or test breaks.
- **Decoration in place of modeling.** Classes with DDD names and no behavior. Detect: every method is an accessor.
- **Under-modeled core.** A complex rule in a map of strings. Detect: the same condition is repeated in several services.
- **Shared domain package.** Detect: one package of "domain objects" used by every module.
- **Technical names in the model.** Detect: `Manager`, `Handler` and `Data` where a business word exists.

## Trade-offs and exceptions

- The ladder is this plugin's judgment; the rule set states the principle (cheapest honest pattern, strengthen as complexity rises) and the triggers for each pattern, not a numbered ladder.
- Supporting and generic areas may climb if their own complexity proves it.
- The rule set lists repositories among the concept kinds but gives no repository rules; for repository design use the `ddd-implementing` plugin.
- A pattern kept for a team-wide convention is a user instruction, not a book rule; follow it and say so.

## Verification

- [ ] Each pattern in the change has a named trigger.
- [ ] No aggregate, event or translator was added to a CRUD or generic area.
- [ ] No complex rule sits in an untyped bag.
- [ ] The change moved concepts up incrementally, not by an overhaul.
- [ ] The reason for each kept pattern is written next to it.

## Related

`ddd-distilled-adoption-fit`; `ddd-distilled-subdomains`; `ddd-distilled-value-objects`; `ddd-distilled-entities`; `ddd-distilled-aggregates`; `ddd-distilled-domain-events`; `ddd-distilled-ceremony-reviewer` to review a diff.

## Source

- `Practicality Rules`
- `Tactical Pattern Rules`
- `Code Generation Rules`
- `Review Rules`: only the excessive ceremony in simple modules and no modeling at all in complex modules items.
