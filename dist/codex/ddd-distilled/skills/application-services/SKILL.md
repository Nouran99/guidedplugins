---
name: "application-services"
description: "Use when a service, handler or controller makes business decisions, when an application service is shaped by HTTP or message formats, or when deciding what a use-case method may contain. Keeps it to coordination. For logic that moves out see $ddd-distilled:entities."
---

# Application services

An application service coordinates one use case. It loads, calls the model, saves and triggers follow-up work; it does not hold the business rules. This skill keeps the service thin; the object that receives the rules is `$ddd-distilled:entities` or `$ddd-distilled:value-objects`, and a decision hiding in a flag is `$ddd-distilled:explicit-concepts`.

## When to use

- A `*Service` method contains conditionals about business state, eligibility, pricing or limits.
- A controller or message handler repeats the same sequence of calls as another entry point.
- A service method takes an HTTP request, a framework context or a raw message envelope.
- A domain class is only getters and setters while a service does the thinking.

## Rules

1. **Let application services coordinate use cases.** One public method per use case keeps the entry points legible. Check: method names are use cases in business terms (`confirmReservation`).
2. **Make the body load aggregates, call domain behavior, save results and trigger integration work.** Those four steps are the service's whole job. Check: read the method top to bottom; every line is one of the four.
3. **Do not let the service become the real domain model.** Business decisions in a service leave the model empty and untestable in isolation. Check: no conditional on business state, no price or eligibility arithmetic inside the service.
4. **Prefer a service thin enough that the model still carries meaning.** This is a should: a thicker service is a warning, not a violation. Check: a newcomer learns the rules by reading the model, not the service.
5. **Do not put all business decisions in application services.** The book calls the result service-centric fake DDD. Check: for each decision in the service, ask which entity, value object or policy should own it.
6. **Do not let controllers duplicate application orchestration.** Two entry points repeating a sequence will diverge. Check: a controller maps a request to a command, calls one service method, and maps the result back; nothing more.
7. **Do not shape application services only by transport.** Check: the service signature takes a command in domain terms, not an HTTP request, a message envelope or a framework context.
8. **Translate transport data at the boundary.** The service should receive already-mapped input. Check: no JSON parsing or header reading inside the service.
9. **Test application services for orchestration, not for all domain rules.** Check: service tests assert load, call, save and publish happened; rule coverage is in the model's tests (`$ddd-distilled:domain-tests`).
10. **Make one use case one transaction.** (Added judgment) Check: the method opens and closes one transaction, usually around one aggregate; see `$ddd-distilled:cross-aggregate-consistency`.

## Procedure

1. Read the service method and highlight every conditional and calculation.
2. For each, decide whether it is business (rule about the domain) or coordination (does it exist? is it saved?). Business belongs in the model.
3. Name the concept that should own each business decision; if none exists, create it (`$ddd-distilled:explicit-concepts`).
4. Move the decision with a test written first or alongside; keep the service signature stable.
5. Strip transport types from the signature; map at the controller or consumer.
6. Check that only one entry point sequence exists per use case.

## Example

```ts
// Before: one function decides, persists, notifies and speaks HTTP
async function confirm(req: Request, res: Response) {
  const r = await db.reservations.findOne(req.body.id);
  if (r.status === "requested" && r.arrival > new Date() && r.guests <= r.roomCapacity) {
    r.status = "confirmed";
    r.depositRequired = r.guest.loyaltyYears <= 3;
    await db.reservations.save(r);
    await mailer.send(r.guest.email, "Confirmed");
    res.status(200).json(r);
  } else {
    res.status(409).json({ error: "cannot confirm" });
  }
}

// After: the controller maps, the service coordinates, the model decides
async function confirmReservation(req: Request, res: Response) {
  await reservationService.confirm({ reservationId: new ReservationId(req.params.id) });
  res.status(204).end();
}

class ReservationService {
  constructor(
    private readonly reservations: Reservations,
    private readonly publisher: EventPublisher,
    private readonly clock: Clock,
  ) {}

  async confirm(cmd: ConfirmReservation): Promise<void> {
    const reservation = await this.reservations.get(cmd.reservationId);
    const confirmed = reservation.confirm(this.clock.now()); // rules and the deposit decision live here
    await this.reservations.save(reservation);
    await this.publisher.publish(confirmed);
  }
}
```

`reservation.confirm(now)` throws a domain error for an invalid confirmation and returns a `ReservationConfirmed` event; the controller or an error filter maps that error to a 409. Types such as `Reservations`, `EventPublisher` and `Clock` are assumed.

## Anti-patterns

- **Fat service.** Detect: long methods full of `if` on business fields over a data-only class.
- **Controller orchestration.** Detect: the same call sequence appears in an HTTP controller and a message consumer.
- **Transport-shaped service.** Detect: parameters named `req`, `ctx`, `message`, or `JsonNode`.
- **Service-centric fake DDD.** Detect: entities exist, but every rule lives in `*Service` classes.
- **Test-everything service tests.** Detect: service tests that re-assert every business rule.

## Trade-offs and exceptions

- In a simple or supporting area, a service holding a few plain rules over plain data is acceptable (`$ddd-distilled:pattern-economy`). The thinness rule protects domains where the model carries meaning.
- Authorization and transaction demarcation commonly sit around the use case; they are coordination, not domain rules. (Added judgment)
- A service may call several domain objects, as long as the decisions stay in them.

## Verification

- [ ] Each service method is load, call, save, trigger.
- [ ] No business conditional or calculation remains in the service.
- [ ] Controllers and consumers only map and call.
- [ ] No transport type appears in a service signature.
- [ ] Service tests check orchestration; rule tests live with the model.

## Related

`$ddd-distilled:entities`; `$ddd-distilled:explicit-concepts`; `$ddd-distilled:infrastructure-isolation`; `$ddd-distilled:domain-tests`; `ddd-distilled-service-reviewer` to review a diff; `ddd-distilled-behavior-mover` to relocate decisions.

## Source

- `Application Service Rules`
- `Review Rules`: only the services containing all behavior item.
- `Testing Rules`: only the rule to test application services for orchestration.
- `Code Generation Rules`: only the default avoidance of service-centric fake DDD.
- `Architecture and Infrastructure Rules`: only the rule to translate transport data at the boundary.
- `Practicality Rules`: only the rule that simple domains may use simple services.
