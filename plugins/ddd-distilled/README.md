# Domain-Driven Design Distilled

Vaughn Vernon's short guide to domain-driven design, turned into a Claude Code toolkit for people who want the benefits of DDD without the ceremony. It makes Claude start from the business (which areas matter, where a model's boundary is, what the words mean) and add a tactical pattern only when it earns its cost, in the order the book recommends and with its own brake against over-modeling.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), seven usage walkthroughs with exact commands, a map from the book's sections to the components, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *Domain-Driven Design Distilled* argues that most teams do not need all of DDD; they need the parts that pay for themselves. Strategic design comes first and gives most of the value: sort the business into core, supporting and generic subdomains and spend the best effort on the core, give each model one bounded context that owns its language, make the relationships between contexts explicit, and translate where meanings differ. Only then choose a few tactical tools (entities with guarded state, value objects that carry their own rules, small aggregates built around invariants, domain events that record real facts) and keep application services thin. Around all of it sit practical accelerators: event storming, timeboxed modeling, spikes, scenarios agreed with domain experts, and an honest record of what was deferred.

**Who this is for.** Developers using Claude Code on business software where the rules, the vocabulary or the integrations are the hard part: order handling, billing, scheduling, claims, logistics, booking. It also fits teams deciding how much DDD a project can sustain, because the plugin's first question is whether an area deserves modeling at all.

**The bias it corrects.** An agent asked to build a feature in a business system tends to fail in one of two directions. Either it models nothing (a controller, a service holding every decision, a class shaped like a table, a status integer, and words borrowed from whichever API it read last), or it overcorrects with an aggregate, a repository, three events and a mapper for a lookup table. This toolkit asks for the middle path the rule set sums up as using DDD selectively, but seriously: business capability and subdomain importance first, then the bounded context, then the local language, and only then the smallest tactical pattern that protects meaning or an invariant.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/ddd-distilled:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- Eighteen topical model-invocable skills, one per rule cluster and written as decisions: when it applies, how to check it, what to do instead, and where the book itself lets the rule bend. Strategic skills (subdomains, bounded contexts, context mapping, translation, integration styles) never discuss class shapes; tactical skills never choose context relationships.
- Thirteen manual workflows named for what the book teaches: `classify-subdomains`, `map-contexts`, `model-first`, `event-storm`, `glossary`, `estimate-work` and `modeling-debt`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- Twenty-one subagents: a `lead` that routes work in at most five steps, fourteen read-only reviewers that each own one concern and report in their own shape (an investment map, an edge table, a term ledger, an invariant-to-boundary table, a use-case transaction map, an event ledger), five implementers that make one small test-backed change, and a `final-gate` that returns PASS or FAIL with evidence.
- Six output styles that change how a whole session behaves, including `context-first` (a context card before every design answer) and `earned-pattern` (every pattern tagged with the reason it earns its cost).
- Honest labels. A rule from the source's full text carries no label. A rule that exists only in the shorter files is marked as a compact-checklist rule, and this plugin's own heuristics are marked as added judgment.

**When not to use it.** Reach for a different plugin when the real risk is elsewhere: Evans' original vocabulary and large-scale structure (`ddd`), implementation depth for work already committed to DDD, such as repositories and aggregate persistence (`ddd-implementing`), choosing enterprise persistence and transaction patterns (`enterprise-patterns`), dependency direction between layers (`clean-architecture`), distributed data semantics (`data-intensive-apps`), or reshaping code that has no tests (`legacy-code`). For a throwaway script, the rules still apply, but the ceremony of this toolkit does not.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install ddd-distilled@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/ddd-distilled
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall ddd-distilled@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**59 components:** 32 skills (19 Claude can load on its own, 13 you run by name), 21 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/ddd-distilled:accelerated-modeling` | Use when workflow, events, commands, policies or team language are unclear, when modeling risks turning into detached analysis, or when delivery pressure tempts skipping design. Covers event storming, timeboxes… |
| `/ddd-distilled:adoption-fit` | Use when deciding whether an area of business software deserves DDD modeling at all, how much effort it earns, or whether an earlier decision needs reassessing. Not for one concept's pattern… |
| `/ddd-distilled:aggregates` | Use when deciding what belongs in one aggregate, reviewing its size, root access or references, or when an object graph is loaded and changed as a whole. A request changing several aggregates… |
| `/ddd-distilled:application-services` | Use when a service, handler or controller makes business decisions, when an application service is shaped by HTTP or message formats, or when deciding what a use-case method may contain. Keeps it to coordination. For… |
| `/ddd-distilled:bounded-contexts` | Use when one class or model is shared across billing, identity, catalog, fulfillment or support, when the same word has different rules in different modules, or when module layout ignores context boundaries. Inside one… |
| `/ddd-distilled:context-mapping` | Use when two contexts or systems must integrate and the relationship (Partnership, Shared Kernel, Customer/Supplier, Conformist, Anticorruption Layer, Open Host Service, Published Language, Separate Ways) is unstated… |
| `/ddd-distilled:context-translation` | Use when another team's model, API payload, event, schema or legacy status codes enter local code, or when an 'anticorruption layer' may translate nothing. Covers translators and their tests. For framework, ORM or HTTP… |
| `/ddd-distilled:cross-aggregate-consistency` | Use when one request or transaction loads or saves more than one aggregate root, when convenience builds a graph, or when a second aggregate must follow the first. Covers transaction scope, eventual consistency. Event… |
| `/ddd-distilled:domain-events` | Use when naming, designing or reviewing domain events, when events are vague, command-like or fired for every field change, or when deciding whether a fact deserves an event. Delivery… |
| `/ddd-distilled:domain-tests` | Use when writing or reviewing tests of domain code: value objects, entity and aggregate transitions, application service orchestration, translators. Tests should read in the ubiquitous language. To build a translator… |
| `/ddd-distilled:entities` | Use when a class has identity and a lifecycle, when public setters let any code change business state, or when an entity is only getters and setters. Covers identity and guarded transitions. Identity-less values… |
| `/ddd-distilled:explicit-concepts` | Use when a boolean, status code, enum, flag, magic string or helper method carries a business decision, or code could belong to any business. Promotes hidden concepts to named ones. For repeated data values use… |
| `/ddd-distilled:infrastructure-isolation` | Use when framework, ORM, persistence, REST or JSON types appear in domain code, when tables or API schemas drive the model, or when a domain method needs a request, session or serializer. For another team's model use… |
| `/ddd-distilled:integration-styles` | Use when choosing or reviewing how contexts talk: RPC, REST resources or asynchronous messaging, and whether a domain event carries its data or makes consumers query back. For converting the foreign model use… |
| `/ddd-distilled:pattern-economy` | Use when deciding which pattern a concept needs (record, value object, entity, aggregate, service, event) or when a module is over- or under-modeled. Shaping a chosen one: /ddd-distilled:value-objects… |
| `/ddd-distilled:principles` | Applies the Domain-Driven Design Distilled rule set to design and coding decisions in business software. Use for any task that creates, reviews or changes domain code where subdomain importance, bounded contexts… |
| `/ddd-distilled:subdomains` | Use when ranking areas of a business system as core, supporting or generic, or when the best modeling effort seems spent on a commodity concern. Covers classification, effort allocation and signs the core has drifted.… |
| `/ddd-distilled:ubiquitous-language` | Use when naming or renaming concepts inside one context, when one concept has several names or one name two meanings there, or when names are placeholders such as Data, Info or Manager. Words: hidden decisions… |
| `/ddd-distilled:value-objects` | Use when a primitive or small group of fields (amount and currency, email, date range) is validated or combined in several places. Covers immutable, self-validating values. Flags and status codes… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/ddd-distilled:audit` | Scan a directory or repository for Domain-Driven Design Distilled health in a forked context and return ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/ddd-distilled:checklist` | Walk the Domain-Driven Design Distilled final checklist against your current work, answering yes, no or not applicable with evidence and a next action for every no. | `[paths \| empty for the current diff]` |
| `/ddd-distilled:classify-subdomains` | Inventory the business capabilities of a codebase in a forked context, propose core, supporting or generic classes with evidence, flag mismatches between class and modeling effort, and list the questions the user must… | `[directory \| product or area description \| empty for the repository root]` |
| `/ddd-distilled:estimate-work` | Size DDD work by modeling uncertainty, integration risk and implementation cost, with team skill and domain-expert access as limits, and say which spike would reduce the uncertainty most. | `[feature list \| epic text \| path to a plan \| empty to ask]` |
| `/ddd-distilled:event-storm` | Run a timeboxed, text-based event storming session with the user for one business process and end with a timeline, glossary entries, candidate boundaries, scenarios and a spike list. | `[process or workflow to explore \| path to notes \| empty to ask]` |
| `/ddd-distilled:explain-rule` | Explain one Domain-Driven Design Distilled rule: its strength, the reason behind it, how to check it in code, an original example and the exception the book allows. | `[rule name \| section heading \| question about a rule \| empty to list the sections]` |
| `/ddd-distilled:fix` | Resolve given Domain-Driven Design Distilled findings with the smallest change per finding, run the tests after each, and report. Stops at modeling decisions. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/ddd-distilled:glossary` | Build a per-context table of domain terms from a codebase in a forked context, and report synonyms, homonyms and placeholder names with the files that show them. At most 40 lines. | `[directory \| glob \| context name \| empty for the repository root]` |
| `/ddd-distilled:map-contexts` | Reconstruct the as-found context map of a codebase in a forked context: contexts, integration edges, the relationship each edge shows in practice versus what it is called, and dishonest claims. Whole tree, not a diff… | `[directory \| glob \| empty for the repository root]` |
| `/ddd-distilled:model-first` | Produce a short model brief before writing new domain behavior: capability, subdomain, context, local terms, concept kinds, smallest patterns, boundaries and scenarios, following the Domain-Driven Design Distilled… | `[feature or behavior to build \| empty to ask]` |
| `/ddd-distilled:modeling-debt` | Record a deliberately deferred modeling imperfection with where it is, why it was deferred, what carrying it costs and what triggers repayment; or review an existing register for items whose trigger has fired. | `[what was deferred \| 'review' + path to a register \| empty to ask]` |
| `/ddd-distilled:plan` | Plan a change to existing code in small increments with the Domain-Driven Design Distilled order: subdomain, context, language, smallest pattern, boundaries, scenarios, spikes and deferred debt. | `[task description \| issue text \| path \| empty to plan the work in the current diff]` |
| `/ddd-distilled:review` | Review a diff or paths against the Domain-Driven Design Distilled rules and report ranked findings. | `[paths \| git ref \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-ddd-distilled:aggregate-reviewer` | sonnet | read-only | Reviewer of aggregate boundaries. Use proactively after edits that add children, references or collections to an aggregate, or that load object graphs, to check that each boundary follows a stated… |
| `@agent-ddd-distilled:behavior-mover` | sonnet | can edit files | Implementer that moves a business decision from a service, controller or helper into the entity, value object or policy that should own it. Use when findings show an anemic model or a service… |
| `@agent-ddd-distilled:ceremony-reviewer` | sonnet | read-only | Reviewer of tactical pattern use in both directions. Use proactively after edits that add aggregates, events, repositories, translators or value objects, or that leave complex rules in plain data… |
| `@agent-ddd-distilled:concept-reviewer` | sonnet | read-only | Reviewer of hidden domain concepts. Use proactively after edits that add boolean parameters, status codes, enums, magic strings, helper methods or repeated primitive groups that carry business… |
| `@agent-ddd-distilled:consistency-reviewer` | sonnet | read-only | Reviewer of transaction scope across aggregates. Use proactively after edits to use cases, handlers or transaction code that load or save more than one aggregate root, or that add follow-up effects… |
| `@agent-ddd-distilled:context-boundary-reviewer` | sonnet | read-only | Reviewer of bounded context ownership. Use proactively after edits that add or change shared domain types, cross-module imports, or terms used in several modules, to find context bleeding and one… |
| `@agent-ddd-distilled:domain-test-reviewer` | sonnet | read-only | Reviewer of tests of domain code. Use proactively after edits that add or change value objects, transitions, aggregates, services or translators, to check coverage per layer and whether tests read… |
| `@agent-ddd-distilled:domain-test-writer` | sonnet | can edit files | Implementer that writes tests in the ubiquitous language for value objects, transitions, orchestration and translation. Use when existing domain code has test gaps or new behavior needs tests; edits… |
| `@agent-ddd-distilled:entity-reviewer` | sonnet | read-only | Reviewer of entities. Use proactively after edits that add or change classes with identity or lifecycle, public setters on business fields, or classes that are only getters and setters, to check… |
| `@agent-ddd-distilled:event-reviewer` | sonnet | read-only | Reviewer of domain events. Use proactively after edits that add, rename or publish events, to find noise events, command-like names, vague or mirror payloads and events raised outside the model. |
| `@agent-ddd-distilled:final-gate` | sonnet | read-only | Pre-merge gate that runs the Domain-Driven Design Distilled review checklist against the working diff and returns PASS or FAIL with evidence. Use before declaring work done, committing or opening a… |
| `@agent-ddd-distilled:infrastructure-reviewer` | sonnet | read-only | Reviewer of infrastructure leaking into the model. Use proactively after edits to domain code that import frameworks, ORM, HTTP or serialization types, or that shape classes after tables or API… |
| `@agent-ddd-distilled:integration-reviewer` | sonnet | read-only | Reviewer of integration style choices. Use proactively after edits that add or change RPC calls, REST resources, queue consumers, webhooks or published events, to check coupling and failure… |
| `@agent-ddd-distilled:language-reviewer` | sonnet | read-only | Reviewer of ubiquitous language in a change. Use proactively after edits that add or rename types, methods, events, commands or tests, to find synonyms, homonyms, technical placeholders and… |
| `@agent-ddd-distilled:lead` | opus | read-only | Triage lead for Domain-Driven Design Distilled work. Use first on any non-trivial change or review to decide which specialists and skills apply, in at most five steps, and how much modeling the… |
| `@agent-ddd-distilled:relationship-reviewer` | sonnet | read-only | Reviewer of relationships between contexts and the translation at their edges. Use proactively after edits that add integrations, clients, adapters or mappers, to find silent conformism, name-only… |
| `@agent-ddd-distilled:service-reviewer` | sonnet | read-only | Reviewer of application services and controllers. Use proactively after edits to service, handler or controller code, to find business decisions that belong in the model, transport-shaped signatures… |
| `@agent-ddd-distilled:subdomain-reviewer` | sonnet | read-only | Reviewer of modeling effort against subdomain importance. Use proactively after edits that add or deepen modules, or when a change touches areas of different business weight, to find over-invested… |
| `@agent-ddd-distilled:term-renamer` | sonnet | can edit files | Implementer that applies an already decided domain term rename across code, tests, events and documentation. Use when a language review or the business has settled a term and changes were requested… |
| `@agent-ddd-distilled:translation-builder` | sonnet | can edit files | Implementer that builds a translator and its tests at one context boundary and moves foreign types behind it. Use when findings show a foreign model, payload or schema leaking into local code and… |
| `@agent-ddd-distilled:value-object-introducer` | sonnet | can edit files | Implementer that replaces a repeated primitive group with a value object in small, test-backed steps. Use when review findings or a plan call for introducing a value object for one concept. |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style ddd-distilled:context-first` | Opens every substantive answer with a context card (subdomain class, bounded context, local terms, foreign terms to translate) before any design or code. |
| `/output-style ddd-distilled:earned-pattern` | Tags every tactical pattern it introduces with the reason it earns its cost, defaults to plain code, and lists the patterns considered and rejected. |
| `/output-style ddd-distilled:mentor` | Teaches the Domain-Driven Design Distilled rule behind each decision and checks understanding. |
| `/output-style ddd-distilled:pair` | Works in small narrated steps with the user, asking before any change larger than a few lines or touching public API, a context boundary or a published name. |
| `/output-style ddd-distilled:strict-reviewer` | Answers as a ranked findings table against the Domain-Driven Design Distilled review rules, never rewrites code unless asked, and says No findings explicitly. |
| `/output-style ddd-distilled:terse` | Gives the result first in a few lines with no preamble, applying Domain-Driven Design Distilled quietly and showing failing output in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with the `lead` agent or the routing table in `/ddd-distilled:principles` when you are not sure what applies. The `lead` answers a gate question first (which business area, which context, which subdomain class, how much modeling the change earns) and then names at most five reviewers and skills. Each reviewer owns one concern and reports in its own shape; when it finds a problem that belongs to a sibling it says which one, so the hand-offs are explicit: for example the aggregate reviewer passes a request that changes several aggregates to the consistency reviewer, and the relationship reviewer passes a missing translator to the translation builder. Findings go to the implementers or to `/ddd-distilled:fix`, which make the smallest change and run the tests. `final-gate` runs the review checklist last. The manual workflows are the entry points you type; `audit`, `classify-subdomains`, `map-contexts` and `glossary` run in a forked context and return at most 40 lines, so a scan of a whole repository does not fill your conversation. Output styles change the rhythm and the report format of the entire session.

Skills are invoked as `/ddd-distilled:<name>`, agents are addressed as `ddd-distilled:<name>` (ask for them by name, mention them with `@agent-ddd-distilled:<name>`, or let Claude delegate), and styles are selected with `/output-style ddd-distilled:<name>`.

## Usage walkthroughs

### 1. Review a pull request that adds an integration

You added a carrier tracking feed and want a review before you open the pull request. Start by asking the router what applies:

```text
Use the ddd-distilled:lead agent on my current diff.
```

The `lead` reads the diff, fills in the gate line (area, context, subdomain class, each `unknown` where the repository does not say) and names at most five steps, for example the relationship reviewer, the integration reviewer, the domain test reviewer and the final gate, plus the question it needs from you: which capability makes customers choose you. Run the first one:

```text
Use the ddd-distilled:relationship-reviewer agent on src/shipping.
```

It prints an edge table with the relationship each edge shows in practice next to what it is called. A typical finding: a class named `CarrierAcl` returns the carrier's own response type and domain code branches on its status codes, so the edge is silent conformism rather than an anticorruption layer. It names the sibling that owns each remaining concern (the webhook's delivery behavior goes to the integration reviewer) and, because you want changes, the missing translator goes to the translation builder:

```text
Use the ddd-distilled:translation-builder agent to build the translator for the carrier feed in src/shipping.
```

The builder records a test baseline, lists the foreign codes and the local term for each (asking when a meaning is unclear), writes the tests first (every mapping rule plus an unknown code), then the pure translator that makes them pass, moves callers inward one at a time, and confirms by search that the carrier's names appear only inside the translator. Then review the webhook consumer and resolve what it finds:

```text
Use the ddd-distilled:integration-reviewer agent on src/shipping/webhook.ts.
/ddd-distilled:fix last review
```

The integration reviewer returns a contract sheet; a consumer that assumes each message arrives once is a finding. `fix` makes the smallest change for it (for example recording tracking events by their identifier so a redelivered webhook has no effect), runs the tests after each edit, and stops and asks if a fix would need a modeling decision. It does not commit. Finish with the gate:

```text
Use the ddd-distilled:final-gate agent on my current changes.
```

### 2. Start a feature in a new area

You need to hold a seat for ten minutes while a customer pays, in code that does not exist yet.

```text
/ddd-distilled:model-first hold a seat for 10 minutes while the customer pays
```

You get a model brief of at most 25 lines and no code: the capability, the subdomain class (marked provisional until you confirm it), the owning context and its neighbors, the local terms and any foreign terms to translate, each concept with the smallest pattern that fits and the trigger for it, the aggregate invariants, the infrastructure at the edge, two to five scenarios in business wording, and the open questions. Suppose one question is whether a hold ends when payment fails and nobody knows. Run a timeboxed session:

```text
/ddd-distilled:event-storm seat hold and release
```

The session asks, one round at a time, for events, then commands and actors, policies, hot spots and candidate boundaries, and marks anything you did not say as assumed. It ends with a timeline, glossary candidates, candidate contexts and aggregates (as hypotheses), scenarios, spikes and the debt to record. After you implement the slice, turn the accepted scenarios into tests:

```text
Use the ddd-distilled:domain-test-writer agent to write tests for the hold scenarios in src/holds.
```

The writer follows the repository's test framework, uses the domain's own constructors rather than setters, names each test as a business sentence, lists any rule it had to assume, and edits tests only.

### 3. Learn the reasoning while you work

You are onboarding someone, or yourself, and want the rule behind each choice.

```text
/output-style ddd-distilled:mentor
/ddd-distilled:explain-rule reference other aggregates by identity
```

In `mentor` mode every answer does the task first, adds a short **Why** block that names the rules used and whether each is a must or a should, and ends with one check question. `explain-rule` gives one rule in detail: its strength taken from the source's wording, the reason, a check you can run on real code, an original example and the exception the book allows. To see the cost of ceremony instead of the reasoning, switch to the other book-specific mode:

```text
/output-style ddd-distilled:earned-pattern
```

Every pattern Claude then introduces is tagged with its trigger, and each answer ends with a line listing the patterns it considered and left out.

### 4. Audit a repository you just inherited

You want to know where the pain is before changing anything.

```text
/ddd-distilled:audit src
/ddd-distilled:classify-subdomains src
/ddd-distilled:map-contexts src
/ddd-distilled:glossary src/stays
```

`audit` returns a rating (healthy, watch or hot) for each cluster with evidence and at most five hot spots, and says plainly when the core domain is unknown. `classify-subdomains` proposes core, supporting or generic for each business capability, marks every class provisional because code cannot show strategy, flags capabilities where effort and class disagree (for example a custom reminder scheduler with more classes than the scheduling core), and asks you the questions that decide the core. `map-contexts` reconstructs the context map from imports, clients, topics and shared tables and flags dishonest claims. `glossary` builds a term table per context and lists synonyms, homonyms and placeholder names with the files that show them. All four run in a fork and return at most 40 lines.

### 5. Move business rules out of a service

A `ReservationService` decides whether a deposit is required and what status a reservation moves to, while `Reservation` is getters and setters.

```text
Use the ddd-distilled:service-reviewer agent on src/stays/reservation-service.ts.
```

The service reviewer prints a decision-placement ledger (the deposit rule is currently in the service and belongs in `Reservation.confirm`; the caller-authorization check is coordination and stays) and an orchestration check per method. Because you want the change made, it hands the relocation to the behavior mover:

```text
Use the ddd-distilled:behavior-mover agent to move the deposit decision from ReservationService.confirm into the Reservation entity.
```

The mover runs the covering tests for a baseline, pins the current behavior with a service-level test if none exists, adds the rule to the entity as a method named in the business's language with its own valid and invalid cases, makes the service call it, removes the old conditional, and removes any setter that existed only for the old code. It stops and asks when a rule needs data from more than one aggregate. Check the result from the entity's side:

```text
Use the ddd-distilled:entity-reviewer agent on src/stays/reservation.ts.
```

### 6. Size the work and record a deferral under deadline pressure

A deadline is close and the team has not settled whether Sales says "booking" while Stays says "reservation".

```text
/ddd-distilled:estimate-work carrier tracking feed, surcharge rules, partner portal
/ddd-distilled:modeling-debt Booking and Reservation both name the held room; Sales has not confirmed the term
```

`estimate-work` rates each item for modeling uncertainty, integration risk and implementation cost, records team skill and expert access as limits on ceremony, gives a relative size with a confidence label instead of a single number, names the one spike that would reduce the most uncertainty, and gives time figures only if you supply a baseline. `modeling-debt` writes an entry with what is imperfect, where, why it was deferred, what carrying it costs, the event that triggers repayment and an owner, and points to the skills that repay it. It prints the entry for pasting unless you name a register file, and then it only appends.

### 7. Gate the work before you commit

Before you open the pull request, pick the lighter or the stricter check.

```text
/ddd-distilled:checklist
Use the ddd-distilled:final-gate agent on my current changes.
```

`checklist` walks the nine review questions plus two compact-checklist questions in your session, answers each with evidence, names the next skill or agent for every no, and asks you only for facts the code cannot show. `final-gate` is the isolated strict version: it returns `GATE: PASS` or `GATE: FAIL`, refuses to pass an item without evidence, does not run tests itself, and records requests that go against a rule as conflicts rather than failures.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale, the confusable-pairs table and the hand-off table are in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Purpose | `principles`, `explain-rule` |
| Primary Directive | `principles`, `adoption-fit`, `plan`, `model-first`, `lead`, `context-first`, `earned-pattern` |
| Adoption Fit and Modeling Investment | `adoption-fit`, `subdomains`, `accelerated-modeling`, `domain-tests`, `audit`, `classify-subdomains`, `estimate-work`, `subdomain-reviewer` |
| Strategic Rules | `subdomains`, `bounded-contexts`, `context-mapping`, `classify-subdomains`, `context-boundary-reviewer` |
| Context Relationship Rules | `context-mapping`, `context-translation`, `map-contexts`, `relationship-reviewer` |
| Integration Style Rules | `integration-styles`, `context-translation`, `cross-aggregate-consistency`, `domain-events`, `integration-reviewer`, `consistency-reviewer`, `event-reviewer`, `translation-builder` |
| Ubiquitous Language Rules | `ubiquitous-language`, `explicit-concepts`, `glossary`, `event-storm`, `language-reviewer`, `term-renamer`, `context-first` |
| Tactical Pattern Rules | `entities`, `value-objects`, `aggregates`, `domain-events`, `pattern-economy`, `ceremony-reviewer`, `earned-pattern` |
| Aggregate Minimalism Rules | `aggregates`, `cross-aggregate-consistency`, `aggregate-reviewer`, `consistency-reviewer` |
| Application Service Rules | `application-services`, `service-reviewer`, `behavior-mover` |
| Architecture and Infrastructure Rules | `infrastructure-isolation`, `context-translation`, `integration-styles`, `infrastructure-reviewer`, `integration-reviewer` |
| Collaboration Rules | `explicit-concepts`, `ubiquitous-language`, `concept-reviewer`, `language-reviewer`, `mentor` |
| Practicality Rules | `adoption-fit`, `pattern-economy`, `plan`, `fix`, `modeling-debt`, `ceremony-reviewer`, `pair`, `earned-pattern` |
| Accelerated Modeling and Project Rules | `accelerated-modeling`, `event-storm`, `estimate-work`, `modeling-debt`, `plan`, `adoption-fit` |
| Code Generation Rules | `model-first`, `plan`, `principles`, `bounded-contexts`, `pattern-economy`, `infrastructure-isolation`, `context-first`, `pair` |
| Review Rules | `review`, `audit`, `strict-reviewer`, `fix`, `lead`, and every reviewer |
| Testing Rules | `domain-tests`, `domain-test-reviewer`, `domain-test-writer`, `entities`, `value-objects`, `context-translation`, `application-services` |
| Review Checklist | `checklist`, `final-gate`, `review`, `principles`, `strict-reviewer` |
| Final Instruction | `principles`, `explain-rule`, `model-first`, `review`, `terse` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `ddd` | Overlap (overlap 88%, conflict 15%, complementarity 34%) | Both steer the same decisions: contexts, language, aggregates, infrastructure isolation, the core domain. Choose one as the active DDD rule set for a task. Prefer this plugin for most practical work; prefer `ddd` when the task is explicitly about Evans' original strategic vocabulary or deeper model refactoring. |
| `ddd-implementing` | Overlap (overlap 78%, conflict 20%, complementarity 52%) | This plugin is the gate and `ddd-implementing` is the implementation playbook. They complement each other only after DDD is selected and implementation detail matters. Loaded together as equals, the implementation-heavy one weakens this plugin's anti-ceremony gate. |
| `enterprise-patterns` | Overlap with tension (overlap 66%, conflict 50%, complementarity 48%) | Choose one decision layer. This plugin decides whether DDD is justified and how little ceremony to use; the other chooses among enterprise patterns for persistence, transactions, remoting and session state. Use them in sequence, not side by side. |
| `clean-architecture` | Complementary (complementarity 68%, overlap 55%, conflict 22%) | It supplies policy independence and replaceable details; this plugin supplies subdomain, context and language pressure. Use both where both scopes are active. The tension is ceremony: layers, contexts, adapters and services must be triggered by real pressure. |
| `data-intensive-apps` | Complementary (complementarity 80%, overlap 35%, conflict 10%) | Use it when the change touches source of truth, consistency, schemas, replay or event flow. It supplies the data semantics that this plugin's events and eventual consistency rely on. |

The compatibility notes also rate `refactoring`, `refactoring-guru`, `legacy-code`, `clean-code`, `philosophy-of-design`, `code-complete`, `release-it` and `pragmatic-programmer` as complementary with this book (complementarity 74 to 78%, conflict 12 to 14%). The useful sequencing: `legacy-code` first when behavior is unclear or tests are weak, then this plugin inside the controlled area; `refactoring` when behavior must stay identical while the code is reshaped toward these rules; `release-it` when timeouts, retries and overload behavior dominate an integration.

**Recommended pairing.** Keep this plugin as the one always-on DDD rule set (`inject_rules` on) for business-software work, and bring in `ddd-implementing` on demand once the gate says an area is modeled and the work is aggregate and repository implementation, and `clean-code` or `legacy-code` per task. **Avoid loading together:** `ddd` or `ddd-implementing` alongside this plugin with equal weight and `inject_rules` on in all of them, because the fuller rule sets re-open decisions this plugin's gate has closed. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score, and read `No findings` as "no listed signal was found", not as "the model is good".
- **Context cost.** Nineteen model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; install only the book plugins you need, because Claude Code's per-skill overrides do not apply to plugin skills and the whole plugin is the smallest unit you can turn off; and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce code that wears the right names while missing the task. The reviewers, the gate and the output styles add structure, but they cannot guarantee obedience.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the mistakes your agents actually make; it will usually matter more than any generic rule.
- **An agent is not the domain expert.** The whole approach depends on facts about the business: which area is core, what a word means, how long two records may disagree. Code cannot show those. Every component that needs one asks you, marks the answer provisional or assumed, and does not invent it; the result is only as good as the answers.
- **Overengineering is the book's own warning, and the toolkit can still cause it.** Used mechanically, the strategic workflows can produce maps and glossaries nobody needs. The skills carry the brake (the cheapest honest pattern, plain code for simple areas) and `earned-pattern` makes the cost visible, but you still need to judge.
- **Contested and unsettled advice.** One aggregate per transaction, eventual consistency between aggregates, event payloads that carry data versus query-back, and how strictly to keep mapping annotations off domain classes are debated (the source's rule is to keep persistence mechanics out of the model; a repository convention or your instruction may still decide). Where the source says "default", "prefer" or "usually", the skills say the same; text labeled added judgment is this plugin's own heuristic, not a rule of the source.
- **Gaps in this book's rule set.** It names repositories among the concept kinds but gives no repository rules, and it gives no step-by-step event storming method, estimation formula or modeling-debt format. Components that touch those say so; the event-storm rounds, the rating scales and the debt fields are this plugin's judgment. Event sourcing, CQRS and large-scale structure are outside it.
- **What it cannot detect.** The reviewers work by reading diffs and files. They do not execute code, cannot see runtime topology, and cannot tell which invariants the business truly requires. A boundary that looks wrong may be right for a reason only the team knows. The validator for this repository checks structure and traceability, not the quality of the advice.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule (framework-mandated base classes, mapping annotations, naming prefixes), the priority order is your instruction, then the repository, then the book.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed *Domain-Driven Design Distilled* rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Domain-Driven Design Distilled* is by Vaughn Vernon. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
