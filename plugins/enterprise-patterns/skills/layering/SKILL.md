---
name: layering
description: "Use for the split into presentation, application, domain and data-access layers, or imports and return types that cross layers: domain code importing a web framework, a repository returning response shapes, forwarding-only layers. Not handler content (presentation-layer) or service design."
---

# Layering

Decides which layer owns a piece of code, which way dependencies may point, and whether a layer is worth having. How to design the application operations is `/enterprise-patterns:service-layer`; what handler and view code may contain is `/enterprise-patterns:presentation-layer`.

## When to use

- A new class or module needs a home and the candidates are "controller", "service" and "repository".
- An import points the wrong way: a repository imports a request type, a domain class imports a web framework.
- A reviewer says "this controller does too much", or a class has four methods that each call one method of the next class.
- You are about to add a layer, a base package or an interface "for the architecture".

## Rules

1. **Use layering as the default organizing principle**, in four logical layers: presentation and delivery, application coordination, domain logic, data source and integration access. "Logical" means responsibilities, not necessarily separate deployables. Separable responsibilities are what let each one change on its own, even inside a single deployable. Check: every file in the changed area can be assigned to exactly one of the four.
2. **Upper layers may depend on lower ones.** A fixed direction keeps the lower layers usable without the layers above them. Check: draw the import edges for the touched files; presentation calls application, application calls domain and data access, and nothing below presentation imports presentation. A data-access class that imports a domain type or interface (a mapper, a repository implementation) is expected and is not the edge this rule forbids.
3. **Lower layers must not reach into presentation concerns.** Otherwise another entry point, such as a batch job, cannot reuse the logic without dragging web types along. Check: no request, response, session, cookie, view-model or UI-framework type is imported or returned below the presentation layer.
4. **Each layer must earn its existence by reducing coupling or clarifying responsibility.** A layer with no job adds hops for the reader and protects nothing. Check: you can state the layer's job in one sentence that no neighboring layer shares.
5. **Do not keep a layer whose methods only pass calls through** (the source calls five forwarding layers "Layering Theater"). Each forwarding hop costs a reader a step and isolates nothing. Check: methods whose whole body is one call to the next layer with the same arguments.
6. **Do not let controllers reach into SQL and transaction details.** A handler that owns them cannot be reused by a second entry point or tested without the web stack. Check: no connection handle, SQL string, `begin` or `commit` in a controller or handler.
7. **Do not embed domain logic in views or handlers.** A rule in a handler is invisible to the job or second endpoint that needs it, and it gets copied. Check: conditionals about business concepts (eligibility, pricing, status transitions) in templates or request handlers.
8. **Do not let repositories return HTTP-shaped DTOs.** Every other caller of the repository would inherit display decisions. Check: repository return types are domain objects (or plain records for table-oriented code), never response bodies with display strings.
9. **Do not let one class or layer own presentation and transport, application workflow, domain logic, data source interaction, transaction management, concurrency control and integration together.** A class that owns all of them changes for every reason and can be tested for none of them alone. Check: list the responsibilities a class touches; more than one layer's worth is a finding (`/enterprise-patterns:responsibility-map` tabulates it).
10. **When unsure, choose the shape that makes those responsibilities explicit.** Added judgment: if two candidate designs are otherwise equal, choose the one with fewer layers.

## Procedure

1. Assign each touched file to a layer, or write "unassigned" and say why.
2. List the import edges between layers and mark any lower layer that points at a presentation type or reaches sideways into web, UI or transport packages.
3. For each violation name the owner it should have (rule 9) and the smallest move: relocate a function, move a type, introduce a mapping at the boundary.
4. Look for forwarding layers: for each class in the layer, count methods that only delegate. If most do, propose removing the layer rather than adding more.
5. Apply the move one violation at a time and run the tests after each.

## Example

```ts
// Before: the data-access layer knows how the HTTP response looks
export async function findOrder(db: Db, id: string): Promise<OrderResponse> {
  const row = await db.one("select id, total_cents, status from orders where id = $1", [id]);
  return { id: row.id, total: `$${(row.total_cents / 100).toFixed(2)}`, statusLabel: row.status.toUpperCase() };
}

// After: data access returns a domain type; presentation shapes the response
export class Order {
  constructor(readonly id: string, readonly totalCents: number, readonly status: string) {}
}

export async function findOrder(db: Db, id: string): Promise<Order> {
  const row = await db.one("select id, total_cents, status from orders where id = $1", [id]);
  return new Order(row.id, row.total_cents, row.status);
}

// handler.ts (presentation)
const order = await findOrder(db, req.params.id);
res.json({ id: order.id, total: formatMoney(order.totalCents), statusLabel: order.status.toUpperCase() });
```

The display strings moved to the only layer that knows about display. Callers of `findOrder` other than the handler now receive something they can reuse, such as a batch job that never wanted `"$12.50"`.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Layering theater | Classes where most methods are one delegating line | Delete the layer; call the real owner |
| Controller-centric flow | Handler contains SQL, `commit`, rule checks and outbound calls | Move coordination to an application service, rules to the domain, SQL to data access |
| Upward import | Domain or data-access file imports a presentation type | Introduce a domain type; map at the boundary |
| Shared "common" bucket | `Utils` or `Common` imported from every layer | Give each function to the layer that owns its concept |
| Pass-through "manager" | `OrderManager` that only calls `OrderDao` | Remove it, or give it a real decision to own |

## Trade-offs and exceptions

- Layers are logical. A small service can hold all four in one deployable and a few packages; it still needs the separation.
- The source's default for simple CRUD is a transaction script or a simple service layer, so a thin layer in a small system is expected, not theater, as long as it owns something (the transaction, the use-case sequence).
- Added judgment: a layer that is thin today may be the place a rule lands tomorrow. Keep it only if you can name that rule now.
- Dependency direction as an enforced architectural rule (ports, plug-in boundaries, import linting) is the subject of `clean-architecture`, not of this book.

## Verification

- [ ] Every touched file has one layer.
- [ ] No import points from a lower layer to a presentation type.
- [ ] No controller or handler holds SQL, transaction control or business rules.
- [ ] Every remaining layer has a job statement that is true of it alone.
- [ ] No repository return type carries display or transport shape.
- [ ] The tests pass after each move.

## Related

`/enterprise-patterns:service-layer` for application operations; `/enterprise-patterns:presentation-layer` for what handlers may hold; `/enterprise-patterns:repository` for the data-access interface; `/enterprise-patterns:responsibility-map` to tabulate ownership; `enterprise-patterns:layering-reviewer` to review a diff.

## Source

- `Architectural Baseline`
- `Layering`
- `Primary Directive`
- `Layering Theater`
- `Controller-Centric Enterprise App`
- `Code Generation Rules`: only the default choice for simple CRUD.
