# Patterns of Enterprise Application Architecture plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` and `###` headings of `skills/principles/references/full.md`.

## Design decisions

1. **One skill per pattern family, not per upstream section.** The upstream rule set is short, but its pattern indexes name more than fifty patterns. Skills follow the families a reader meets in code: business logic, application workflow, data source, write coordination, loading, object-relational structure, inheritance, queries and metadata, offline locking, presentation, integration, remoting, session state and base patterns. A family that mixes unrelated triggers is split; a family with one trigger stays whole.
2. **Every pattern in the upstream indexes has exactly one owning skill** (table below). Other skills may mention it and point to the owner.
3. **The book's own brake is built into every component.** The source says "choose the smallest set of enterprise patterns" and rejects fashionable complexity. Each skill states when the pattern is not warranted, and `choose-pattern`, `escalate-pattern` and the `force-first` mode are the workflow expression of that brake.
4. **Source-only rules versus background.** The rule set gives conditions ("Use when ...") and prohibitions, not mechanics. Where a skill adds how a pattern works (for example how a version column is checked) that is general knowledge of the catalog, written as procedure, and any threshold or heuristic is labelled "Added judgment". Rules that exist only in `mini.md` or `nano.md` are labelled "compact checklist".
5. **Model-invocable skills are capped at 20.** There are exactly 20. Everything that is a procedure with arguments is a manual skill (12), three of them forked.
6. **Reviewers own one concern and have their own output shape.** The layering reviewer reports a layer map, the transaction reviewer a write trace, the lock reviewer a conflict matrix, the remote reviewer a call-count table. Implementers are separated by situation: moving a decision, extracting data access, building a facade, adding a lock, writing tests.
7. **Sibling book plugins are named, never linked.** The compatibility docs mark `ddd` and `ddd-implementing` as conflicting and `clean-architecture` and `ddd-distilled` as overlapping, so this plugin never prescribes DDD tactical patterns itself and says so in `principles`.
8. **Blocker is reserved for the six forbidden patterns.** `review`, `strict-reviewer` and every specialist reviewer use the same scale (`final-gate` is binary and has no scale): a blocker is an instance of one of the six forbidden patterns, a review-rule finding or a MUST NOT anti-pattern is at most major, a "should" or "prefer" rule is minor, naming is a nit. The source ranks nothing, so every band beyond the blocker class is labelled added judgment in the component that uses it. A reviewer with no forbidden-pattern carrier says "no blocker class" in its template.

## Pattern ownership

Every pattern named in the upstream rule set has exactly one owner.

| Pattern | Owner skill |
| --- | --- |
| Transaction Script, Table Module, Domain Model | `business-logic-patterns` |
| Service Layer | `service-layer` |
| Repository | `repository` |
| Data Mapper | `data-mapper` |
| Row Data Gateway, Table Data Gateway, Active Record | `gateways-and-active-record` |
| Unit of Work (and transaction boundaries) | `transactions-and-unit-of-work` |
| Identity Map, Lazy Load | `loading-behavior` |
| Identity Field, Foreign Key Mapping, Association Table Mapping, Dependent Mapping, Embedded Value, Serialized LOB | `relational-mapping-structure` |
| Single Table Inheritance, Class Table Inheritance, Concrete Table Inheritance, Inheritance Mappers | `inheritance-mapping` |
| Metadata Mapping, Query Object | `query-and-metadata-mapping` |
| Optimistic Offline Lock, Pessimistic Locking, Coarse-Grained Lock, Implicit Lock | `offline-locking` |
| Presentation responsibilities (input, rendering, transport, presentation models) | `presentation-layer` |
| Model View Controller, Page Controller, Front Controller, Template View, Transform View, Two Step View, Application Controller | `web-presentation-patterns` |
| Gateway (to external resources) | `integration-boundaries` |
| Remote Facade, Data Transfer Object | `remote-boundaries` |
| Client, Server and Database Session State | `session-state` |
| Mapper, Layer Supertype, Separated Interface, Registry, Plugin, Value Object, Money, Special Case, Record Set | `base-patterns` |
| Service Stub | `testing-by-responsibility` |

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priority, final checklist | Purpose; Primary Directive; Architectural Baseline; Code Generation Rules; Review Rules; Forbidden Patterns; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules itself. |
| `layering` | Four layers, dependency direction, layers that earn their cost, responsibilities that must not collapse into one class | Architectural Baseline; Layering; Primary Directive; Layering Theater; Controller-Centric Enterprise App; Code Generation Rules | `service-layer` designs the application layer's operations; `layering` decides which layer owns what and what may depend on what. |
| `business-logic-patterns` | Choose Transaction Script, Table Module or Domain Model by force, keep each honest, escalate when it outgrows its pattern | Choosing the Business Logic Pattern; Transaction Script; Table Module; Domain Model; Code Generation Rules; Review Rules | `service-layer` is about use-case coordination; this skill is about where business decisions live. |
| `service-layer` | Application operations, orchestration, application-oriented API, not a domain-logic bucket | Application Workflow Rules; Service Layer; Code Generation Rules | `business-logic-patterns` places decisions; `service-layer` places coordination. Transaction mechanics are `transactions-and-unit-of-work`. |
| `repository` | Collection-like, domain-term access, hidden query and storage details, no generic everything-gateway | Persistence Pattern Rules; Repository; Generic Repository Everywhere; Layering | `data-mapper` is how objects are copied to and from storage; `repository` is the interface the domain code sees. |
| `data-mapper` | Mapping code outside domain objects, explicit and testable mapping, when decoupling is worth it | Persistence Pattern Rules; Data Mapper; ORM-Driven Everything; Active Record | It judges mapping code and domain purity; `repository` judges the access interface; `gateways-and-active-record` covers the couplings the mapper avoids. |
| `gateways-and-active-record` | Choose Row Data Gateway, Table Data Gateway or Active Record for simple, table-shaped or record-shaped work | Persistence Pattern Rules; Row Data Gateway; Table Data Gateway; Active Record; Code Generation Rules | The three choices that accept persistence coupling; the other two persistence skills defend decoupling. |
| `transactions-and-unit-of-work` | Explicit transaction owner, short transactions, no remote calls inside, one logical commit, no ad hoc saves | Concurrency and Transaction Rules; Transaction Boundaries; Unit of Work; Identity, Caching, and Unit-of-Work Rules; Unclear Transaction Ownership; Testing Rules | `offline-locking` handles conflicts across user-level edits; this skill handles the boundary of one unit of work. |
| `loading-behavior` | One in-memory object per identity per scope, deliberate lazy loading, N+1 and serialization traps | Identity, Caching, and Unit-of-Work Rules; Identity Map; Lazy Load; Object-Relational Mapping Pattern Index; Review Rules; Review Checklist | It is about reading and identity; `transactions-and-unit-of-work` is about writing. |
| `relational-mapping-structure` | Identity fields, foreign keys, association tables, dependent children, embedded values, serialized LOBs | Object-Relational Mapping Pattern Index | `inheritance-mapping` owns hierarchy strategies; `query-and-metadata-mapping` owns how mappings and queries are expressed. |
| `inheritance-mapping` | Choose single, class or concrete table inheritance and isolate it behind inheritance mappers | Object-Relational Mapping Pattern Index | Triggered only by a class hierarchy being persisted. |
| `query-and-metadata-mapping` | Composable query objects instead of scattered SQL, metadata mapping only when regular | Object-Relational Mapping Pattern Index; Review Rules; Final Instruction | It is about how queries and mapping rules are expressed; `repository` decides which queries exist. |
| `offline-locking` | Optimistic, pessimistic, coarse-grained and implicit locks for user-level edits | Concurrency and Transaction Rules; Optimistic Offline Lock; Pessimistic Locking; Additional Offline Concurrency Patterns; Unclear Transaction Ownership; Testing Rules | Conflicts that span several requests; `transactions-and-unit-of-work` covers one transaction. |
| `presentation-layer` | What presentation code may own, presentation models, rules that must not live in handlers and views | Presentation Layer Rules; Controller-Centric Enterprise App; Layering; Review Rules | `web-presentation-patterns` picks the request-handling and view pattern; this skill decides what is allowed inside it. |
| `web-presentation-patterns` | Choose MVC, Page Controller, Front Controller, Template View, Transform View, Two Step View, Application Controller | Presentation Pattern Index; Presentation Layer Rules; Final Instruction | Pattern selection for request handling and rendering; ownership rules are `presentation-layer`. |
| `integration-boundaries` | Gateway to external systems, translate partner formats, no vendor DTOs across the app | Offline and Integration Rules; Session State and Base Pattern Index; Review Rules | Triggered by partner or vendor payloads; `remote-boundaries` is triggered by call counts and API shape of distributed pieces. |
| `remote-boundaries` | Do not distribute by default, coarse operations, Remote Facade, DTOs, latency/versioning/partial-failure budget | Distribution Rules; Remote Facade; Data Transfer Object; Application Workflow Rules; Distributed Object Fantasy; Code Generation Rules | Triggered by chatty calls and API shape; `integration-boundaries` is triggered by foreign formats. |
| `session-state` | Client, server or database session state with owner, security, scaling, cleanup | Session State and Base Pattern Index; Presentation Layer Rules | Per-user state between requests; `presentation-layer` only says UI state stays out of the domain. |
| `base-patterns` | Mapper, Layer Supertype, Separated Interface, Registry, Plugin, Value Object, Money, Special Case, Record Set under concrete pressure | Session State and Base Pattern Index | Small supporting patterns only; every major family has its own skill. |
| `testing-by-responsibility` | Test each behavior at the layer that owns it; locks, mappers, facades; Service Stub | Testing Rules; Session State and Base Pattern Index | It decides what to test where; it never judges test style, which belongs to a testing plugin. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Review Checklist; Forbidden Patterns | `audit` scans a tree; `review` judges a change. |
| `audit` | yes | no | Health picture of a tree per pattern family, at most 40 lines | Review Rules; Review Checklist; Architectural Baseline | `blocker-scan` hunts the six forbidden patterns; `audit` rates every family. |
| `plan` | no | no | Plan a non-trivial change in the generation order with an explicit transaction and test plan | Code Generation Rules; Final Instruction; Testing Rules | `build-feature` carries the order out; `plan` stops at the plan. |
| `explain-rule` | no | no | Explain one rule: strength, reason, check, original example, exceptions | Purpose; Primary Directive | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the book's review checklist with yes, no or not applicable and a next step for each no | Review Checklist; Final Instruction | `final-gate` is the isolated pass/fail gate; `checklist` is the in-session walk. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Review Rules; Code Generation Rules | `escalate-pattern` chooses and starts a pattern change; `fix` only resolves given findings. |
| `choose-pattern` | no | no | Turn a situation into forces, recommend the smallest fitting pattern with rejected alternatives | Choosing the Business Logic Pattern; Persistence Pattern Rules; Code Generation Rules; Final Instruction | It answers "which pattern"; `plan` answers "in what steps". |
| `responsibility-map` | yes | no | Table of who owns each of the seven responsibilities per use case or class, with collisions | Primary Directive; Purpose; Architectural Baseline | `layering-reviewer` judges layer edges in a diff; this maps ownership across a scope before design. |
| `blocker-scan` | yes | no | Hunt the six forbidden patterns across a tree and name each instance | Forbidden Patterns; Layering Theater; Generic Repository Everywhere; ORM-Driven Everything; Controller-Centric Enterprise App; Distributed Object Fantasy; Unclear Transaction Ownership | `audit` rates families; this reports only blocker-class instances. |
| `escalate-pattern` | no | yes | When a Transaction Script has outgrown itself, move one repeated decision into the model and name the persistence follow-up | Transaction Script; Domain Model; Choosing the Business Logic Pattern; Review Rules | `logic-mover` is the delegated agent for a finding list; this skill decides whether to escalate and does the first slice. |
| `remote-contract` | no | no | Design a coarse remote operation: request and response DTOs, translation, versioning, failure budget | Remote Facade; Data Transfer Object; Distribution Rules | `facade-builder` implements a contract; this skill produces it. |
| `build-feature` | no | yes | Implement a new use case slice by slice in the book's generation order | Code Generation Rules; Testing Rules; Transaction Boundaries | `plan` only plans; `build-feature` edits, tests and reports. |

## Subagents (21)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to specialists and skills; does not review | principles | Primary Directive; Review Rules; Final Instruction | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the review checklist on the working diff and returns PASS or FAIL | principles | Review Checklist; Forbidden Patterns | Binary gate with evidence; reviewers return ranked findings. |
| `layering-reviewer` | sonnet | Layer map, illegal dependency edges, pass-through layers | layering | Architectural Baseline; Layering; Layering Theater; Controller-Centric Enterprise App | Output is a layer map; `logic-placement-reviewer` follows decisions, not imports. |
| `logic-placement-reviewer` | sonnet | Decision ledger: which business decision lives where, pattern fit | business-logic-patterns | Choosing the Business Logic Pattern; Transaction Script; Table Module; Domain Model; Review Rules | Judges where decisions live; `service-layer-reviewer` judges coordination. |
| `service-layer-reviewer` | sonnet | Operation inventory of application services | service-layer | Application Workflow Rules; Service Layer; Code Generation Rules | Judges the service surface and thickness; transaction ownership is `transaction-reviewer`. |
| `persistence-reviewer` | sonnet | Access-path inventory: repository, mapper, gateway or active record, and purity of each | repository, data-mapper, gateways-and-active-record | Persistence Pattern Rules; Repository; Data Mapper; Row Data Gateway; Table Data Gateway; Active Record; Generic Repository Everywhere; ORM-Driven Everything | Judges the access interface and coupling; `mapping-reviewer` judges table and column structure. |
| `transaction-reviewer` | sonnet | Write trace: who opens, who commits, what is inside, remote calls in transactions | transactions-and-unit-of-work | Concurrency and Transaction Rules; Transaction Boundaries; Unit of Work; Unclear Transaction Ownership | Output is a write trace per use case; `lock-reviewer` looks at concurrent edits. |
| `loading-reviewer` | sonnet | Load-path report: duplicate identities, lazy loads in loops and serializers, N+1 | loading-behavior | Identity, Caching, and Unit-of-Work Rules; Identity Map; Lazy Load; Review Rules | Reads, not writes. |
| `mapping-reviewer` | sonnet | Mapping table: identity, associations, value placement, inheritance strategy, query construction | relational-mapping-structure, inheritance-mapping, query-and-metadata-mapping | Object-Relational Mapping Pattern Index; Review Rules | Judges schema-to-object structure; `persistence-reviewer` judges the access interface. |
| `lock-reviewer` | sonnet | Conflict matrix: concurrent edits, lock type, failure behavior, stale locks | offline-locking | Concurrency and Transaction Rules; Optimistic Offline Lock; Pessimistic Locking; Additional Offline Concurrency Patterns | Output is a conflict matrix per edited entity. |
| `presentation-reviewer` | sonnet | Leak report: business rules or SQL in handlers and views, pattern fit | presentation-layer, web-presentation-patterns | Presentation Layer Rules; Presentation Pattern Index; Controller-Centric Enterprise App | Looks only at the presentation edge; `logic-placement-reviewer` looks at where the moved logic should land. |
| `integration-reviewer` | sonnet | Translation report: partner payloads in internal code, gateway presence, messages as domain objects | integration-boundaries | Offline and Integration Rules; Review Rules | Foreign formats; `remote-api-reviewer` is about call counts and API shape. |
| `remote-api-reviewer` | sonnet | Call-count table per user action; chattiness, leaked internals, missing translation | remote-boundaries | Distribution Rules; Remote Facade; Data Transfer Object; Distributed Object Fantasy | Output is a call-count table. |
| `session-state-reviewer` | sonnet | Session inventory: what is stored, where, owner, lifetime, trust | session-state | Session State and Base Pattern Index; Presentation Layer Rules | Only state between requests. |
| `base-pattern-reviewer` | sonnet | Small-pattern review: registries, supertypes, money, repeated null handling | base-patterns | Session State and Base Pattern Index | Small supporting patterns only. |
| `test-alignment-reviewer` | sonnet | Map of behavior to the test level that should own it | testing-by-responsibility | Testing Rules; Session State and Base Pattern Index | Reviews test placement; never writes tests. |
| `logic-mover` | sonnet | Moves a business decision from a handler, script, SQL or DTO to its owning layer in small steps | business-logic-patterns, service-layer | Choosing the Business Logic Pattern; Domain Model; Review Rules | Takes decisions out of the wrong place; `persistence-extractor` takes data access out. |
| `persistence-extractor` | sonnet | Extracts SQL, mapping or storage detail behind a repository, mapper or gateway | repository, data-mapper | Persistence Pattern Rules; Repository; Data Mapper; Generic Repository Everywhere | Moves data access; never moves business decisions. |
| `facade-builder` | sonnet | Builds a coarse Remote Facade and DTO mapping over local objects | remote-boundaries | Remote Facade; Data Transfer Object | Edits the boundary only. |
| `lock-adder` | sonnet | Adds an optimistic lock (version check and conflict path) to one entity | offline-locking | Optimistic Offline Lock; Additional Offline Concurrency Patterns | The only agent that changes write statements and schema for concurrency. |
| `test-writer` | sonnet | Writes tests at the layer that owns each behavior | testing-by-responsibility | Testing Rules; Session State and Base Pattern Index | Writes tests only; never edits production code. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Purpose; Final Instruction | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Forbidden Patterns | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Code Generation Rules | Interaction rhythm. |
| `terse` | Result first, few lines, failing output in full | Final Instruction | Brevity. |
| `force-first` | Prints the forces and the smallest fitting pattern, its escalation trigger and the rejected alternative before any design or code | Choosing the Business Logic Pattern; Primary Directive; Final Instruction | Pattern selection is shown, not implied. It prints the forces inline, as a short header on every design or code answer for the whole session, and covers only the one decision that answer commits to; the skill `choose-pattern` is an on-demand, argument-driven table that lines up all open decisions of one situation. |
| `request-path` | Starts every design or change with the request path across layers, marking owner, transaction and remote hops | Architectural Baseline; Code Generation Rules; Distribution Rules | Diagram first; the other modes never draw the path. |

## Confusable pairs

Model-invocable skills whose triggers could meet. The discriminating clause is written into both descriptions.

| Pair | Request that could fit both | Discriminator |
| --- | --- | --- |
| `layering` / `service-layer` | "This controller does too much" | Layer assignment and dependency direction versus designing the application operation that the controller should call. |
| `layering` / `presentation-layer` | "Business rule in a handler", "there is SQL in this controller" | `presentation-layer` fires on what sits inside handler, view, template or presentation-model code (rules, SQL, transactions, display formatting); `layering` fires on imports and return types that cross layers (domain code importing a web framework, a repository returning response shapes) and on layers that only forward calls. Neither description uses the other's example. |
| `business-logic-patterns` / `service-layer` | "Where does this rule go" | Decisions about the business versus sequencing, transactions and calls to collaborators. |
| `repository` / `data-mapper` / `gateways-and-active-record` | "How should I persist this" | Interface the domain sees; mapping code and domain purity; accepting persistence coupling. |
| `transactions-and-unit-of-work` / `offline-locking` | "Two users edit the same record" | One request's transaction and commit versus a conflict across requests or user sessions. |
| `transactions-and-unit-of-work` / `loading-behavior` | "The ORM saves or loads unexpectedly" | Write timing and commit scope versus read identity and lazy loading. |
| `relational-mapping-structure` / `inheritance-mapping` / `query-and-metadata-mapping` | "Design the tables for this model" | Associations and values; class hierarchies; query objects and mapping configuration. |
| `presentation-layer` / `web-presentation-patterns` | "Add a new page or endpoint" | Allowed content of the handler versus choice of controller and view pattern. |
| `integration-boundaries` / `remote-boundaries` | "We call another service" | Foreign format and vendor types versus call count, coarseness and DTOs of the application's own remote API. |
| `business-logic-patterns` / `presentation-layer` | "There is a business rule in this handler" | `presentation-layer` fires on handler, view and template content and what must be handed off; `business-logic-patterns` fires on choosing the pattern and on duplicated or misplaced rules wherever they live. |
| `session-state` / `presentation-layer` | "Remember the user's selection" | Storage location, lifetime and trust versus keeping UI state out of domain logic. |
| `base-patterns` / `integration-boundaries` | "Wrap this client" | `Gateway` belongs to `integration-boundaries`; `base-patterns` never covers wrapping external resources. |

Reviewer pairs follow the same discriminator: `layering-reviewer` / `presentation-reviewer` (the layer map, import edges and forwarding layers, versus what a handler, view or template contains; a handler that owns SQL, transaction and rules is recorded as a collision in the layer map and itemized by `presentation-reviewer`).

Manual workflow pairs: `review` / `audit` / `blocker-scan` (a change, every family over a tree, only blockers over a tree); `plan` / `build-feature` (plan only, plan and do); `choose-pattern` / `plan` (which pattern, in what steps); `escalate-pattern` / `fix` (decide and begin a pattern change, resolve given findings); `remote-contract` / `remote-boundaries` (produce a contract, apply rules while editing).

Components that walk the same checklist or the same map, and how they differ:

- `review` / `checklist` / `final-gate`: `review` judges a diff or paths against every family's rules and ranks findings by severity; `checklist` is an interactive yes, no or n/a walk of the ten source questions with a next step for each no; `final-gate` is the isolated, binary pre-commit gate that returns `GATE: PASS` or `GATE: FAIL` and never negotiates.
- `choose-pattern` / `force-first`: `force-first` prints the forces inline, as a short header on every design or code answer of a session, for the one decision that answer commits to; `choose-pattern` is an on-demand, argument-driven table covering all open decisions of one situation side by side.
- `responsibility-map` / `request-path`: `responsibility-map` is a forked, on-demand table of who owns each of the seven responsibilities per unit, with collisions, before a design; `request-path` is a session-long mode that draws the hop-by-hop path of one request, marking transaction and remote hops, before and after each change.
- `lead` / the routing table in `principles`: the table is the static map from a situation to the components that handle it; `lead` reads the actual task or diff, picks at most five steps from that map, orders them and names what not to add, and never reviews.

## Coverage of the upstream sections

Every `##` section is cited by at least one component. The generated `docs/TRACEABILITY.md` is the authoritative table; the intent is:

| Upstream section | Main owners |
| --- | --- |
| Purpose, Primary Directive | `principles`, `layering`, `responsibility-map`, `explain-rule` |
| Architectural Baseline, Layering | `layering`, `layering-reviewer`, `audit` |
| Choosing the Business Logic Pattern and its patterns | `business-logic-patterns`, `choose-pattern`, `escalate-pattern`, `logic-placement-reviewer`, `logic-mover` |
| Application Workflow Rules and Service Layer | `service-layer`, `service-layer-reviewer` |
| Remote Facade, Data Transfer Object, Distribution Rules | `remote-boundaries`, `remote-contract`, `remote-api-reviewer`, `facade-builder` |
| Persistence Pattern Rules and its patterns | `repository`, `data-mapper`, `gateways-and-active-record`, `persistence-reviewer`, `persistence-extractor` |
| Identity, Caching, and Unit-of-Work Rules | `loading-behavior`, `transactions-and-unit-of-work`, `loading-reviewer`, `transaction-reviewer` |
| Object-Relational Mapping Pattern Index | `relational-mapping-structure`, `inheritance-mapping`, `query-and-metadata-mapping`, `mapping-reviewer` |
| Concurrency and Transaction Rules and its patterns | `offline-locking`, `transactions-and-unit-of-work`, `lock-reviewer`, `lock-adder` |
| Presentation Layer Rules and Presentation Pattern Index | `presentation-layer`, `web-presentation-patterns`, `presentation-reviewer` |
| Offline and Integration Rules | `integration-boundaries`, `integration-reviewer` |
| Session State and Base Pattern Index | `session-state`, `base-patterns`, `session-state-reviewer`, `base-pattern-reviewer` |
| Code Generation Rules | `build-feature`, `plan`, `choose-pattern`, `service-layer` |
| Review Rules, Review Checklist | `review`, `audit`, `checklist`, `final-gate` |
| Forbidden Patterns and its six subsections | `blocker-scan`, `layering`, `repository`, `data-mapper`, `transactions-and-unit-of-work`, `remote-boundaries` |
| Testing Rules | `testing-by-responsibility`, `test-alignment-reviewer`, `test-writer` |
| Final Instruction | `principles`, `lead`, `checklist`, `choose-pattern` |
