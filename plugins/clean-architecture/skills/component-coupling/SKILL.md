---
name: component-coupling
description: "Use when two packages or modules depend on each other, a stable component depends on a volatile one, or an abstract component has no reason to exist. Covers cycles, stability and abstractness. Layer import direction is dependency-rule, component membership is component-grouping."
---

# Component coupling

Owns the arrows between components: cycles, stability and abstractness. Direction of single imports across layers is `/clean-architecture:dependency-rule`; which classes sit in a component is `/clean-architecture:component-grouping`; a shared catch-all module that creates sideways coupling is `/clean-architecture:shared-code-coupling`.

## When to use

- Package A imports package B and B imports A, directly or through a third.
- A build or test cannot run one component without building a large part of the rest.
- A component many others depend on is changed often.
- An interface-only component has one implementation and one consumer in the same release.
- You are asked to compute or reason about instability and abstractness.

## Rules

1. **Avoid component cycles, and break them before they harden into deployment or test bottlenecks.** `[MUST NOT]` Check: build the component graph from imports that cross component boundaries; any strongly connected set of two or more components is a cycle.
2. **Keep stable components from depending on unstable details.** `[SHOULD NOT]` A component that many others rely on should not rely on something that changes often. Check: for each edge from A to B, B is at least as stable as A.
3. **Give an abstract component a concrete reason to exist.** `[SHOULD]` Check: every interface-only component has at least one implementation and one client that differ in layer, owner or release.
4. **Let the inner layer own the abstractions it needs and the outer layer implement them.** `[MUST]` The source states this without qualification (`Non-Negotiable Rules` rule 10, and the checklist item that ports are owned by inner layers); `/clean-architecture:ports-and-gateways` applies it per port. Check: abstractions live in the component that uses them, not in the component that provides the implementation. Preferring stable dependency targets, under the heading `Prefer Stable Dependencies`, is the `[SHOULD]` part and is rule 2.
5. **Break the cycle; the usual cure is to invert one edge.** `[MUST]` on breaking the cycle (rule 1). Added judgment on the technique: declare an interface in the component that needs the other and implement it in the other, so that only one direction of source dependency remains (`/clean-architecture:dependency-rule`). The alternative is rule 6. Check: after the change the component graph is acyclic.
6. **Know the other cure and its smell.** Added judgment (the book's resolution of cycles): extract the shared part into a new component that both depend on. Treat it with suspicion; it often only relocates shared code that lacked an owner (`/clean-architecture:shared-code-coupling`). Check: the new component has a capability name and an owner.
7. **Measure instability as a search aid.** Added judgment (the book's metric, not in the vendored rule set): `I = Ce / (Ca + Ce)`, where `Ce` counts dependencies from the component to classes in other components and `Ca` counts dependencies from other components to classes in it. `0` is maximally stable, `1` maximally unstable. Dependencies should lead toward lower `I`. Check: for each edge from A to B, `I(B) <= I(A)`. A component with no dependencies in either direction has no defined value; skip it.
8. **Measure abstractness as a second aid.** Added judgment (the book's metric): `A = abstract classes or interfaces / all classes` in the component. A stable component with `A` near zero is hard to change safely, because many depend on it and nothing in it can be extended; an unstable component with `A` near one is abstraction nobody uses. A rough check is `D = |A + I - 1|`; a component with a large `D` deserves a look.
9. **Use the numbers to find components to read, not to grade them.** Added judgment: a stable, concrete component that never changes (a vetted value type) is harmless. The risk is a component that is both depended upon and changing. Check: for each flagged component, ask how often it changed in the recent history.
10. **Make the component boundaries enforceable, so a new cycle fails a build.** `[MUST]` Use package structure, tests, dependency rules or build constraints. Added judgment: add the stable-direction check only where the team has chosen to enforce it, since that rule is `SHOULD NOT`. Check: a new cycle makes a check fail (`/clean-architecture:enforce-boundaries`).
11. **Count at component granularity.** Added judgment: class-level cycles inside one component are a design smell for that component's author, not a violation of this rule. Count only imports that cross a component boundary, and leave test code out of the metrics. Check: the graph's nodes are components, not files.

## Procedure

1. Define the components in scope (`/clean-architecture:component-grouping`) and list the imports that cross their boundaries; `clean-architecture:import-scanner` produces the raw counts.
2. Build the component graph and find cycles (rule 1).
3. For each cycle, choose the cure: invert one edge with an interface owned by the needier side (rule 5), or, after checking rule 6, extract the shared piece.
4. Compute `Ca`, `Ce` and `I` for each component; flag edges that lead toward higher instability (rule 7).
5. Compute `A` for the flagged components and read them (rules 8 and 9). Decide for each whether to add an abstraction, remove one, or leave it.
6. Add the check that keeps the graph acyclic (`/clean-architecture:enforce-boundaries`) and run the tests.

## Example

```java
// Before: orders -> inventory, and inventory -> orders. The two packages form a cycle.

// orders/PlaceOrder.java
package orders;
import inventory.StockService;                 // orders depends on inventory
public class PlaceOrder { /* calls stock.reserve(sku, quantity) */ }

// inventory/StockService.java
package inventory;
import orders.BackorderQueue;                  // inventory depends on orders
public class StockService {
    public void restock(String sku, int quantity) { /* ... */ backorders.release(sku); }
}
```

```java
// After: inventory declares the callback it needs; orders implements it

// inventory/RestockListener.java: inventory imports nothing from orders
package inventory;
public interface RestockListener {
    void onRestocked(String sku, int quantity);
}

// inventory/StockService.java
package inventory;
import java.util.List;
public class StockService {
    private final List<RestockListener> listeners;

    public StockService(List<RestockListener> listeners) {
        this.listeners = List.copyOf(listeners);
    }

    public void restock(String sku, int quantity) {
        /* update stock ... */
        listeners.forEach(l -> l.onRestocked(sku, quantity));
    }
}

// orders/BackorderQueue.java: orders -> inventory only
package orders;
import inventory.RestockListener;
public class BackorderQueue implements RestockListener {
    @Override
    public void onRestocked(String sku, int quantity) { release(sku); }
    void release(String sku) { /* fill waiting orders */ }
}

// composition root: new StockService(List.of(backorderQueue));
```

Before the change each package had one class-level dependency on the other, so `I = 1 / (1 + 1) = 0.5` for both. After it, `inventory` has `Ce = 0` and incoming dependencies from `orders`, so `I = 0`; `orders` has outgoing dependencies and none incoming, so `I = 1`. The only direction left leads from the unstable component to the stable one.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Mutual packages | Imports in both directions between two packages | Invert one edge with an interface the needier side owns |
| Cycle through a hub | A and B both depend on `events` or `shared`, which depends back on them | Remove the back edge; give the hub an owner |
| Hidden cycle | A cycle that only appears through re-exports or reflection | Count re-exports; remove the indirection |
| Stable but volatile | A package many depend on that changes weekly | Extract an abstraction it implements, or stabilize its API |
| Pointless abstraction | An interface-only package with one implementer and one consumer, released together | Merge it into its consumer |
| Cycle-hiding extraction | A new `common` component created only to break a cycle | Give the extracted code an owner and a capability name |

## Trade-offs and exceptions

- The three component rules in the source are one line each; the instability and abstractness formulas are the book's, shown here as search aids. No threshold is a rule of the source.
- Inside one component, cycles between classes may be fine; the rule concerns components that are built, tested or deployed separately.
- A small codebase with one component has no component graph to compute; do not invent components to run the metrics.
- Stable concrete components that do not change cost little; the abstractness measure matters only where change and dependents coincide.

## Verification

- [ ] The component graph has no cycle.
- [ ] Every edge leads from a less stable component to a more stable one, or the exception is explained.
- [ ] Every interface-only component has a distinct implementation and consumer.
- [ ] Cycles were broken by inverting an edge, or the extracted component has an owner.
- [ ] A check fails when a new cycle appears.
- [ ] The tests pass after the change.

## Related

`/clean-architecture:dependency-rule` for layer direction per import; `/clean-architecture:component-grouping` for membership; `/clean-architecture:solid-design` for DIP; `clean-architecture:component-coupling-reviewer` to review a graph; `clean-architecture:import-scanner` for the raw census.

## Source

- `Paradigm and Component Rules`: rules 10 and 11, avoiding cycles and balancing stability and abstraction.
- `Prefer Stable Dependencies`
- `Non-Negotiable Rules`: only rule 10, outer layers depend on inner layers and implement interfaces the inner layers own.
- `Refactoring Rules`: only the rule on replacing concrete dependencies with ports owned by inner layers.
- `Boundary Cost, Deployment, and Operations`: only the rule that boundaries must be enforceable.
