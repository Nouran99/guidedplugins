---
name: domain-events
description: "Use when naming, designing or reviewing domain events, when events are vague, command-like or fired for every field change, or when deciding whether a fact deserves an event. Delivery: /ddd-distilled:integration-styles; transaction scope around events: /ddd-distilled:cross-aggregate-consistency."
---

# Domain events

A domain event records a meaningful business fact that has already happened. This skill decides what an event is: its name, whether it earns existence, and what it carries. How events are delivered and consumed safely is `/ddd-distilled:integration-styles`; the transaction scope around them is `/ddd-distilled:cross-aggregate-consistency`.

## When to use

- You add an event type, or a publish call.
- An event is called `Updated`, `Changed` or `Modified`, or has the shape of an instruction (`SendInvoice`).
- Every setter raises an event.
- A team debates whether a fact should be an event at all.

## Rules

1. **Use domain events for meaningful facts.** An event is the business saying "this happened". Check: a domain expert would answer "yes, that happened, and we care".
2. **Name events in the past tense.** The tense keeps events from being mistaken for requests. Check: `InvoiceIssued`, not `IssueInvoice`, `InvoiceIssuing` or `InvoiceEvent`.
3. **Use events when they clarify collaboration or integration.** An event with no consumer and no business reason is noise. Check: a consumer or a stated business purpose exists for each event type.
4. **Do not publish trivial noise for every field change.** Consumers would have to reconstruct meaning from diffs. Check: no `XUpdated` or `XChanged` event whose payload is a field name with old and new values.
5. **Redesign vague, command-like or field-change events as specific business facts, or remove them.** (Compact checklist) Check: `OrderUpdated` became `OrderShipped` or `OrderAddressCorrected`; `SendInvoice` became `InvoiceIssued` or was dropped.
6. **Decide whether the event carries enough information for consumers or requires them to query back, and record the decision.** The choice shapes coupling; see `/ddd-distilled:integration-styles`. Check: each event type states which.
7. **Name events and their fields in the ubiquitous language of the publishing context.** Check: the event name matches a term in that context's glossary.
8. **Carry facts, not aggregate internals.** (Added judgment) A payload that mirrors the aggregate's fields leaks its structure. Check: the fields describe what happened and the identifiers needed to find more.
9. **Give each event an identifier and an occurrence time.** (Added judgment) Consumers need them to deduplicate and to reason about order. Check: both fields exist.
10. **Create the event where the fact becomes true.** (Added judgment) The model method that decides the fact is the one that records it. Check: no `publish` call in a controller for something the model decided.
11. **Never change a published event after the fact.** (Added judgment) A corrected fact is a new event. Check: events are immutable, and corrections have their own names.

## Procedure

1. List the event types in the change and the places they are created.
2. For each, ask rule 1: what business fact does it record, in one sentence?
3. Rename to the past tense in the context's language; delete or split noise events.
4. Decide carry-data or query-back and write it next to the type.
5. Move creation into the model method that makes the fact true.
6. Add identifier and time; test that the model produces the event only on valid transitions.

## Example

```go
// Before: a diff, not a fact; every consumer must work out what happened
type OrderUpdated struct {
	OrderID string
	Field   string
	Old     any
	New     any
}

// After: a fact in the Fulfillment context's language, produced by the model
type OrderShipped struct {
	EventID    string
	OrderID    OrderID
	CarrierRef CarrierRef
	ShippedAt  time.Time
}

func (o *Order) Ship(carrier CarrierRef, at time.Time) (OrderShipped, error) {
	if o.status != statusPacked {
		return OrderShipped{}, fmt.Errorf("order %s cannot ship from status %s", o.id, o.status)
	}
	o.status = statusShipped
	return OrderShipped{
		EventID:    newEventID(),
		OrderID:    o.id,
		CarrierRef: carrier,
		ShippedAt:  at,
	}, nil
}
```

`OrderID`, `CarrierRef`, the status constants and `newEventID` are assumed; the id and status types are string-based, so they print with `%s`. The event exists only when the transition is valid.

## Anti-patterns

- **Event per setter.** Detect: an event raised in every property assignment.
- **Command in disguise.** Detect: a name that is an instruction (`ProcessPayment`), or a handler that must act or the system breaks.
- **Mirror payload.** Detect: the event copies the aggregate's fields.
- **Event soup.** Detect: dozens of event types, few consumers.
- **Controller-published facts.** Detect: a publish call outside the model for a decision the model made.

## Trade-offs and exceptions

- Not every domain needs events; introducing them before knowing why is a named anti-pattern (`/ddd-distilled:pattern-economy`).
- Some facts matter only for audit; that is a business purpose and justifies the event.
- An event may carry a snapshot of data a consumer cannot get elsewhere; that is a recorded carry-data decision, not a mirror payload.
- Event sourcing is a separate technique and is not covered by this rule set.

## Verification

- [ ] Every event is a past-tense business fact in the publishing context's language.
- [ ] No event exists only to report that a field changed.
- [ ] Each event has a consumer or a stated purpose.
- [ ] The payload decision (carry or query back) is recorded.
- [ ] Events are created by the model and carry an identifier and time.

## Related

`/ddd-distilled:integration-styles`; `/ddd-distilled:cross-aggregate-consistency`; `/ddd-distilled:ubiquitous-language`; `ddd-distilled:event-reviewer` to review a diff.

## Source

- `Domain Events`
- `Tactical Pattern Rules`
- `Integration Style Rules`: only the rule to decide whether domain events carry enough information or require query-back.
- `Ubiquitous Language Rules`: only the rule to use local terms in events.
- `Practicality Rules`: only the anti-pattern of introducing aggregates and events before knowing why.
