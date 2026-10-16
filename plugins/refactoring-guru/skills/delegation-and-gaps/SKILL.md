---
name: delegation-and-gaps
description: "Use when client code walks a chain of objects (message chains), a class only forwards calls (middle man), or a library class lacks an operation you keep working around (incomplete library class). Balances hiding delegates against removing layers; mechanics: moving-features."
---

# Delegation and gaps

Owns three Couplers about the paths between objects and the edge to code you cannot change: Message Chains, Middle Man and Incomplete Library Class. Hide Delegate and Remove Middle Man are inverse moves, so this skill exists to decide which direction a layer should go. Who owns a piece of logic is `/refactoring-guru:behavior-ownership`; the mechanics of the moves are `/refactoring-guru:moving-features`.

## When to use

- Client code reads like `order.customer.address.city`, or navigates several objects to reach one value or call.
- A class has many methods whose bodies are a single call to another object.
- The same small workaround for a library or framework class appears in several places.
- A review comment says "why does the caller know the shape of this graph?" or "why does this class exist?".

## Rules

1. **Treat client code that navigates through a chain of objects to reach data or behavior as Message Chains.** Hide the delegate behind the object the client already knows (`SHOULD`). Check: after the change the client names one object and one operation.
2. **Move behavior closer to the data instead of making clients navigate structure** (`SHOULD`), as the fallback. Check: the logic that used the chain now runs next to the data it read.
3. **Do not expose object graph topology as a routine calling convention** (`MUST NOT`). Check: changing who owns the address does not change any caller.
4. **Do not use Hide Delegate when it only creates a pure pass-through layer that reduces no knowledge.** A forwarding method must carry meaning or policy, or it is the risky rung. Check: the new method has a domain name (`shippingCity`), not a path name (`getAddressCity`).
5. **Treat a class that mostly forwards calls and adds no policy, coordination or protection as a Middle Man, and remove it when direct collaboration is clearer** (`SHOULD`). Check: its methods are single calls to the same collaborator.
6. **Inline a class that exists only as a pass-through** (`SHOULD`), as the fallback. Check: after inlining, its callers depend on the real collaborator and the dependency is not surprising.
7. **Keep a delegating layer when it protects a boundary, hides volatile structure or provides useful policy** (`SHOULD`). Removing such a layer is the risky rung. Check: you can name what would break or leak if the layer disappeared.
8. **Do not preserve a forwarding class merely because deleting it requires caller updates** (`MUST NOT`). Check: "many callers" is not the only argument for keeping it.
9. **Decide Hide Delegate versus Remove Middle Man by one question: does the layer reduce what callers must know, or add policy?** Added judgment. Check: if both answers are no, remove it; if either is yes, keep or add it.
10. **For an Incomplete Library Class, use Introduce Foreign Method for one or two missing operations** (`SHOULD`), as the preferred rung. Check: the method is a local helper near its use, named as if it belonged to the library type.
11. **Use Introduce Local Extension when missing behavior is substantial and repeated** (`SHOULD`), as the fallback. Check: at least several call sites share the behavior.
12. **Do not scatter repeated library workarounds throughout the codebase** (`MUST NOT`), and do not fork or wrap a library broadly when one narrow foreign method solves the gap (`MUST NOT`). Check: no wrapper re-exports the library's whole surface.

### Treatment ladder

| Smell | Preferred | Fallback | Risky |
| --- | --- | --- | --- |
| Message Chains | Hide Delegate | Move Method closer to the data | Adding a middle man that only forwards without reducing knowledge |
| Middle Man | Remove Middle Man | Inline Class | Removing a boundary that hides volatile structure or policy |
| Incomplete Library Class | Introduce Foreign Method for a narrow gap | Introduce Local Extension for repeated substantial behavior | Broad library wrapping or forking |

## Procedure

1. For a chain, count the objects the caller needs to know. Added judgment: three or more hops in a decision is a prompt to look, not a rule.
2. For a forwarding class, count methods that are a single call, and list what policy, if any, the class adds.
3. For a library gap, count the occurrences of the workaround and how much behavior it is.
4. Choose the rung; for chains, name the new method by the question the client asks, not by the path.
5. Hand the mechanics to `/refactoring-guru:moving-features`; migrate callers one at a time with tests after each.
6. Re-read the result for a new middle man (it is one of the smells the after-editing check looks for).

## Example

A report reads the shipping city through the whole graph, and checks for weekends with a snippet repeated at call sites.

```python
from dataclasses import dataclass
from datetime import date

@dataclass
class Address:
    city: str

@dataclass
class Customer:
    address: Address

@dataclass
class Order:
    customer: Customer
    placed_on: date

    # Hide Delegate: callers ask the order a question, not the graph
    def shipping_city(self) -> str:
        return self.customer.address.city

# Before (at each call site)
city = order.customer.address.city
weekend = order.placed_on.weekday() >= 5

# After
city = order.shipping_city()

# Introduce Foreign Method: the standard date type has no such operation
def is_weekend(d: date) -> bool:
    return d.weekday() >= 5

weekend = is_weekend(order.placed_on)
```

`shipping_city` has a domain name and tells callers nothing about the graph, so the order can later store the city itself without touching clients. `is_weekend` is one narrow helper; a wrapper around `date` would be the risky rung for a gap this small.

## Anti-patterns

- **Path-named forwarder.** `getCustomerAddressCity()` added to the order. Detect: the new name repeats the path; the policy or meaning is absent.
- **Forwarding class kept for convenience.** A class retained because removal means editing callers. Detect: all methods are one-line calls and the only argument is churn.
- **Law-of-everything wrapping.** Every library class wrapped "for flexibility". Detect: wrappers with a 1:1 method list.
- **Scattered workaround.** The same three lines compensating for a library gap in many files. Detect: duplicated snippets around a specific library call.
- **Removing the boundary.** Deleting a layer that isolates a volatile service. Detect: after removal, many files import the volatile client.

## Trade-offs and exceptions

- A delegating layer may stay when it hides volatile structure, applies policy or marks a boundary.
- Hide Delegate can create a middle man if applied to every collaborator; apply it where clients genuinely should not know the structure.
- A local extension has upkeep costs: verify compatibility with library construction and updates.
- Added judgment: if the library may add the missing operation itself soon, keep the foreign method private and small so it can be dropped.

## Verification

- [ ] Each new forwarding method has a domain name and carries meaning or policy.
- [ ] Callers know fewer objects after the change.
- [ ] Removed layers were not hiding a boundary, volatility or policy.
- [ ] Library workarounds are in one place, and no wrapper mirrors the whole library.
- [ ] Tests ran after each migrated call site.

## Related

`/refactoring-guru:moving-features` for Hide Delegate, Remove Middle Man, Introduce Foreign Method and Introduce Local Extension; `/refactoring-guru:behavior-ownership` for which class owns logic; `refactoring-guru:coupling-reviewer` to review a diff; `/refactoring-guru:public-compatibility` before removing a layer others depend on.

## Source

- `Couplers`: only the Message Chains, Middle Man and Incomplete Library Class entries.
- `Message Chains`
- `Middle Man`
- `Incomplete Library Class`
- `Smell-to-Treatment Priority Map`: only the Message Chains, Middle Man and Incomplete Library Class rows.
- `Moving Features Playbook`: only the Hide Delegate, Remove Middle Man, Introduce Foreign Method and Introduce Local Extension entries.
- `Decision Anti-Patterns`: only the rule on preserving a forwarding class because deleting it requires caller updates.
