---
name: "clean-architecture-dependency-rule"
description: "Use when judging or writing an import between your own layers, a package dependency or an interface's home layer, or when inner code reaches outward. Covers import direction. Framework markers go to framework-independence, ORM and SQL to persistence-independence, cycles to component-coupling."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# The dependency rule

Owns the direction of source-code dependencies between layers. Which framework or storage marker sits inside a core class is `clean-architecture-framework-independence` and `clean-architecture-persistence-independence`; cycles and stability between components are `clean-architecture-component-coupling`; where a concrete object gets constructed is `clean-architecture-composition-root`.

## When to use

- A changed file in domain or application code gains an import.
- You are declaring a new interface and must choose which layer holds it.
- A reviewer asks "does this point inward?" and you need a defensible answer.
- A gateway interface is declared next to its implementation in infrastructure and a use case imports it from there.
- Two layers import each other, directly or through a re-exporting module.

## Rules

1. **Make source-code dependencies point inward, toward higher-level policy.** `[MUST]` A policy file that imports a detail has to change when the detail does. Check: for every import in a changed file, the imported module lives in the same layer or a more inward one.
2. **Do not let inner layers import or depend on outer layers.** `[MUST NOT]` Check: a search of the domain and application directories for adapter, infrastructure, web, driver and SDK module names returns nothing.
3. **Do not let a business rule rely on a web stack or handler, a database driver, a UI toolkit, a queue client, a remote service or any similar detail.** `[MUST NOT]` Check: a rule file imports only the language's standard library and modules of its own or a more inward layer. Added judgment: a library that would survive a change of framework, storage and delivery mechanism (decimal arithmetic, an immutable-collection library) is not a "detail" in the sense of this rule; ask whether replacing the web framework or the database would force you to replace it.
4. **Let outer layers depend on inner layers, never the reverse.** `[MUST NOT]` Controllers depend on use cases, gateways implement interfaces defined by the use case or domain layer, presenters implement output boundaries owned by inner layers. Check: for every interface, the file that declares it is at least as inward as every file that implements it.
5. **Never invert that relationship accidentally.** `[MUST NOT]` The usual accident is an editor auto-import that picks the nearest matching class. Check: each new import in the diff was read, not accepted by completion.
6. **Do not define a gateway interface in infrastructure and consume it from core policy, let entities import adapters, or let use cases depend on concrete implementations.** `[MUST NOT]` unless explicitly required and justified. Check: the constructor parameters of a use case are interfaces it owns or plain data.
7. **Do not let infrastructure be both imported by and importing inward code.** `[MUST NOT]` That shape means the layers have collapsed into one. Check: no import path leads from a domain or application module to an infrastructure module.
8. **Put four questions to every new import.** `[MUST]` Does it point inward? Does high-level policy end up relying on a low-level detail? Has a framework or vendor type slipped into a core layer? Is an adapter going around the boundary that should sit between it and the core? A yes to any of them means refactor.
9. **Fix an outward import by inverting it.** `[MUST]` Define the interface in the inner layer and implement it in the outer one. Added judgment: moving the importing file outward is a legitimate cure when the file was misplaced adapter code (a mapper sitting in the application directory, say) and holds no policy. It does not cure a use case that really needs the detail; that case still needs an interface the inner layer declares. Moving a detail inward only hides the arrow. Check: after the change the inner module names an interface it declared itself, or the moved file holds no policy.
10. **Make the direction checkable by a machine.** `[MUST]` Package structure, a test, a dependency rule or a build constraint should fail when an inner file imports an outer one (compact rules: a diagram or a folder name is not enough). See `/clean-architecture:enforce-boundaries`.
11. **Count indirect routes.** Added judgment: a barrel file, package initializer or facade that re-exports an outer module puts that module in the inner file's import graph. Check: follow each re-export one hop before accepting an import as inward.
12. **Judge direction by the layer map, not by folder names alone.** Added judgment: a directory called `domain` that imports `adapters` is not a domain layer. Check: build the map from what the code actually does (`/clean-architecture:layer-map`) when names and behavior disagree.

## Procedure

1. Establish the layer map from directory and package names, or run `/clean-architecture:layer-map`. Write down which directories are domain, application, adapters and infrastructure.
2. List the imports of every changed file (`git diff`, then a search of the import lines in those files).
3. Classify each import as same-layer, inward or outward. Treat third-party packages as outermost unless rule 3's exception clearly applies.
4. For each outward edge in an inner file choose one cure: pass the data in through a request model (`clean-architecture-boundary-models`), declare an interface in the inner layer and implement it outward (`clean-architecture-ports-and-gateways`), or, when the file is misplaced adapter code with no policy in it, move that file to an outer layer (rule 9).
5. Wire the concrete implementation in the composition root (`clean-architecture-composition-root`).
6. Run the tests, then list the imports again to confirm the edge is gone.

## Example

```ts
// Before: application/renewSubscription.ts imports two outer details
import { Pool } from "pg";
import type { Request } from "express";

export async function renewSubscription(req: Request, db: Pool): Promise<void> {
  const { rows } = await db.query(
    "select id, renews_on from subscriptions where id = $1",
    [req.params.id],
  );
  // renewal rule, parsing and SQL are interleaved from here on
}
```

```ts
// After. domain/subscription.ts defines Subscription with id, renewsOn, renew(today) and restore(id, renewsOn).

// application/renewSubscription.ts: imports only the domain and a port it declares itself
import { Subscription } from "../domain/subscription";

export interface SubscriptionStore {
  findById(id: string): Promise<Subscription | undefined>;
  save(subscription: Subscription): Promise<void>;
}

export interface RenewRequest {
  subscriptionId: string;
  today: Date;
}

export class RenewSubscription {
  constructor(private readonly store: SubscriptionStore) {}

  async execute(request: RenewRequest): Promise<void> {
    const subscription = await this.store.findById(request.subscriptionId);
    if (!subscription) throw new Error(`unknown subscription ${request.subscriptionId}`);
    subscription.renew(request.today);
    await this.store.save(subscription);
  }
}

// infrastructure/pgSubscriptionStore.ts: the only file that knows pg, and it imports inward
import { Pool } from "pg";
import { Subscription } from "../domain/subscription";
import { SubscriptionStore } from "../application/renewSubscription";

export class PgSubscriptionStore implements SubscriptionStore {
  constructor(private readonly db: Pool) {}

  async findById(id: string): Promise<Subscription | undefined> {
    const { rows } = await this.db.query(
      "select id, renews_on from subscriptions where id = $1",
      [id],
    );
    return rows[0] && Subscription.restore(rows[0].id, rows[0].renews_on);
  }

  async save(subscription: Subscription): Promise<void> {
    await this.db.query("update subscriptions set renews_on = $2 where id = $1", [
      subscription.id,
      subscription.renewsOn,
    ]);
  }
}
```

The arrows now run `infrastructure -> application -> domain`. At run time control still flows outward, through the interface; only the source dependency was reversed.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Interface beside its implementation | An interface declared in an infrastructure file and imported by a use case | Move the declaration to the application layer |
| Auto-import drift | `../infrastructure` or `../adapters` appearing in an application import list | Replace with a port the application declares |
| Folder-name layering | A `domain/` directory whose files import web, ORM or SDK modules | Move the dependency behind a port or the code outward |
| Mutual layers | Two layers importing each other | Invert one edge; see `clean-architecture-component-coupling` for cycles |
| Barrel leak | An index file re-exporting an adapter into an inner package | Remove the re-export; import the port directly |
| Concrete parameter | A use case constructor typed with a concrete client class | Type it with the interface the use case owns |

## Trade-offs and exceptions

- The rule governs source dependencies, not the direction of control at run time. A use case calling a gateway through an interface is the intended shape.
- The source asks to avoid annotations and infrastructure imports in the domain "where possible", and forbids the patterns above "unless explicitly required and justified". When a framework forces a violation, keep it at the outermost point possible, document it and keep a path to separation (`clean-architecture-boundary-economics`).
- Imports within one layer are not governed by this rule; cycles among them are a component question.
- Added judgment: test code sits at the outermost position and may import anything it needs, but a core test that needs the real framework to run is a signal (`clean-architecture-testing-seams`).

## Verification

- [ ] Every import in the changed inner files points to the same layer or a more inward one.
- [ ] Every interface is declared in a layer at least as inward as its implementations and its callers' clients.
- [ ] No use case or entity names a concrete adapter or infrastructure class.
- [ ] No import path leads from domain or application code to infrastructure.
- [ ] A test, lint rule or build constraint would fail on a new outward import.
- [ ] The tests pass after the inversion.

## Related

`clean-architecture-ports-and-gateways` for shaping and naming the inverted interface; `clean-architecture-boundary-models` for data that must enter instead; `/clean-architecture:enforce-boundaries` to make the rule executable; `clean-architecture-import-direction-reviewer` to review a diff; `clean-architecture-import-scanner` for a raw edge census.

## Source

- `Non-Negotiable Rules`: rules 1 and 10, the dependency rule and the direction of dependencies.
- `Dependency Direction`
- `Direction Violations`
- `Layer Bypass`: only the rule on infrastructure that is both imported by and importing inward code.
- `Preferred dependency pattern`
- `Refactoring Rules`: only the rule on replacing concrete dependencies with ports.
- `Boundary Cost, Deployment, and Operations`: only the rule that boundaries must be enforceable.
