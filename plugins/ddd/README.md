# Domain-Driven Design

Eric Evans' approach to software for complicated business domains, turned into a Claude Code toolkit. It makes Claude start from what the business calls things and which rules those things obey, keep that language and those rules in the code, draw explicit boundaries where models meet, spend modeling effort where it pays, and hold back from ceremony where it does not.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), eight usage walkthroughs with exact commands, a map from the rule set's sections to the components, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *Domain-Driven Design* argues that in software for complex business areas the hard part is understanding the domain, not choosing technology. The code should be a model of that domain, built together with the people who know it, expressed in one shared language, and kept honest by refactoring toward deeper insight. The book works at two levels. At the building-block level it asks for entities, value objects, aggregates, services, repositories and factories that carry business meaning and protect their rules, inside a domain layer that infrastructure and user interfaces serve rather than shape. At the strategic level it asks for explicit bounded contexts, deliberate relationships between them, a clearly distilled core domain that gets the best design effort, and, only when a model is too large to grasp, a light guiding structure.

**Who this is for.** Developers using Claude Code on business software where rules, lifecycle and vocabulary matter more than plumbing: claims, billing, scheduling, rentals, eligibility, pricing, fulfilment. It pays off in three situations: when you add behavior to a codebase whose names come from tables and endpoints, when a change touches another team's or a legacy system's model, and when a team argues about how much of this to apply.

**The bias it corrects.** An agent given a feature in such a codebase starts from what already has a shape. It writes a service method that loads rows, branches on a status string and saves. Names come from the schema, "customer" quietly means three things, the same rule lives in two handlers, and "DDD", if it arrives, shows up as renamed folders and a repository for every table. The opposite failure is common too: after reading about the approach, the agent wraps a CRUD screen in aggregates, factories and domain services. This toolkit breaks both habits with one question asked before code is written: what does the business call this, what rule does it express, and does this part of the system deserve a rich model? When uncertain, the rule set's tie-breaker is the option that makes the domain model clearer.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/ddd:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- One skill per rule cluster, written as decisions: when it applies, how to check it, what to do instead, and where the rule set itself lets the rule bend. Strategic skills (bounded contexts, context relationships, distillation) and tactical skills (entities, value objects, aggregates, repositories, factories, domain services) are kept apart so each stays focused.
- A brake as a first-class component: `/ddd:right-sizing` and `ddd:ceremony-reviewer` decide how much of the rule set a change earns and recognize fake DDD.
- Book-specific workflows next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`: `smell-hunt` (forbidden patterns to treatments), `map-contexts` (the context map as found), `language-audit` (terms across a tree), `scenario-walkthrough` (test the model with a story), `choose-structure` (large-scale structure, with restraint) and `pattern-fit` (vet analysis patterns and design patterns).
- Fifteen read-only specialist reviewers, each with its own report shape (a term ledger, a context map as found, an invariant-to-boundary table, a creation-and-access trail), five implementers that make small test-backed changes, a `lead` that routes work in at most five steps, and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `context-first` (declare context, terms and invariants before code) and `model-explorer` (discovery conversation before code).

**Scope against the sibling plugins.** This plugin carries Evans' original scope: model discovery, the ubiquitous language, strategic design and the building blocks. `ddd-distilled` is the lighter, subdomain-first, low-ceremony version. `ddd-implementing` goes deeper into implementation mechanics that this rule set does not contain, such as domain events and integration styles. See "Works with other plugins" for how to combine them.

**When not to use it.** Plain CRUD, a one-off script or a settings screen does not need this; `/ddd:right-sizing` will tell you so. Reach for a different book when the real risk lies elsewhere: dependency direction between layers in general (`clean-architecture`), choosing enterprise patterns by force (`enterprise-patterns`), reshaping code that has no tests (`legacy-code`, then come back), or distributed data semantics (`data-intensive-apps`).

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install ddd@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/ddd
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall ddd@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**60 components:** 32 skills (20 Claude can load on its own, 12 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/ddd:aggregates` | Use when deciding what must be consistent together, when a transaction changes several domain objects, when callers mutate a collection inside an object, or when an object holds a live reference to another root. For… |
| `/ddd:bounded-contexts` | Use when deciding where a model starts and stops, when one word means different things in different modules, or when domain types are shared by several contexts. Who owns a model; how two contexts relate… |
| `/ddd:context-relationships` | Use when integrating with another team's model, a legacy system or a vendor API, choosing among Shared Kernel, Customer/Supplier, Conformist or Anticorruption Layer, or phasing out a legacy system. The edge between… |
| `/ddd:deep-models` | Use when a model feels shallow, table-shaped or contradictory, when requirements keep adding special cases, or when one concept could simplify many rules. Whole-model judgment and breakthrough refactoring; for a single… |
| `/ddd:distillation` | Use when deciding where modeling effort belongs, when generic mechanisms outweigh and hide the distinctive logic, or when picking refactoring targets by strategic value. Finding the core; types shared across contexts… |
| `/ddd:domain-services` | Use when a domain operation fits no single entity or value object, when a *Service class collects unrelated rules, or when behavior is moved out of entities only to keep them thin. Services that hold domain decisions… |
| `/ddd:domain-tests` | Use when writing, reviewing or ordering tests for domain behavior: invariants, allowed and forbidden transitions, invalid construction, specifications, application orchestration, and translations at context boundaries.… |
| `/ddd:entities` | Use when an object has identity and a lifecycle, when setters or public fields let callers edit state, or when it lacks methods for its valid transitions. The entity class itself; for rules in controllers or jobs use… |
| `/ddd:explicit-concepts` | Use when a flag, status string, repeated condition over several values, rule in a comment or script-like process hides a business concept, or a named rule (specification, policy) is needed. Whole model… |
| `/ddd:factories` | Use when creating a domain object takes several collaborating values or business rules, when endpoints or mappers assemble objects field by field, or when invalid or partly built objects can exist. Creation of new… |
| `/ddd:infrastructure` | Use when ORM annotations, table shapes, serializers or framework types appear in domain classes, or domain classes take names from tables or columns. Own technical shapes; word choice: ddd:ubiquitous-language… |
| `/ddd:layers` | Use when controllers, handlers, jobs or application services decide business outcomes, or when choosing a rich domain layer or Smart UI. Which layer decides; ORM shapes in the model: ddd:infrastructure; an entity's… |
| `/ddd:model-driven-design` | Use when design documents, diagrams, tickets and code describe different models, when a model exists only on a whiteboard, or when tests and docs should explain the domain. Alignment of model, code and artifacts; for… |
| `/ddd:modules-and-associations` | Use when organizing packages or directories, adding a field that references another domain object, or finding models, services, utils or helpers folders dominating the layout. Folder layout only; shared types… |
| `/ddd:principles` | Applies the Domain-Driven Design rule set (Evans) to design and code decisions. Use for any task that models a business domain, reviews domain code, names things in the language of the business, or integrates with… |
| `/ddd:repositories` | Use when adding or reviewing a repository: one per table, generic CRUD or query-builder interfaces, persistence records returned instead of domain objects, rules in repository code. The access contract; for new objects… |
| `/ddd:right-sizing` | Use when a change adds repositories, factories, aggregates or services to simple CRUD, when DDD vocabulary is applied without a model change, or when deciding how much modeling an area deserves. Brake on ceremony; for… |
| `/ddd:supple-design` | Use when a domain API hides intent behind technical names, a method both answers and changes state, invariants live only in comments or UI checks, or named rules are combined. Vocabulary: ddd:ubiquitous-language.… |
| `/ddd:ubiquitous-language` | Use when naming or renaming domain types, methods, tests or modules, or when synonyms or one word with two meanings inside one context appear. One term per concept; names copied from tables or columns… |
| `/ddd:value-objects` | Use when raw strings, numbers or dates stand for money, ranges, codes or measurements, when one value's validation repeats across handlers, or when a descriptive concept is mutable. Attribute-only concepts; for… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/ddd:audit` | Scan a directory or repository for Domain-Driven Design health in a forked context and return ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/ddd:checklist` | Walk the Domain-Driven Design review checklist against the current work, answer yes, no or not applicable with evidence, and give a next step for each no. | `[paths \| git ref \| empty for the current diff]` |
| `/ddd:choose-structure` | Decide whether a large model needs a guiding large-scale structure and which, with governance and a review trigger, using the rule set's restraint: minimal, evolving, domain-specific. | `[area or system to structure \| proposed structure to evaluate \| empty to assess the repository root]` |
| `/ddd:explain-rule` | Explain one Domain-Driven Design rule, pattern or section: its strength, the reason, how to check it, an original example and when it bends. | `[rule, pattern or section name, for example aggregates or anticorruption layer]` |
| `/ddd:fix` | Resolve named Domain-Driven Design findings with the smallest change each, in the rule set's refactoring order, running the tests and never committing. | `[findings text \| review output \| finding numbers \| empty to use findings from this session]` |
| `/ddd:language-audit` | Build a concept-to-term table for each context of a tree in a forked context and find synonyms, overloaded terms, technical stand-ins and doc drift, in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/ddd:map-contexts` | Reconstruct the context map of a repository as found, in a forked context: contexts, relationships, translation points and leaks, in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/ddd:pattern-fit` | Decide whether an analysis pattern, design pattern or industry formalism fits the model without displacing domain names, and report adopt, adapt or reject with a term mapping. | `[pattern or formalism name \| the concept you want to model \| empty to review patterns in the current diff]` |
| `/ddd:plan` | Plan a feature or model change in the rule set's code-generation order: domain concept first, then model, boundaries, translation, tests and steps. | `[feature or change description \| issue text \| empty to plan from the current diff]` |
| `/ddd:review` | Review a diff or paths against the Domain-Driven Design rules and report ranked findings with proposed refactorings. | `[paths \| git ref \| empty for the current diff]` |
| `/ddd:scenario-walkthrough` | Walk a real business scenario through the model and code and report where it turns procedural, awkward or leaky, with the model pressure it reveals. | `[scenario in one or two sentences \| ticket text \| empty to derive one from the current diff]` |
| `/ddd:smell-hunt` | Walk the forbidden-pattern families over a scope and map every hit to a treatment skill and an order of treatment. | `[family \| all] [path]   families: passive-model, smart-ui, persistence-driven, primitive-obsession, shared-model, god-service, invalid-construction, fake-ddd, context-blindness, pattern-obscurity` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-ddd:aggregate-reshaper` | sonnet | can edit files | Implementer that redraws one aggregate boundary: root-only mutation, encapsulated members, references to other aggregates by identity and a smaller transaction scope. Use when review findings report… |
| `@agent-ddd:aggregate-reviewer` | sonnet | read-only | Reviewer of aggregate boundaries and transaction scope. Use proactively after edits that change a root and its members, expose internal collections, hold references between roots, or save several… |
| `@agent-ddd:behavior-mover` | sonnet | can edit files | Implementer that moves business rules out of controllers, jobs, application services and repositories into the entity, value object or domain service that owns them. Use when review findings report… |
| `@agent-ddd:ceremony-reviewer` | sonnet | read-only | Reviewer of DDD ceremony. Use proactively after edits that add repositories, factories, aggregates, domain services, layers, pattern-named types or imported patterns to simple code, to separate real… |
| `@agent-ddd:concept-reviewer` | sonnet | read-only | Reviewer of hidden domain concepts. Use proactively after edits that add flags, status or type strings, repeated conditions, magic thresholds, rules in comments or script-like processes, to find the… |
| `@agent-ddd:context-boundary-reviewer` | sonnet | read-only | Reviewer of bounded contexts and integrations. Use proactively after edits that call another service, consume a vendor or legacy API, or share or reuse domain types across areas, to check ownership… |
| `@agent-ddd:domain-test-reviewer` | sonnet | read-only | Reviewer of tests of the domain model. Use proactively after edits to invariants, transitions, creation rules, specifications, application orchestration or context translation, or after tests are… |
| `@agent-ddd:domain-test-writer` | sonnet | can edit files | Implementer that writes tests of the domain model in the ubiquitous language: invariants, allowed and forbidden transitions, invalid construction and translations. Use when review findings report… |
| `@agent-ddd:entity-reviewer` | sonnet | read-only | Reviewer of entity classes: identity, setters, public fields, missing transition methods. Use proactively after edits that add or change classes with identity or lifecycle. Rules sitting in… |
| `@agent-ddd:final-gate` | sonnet | read-only | Pre-merge gate that runs the Domain-Driven Design review checklist against the working diff and returns PASS or FAIL with evidence per item. Use before declaring work done, committing, or opening a… |
| `@agent-ddd:infrastructure-reviewer` | sonnet | read-only | Reviewer of technical shapes inside the domain model. Use proactively after edits that add ORM annotations, table-shaped classes, serializer or framework types, DTO reuse, or persistence-only… |
| `@agent-ddd:language-reviewer` | sonnet | read-only | Reviewer of the ubiquitous language in code, tests and documents. Use proactively after edits that add or rename domain types, methods, tests or modules, or when synonyms or overloaded words appear.… |
| `@agent-ddd:layer-reviewer` | sonnet | read-only | Reviewer of where business decisions live. Use proactively after edits to controllers, handlers, jobs, scripts or application services, or when a Smart UI is proposed, to find rules outside the… |
| `@agent-ddd:lead` | opus | read-only | Triage lead for Domain-Driven Design work. Use first on any non-trivial change or review to decide which reviewers, implementers and skills apply, in what order, in at most five steps, and how much… |
| `@agent-ddd:lifecycle-reviewer` | sonnet | read-only | Reviewer of how domain objects are created and retrieved. Use proactively after edits that add constructors, builders, factories, repositories or data-access interfaces, or let controllers assemble… |
| `@agent-ddd:module-reviewer` | sonnet | read-only | Reviewer of package structure and associations. Use proactively after edits that add packages or directories in a domain area, move files, add references between domain objects, or introduce models… |
| `@agent-ddd:service-reviewer` | sonnet | read-only | Reviewer of behavior placement among entities, value objects and domain services. Use proactively after edits that add or grow a *Service, Manager or Handler class holding domain rules, or that move… |
| `@agent-ddd:strategy-reviewer` | sonnet | read-only | Reviewer of strategic design choices. Use proactively when a plan or diff affects where modeling effort goes, lets generic mechanisms bury or outweigh the core domain, or changes a context map or… |
| `@agent-ddd:supple-design-reviewer` | sonnet | read-only | Reviewer of the model's interface: intention-revealing operations, command and query separation, explicit assertions, conceptual contours and readable rule combination. Use proactively after edits… |
| `@agent-ddd:translation-builder` | sonnet | can edit files | Implementer that builds a translation layer at one boundary: a mapper or anticorruption layer from a foreign or legacy model to the local model, with boundary tests. Use when review findings report… |
| `@agent-ddd:value-object-introducer` | sonnet | can edit files | Implementer that replaces primitive groups and repeated validation with value objects in small, test-backed steps. Use when review findings or a plan call for introducing value types for amounts… |
| `@agent-ddd:value-object-reviewer` | sonnet | read-only | Reviewer of value objects and primitive obsession. Use proactively after edits that add raw strings, numbers or dates for amounts, ranges, codes or identifiers, repeat a validation, or add mutable… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style ddd:context-first` | Opens every implementation answer with a domain frame: bounded context, domain terms, the kind of model element, and the invariants at stake, before any code. |
| `/output-style ddd:mentor` | Teaches the Domain-Driven Design rule behind each decision, names its strength, and ends non-trivial answers with one question that checks understanding. |
| `/output-style ddd:model-explorer` | Runs a discovery conversation about the model: asks domain questions, offers two or three candidate model shapes, walks a scenario through each, and writes no code until a shape is chosen. |
| `/output-style ddd:pair` | Works in small narrated steps as a pair partner for domain-model changes, and asks before any change larger than a few lines or one that touches public API. |
| `/output-style ddd:strict-reviewer` | Reviews only: every answer is a ranked findings table against the Domain-Driven Design rules, with no rewrites unless asked and an explicit statement when nothing is found. |
| `/output-style ddd:terse` | Result first and brief: no preamble, a few lines unless more is asked, domain terms named, failing output still shown in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with the router: `ddd:lead` reads a task or diff, names the bounded context and the tier of the area, and returns at most five steps. The reviewers are read-only and each owns one concern with its own report shape, so findings do not repeat across them. When a reviewer's finding needs a change, its report names the hand-off: the layer reviewer points to the service reviewer for the destination of a rule, the service and entity reviewers point to `ddd:behavior-mover`, the value-object reviewer to `ddd:value-object-introducer`, the aggregate reviewer to `ddd:aggregate-reshaper`, the context-boundary reviewer to `ddd:translation-builder`, and the domain-test reviewer to `ddd:domain-test-writer`. Implementers make one behavior-preserving change at a time, run your tests, and never commit. `ddd:final-gate` closes the loop with PASS or FAIL against the review checklist. The manual skills are the same work done inside your session: `/ddd:review` and `/ddd:checklist` to judge, `/ddd:plan` and `/ddd:fix` to act, `/ddd:audit` and `/ddd:map-contexts` for whole-tree scans that run in an isolated context and return at most 40 lines.

## Usage walkthroughs

Each walkthrough follows the hand-offs the components describe. Reviewers report and hand off; they never edit.

### 1. Review a pull request that adds a refund endpoint

**Situation.** The branch adds `POST /orders/:id/refund`. The controller decides whether an order is still refundable, amounts travel as `(number, string)` pairs, and the tests call the endpoint.

```text
@agent-ddd:lead route the working diff
```

The router names the context and tier and returns at most five steps, for example:

```text
Context: orders   Area: core   Tier: 2   Change: feature
Touched clusters: layers, values, tests
Run, in order (at most 5):
1. ddd:layer-reviewer - the refund window is decided in RefundController
2. ddd:value-object-reviewer - amount and currency travel as raw pairs
3. ddd:domain-test-reviewer - rules are covered only through the endpoint
4. ddd:final-gate - before the pull request
Skip: contexts - no integration touched
Risk: medium - a business rule lives in the delivery layer
```

```text
@agent-ddd:layer-reviewer review the working diff
```

You get a rule-placement ledger (decision, where it lives, where it belongs) and a finding that carries the hand-off "ddd:service-reviewer for the destination". Run `@agent-ddd:service-reviewer` and its behavior-placement ledger says one object can decide the rule from its own data, so it belongs on the order, and hands off to `ddd:behavior-mover`. Run that only if you want the change made. `@agent-ddd:value-object-reviewer` returns a primitive inventory proposing a money type and hands off to `ddd:value-object-introducer`; `@agent-ddd:domain-test-reviewer` returns a rule-to-test map showing the missing rejecting test and hands off to `ddd:domain-test-writer`. When the work is done, run `@agent-ddd:final-gate`; it prints `GATE: FAIL` with the blocking items until each checklist question is a yes or a reasoned n/a. Prefer one pass inside your session? `/ddd:review` covers the same seven review families and delegates to these reviewers when the diff is large.

### 2. Plan a risky change before editing

**Situation.** Product wants guests to cancel free of charge up to 48 hours before check-in, and pay the first night after that.

```text
/ddd:plan guests can cancel up to 48 hours before check-in; later cancellations pay the first night
```

The plan follows the rule set's code-generation order and edits nothing: the bounded context and the terms with the kind of element each is (a reservation as the root, a stay period as a value, a cancellation policy as a named rule), the invariants and where they will be enforced, the aggregate boundary and transaction scope, any other model involved (payments) with the relationship and the translation point, the domain-language test names to write first, small steps, and open questions for domain experts, such as whether the 48 hours count from the check-in time or the date. Then:

```text
@agent-ddd:domain-test-writer write the tests listed in the plan
/output-style ddd:context-first
```

The test writer adds tests only and reports any production gaps instead of repairing them. In `context-first`, every implementation answer opens with a domain frame (context, terms, invariants, other models) so the premise can be corrected before code appears. When the change is ready, `/ddd:checklist` walks the 19 questions with a next step for each no.

### 3. Learning mode: discover the model before coding

**Situation.** A `Claim` has a `status` of `OPEN`, `DOCS_MISSING`, `ESCALATED` or `CLOSED`, and every month someone wants a fifth value.

```text
/output-style ddd:model-explorer
```

Describe the problem. The mode restates it in domain words, asks at most three domain questions, offers two or three candidate model shapes (for example: lifecycle plus outstanding requirements plus approval authority as separate concepts), says which special cases each removes and what each costs to migrate to, and ends with open questions and a next step. It writes no code until you choose. Then test the candidates against a real decision:

```text
/ddd:scenario-walkthrough an adjuster approves a claim above their limit while a document is missing
```

You get a beat-by-beat trace through the code, marking where the scenario turns procedural, hits a missing concept or leaks, then ranked model pressure with the skill that carries each change out (`/ddd:deep-models`, `/ddd:explicit-concepts`). The migration itself is a normal `/ddd:plan`: behavior-preserving steps, tests green after each.

### 4. Audit a repository before a rewrite

**Situation.** A team inherits a billing service and wants to know where domain modeling will pay off before it plans anything.

```text
/ddd:audit src/
```

The scan runs in a forked context and returns at most 40 lines: a rating (healthy, watch, hot) per cluster with `file:line` evidence, up to five ranked hot spots with the skill or agent for each, what was not examined, and a next step such as `/ddd:map-contexts src/`.

```text
/ddd:map-contexts src/
/ddd:language-audit src/orders
```

The first reconstructs the context map as found: contexts, integrations labeled by what the code actually does (or `unlabeled`), translation points and leaks. Its next step points to `/ddd:context-relationships` for any unlabeled integration. The second builds a concept-to-term table per context, with synonyms, overloaded terms, cross-context homonyms and documentation drift. If the audit rated strategy as watch because no one has named the core domain:

```text
@agent-ddd:strategy-reviewer review src/
```

It reports "core not identified" instead of guessing, plus an effort map. `/ddd:distillation` (loaded on demand) then guides writing a short statement of the core and separating the mechanisms that bury it.

### 5. Integrate a legacy system without importing its vocabulary

**Situation.** New code must read policies from a legacy ERP that encodes status as `A`, `L` and `X`.

Ask Claude which relationship to use; `/ddd:context-relationships` loads from its description and walks the options. A typical decision is recorded as one sentence: "We are the downstream side of the ERP; we choose an anticorruption layer because the ERP's codes would otherwise reach pricing." After a first draft:

```text
@agent-ddd:context-boundary-reviewer review the working diff
```

You get the context map as found for the diff, each integration classified by what the code does, and a finding such as a legacy status code inside `pricing.py`, with the hand-off to `ddd:translation-builder`:

```text
@agent-ddd:translation-builder translate the ERP policy status used in src/orders/pricing.py
```

It writes boundary tests first (every known value, each direction, an unknown value), builds the translator in a module named for the relationship, routes callers through it and stops when no foreign term remains outside it. The unknown-value policy and any provisional names come back under "Needs a decision". `@agent-ddd:domain-test-reviewer` then confirms the translation has tests.

### 6. Find forbidden patterns and fix them

**Situation.** You suspect primitive obsession in `src/billing`.

```text
/ddd:smell-hunt primitive-obsession src/billing
```

The result is a ledger of confirmed hits (pattern, location, evidence, treatment, order), with rejected candidates listed under "Residual". Then:

```text
/ddd:fix 1,2
```

`/ddd:fix` records a test baseline, orders the findings by the rule set's refactoring sequence, applies the smallest change per finding, runs the covering tests, and does not commit. For a step larger than a few files it hands off to the matching implementer, here `ddd:value-object-introducer`, and reviews what comes back. Findings that need a decision (a public API, a context boundary) are reported instead of fixed. Close with `/ddd:checklist` or `@agent-ddd:final-gate`.

### 7. Stop over-modeling

**Situation.** A pull request adds `TagRepository`, `TagFactory`, `TagDomainService` and `CreateTagCommandHandler` for a table of tag names.

```text
@agent-ddd:ceremony-reviewer review the working diff
```

You get a need ledger: each added element, the rule it serves, the removal test (would anything be lost if it were inlined?) and a verdict of keep, simplify or remove. Here nothing would be lost, so the finding is to remove the stack and keep a plain function with its uniqueness handling, via `/ddd:right-sizing`. The reviewer does not number its findings, so pass the finding text to the fixer:

```text
/ddd:fix remove the TagRepository, TagFactory, TagDomainService and CreateTagCommandHandler stack from the ceremony review, keeping a plain create_tag function
```

`/ddd:fix` treats removing ceremony as its own first step: it inlines each element into its caller, deletes it and runs the covering tests. The same reviewer will keep a factory that carries real creation rules, so the answer depends on the rule the model must protect, not on a taste for or against patterns.

### 8. Redraw an aggregate boundary

**Situation.** `OrderService` pushes lines into `order.lines`, re-checks the credit limit in two places and saves the order and the customer in one transaction.

```text
@agent-ddd:aggregate-reviewer review src/orders
```

The invariant-to-boundary table shows each invariant, its participants, the root, where it is enforced and the transaction span. The findings hand off to `ddd:aggregate-reshaper`:

```text
@agent-ddd:aggregate-reshaper redraw the Order aggregate from the invariants in the review
```

It confirms the invariants, makes the root enforce them and routes callers through it, makes the members private, and replaces the live customer reference with an identifier. It does not narrow the transaction on its own: how the customer rule stays consistent when it spans two aggregates is a decision for the team, so it appears under "Needs a decision". `ddd-implementing` covers implementation mechanisms for that choice.

## How it maps to the book

Section names are the headings of the vendored rule set (`skills/principles/references/full.md`). The generated `docs/TRACEABILITY.md` lists the exact citation in each component.

| Upstream section | Components |
| --- | --- |
| Purpose | principles, explain-rule, mentor |
| Primary Directive | principles, right-sizing |
| What DDD Means in This Repository | principles, right-sizing, ceremony-reviewer |
| Knowledge Crunching and Deep Models | deep-models, scenario-walkthrough, concept-reviewer, model-explorer |
| Model-Driven Design | model-driven-design, language-reviewer, model-explorer |
| Breakthrough and Deeper Insight | deep-models, model-explorer |
| Making Implicit Concepts Explicit | explicit-concepts, concept-reviewer, model-explorer |
| Ubiquitous Language | ubiquitous-language, language-audit, language-reviewer, context-first |
| Communication Artifacts | model-driven-design, language-audit, domain-tests, domain-test-writer |
| Scenario Walkthroughs | scenario-walkthrough, model-explorer, infrastructure |
| Layered Architecture and Smart UI | layers, right-sizing, layer-reviewer, infrastructure |
| Bounded Contexts | bounded-contexts, map-contexts, language-audit, context-boundary-reviewer |
| Strategic Design | context-relationships, distillation, map-contexts, context-boundary-reviewer, strategy-reviewer, deep-models, lead |
| Model Integrity Patterns | bounded-contexts, context-relationships, map-contexts, context-boundary-reviewer, translation-builder |
| Distillation | distillation, audit, review, strategy-reviewer, deep-models |
| Large-Scale Structure | choose-structure, strategy-reviewer |
| Strategic Decision Making | choose-structure, plan, strategy-reviewer, distillation |
| Entities | entities, entity-reviewer, behavior-mover |
| Value Objects | value-objects, value-object-reviewer, value-object-introducer |
| Associations and Modules | modules-and-associations, module-reviewer, aggregates, aggregate-reviewer |
| Aggregates | aggregates, aggregate-reviewer, aggregate-reshaper |
| Domain Services | domain-services, service-reviewer, behavior-mover |
| Explicit Concepts and Specifications | explicit-concepts, concept-reviewer, repositories |
| Repositories | repositories, lifecycle-reviewer |
| Factories | factories, lifecycle-reviewer |
| Application Layer | layers, layer-reviewer, domain-services |
| Infrastructure | infrastructure, infrastructure-reviewer |
| Translation at Boundaries | infrastructure, context-relationships, map-contexts, infrastructure-reviewer, translation-builder, context-boundary-reviewer |
| Supple Design | supple-design, supple-design-reviewer, explicit-concepts |
| Analysis and Model Patterns | pattern-fit, explicit-concepts, ceremony-reviewer |
| Code Generation Rules | plan, lead, context-first, infrastructure, bounded-contexts, distillation, modules-and-associations, principles, value-objects, value-object-reviewer |
| Review Rules | review, audit, smell-hunt, strict-reviewer |
| Testing Rules | domain-tests, domain-test-reviewer, domain-test-writer, infrastructure, audit |
| Forbidden Patterns | smell-hunt, right-sizing, factories, aggregates, ceremony-reviewer, fix |
| Refactoring Rules | fix, pair, value-object-introducer, behavior-mover, aggregate-reshaper, translation-builder, smell-hunt |
| Output Expectations | review, plan, fix, final-gate, terse, mentor, principles |
| Review Checklist | principles, checklist, final-gate, review, audit, strict-reviewer |
| Final Instruction | principles, explain-rule, lead |

## Works with other plugins

The compatibility notes published with the upstream rule sets compare each pair of books. The verdicts that matter for this plugin:

| Plugin | Verdict | What it means here |
| --- | --- | --- |
| `ddd-distilled` | Overlap | Choose one as the active DDD rule set for a task. `ddd-distilled` is the better default for selective, low-ceremony guidance; this plugin is better when the work is explicitly about the fuller strategic vocabulary: context maps, core-domain distillation, deeper model refactoring. Loading both mostly duplicates the same decisions. |
| `ddd-implementing` | Overlap | Treat `ddd-implementing` as the implementation-focused extension once DDD is chosen: aggregates, repositories, events, application services, package structure and integration. Prefer this plugin when model discovery, language, context mapping and deeper insight are the work. Use both only when you want this plugin as the strategic source and the other as the implementation playbook. |
| `enterprise-patterns` | Conflicting | Do not load as equal guidance: one pushes a richer domain model where language, invariants and contexts drive the design, the other explicitly allows simpler transaction-script, table-module or active-record designs. Use this plugin as primary and `enterprise-patterns` constrained to a specific persistence, transaction or remoting decision. |
| `clean-architecture` | Complementary | Dependency direction and policy independence there; model language, contexts and invariants here. Load both only for business software where both forces are visible; both can add architecture vocabulary, so scope them carefully. |
| `legacy-code` and `refactoring` | Complementary | One controls safe change sequencing, this one defines the target design. For weakly tested code, characterize behavior and create seams first, then apply this plugin inside the controlled area. For tested code, `refactoring` keeps each step behavior-preserving while this plugin chooses the destination. |

Also marked complementary by the same notes: `clean-code`, `code-complete`, `philosophy-of-design`, `pragmatic-programmer`, `refactoring-guru`, `release-it` and `data-intensive-apps`, each only where its own trigger (local readability, defect-risk construction, interface depth, engineering habits, production failure behavior, data semantics) is present as well.

**Recommended pairing.** Make this plugin the primary, always-on rule set for domain-heavy work (`inject_rules` on) and add `refactoring` or `legacy-code` on demand when you change existing code. Do not stack `ddd-distilled`, `ddd-implementing` or `enterprise-patterns` as equal active rule sets in one session.

## Limitations

- **No measured improvement.** The upstream project has no benchmarks, before-and-after comparisons or defect data showing that rule sets like this improve outcomes. These components make an agent apply the book's judgment more consistently; they do not prove the result is better.
- **Context cost.** Twenty skill descriptions are always visible to Claude, and loading a rule file spends tokens. Use the compact rules first, keep `inject_rules` off unless this is your primary rule set, and do not load several large rule sets at once.
- **The model can still ignore rules.** Rules compete with each other and with the task; reviewers and the gate exist because instructions alone are not reliable.
- **Rules come from a book, not from your incidents.** Nothing here learns from your project's failures. Add project-specific rules to your own `CLAUDE.md` where the team has learned something this book does not say.
- **Risk of overengineering.** Applied everywhere, this approach produces layers, aggregates and factories nobody needs. `/ddd:right-sizing`, `ddd:ceremony-reviewer` and the tier idea (an Added judgment of this plugin, not a rule of the source) are there to counter that, but they cannot enforce good task selection.
- **Pseudo-compliance.** An agent can produce code that looks architecturally proper while missing the real task. Review against scenarios (`/ddd:scenario-walkthrough`) and tests in domain language, not against vocabulary.
- **Rules from different books can conflict.** See the compatibility table; choose one primary rule set.
- **The domain is not in the repository.** The plugin cannot know your business. It asks for terms, contexts and the core domain, marks guesses as provisional and lists questions for domain experts; the answers have to come from people.
- **Detection is heuristic.** The search recipes in `audit`, `smell-hunt` and the reviewers find candidates; they need reading to confirm. Their thresholds are labeled Added judgment. Reviewers never run your tests; only the implementers and `/ddd:fix` do.
- **Scope of the source.** This rule set does not include domain events, event sourcing, CQRS or integration styles; `/ddd:explain-rule` says so rather than inventing guidance. It also leaves the mechanism for consistency across aggregates to the team.
- **Contested advice.** Some tactical conventions here, such as referencing other aggregates by identity and keeping translation mandatory at boundaries, are the rule set's policy and are debated in practice; the plugin states the exceptions the rule set itself allows (Smart UI, Conformist, plain constructors) and defers to your explicit instruction and repository conventions.
- **Examples cover TypeScript and Python.** The rules are language-neutral; the examples are not exhaustive.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Domain-Driven Design rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Domain-Driven Design* is by Eric Evans. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
