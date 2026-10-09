---
name: service-layer
description: "Use when writing or reviewing application services or use-case classes: a controller orchestrating several steps, a service that holds every rule or only forwards to persistence, an API shaped by UI mechanics. Not for rule placement (business-logic-patterns) or layer imports (layering)."
---

# Service layer

Designs the application's operations: one named entry point per use case that coordinates the steps, owns the transaction boundary and speaks in application terms. Where business decisions live is `/enterprise-patterns:business-logic-patterns`; transaction mechanics are `/enterprise-patterns:transactions-and-unit-of-work`.

## When to use

- A request handler loads data, calls several collaborators, saves and sends a message, all in one function.
- Two entry points (web handler, message consumer, scheduled job) need the same use case.
- A "service" class has methods named after tables (`saveOrder`, `updateOrder`) or after screens (`getOrderPageModel`).
- A service has grown every business rule in the system and the entities hold none.

## Rules

1. **Let application services coordinate use cases.** One public operation per use case, named for what the application does (`ConfirmOrder`, `ReopenTicket`), not for a table or a screen. Use-case names tell readers what the application does; table names only how it stores. Check: each public method reads as a user-level goal.
2. **Let the service define transaction boundaries and orchestration.** Seeing "begin", the ordered steps and "commit" together makes failure behavior reviewable in one place. Check: one place per use case where the transaction opens and closes (details in `/enterprise-patterns:transactions-and-unit-of-work`).
3. **Do not let the service absorb all domain logic by default.** It calls model objects that decide. A service that decides everything leaves the model empty and the rules scattered across services. Check: no long chains of business conditionals in the service; where it does hold a rule, you can say why no model object owns it.
4. **Expose an application-oriented API, not UI mechanics (SHOULD, a strong default rather than a binding rule).** Parameters are what the use case needs (an id, a command), not request objects, form models or pagination widgets. UI types in a service tie every other caller, such as a job or a consumer, to the web framework. Check: by default no operation signature names a UI or request type; where one stays, you can name the reason and the cost. Importing a web or UI package into the application layer is a separate matter, governed by the layering rule that lower layers must not reach into presentation concerns (`/enterprise-patterns:layering`); this rule's softer strength does not excuse it.
5. **Keep presentation, transport and persistence mechanics outside.** Mechanics in the service make it untestable without the stack and hard to reuse. Check: no response codes, template names, SQL or connection handles inside the service body.
6. **Place use-case coordination in the application layer right after choosing the business logic pattern, and before domain decisions, persistence and presentation.** The source's generation order has exactly this sequence. Coordination placed first gives controllers and repositories a fixed seam to attach to. Check: when generating a new feature, the service exists before controllers or repositories are written.
7. **For simple CRUD, a simple service layer is a valid default.** Plain CRUD needs a place for the transaction and the sequence, not a hierarchy. Check: a thin service is acceptable when it owns the transaction and the sequence; it is theater if it only forwards (see `/enterprise-patterns:layering`).
8. **Make one entry point per use case, not one per caller.** Added judgment: if the web handler and the message consumer each contain the sequence, extract it and have both call the service. Two copies of a sequence drift apart.

## Procedure

1. Name the use case in the user's words and write its steps as a list: load, decide, change, persist, notify.
2. Mark each step with its owner: model object, repository, collaborator, or the service itself.
3. Keep in the service only the sequencing, the transaction, authorization of the use case if the project does it here, and calls out; move decisions to the model.
4. Define the service's input as a small command or plain arguments; define its output as what the caller needs, not an entity graph.
5. Call outbound systems after the transaction commits unless the project has a reason otherwise (see `/enterprise-patterns:transactions-and-unit-of-work`).
6. Run the tests after each move.

## Example

```ts
// Before: the handler orchestrates, owns the transaction and holds the rule
app.post("/orders/:id/confirm", async (req, res) => {
  const conn = await pool.connect();
  try {
    await conn.query("begin");
    const { rows } = await conn.query("select * from orders where id = $1", [req.params.id]);
    if (rows[0].status !== "draft" || rows[0].total_cents <= 0) { await conn.query("rollback"); return res.status(409).end(); }
    await conn.query("update orders set status = 'confirmed' where id = $1", [req.params.id]);
    await conn.query("commit");
    await mailer.send(rows[0].customer_email, "Order confirmed");
    res.status(204).end();
  } catch (e) { await conn.query("rollback"); res.status(500).end(); } finally { conn.release(); }
});

// After: the handler translates; the service coordinates; the model decides
class OrderNotConfirmable extends Error {}

class Order {
  constructor(
    public readonly id: string,
    public readonly customerEmail: string,
    private status: "draft" | "confirmed",
    private totalCents: number,
  ) {}
  confirm(): void {
    if (this.status !== "draft" || this.totalCents <= 0) throw new OrderNotConfirmable(this.id);
    this.status = "confirmed";
  }
}

class ConfirmOrder {
  constructor(private tx: Transactions, private orders: OrderRepository, private notifier: Notifier) {}
  async execute(orderId: string): Promise<void> {
    const customerEmail = await this.tx.run(async () => {
      const order = await this.orders.get(orderId);
      order.confirm();
      await this.orders.save(order);
      return order.customerEmail;
    });
    await this.notifier.orderConfirmed(customerEmail);
  }
}

app.post("/orders/:id/confirm", async (req, res) => {
  try { await confirmOrder.execute(req.params.id); res.status(204).end(); }
  catch (e) { res.status(e instanceof OrderNotConfirmable ? 409 : 500).end(); }
});
```

The mail is sent after the transaction has committed, so a slow mail server cannot hold the transaction open. The model keeps `status` and `totalCents` private and exposes the one decision, `confirm()`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| God service | One `*Service` with all rules; entities have none | Move each decision to the object it concerns |
| Pass-through service | Methods whose body is one repository call | Remove it or give it the transaction and sequence |
| UI-shaped API | Parameters named `form`, `req`, `pageModel` | Take a command or primitive arguments |
| Table-named operations | `saveOrder`, `updateOrderRow` | Rename for the use case; split by intent |
| Duplicate orchestration | Handler and consumer repeat the same steps | One service entry point, two callers |

## Trade-offs and exceptions

- A service in a Transaction Script system legitimately holds the logic; the script is the service. The rule against absorbing domain logic applies where a domain model exists or is warranted.
- Simple CRUD does not need a hierarchy of services; one small class per use case, or a few functions, is enough.
- Authorization, validation of input shape and mapping to response are placed where the project already places them; do not move them for the sake of this skill.
- The source words the application-oriented API as "should", so the shape of an operation's parameters is a strong default, not an absolute. An operation with exactly one caller, a web handler in a small app, may take a small request-shaped command if you state the cost: a job or consumer added later must build one too, and a unit test needs a fake. Report that as a note, not as a defect. Importing a web framework package into the service is not covered by this softening; the layering rule applies at its own strength.

## Verification

- [ ] Each public operation is named after a use case.
- [ ] The transaction opens and closes in one visible place per use case.
- [ ] The service imports no web, UI or SQL package.
- [ ] No operation signature names a UI or request type, or the reason and cost are stated.
- [ ] Business conditions are called on model objects, not written in the service, except where a reason is stated.
- [ ] Outbound calls to other systems happen after the commit or are justified.
- [ ] The tests pass after each move.

## Related

`/enterprise-patterns:business-logic-patterns` for decisions; `/enterprise-patterns:transactions-and-unit-of-work` for commit scope; `/enterprise-patterns:presentation-layer` for the handler's side; `enterprise-patterns:service-layer-reviewer` to review a diff.

## Source

- `Application Workflow Rules`
- `Service Layer`
- `Code Generation Rules`: only the generation order and the simple CRUD default.
