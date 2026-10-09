# Domain-Driven Design plugin: component map

This file is the plan the components were built from. It lists every component with its purpose, the upstream sections it applies, and the one-sentence reason it is not a duplicate of its nearest sibling.
Upstream sections are the `##` headings of `skills/principles/references/full.md` (the Evans-based rule set, 38 sections). A few `###` headings are cited where only a slice of a section applies.

## Design decisions

1. **Evans' original scope, not the sibling plugins' scope.** This plugin owns model discovery (knowledge crunching, breakthroughs, implicit concepts), the ubiquitous language, strategic design (bounded contexts, context relationships, distillation, large-scale structure) and the building blocks (entities, value objects, aggregates, services, repositories, factories, supple design). It deliberately stops where the sibling plugins start: `ddd-distilled` owns low-ceremony, subdomain-first and event-storming guidance; `ddd-implementing` owns implementation depth that this rule set does not contain (domain events, integration styles, application-service mechanics, CQRS). No component presents a rule as the source's when the upstream file does not support it; the plugin's own heuristics are labeled "Added judgment" and rules that exist only in the compact files are labeled "compact checklist".
2. **Strategic and tactical are separate families.** Strategic skills and agents (`bounded-contexts`, `context-relationships`, `distillation`, `choose-structure`, `context-boundary-reviewer`, `strategy-reviewer`) never discuss class design. Tactical ones (`entities`, `value-objects`, `aggregates`, `repositories`, `factories`, `domain-services`) never discuss context relationships. The two meet in `infrastructure` (own technical representations) and `context-relationships` (foreign models), which are split by who owns the other side.
3. **The brake is a first-class cluster.** The rule set warns repeatedly against ceremony ("Fake DDD", over-modeling simple subdomains). `right-sizing` and `ceremony-reviewer` carry that brake so that every other skill can assume the work is justified. `distillation` finds where the effort belongs; `right-sizing` decides how much tactical machinery a given change earns.
4. **Discovery is split from shaping.** `deep-models` is the whole-model stance (is this model shallow, is a breakthrough due). `explicit-concepts` is the local move (this flag, condition or process is a hidden concept: name it, usually as a policy or specification). `supple-design` is how the resulting API reads.
5. **Large sections are split along the seams a reader meets in code.** `Supple Design` stays one skill (nine rules that share one reviewer), `Associations and Modules` becomes one skill with two halves because both are about how the model is laid out for navigation and discovery, and `Translation at Boundaries` is divided between `infrastructure` (own persistence and transport shapes) and `context-relationships` (foreign models).
6. **Model-invocable skills are capped at 20.** There are 20. Everything that is a procedure with arguments or a decision workflow is manual; large-scale structure and analysis/model patterns are decision workflows (`choose-structure`, `pattern-fit`) because they apply rarely and always deliberately.
7. **Reviewers own one concern and have their own output shape.** The language reviewer reports a term ledger, the context-boundary reviewer a context map as found, the aggregate reviewer an invariant-to-boundary table, the lifecycle reviewer a creation-and-access trail, the domain-test reviewer a rule-to-test map.
8. **Provenance is labeled.** Rules that exist only in `mini.md` or `nano.md` are marked "compact checklist"; detection recipes, thresholds and the right-sizing tiers are marked "Added judgment".

## Skills: model-invocable (20)

| Name | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- |
| `principles` | Hub: bias, loading order, modal convention, routing table to every component, priorities, final checklist | Purpose; Primary Directive; What DDD Means in This Repository; Code Generation Rules; Output Expectations; Review Checklist; Final Instruction | It decides which other component to use; it holds no cluster rules itself. |
| `deep-models` | Model as discovered; shallow versus deep; awkwardness as a signal; when a breakthrough justifies deliberate, incremental refactoring | Knowledge Crunching and Deep Models; Breakthrough and Deeper Insight; Strategic Design; Distillation | `explicit-concepts` names one hidden concept; `deep-models` judges the whole model and the decision to restructure it. |
| `model-driven-design` | Keep model, code, tests, documents and diagrams aligned; hands-on modelers; living documentation | Model-Driven Design; Communication Artifacts | `ubiquitous-language` is about the words; this is about whether the artifacts still describe the code. |
| `ubiquitous-language` | One name per concept per context, one concept per name, domain names in methods, tests and modules, rename on insight | Ubiquitous Language | `model-driven-design` aligns artifacts; this skill owns vocabulary, synonyms and homonyms inside one context; names copied from tables or columns go to `infrastructure`. |
| `explicit-concepts` | Promote hidden constraints, policies, processes and flags to named domain concepts; specifications and their limits | Making Implicit Concepts Explicit; Explicit Concepts and Specifications; Analysis and Model Patterns; Supple Design | `deep-models` is whole-model; this is the local move for one condition, flag or process; one value's repeated validation is `value-objects`. |
| `layers` | Where rules live: domain layer, application coordination, presentation; when Smart UI is acceptable; application services | Layered Architecture and Smart UI; Application Layer | `infrastructure` is about technical representations inside the model; `layers` is about which layer decides; `right-sizing` asks whether the modeling is earned at all. |
| `infrastructure` | Infrastructure subordinate to the model; persistence and transport shapes stay out; translation to own representations | Infrastructure; Translation at Boundaries; Code Generation Rules; Scenario Walkthroughs; Testing Rules; Layered Architecture and Smart UI | `context-relationships` handles foreign models; `infrastructure` handles the system's own technical shapes, including classes and fields that take their names from tables and columns; choosing the business word that replaces them is `ubiquitous-language`. |
| `bounded-contexts` | Identify contexts, validity of a model inside one, no shared model unless governed, ownership in structure, continuous integration inside a context | Bounded Contexts; Model Integrity Patterns; Code Generation Rules | `context-relationships` chooses how two contexts relate; this defines and protects one, including who owns a package of domain types shared by several contexts. |
| `context-relationships` | Shared Kernel, Customer/Supplier, Conformist, Anticorruption Layer, Separate Ways, Open Host Service, Published Language; transformations; translation across contexts | Strategic Design; Model Integrity Patterns; Translation at Boundaries | It is about the edge between two models; `bounded-contexts` is about the inside of one. |
| `distillation` | Core domain, supporting and generic subdomains, distillation patterns, effort allocation, refactoring targets by strategic importance | Strategic Design; Distillation; Code Generation Rules; Strategic Decision Making | `right-sizing` limits tactical ceremony for a change; `distillation` locates the core and separates it from the generic mechanisms that bury it. |
| `entities` | Identity, lifecycle, protected transitions, intention-revealing behavior, no passive record | Entities | `value-objects` covers identity-less values; `aggregates` covers consistency across objects; `layers` covers rules that sit in callers. |
| `value-objects` | Immutability, valid construction, value equality, validation inside, primitive obsession | Value Objects; Code Generation Rules | `entities` is identity; this is attributes-only meaning; `explicit-concepts` names a rule over several values. |
| `aggregates` | Consistency boundaries from invariants, small size, root-only modification, identity references, transaction scope | Aggregates; Associations and Modules; Forbidden Patterns | `modules-and-associations` handles navigation and packaging; `aggregates` handles consistency. |
| `repositories` | Repositories for aggregate roots, domain-defined contracts, reconstitution, intent, no persistence leak | Repositories; Explicit Concepts and Specifications | `factories` creates new valid objects; repositories fetch and store existing ones; `infrastructure` owns ORM and table shapes inside domain classes. |
| `factories` | When creation deserves a factory, valid creation, domain creation rules, constructors for simple cases, reconstitution kept apart | Factories; Forbidden Patterns | It is about birth; `repositories` is about retrieval. |
| `domain-services` | When an operation belongs to a service, naming, staying domain-level, god services | Domain Services; Application Layer | `layers` covers application services (orchestration); this covers services that hold domain decisions. |
| `modules-and-associations` | Package structure by model meaning, context ownership in directories, association discipline | Associations and Modules; Code Generation Rules | `aggregates` decides the consistency boundary; this decides navigation and discoverability, and owns folder names such as `models`, `services` and `utils`. |
| `supple-design` | Intention-revealing interfaces, side-effect-free functions, assertions, conceptual contours, standalone classes, closure, declarative design, specification combination | Supple Design | `ubiquitous-language` is vocabulary; supple design is the shape and behavior of the API. |
| `domain-tests` | Tests in the ubiquitous language, valid and forbidden transitions, invalid construction, translation tests, infrastructure tests apart | Testing Rules; Communication Artifacts | It judges tests of the model; no other skill is about test content. |
| `right-sizing` | How much DDD a change earns; Smart UI and simple designs; fake DDD signals | What DDD Means in This Repository; Primary Directive; Forbidden Patterns; Layered Architecture and Smart UI | `distillation` finds where effort belongs; this refuses ceremony in a given change; `layers` decides where a rule lives once modeling is wanted. |

## Skills: manual workflows (12)

| Name | Fork | Edits | Purpose | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `review` | no | no | Review a diff or paths against the rules and report ranked findings | Review Rules; Review Checklist; Output Expectations; Distillation | `audit` scans a tree; `review` judges a change. |
| `audit` | yes | no | Repository or directory health scan across strategic and tactical clusters, at most 40 lines | Review Rules; Review Checklist; Testing Rules; Distillation | `smell-hunt` is catalog driven; `audit` rates clusters. |
| `plan` | no | no | Plan a feature or model change in the rule set's code-generation order, with a strategy note | Code Generation Rules; Output Expectations; Strategic Decision Making | `scenario-walkthrough` tests a model; `plan` sequences the work. |
| `explain-rule` | no | no | Explain one rule or pattern: strength, reason, check, example, exception | Purpose; Final Instruction | It teaches; no other skill explains. |
| `checklist` | no | no | Walk the 18 review-checklist questions plus one compact-checklist item on tests, with yes/no/not-applicable and a next step for each no | Review Checklist | `final-gate` is the isolated strict gate; `checklist` is interactive. |
| `fix` | no | yes | Resolve named findings with the smallest change, ordered by the refactoring rules (removing ceremony first, as Added judgment), run tests, never commit | Refactoring Rules; Output Expectations; Forbidden Patterns | The implementers take one finding family each; `fix` resolves a mixed list in the session. |
| `smell-hunt` | no | no | Walk the forbidden-pattern families over a scope and map each hit to a treatment skill | Forbidden Patterns; Review Rules; Refactoring Rules | `audit` rates clusters; `smell-hunt` lists instances with a treatment. |
| `map-contexts` | yes | no | Reconstruct the context map as found: contexts, relationships, translation points, leaks | Bounded Contexts; Model Integrity Patterns; Translation at Boundaries; Strategic Design | `context-boundary-reviewer` reviews a diff; this scans a tree. |
| `language-audit` | yes | no | Build a term-to-meaning table per context and find synonyms, homonyms and technical stand-ins | Ubiquitous Language; Communication Artifacts; Bounded Contexts | `language-reviewer` reviews a diff; this scans a tree. |
| `scenario-walkthrough` | no | no | Walk a real scenario through the model and report where it turns procedural, awkward or leaky | Scenario Walkthroughs; Knowledge Crunching and Deep Models | It tests the model with a story; `review` tests code against rules. |
| `choose-structure` | no | no | Decide whether a large-scale structure is warranted and which, with governance and revision | Large-Scale Structure; Strategic Decision Making | `distillation` finds the core; this decides on an overall guiding structure. |
| `pattern-fit` | no | no | Decide whether an analysis pattern, design pattern or formalism fits the model without displacing domain names | Analysis and Model Patterns | `explicit-concepts` names a local concept; this vets imported patterns. |

## Subagents (22)

Reviewers are read-only (`Read, Grep, Glob, Bash`, `Write` and `Edit` disallowed). Implementers also have `Edit` and `Write`.

| Name | Model | Purpose | Skills preloaded | Upstream sections | Distinct from its nearest sibling because |
| --- | --- | --- | --- | --- | --- |
| `lead` | opus | Routes a task or diff to at most five steps; does not review | principles | Code Generation Rules; Final Instruction; Strategic Design | Only agent that does not read code for defects. |
| `final-gate` | sonnet | Runs the 18 review-checklist items plus the compact tests item on the working diff and returns PASS or FAIL | principles | Review Checklist; Output Expectations | Binary gate with evidence; reviewers return ranked findings. |
| `language-reviewer` | sonnet | Term ledger: synonyms, homonyms, technical names, DB-driven names, document drift | ubiquitous-language | Ubiquitous Language; Model-Driven Design | Output is a term ledger; `concept-reviewer` looks for missing concepts, not names. |
| `concept-reviewer` | sonnet | Hidden concepts: flags, status fields, repeated conditions, rules in comments | explicit-concepts | Making Implicit Concepts Explicit; Explicit Concepts and Specifications; Knowledge Crunching and Deep Models | Output is a concept-candidate list; `service-reviewer` places behavior that already has a name. |
| `layer-reviewer` | sonnet | Business decisions in UI, controllers, jobs or application services; Smart UI justification | layers | Layered Architecture and Smart UI; Application Layer | Output is a rule-placement ledger by layer, with findings located at the caller; `entity-reviewer` judges the entity class, `service-reviewer` decides placement inside the domain. |
| `infrastructure-reviewer` | sonnet | Persistence, transport and framework shapes leaking into the model | infrastructure | Infrastructure; Translation at Boundaries | Own technical shapes; `context-boundary-reviewer` handles foreign models. |
| `context-boundary-reviewer` | sonnet | Context map as found; foreign models, shared kernels, translation | bounded-contexts, context-relationships | Bounded Contexts; Model Integrity Patterns; Strategic Design; Translation at Boundaries | Output is a context map; it never judges class design. |
| `entity-reviewer` | sonnet | Entity class surface: setters, public fields, missing transition methods, identity, transition tests | entities | Entities | Findings are located in the entity class; `layer-reviewer` locates the same symptom at the caller that holds the rule. `value-object-reviewer` covers identity-less values. |
| `value-object-reviewer` | sonnet | Primitive obsession, mutability, repeated validation, equality | value-objects | Value Objects; Code Generation Rules | Output is a primitive inventory. |
| `aggregate-reviewer` | sonnet | Invariant-to-boundary table, root bypass, cross-aggregate references, transaction span | aggregates | Aggregates; Associations and Modules | Judges consistency boundaries; `module-reviewer` judges layout. |
| `lifecycle-reviewer` | sonnet | Creation trail and access trail for each aggregate | factories, repositories | Factories; Repositories | Output is a creation-and-access trail; `aggregate-reviewer` judges the boundary. |
| `service-reviewer` | sonnet | Behavior placement among entity, value object and domain service; god services | domain-services | Domain Services | Placement ledger inside the domain; `layer-reviewer` checks layers. |
| `module-reviewer` | sonnet | Package structure by technical artifact versus model meaning; association discipline | modules-and-associations | Associations and Modules | Output is a structure map; `context-boundary-reviewer` judges contexts. |
| `supple-design-reviewer` | sonnet | Intention-revealing names, command/query mixing, assertions, contours, closure | supple-design | Supple Design | Judges the API surface; `language-reviewer` judges vocabulary. |
| `domain-test-reviewer` | sonnet | Rule-to-test map: invariants, transitions, invalid construction, translation | domain-tests | Testing Rules | Reviews test content; `domain-test-writer` writes tests. |
| `strategy-reviewer` | sonnet | Core visibility, effort allocation, generic mechanisms burying the core, undocumented strategic decisions | distillation | Distillation; Strategic Design; Strategic Decision Making; Large-Scale Structure | Under-protected core; `ceremony-reviewer` flags over-modeling. |
| `ceremony-reviewer` | sonnet | Patterns, layers and types added without domain need | right-sizing | What DDD Means in This Repository; Forbidden Patterns; Analysis and Model Patterns | Over-modeling; `strategy-reviewer` flags the core left weak. |
| `value-object-introducer` | sonnet | Replaces primitive groups with value objects in test-backed steps | value-objects | Value Objects; Refactoring Rules | Takes primitives in; `behavior-mover` takes behavior out of services. |
| `behavior-mover` | sonnet | Moves business rules from controllers, services and jobs into entities, values or domain services | entities, domain-services | Entities; Domain Services; Refactoring Rules | Moves existing behavior; `aggregate-reshaper` changes boundaries. |
| `aggregate-reshaper` | sonnet | Redraws an aggregate boundary: root-only mutation, identity references, smaller transaction scope | aggregates | Aggregates; Refactoring Rules | Changes boundaries and transaction scope; `behavior-mover` leaves boundaries alone. |
| `translation-builder` | sonnet | Builds a translation layer at one boundary with boundary tests | context-relationships | Translation at Boundaries; Model Integrity Patterns; Refactoring Rules | Builds the edge; the reviewers only report. |
| `domain-test-writer` | sonnet | Writes ubiquitous-language tests for invariants, transitions and invalid construction | domain-tests | Testing Rules; Communication Artifacts | Writes tests only; never edits production code. |

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

The "shared package" trigger once appeared in three skills and three reviewers; it is now split by who owns what. Context ownership of a package holding domain types is `bounded-contexts` and `context-boundary-reviewer`; generic mechanisms that bury the core are `distillation` and `strategy-reviewer`; folder naming and layout are `modules-and-associations` and `module-reviewer`. The table-derived names trigger is split the same way between `ubiquitous-language` with `language-reviewer` (the business word) and `infrastructure` with `infrastructure-reviewer` (the table-shaped class or field); each reviewer description and body names its counterpart.

| Pair | Separator |
| --- | --- |
| `deep-models` / `explicit-concepts` | Whole model is shallow, table-shaped or contradictory (deep-models) versus one flag, condition, process or rule to name (explicit-concepts). |
| `ubiquitous-language` / `model-driven-design` | Which word to use (ubiquitous-language) versus whether documents, diagrams and code still describe the same model (model-driven-design). |
| `layers` / `infrastructure` | Which layer decides a rule (layers) versus persistence, transport or framework shapes inside the model (infrastructure). |
| `repositories` / `infrastructure` | The repository contract and access path: what it accepts, returns and hides (repositories) versus persistence or ORM shapes inside domain classes and domain names that follow tables (infrastructure). |
| `value-objects` / `explicit-concepts` | One value validated again and again, or a primitive standing for a measure (value-objects) versus a rule or condition over several values that needs a name (explicit-concepts). |
| `layers` / `right-sizing` | Which layer decides a rule once the model is wanted (layers) versus whether the change earns this much modeling at all (right-sizing). |
| `entities` / `layers` | The entity class: its setters, public fields and missing transition methods (entities) versus a rule sitting in a controller, job or application service (layers). |
| `infrastructure` / `context-relationships` | The system's own technical representations (infrastructure) versus another team's or legacy system's model (context-relationships). |
| `bounded-contexts` / `context-relationships` | Defining and protecting one context (bounded-contexts) versus choosing how two contexts relate (context-relationships). |
| `entities` / `value-objects` | Which one of two instances matters (entities) versus only the attributes matter (value-objects). |
| `entities` / `aggregates` | Behavior and transitions of one object (entities) versus consistency across several objects and transactions (aggregates). |
| `aggregates` / `modules-and-associations` | Consistency boundary (aggregates) versus navigation and package layout (modules-and-associations). |
| `factories` / `repositories` | Creating a new valid object (factories) versus loading or saving an existing one (repositories). |
| `domain-services` / `layers` | A domain-significant operation with no natural home (domain-services) versus orchestration of an application task (layers). |
| `explicit-concepts` / `supple-design` | Creating the named concept or specification (explicit-concepts) versus how its interface reads and combines (supple-design). |
| `distillation` / `right-sizing` | Locating and separating the core domain (distillation) versus deciding how much tactical machinery a change earns (right-sizing). |
| `ubiquitous-language` / `supple-design` | Vocabulary of names (ubiquitous-language) versus command/query separation, assertions and closure (supple-design). |
| `ubiquitous-language` / `infrastructure` | Choosing the business word, synonyms and homonyms inside one context (ubiquitous-language) versus classes and fields that take their names from tables and columns (infrastructure). The ubiquitous-language description sends "names copied from tables or columns" to infrastructure; the infrastructure description sends "word choice" back. |
| `ubiquitous-language` / `bounded-contexts` | One word with two meanings inside one context (ubiquitous-language) versus one word meaning different things in different contexts, or a model that must be split (bounded-contexts). |
| `bounded-contexts` / `distillation` | Who owns a package of domain types shared by several contexts (bounded-contexts) versus generic or technical mechanisms that hide and outweigh the distinctive core logic (distillation). |
| `bounded-contexts` / `modules-and-associations` | Context ownership of shared domain types (bounded-contexts) versus folder layout and the `models`, `services`, `utils` or `helpers` folders that dominate it (modules-and-associations). |
| `distillation` / `modules-and-associations` | A core buried under generic code (distillation) versus the layout of folders by technical artifact (modules-and-associations). |

## Coverage check against the upstream sections

Generated from the `## Source` sections of the components as built.

| Upstream section | Components that apply it |
| --- | --- |
| Purpose | explain-rule, mentor, principles |
| Primary Directive | principles, right-sizing |
| What DDD Means in This Repository | ceremony-reviewer, principles, right-sizing |
| Knowledge Crunching and Deep Models | concept-reviewer, deep-models, model-explorer, scenario-walkthrough |
| Model-Driven Design | language-reviewer, model-driven-design, model-explorer |
| Breakthrough and Deeper Insight | deep-models, model-explorer |
| Making Implicit Concepts Explicit | concept-reviewer, explicit-concepts, model-explorer |
| Ubiquitous Language | context-first, language-audit, language-reviewer, ubiquitous-language |
| Communication Artifacts | domain-test-writer, domain-tests, language-audit, model-driven-design |
| Scenario Walkthroughs | infrastructure, model-explorer, scenario-walkthrough |
| Layered Architecture and Smart UI | infrastructure, layer-reviewer, layers, right-sizing |
| Bounded Contexts | bounded-contexts, context-boundary-reviewer, language-audit, map-contexts |
| Strategic Design | context-boundary-reviewer, context-relationships, deep-models, distillation, lead, map-contexts, strategy-reviewer |
| Model Integrity Patterns | bounded-contexts, context-boundary-reviewer, context-relationships, map-contexts, translation-builder |
| Distillation | audit, deep-models, distillation, review, strategy-reviewer |
| Large-Scale Structure | choose-structure, strategy-reviewer |
| Strategic Decision Making | choose-structure, distillation, plan, strategy-reviewer |
| Entities | behavior-mover, entities, entity-reviewer |
| Value Objects | value-object-introducer, value-object-reviewer, value-objects |
| Associations and Modules | aggregate-reviewer, aggregates, module-reviewer, modules-and-associations |
| Aggregates | aggregate-reshaper, aggregate-reviewer, aggregates |
| Domain Services | behavior-mover, domain-services, service-reviewer |
| Explicit Concepts and Specifications | concept-reviewer, explicit-concepts, repositories |
| Repositories | lifecycle-reviewer, repositories |
| Factories | factories, lifecycle-reviewer |
| Application Layer | domain-services, layer-reviewer, layers |
| Infrastructure | infrastructure, infrastructure-reviewer |
| Translation at Boundaries | context-boundary-reviewer, context-relationships, infrastructure, infrastructure-reviewer, map-contexts, translation-builder |
| Supple Design | explicit-concepts, supple-design, supple-design-reviewer |
| Analysis and Model Patterns | ceremony-reviewer, explicit-concepts, pattern-fit |
| Code Generation Rules | bounded-contexts, context-first, distillation, infrastructure, lead, modules-and-associations, plan, principles, value-object-reviewer, value-objects |
| Review Rules | audit, review, smell-hunt, strict-reviewer |
| Testing Rules | audit, domain-test-reviewer, domain-test-writer, domain-tests, infrastructure |
| Forbidden Patterns | aggregates, ceremony-reviewer, factories, fix, right-sizing, smell-hunt |
| Refactoring Rules | aggregate-reshaper, behavior-mover, fix, pair, smell-hunt, translation-builder, value-object-introducer |
| Output Expectations | final-gate, fix, mentor, plan, principles, review, terse |
| Review Checklist | audit, checklist, final-gate, principles, review, strict-reviewer |
| Final Instruction | explain-rule, lead, principles |

## Overlap review

Pairs that were close and how they were separated:

- `entity-reviewer` and `layer-reviewer`: both can see a passive entity whose rules sit elsewhere, so each owns one location. `entity-reviewer` reports only what is in the entity class or its tests (public setters, writable fields, missing transition methods, identity, untested transitions); `layer-reviewer` reports only what is in the caller (a controller, job or application service that holds the rule). A caller assigning an entity field is cited as evidence inside the entity finding and never raised twice. `lead` names both only when each condition is visible in the diff, and both hand the fix to `behavior-mover`.
- `layer-reviewer` and `service-reviewer`: the first reads imports and call paths to see which layer made a decision; the second reads behavior to decide whether it belongs on an entity, a value object or a domain service. An application service with branching business rules is reported once, by `layer-reviewer`, with a hand-off to `service-reviewer` for the destination.
- `language-reviewer` and `infrastructure-reviewer`: both can see a column-derived name. The infrastructure reviewer reports the table-shaped class or field; the language reviewer does not rank it, lists it under `Not checked` for the infrastructure reviewer, and supplies the business term only when an expert has one.
- `context-boundary-reviewer`, `strategy-reviewer` and `module-reviewer`: a `shared` or `common` package can raise all three. Types shared across contexts go to the first, a core hidden behind generic code to the second, folder naming to the third; each hands the other two cases on instead of ranking them.
- `infrastructure-reviewer` and `context-boundary-reviewer`: ownership of the other side decides. A table-shaped class in the domain is infrastructure; a vendor status code in the domain is a context boundary.
- `strategy-reviewer` and `ceremony-reviewer`: opposite failures. One flags a weak or buried core, the other flags machinery around simple code. They never report the same finding because a supporting subdomain is judged only by `ceremony-reviewer`.
- `concept-reviewer` and `language-reviewer`: the first finds concepts the code does not name yet; the second finds names that are wrong for concepts the code already has.
- `value-object-introducer` and `behavior-mover`: one starts from data that carries meaning, the other from behavior that sits in the wrong place. Neither changes aggregate boundaries.
- `checklist` and `final-gate`: interactive walk with next steps versus isolated PASS or FAIL with evidence.
- `review` and `lead`: `review` produces findings; `lead` only decides who should.
- `fix` and the five implementers: `fix` resolves a mixed list in-session; the implementers are delegated, each for one family of change, and report in their own formats.
