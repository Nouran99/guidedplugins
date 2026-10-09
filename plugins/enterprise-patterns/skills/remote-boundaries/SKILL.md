---
name: remote-boundaries
description: "Use when your own API or client makes several calls per user action, objects are exposed remotely method by method, domain classes appear in responses, or a service split is proposed. Covers Remote Facade, DTOs, distribution rules. Partner payloads are integration-boundaries."
---

# Remote boundaries

Decides whether a boundary should be remote at all, and shapes it when it is: coarse operations (Remote Facade), explicit transfer structures (DTOs), and a budget for latency, serialization, versioning and partial failure. Foreign systems you consume are `/enterprise-patterns:integration-boundaries`.

## When to use

- A screen or job needs several round trips to a service to assemble one result.
- A remote interface mirrors an object's fine-grained getters and setters.
- Controllers or endpoints return entities or ORM models directly.
- A design proposes splitting a module into a separately deployed service.
- A caller treats a remote call like a local method (no failure handling, no payload thought).

## Rules

1. **Do not distribute objects or services remotely by default.** Remote calls cost latency and can fail in ways local calls cannot. Check: every process boundary has a written reason; staying in-process is the default.
2. **Make remote boundaries coarse-grained.** Each call pays latency and serialization, and fine-grained interfaces multiply them. Check: one user-level action needs one remote call, or very few; Added judgment: count calls per user action and treat growth with list size as a defect.
3. **Separate local object design from remote contract design.** Otherwise a domain refactoring breaks clients. Check: contract types are not the domain classes, and a domain refactoring does not change the wire format unless you meant it to.
4. **Budget explicitly for latency, serialization, versioning and partial failure.** These costs are what separate a remote call from a local one, and unbudgeted they surface as incidents. Check: each operation states its payload scope, how old and new callers coexist, and what the caller does when the call fails or times out (the mechanisms for timeouts and retries belong to `release-it`).
5. **Use a Remote Facade when the boundary is remote, coarse-grained APIs reduce chatty calls and the transport shape differs from the internal design.** A facade turns many fine-grained calls into one and hides the internal shape. Check: the facade has operations for use cases, not for objects.
6. **Expose coarse remote operations.** Per-field operations recreate the chattiness a facade exists to remove. Check: no remote operation exists per field or per entity getter.
7. **Translate between remote contracts and the internal model.** Without translation the wire format becomes the domain model. Check: an explicit assembler maps domain to DTO and back.
8. **Keep remote transport concerns at the boundary.** Transport concerns in the core tie it to one protocol. Check: serialization annotations, status codes and protocol types do not appear in domain or application classes.
9. **Use a Data Transfer Object when data crosses a process or layer boundary, batching values reduces remote or serialization cost, or translation protects the internal model.** A DTO is a cost, and it earns that cost at a boundary. Check: each DTO sits at a process or layer boundary where at least one of those three forces applies; between collaborators in one layer, where none applies, passing domain objects is fine.
10. **Treat DTOs as transport structures, not domain models.** A DTO with behavior becomes a second domain model. Check: DTOs hold data and, at most, serialization behavior.
11. **Keep DTO mapping explicit, and do not move business behavior into DTOs.** Implicit mapping hides which fields cross the boundary. Check: one assembler function per DTO, with a test.
12. **Do not assume local method-call semantics over a network.** A network call can be slow, fail, repeat or lose its answer. Check: callers handle failure, slowness and the possibility that a call happened but the answer was lost.
13. **Do not leak domain internals through remote endpoints.** Internals on the wire become a contract you cannot change. Check: responses expose only what consumers need, in contract terms (no internal ids of collaborators' tables, no lazy proxies, no internal status enums).
14. **Default remote design: a remote facade plus DTOs.** The source gives this as the default choice for a remote boundary; use it unless a force says otherwise.

## Procedure

1. List the calls a consumer makes for one user action. Count them, and note which grow with data size.
2. Define the use-case-level operation that answers the action in one call.
3. Define request and response DTOs with only what the consumer needs; add a version marker or tolerant-reader rule for evolution.
4. Write the assembler between domain objects and the DTOs.
5. Implement the facade as a thin class that calls application services and assembles; keep transactions in the services.
6. Test the assembler and the facade mapping at the boundary (see `/enterprise-patterns:testing-by-responsibility`).
7. Decide failure behavior for the caller and document it.

## Example

```ts
// Before: the client assembles one screen from many fine-grained remote calls
const order = await api.get(`/orders/${id}`);
const customer = await api.get(`/customers/${order.customerId}`);
const lines = await Promise.all(order.lineIds.map((lid: string) => api.get(`/order-lines/${lid}`)));
const shipment = await api.get(`/shipments/${order.shipmentId}`);      // 3 + N calls per screen

// After: one coarse operation per use-case need, with an explicit DTO and an assembler
interface OrderScreenDto {
  version: 1;
  orderId: string;
  customerName: string;
  lines: { sku: string; quantity: number; unitPriceCents: number }[];
  shipmentStatus: "in_transit" | "delivered" | "unknown" | "none";
}

// the application service loads what the use case needs
class OrderDetails {
  constructor(private orders: OrderRepository, private customers: CustomerRepository) {}
  async forOrder(orderId: string): Promise<{ order: Order; customer: Customer }> {
    const order = await this.orders.get(orderId);
    return { order, customer: await this.customers.get(order.customerId) };
  }
}

// the assembler is one explicit function, tested on its own
export function toOrderScreenDto(order: Order, customer: Customer): OrderScreenDto {
  return {
    version: 1,
    orderId: order.id,
    customerName: customer.name,
    lines: order.lines.map((l) => ({ sku: l.sku, quantity: l.quantity, unitPriceCents: l.unitPriceCents })),
    shipmentStatus: order.shipmentStatus ?? "none",
  };
}

// the facade only calls the service and assembles; it holds no rule and no repository
class OrderFacade {
  constructor(private orderDetails: OrderDetails) {}
  async orderScreen(orderId: string): Promise<OrderScreenDto> {
    const { order, customer } = await this.orderDetails.forOrder(orderId);
    return toOrderScreenDto(order, customer);
  }
}

const screen = await api.get(`/order-screen/${id}`);                    // 1 call
```

The DTO can change on its own schedule: adding a field is compatible, and the `version` field gives a place to introduce a breaking shape later without surprising old clients. The domain `Order` is not on the wire, and `toOrderScreenDto` is the single place that decides which fields cross.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Chatty interface | Calls per action grow with list size or object graph | Coarse use-case operation |
| Distributed objects | Remote getters, setters and object proxies | Facade over use cases |
| Entity on the wire | Endpoints return ORM or domain classes | DTO plus assembler |
| Behavioral DTO | DTO with methods that decide | Move the decision to the model |
| Local-call assumption | No handling for failure or timeout around a remote call | Define failure behavior for the caller |
| Premature service split | Separate deployment with no recorded reason | Keep in-process until a force appears |

## Trade-offs and exceptions

- "By default" matters: the source does not forbid distribution, it requires a reason and a design for it.
- A coarse operation may return more than a particular consumer needs; the alternative is chattiness, so balance by use case, not by principle.
- DTOs are a cost; use them at process and layer boundaries where one of the three listed forces applies, and not by reflex between collaborators of one layer.
- API style (REST, RPC, GraphQL) is not decided by this book; apply the coarse-grained and translation rules within whichever the project uses.

## Verification

- [ ] Each remote boundary has a stated reason.
- [ ] One user action costs one or a few remote calls, independent of list size.
- [ ] Contract types are not domain classes.
- [ ] An assembler maps domain and DTO explicitly and is tested.
- [ ] Caller behavior on failure, timeout and version mismatch is defined.
- [ ] No domain internals appear in responses.

## Related

`/enterprise-patterns:remote-contract` to design an operation; `/enterprise-patterns:integration-boundaries` for foreign systems; `/enterprise-patterns:service-layer` for what the facade calls; `enterprise-patterns:remote-api-reviewer` to review a diff; `enterprise-patterns:facade-builder` to build a facade.

## Source

- `Distribution Rules`
- `Remote Facade`
- `Data Transfer Object`
- `Application Workflow Rules`
- `Distributed Object Fantasy`
- `Code Generation Rules`: only the default of a remote facade plus DTOs at a remote boundary.
