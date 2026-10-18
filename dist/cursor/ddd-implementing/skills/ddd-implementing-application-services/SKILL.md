---
name: "ddd-implementing-application-services"
description: "Use when writing or reviewing use-case code in a modeled area: a service or handler that loads, calls, saves and publishes, or whose branching on business state keeps growing. Thin orchestration and transactions. Decisions over several domain objects are domain-services; persistence is repositories."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Application services

Owns the use-case layer: one method per use case, coordinating the model without containing its decisions. Domain decisions that span objects are `ddd-implementing-domain-services`; the persistence contract it calls is `ddd-implementing-repositories`; deciding whether an area deserves a model at all is `ddd-implementing-core-domain-focus`.

## When to use

- You add a use case (a command handler, a service method, an endpoint's body).
- A `*Service` method has a long run of `if` and `switch` on business state.
- A controller and a service both load, check and save the same thing.
- A repository implementation and a service both enforce the same rule.
- A test of a service needs dozens of cases about business rules.

## Rules

1. **[MUST] Use application services to coordinate use cases.** One use case, one method, named in the ubiquitous language (`renewLoan`, not `process`). Check: a method corresponds to one thing a user or system asks for.
2. **[MUST] Have them load aggregates, invoke domain behavior, persist results and publish resulting events.** In that order. Check: the method reads like four steps, and the second step is a call into the model.
3. **[MUST NOT] Put the model's core decision logic in an application service.** Rules about state, limits and eligibility belong to the aggregate, a value object or a domain service. Check: removing the service's branching on business state would lose no rule that the model should own.
4. **[MUST] Keep them thin enough that the model still matters.** Check (Added judgment, a search aid): in the service body, count the lines that test business state against the lines that call the model or a port; decisions outnumbering calls mean the model has stopped mattering for this use case.
5. **[MAY] Own transaction boundaries and integration coordination.** Starting a unit of work, calling a port, mapping an inbound command are legitimate here. Check (Added judgment, the source only permits service ownership): the model and repositories do not open transactions; where the service owns the transaction, it is not duplicated in controllers.
6. **[MUST NOT] Contain all the branching business rules.** Check: the service has no state-dependent `if` chains that a domain expert would recognize as rules.
7. **[MUST NOT] Duplicate orchestration in controllers.** A controller translates the transport and calls one service. Check: controllers do not load aggregates or call repositories.
8. **[MUST NOT] Let a repository and an application service implement the same invariant.** One owner per rule. Check: grep a rule's key condition; it appears in exactly one place, in the model.
9. **[MUST] Test application services for orchestration, not for all domain decisions.** Check: service tests use fakes for repositories and publishers and assert load/call/save/publish, not every rule combination (`ddd-implementing-domain-tests`).
10. **[MUST] Define application services around use cases.** The code-generation order names use cases as the unit. Check: each class or method is a use case. Added judgment: a service class per entity (a `LoanService` with twenty unrelated methods) is the usual way this rule is missed.
11. **[Added judgment] Translate at the edge.** Convert the incoming command or request into value objects before calling the model, and return a small result or view, not the aggregate (`ddd-implementing-client-representations`). Check: no aggregate type is returned to controllers.
12. **[Added judgment] Gather the facts a rule needs and pass them in.** When a rule depends on data outside the aggregate (is the copy reserved?), the service queries it and hands it to the behavior as an argument. Check: the aggregate method takes the fact; it does not reach for another repository.

## Procedure

1. Write the use case's name and its four steps in comments or a short list.
2. For every branch on business state found in the service, ask which model object owns the data it tests. Move the decision there (`ddd-implementing-root-encapsulator` for a larger move).
3. Replace what remains with straight-line coordination: load, gather facts, call one behavior, save, publish.
4. Make controllers call exactly one service method; delete orchestration copies.
5. Check each invariant for a second implementation in repositories or services and remove all but the model's.
6. Rewrite the service test with fakes to assert orchestration; move rule cases to the model's tests.

## Example

```ts
// Before: the service owns the rules, the controller repeats part of them
export class LoanService {
  async renew(loanId: string, today: Date): Promise<void> {
    const row = await db.loan.findUnique({ where: { id: loanId } });
    if (!row) throw new Error("not found");
    if (row.status !== "OPEN") throw new Error("closed");
    if (row.renewals >= 2) throw new Error("limit reached");
    const reserved = await db.reservation.count({ where: { copyId: row.copyId, active: true } });
    if (reserved > 0) throw new Error("reserved");
    await db.loan.update({
      where: { id: loanId },
      data: { dueOn: addDays(row.dueOn, 14), renewals: row.renewals + 1 },
    });
  }
}

// After: the service coordinates; the aggregate decides
export class RenewLoan {
  constructor(
    private readonly loans: LoanRepository,
    private readonly reservations: ReservationQueries,
    private readonly clock: Clock,
    private readonly bus: EventBus,
    private readonly tx: UnitOfWork,
  ) {}

  async execute(cmd: { loanId: LoanId }): Promise<void> {
    const renewed = await this.tx.run(async () => {
      const loan = await this.loans.byId(cmd.loanId);
      const copyIsReserved = await this.reservations.hasActiveForCopy(loan.copyId);
      const event = loan.renew(this.clock.today(), { copyIsReserved });   // limit, state and reservation rules live here
      await this.loans.save(loan);
      return event;
    });
    await this.bus.publish([renewed]);                                    // after the commit
  }
}
```

`RenewLoan` has no business `if`; its test asserts that the loan was saved and the event published, and the limit rule is tested on `Loan`.

## Anti-patterns

- **Transaction script in a service.** All rules in the service. Detect: branching on status or counters read from the entity.
- **Entity-named god service.** `LoanService` with every operation. Detect: one class with many unrelated public methods.
- **Double implementation.** The same check in the service and the repository. Detect: the same condition in two classes of different layers.
- **Fat controller.** Controllers that load, check and save. Detect: repository calls from the interface layer.
- **Aggregate out.** Methods returning the aggregate to the transport layer. Detect: aggregate types in controller signatures.
- **Model-reaching aggregate.** The aggregate fetching what it needs through a repository. Detect: repository parameters on aggregate methods.

## Trade-offs and exceptions

- In a plain supporting area a service holding simple rules is not a failure; the source asks for modeling when invariants and lifecycle complexity appear (`ddd-implementing-core-domain-focus`).
- Transaction ownership in the service is a permission ("may"), not a mandate; Added judgment: an existing framework convention that opens transactions elsewhere (a controller decorator, a middleware) may stay, as long as the model and repositories do not open them and the same transaction is not opened twice.
- Process coordination across several use cases (policies reacting to events) belongs to `ddd-implementing-cross-aggregate-coordination`; keep each reaction itself a thin application service.

## Verification

- [ ] Each service method is one use case with a business name.
- [ ] The method shows load, invoke, persist, publish and nothing else of substance.
- [ ] No state-dependent business branching remains in the service or controller.
- [ ] No invariant is implemented in two layers.
- [ ] Controllers call one service method and do not touch repositories.
- [ ] Service tests assert orchestration with fakes; rule tests live on the model.

## Related

`ddd-implementing-domain-services` for cross-object decisions; `ddd-implementing-aggregate-root-discipline` for the model's door; `ddd-implementing-repositories`; `ddd-implementing-domain-events`; `ddd-implementing-rule-placement-reviewer` to review a diff; `ddd-implementing-root-encapsulator` to move decisions into the model.

## Source

- `Application Service Rules`
- `Code Generation Rules`: only the step that defines application services around use cases.
- `Testing Rules`: only the rule to test application services for orchestration.
