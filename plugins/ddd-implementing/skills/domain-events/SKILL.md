---
name: domain-events
description: "Use when naming, shaping, raising or reviewing a domain event: past-tense facts, payload, and events that are really commands or property changes. Events as model facts. Messages leaving a context are integration-contracts; event-based persistence is event-sourcing."
---

# Domain events

Owns events as facts inside the model: when one is worth raising, how it is named, what it carries, how it is raised and tested. It does not shape the message that leaves the context (`/ddd-implementing:integration-contracts`), choose event-based persistence (`/ddd-implementing:event-sourcing`) or manage the coordination step that reacts (`/ddd-implementing:cross-aggregate-coordination`).

## When to use

- You add an event class, a publish call or a subscriber.
- An event is named `UpdateX`, `ProcessY` or `XChanged`.
- An event is emitted from every setter.
- An event payload contains an HTTP request, an ORM row, a JSON blob or the aggregate itself.
- A second aggregate needs to react to something that happened in the first.

## Rules

1. **[MUST] Publish domain events for meaningful business facts.** An event is something the business would say happened. Check: you can finish the sentence "the business cares that ..." for each event.
2. **[MUST] Name events in the past tense.** `PledgeWithdrawn`, `CampaignFunded`; not `WithdrawPledge`. Check: the name reads as a completed fact in the ubiquitous language (`/ddd-implementing:ubiquitous-language`).
3. **[MUST] Treat domain events as part of the model, not transport mechanics.** Check: the event class sits in the domain package, is raised by model behavior and has no dependency on a broker, framework or serializer.
4. **[MUST] Use events to coordinate across aggregates or contexts when immediate consistency is not required.** Check: a reaction in another aggregate is triggered by a published event, a named policy or a process step, not by the first aggregate calling it (`/ddd-implementing:cross-aggregate-coordination` rule 6).
5. **[MUST] Keep event payloads meaningful and local to the model.** Check: the payload uses domain identities and value objects; a reader of the event learns what happened without opening another table.
6. **[MUST NOT] Use events for every property change.** `CampaignTotalChanged` after each pledge announces bookkeeping, not a business fact. Check: no event is emitted from a setter or from a generic update method.
7. **[MUST NOT] Name events as commands.** `ApproveInvoice` is a request; `InvoiceApproved` is a fact. Check: no event class is named with an imperative verb.
8. **[MUST NOT] Put framework request objects or persistence artifacts in events.** Check: payload types contain no HTTP request, DTO, row, entity-manager reference or ORM entity.
9. **[MUST NOT] Use events to compensate for missing aggregate design.** An event that exists so another object can fix an invariant the first should have kept shows a wrong boundary. Check: the event's consumer does not undo or re-derive something the raising aggregate owns (`/ddd-implementing:aggregate-boundaries`).
10. **[MUST] Let application services publish the resulting events** after loading, invoking behavior and persisting. Check: publication happens in the application service after the save, not inside the aggregate or the repository (`/ddd-implementing:application-services`).
11. **[MUST] Test domain events as outcomes of domain behavior.** Check: a test performs the behavior and asserts which event it returned or recorded, and that a rejected call raises none (`/ddd-implementing:domain-tests`).
12. **[Added judgment] Raise an event once, at the transition.** A fact like "funded" happens when the goal is first reached, not on every later pledge. Check: a guard or state field keeps the event from repeating.
13. **[Added judgment] Include the event's own identity and time** (an event id, an occurred-at timestamp from an injected clock) so handlers can deduplicate and tests are deterministic. If publication can fail after the commit, a transactional outbox is the common remedy.

## Procedure

1. List what the business would call "worth knowing": state transitions with consequences, thresholds reached, things another part reacts to.
2. For each, name the fact in the past tense with the context's words; discard names that are commands or field changes.
3. Choose the payload: identities of the aggregate and of anything the consumer needs, value objects for amounts and dates. Do not include the aggregate.
4. Have the aggregate method record or return the event when the transition occurs; keep a guard so it fires once.
5. In the application service: save first, then publish the recorded events.
6. Write the outcome test for the behavior and a test that the rejected path raises nothing.
7. If another context needs the fact, map it to a published message (`/ddd-implementing:integration-contracts`).

## Example

```ts
// Before: a command-shaped event with framework and persistence artifacts, emitted on every setter
class UpdateCampaign {
  constructor(readonly request: express.Request, readonly rowBefore: CampaignRow, readonly rowAfter: CampaignRow) {}
}
campaign.setRaised(total);                          // emits "CampaignTotalChanged" each time

// After: one fact, past tense, domain payload, raised by behavior
export class CampaignFunded {
  constructor(
    readonly campaignId: CampaignId,
    readonly raised: Money,
    readonly occurredAt: Date,
  ) {}
}

class Campaign {
  private recorded: DomainEvent[] = [];
  constructor(
    readonly id: CampaignId,
    private readonly goal: Money,
    private raised: Money,
    private funded = false,
  ) {}

  pledge(amount: Money, now: Date): void {
    this.raised = this.raised.plus(amount);
    if (!this.funded && this.raised.isAtLeast(this.goal)) {
      this.funded = true;
      this.recorded.push(new CampaignFunded(this.id, this.raised, now));
    }
  }

  pullEvents(): DomainEvent[] {
    const out = this.recorded;
    this.recorded = [];
    return out;
  }
}

async function makePledge(cmd: MakePledge): Promise<void> {   // application service
  const campaign = await campaigns.byId(cmd.campaignId);
  campaign.pledge(cmd.amount, clock.now());
  await campaigns.save(campaign);
  await bus.publish(campaign.pullEvents());                    // after the save
}
```

A later pledge returns no second `CampaignFunded`, because `funded` is already true.

## Anti-patterns

- **Command as event.** `ProcessOrder`, `SendEmail`. Detect: imperative names; a consumer that must obey rather than react.
- **Chatty events.** One event per field. Detect: events emitted inside setters or by an ORM listener.
- **Fat event.** The entity, a request or a row in the payload. Detect: payload types from web, ORM or serializer packages.
- **Repair event.** An event whose consumer fixes the raiser's state. Detect: handler that writes back to the aggregate that raised the event.
- **Repeating fact.** The same event on every call after a threshold. Detect: no guard on a threshold or transition.

## Trade-offs and exceptions

- Not every state change needs an event. The source asks for meaningful facts; a team with no consumer today need not publish one.
- Whether the event is returned by the method or recorded and pulled is a style choice; keep the repository's convention.
- Event delivery guarantees, ordering and duplicate handling are not covered by this rule set (see the sibling plugin `data-intensive-apps`); treat them as part of the coordination design.

## Verification

- [ ] Each event states a fact the business cares about, in the past tense.
- [ ] No event is named as a command or emitted per property change.
- [ ] Payloads hold domain identities and values, no request, row or aggregate.
- [ ] The event is raised by model behavior and published by the application service after saving.
- [ ] A test asserts the event as the outcome of the behavior.
- [ ] A fact fires once, at its transition.

## Related

`/ddd-implementing:cross-aggregate-coordination` for the reaction; `/ddd-implementing:integration-contracts` for messages leaving the context; `/ddd-implementing:event-sourcing` if events are also stored; `ddd-implementing:event-reviewer` to review a diff; `ddd-implementing:transaction-splitter` to introduce events in place of a wide transaction.

## Source

- `Domain Event Rules`
- `Application Service Rules`: only the rule that application services publish the resulting events.
- `Testing Rules`: only the rule to test domain events as outcomes of domain behavior.
