# Domain-Driven Design plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md` (the Evans-based rule set, 38 sections). A few `###` headings are cited where only a slice of a section applies.

## Design decisions

1. **Evans' original scope, not the sibling plugins' scope.** This plugin owns model discovery (knowledge crunching, breakthroughs, implicit concepts), the ubiquitous language, strategic design (bounded contexts, context relationships, distillation, large-scale structure) and the building blocks (entities, value objects, aggregates, services, repositories, factories, supple design). It deliberately stops where the sibling plugins start: `ddd-distilled` owns low-ceremony, subdomain-first and event-storming guidance; `ddd-implementing` owns implementation depth that this rule set does not contain (domain events, integration styles, application-service mechanics, CQRS). No component presents a rule as the source's when the upstream file does not support it; the plugin's own heuristics are labeled "Added judgment" and rules that exist only in the compact files are labeled "compact checklist".
2. **Strategic and tactical are separate families.** Strategic skills and agents (`ddd-bounded-contexts`, `ddd-context-relationships`, `distillation`, `ddd-choose-structure`, `ddd-context-boundary-reviewer`, `ddd-strategy-reviewer`) never discuss class design. Tactical ones (`entities`, `ddd-value-objects`, `aggregates`, `repositories`, `factories`, `ddd-domain-services`) never discuss context relationships. The two meet in `infrastructure` (own technical representations) and `ddd-context-relationships` (foreign models), which are split by who owns the other side.
3. **The brake is a first-class cluster.** The rule set warns repeatedly against ceremony ("Fake DDD", over-modeling simple subdomains). `ddd-right-sizing` and `ddd-ceremony-reviewer` carry that brake so that every other skill can assume the work is justified. `distillation` finds where the effort belongs; `ddd-right-sizing` decides how much tactical machinery a given change earns.
4. **Discovery is split from shaping.** `ddd-deep-models` is the whole-model stance (is this model shallow, is a breakthrough due). `ddd-explicit-concepts` is the local move (this flag, condition or process is a hidden concept: name it, usually as a policy or specification). `ddd-supple-design` is how the resulting API reads.
5. **Large sections are split along the seams a reader meets in code.** `Supple Design` stays one skill (nine rules that share one reviewer), `Associations and Modules` becomes one skill with two halves because both are about how the model is laid out for navigation and discovery, and `Translation at Boundaries` is divided between `infrastructure` (own persistence and transport shapes) and `ddd-context-relationships` (foreign models).
6. **Model-invocable skills are capped at 20.** There are 20. Everything that is a procedure with arguments or a decision workflow is manual; large-scale structure and analysis/model patterns are decision workflows (`ddd-choose-structure`, `ddd-pattern-fit`) because they apply rarely and always deliberately.
7. **Reviewers own one concern and have their own output shape.** The language reviewer reports a term ledger, the context-boundary reviewer a context map as found, the aggregate reviewer an invariant-to-boundary table, the lifecycle reviewer a creation-and-access trail, the domain-test reviewer a rule-to-test map.
8. **Provenance is labeled.** Rules that exist only in `mini.md` or `nano.md` are marked "compact checklist"; detection recipes, thresholds and the right-sizing tiers are marked "Added judgment".

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; What DDD Means in This Repository; Code Generation Rules; Output Expectations; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules itself. |
| `ddd-deep-models` | Model as discovered; shallow versus deep; awkwardness as a signal; when a breakthrough justifies deliberate, incremental refactoring | Knowledge Crunching and Deep Models; Breakthrough and Deeper Insight; Strategic Design; Distillation | `ddd-explicit-concepts` names one hidden concept; `ddd-deep-models` judges the whole model and the decision to restructure it. |
| `ddd-model-driven-design` | Keep model, code, tests, documents and diagrams aligned; hands-on modelers; living documentation | Model-Driven Design; Communication Artifacts | `ddd-ubiquitous-language` is about the words; this is about whether the artifacts still describe the code. |
| `ddd-ubiquitous-language` | One name per concept per context, one concept per name, domain names in methods, tests and modules, rename on insight | Ubiquitous Language | `ddd-model-driven-design` aligns artifacts; this skill owns vocabulary, synonyms and homonyms inside one context; names copied from tables or columns go to `infrastructure`. |
| `ddd-explicit-concepts` | Promote hidden constraints, policies, processes and flags to named domain concepts; specifications and their limits | Making Implicit Concepts Explicit; Explicit Concepts and Specifications; Analysis and Model Patterns; Supple Design | `ddd-deep-models` is whole-model; this is the local move for one condition, flag or process; one value's repeated validation is `ddd-value-objects`. |
| `layers` | Where rules live: domain layer, application coordination, presentation; when Smart UI is acceptable; application services | Layered Architecture and Smart UI; Application Layer | `infrastructure` is about technical representations inside the model; `layers` is about which layer decides; `ddd-right-sizing` asks whether the modeling is earned at all. |
| `infrastructure` | Infrastructure subordinate to the model; persistence and transport shapes stay out; translation to own representations | Infrastructure; Translation at Boundaries; Code Generation Rules; Scenario Walkthroughs; Testing Rules; Layered Architecture and Smart UI | `ddd-context-relationships` handles foreign models; `infrastructure` handles the system's own technical shapes, including classes and fields that take their names from tables and columns; choosing the business word that replaces them is `ddd-ubiquitous-language`. |
| `ddd-bounded-contexts` | Identify contexts, validity of a model inside one, no shared model unless governed, ownership in structure, continuous integration inside a context | Bounded Contexts; Model Integrity Patterns; Code Generation Rules | `ddd-context-relationships` chooses how two contexts relate; this defines and protects one, including who owns a package of domain types shared by several contexts. |
| `ddd-context-relationships` | Shared Kernel, Customer/Supplier, Conformist, Anticorruption Layer, Separate Ways, Open Host Service, Published Language; transformations; translation across contexts | Strategic Design; Model Integrity Patterns; Translation at Boundaries | It is about the edge between two models; `ddd-bounded-contexts` is about the inside of one. |
| `distillation` | Core domain, supporting and generic subdomains, distillation patterns, effort allocation, refactoring targets by strategic importance | Strategic Design; Distillation; Code Generation Rules; Strategic Decision Making | `ddd-right-sizing` limits tactical ceremony for a change; `distillation` locates the core and separates it from the generic mechanisms that bury it. |
| `entities` | Identity, lifecycle, protected transitions, intention-revealing behavior, no passive record | Entities | `ddd-value-objects` covers identity-less values; `aggregates` covers consistency across objects; `layers` covers rules that sit in callers. |
| `ddd-value-objects` | Immutability, valid construction, value equality, validation inside, primitive obsession | Value Objects; Code Generation Rules | `entities` is identity; this is attributes-only meaning; `ddd-explicit-concepts` names a rule over several values. |
| `aggregates` | Consistency boundaries from invariants, small size, root-only modification, identity references, transaction scope | Aggregates; Associations and Modules; Forbidden Patterns | `ddd-modules-and-associations` handles navigation and packaging; `aggregates` handles consistency. |
| `repositories` | Repositories for aggregate roots, domain-defined contracts, reconstitution, intent, no persistence leak | Repositories; Explicit Concepts and Specifications | `factories` creates new valid objects; repositories fetch and store existing ones; `infrastructure` owns ORM and table shapes inside domain classes. |
| `factories` | When creation deserves a factory, valid creation, domain creation rules, constructors for simple cases, reconstitution kept apart | Factories; Forbidden Patterns | It is about birth; `repositories` is about retrieval. |
| `ddd-domain-services` | When an operation belongs to a service, naming, staying domain-level, god services | Domain Services; Application Layer | `layers` covers application services (orchestration); this covers services that hold domain decisions. |
| `ddd-modules-and-associations` | Package structure by model meaning, context ownership in directories, association discipline | Associations and Modules; Code Generation Rules | `aggregates` decides the consistency boundary; this decides navigation and discoverability, and owns folder names such as `models`, `services` and `utils`. |
| `ddd-supple-design` | Intention-revealing interfaces, side-effect-free functions, assertions, conceptual contours, standalone classes, closure, declarative design, specification combination | Supple Design | `ddd-ubiquitous-language` is vocabulary; supple design is the shape and behavior of the API. |
| `ddd-domain-tests` | Tests in the ubiquitous language, valid and forbidden transitions, invalid construction, translation tests, infrastructure tests apart | Testing Rules; Communication Artifacts | It judges tests of the model; no other skill is about test content. |
| `ddd-right-sizing` | How much DDD a change earns; Smart UI and simple designs; fake DDD signals | What DDD Means in This Repository; Primary Directive; Forbidden Patterns; Layered Architecture and Smart UI | `distillation` finds where effort belongs; this refuses ceremony in a given change; `layers` decides where a rule lives once modeling is wanted. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Review Checklist; Output Expectations; Distillation | `audit` scans a tree; `review` judges a change. |
| `audit` | yes | no | Repository or directory health scan across strategic and tactical clusters, at most 40 lines | Review Rules; Review Checklist; Testing Rules; Distillation | `ddd-smell-hunt` is catalog driven; `audit` rates clusters. |
| `plan` | no | no | Plan a feature or model change in the rule set's code-generation order, with a strategy note | Code Generation Rules; Output Expectations; Strategic Decision Making | `ddd-scenario-walkthrough` tests a model; `plan` sequences the work. |
| `ddd-explain-rule` | no | no | Explain one rule or pattern: strength, reason, check, example, exception | Purpose; Final Instruction | It teaches; no other skill explains. |
| `checklist` | no | no | Walk the 18 review-checklist questions plus one compact-checklist item on tests, with yes/no/not-applicable and a next step for each no | Review Checklist | `ddd-final-gate` is the isolated strict gate; `checklist` is interactive. |
| `fix` | no | yes | Resolve named findings with the smallest change, ordered by the refactoring rules (removing ceremony first, as Added judgment), run tests, never commit | Refactoring Rules; Output Expectations; Forbidden Patterns | The implementers take one finding family each; `fix` resolves a mixed list in the session. |
| `ddd-smell-hunt` | no | no | Walk the forbidden-pattern families over a scope and map each hit to a treatment skill | Forbidden Patterns; Review Rules; Refactoring Rules | `audit` rates clusters; `ddd-smell-hunt` lists instances with a treatment. |
| `ddd-map-contexts` | yes | no | Reconstruct the context map as found: contexts, relationships, translation points, leaks | Bounded Contexts; Model Integrity Patterns; Translation at Boundaries; Strategic Design | `ddd-context-boundary-reviewer` reviews a diff; this scans a tree. |
| `ddd-language-audit` | yes | no | Build a term-to-meaning table per context and find synonyms, homonyms and technical stand-ins | Ubiquitous Language; Communication Artifacts; Bounded Contexts | `ddd-language-reviewer` reviews a diff; this scans a tree. |
| `ddd-scenario-walkthrough` | no | no | Walk a real scenario through the model and report where it turns procedural, awkward or leaky | Scenario Walkthroughs; Knowledge Crunching and Deep Models | It tests the model with a story; `review` tests code against rules. |
| `ddd-choose-structure` | no | no | Decide whether a large-scale structure is warranted and which, with governance and revision | Large-Scale Structure; Strategic Decision Making | `distillation` finds the core; this decides on an overall guiding structure. |
| `ddd-pattern-fit` | no | no | Decide whether an analysis pattern, design pattern or formalism fits the model without displacing domain names | Analysis and Model Patterns | `ddd-explicit-concepts` names a local concept; this vets imported patterns. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `ddd-lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Code Generation Rules; Final Instruction; Strategic Design | Only agent that does not read code for defects. |
| `ddd-final-gate` | sonnet | Runs the 18 review-checklist items plus the compact tests item on the working diff and returns PASS or FAIL | principles | Review Checklist; Output Expectations | Binary gate with evidence; reviewers return ranked findings. |
| `ddd-language-reviewer` | sonnet | Term ledger: synonyms, homonyms, technical names, DB-driven names, document drift | ubiquitous-language | Ubiquitous Language; Model-Driven Design | Output is a term ledger; `ddd-concept-reviewer` looks for missing concepts, not names. |
| `ddd-concept-reviewer` | sonnet | Hidden concepts: flags, status fields, repeated conditions, rules in comments | explicit-concepts | Making Implicit Concepts Explicit; Explicit Concepts and Specifications; Knowledge Crunching and Deep Models | Output is a concept-candidate list; `ddd-service-reviewer` places behavior that already has a name. |
| `ddd-layer-reviewer` | sonnet | Business decisions in UI, controllers, jobs or application services; Smart UI justification | layers | Layered Architecture and Smart UI; Application Layer | Output is a rule-placement ledger by layer, with findings located at the caller; `ddd-entity-reviewer` judges the entity class, `ddd-service-reviewer` decides placement inside the domain. |
| `ddd-infrastructure-reviewer` | sonnet | Persistence, transport and framework shapes leaking into the model | infrastructure | Infrastructure; Translation at Boundaries | Own technical shapes; `ddd-context-boundary-reviewer` handles foreign models. |
| `ddd-context-boundary-reviewer` | sonnet | Context map as found; foreign models, shared kernels, translation | bounded-contexts, context-relationships | Bounded Contexts; Model Integrity Patterns; Strategic Design; Translation at Boundaries | Output is a context map; it never judges class design. |
| `ddd-entity-reviewer` | sonnet | Entity class surface: setters, public fields, missing transition methods, identity, transition tests | entities | Entities | Findings are located in the entity class; `ddd-layer-reviewer` locates the same symptom at the caller that holds the rule. `ddd-value-object-reviewer` covers identity-less values. |
| `ddd-value-object-reviewer` | sonnet | Primitive obsession, mutability, repeated validation, equality | value-objects | Value Objects; Code Generation Rules | Output is a primitive inventory. |
| `ddd-aggregate-reviewer` | sonnet | Invariant-to-boundary table, root bypass, cross-aggregate references, transaction span | aggregates | Aggregates; Associations and Modules | Judges consistency boundaries; `ddd-module-reviewer` judges layout. |
| `ddd-lifecycle-reviewer` | sonnet | Creation trail and access trail for each aggregate | factories, repositories | Factories; Repositories | Output is a creation-and-access trail; `ddd-aggregate-reviewer` judges the boundary. |
| `ddd-service-reviewer` | sonnet | Behavior placement among entity, value object and domain service; god services | domain-services | Domain Services | Placement ledger inside the domain; `ddd-layer-reviewer` checks layers. |
| `ddd-module-reviewer` | sonnet | Package structure by technical artifact versus model meaning; association discipline | modules-and-associations | Associations and Modules | Output is a structure map; `ddd-context-boundary-reviewer` judges contexts. |
| `ddd-supple-design-reviewer` | sonnet | Intention-revealing names, command/query mixing, assertions, contours, closure | supple-design | Supple Design | Judges the API surface; `ddd-language-reviewer` judges vocabulary. |
| `ddd-domain-test-reviewer` | sonnet | Rule-to-test map: invariants, transitions, invalid construction, translation | domain-tests | Testing Rules | Reviews test content; `ddd-domain-test-writer` writes tests. |
| `ddd-strategy-reviewer` | sonnet | Core visibility, effort allocation, generic mechanisms burying the core, undocumented strategic decisions | distillation | Distillation; Strategic Design; Strategic Decision Making; Large-Scale Structure | Under-protected core; `ddd-ceremony-reviewer` flags over-modeling. |
| `ddd-ceremony-reviewer` | sonnet | Patterns, layers and types added without domain need | right-sizing | What DDD Means in This Repository; Forbidden Patterns; Analysis and Model Patterns | Over-modeling; `ddd-strategy-reviewer` flags the core left weak. |
| `ddd-value-object-introducer` | sonnet | Replaces primitive groups with value objects in test-backed steps | value-objects | Value Objects; Refactoring Rules | Takes primitives in; `ddd-behavior-mover` takes behavior out of services. |
| `ddd-behavior-mover` | sonnet | Moves business rules from controllers, services and jobs into entities, values or domain services | entities, domain-services | Entities; Domain Services; Refactoring Rules | Moves existing behavior; `ddd-aggregate-reshaper` changes boundaries. |
| `ddd-aggregate-reshaper` | sonnet | Redraws an aggregate boundary: root-only mutation, identity references, smaller transaction scope | aggregates | Aggregates; Refactoring Rules | Changes boundaries and transaction scope; `ddd-behavior-mover` leaves boundaries alone. |
| `ddd-translation-builder` | sonnet | Builds a translation layer at one boundary with boundary tests | context-relationships | Translation at Boundaries; Model Integrity Patterns; Refactoring Rules | Builds the edge; the reviewers only report. |
| `ddd-domain-test-writer` | sonnet | Writes ubiquitous-language tests for invariants, transitions and invalid construction | domain-tests | Testing Rules; Communication Artifacts | Writes tests only; never edits production code. |

## Output styles (6)

| Name | Observable behavior | Upstream sections | Distinct because |
| --- | --- | --- | --- |
| `mentor` | Names the rule behind each choice, ends non-trivial answers with one check question | Purpose; Output Expectations | Teaching is the only goal. |
| `strict-reviewer` | Output is a ranked findings table, no rewrites unless asked, explicit "No findings" | Review Rules; Review Checklist | Never changes code. |
| `pair` | Small steps, narrates intent, asks before changes larger than a few lines or touching public API | Refactoring Rules | Interaction rhythm. |
| `terse` | Result first, a few lines, failing output still in full | Output Expectations | Brevity rules. |
| `context-first` | Opens every implementation answer with a domain frame: context, terms, concept kind, invariants | Code Generation Rules; Ubiquitous Language | Declares the model before code. |
| `model-explorer` | Discovery conversation: domain questions, two or three candidate model shapes, a scenario walked through each, no code until a shape is chosen | Knowledge Crunching and Deep Models; Model-Driven Design; Making Implicit Concepts Explicit; Breakthrough and Deeper Insight; Scenario Walkthroughs | Produces options and open questions instead of code. |

## Confusable pairs

Model-invocable skills whose requests could overlap, and the clause that separates them (the clause is written into both descriptions).

The "shared package" trigger once appeared in three skills and three reviewers; it is now split by who owns what. Context ownership of a package holding domain types is `ddd-bounded-contexts` and `ddd-context-boundary-reviewer`; generic mechanisms that bury the core are `distillation` and `ddd-strategy-reviewer`; folder naming and layout are `ddd-modules-and-associations` and `ddd-module-reviewer`. The table-derived names trigger is split the same way between `ddd-ubiquitous-language` with `ddd-language-reviewer` (the business word) and `infrastructure` with `ddd-infrastructure-reviewer` (the table-shaped class or field); each reviewer description and body names its counterpart.

| Pair | Separator |
| --- | --- |
| `ddd-deep-models` / `ddd-explicit-concepts` | Whole model is shallow, table-shaped or contradictory (deep-models) versus one flag, condition, process or rule to name (explicit-concepts). |
| `ddd-ubiquitous-language` / `ddd-model-driven-design` | Which word to use (ubiquitous-language) versus whether documents, diagrams and code still describe the same model (model-driven-design). |
| `layers` / `infrastructure` | Which layer decides a rule (layers) versus persistence, transport or framework shapes inside the model (infrastructure). |
| `repositories` / `infrastructure` | The repository contract and access path: what it accepts, returns and hides (repositories) versus persistence or ORM shapes inside domain classes and domain names that follow tables (infrastructure). |
| `ddd-value-objects` / `ddd-explicit-concepts` | One value validated again and again, or a primitive standing for a measure (value-objects) versus a rule or condition over several values that needs a name (explicit-concepts). |
| `layers` / `ddd-right-sizing` | Which layer decides a rule once the model is wanted (layers) versus whether the change earns this much modeling at all (right-sizing). |
| `entities` / `layers` | The entity class: its setters, public fields and missing transition methods (entities) versus a rule sitting in a controller, job or application service (layers). |
| `infrastructure` / `ddd-context-relationships` | The system's own technical representations (infrastructure) versus another team's or legacy system's model (context-relationships). |
| `ddd-bounded-contexts` / `ddd-context-relationships` | Defining and protecting one context (bounded-contexts) versus choosing how two contexts relate (context-relationships). |
| `entities` / `ddd-value-objects` | Which one of two instances matters (entities) versus only the attributes matter (value-objects). |
| `entities` / `aggregates` | Behavior and transitions of one object (entities) versus consistency across several objects and transactions (aggregates). |
| `aggregates` / `ddd-modules-and-associations` | Consistency boundary (aggregates) versus navigation and package layout (modules-and-associations). |
| `factories` / `repositories` | Creating a new valid object (factories) versus loading or saving an existing one (repositories). |
| `ddd-domain-services` / `layers` | A domain-significant operation with no natural home (domain-services) versus orchestration of an application task (layers). |
| `ddd-explicit-concepts` / `ddd-supple-design` | Creating the named concept or specification (explicit-concepts) versus how its interface reads and combines (supple-design). |
| `distillation` / `ddd-right-sizing` | Locating and separating the core domain (distillation) versus deciding how much tactical machinery a change earns (right-sizing). |
| `ddd-ubiquitous-language` / `ddd-supple-design` | Vocabulary of names (ubiquitous-language) versus command/query separation, assertions and closure (supple-design). |
| `ddd-ubiquitous-language` / `infrastructure` | Choosing the business word, synonyms and homonyms inside one context (ubiquitous-language) versus classes and fields that take their names from tables and columns (infrastructure). The ubiquitous-language description sends "names copied from tables or columns" to infrastructure; the infrastructure description sends "word choice" back. |
| `ddd-ubiquitous-language` / `ddd-bounded-contexts` | One word with two meanings inside one context (ubiquitous-language) versus one word meaning different things in different contexts, or a model that must be split (bounded-contexts). |
| `ddd-bounded-contexts` / `distillation` | Who owns a package of domain types shared by several contexts (bounded-contexts) versus generic or technical mechanisms that hide and outweigh the distinctive core logic (distillation). |
| `ddd-bounded-contexts` / `ddd-modules-and-associations` | Context ownership of shared domain types (bounded-contexts) versus folder layout and the `models`, `services`, `utils` or `helpers` folders that dominate it (modules-and-associations). |
| `distillation` / `ddd-modules-and-associations` | A core buried under generic code (distillation) versus the layout of folders by technical artifact (modules-and-associations). |

## Coverage check against the upstream sections

Generated from the `## Source` sections of the components as built.

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | explain-rule, mentor, principles |
| Primary Directive | principles, right-sizing |
| What DDD Means in This Repository | ddd-ceremony-reviewer, principles, right-sizing |
| Knowledge Crunching and Deep Models | ddd-concept-reviewer, deep-models, model-explorer, scenario-walkthrough |
| Model-Driven Design | ddd-language-reviewer, model-driven-design, model-explorer |
| Breakthrough and Deeper Insight | deep-models, model-explorer |
| Making Implicit Concepts Explicit | ddd-concept-reviewer, explicit-concepts, model-explorer |
| Ubiquitous Language | context-first, language-audit, ddd-language-reviewer, ubiquitous-language |
| Communication Artifacts | ddd-domain-test-writer, domain-tests, language-audit, model-driven-design |
| Scenario Walkthroughs | infrastructure, model-explorer, scenario-walkthrough |
| Layered Architecture and Smart UI | infrastructure, ddd-layer-reviewer, layers, right-sizing |
| Bounded Contexts | bounded-contexts, ddd-context-boundary-reviewer, language-audit, map-contexts |
| Strategic Design | ddd-context-boundary-reviewer, context-relationships, deep-models, distillation, lead, map-contexts, ddd-strategy-reviewer |
| Model Integrity Patterns | bounded-contexts, ddd-context-boundary-reviewer, context-relationships, map-contexts, ddd-translation-builder |
| Distillation | audit, deep-models, distillation, review, ddd-strategy-reviewer |
| Large-Scale Structure | choose-structure, ddd-strategy-reviewer |
| Strategic Decision Making | choose-structure, distillation, plan, ddd-strategy-reviewer |
| Entities | ddd-behavior-mover, entities, ddd-entity-reviewer |
| Value Objects | ddd-value-object-introducer, ddd-value-object-reviewer, value-objects |
| Associations and Modules | ddd-aggregate-reviewer, aggregates, ddd-module-reviewer, modules-and-associations |
| Aggregates | ddd-aggregate-reshaper, ddd-aggregate-reviewer, aggregates |
| Domain Services | ddd-behavior-mover, domain-services, ddd-service-reviewer |
| Explicit Concepts and Specifications | ddd-concept-reviewer, explicit-concepts, repositories |
| Repositories | ddd-lifecycle-reviewer, repositories |
| Factories | factories, ddd-lifecycle-reviewer |
| Application Layer | domain-services, ddd-layer-reviewer, layers |
| Infrastructure | infrastructure, ddd-infrastructure-reviewer |
| Translation at Boundaries | ddd-context-boundary-reviewer, context-relationships, infrastructure, ddd-infrastructure-reviewer, map-contexts, ddd-translation-builder |
| Supple Design | explicit-concepts, supple-design, ddd-supple-design-reviewer |
| Analysis and Model Patterns | ddd-ceremony-reviewer, explicit-concepts, pattern-fit |
| Code Generation Rules | bounded-contexts, context-first, distillation, infrastructure, lead, modules-and-associations, plan, principles, ddd-value-object-reviewer, value-objects |
| Review Rules | audit, review, smell-hunt, strict-reviewer |
| Testing Rules | audit, ddd-domain-test-reviewer, ddd-domain-test-writer, domain-tests, infrastructure |
| Forbidden Patterns | aggregates, ddd-ceremony-reviewer, factories, fix, right-sizing, smell-hunt |
| Refactoring Rules | ddd-aggregate-reshaper, ddd-behavior-mover, fix, pair, smell-hunt, ddd-translation-builder, ddd-value-object-introducer |
| Output Expectations | ddd-final-gate, fix, mentor, plan, principles, review, terse |
| Review Checklist | audit, checklist, ddd-final-gate, principles, review, strict-reviewer |
| Final Instruction | explain-rule, lead, principles |

## Overlap review

Pairs that were close and how they were separated:

- `ddd-entity-reviewer` and `ddd-layer-reviewer`: both can see a passive entity whose rules sit elsewhere, so each owns one location. `ddd-entity-reviewer` reports only what is in the entity class or its tests (public setters, writable fields, missing transition methods, identity, untested transitions); `ddd-layer-reviewer` reports only what is in the caller (a controller, job or application service that holds the rule). A caller assigning an entity field is cited as evidence inside the entity finding and never raised twice. `ddd-lead` names both only when each condition is visible in the diff, and both hand the fix to `ddd-behavior-mover`.
- `ddd-layer-reviewer` and `ddd-service-reviewer`: the first reads imports and call paths to see which layer made a decision; the second reads behavior to decide whether it belongs on an entity, a value object or a domain service. An application service with branching business rules is reported once, by `ddd-layer-reviewer`, with a hand-off to `ddd-service-reviewer` for the destination.
- `ddd-language-reviewer` and `ddd-infrastructure-reviewer`: both can see a column-derived name. The infrastructure reviewer reports the table-shaped class or field; the language reviewer does not rank it, lists it under `Not checked` for the infrastructure reviewer, and supplies the business term only when an expert has one.
- `ddd-context-boundary-reviewer`, `ddd-strategy-reviewer` and `ddd-module-reviewer`: a `shared` or `common` package can raise all three. Types shared across contexts go to the first, a core hidden behind generic code to the second, folder naming to the third; each hands the other two cases on instead of ranking them.
- `ddd-infrastructure-reviewer` and `ddd-context-boundary-reviewer`: ownership of the other side decides. A table-shaped class in the domain is infrastructure; a vendor status code in the domain is a context boundary.
- `ddd-strategy-reviewer` and `ddd-ceremony-reviewer`: opposite failures. One flags a weak or buried core, the other flags machinery around simple code. They never report the same finding because a supporting subdomain is judged only by `ddd-ceremony-reviewer`.
- `ddd-concept-reviewer` and `ddd-language-reviewer`: the first finds concepts the code does not name yet; the second finds names that are wrong for concepts the code already has.
- `ddd-value-object-introducer` and `ddd-behavior-mover`: one starts from data that carries meaning, the other from behavior that sits in the wrong place. Neither changes aggregate boundaries.
- `checklist` and `ddd-final-gate`: interactive walk with next steps versus isolated PASS or FAIL with evidence.
- `review` and `ddd-lead`: `review` produces findings; `ddd-lead` only decides who should.
- `fix` and the five implementers: `fix` resolves a mixed list in-session; the implementers are delegated, each for one family of change, and report in their own formats.
