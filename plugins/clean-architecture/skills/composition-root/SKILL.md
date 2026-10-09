---
name: composition-root
description: "Use when deciding where objects are built and wired, when a use case or entity instantiates infrastructure, or when a constructor gains a dependency. Covers the main component and explicit construction. Interface design belongs to ports-and-gateways, container annotations to framework-independence."
---

# Composition root

Owns where concrete objects are created and connected: the main component at the outermost edge. What an interface looks like and who owns it is `/clean-architecture:ports-and-gateways`; the import direction that wiring must respect is `/clean-architecture:dependency-rule`; framework registration annotations are `/clean-architecture:framework-independence`.

## When to use

- A use case, entity or domain service calls a constructor for a client, store or driver.
- A new dependency must be passed to a use case and you need to decide who builds it.
- A static singleton or global lookup is used from core code to obtain a collaborator.
- Environment variables, config files or flags are read in the middle of business code.
- `main` or the bootstrap code has grown business branching.

## Rules

1. **Keep object construction in the composition root.** `[MUST]` Check: constructors of infrastructure classes are called in the main component and in tests, nowhere else.
2. **Do not instantiate infrastructure dependencies inside use cases or entities.** `[MUST NOT]` Check: no `new`, factory call or client builder for a store, driver, mailer or SDK appears in the application or domain directories.
3. **Use explicit construction, factories or composition in the outer layer.** `[MUST]` Check: you can read the object graph top to bottom in one place.
4. **Put framework bootstrap, the object graph and component wiring in the infrastructure layer.** `[MUST]` Check: the entry point is the outermost module and nothing imports it.
5. **Keep infrastructure replaceable and at the outermost edge.** `[MUST]` Check: replacing an adapter means editing one wiring line and adding one class.
6. **Let the root be the only place that constructs the concrete adapters and hands them to the policy.** `[SHOULD]` Added judgment drawn from the preferred pattern: the inner layer defines the interface, the outer layer implements it, and the composition root connects them. An adapter file still names the port it implements and its own class; what only the root does is build the adapter and pass it inward. Check: a concrete adapter's name appears in its own file, in the root and in tests.
7. **Do not read configuration directly from business code.** `[MUST NOT]` Check: environment variables, config files and flags are read in the root (or an infrastructure loader) and handed inward as typed values.
8. **Keep the concerns of building, shipping, running and maintaining the system visible, and never let them decide business policy.** `[MUST]` Check: the root handles listen addresses, timeout settings, feature switches and logging setup; no business rule is decided there.
9. **Do not bundle unrelated use cases into one object because wiring is easier.** `[MUST NOT]` Check: no class named for "all use cases" or "the services" is passed to every controller.
10. **Pass collaborators in through constructors or parameters.** Added judgment: prefer them to setters and to a service locator. A locator lets core code reach outward at run time, and that arrow is invisible to import analysis. Check: a use case's dependencies are readable from its constructor signature.
11. **Keep the root boring.** Added judgment: straight-line construction with no domain conditionals. A conditional that depends on business meaning is policy and belongs inward. Check: the root contains no comparison on a domain value.

## Procedure

1. Search the application and domain directories for constructors of infrastructure types, static accessors, container lookups and configuration reads.
2. For each, introduce a constructor parameter typed with the port the code needs (`/clean-architecture:ports-and-gateways`), or a plain value for configuration.
3. Create the wiring in the entry point: build adapters, build use cases with them, build controllers or listeners with the use cases, start the framework.
4. If a use case needs to create objects at run time (one per request), give it a factory interface that it owns and implement the factory in the outer layer.
5. Delete the old construction sites and static accessors.
6. Run the tests, and start the application once to verify the graph is complete.

## Example

```go
// Before: the use case opens its own database connection from the environment
package application

type RenewPermit struct{}

func (r RenewPermit) Execute(id string) error {
	db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		return err
	}
	defer db.Close()
	// load the permit, apply the renewal, save it ...
	return nil
}
```

```go
// After: application/renew_permit.go receives what it needs
package application

import "time"

type PermitStore interface {
	Find(id string) (Permit, error)
	Save(p Permit) error
}

type RenewPermit struct {
	store PermitStore
	now   func() time.Time
}

func NewRenewPermit(store PermitStore, now func() time.Time) *RenewPermit {
	return &RenewPermit{store: store, now: now}
}
```

```go
// cmd/permits/main.go: the one file that constructs the adapters and hands them to the use cases
package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq" // driver registration, outermost file only

	"example.org/permits/application"
	"example.org/permits/adapters/web"
	"example.org/permits/infrastructure/postgres"
)

func main() {
	db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}

	store := postgres.NewPermitStore(db)
	renew := application.NewRenewPermit(store, time.Now)

	mux := http.NewServeMux()
	mux.Handle("/permits/renew", web.NewRenewHandler(renew))
	log.Fatal(http.ListenAndServe(":8080", mux))
}
```

Swapping Postgres for another store means a new type implementing `PermitStore` and one changed line in `main`. The environment variable is read once, in the entry point.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Construction in policy | Calls to client or driver constructors in application or domain code | Inject a port-typed parameter |
| Service locator | A static `Container.get(...)` or registry lookup used from core code | Constructor parameters; wire in the root |
| Config in the core | Environment or settings reads in business code | Read in the root; pass typed values |
| God container | One object holding every use case, passed everywhere | Pass each controller only the use cases it calls |
| Smart main | Business branching in the entry point | Move the branch into an entity or use case |
| Scan-wired core | Core classes annotated so a framework scan discovers them | Register them from a configuration class in infrastructure |

## Trade-offs and exceptions

- A dependency-injection container is a detail and is allowed in the outer layer; plain explicit construction is the simplest start. The source asks for "explicit construction, factories, or composition", not for any particular tool.
- Small programs have a short `main`; do not invent a wiring framework for twenty lines.
- When an object depends on runtime data (a request, a tenant), pass a factory the inner layer owns instead of constructing inside the core.
- A service locator at the very edge (inside a framework callback that cannot take constructor parameters) is a compromise; keep it there, document it and keep the core free of it (`/clean-architecture:boundary-economics`).

## Verification

- [ ] No infrastructure constructor is called in application or domain code.
- [ ] Configuration is read only in the root or an infrastructure loader.
- [ ] Every use case lists its dependencies in its constructor signature.
- [ ] The entry point is the only module that constructs the concrete adapters and hands them to the policy.
- [ ] The root contains no business decision.
- [ ] The application starts and the tests pass after the change.

## Related

`/clean-architecture:ports-and-gateways` for the interfaces being wired; `/clean-architecture:introduce-port` to move one construction site out; `/clean-architecture:framework-independence` for container annotations; `clean-architecture:wiring-reviewer` to review a diff.

## Source

- `Keep Wiring in the Main Component`
- `Infrastructure Layer`
- `Preferred dependency pattern`
- `Domain Layer`: only the rule that the domain does not read configuration directly.
- `Boundary Cost, Deployment, and Operations`: only the rules on keeping operational concerns visible and not combining unrelated use cases for wiring.
- `When Tradeoffs Are Necessary`: only the handling of a compromise at the edge.
