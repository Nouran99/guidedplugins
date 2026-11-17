# Patterns of Enterprise Application Architecture

Martin Fowler's catalog of enterprise application patterns, turned into a Claude Code toolkit. It makes Claude say who owns presentation, workflow, domain decisions, data access, the transaction, concurrency control and integration before it writes code, choose the lightest pattern whose forces actually fit, and refuse the forbidden shortcuts: layers that only forward calls, a generic repository for everything, controllers that run the whole workflow, and remote calls dressed up as method calls.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), eight usage walkthroughs with exact commands, a map from the book's sections to the components, and an honest section on what this cannot do.

<!-- START-HERE:START -->
## Start here

9 components cover most uses; everything else is reachable from the `enterprise-patterns:principles` skill's routing table.

| To | Run |
| --- | --- |
| Review your current change | `/enterprise-patterns:review` |
| Plan a non-trivial change before you edit | `/enterprise-patterns:plan` |
| Walk the book's final checklist against your change | `/enterprise-patterns:checklist` |
| Act on review findings, one at a time | `/enterprise-patterns:fix` |
| Hunt the six forbidden patterns (layering theater, generic repository, ORM-driven everything, controller-centric app | `/enterprise-patterns:blocker-scan` |
| Map who owns each of the seven enterprise responsibilities (presentation, workflow, domain, data access, transactions | `/enterprise-patterns:responsibility-map` |
| Turn a feature or code situation into forces | `/enterprise-patterns:choose-pattern` |
| Not sure which specialist applies? Route the task | ask Claude to use `enterprise-patterns:lead` |
| Strict pass or fail before you commit or open a pull request | ask Claude to use `enterprise-patterns:final-gate` |

Using this book next to others? `/plugin install guided-<preset>@guided-plugins` installs a primary book with complementary ones, and `/guided:review` reviews with all of them at once. Project settings (ignored paths, strictness, the primary book): [`.guided-plugins.json`](https://github.com/Nouran99/guidedplugins/blob/main/docs/PROJECT_CONFIG.md).
<!-- START-HERE:END -->

## Overview

**The book in one paragraph.** *Patterns of Enterprise Application Architecture* starts from an observation: business applications that handle data for many users keep facing the same few problems. Where should the business rules live? How do objects map to relational tables? Who commits, and what happens when two people edit the same record? How are pages built and navigated? What changes when a boundary is remote, and where does per-user state live? The book answers each with a family of named patterns and, importantly, with the trade-offs between them, so that the choice follows from the problem instead of from fashion. The upstream rule set condenses that into a working policy for an agent: make responsibilities explicit, pick the smallest set of well-understood patterns that fits, escalate only when the code shows the pressure, and reject accidental coupling and fashionable complexity alike.

**Who this is for.** Developers using Claude Code on server-side business applications in any mainstream language and framework: web back ends, internal systems, order and billing flows, anything with a database, users and a transaction. The plugin pays off when a task crosses layers, such as adding a use case, introducing persistence, deciding who commits, handling concurrent edits, shaping an API, or reviewing a pull request that touches several of those at once.

**The bias it corrects.** An agent asked to build an enterprise feature reaches for whatever the framework makes easy. The controller opens the connection, one ORM class doubles as table row, domain object, request body and response, a generic repository gets one method per table column, and a call to another service reads like a local method call. The opposite habit is just as common: five layers and an interface for every class, each forwarding to the next. This toolkit asks for the middle path. Name the owner of each responsibility, give each the lightest pattern its forces justify, and move up to a stronger pattern only when duplication, lifecycle or invariant complexity actually appears.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/enterprise-patterns:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- One skill per pattern family, written as decisions rather than slogans: business logic, application services, repositories and mappers, gateways and Active Record, transactions and the unit of work, loading behavior, object-relational structure, inheritance mapping, queries and metadata, offline locking, presentation, web presentation patterns, integration, remote boundaries, session state, base patterns and testing by responsibility. Each says when the pattern applies, how to check it, what to do instead, and where the book itself lets the rule bend.
- Workflows that follow what the book teaches: `choose-pattern` (forces in, smallest fitting pattern out), `responsibility-map`, `blocker-scan` for the six forbidden patterns, `escalate-pattern` for a script that has outgrown itself, `remote-contract` and `build-feature` in the book's generation order, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (a layer map, a decision ledger, a write trace, a conflict matrix, a call-count table), five implementers that make small test-backed changes, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `force-first`, which names the forces before any pattern, and `request-path`, which draws the request path across layers before any change.

**When not to use it.** The rule set is a pattern selector, not a domain-modeling method. Reach for a different book when the real risk lies elsewhere: whether a rich domain model, aggregates and bounded contexts are justified (the `ddd` family of plugins), dependency direction as an enforced architecture rule (`clean-architecture`), consistency, replication and schema evolution (`data-intensive-apps`), timeouts and stability patterns (`release-it`), or reshaping code that has no tests (`legacy-code`). For a throwaway script, the rules still apply in spirit, and the ceremony of this toolkit does not.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install enterprise-patterns@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/enterprise-patterns
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall enterprise-patterns@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**59 components:** 32 skills (20 Claude can load on its own, 12 you run by name), 21 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/enterprise-patterns:base-patterns` | Use for small supporting patterns: money held in floats, repeated null checks, a global registry or service locator, a shared base class, plug-in selection, an interface beside its implementation, tabular data passed… |
| `/enterprise-patterns:business-logic-patterns` | Use when deciding where business rules live: choosing Transaction Script, Table Module or Domain Model, noticing a script growing duplicated rules, or an anemic model beside a fat service. Decisions about the business… |
| `/enterprise-patterns:data-mapper` | Use when storage knowledge leaks into domain objects (SQL, column names or ORM base classes in the model), mapping code is repeated in callers, or you must decide if a Data Mapper is worth it. Interface shape is… |
| `/enterprise-patterns:gateways-and-active-record` | Use when choosing a persistence pattern for simple or table-shaped work: Row Data Gateway, Table Data Gateway or Active Record, a report building objects per row, or Active Record spreading into a complex domain.… |
| `/enterprise-patterns:inheritance-mapping` | Use when a class hierarchy has to be persisted: choosing between one table for the hierarchy, a table per class, or a table per concrete class, or when domain code branches on a discriminator column. Not for… |
| `/enterprise-patterns:integration-boundaries` | Use when code consumes a partner, vendor or legacy system: foreign field names, status codes or SDK types spread through the app, messages used as domain objects, or serialization code with rules in it. Call counts and… |
| `/enterprise-patterns:layering` | Use for the split into presentation, application, domain and data-access layers, or imports and return types that cross layers: domain code importing a web framework, a repository returning response shapes… |
| `/enterprise-patterns:loading-behavior` | Use when objects are loaded: the same row appears as two live objects, an association is lazy-loaded inside a loop, serializer or template, or a list endpoint issues one query per row (N+1). Reads and identity; commit… |
| `/enterprise-patterns:offline-locking` | Use when two users or sessions can edit the same data across separate requests: lost updates, a version column, row locks held between requests, locks on related objects, or stale locks. One request's commit scope is… |
| `/enterprise-patterns:presentation-layer` | Use when writing or reviewing what sits inside handlers, controllers, views, templates or presentation models: business rules, SQL or transactions in them, display formatting in domain code, one type as form, entity… |
| `/enterprise-patterns:principles` | Applies the Patterns of Enterprise Application Architecture rule set to enterprise code. Use for any task that places business logic, persistence, transactions, locking, presentation, integration, session state or… |
| `/enterprise-patterns:query-and-metadata-mapping` | Use when SQL strings are built in several places, search filters are combined at runtime, or mapping rules are driven by configuration, annotations or reflection. Covers Query Object and Metadata Mapping. Finder… |
| `/enterprise-patterns:relational-mapping-structure` | Use when designing or reviewing how objects map to tables: keys and identity fields, object references, many-to-many links, owned child rows, small values in the parent row, serialized blob columns. Hierarchies are… |
| `/enterprise-patterns:remote-boundaries` | Use when your own API or client makes several calls per user action, objects are exposed remotely method by method, domain classes appear in responses, or a service split is proposed. Covers Remote Facade, DTOs… |
| `/enterprise-patterns:repository` | Use when defining or reviewing the interface domain or application code uses to read and store objects: a generic CRUD repository, finders shaped by columns, callers building queries. Mapping code is data-mapper… |
| `/enterprise-patterns:service-layer` | Use when writing or reviewing application services or use-case classes: a controller orchestrating several steps, a service that holds every rule or only forwards to persistence, an API shaped by UI mechanics. Not for… |
| `/enterprise-patterns:session-state` | Use when per-user state must survive between requests: cookies or tokens carrying data, server-held sessions, a session table, expiry and cleanup, a cart or wizard lost on restart. Shared-record edit conflicts are… |
| `/enterprise-patterns:testing-by-responsibility` | Use when writing or placing tests for enterprise code: a business rule tested only through HTTP or a database, mappers or repositories mocked away, transaction or locking behavior untested, remote mapping uncovered, or… |
| `/enterprise-patterns:transactions-and-unit-of-work` | Use when deciding who opens and commits a transaction, saves are scattered across callers, an ORM flushes at surprising times, or a remote call sits inside a transaction. One request's commit scope; cross-request edits… |
| `/enterprise-patterns:web-presentation-patterns` | Use when choosing how requests are handled and responses rendered: Page Controller or Front Controller, Template View, Transform View or Two Step View, MVC roles, or a multi-step flow whose navigation is scattered.… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/enterprise-patterns:audit` | Scan a directory or repository for Patterns of Enterprise Application Architecture health in a forked context and return one rating per pattern family and ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/enterprise-patterns:blocker-scan` | Hunt the six forbidden patterns (layering theater, generic repository, ORM-driven everything, controller-centric app, distributed object fantasy, unclear transaction ownership) over a tree in a forked context and… | `[directory \| glob \| empty for the repository root]` |
| `/enterprise-patterns:build-feature` | Implement a new enterprise use case slice by slice in the book's generation order (pattern, service, domain, persistence, transaction, boundary DTOs, presentation) with tests at each responsibility. Runs the tests and… | `[use case description \| plan reference \| empty to ask]` |
| `/enterprise-patterns:checklist` | Walk the Patterns of Enterprise Application Architecture review checklist against the current work, answering yes, no or not applicable with evidence and a next step for each no. Interactive and read-only. | `[paths \| empty for the current diff]` |
| `/enterprise-patterns:choose-pattern` | Turn a feature or code situation into forces, then recommend the smallest fitting enterprise pattern per decision (business logic, data access, transactions, presentation, remote, session), with rejected alternatives… | `[situation or feature \| file \| empty to ask]` |
| `/enterprise-patterns:escalate-pattern` | When a Transaction Script has outgrown itself (duplicated decisions, lifecycle or invariant complexity), confirm the trigger, move the most repeated decision into a model object in small tested steps, and name the… | `[file \| function \| file:line \| empty to ask]` |
| `/enterprise-patterns:explain-rule` | Explain one Patterns of Enterprise Application Architecture rule or pattern: its strength (must, should, must not), the force behind it, how to check it, an original example and the book's own exceptions. | `[rule or pattern name \| section \| situation you are unsure about]` |
| `/enterprise-patterns:fix` | Resolve given Patterns of Enterprise Application Architecture findings with the smallest change per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/enterprise-patterns:plan` | Plan a non-trivial enterprise change in the book's generation order, with an explicit transaction owner, test plan and a list of patterns you will not add. Produces a plan only; no edits. | `[feature or change description \| file:line \| empty to ask]` |
| `/enterprise-patterns:remote-contract` | Design a coarse remote operation for a consumer need: the single call, request and response DTOs, the domain-to-DTO translation, versioning rule, failure behavior and a before-and-after call count. Produces a contract… | `[consumer need or screen \| endpoint file \| empty to ask]` |
| `/enterprise-patterns:responsibility-map` | Map who owns each of the seven enterprise responsibilities (presentation, workflow, domain, data access, transactions, concurrency, integration) for a use case or package in a forked context, and list collisions in at… | `[use case \| file \| directory \| empty for the current diff]` |
| `/enterprise-patterns:review` | Review a diff or paths against the Patterns of Enterprise Application Architecture rules and report ranked findings, with forbidden patterns as blockers. | `[paths \| git ref \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-enterprise-patterns:base-pattern-reviewer` | sonnet | read-only | Reviewer of small supporting patterns: float money, repeated null handling, registries and service locators, speculative base classes, interfaces beside implementations, plug-in selection and row… |
| `@agent-enterprise-patterns:facade-builder` | sonnet | can edit files | Implementer that builds a coarse remote operation: a facade method, request and response DTOs and assemblers over existing application services, with boundary tests. Use when a remote contract or… |
| `@agent-enterprise-patterns:final-gate` | sonnet | read-only | Pre-merge gate that runs the Patterns of Enterprise Application Architecture review checklist and the six forbidden patterns against the working diff and returns PASS or FAIL with evidence. Use… |
| `@agent-enterprise-patterns:integration-reviewer` | sonnet | read-only | Reviewer of how external and partner systems are consumed: vendor or partner types and field names outside one gateway, internal design shaped by payloads, messages used as domain objects, rules… |
| `@agent-enterprise-patterns:layering-reviewer` | sonnet | read-only | Reviewer of layer assignment and dependency direction: domain or data-access code importing web types, repositories returning response shapes, layers that only forward calls, unassigned files.… |
| `@agent-enterprise-patterns:lead` | opus | read-only | Triage lead for enterprise application architecture work. Use first on any non-trivial change or review to decide which specialist reviewers, implementers and skills apply, in what order, and which… |
| `@agent-enterprise-patterns:loading-reviewer` | sonnet | read-only | Reviewer of how objects are loaded: queries per row (N+1), lazy associations touched in loops, serializers or templates, duplicate in-memory objects for one row, and expensive joins hidden behind… |
| `@agent-enterprise-patterns:lock-adder` | sonnet | can edit files | Implementer that adds an optimistic offline lock to one entity: version field, conditional update, named conflict error, conflict mapping at the edge and an interleaved-edit test. Use when a review… |
| `@agent-enterprise-patterns:lock-reviewer` | sonnet | read-only | Reviewer of concurrent-edit handling: last-write-wins updates, missing or ignored version checks, locks held across requests or think time, stale locks, groups edited as one without a shared lock… |
| `@agent-enterprise-patterns:logic-mover` | sonnet | can edit files | Implementer that moves a business decision out of a handler, script, SQL, DTO or serializer into the object, function or layer that owns it, in small test-backed steps. Use when review findings or a… |
| `@agent-enterprise-patterns:logic-placement-reviewer` | sonnet | read-only | Reviewer of where business decisions live and whether the business logic pattern fits: rules in controllers, views, SQL or DTOs, rules trapped in growing scripts, anemic models in rich domains, or… |
| `@agent-enterprise-patterns:mapping-reviewer` | sonnet | read-only | Reviewer of object-relational structure: keys and identity fields, foreign keys, association tables, owned child rows, embedded values, serialized blobs, inheritance strategy, scattered SQL… |
| `@agent-enterprise-patterns:persistence-extractor` | sonnet | can edit files | Implementer that extracts SQL, row mapping or storage detail from handlers, services or domain classes behind a repository, mapper or gateway shaped by use-case questions, in small test-backed… |
| `@agent-enterprise-patterns:persistence-reviewer` | sonnet | read-only | Reviewer of data access design: generic or table-shaped repositories, SQL outside data-access code, domain objects that know storage, Active Record in complex domains, and one class serving as row… |
| `@agent-enterprise-patterns:presentation-reviewer` | sonnet | read-only | Reviewer of the presentation edge: business rules, SQL or transactions inside handlers, views and templates, one type reused as form, entity and response, display formatting in domain code, pattern… |
| `@agent-enterprise-patterns:remote-api-reviewer` | sonnet | read-only | Reviewer of the application's own remote boundaries: many calls per user action, object-shaped or fine-grained operations, domain classes on the wire, missing DTO translation, and callers that treat… |
| `@agent-enterprise-patterns:service-layer-reviewer` | sonnet | read-only | Reviewer of application services and use-case classes: naming by table or screen, UI mechanics in signatures, services that forward calls or swallow all domain logic, and duplicated orchestration… |
| `@agent-enterprise-patterns:session-state-reviewer` | sonnet | read-only | Reviewer of state kept between requests: client-held values that drive decisions, session data with no owner or expiry, in-memory sessions on several instances, domain objects stored in sessions… |
| `@agent-enterprise-patterns:test-alignment-reviewer` | sonnet | read-only | Reviewer of test placement: business rules tested only through HTTP or a database, mocked-away data access, workflows without commit and rollback tests, locks without conflict tests, boundary… |
| `@agent-enterprise-patterns:test-writer` | sonnet | can edit files | Implementer that writes tests at the layer that owns each behavior: domain rules without a database, data-access round trips, workflow commit and rollback, interleaved edits, boundary mapping and… |
| `@agent-enterprise-patterns:transaction-reviewer` | sonnet | read-only | Reviewer of transaction ownership and write coordination: commits in helpers, ad hoc saves, remote calls inside a transaction, surprising ORM flush timing, and workflows held in one transaction. Use… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style enterprise-patterns:force-first` | Before any design or code, states the forces in play, the smallest enterprise pattern that fits, the alternative rejected and the trigger that would change the choice. |
| `/output-style enterprise-patterns:mentor` | Teaches the enterprise pattern behind each decision, names the force that chose it, and ends non-trivial answers with one check question. |
| `/output-style enterprise-patterns:pair` | Works in small narrated steps in the book's generation order, runs the tests after each, and asks before any change larger than a few lines or touching a public API, schema or transaction boundary. |
| `/output-style enterprise-patterns:request-path` | Starts every design or change by drawing the request path across layers, marking who owns the transaction, where data is read and written, and every remote hop, then repeats the path after the change. |
| `/output-style enterprise-patterns:strict-reviewer` | Responds with a ranked findings table against the enterprise pattern rules, treats forbidden patterns as blockers, and does not rewrite code unless asked. |
| `/output-style enterprise-patterns:terse` | Gives the result first in a few lines, with no preamble, the pattern chosen in at most a clause, and failing output shown in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** `enterprise-patterns:lead` reads a task or diff and names, in at most five steps, which family reviewers and skills apply and which patterns not to add. The family reviewers (`layering-reviewer`, `logic-placement-reviewer`, `service-layer-reviewer`, `persistence-reviewer`, `transaction-reviewer`, `loading-reviewer`, `mapping-reviewer`, `lock-reviewer`, `presentation-reviewer`, `integration-reviewer`, `remote-api-reviewer`, `session-state-reviewer`, `base-pattern-reviewer`, `test-alignment-reviewer`) are read-only and each owns one concern. The implementers (`logic-mover`, `persistence-extractor`, `facade-builder`, `lock-adder`, `test-writer`) make small changes from findings, run the project's tests and never commit. `enterprise-patterns:final-gate` closes the work with PASS or FAIL. The manual workflows are the entry points you type, and the output styles change how the whole session talks. Every skill, agent and style ends with a `Source` list that ties it to the sections of the upstream rule set.

## Usage walkthroughs

### 1. Review the work in progress, fix it, gate it

You have changed a handler, a service and a repository, and want a second opinion before you stage anything. Start with the router if the change is big:

```text
Use the enterprise-patterns:lead agent on my current changes.
```

It reads `git status` and `git diff`, lists the pattern families the change touches, and gives at most five steps, for example the transaction reviewer first, then the persistence reviewer, then the gate, plus a one-line "do not add" note. Then run the review itself:

```text
/enterprise-patterns:review
```

With no argument it reviews the working diff, applies the rules of each touched family, treats any of the six forbidden patterns as a blocker, and prints ranked findings with `file:line`, the rule by name, why it matters and the smallest fix. If it finds nothing it prints `No findings` and lists the families it checked. To act on the result:

```text
/enterprise-patterns:fix last review
```

`fix` resolves one finding at a time in severity order, records a test baseline first, delegates longer sequences of moves to the matching implementer (`logic-mover`, `persistence-extractor`, `facade-builder` or `lock-adder`), and does not commit. When you are ready to commit or open the pull request:

```text
Use the enterprise-patterns:final-gate agent on my current changes.
```

It checks the ten review-checklist questions and the six forbidden patterns against the diff, cites evidence for each, and answers `GATE: PASS` or `GATE: FAIL` with the blocking items.

### 2. Pick a pattern, plan the change, build it

You must add "reopen a closed ticket within 14 days", and you are not sure how much structure it deserves.

```text
/enterprise-patterns:choose-pattern reopen a closed ticket within 14 days; one table, one rule, no other consumers
```

You get the forces as observations, then a table with one row per open decision: the choice, the force that selected it, the heavier alternative that was rejected, and the observation that would make you escalate. A single independent rule on one table usually comes back as a transaction script or a simple service, with a note on what would change that. The last line names the next command:

```text
/enterprise-patterns:plan reopen a closed ticket within 14 days
/enterprise-patterns:build-feature plan
```

`plan` walks the book's generation order (pattern, coordination, domain decisions, persistence, transaction, boundaries, presentation), adds the cross-cutting questions the change raises, chooses tests by responsibility and lists the patterns you will deliberately not add. `build-feature plan` then builds it in that order, runs the tests after each slice, writes any schema change as a migration file only, and never commits.

### 3. A transaction script has outgrown itself

Two request scripts copy the same refund-window condition, and one copy has drifted.

```text
/enterprise-patterns:escalate-pattern src/orders/refunds.py
```

The skill first demands evidence of a trigger (duplication, lifecycle or invariants) and stops with "no trigger" if there is none. With the trigger confirmed it records a test baseline, pins the decision with a test if none exists, moves the most repeated decision onto the object that owns its data, replaces the copies one at a time, and leaves the scripts as sequences. If the copies disagree it stops and asks which behavior is right. The report ends with the persistence follow-up it did not do and the next candidate decisions. Hand those on:

```text
Use the enterprise-patterns:logic-mover agent to move the remaining decisions listed under Next candidates.
```

### 4. Untangle a fat handler

A 200-line request handler loads rows, checks rules, commits and sends mail.

```text
/enterprise-patterns:responsibility-map src/web/orders.ts
```

This runs in a forked context and returns at most 40 lines: a matrix of the seven responsibilities (presentation, workflow, domain, data access, transaction, concurrency, integration) per unit with evidence, the collisions ranked, and the proposed owner of each mixed responsibility. Plan the split, then delegate the moves:

```text
/enterprise-patterns:plan split the confirm handler into a service, a model rule and a repository
Use the enterprise-patterns:persistence-extractor agent to move the SQL at src/web/orders.ts:40-58 behind an OrderRepository.
Use the enterprise-patterns:logic-mover agent to move the confirmability check onto Order.
Use the enterprise-patterns:transaction-reviewer agent on src/orders.
```

The extractor writes finders named for the questions the use case asks, not for table columns. The mover relocates the rule without changing behavior. The transaction reviewer prints the write trace of the use case, so you can see that there is now one owner, one commit, and that the mail goes out after it.

### 5. Stop users overwriting each other

Support agents edit tickets for minutes at a time, and the second save silently erases the first.

```text
Use the enterprise-patterns:lock-reviewer agent on src/tickets.
```

The reviewer prints a conflict matrix per edited entity: who edits it, whether the edit spans requests, which lock type exists, what happens on conflict, whether there is a stale-lock plan and whether a test exists. A ticket updated by id alone comes back as a major finding (blockers are reserved for the six forbidden patterns). Then:

```text
Use the enterprise-patterns:lock-adder agent to add an optimistic lock to Ticket.
```

The agent locates every write path, adds a version column as a migration file (written, not applied), makes the update conditional on the version read, raises a named conflict error when no row matched, maps it to your usual conflict response at the edge, and writes an interleaved-edit test. Pessimistic locks and retries are out of its scope on purpose; the book allows pessimistic locking only where contention is expected and the cost is justified.

### 6. Replace a chatty API with one coarse call

The order screen makes three calls plus one per line item.

```text
/enterprise-patterns:remote-contract order detail screen
```

The skill first checks that the boundary needs to be remote at all, then counts today's calls, names one operation after the use case, defines the request and response DTOs, the translation, the versioning rule and what the caller does on failure, and prints the before and after call counts. Build and then check it:

```text
Use the enterprise-patterns:facade-builder agent to implement the orderScreen contract.
Use the enterprise-patterns:remote-api-reviewer agent on the new facade.
```

The builder writes the facade operation, the DTOs and the assemblers, tests the mapping both ways, and leaves the old endpoints in place, listing them as candidates to retire. The reviewer's call-count table should now show one call that does not grow with the number of lines.

### 7. Audit an inherited system

You joined a team and want to know where the structural pain is before touching anything.

```text
/enterprise-patterns:audit src
```

The forked audit rates fourteen pattern families (healthy, watch, hot or unknown) with `file:line` evidence, lists at most five hot spots each pointing at the skill that treats it, and ends with a suggested next command. When forbidden patterns look likely, take the next step it names:

```text
/enterprise-patterns:blocker-scan src
/enterprise-patterns:fix src/web/orders.ts:40
```

`blocker-scan` reports only instances of the six patterns the source treats as blockers, confirmed by reading, with documented exceptions listed separately. `fix` then takes the chosen finding, records a baseline and resolves it with the smallest change.

### 8. Learn the reasoning while you work

You are onboarding someone, or yourself, and want the pattern and the force behind every choice.

```text
/output-style enterprise-patterns:mentor
/enterprise-patterns:explain-rule optimistic offline lock
```

In `mentor` mode every answer does the task first, adds a short **Why** block naming the patterns used, the force that selected each and the alternative left out, and ends with one check question. `explain-rule` gives one rule in detail: its strength (must, should, must not, or a selection condition, taken from the source's wording), the reason, a check you can run on real code, an original example and the book's own exceptions. For design discussions, `force-first` prints the forces, the smallest fitting pattern and the escalation trigger before any code, and `request-path` draws the path across layers, with transaction and remote hops marked, before and after each change.

## How it maps to the book

Section names below are the headings of the upstream full rule set vendored at `skills/principles/references/full.md`. The generated `docs/TRACEABILITY.md` lists every component per section, including the pattern subsections.

| Upstream section | Where it is applied |
| --- | --- |
| Purpose | `principles`, `explain-rule`, `responsibility-map`, `mentor` |
| Primary Directive | `layering`, `responsibility-map`, `lead`, `force-first` |
| Architectural Baseline | `layering`, `layering-reviewer`, `audit`, `request-path` |
| Choosing the Business Logic Pattern | `business-logic-patterns`, `choose-pattern`, `escalate-pattern`, `logic-placement-reviewer`, `logic-mover` |
| Application Workflow Rules | `service-layer`, `service-layer-reviewer`, `remote-boundaries` |
| Persistence Pattern Rules | `repository`, `data-mapper`, `gateways-and-active-record`, `persistence-reviewer`, `persistence-extractor` |
| Identity, Caching, and Unit-of-Work Rules | `loading-behavior`, `transactions-and-unit-of-work`, `loading-reviewer` |
| Object-Relational Mapping Pattern Index | `relational-mapping-structure`, `inheritance-mapping`, `query-and-metadata-mapping`, `mapping-reviewer` |
| Concurrency and Transaction Rules | `offline-locking`, `transactions-and-unit-of-work`, `transaction-reviewer`, `lock-reviewer`, `lock-adder` |
| Presentation Layer Rules | `presentation-layer`, `web-presentation-patterns`, `presentation-reviewer` |
| Offline and Integration Rules | `integration-boundaries`, `integration-reviewer` |
| Session State and Base Pattern Index | `session-state`, `base-patterns`, `session-state-reviewer`, `base-pattern-reviewer` |
| Distribution Rules | `remote-boundaries`, `remote-contract`, `remote-api-reviewer`, `facade-builder` |
| Code Generation Rules | `build-feature`, `plan`, `choose-pattern`, `service-layer`, `pair` |
| Review Rules | `review`, `audit`, `fix`, `strict-reviewer` |
| Forbidden Patterns | `blocker-scan`, `review`, `final-gate`, `strict-reviewer` |
| Testing Rules | `testing-by-responsibility`, `test-alignment-reviewer`, `test-writer` |
| Review Checklist | `checklist`, `final-gate`, `audit` |
| Final Instruction | `principles`, `lead`, `checklist`, `choose-pattern`, `terse` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. This book is a pattern selector, so its pairings depend on who should arbitrate the design:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `ddd-implementing` | Conflicting (conflict 66%, overlap 72%) | Do not load both as equal active guidance. The DDD implementation book commits to aggregates, aggregate-root repositories and domain events, while this one deliberately allows a transaction script, table module, Active Record or a simple service when the forces fit. If you load both, make `ddd-implementing` primary and limit this plugin to one infrastructure decision at a time (a unit of work, an identity map, locks, DTOs, session state). |
| `ddd` | Conflicting (conflict 62%, overlap 68%) | Same shape. Prefer `ddd` when model language, invariants, lifecycle or bounded contexts drive the design; prefer this plugin for choosing enterprise patterns, including the simpler ones, outside strong domain-model pressure. Use both only with `ddd` primary. |
| `clean-architecture` | Overlap (conflict 44%, overlap 64%) | Both govern responsibilities, layering and persistence isolation. Choose one primary. Use `clean-architecture` when policy independence and dependency direction are the main risk; use this plugin to select concrete persistence, transaction, remoting or session-state patterns. Loading both equally invites too many layers. |
| `refactoring` | Complementary (conflict 12%, overlap 38%) | It controls safe change sequencing and stop conditions; this plugin defines the target design. Use both when reshaping existing code toward these patterns without changing behavior, and prefer the refactoring plugin when observable behavior must stay exactly the same. `legacy-code` pairs the same way (conflict 12%, overlap 38%) when tests are weak: characterize first, then apply this plugin inside the controlled area. |
| `data-intensive-apps` | Complementary (conflict 10%, overlap 35%) | It supplies source-of-truth, consistency, replay and schema-evolution semantics; this plugin supplies the application-level patterns on top. Use both when a change touches state, events or ownership as well as workflow and persistence structure. |

`ddd-distilled` is rated as overlap (conflict 50%, overlap 66%): let it decide first whether domain-driven design is justified at all, and then use this plugin for the specific enterprise pattern decision. The remaining books (`release-it`, `clean-code`, `code-complete`, `philosophy-of-design`, `pragmatic-programmer`, `refactoring-guru`) are rated complementary, with the usual condition that you load a second rule set only when its trigger is present.

**Recommended pairing.** Keep this plugin as the one always-on rule set (`inject_rules` on) for server-side business application work, and bring in `refactoring` or `legacy-code` on demand when you are changing existing code. **Avoid loading together:** `ddd` or `ddd-implementing` as equal active guidance alongside this plugin, and `clean-architecture` at equal weight, each with `inject_rules` on. Do not run several books' `lead` agents at once to plan one task by hand: they give overlapping plans, so choose one router. (`/guided:review` is the exception: it asks each book's lead only to pick that book's reviewers and merges the findings itself.)

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **Context cost.** Twenty model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; install only the book plugins you need, because Claude Code's per-skill overrides do not apply to plugin skills and the whole plugin is the smallest unit you can turn off; and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce a tidy layered design that still misses the task. Reviewers, gate and styles add structure, but cannot guarantee obedience.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the mistakes your agents actually make; it will usually matter more than any generic rule.
- **Overengineering is the main risk, and the book is the brake.** Applied mechanically, a pattern catalog produces layers, repositories and DTOs nobody needed. The skills carry the source's own instruction to choose the smallest set of patterns, and `choose-pattern`, `escalate-pattern` and the `force-first` style exist to require evidence of a force, but you still need to judge.
- **A dated catalog.** The book is from the early 2000s. Many of its patterns, such as the unit of work, identity map, lazy loading, data mapper, front controller and template view, are now provided by ORMs and web frameworks, so the practical question is often "which pattern is my framework using and do I understand its timing" rather than "which one to write". Single-page front ends, event-driven designs and service-to-service architectures are outside its focus; the rules on coarse boundaries and translation transfer, the pattern names do not always.
- **Contested advice.** Active Record versus Data Mapper, generic repositories, the weight of a service layer and whether a rich domain model pays off are argued in the community. Where the source says "prefer", the skills say "prefer"; text labeled "Added judgment" is this plugin's own heuristic, and text labeled "compact checklist" comes from the compressed rule files only.
- **What it cannot detect.** The reviewers work by reading diffs and files. They do not execute code or queries, so N+1 behavior is estimated from the code, transaction isolation and lock timing are not observed, and a test that passes for the wrong reason is not seen. Distributed consistency, timeouts and retries are outside this book. The validator for this repository checks structure and traceability, not the quality of the advice.
- **Frameworks and conventions win.** Where a framework or a repository convention conflicts with a rule (an ORM that requires annotated entities, a platform that always opens a transaction), the priority order is your instruction, then the repository, then the book.
- **The model may already know the book.** The value here is a short, decision-changing reminder plus structure, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Patterns of Enterprise Application Architecture rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Patterns of Enterprise Application Architecture* is by Martin Fowler. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
