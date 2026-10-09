# Implementing Domain-Driven Design

Vaughn Vernon's practical, implementation-level take on Domain-Driven Design, turned into a Claude Code toolkit. It makes Claude name the bounded context before it writes a class, keep each aggregate small and tied to a rule, refer to other aggregates by identity, translate wherever one model meets another, and hold back from ceremony where an area is plain CRUD.

Below the overview you will find the full component list (generated from the files themselves), eight usage walkthroughs with exact commands, a map from the rule set's sections to the components, how this plugin sits next to the other DDD and architecture plugins, and an honest section on what it cannot do.

## Overview

**The book in one paragraph.** *Implementing Domain-Driven Design* is about doing DDD in real code rather than admiring it on a whiteboard. It asks for explicit bounded contexts with their own language, aggregates designed as small consistency boundaries around rules that must hold at once, identities instead of object graphs between aggregates, consistency across aggregates that is usually eventual, and integration across contexts through deliberate translation instead of a shared model. It adds the implementation vocabulary around those ideas: entities and value objects that carry behavior, domain services, repositories for aggregate roots, domain events as business facts, event sourcing only where history is the right storage, thin application services, modules that show the model, and representations for clients that do not expose aggregates. The rule set this plugin is built on states its aim as practical DDD instead of theory theater: reject designs that sound like DDD but behave like generic CRUD with renamed classes.

**Who this is for.** Developers using Claude Code on a codebase that has already chosen DDD, or that is about to, and where the questions are implementation questions: where does this aggregate end, why does this use case save two things, what should this repository return, how do we consume the legacy billing model without letting it in, is this event a fact or a command. It also helps a team arguing about how much of this to apply, because the brake is part of the rule set.

**What this toolkit adds.** The rule set is short, so the toolkit does not paraphrase it a second time. It separates roles and situations. A rules skill states a cluster once; a manual workflow produces the evidence the rules ask for (an invariant list before a boundary changes, a context map from the code, a verdict on how much modeling an area earns); a read-only reviewer reports a ledger shaped to its concern; an implementer makes one kind of change in small steps and runs your tests; a gate answers the checklist with evidence. Two session modes keep a frame in front of every answer: the context and its terms, or the invariants and transaction scope.

**When not to use it.** If the system has not committed to DDD and a simpler pattern fits, load a different book first. The upstream compatibility notes call the pairing with the enterprise-patterns book conflicting, because it may deliberately choose Transaction Script or Active Record where this plugin pushes toward aggregates. If you are still discovering the model with domain experts, or classifying subdomains, the sibling plugins `ddd` and `ddd-distilled` are the better primary rule set. If the work is a tiny edit to plain CRUD code, load nothing.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install ddd-implementing@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/ddd-implementing
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall ddd-implementing@guided-plugins
```

## Components

The pieces fit as a pipeline you enter at any point. `ddd-implementing:lead` routes a task to at most five steps. The reviewers (one concern each, read-only) and the manual workflows produce findings and evidence. The five implementers make one kind of change at a time and run your tests. `ddd-implementing:final-gate` closes the work with a PASS or FAIL against the checklist. The `principles` skill is the hub: it loads the rules in the right order and holds the routing table to every component.

<!-- COMPONENTS:START -->

**57 components:** 30 skills (20 Claude can load on its own, 10 you run by name), 21 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/ddd-implementing:aggregate-boundaries` | Use when designing or reviewing what belongs inside one aggregate: its size, members, invariants, or an aggregate shaped like an ORM object graph. Inside one aggregate only. Outside access is aggregate-root-discipline… |
| `/ddd-implementing:aggregate-root-discipline` | Use when code outside an aggregate sets its fields, mutates child entities, receives its child collections or navigates through its internals. Judges the access surface; where the deciding code lives is… |
| `/ddd-implementing:anticorruption-layer` | Use when code consumes a legacy system, vendor or partner API, or another context's model, and foreign names, status codes or schemas appear in local domain code. Builds and tests the inbound translation. Outbound… |
| `/ddd-implementing:application-services` | Use when writing or reviewing use-case code in a modeled area: a service or handler that loads, calls, saves and publishes, or whose branching on business state keeps growing. Thin orchestration and transactions.… |
| `/ddd-implementing:bounded-context` | Use when deciding which bounded context code belongs to, when one class or enum is used by several contexts, or when a model looks shared or global. Owns ownership and validity of a model. Folder layout is… |
| `/ddd-implementing:client-representations` | Use when a UI, REST endpoint, report or other client needs data shaped differently from an aggregate: serializing aggregates, per-client DTOs, projections, read models, query/command split, owner scope. Clients of this… |
| `/ddd-implementing:context-mapping` | Use when two bounded contexts, a legacy system or a partner exchange data or terms, or when no one can say who translates between them. Decides the relationship, influence and translation ownership. The translator is… |
| `/ddd-implementing:core-domain-focus` | Use when deciding how much DDD modeling an area deserves: plain CRUD or reference data wrapped in aggregates and events, or real lifecycle and invariants kept as flat records and scripts. Rules for core-domain effort… |
| `/ddd-implementing:cross-aggregate-coordination` | Use when an aggregate holds or loads another aggregate, or one use case saves several aggregates in a single transaction. Identity references, one aggregate per transaction, eventual coordination. Not for the inside of… |
| `/ddd-implementing:domain-events` | Use when naming, shaping, raising or reviewing a domain event: past-tense facts, payload, and events that are really commands or property changes. Events as model facts. Messages leaving a context are… |
| `/ddd-implementing:domain-services` | Use when a domain operation needs several domain objects and fits no single entity or value object, or when a class with a domain-sounding name only maps between schemas. Domain layer only; load-call-save use-case code… |
| `/ddd-implementing:domain-tests` | Use when writing or reviewing tests of domain code: aggregate invariants, state transitions, value objects, domain events, repositories, translators and application services. Says what each layer's test asserts and… |
| `/ddd-implementing:entities` | Use when designing or reviewing a class that has identity and a life cycle: status fields, setters, state transitions, or an ORM-mapped class with no behavior. Covers identity, transitions and domain verbs. Outside… |
| `/ddd-implementing:event-sourcing` | Use when deciding whether to persist an aggregate as its sequence of events, or when writing or reviewing event streams, replay, event versions or upcasters. Storage by events only. Events as announced facts, with or… |
| `/ddd-implementing:integration-contracts` | Use when data leaves a bounded context for another: a message, event payload, API response, identifier, or another context reading its tables. Shapes the outbound contract model. Inbound is anticorruption-layer; who… |
| `/ddd-implementing:module-structure` | Use when laying out or moving folders, packages or modules: a layer-only tree, a shared or common package, or directory names that hide the model. Layout only. Which context owns a class is bounded-context; what… |
| `/ddd-implementing:principles` | Applies the Implementing Domain-Driven Design rule set to code that models a business domain. Use for any task on bounded contexts, aggregates, repositories, domain events, application services or cross-context… |
| `/ddd-implementing:repositories` | Use when writing or reviewing a repository interface or implementation: one per aggregate root, its methods, what it returns, and whether business rules or ORM rows leak through it. Persistence contract only. Client… |
| `/ddd-implementing:ubiquitous-language` | Use when naming or renaming a class, method, event, test or package, when one concept has several names, or when one term carries two meanings inside the same context. Keeps one local term per concept. Which context… |
| `/ddd-implementing:value-objects` | Use when raw primitives such as strings, numbers, dates or ids carry business meaning, when a small value class is mutable or unvalidated, or when equality of a descriptive type is by identity. Immutable, validated… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/ddd-implementing:audit` | Scan a directory or repository for Implementing Domain-Driven Design health in a forked context and return ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/ddd-implementing:ceremony-check` | Plan, for named areas (paths, contexts or subdomain names), what to keep, trim or extract so the modeling matches the complexity there, with evidence per signal. Reads whole areas, not a diff; reviewing a diff is the… | `[areas: paths, contexts or subdomain names \| empty for the areas in the current diff]` |
| `/ddd-implementing:checklist` | Walk the Implementing Domain-Driven Design review checklist interactively: ten source questions plus five compact additions, each answered yes, no or not applicable with a next action. | `[paths \| git ref \| empty for the current diff]` |
| `/ddd-implementing:context-map` | Reconstruct the context map of a codebase as found in a forked context: contexts, relationships, translation points and leaks, in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/ddd-implementing:explain-rule` | Explain one Implementing Domain-Driven Design rule: its strength, the reason, how to check it in code, a small example and where it bends. | `[rule name \| section name \| question about a rule]` |
| `/ddd-implementing:fix` | Resolve named Implementing Domain-Driven Design findings with the smallest change that fixes each, run the tests after every step, and never commit. | `[findings text \| review output \| finding ids \| empty to fix the findings above]` |
| `/ddd-implementing:invariant-inventory` | List the invariants of an aggregate or use case, decide which must hold immediately and which may be eventual, and propose or defend the aggregate boundary or transaction scope with that evidence. | `[aggregate or class \| use case \| empty to ask or use the diff]` |
| `/ddd-implementing:model-walk` | Walk a new domain concept through the nine code-generation steps and produce a model sheet before any code: context, terms, tactical types, aggregate boundary, references, invariants, repositories, services… | `[concept or feature description \| issue text \| empty to ask]` |
| `/ddd-implementing:plan` | Plan a change to existing DDD code: context, edit order, tests first, boundary and transaction decisions, hand-offs and stop conditions. Plans only. | `[change request \| issue text \| empty to plan from the current diff]` |
| `/ddd-implementing:review` | Review a diff or paths against the Implementing Domain-Driven Design rules and report ranked findings, each mapped to the skill that treats it. | `[paths \| git ref \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-ddd-implementing:acl-builder` | sonnet | can edit files | Implementer that wraps a legacy, vendor, partner or other-context model behind a narrow port in local language with a translator and its tests, then migrates callers one at a time. Use when reviews… |
| `@agent-ddd-implementing:aggregate-design-reviewer` | sonnet | read-only | Reviewer of aggregate shape: size, which invariant justifies each member, ORM-shaped object graphs, and object references to other aggregates instead of identities. Use proactively after edits that… |
| `@agent-ddd-implementing:context-boundary-reviewer` | sonnet | read-only | Reviewer of context ownership and layout: which bounded context each changed file belongs to, shared or common domain packages, global models, boundaries that exist only in diagrams, and package… |
| `@agent-ddd-implementing:domain-test-writer` | sonnet | can edit files | Implementer that writes tests for domain code by layer: invariants, transitions, value objects, events as outcomes, translators, repositories and application-service orchestration, in the ubiquitous… |
| `@agent-ddd-implementing:event-reviewer` | sonnet | read-only | Reviewer of domain events: past-tense facts versus commands, events emitted per property change, payloads with framework or persistence types, repair events, and publication order. Use proactively… |
| `@agent-ddd-implementing:event-sourcing-reviewer` | sonnet | read-only | Reviewer of event-sourced aggregates: whether sourcing is justified, stream identity and versioning, deterministic replay, event versions and upcasters. Use proactively after edits that add or… |
| `@agent-ddd-implementing:final-gate` | sonnet | read-only | Pre-merge gate that runs the Implementing Domain-Driven Design review checklist (ten questions plus five compact additions) against the working diff and returns PASS or FAIL with evidence. Use when… |
| `@agent-ddd-implementing:identity-reference-converter` | sonnet | can edit files | Implementer that replaces object references between aggregates with identity references in small test-backed steps, and moves an unrelated member of an oversized aggregate into its own aggregate… |
| `@agent-ddd-implementing:language-reviewer` | sonnet | read-only | Reviewer of ubiquitous language: synonyms for one concept, one term with two meanings, technical placeholders, foreign vocabulary, and names in tests, events and packages that drift from the model.… |
| `@agent-ddd-implementing:lead` | opus | read-only | Triage lead for Implementing Domain-Driven Design work. Use when starting any non-trivial change or review to decide which reviewers, skills and (only when edits were requested) implementers apply… |
| `@agent-ddd-implementing:modeling-effort-reviewer` | sonnet | read-only | Reviewer of modeling effort per area: DDD patterns on trivial CRUD, vocabulary without design change, vendor terms in the core, and real lifecycle complexity left in service branching. Use… |
| `@agent-ddd-implementing:repository-reviewer` | sonnet | read-only | Reviewer of repository contracts: one per aggregate root, method shape, return types, generic CRUD bases, ORM rows leaking out and business rules inside implementations. Use proactively after edits… |
| `@agent-ddd-implementing:representation-reviewer` | sonnet | read-only | Reviewer of what clients receive and ask for: aggregates or rows serialized to APIs and views, one DTO for every client, load-and-stitch reads, domain annotations for the wire, and implicit tenant… |
| `@agent-ddd-implementing:root-discipline-reviewer` | sonnet | read-only | Reviewer of aggregate access paths: public setters, returned mutable collections, child entities held outside the root, and callers that read state and write it back. Use proactively after edits to… |
| `@agent-ddd-implementing:root-encapsulator` | sonnet | can edit files | Implementer that moves invariant-changing logic behind aggregate root methods and closes setters and exposed collections, one finding at a time with tests. Use when reviews find outside code… |
| `@agent-ddd-implementing:rule-placement-reviewer` | sonnet | read-only | Reviewer of where business decisions live: model, domain service, application service, controller or repository. Finds branching rules in the wrong layer, duplicated invariants, behavior parked in… |
| `@agent-ddd-implementing:test-coverage-reviewer` | sonnet | read-only | Reviewer of domain test coverage: maps each changed domain behavior to the layer of test the rules call for (invariant, transition, value, event, repository, translator, application service) and… |
| `@agent-ddd-implementing:transaction-reviewer` | sonnet | read-only | Reviewer of transaction scope in use cases: how many aggregates each transaction saves, the invariant that justifies it, and whether cross-aggregate reactions run in their own transactions. Use… |
| `@agent-ddd-implementing:transaction-splitter` | sonnet | can edit files | Implementer that splits a use case saving several aggregates into one transaction per aggregate, coordinated by a past-tense domain event and a repeat-safe policy, after the invariants are listed… |
| `@agent-ddd-implementing:translation-reviewer` | sonnet | read-only | Reviewer of boundary crossings: every place a model enters or leaves a context or system, in which direction, as which type, and where it is translated. Use proactively after edits that call another… |
| `@agent-ddd-implementing:value-object-reviewer` | sonnet | read-only | Reviewer of value types and primitive obsession: meaningful primitives in signatures and fields, mutable or unvalidated value classes, identity-compared values, and rules copied across callers. Use… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style ddd-implementing:context-first` | Opens every design or code answer with the bounded context, its local terms and its relationship to neighbors, and asks one question when the context is unknown. |
| `/output-style ddd-implementing:invariant-first` | Before any change to an aggregate, a transaction or an event, prints the invariants, the boundary decision and the transaction scope, then makes the change. |
| `/output-style ddd-implementing:mentor` | Teaches the Implementing Domain-Driven Design rule behind each decision, names its strength and provenance, and checks understanding with one question. |
| `/output-style ddd-implementing:pair` | Works in small narrated steps and asks before changing an aggregate boundary, a transaction scope, a published contract or anything past a few lines. |
| `/output-style ddd-implementing:strict-reviewer` | Answers as a ranked findings table against the Implementing Domain-Driven Design rules, does not rewrite code unless asked, and says No findings explicitly. |
| `/output-style ddd-implementing:terse` | Result first, no preamble, a few lines at most unless asked, while still reporting what ran, any unresolved risk, and failing output in full. |

<!-- COMPONENTS:END -->

Rules in the skills carry a strength tag taken from the rule set: `[MUST]`, `[MUST NOT]`, `[SHOULD]`, `[SHOULD NOT]` and `[MAY]`. `[Compact checklist]` marks a rule that appears only in the shorter rule files, and `[Added judgment]` marks this plugin's own heuristics, detection recipes and numeric search aids. Nothing tagged `[Added judgment]` is a rule of the book.

## Usage walkthroughs

The commands below are exact. Agents are asked for by name in plain language ("use the transaction-splitter agent"); slash commands and output styles are typed as shown.

### 1. Review the work in progress before a pull request

Situation: you added renewal and return use cases under `src/lending` and a new `GET /loans/:id` endpoint.

```text
/ddd-implementing:review
```

The skill runs `git status` and `git diff`, reads the compact rules, names the bounded context of each changed file, walks the source's ten review items and the "avoid by default" list, and ranks what it finds. Each finding carries a file and line, the rule with its strength, a one-sentence consequence, the smallest fix and the skill that treats it. A typical result: a BLOCKER at `src/lending/http/loans.ts:12` because the endpoint serializes the `Loan` aggregate (`/ddd-implementing:client-representations`), and a MAJOR at `src/lending/return_copy.ts:31` because one transaction saves `Loan` and `Copy` with no immediate invariant named (`/ddd-implementing:cross-aggregate-coordination`). It ends with one next step and never edits.

Resolve the first finding in the session:

```text
/ddd-implementing:fix 1
```

`fix` runs your test command for a baseline, makes the smallest change (a `LoanSummary` representation and a use-case query), runs the tests again and reports. It will not touch finding 2: it changes consistency from immediate to eventual, so `fix` stops and asks. Walkthrough 2 handles it. When both are done, ask for the gate:

```text
Use the final-gate agent on the working diff.
```

The gate answers fifteen questions (the source's ten plus five compact additions) with `file:line` evidence and returns `GATE: PASS` or `GATE: FAIL` with the blocking items listed. It does not run tests; it asks for the output you ran.

### 2. Split a use case that saves two aggregates

Situation: `ReturnCopy` loads a `Loan` and a `Copy`, changes both and saves them in one transaction. First, collect the evidence:

```text
/ddd-implementing:invariant-inventory ReturnCopy
```

The workflow lists the rules the use case must keep, the data each one touches, where each is enforced today and its timing. For a rule it cannot place it writes `ask` and phrases the question for the domain expert instead of deciding. A typical result: the loan's "cannot be returned twice" rule is immediate and lives in `Loan`; "a copy is available again after return" spans `Loan` and `Copy` but no immediate rule requires them to change together; verdict `make eventual`; question for the business: "if the copy is shown as on loan for a few seconds after return, what goes wrong?" The next step it names is `ddd-implementing:transaction-splitter`.

Ask the business, then hand over:

```text
Use the transaction-splitter agent on ReturnCopy. The inventory above shows no immediate rule spans Loan and Copy, and the library accepts that copy availability updates shortly after a return.
```

The agent needs exactly those three things: the use case, the invariant list, and the statement that the delay is acceptable. It records the baseline test run, creates the past-tense event `CopyReturned` in the domain package with identities and an event id, makes `Loan` return it, reduces the use case to load, call, save and publish after the save, writes a policy that changes `Copy` in its own transaction keyed by the event id so a repeated delivery changes nothing, and adds the outcome, policy and repeat-delivery tests. Its report has a `Consistency change: immediate -> eventual` line so the reviewer sees what was accepted. If the project has no event mechanism it stops and says so; it does not add a broker. Finish with a review of the result:

```text
Use the transaction-reviewer agent on the working diff.
```

It returns a transaction map: `ReturnCopy` now saves one aggregate, and the policy runs in its own transaction.

### 3. Design a new concept before any code

Situation: members want a waiting list for popular titles.

```text
/ddd-implementing:model-walk waiting list for popular titles
```

The skill refuses to model a concept that is plain CRUD; this one has state-dependent rules, so it walks the nine code-generation steps and prints a model sheet of at most forty lines: the context (lending), the terms (waiting list, place, notification) with the words not to use, the tactical type of each concept, the conservative aggregate boundary and the rules that justify it, identity references (`TitleId`, `MemberId`), invariants with timing, the repository's questions in business words, the use cases, and the boundaries crossed (notifying members is another context's job). It checks the sheet against the "avoid by default" list and ends with open questions for the domain expert and `Next step: /ddd-implementing:plan <change>`.

Then sequence the edits:

```text
/ddd-implementing:plan add the waiting list from the model sheet
```

`plan` starts from the model sheet, finds your test command, lists the decisions needed before any edit (the immediate invariants, the notification contract), orders the work from the inside out (tests on the aggregate, model, repository, application service, boundary translation, interfaces, module moves kept apart from behavior changes), and names the reviewers and the gate to use. It edits nothing.

### 4. Decide how much DDD an area deserves

Situation: the codebase has an aggregate, a repository and two events around a table of country codes, while the loan-renewal rules sit as `if` chains in `LoanService`.

```text
/ddd-implementing:ceremony-check reference/country lending/loans
```

For each area the skill gathers evidence for three signals (rules that depend on state, an invariant over more than one field or object, vocabulary the business argues about; these signals are this plugin's judgment, not the book's), lists what the area has today, sets a target level and decides keep, trim or extract. Typical result: `reference/country` has target `plain` and decision `TRIM`; `lending/loans` has target `full` and decision `EXTRACT`, with the evidence `src/lending/loan_service.ts:40-96` branching on status for five rules. The ordered plan it prints names what to remove or extract first and the skill that covers it. It reads whole areas; it is not a diff review.

Remove the machinery that carries no rule, passing the first step of the plan as the finding:

```text
/ddd-implementing:fix remove the events and the repository around reference/country (ceremony-check plan step 1)
```

`fix` runs the tests for a baseline, removes one pattern at a time with the tests green, and reports. Then move the rules into the model:

```text
Use the root-encapsulator agent to move the renewal branches in LoanService.renew onto Loan.
```

The agent baselines the tests, pins the rule with a test on `Loan` if none exists, adds `Loan.renew` in the context's language, switches the caller, removes the old branch, closes any setter the old code needed and reports what it left alone. For a diff-level check afterwards, ask for the `modeling-effort-reviewer` agent: it judges only the changed code and returns findings by severity with `file:line`, plus a list of the areas the change touched.

### 5. Put a legacy system behind an anticorruption layer

Situation: the legacy CRM's statuses (`"A"`, `"S"`, `"X"`) have leaked into the lending domain.

```text
/ddd-implementing:context-map src
```

The skill runs in a forked context so the scan does not fill your session, and returns at most forty lines: the contexts it found, an edge table with the mechanism and where the translation lives, and ranked leaks. Typical result: `lending -> crm` is an HTTP client with no translator, and `src/lending/domain/member.py:4` imports the CRM client's customer type. For the relationship and ownership question, ask in plain words and the `context-mapping` skill loads on its own:

```text
Who should own the translation between lending and the CRM, and how do we record it?
```

Then build the boundary:

```text
Use the acl-builder agent to put the CRM customer type behind a port in lending.
```

The agent finds every foreign usage, writes the local concept each stands for (and asks once if the context has no word for it), defines a narrow port with no foreign type in its signatures, writes the translator in the infrastructure package with a loud policy for an unknown status, tests it with sample payloads and no live calls, migrates callers one at a time and lists any foreign imports left. Confirm with the `translation-reviewer` agent: its crossing inventory should show the CRM edge as translated in `lending/infra`.

### 6. Learn the reasoning while you work

```text
/output-style ddd-implementing:mentor
```

Ask for a normal task, for example "add a method to cancel a reservation". Claude does the work and adds a Why block of at most four lines: each rule you applied, in plain words, with its strength (`SHOULD`, `MUST NOT`) and the failure it prevents, and whether it comes from the full rule set, the compact files or this plugin's own judgment. Non-trivial answers end with one question, such as which immediate invariant would force two entities into one aggregate. To study a single rule on its own:

```text
/ddd-implementing:explain-rule one aggregate per transaction
```

The result is a short card: the section and strength, what it asks, why, how to check it in code, an example of at most fifteen lines, where the source itself says it bends, and the skill and agent that apply and review it. Switch back with `/output-style default`.

### 7. Audit a repository, then follow the map

```text
/ddd-implementing:audit src
```

The forked scan reads up to fifteen files, probes each cluster with read-only searches (contexts and layout, language, aggregate size, root discipline, cross-aggregate links, entities and values, repositories, events, services, integration, client representations, modeling effort, tests), rates each healthy, watch, hot or unknown, and returns at most forty lines with five ranked hot spots and one next command. If the top hot spot is a `shared` package imported by three contexts, the next command is:

```text
/ddd-implementing:context-map src
```

When you are not sure where to start on the resulting leaks, ask the router:

```text
Use the lead agent: billing and lending import the same Customer class from a shared package, and we want the edits made.
```

`lead` replies with its context, whether the area is modeled, and at most five steps in order, for example `context-boundary-reviewer` first (who owns the class and where the shared package is used), `translation-reviewer` next (the crossing and who translates), `/ddd-implementing:integration-contracts` (which identifier or message crosses once each side has its own model), `acl-builder` because edits were requested, and `final-gate` last. The `acl-builder` covers only the foreign-model part: the context that does not own `Customer` reads the owner's contract model through its own port and translator. Splitting the shared class into two local models stays a design decision for the team; no implementer makes it. `lead` routes; it does not review.

### 8. Keep a frame in front of every answer

Two modes carry a discipline through a session. For strategic work:

```text
/output-style ddd-implementing:context-first
```

Each answer opens with `Context:`, `Terms:` and `Neighbors:`, asks one question when the context is unknown, and closes with `Crossing:` when a boundary is touched. For model changes:

```text
/output-style ddd-implementing:invariant-first
```

Ask: "let a member join a cohort while seats are free". Before editing, Claude prints an Invariants table (rule, data it spans, timing), a one-line boundary decision and the transaction scope, makes the change, and finishes with a Proof line naming a test for each row. If a timing is `ask`, it puts the question to you and stops.

## How it maps to the book

The upstream rule set has nineteen sections. Every one is applied by at least one component; the validator checks this, and `docs/TRACEABILITY.md` is the generated, exhaustive version. `docs/DESIGN.md` explains the split and lists the pairs of skills that could be confused and how they were separated.

| Upstream section | Where it is applied |
| --- | --- |
| Purpose | `explain-rule`, `principles`, `mentor` |
| Primary Directive | `bounded-context`, `core-domain-focus`, `explain-rule`, `model-walk`, `module-structure`, `principles`, `lead`, `context-first` |
| Strategic Design Rules | `bounded-context`, `ceremony-check`, `context-map`, `context-mapping`, `core-domain-focus`, `module-structure`, `context-boundary-reviewer`, `modeling-effort-reviewer`, `context-first` |
| Ubiquitous Language Rules | `domain-tests`, `ubiquitous-language`, `domain-test-writer`, `language-reviewer`, `context-first` |
| Aggregate Rules of Thumb | `aggregate-boundaries`, `aggregate-root-discipline`, `cross-aggregate-coordination`, `invariant-inventory`, `aggregate-design-reviewer`, `identity-reference-converter`, `root-discipline-reviewer`, `root-encapsulator`, `transaction-reviewer`, `transaction-splitter`, `invariant-first`, `pair` |
| Entity and Value Object Rules | `entities`, `value-objects`, `root-discipline-reviewer`, `value-object-reviewer` |
| Domain and Transformation Service Rules | `anticorruption-layer`, `domain-services`, `acl-builder`, `rule-placement-reviewer`, `translation-reviewer` |
| Repository Rules | `repositories`, `repository-reviewer` |
| Domain Event Rules | `domain-events`, `event-sourcing`, `integration-contracts`, `event-reviewer`, `event-sourcing-reviewer`, `transaction-splitter`, `invariant-first` |
| Application Service Rules | `application-services`, `domain-events`, `event-reviewer`, `root-encapsulator`, `rule-placement-reviewer`, `transaction-reviewer` |
| Module and Package Rules | `module-structure`, `context-boundary-reviewer` |
| Context Integration Rules | `anticorruption-layer`, `context-map`, `context-mapping`, `integration-contracts`, `acl-builder`, `translation-reviewer` |
| Client Representation and Scope Discipline | `client-representations`, `integration-contracts`, `representation-reviewer` |
| Practical Simplicity Rule | `audit`, `ceremony-check`, `core-domain-focus`, `modeling-effort-reviewer` |
| Code Generation Rules | `aggregate-boundaries`, `application-services`, `fix`, `invariant-inventory`, `model-walk`, `plan`, `principles`, `review`, `pair` |
| Review Rules | `aggregate-root-discipline`, `audit`, `fix`, `review`, `ubiquitous-language`, `context-boundary-reviewer`, `language-reviewer`, `lead`, `strict-reviewer` |
| Testing Rules | `anticorruption-layer`, `application-services`, `domain-events`, `domain-tests`, `entities`, `plan`, `repositories`, `value-objects`, `acl-builder`, `domain-test-writer`, `test-coverage-reviewer` |
| Review Checklist | `audit`, `checklist`, `fix`, `principles`, `review`, `final-gate`, `strict-reviewer` |
| Final Instruction | `cross-aggregate-coordination`, `explain-rule`, `plan`, `principles`, `final-gate`, `mentor`, `terse` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `ddd` | Overlap (conflict 22%, overlap 80%, complementarity 48%) | Same vocabulary and the same triggers. Choose one as primary. Prefer `ddd` when model discovery, the ubiquitous language and context mapping are the work; prefer this plugin when the design is already DDD and the task is aggregates, repositories, events, application services, projections or context translation. Loading both as equals doubles the pressure to add tactical mechanisms. |
| `ddd-distilled` | Overlap (conflict 20%, overlap 78%, complementarity 52%) | The distilled plugin is a gate; this one is the implementation playbook. They complement each other only after DDD is selected and implementation detail matters. Loaded together as equals, this plugin's tactical stack weakens the other's anti-ceremony gate. Run the gate first, then use this plugin. |
| `clean-architecture` | Overlap (conflict 46%, overlap 66%, complementarity 58%) | They compete for the same architecture layer. Choose one primary: Clean Architecture for dependency direction and replaceable infrastructure, this plugin for DDD implementation decisions. Use both only in an intentionally DDD application with a concrete need for replaceable infrastructure; otherwise ports, use cases, adapters, repositories, events and DTOs stack up. |
| `enterprise-patterns` | Conflicting (conflict 66%, overlap 72%, complementarity 40%) | The enterprise-patterns book can deliberately choose Transaction Script, Table Module or Active Record where this plugin pushes toward aggregates. Do not load them as equal active guidance. Keep this plugin primary for committed DDD work and bring in the other for one infrastructure decision at a time (Unit of Work, Identity Map, Data Mapper, locks, session state) whose force fits your aggregate boundaries. |
| `data-intensive-apps` | Complementary (conflict 10%, overlap 35%, complementarity 80%) | Use it when a change touches source of truth, consistency, schema evolution, event flow or replay. It supplies the mechanics this plugin deliberately leaves out (delivery guarantees, ordering, duplicates) and that its eventual-consistency and event-sourcing rules rely on. |

The compatibility notes rate `refactoring`, `refactoring-guru`, `legacy-code` and `release-it` as complementary (conflict 12%, overlap 34 to 38%, complementarity 78%) and `clean-code`, `philosophy-of-design`, `code-complete` and `pragmatic-programmer` as complementary (conflict 14%, overlap 38%, complementarity 74%). The useful sequencing: `legacy-code` first when behavior is unclear or tests are weak, then this plugin inside the controlled area; `refactoring` when behavior must stay identical while code is reshaped toward these rules; `release-it` when timeouts, retries and overload behavior dominate an integration; `clean-code` for local readability of the classes you write.

**Recommended pairing.** For a system that is already committed to DDD, keep this plugin as the one always-on DDD rule set (`inject_rules` on) and bring in `data-intensive-apps` on demand for events and consistency mechanics and `legacy-code` for weakly tested areas. For a team still deciding how much DDD to apply, start with `ddd-distilled` as primary and add this plugin when an area is chosen for full tactical modeling. **Avoid loading together:** `ddd`, `ddd-distilled` or `enterprise-patterns` alongside this plugin with equal weight and `inject_rules` on in all of them, because the rule sets re-open each other's decisions. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **The rule set is short, and the plugin is large.** The upstream file has nineteen sections. The extra components come from separating roles and situations, not from extra rules. Where a skill goes beyond the rule set (idempotent handlers, a transactional outbox, snapshots, glossary files, import-direction tests, a three-signal test for modeling effort) it is tagged `[Added judgment]`, and those parts lose to your instruction and your repository's conventions.
- **What the rule set does not cover.** It has no section on factories, on process managers or sagas, on delivery guarantees, on CQRS infrastructure beyond the single rule on separating command behavior from query models, or on classifying subdomains. The skills say so where it matters and point to the sibling plugins instead of inventing rules.
- **Context cost.** Twenty model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; disable skills you do not use, and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce code that looks like DDD while missing the task. The reviewers, gate and output styles add structure; they cannot guarantee obedience.
- **Overengineering risk.** Applied mechanically, aggregates, repositories, events and application services appear around CRUD. The brake is built in (`core-domain-focus`, `ceremony-check`, `modeling-effort-reviewer`), but it depends on you loading the right tool for the size of the task.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the mistakes your agents actually make; it will usually matter more than any generic rule.
- **Judgments that need people.** Whether a delay is acceptable to the business, which invariants must hold at once, and what a term means in a context are questions for domain experts. The skills stop and ask rather than answer.
- **What it cannot detect.** The reviewers read diffs and files. They do not execute code, so they cannot find race conditions, performance problems or a test that passes for the wrong reason, and they cannot see consumers of an event that live in another repository. The validator for this repository checks structure and traceability, not the quality of the advice.
- **The model may already know the book.** The value here is a short, decision-changing reminder plus structure, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Implementing Domain-Driven Design rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Implementing Domain-Driven Design* is by Vaughn Vernon. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it. Nothing here is legal advice.
