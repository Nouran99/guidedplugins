# Domain-Driven Design Distilled plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md` (19 sections, 317 lines). A few `###` headings (Start with Subdomains, Define Bounded Contexts Early, Use Context Mapping, Entities, Value Objects, Aggregates, Domain Events) are cited where only a slice of a section applies.

## Design decisions

1. **The rule set is small, so components are separated by role and situation, not by rewording.** The rule set is short. The same rule appears in different components only in a different role: a rules skill (what to do), a reviewer (find violations in a diff and report them in a shape specific to that concern), an implementer (make one small change), a workflow (a procedure with arguments and an output template).
2. **The book's gate comes first.** The primary bias to correct is both extremes: no modeling where the domain is complex, and full tactical ceremony where it is simple. `adoption-fit`, `subdomains`, `pattern-economy`, `subdomain-reviewer` and `ceremony-reviewer` carry that brake, so every other component can assume the modeling effort is justified.
3. **Strategic and tactical clusters never discuss each other's concerns.** Strategic skills (`subdomains`, `bounded-contexts`, `context-mapping`, `context-translation`, `integration-styles`) never discuss class shapes. Tactical skills (`entities`, `value-objects`, `aggregates`, `cross-aggregate-consistency`, `domain-events`, `application-services`) never decide context relationships.
4. **Boundaries are split three ways along what a reader meets.** `bounded-contexts` is the inside of one context (ownership, language, code structure). `context-mapping` is the edge between two contexts (which of the nine relationships, and whether the claim is honest). `context-translation` is the code at that edge (the translator and its tests). `integration-styles` is the mechanism (RPC, REST, messaging, event payload). `infrastructure-isolation` is about technology types, not foreign meaning.
5. **Aggregates are split by situation.** `aggregates` judges the shape of one aggregate (invariant, size, root, references). `cross-aggregate-consistency` judges a use case that touches several (transaction scope, eventual consistency, graph loading).
6. **Accelerated modeling is a skill plus three workflows.** `accelerated-modeling` holds the rules (event storming, timeboxes, spikes, expert involvement, scenarios). `event-storm`, `estimate-work` and `modeling-debt` are the procedures. An agent cannot convene domain experts, so every one of them says to ask the user for expert input and never to invent business rules.
7. **Model-invocable skills are capped at 20.** There are 19. Everything that is a procedure with arguments is manual.
8. **Reviewers own one concern and have their own output shape.** The language reviewer reports a term ledger, the relationship reviewer an edge table, the aggregate reviewer an invariant-to-boundary table, the consistency reviewer a use-case transaction map, the event reviewer an event ledger, the service reviewer a decision-placement ledger.
9. **Provenance is labeled.** A numbered rule with no label comes from `references/full.md`. `(Compact checklist)` marks a rule that exists only in `mini.md` or `nano.md`. `(Added judgment)` marks this plugin's own heuristic, threshold or procedure detail. The rule set gives no repository rules and no step-by-step event storming method; where components touch those, they say so.
10. **Sequencing with the sibling DDD plugins is stated, not implied.** This plugin is the gate and the default; `ddd` (Evans vocabulary) and `ddd-implementing` (implementation depth) are for committed DDD work.

## Skills: model-invocable (19)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, provenance labels, routing table to every component, priorities, final checklist | Purpose; Primary Directive; Code Generation Rules; Review Checklist; Final Instruction | It decides which component to use and holds no cluster rules itself. |
| `adoption-fit` | Whether an area deserves DDD at all, how much, and when to reassess | Adoption Fit and Modeling Investment; Primary Directive; Practicality Rules; Accelerated Modeling and Project Rules | `pattern-economy` picks the pattern for one concept inside an area that already earned modeling; `adoption-fit` decides the area. |
| `subdomains` | Classify core, supporting, generic; put the best effort in the core | Start with Subdomains; Strategic Rules; Adoption Fit and Modeling Investment; Review Rules; Primary Directive | `adoption-fit` asks whether to model; `subdomains` ranks areas against each other by business importance. |
| `bounded-contexts` | Ownership, language and code structure of one context; same word, different meaning | Define Bounded Contexts Early; Strategic Rules; Use Context Mapping; Code Generation Rules; Review Rules; Context Relationship Rules | `context-mapping` is about the relationship between two contexts; this is the inside of one. |
| `context-mapping` | Make relationships explicit; choose among the nine; keep the claims honest | Use Context Mapping; Context Relationship Rules; Strategic Rules | `context-translation` is the code at the edge; this is the relationship decision and its honesty. |
| `context-translation` | Translators at boundaries: foreign names stop there, contracts stay separate, translation is tested | Use Context Mapping; Integration Style Rules; Architecture and Infrastructure Rules; Testing Rules; Context Relationship Rules | `infrastructure-isolation` handles technology types; this handles another model's meaning. |
| `integration-styles` | Choose RPC, REST or messaging from business coupling and failure semantics; event payload carry versus query-back | Integration Style Rules; Architecture and Infrastructure Rules | `context-translation` converts meaning at the edge; this chooses the mechanism that crosses it. |
| `ubiquitous-language` | One concept one term, one term one meaning per context, domain names over placeholders, rename on insight | Ubiquitous Language Rules; Collaboration Rules; Testing Rules; Code Generation Rules | `explicit-concepts` changes structure (flags to concepts); this changes words. |
| `explicit-concepts` | Flags, status codes, enums, booleans and helpers that carry domain decisions become named concepts | Collaboration Rules; Value Objects; Review Rules; Ubiquitous Language Rules; Accelerated Modeling and Project Rules; Practicality Rules | `value-objects` types a repeated data value with rules; this surfaces decisions and states hidden in control flow. |
| `entities` | Identity, lifecycle, guarded transitions, no unrestricted setters, anemic entities | Entities; Tactical Pattern Rules; Review Rules; Testing Rules; Practicality Rules | `value-objects` is the identity-less case; `application-services` is where decisions must not pile up. |
| `value-objects` | Immutable, self-validating values that make code read in domain language | Value Objects; Tactical Pattern Rules; Review Rules; Testing Rules; Practicality Rules | `entities` has identity; `explicit-concepts` handles decisions, not data values. |
| `aggregates` | Invariant-driven boundary, small size, root protection, references by identity | Aggregates; Tactical Pattern Rules; Aggregate Minimalism Rules; Review Rules; Testing Rules | `cross-aggregate-consistency` judges a use case across aggregates; this judges one aggregate's shape. |
| `cross-aggregate-consistency` | One transaction, one aggregate by default; eventual consistency between aggregates; no graph loading | Aggregate Minimalism Rules; Aggregates; Integration Style Rules | `aggregates` is the static shape; this is the dynamic transaction scope of a request. |
| `domain-events` | Past-tense business facts, not field-change noise or commands | Domain Events; Tactical Pattern Rules; Integration Style Rules; Ubiquitous Language Rules; Practicality Rules | `integration-styles` decides how events travel; this decides what an event is. |
| `application-services` | Thin use-case coordination; no business decisions; not shaped by transport | Application Service Rules; Review Rules; Testing Rules; Code Generation Rules; Architecture and Infrastructure Rules; Practicality Rules | `entities` hosts the decisions that leave the service; this keeps the service to orchestration. |
| `infrastructure-isolation` | Framework, persistence and transport types stay out of the model; no persistence-first modeling | Architecture and Infrastructure Rules; Code Generation Rules; Practicality Rules | `context-translation` handles foreign meaning; this handles technology. |
| `pattern-economy` | The cheapest tactical pattern that models the concept honestly; escalate as invariants and language grow | Practicality Rules; Tactical Pattern Rules; Code Generation Rules; Review Rules | `adoption-fit` decides the area; this decides the pattern inside it. |
| `accelerated-modeling` | Event storming, timeboxes, spikes, expert walkthroughs, scenarios | Accelerated Modeling and Project Rules; Adoption Fit and Modeling Investment | The three workflows run the procedure; this holds the rules and the honest limit (an agent cannot be the domain expert). |
| `domain-tests` | Tests in the ubiquitous language: value objects, transitions, orchestration only, translation | Testing Rules; Adoption Fit and Modeling Investment | It judges what tests of the model contain; no other skill is about test content. |

## Skills: manual workflows (13)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the Review Rules and report ranked findings | Review Rules; Review Checklist; Final Instruction | `audit` scans a tree for hot spots; `review` judges a change. |
| `audit` | yes | no | Repository or directory health by cluster, ranked hot spots, at most 40 lines | Review Rules; Adoption Fit and Modeling Investment | `classify-subdomains` and `map-contexts` each own one strategic question; `audit` is the cross-cluster health picture. |
| `plan` | no | no | Plan a change to existing code incrementally: fit, increments, scenarios, spikes, debt | Code Generation Rules; Practicality Rules; Accelerated Modeling and Project Rules; Primary Directive | `model-first` is the brief for new domain code; `plan` sequences evolving what exists. |
| `explain-rule` | no | no | Explain one rule: modal strength, reason, check, example, exception | Purpose; Primary Directive; Final Instruction | It teaches; no other manual skill produces explanation instead of findings. |
| `checklist` | no | no | Walk the Review Checklist interactively with a next action for each no | Review Checklist | `final-gate` is the isolated strict pass or fail; `checklist` is the in-session walk. |
| `fix` | no | yes | Resolve named findings with the smallest change, run tests, never commit | Practicality Rules; Code Generation Rules; Review Rules | It only resolves findings it is given and stops at modeling decisions. |
| `model-first` | no | no | Produce a short model brief (subdomain, context, terms, concept kinds, smallest pattern, boundaries) before writing new domain code | Code Generation Rules; Primary Directive; Adoption Fit and Modeling Investment; Accelerated Modeling and Project Rules; Final Instruction | `plan` changes what exists in increments; `model-first` is the seven-step gate for new behavior. |
| `classify-subdomains` | yes | no | Inventory capabilities, classify core, supporting, generic, flag effort mismatches | Start with Subdomains; Adoption Fit and Modeling Investment; Strategic Rules | The `subdomains` skill gives the rules during a task; this scans a codebase and asks the user to confirm what code cannot show. |
| `map-contexts` | yes | no | Reconstruct the as-found context map from code and flag dishonest relationships | Use Context Mapping; Context Relationship Rules; Define Bounded Contexts Early | The `context-mapping` skill chooses relationships for pairs; this discovers the existing ones. |
| `event-storm` | no | no | Run a text-based event storming session with the user and end with candidate contexts and a spike list | Accelerated Modeling and Project Rules; Ubiquitous Language Rules | `accelerated-modeling` holds the rules; this is the interactive procedure. |
| `glossary` | yes | no | Build a per-context term table, find synonyms and homonyms | Ubiquitous Language Rules; Define Bounded Contexts Early | `language-reviewer` reviews a diff; this scans a tree. |
| `estimate-work` | no | no | Estimate DDD work from modeling uncertainty, integration risk, implementation cost, team skill and expert access | Accelerated Modeling and Project Rules; Adoption Fit and Modeling Investment | `plan` sequences work; this sizes it and names what would reduce the uncertainty. |
| `modeling-debt` | no | optional | Record deliberately deferred modeling imperfections with a repayment trigger | Accelerated Modeling and Project Rules; Practicality Rules | `estimate-work` sizes future work; this records known imperfections already in the code. |

## Subagents (21)

Reviewers are read-only (`Read, Grep, Glob, Bash`; `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Primary Directive; Review Rules; Practicality Rules | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the Review Checklist on the working diff, PASS or FAIL with evidence | principles | Review Checklist; Practicality Rules | Binary gate with evidence; reviewers return ranked findings. |
| `subdomain-reviewer` | sonnet | Investment map: does modeling effort match subdomain importance | subdomains, adoption-fit | Start with Subdomains; Adoption Fit and Modeling Investment; Review Rules | Looks across areas; `ceremony-reviewer` looks at patterns inside one. |
| `ceremony-reviewer` | sonnet | Pattern ledger: each tactical pattern earned, unearned or missing | pattern-economy | Practicality Rules; Tactical Pattern Rules; Review Rules; Code Generation Rules | Judges both too much and too little modeling per concept. |
| `context-boundary-reviewer` | sonnet | Ownership table: types shared across contexts, same word with drift | bounded-contexts | Define Bounded Contexts Early; Strategic Rules; Review Rules; Code Generation Rules | Looks at the inside of contexts; `relationship-reviewer` looks at the edges. |
| `relationship-reviewer` | sonnet | Edge table: claimed versus actual relationship, translation present and tested | context-mapping, context-translation | Use Context Mapping; Context Relationship Rules; Integration Style Rules | Judges claims about relationships; `integration-reviewer` judges the mechanism. |
| `integration-reviewer` | sonnet | Contract sheet per integration point: style, failure semantics, separation | integration-styles | Integration Style Rules; Architecture and Infrastructure Rules | Looks at RPC, REST and messaging choices, not at what is translated. |
| `language-reviewer` | sonnet | Term ledger for a diff: synonyms, homonyms, placeholders, imported names | ubiquitous-language | Ubiquitous Language Rules; Collaboration Rules | Judges words; `concept-reviewer` judges structure. |
| `concept-reviewer` | sonnet | Hidden-concept list: primitives, flags, enums, booleans carrying rules | explicit-concepts, value-objects | Collaboration Rules; Value Objects; Review Rules | Looks for what should be a concept; `entity-reviewer` looks at existing entities. |
| `entity-reviewer` | sonnet | Entity sheet: identity, guarded transitions, setters, anemia | entities | Entities; Review Rules; Testing Rules; Practicality Rules | Judges entity behavior; `aggregate-reviewer` judges boundaries around entities. |
| `aggregate-reviewer` | sonnet | Invariant-to-boundary table for each aggregate | aggregates | Aggregates; Aggregate Minimalism Rules; Review Rules; Testing Rules | Static shape; `consistency-reviewer` looks at requests. |
| `consistency-reviewer` | sonnet | Use-case transaction map: aggregates loaded, modified and saved per request | cross-aggregate-consistency | Aggregate Minimalism Rules; Integration Style Rules | Dynamic scope of a use case; `aggregate-reviewer` looks at types. |
| `event-reviewer` | sonnet | Event ledger: name, fact, trigger, payload decision, verdict | domain-events | Domain Events; Integration Style Rules; Practicality Rules | Judges the events themselves, including payload and the carry-versus-query decision; `integration-reviewer` judges how they travel and whether consumers are safe. |
| `service-reviewer` | sonnet | Decision-placement ledger for application services and controllers | application-services | Application Service Rules; Review Rules; Testing Rules; Practicality Rules | Looks at where decisions live; `entity-reviewer` looks at what entities protect. |
| `infrastructure-reviewer` | sonnet | Dependency leak list: framework, persistence and transport types in the model | infrastructure-isolation | Architecture and Infrastructure Rules; Practicality Rules | Technology leaks; `relationship-reviewer` finds foreign-meaning leaks. |
| `domain-test-reviewer` | sonnet | Test coverage by rule layer, in which language | domain-tests | Testing Rules; Adoption Fit and Modeling Investment | Judges tests that exist; `domain-test-writer` produces them. |
| `value-object-introducer` | sonnet | Replaces a repeated primitive group with a value object in small steps | value-objects | Value Objects; Review Rules; Testing Rules | Takes one concept; `behavior-mover` moves decisions. |
| `behavior-mover` | sonnet | Moves a business decision from a service or controller into the model | entities, application-services | Entities; Application Service Rules; Review Rules | Moves existing logic; `value-object-introducer` creates a type. |
| `translation-builder` | sonnet | Builds a translator and its tests at one boundary | context-translation | Use Context Mapping; Integration Style Rules; Testing Rules; Context Relationship Rules | Edits one seam; reviews nothing. |
| `domain-test-writer` | sonnet | Writes tests in the ubiquitous language for value objects, transitions, orchestration, translation | domain-tests | Testing Rules; Adoption Fit and Modeling Investment | Writes tests only; never edits production code. |
| `term-renamer` | sonnet | Applies a decided rename of a domain term across code, tests, events and docs | ubiquitous-language | Ubiquitous Language Rules | Executes a decision; `language-reviewer` finds the problem. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Collaboration Rules; Purpose | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Review Checklist | Never changes code. |
| `pair` | Small steps, narrates intent, asks before anything larger than a few lines or touching public API | Practicality Rules; Code Generation Rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Final Instruction | Brevity rules. |
| `context-first` | Every substantive answer opens with a context card: subdomain class, bounded context, local terms, foreign terms needing translation | Code Generation Rules; Primary Directive; Ubiquitous Language Rules | The card precedes design or code; strategic position first. |
| `earned-pattern` | Every tactical pattern introduced is tagged with the reason it earns its cost; patterns considered and rejected are listed | Practicality Rules; Tactical Pattern Rules; Primary Directive | Reports on ceremony cost, not on strategic position. |

## Confusable pairs

Model-invocable skills whose descriptions could match the same request, and the clause in each description that separates them.

| Pair | Request that could match both | Separating clause |
| --- | --- | --- |
| `bounded-contexts` and `context-mapping` | "Billing and support share a Customer class" | `bounded-contexts`: one model, its ownership and its shared classes. `context-mapping`: the relationship between two contexts and which of the nine patterns it is. |
| `context-mapping` and `context-translation` | "We call the legacy ordering system" | `context-mapping`: choose and name the relationship. `context-translation`: the code that converts the foreign model, and its tests. |
| `context-translation` and `infrastructure-isolation` | "An API payload object is used in the domain" | `context-translation`: another team's or system's meaning and terms. `infrastructure-isolation`: framework, ORM or transport types. |
| `context-translation` and `integration-styles` | "Add an integration with the carrier" | `integration-styles`: choose RPC, REST or messaging. `context-translation`: translate what arrives. |
| `aggregates` and `cross-aggregate-consistency` | "This request saves an order and an invoice" | `aggregates`: the shape of one aggregate. `cross-aggregate-consistency`: how many aggregates one transaction may change. |
| `value-objects` and `explicit-concepts` | "A string and a boolean carry business meaning" | `value-objects`: repeated data values (amount, period, address) with rules. `explicit-concepts`: flags, status codes, enums and helpers that hold decisions. |
| `entities` and `application-services` | "The logic is in the service, should it be in the class" | `entities`: identity and the transitions an object protects. `application-services`: the use-case method that should only coordinate. |
| `adoption-fit`, `subdomains` and `pattern-economy` | "Should we use DDD here" | `adoption-fit`: go or no go for an area. `subdomains`: ranking areas. `pattern-economy`: which pattern for one concept. |
| `ubiquitous-language` and `explicit-concepts` | "The names `status` and `flag` are vague" | `ubiquitous-language`: the words. `explicit-concepts`: the structure behind a vague word. |
| `domain-events` and `integration-styles` | "Publish an event when the order ships" | `domain-events`: what the event is called and whether it is a fact. `integration-styles`: how it is delivered and consumed. |
| `domain-tests` and `context-translation` | "Test the carrier mapping" | `domain-tests`: what tests of the model contain. `context-translation`: the translator itself. |
| `accelerated-modeling` and `adoption-fit` | "How do we validate the model" | `accelerated-modeling`: the techniques (storming, spikes, scenarios). `adoption-fit`: whether the area needs modeling. |
| `bounded-contexts` and `ubiquitous-language` | "Customer means something different in billing and in support" | `bounded-contexts`: the same word carrying different rules in different modules, and who owns each model. `ubiquitous-language`: naming and renaming inside one context; its description sends cross-context drift to `bounded-contexts`. |
| `pattern-economy` with `value-objects`, `entities` and `aggregates` | "Should this be a value object or an entity" | `pattern-economy`: decide which pattern a concept needs, or whether it needs one. `value-objects`, `entities` and `aggregates`: shape the pattern once it is chosen; each of their descriptions sends an undecided pattern back to `pattern-economy`, and `pattern-economy` sends a chosen one to them. |
| `domain-events` and `cross-aggregate-consistency` | "When the order ships, an invoice must be created" | `domain-events`: what the event is called, whether it is a fact, what it carries. `cross-aggregate-consistency`: whether the second change is its own transaction and how long the two aggregates may disagree. |

Manual workflows and agents that sit next to each other:

| Pair | Separating fact |
| --- | --- |
| `plan` and `model-first` | `plan` is for evolving existing code in increments; `model-first` is the seven-step brief before writing new domain behavior. |
| `review`, `audit` and `checklist` | `review` judges a change; `audit` scans a tree; `checklist` walks nine questions with the user. |
| `classify-subdomains` and `subdomains` | One scans and asks; the other is the rules loaded during a task. |
| `map-contexts` and `context-mapping` | One discovers the as-found map; the other chooses relationships for a pair. |
| `map-contexts`, `relationship-reviewer` and `context-boundary-reviewer` | `map-contexts` discovers the whole as-found map from a tree in a fork and reports it as a map with ranked flags. The two reviewers judge a diff: `relationship-reviewer` the edges the change adds, `context-boundary-reviewer` the ownership of types and terms it touches. Each description names the other side. |
| `estimate-work` and `modeling-debt` | Future work sizing versus a register of known imperfections. |
| `subdomain-reviewer` and `ceremony-reviewer` | Effort across areas versus patterns inside one. |
| `context-boundary-reviewer` and `relationship-reviewer` | Inside one context versus the edge between two. |
| `aggregate-reviewer` and `consistency-reviewer` | One aggregate's shape versus a request's transaction scope. |
| `concept-reviewer` and `entity-reviewer` | Concepts that are missing versus entities that exist. |
| `ceremony-reviewer` and `concept-reviewer` | Both fire on a rule left in plain data. `ceremony-reviewer` judges the pattern cost per concept and refers hidden primitives and flags to `concept-reviewer`, which names the replacement concept. |
| `entity-reviewer` and `service-reviewer` | Both fire on an anemic entity beside a fat service. `entity-reviewer` judges the class and refers decisions found in a service to `service-reviewer`; `service-reviewer` judges where decisions sit and refers moves to `behavior-mover`. |
| `domain-test-writer`, `value-object-introducer` and `translation-builder` | All three write tests. `domain-test-writer` covers existing code with gaps; the other two write the tests of the value object or translator they introduce in the same task. |
| `behavior-mover` and `value-object-introducer` | Moving a decision versus introducing a type. |
| `domain-test-reviewer` and `domain-test-writer` | Judges tests versus writes them. |
| `lead` and `final-gate` | Plans before the work versus gates after it. |

## Hand-offs between agents

A reviewer that finds a problem outside its concern names the sibling that owns it; the README walkthroughs follow exactly these hand-offs.

| From | Finding | To |
| --- | --- | --- |
| `subdomain-reviewer` | Pattern-level over- or under-modeling inside one area; shared-model or boundary concerns | `ceremony-reviewer`; `context-boundary-reviewer` |
| `ceremony-reviewer` | Oversized aggregate; hidden concept; vague names | `aggregate-reviewer`; `concept-reviewer`; `language-reviewer` |
| `context-boundary-reviewer` | Foreign model crossing without translation or a doubtful relationship claim; term drift | `relationship-reviewer`; `language-reviewer` |
| `relationship-reviewer` | Style or failure semantics; framework or ORM types; missing translator (changes requested) | `integration-reviewer`; `infrastructure-reviewer`; `translation-builder` |
| `integration-reviewer` | Event naming, noise, payload shape or the carry-versus-query decision; aggregate exposed through a resource; translation concerns | `event-reviewer`; `aggregate-reviewer`; `relationship-reviewer` |
| `language-reviewer` | A vague word hiding a flag, status or decision; agreed rename (changes requested) | `concept-reviewer`; `term-renamer` |
| `concept-reviewer` | Repeated primitive group (changes requested); decision in a service or controller; lifecycle and transitions | `value-object-introducer`; `behavior-mover`; `entity-reviewer` |
| `entity-reviewer` | Anemic entity (changes requested); decision found in a service or controller; boundary or size | `behavior-mover`; `service-reviewer`; `aggregate-reviewer` |
| `aggregate-reviewer` | One request changes several aggregates | `consistency-reviewer` |
| `consistency-reviewer` | Follow-up event design; delivery and consumer safety | `event-reviewer`; `integration-reviewer` |
| `event-reviewer` | Delivery, duplicate and ordering handling; consumer behavior (the event reviewer keeps payload shape and the carry-versus-query decision) | `integration-reviewer` |
| `service-reviewer` | Business decision found (changes requested); framework or transport types in the domain | `behavior-mover`; `infrastructure-reviewer` |
| `infrastructure-reviewer` | The leak is another team's meaning, not technology | `relationship-reviewer` |
| `domain-test-reviewer` | Missing tests (changes requested) | `domain-test-writer` |

## Coverage check against the upstream sections

Generated from the `## Source` sections of the components; `docs/TRACEABILITY.md` is the validator's own view of the same data.

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | explain-rule, principles, mentor (style) |
| Primary Directive | adoption-fit, explain-rule, model-first, plan, principles, subdomains, lead, context-first (style), earned-pattern (style) |
| Adoption Fit and Modeling Investment | accelerated-modeling, adoption-fit, audit, classify-subdomains, domain-tests, estimate-work, model-first, subdomains, domain-test-reviewer, domain-test-writer, subdomain-reviewer |
| Strategic Rules | bounded-contexts, classify-subdomains, context-mapping, subdomains, context-boundary-reviewer |
| Context Relationship Rules | bounded-contexts, context-mapping, context-translation, map-contexts, relationship-reviewer, translation-builder |
| Integration Style Rules | context-translation, cross-aggregate-consistency, domain-events, integration-styles, consistency-reviewer, event-reviewer, integration-reviewer, relationship-reviewer, translation-builder |
| Ubiquitous Language Rules | domain-events, event-storm, explicit-concepts, glossary, ubiquitous-language, language-reviewer, term-renamer, context-first (style) |
| Tactical Pattern Rules | aggregates, domain-events, entities, pattern-economy, value-objects, ceremony-reviewer, earned-pattern (style) |
| Aggregate Minimalism Rules | aggregates, cross-aggregate-consistency, aggregate-reviewer, consistency-reviewer |
| Application Service Rules | application-services, behavior-mover, service-reviewer |
| Architecture and Infrastructure Rules | application-services, context-translation, infrastructure-isolation, integration-styles, infrastructure-reviewer, integration-reviewer |
| Collaboration Rules | explicit-concepts, ubiquitous-language, concept-reviewer, language-reviewer, mentor (style) |
| Practicality Rules | adoption-fit, application-services, domain-events, entities, explicit-concepts, fix, infrastructure-isolation, modeling-debt, pattern-economy, plan, value-objects, ceremony-reviewer, entity-reviewer, event-reviewer, final-gate, infrastructure-reviewer, lead, service-reviewer, earned-pattern (style), pair (style) |
| Accelerated Modeling and Project Rules | accelerated-modeling, adoption-fit, estimate-work, event-storm, explicit-concepts, model-first, modeling-debt, plan |
| Code Generation Rules | application-services, bounded-contexts, fix, infrastructure-isolation, model-first, pattern-economy, plan, principles, ubiquitous-language, ceremony-reviewer, context-boundary-reviewer, context-first (style), pair (style) |
| Review Rules | aggregates, application-services, audit, bounded-contexts, entities, explicit-concepts, fix, pattern-economy, review, subdomains, value-objects, aggregate-reviewer, behavior-mover, ceremony-reviewer, concept-reviewer, context-boundary-reviewer, entity-reviewer, lead, service-reviewer, subdomain-reviewer, value-object-introducer, strict-reviewer (style) |
| Testing Rules | aggregates, application-services, context-translation, domain-tests, entities, ubiquitous-language, value-objects, aggregate-reviewer, domain-test-reviewer, domain-test-writer, entity-reviewer, service-reviewer, translation-builder, value-object-introducer |
| Review Checklist | checklist, principles, review, final-gate, strict-reviewer (style) |
| Final Instruction | explain-rule, model-first, principles, review, terse (style) |
