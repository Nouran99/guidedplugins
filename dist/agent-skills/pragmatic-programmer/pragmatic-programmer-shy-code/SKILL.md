---
name: "pragmatic-programmer-shy-code"
description: "Use when code reaches through an object's internals (a.b().c().d()), needs calls in a fixed order (init before use), or a shared workspace is proposed. Covers Law of Demeter, temporal coupling and blackboards. Module-level ripple is `orthogonality`; mutable state is `pragmatic-programmer-shared-state`."
license: "MIT"
metadata:
  plugin: "pragmatic-programmer"
  book: "The Pragmatic Programmer"
  invocation: "auto"
---

# Shy code

How one piece of code reaches another, and in what order. This skill decides what a module reveals, what a caller may reach through, and whether a required order is explicit. Module boundaries and change ripple are `pragmatic-programmer-orthogonality`; mutable state is `pragmatic-programmer-shared-state`.

## When to use

- Chains such as `order.getCustomer().getAddress().getCountry()` or `config["db"]["pool"]["size"]` appear in business code.
- An object must be initialized, configured or connected before use, or two calls must happen in a fixed order with nothing enforcing it.
- A shared workspace (a "context" dictionary, a bag of facts that many steps read and write) is proposed or already exists.
- A class exposes many members "just in case".

## Rules

1. **Apply shy-code discipline: modules reveal only necessary information.** [MUST] Check: every public member has a caller outside the module; everything else is private or removed.
2. **Apply Law of Demeter discipline: talk to your direct collaborators, not to their internals.** [MUST] Added judgment on the working form: a method may call its own object, its parameters, objects it creates and its direct components; reaching through the structure of an object another module returned is the signal. Added judgment on the threshold (the source gives no number): after the first call on a direct collaborator, a chain that goes on through two or more further behavior-bearing objects of another module (`a.b().c().d()`) is a violation; a single step past the collaborator is a judgment call. Check: no such chain in the change.
3. **Prefer asking the owner over digging through it.** [Added judgment] Put the question on the object that holds the data (`order.shippingCountry()`), so callers depend on a purpose, not on a structure. Check: renaming a nested field changes one class.
4. **Avoid temporal coupling: make ordering requirements explicit or remove them.** [MUST NOT] Check: for each "call A before B", the order is removed or explicit. Added judgment on the working form: explicit means enforced by code, and a comment is not enforcement.
5. **Prefer designs where the wrong order cannot be written.** [Added judgment] Construct objects ready to use (the constructor or a factory does the initialization), pass the result of step one as the input of step two so the type carries the proof, or offer one method that runs the sequence. Check: a caller who forgets a step gets a compile error or an immediate, named failure, not a silent wrong result.
6. **When an order cannot be removed, make it explicit.** [MUST] That is the source's requirement. Added judgment on the working form: state it in a name or a type, and also fail with a clear message at the first call that violates it (`pragmatic-programmer-contracts`). Check: the order is visible in the API, and the failure names the missing step.
7. **Use blackboard-style coordination only when uncertain order, multiple sources or opportunistic collaboration justify it.** [MUST NOT] Outside those conditions it is forbidden. Check: you can name which of the three conditions holds; if none does, use direct calls or a pipeline.
8. **If you use a blackboard, give it owners.** [Added judgment] Typed entries, one writer per key or a stated merge rule, documented readers, and no entry that exists only to pass a value between two steps. Otherwise it is global mutable state (`pragmatic-programmer-shared-state`). Check: for each key, who writes and who reads.
9. **Do not treat every chain as a violation.** [Added judgment] Fluent builders, stream pipelines and navigation inside one module's own structure return the same logical subject or plain values; they do not expose another module's internals. Check: the chain stays inside one abstraction.
10. **Keep collaborator knowledge small.** [Compact checklist] Check: a class needs few other types to do its job; a constructor that needs half the system is a signal.

## Procedure

1. Find chains: search business code for repeated member access and getters in sequence, then read each hit.
2. For each, ask whose knowledge it is. Move the question to the owner, or pass in the value the code actually needs.
3. Find order requirements: methods named `init`, `setup`, `start`, `prepare`, fields assigned after construction, comments saying "call X first".
4. Remove the order (constructor, factory, pipeline) or enforce it with a check that names the missing step.
5. For shared workspaces, apply rule 7 and then rule 8.
6. Run the tests; update callers one at a time.

## Example

```ts
// Before: the caller knows the shape of three objects and the order of three calls
const country = order.getCustomer().getAddress().getCountry();
const tax = taxFor(country, order.getTotal());

const client = new MailClient();
client.setCredentials(user, pass);   // must come before connect()
client.connect();                    // must come before send()
client.send(message);

// After
class Order {
  shippingCountry(): string { return this.customer.address.country; }
}
const tax = taxFor(order.shippingCountry(), order.total());

const client = await MailClient.connect({ user, pass });   // returns a connected client; there is no half-built state
client.send(message);
```

If the customer's address later moves into a separate record, `Order.shippingCountry` changes and its callers do not. A caller cannot call `send` on a client that never connected, because that object cannot be built.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Train wreck | Two or more hops past the first collaborator into another module's behavior-bearing objects (Added judgment, same threshold as rule 2) | Add the question to the owner |
| Init before use | `init()`, `setup()`, `start()` that callers must remember | Constructor or factory that returns a ready object |
| Context bag | A dictionary passed through steps, read and written by all | Pass typed values, or a blackboard with owners (rule 8) |
| Setter-injected requirement | A required collaborator assigned after construction | Constructor parameter |
| Wide public surface | Public members with no outside caller | Make private or delete |
| Middle man | A wrapper method per field of the wrapped object | Expose the questions callers actually ask |

## Trade-offs and exceptions

- Over-delegation is its own smell: one forwarding method per field makes a bloated API. Added judgment: add the question callers ask, not one method per hop.
- Plain data records are meant to be read. Navigating a record you were handed is not the violation; reaching through behavior-bearing objects owned by another module is (Added judgment).
- Frameworks sometimes impose a lifecycle (`init`, `start`, `stop`). Wrap it at the edge so your callers do not carry the order.
- A blackboard is legitimate for rule engines and multi-source enrichment where order is genuinely uncertain. The source allows it only with that justification.
- Dependency direction between layers is the territory of a Clean Architecture plugin.

## Verification

- [ ] No chain in the change reaches through another module's structure.
- [ ] Every required call order is enforced by construction or by a named failure.
- [ ] Every public member of a touched class has an outside caller.
- [ ] Any shared workspace has a stated reason (uncertain order, multiple sources or opportunistic collaboration) and owners per key.
- [ ] Tests cover the first call that violates an order requirement.

## Related

`pragmatic-programmer-orthogonality` for boundaries and ripple; `pragmatic-programmer-shared-state` for mutable state; `pragmatic-programmer-contracts` to enforce an order; `pragmatic-programmer-coupling-reviewer` to review a diff.

## Source

- `Resource and Coupling Rules`: only the rules on shy code, the Law of Demeter, temporal coupling and blackboard-style coordination.
