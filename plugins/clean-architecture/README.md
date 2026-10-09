# Clean Architecture

Robert C. Martin's rules for keeping business policy independent of frameworks, databases, delivery mechanisms and vendors, turned into a Claude Code toolkit. It makes Claude put rules where they belong, point every source dependency inward, hide volatile details behind interfaces the core owns, shape the folders around use cases, and price each new boundary instead of building layers by reflex.

Below the overview you will find the full component list (skills, subagents and output styles, generated from the files themselves), nine usage walkthroughs with exact commands, a map from the book's sections to the components, how it combines with the sibling plugins, and an honest section on what this cannot do.

## Overview

**The book in one paragraph.** *Clean Architecture* argues that the part of a system worth protecting is its business policy: the rules and the application's use cases. Everything else (the web framework, the database, the user interface, the message broker, the device, the vendor SDK) is a detail that plugs into that policy, and a detail should be replaceable without rewriting the policy. The mechanism is the dependency rule: source-code dependencies point inward, toward higher-level policy, so inner code never names outer code, and control flows outward only through interfaces the inner layer owns. Around that sit design principles for classes (the five usually called SOLID), principles for grouping and linking components, a view of services and deployment boundaries as one kind of boundary among several, not automatically an architectural one, the idea that a project's structure should announce what it does rather than which framework it uses, and a strong warning that a boundary is an investment with a price.

**Who this is for.** Developers using Claude Code on services and applications with real business rules and more than one moving part around them: web back ends, job processors, message consumers, command-line tools with a domain, embedded software with a testable policy core. The rules matter most on codebases where the framework or the ORM has quietly become the design.

**The bias it corrects.** Left alone, an agent builds around the grain of the tooling it can see. The web framework's request object travels into the service, the ORM entity doubles as the domain model, validation sits in the controller because that is where the input arrives, and a class named `OrderService` collects every operation on orders. The tests pass, and the design mirrors the framework: changing the database or the transport means editing business rules. This rule set reverses the picture, and it also guards against the opposite failure. Boundaries are chosen by volatility, policy importance, substitution value, testability and cost, and one whose cost exceeds the option value it preserves must not be built.

**What the toolkit adds to the raw rule set.**

- A hub skill (`/clean-architecture:principles`) that loads the compact rules first, the full rules only when needed, and routes every situation to a specific skill, agent or mode.
- One skill per rule cluster, written as decisions rather than slogans: when it applies, how to check it, what to do instead, the exceptions the source itself gives, and a tag on every rule for its strength (`MUST`, `SHOULD`, `MUST NOT`) or its origin (`Added judgment` for this plugin's own heuristics, `compact rules` for wording found only in the short rule files).
- The long `Forbidden Patterns` catalog split by what a reader sees in code: an import edge, a framework marker, a table-shaped class, a type in a signature, a fat controller, a catch-all service, a junk-drawer module.
- Workflows named for what the book teaches: `place-code`, `layer-map`, `extract-use-case`, `introduce-port`, `new-feature` and `enforce-boundaries`, next to `review`, `audit`, `plan`, `explain-rule`, `checklist` and `fix`.
- A team of read-only specialist reviewers, each with its own report shape (an import ledger, a crossing table, a port ledger, a component graph, a boundary ledger), five implementers that make small test-backed changes, a mechanical `import-scanner`, a `lead` that routes work and a `final-gate` that returns PASS or FAIL.
- Six output styles that change how a whole session behaves, including `architect` (use case and dependency arrows before code) and `boundary-budget` (every boundary priced).

**When not to use it.** Reach for a different book when the real risk lies elsewhere: local readability, naming and function shape (`clean-code`); module depth and interface simplicity (`philosophy-of-design`); domain language, bounded contexts and aggregates (the `ddd` family); timeouts, retries and overload (`release-it`); consistency and schema evolution (`data-intensive-apps`); reshaping code that has no tests (`legacy-code`, then come back). For a throwaway script, a three-endpoint CRUD tool or a prototype, the book's own cost rule says to build little structure; the skills here apply that rule and will say "do not build" when it is the answer.

## Installation

Add the marketplace once, then install the plugin:

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install clean-architecture@guided-plugins
```

To try it from a local checkout without installing:

```text
claude --plugin-dir ./plugins/clean-architecture
```

**Always-on compact rules (optional).** The plugin declares one option, `inject_rules`, a boolean that defaults to `false`. When it is `true`, a `SessionStart` hook adds the short rule set (`skills/principles/references/nano.md`) to every new, cleared or compacted session. Set it in the plugin's configuration from the `/plugin` manager. Claude Code passes the option to the hook as `CLAUDE_PLUGIN_OPTION_INJECT_RULES`; the script exits silently unless it is true. Leave it off if you load several book plugins: choose one primary rule set to be always on and bring the others in on demand.

To remove it later:

```text
/plugin uninstall clean-architecture@guided-plugins
```

## Components

The block between the markers below is generated from the component files by `scripts/gen-catalog.mjs`; do not edit it by hand.

<!-- COMPONENTS:START -->

**60 components:** 32 skills (20 Claude can load on its own, 12 you run by name), 22 subagents, 6 output styles.

### Skills Claude loads on its own

| Command | Use it when |
| --- | --- |
| `/clean-architecture:boundary-economics` | Use when deciding whether, where and how heavy a boundary should be, when a shortcut is proposed under deadline pressure, or when a compromise is unavoidable. Shaping a justified port is ports-and-gateways; code… |
| `/clean-architecture:boundary-models` | Use when a use case, entity or core service signature takes or returns a web request, ORM row, framework context or response object, or when request and response models are designed. Controller and mapper bodies are… |
| `/clean-architecture:component-coupling` | Use when two packages or modules depend on each other, a stable component depends on a volatile one, or an abstract component has no reason to exist. Covers cycles, stability and abstractness. Layer import direction is… |
| `/clean-architecture:component-grouping` | Use when deciding which classes ship, version or change together, or how to split a codebase into packages, modules or deployables. Covers cohesion and release pressure. Cycles and stability belong to… |
| `/clean-architecture:composition-root` | Use when deciding where objects are built and wired, when a use case or entity instantiates infrastructure, or when a constructor gains a dependency. Covers the main component and explicit construction. Interface… |
| `/clean-architecture:dependency-rule` | Use when judging or writing an import between your own layers, a package dependency or an interface's home layer, or when inner code reaches outward. Covers import direction. Framework markers go to… |
| `/clean-architecture:entities-and-invariants` | Use when a business rule needs a home, an entity can reach an invalid state, or domain code does I/O or reads configuration. A rule already sitting in a controller or job: the destination is here, judging the… |
| `/clean-architecture:framework-independence` | Use when framework annotations, decorators, base classes, middleware, serializers or context objects appear in domain or use case code. Covers keeping the framework at the edge. Database and ORM markers belong to… |
| `/clean-architecture:interface-adapters` | Use when writing or judging controllers, presenters, mappers or gateway implementations, including one that skips a use case or branches on business fields. Rule destination: entities-and-invariants or use-cases.… |
| `/clean-architecture:inward-refactoring` | Use only when asked to restructure existing code toward Clean Architecture in safe steps: wrapping details, replacing concrete dependencies with ports, splitting god services, ordering several findings. Where a moved… |
| `/clean-architecture:persistence-independence` | Use when the domain model is shaped by tables, when SQL, ORM mappings or gateway code carry business rules, or when rules need a real database. Web and injection markers belong to framework-independence, import… |
| `/clean-architecture:ports-and-gateways` | Use when core code builds or calls a database, mailer, payment provider, clock or ID generator directly, or when choosing which layer owns and names an interface. Construction sites are composition-root, storage leaks… |
| `/clean-architecture:principles` | Applies the Clean Architecture rule set to design and code decisions. Use for any task that creates, reviews or changes code where dependency direction, business policy independence, boundaries, use cases or… |
| `/clean-architecture:screaming-structure` | Use when creating or reorganizing folders, packages, modules or class names, or when the tree shows only controllers, services and models. Covers feature and use-case first layout, role-based naming and the default… |
| `/clean-architecture:service-and-device-edges` | Use when code crosses a process or network boundary, consumes messages, wraps a remote service, or talks to hardware. Covers humble listeners, remote calls as I/O and device interfaces. In-process controllers belong to… |
| `/clean-architecture:service-sprawl` | Use when a *Service, *Manager or *Helper class keeps growing, owns unrelated use cases, or creates, fetches, validates, persists, publishes and presents in one place. Covers splitting god services by use case. Shared… |
| `/clean-architecture:shared-code-coupling` | Use when about to remove duplication, create or grow a common, shared, utils, base or core module, or merge use cases for convenience. Covers when sharing couples different actors and when duplication is the right… |
| `/clean-architecture:solid-design` | Use when judging class and interface design: fat interfaces, substitutable implementations, extension without editing stable policy, or inverting a dependency with polymorphism. A catch-all Service class is… |
| `/clean-architecture:testing-seams` | Use when writing, placing or judging tests for entities, use cases, adapters or boundary contracts, or when business rules can only be tested with a framework, database or network. Covers core-first tests, fakes and… |
| `/clean-architecture:use-cases` | Use when writing or reshaping one application action: a use case class or function, its orchestration and the order to build a feature. Types crossing its boundary are boundary-models, rules that hold for every action… |

### Skills you run by name

| Command | What it does | Arguments |
| --- | --- | --- |
| `/clean-architecture:audit` | Scan a directory or repository for Clean Architecture health in a forked context, rate each rule cluster, and return ranked hot spots in at most 40 lines. | `[directory \| glob \| empty for the repository root]` |
| `/clean-architecture:checklist` | Walk the Clean Architecture review checklist against your current change, with yes, no, unproven or n/a for each item and a next action for each open one. | `[paths \| empty for the current diff]` |
| `/clean-architecture:enforce-boundaries` | Make the layer rules fail a test or a build: choose the mechanism with the user from tooling the project already has, add the check, freeze known violations as a baseline, and prove the check can fail. Runs the tests… | `[tool name \| layer description \| empty to detect the tooling]` |
| `/clean-architecture:explain-rule` | Explain one Clean Architecture rule: its strength (MUST, SHOULD, MUST NOT), the reason, how to check it, an original example and the rule set's own exceptions. | `[rule name \| section \| situation you are unsure about]` |
| `/clean-architecture:extract-use-case` | Move the rules and orchestration out of one handler, controller, job or service method into a use case with request and response models and ports, keeping behavior. Runs the tests, never commits. | `[file:line \| function or method name \| empty to ask]` |
| `/clean-architecture:fix` | Resolve given Clean Architecture findings with the smallest change per finding, run the tests after each, and report. Never commits. | `[finding text \| file:line \| 'last review' \| empty to ask]` |
| `/clean-architecture:introduce-port` | Replace one direct use of a volatile dependency in core code with a policy-owned port, an adapter and wiring in the composition root, plus a fake for tests. Runs the tests, never commits. | `[file:line of the direct use \| dependency name \| empty to ask]` |
| `/clean-architecture:layer-map` | Discover the layers a repository really has and the direction of the imports between them, in a forked context. Returns a ranked layer table, an import matrix and the outward edges, in at most 40 lines. | `[directory \| empty for the repository root]` |
| `/clean-architecture:new-feature` | Build a new feature in the order Clean Architecture gives: domain rule, use case, boundary interfaces, presenter and gateway contracts, adapters, wiring. Skips layers the feature does not need. Runs the tests, never… | `[feature description \| ticket text \| empty to ask]` |
| `/clean-architecture:place-code` | Classify a function, class or snippet statement by statement as business policy, orchestration, translation or infrastructure, and say which layer each part belongs in. Read-only; it reports where code belongs and… | `[file:line \| function or class name \| pasted snippet \| empty for the current diff]` |
| `/clean-architecture:plan` | Plan a non-trivial change with Clean Architecture: the use case, its models and ports, where each piece lives, the boundary decisions and the build order, without editing anything. | `[feature or change description \| ticket text \| empty to ask]` |
| `/clean-architecture:review` | Review a diff or paths against the Clean Architecture rules and report ranked findings with concrete refactoring proposals. | `[paths \| git ref \| empty for the current diff]` |

### Subagents

| Agent | Model | Access | Use it when |
| --- | --- | --- | --- |
| `@agent-clean-architecture:adapter-humility-reviewer` | sonnet | read-only | Reviewer of adapters: controllers, presenters, mappers and gateway implementations that hold business decisions or skip the use case. Use proactively after edits to routes, handlers, jobs… |
| `@agent-clean-architecture:architecture-test-writer` | sonnet | can edit files | Test author that writes the executable layer-rule check with the tooling the project already has, with a baseline for known violations. Use when the dependency rule exists only in a diagram or in… |
| `@agent-clean-architecture:boundary-cost-reviewer` | sonnet | read-only | Reviewer of boundary decisions: boundaries that are missing, overbuilt or unenforced, and compromises without a note. Use proactively after edits that add a port, layer, package, queue or service… |
| `@agent-clean-architecture:boundary-model-reviewer` | sonnet | read-only | Reviewer of the types that cross the core boundary: requests, rows, framework objects and response types in use case and entity signatures. Use proactively after edits that change a use case… |
| `@agent-clean-architecture:component-coupling-reviewer` | sonnet | read-only | Reviewer of dependencies between components: cycles, stable components depending on volatile ones, and abstract components without a reason to exist. Use proactively after edits that add imports… |
| `@agent-clean-architecture:domain-purity-reviewer` | sonnet | read-only | Reviewer of the domain layer: whether entities guard their invariants and whether domain code is free of I/O, configuration reads and clock calls. Use proactively after edits to entities, domain… |
| `@agent-clean-architecture:feature-builder` | sonnet | can edit files | Implementer that builds a new feature inside out: domain rule, use case, boundary interfaces, adapters and wiring, skipping layers the feature does not need. Use when a requirement for new behavior… |
| `@agent-clean-architecture:final-gate` | sonnet | read-only | Pre-merge gate that runs the Clean Architecture review checklist against the working diff and returns PASS or FAIL with evidence per item. Use before declaring work done, committing or opening a… |
| `@agent-clean-architecture:import-direction-reviewer` | sonnet | read-only | Reviewer of import direction between layers, including framework, ORM, driver and vendor imports in domain or application code. Use proactively after edits that add imports, declare interfaces or… |
| `@agent-clean-architecture:import-scanner` | haiku | read-only | Mechanical scanner that counts imports per directory and lists outward-looking candidates without judging them. Use when a reviewer or the lead needs a raw import census of a tree before layers or… |
| `@agent-clean-architecture:interface-contract-reviewer` | sonnet | read-only | Reviewer of interface and subtype design: fat interfaces, unsubstitutable implementations, policy edited per variant, needless extension points. Use proactively after edits that add an interface, an… |
| `@agent-clean-architecture:lead` | opus | read-only | Triage lead for Clean Architecture work. Use first on any non-trivial change or review to decide which specialist reviewers, implementers and skills apply, in what order, and how much structure is… |
| `@agent-clean-architecture:port-introducer` | sonnet | can edit files | Implementer that replaces named direct uses of volatile dependencies in core code with policy-owned ports, adapters, fakes and composition-root wiring. Use when review findings call for isolating a… |
| `@agent-clean-architecture:port-ownership-reviewer` | sonnet | read-only | Reviewer of ports and gateways: whether volatile dependencies sit behind interfaces owned by the inner layer and named by role. Use proactively after edits that call a client, SDK, clock, ID… |
| `@agent-clean-architecture:seam-test-writer` | sonnet | can edit files | Test author that writes core tests for entities and use cases with fakes for ports, plus separate adapter tests. Use when policy has no tests that run without a framework, database or network. Edits… |
| `@agent-clean-architecture:service-edge-reviewer` | sonnet | read-only | Reviewer of process, network and device edges: message listeners, webhooks, remote clients and hardware access. Use proactively after edits to consumers, scheduled triggers, service clients… |
| `@agent-clean-architecture:sprawl-reviewer` | sonnet | read-only | Reviewer of code accumulation: god services, Manager and Helper classes, and shared, common or utils modules that couple different actors. Use proactively after edits that grow a Service class, add… |
| `@agent-clean-architecture:structure-reviewer` | sonnet | read-only | Reviewer of folder layout and names: whether the tree announces use cases or frameworks, and whether grouping follows cohesion and release pressure. Use proactively after edits that add or move… |
| `@agent-clean-architecture:test-seam-reviewer` | sonnet | read-only | Reviewer of where tests sit relative to the architectural seams: rule tests that need a framework, database or network, and adapters without tests of their own. Use proactively after edits that add… |
| `@agent-clean-architecture:use-case-extractor` | sonnet | can edit files | Implementer that moves the rules and orchestration of existing handlers, controllers, jobs or service methods into use cases with request and response models and ports, test-backed. Use when review… |
| `@agent-clean-architecture:use-case-reviewer` | sonnet | read-only | Reviewer of use cases: one application action, explicit input and output, ports for external effects, orchestration only. Use proactively after edits that add or change a use case, an application… |
| `@agent-clean-architecture:wiring-reviewer` | sonnet | read-only | Reviewer of object construction and wiring: infrastructure built inside policy code, configuration reads in business code, service locators. Use proactively after edits that add a constructor… |

### Output styles (modes)

| Style | What changes |
| --- | --- |
| `/output-style clean-architecture:architect` | States the use case and a placement table before writing code, lists the arrows of every new dependency, and ends each change with a dependency direction check. |
| `/output-style clean-architecture:boundary-budget` | Justifies every proposed port, layer, package or service with a one-line cost versus option value entry and the lighter alternative, and tallies built, skipped and compromised boundaries. |
| `/output-style clean-architecture:mentor` | Teaches the Clean Architecture rule behind each decision, with its strength, and checks understanding with one question. |
| `/output-style clean-architecture:pair` | Works in small narrated steps, states intent before each move, and asks before any change larger than a few lines or touching a public name or an interface. |
| `/output-style clean-architecture:strict-reviewer` | Answers review requests as a ranked findings table with rule, evidence and minimal fix; never rewrites code unless asked; says No findings explicitly. |
| `/output-style clean-architecture:terse` | Result first, no preamble, a few lines at most unless asked, with a one-line dependency direction verdict; failing output is still shown in full. |

<!-- COMPONENTS:END -->

**How the pieces fit.** Start with the router: `clean-architecture:lead` reads a task or diff and names at most five steps. The steps are usually specialist reviewers, one per concern, each reading the code from a different side: `import-direction-reviewer` follows imports, `domain-purity-reviewer` starts inside the entities, `adapter-humility-reviewer` starts at the controllers and gateways, `boundary-model-reviewer` reads signatures, `port-ownership-reviewer` asks who owns each interface, `wiring-reviewer` finds construction sites, and so on. `boundary-cost-reviewer` is the one that may say a boundary should not exist. When you have asked for changes, the implementers act on the findings: `use-case-extractor` for rules stuck in handlers, `port-introducer` for direct use of a volatile dependency, `feature-builder` for new behavior, `seam-test-writer` and `architecture-test-writer` for the two kinds of test. The hub skill's routing table maps every situation to the right component. Last in line is `clean-architecture:final-gate`, which returns PASS or FAIL against the review checklist. The manual skills are the same work done inside your session, with you making the naming decisions; the agents are the delegated, isolated versions.

## Usage walkthroughs

### 1. Not sure where to start: let the lead route a diff

You have edited a handful of files, one of which adds a payment call to a use case, and you do not know which checks are worth running.

```text
Use the clean-architecture:lead agent on my current changes.
```

The lead reads `git status` and `git diff`, classifies the clusters the change touches and replies with at most five steps, for example the port reviewer for the new SDK call, the adapter reviewer for the edited controller, the test-seam reviewer for a rule that is only tested through the web application, and the gate at the end. It does not review anything itself, and it proposes implementers only if you asked for changes. Run the first step:

```text
Use the clean-architecture:port-ownership-reviewer agent on my current changes.
```

It returns a port ledger (volatile dependency, where it is used, which layer declares the interface, whether the name describes a role) and ranked findings. To act on the finding about the direct SDK call:

```text
/clean-architecture:introduce-port src/billing/application/charge.py:9
```

`introduce-port` first checks that the port is worth its cost, writes the operations in the use case's words, declares the port in the application layer, writes the adapter, wires it in the composition root, adds a fake, and runs the tests. It never commits.

### 2. Review the work in progress

You want a second opinion before you stage anything.

```text
/clean-architecture:review
```

With no argument it runs `git status` and `git diff`, infers the layer map, applies the rule clusters the change touches, and prints ranked findings (BLOCKER, MAJOR, MINOR, NIT) with `file:line`, the rule and its strength, the consequence and the smallest fix, plus boundary violations, refactoring proposals in order and any architectural debt that cannot be fixed now. If it finds nothing it prints `No findings` and lists what it checked. To act on the result:

```text
/clean-architecture:fix last review
```

`fix` resolves the findings one at a time in severity order, runs the project's tests after each, reverts a step that breaks them without an obvious cause, and does not commit. A finding it cannot fix safely becomes a short compromise note at the outermost layer possible (rule bent, reason, exit), and it says so.

### 3. Plan and build a feature inside out

You are adding a late-fee waiver to the returns flow of a library application.

```text
/clean-architecture:plan add a late-fee waiver for members with a medical hold when a loan is returned
```

You get a plan and no edits: the use case as a verb phrase with input, output and actor; a placement table (which rule goes to which entity, which port, which adapter); a boundary decision for each new boundary with the lighter alternative; the build order with the steps this feature does not need marked as skipped; the compromises you expect; and a test plan that starts with the core. To build it:

```text
/clean-architecture:new-feature add a late-fee waiver for members with a medical hold when a loan is returned
```

The skill builds in the order the rule set gives (domain rule, use case, boundary interfaces, presenter contract, gateway contract, adapters, wiring), runs the tests after each step, lists the imports it added to inner-layer files and confirms each points inward. For a requirement that is already clear you can hand the whole job to `clean-architecture:feature-builder` instead.

### 4. Decide where a piece of code belongs, then pull the use case out of a fat controller

A route handler loads a member, compares tiers and limits, updates points and builds the HTTP reply in one body.

```text
/clean-architecture:place-code src/api/redeem.ts:14
```

The skill cuts the handler into blocks and classifies each as business policy, orchestration, translation or infrastructure, with the layer each belongs in, which blocks are already in place, and the moves in order. It edits nothing. To perform the move:

```text
/clean-architecture:extract-use-case src/api/redeem.ts:14
```

`extract-use-case` records a test baseline (if nothing covers the handler it writes a test that pins the current behavior first, or stops to ask), names the use case with a business verb, defines the request and response from the policy and orchestration blocks only, declares a port for each volatile call, moves enterprise rules into an entity, makes the handler translate and call, wires the new objects in the composition root and re-runs the tests. Then check the result from the use case's side:

```text
Use the clean-architecture:use-case-reviewer agent on the new use case.
```

### 5. Map the layers and make the dependency rule fail the build

The repository has folders called `domain` and `infrastructure`, and nobody knows whether the first still imports the second.

```text
/clean-architecture:layer-map src
```

The map runs in a forked context and returns at most 40 lines: the layers inferred from what the directories actually import (with the name in brackets where behavior disagrees), an import matrix, up to eight outward edges with `file:line`, third-party packages found in inner layers, cycles, and a suggested next command. A raw census with no verdicts is available from `clean-architecture:import-scanner` when a reviewer needs the numbers. To turn the rule into something that fails:

```text
/clean-architecture:enforce-boundaries
```

The skill detects the tooling the project already declares, proposes a mechanism and waits for your choice, writes the check, freezes today's violations in a baseline that must only shrink, proves the check can fail by adding and removing one deliberate outward import, and wires it into the normal test command. It installs nothing. Once you have decided the mechanism, `clean-architecture:architecture-test-writer` does the same without questions.

### 6. Is this boundary worth its cost?

Someone proposes moving pricing into its own service and wrapping the system clock in a port.

```text
/clean-architecture:boundary-economics should pricing become its own service, and does the clock need a port?
```

You get one entry per boundary: its kind (source, partial, deployment, process or service), a line each for volatility, policy importance, substitution value, testability and cost, the lighter alternative, and a verdict: build, build partially, defer until a named trigger, or do not build. For the clock the lighter alternative is usually to pass today's date in as a value (this plugin's own judgment: the value keeps the call out of the core). For a session in which every boundary must be priced:

```text
/output-style clean-architecture:boundary-budget
```

After a diff that adds structure, `clean-architecture:boundary-cost-reviewer` returns a boundary ledger and a compromise ledger, and is the one reviewer that may report that a boundary is missing or overbuilt.

### 7. Audit a repository you inherited

You want to know where the architecture hurts before you change anything.

```text
/clean-architecture:audit src
```

The audit runs in a fork and returns at most 40 lines: a rating (healthy, watch or hot) for each rule cluster with evidence, and at most five hot spots ranked by the cost of the next change, each pointing to the skill that treats it. It suggests a next command, typically `/clean-architecture:layer-map src` when direction is the problem. Follow a hot spot with the matching reviewer, for example `clean-architecture:sprawl-reviewer` for a `Service` class that has grown, and then act on its findings with the owning skill.

### 8. Learn the reasoning while you work

You are onboarding a teammate, or yourself, and want the rule behind each choice.

```text
/output-style clean-architecture:mentor
/clean-architecture:explain-rule humble adapter
```

In `mentor` mode every answer does the task first, adds a short **Why** block naming the rules used with their strength, notes the trade-off when a rule bent, and ends with one check question. `explain-rule` takes one rule and gives its strength from the source's wording, the reason, a check you can run on real code, an original example and the rule set's own limits. Anything beyond the vendored rule set (for example the stability metrics from the book's component chapters) is labeled as such.

### 9. Gate the change before you commit

Before you open the pull request:

```text
Use the clean-architecture:final-gate agent on my current changes.
```

It evaluates the 13 checklist questions plus a compromise item drawn from `When Tradeoffs Are Necessary` against the diff with evidence for each, answers `GATE: PASS` or `GATE: FAIL`, lists blocking items with the smallest fix and the skill that performs it, and records any violation you explicitly requested as a conflict. It does not run tests; it asks for the output you ran. For a lighter, interactive walk with next actions use `/clean-architecture:checklist`.

## How it maps to the book

Section names below are the headings of the upstream rule set in `skills/principles/references/full.md`. The generated [docs/TRACEABILITY.md](docs/TRACEABILITY.md) lists every component that cites each section, and the validator fails if a section is left uncovered. The design rationale, including the pairs of skills that could be confused and how they are told apart, is in [docs/DESIGN.md](docs/DESIGN.md).

| Upstream section | Main components |
| --- | --- |
| Purpose | `principles`, `explain-rule`, `mentor` |
| Non-Negotiable Rules | `dependency-rule`, `entities-and-invariants`, `use-cases`, `boundary-models`, `interface-adapters`, `framework-independence`, `persistence-independence`, `screaming-structure`, `service-sprawl`, `import-direction-reviewer`, `domain-purity-reviewer`, `use-case-reviewer`, `boundary-model-reviewer` |
| Required Layer Responsibilities | `place-code`, `layer-map`, `import-scanner`; the four layer subsections by `entities-and-invariants`, `use-cases`, `interface-adapters`, `composition-root` |
| Code Generation Rules | `plan`, `new-feature`, `feature-builder`, `pair`; the six subsections by `use-cases`, `boundary-models`, `ports-and-gateways`, `composition-root`, `boundary-economics` |
| Architecture Heuristics | `audit`, `lead`; dependency direction by `dependency-rule`, `layer-map`, `architect`; policy versus detail by `place-code`, `architect`; stable core by `framework-independence`; feature-first structure by `screaming-structure`, `structure-reviewer` |
| Architecture Economics and Priority | `audit`, `boundary-economics`, `boundary-cost-reviewer`, `boundary-budget`, `plan`, `mentor` |
| Paradigm and Component Rules | `audit`, `solid-design`, `component-grouping`, `component-coupling`, `interface-contract-reviewer`, `component-coupling-reviewer`, `structure-reviewer` |
| Boundary Cost, Deployment, and Operations | `boundary-economics`, `enforce-boundaries`, `architecture-test-writer`, `shared-code-coupling`, `component-grouping`, `wiring-reviewer`, `boundary-cost-reviewer` |
| Services, Distribution, and Embedded Boundaries | `audit`, `service-and-device-edges`, `service-edge-reviewer` |
| Naming Rules | `screaming-structure`, `structure-reviewer`, `ports-and-gateways`, `service-sprawl`, `adapter-humility-reviewer` |
| Testing Rules | `audit`, `testing-seams`, `test-seam-reviewer`, `seam-test-writer` |
| Forbidden Patterns | `review`, `audit`, `strict-reviewer`; the seven families by `framework-independence`, `persistence-independence`, `boundary-models`, `interface-adapters`, `adapter-humility-reviewer`, `service-sprawl`, `sprawl-reviewer`, `shared-code-coupling`, `dependency-rule`, `ports-and-gateways` |
| Refactoring Rules | `inward-refactoring`, `fix`, `extract-use-case`, `introduce-port`, `use-case-extractor`, `port-introducer`, `pair` |
| Output Expectations | `review`, `fix`, `new-feature`, `feature-builder`, `lead`, `terse`, `strict-reviewer` |
| Review Checklist | `checklist`, `final-gate`, `review`, `audit`, `strict-reviewer` |
| Preferred Default Shapes | `new-feature`, `feature-builder`, `screaming-structure`, `use-cases`, `composition-root` |
| When Tradeoffs Are Necessary | `boundary-economics`, `boundary-cost-reviewer`, `boundary-budget`, `checklist`, `final-gate` |
| Final Instruction | `principles`, `explain-rule`, `boundary-cost-reviewer`, `final-gate` |

## Works with other plugins

The upstream compatibility notes compare every pair of books and rate them as complementary, overlapping or conflicting. The ones that matter most for this plugin:

| Plugin | Verdict | What to know |
| --- | --- | --- |
| `ddd` | Complementary, with care (conflict 36%, overlap 62%) | Clean Architecture supplies dependency direction and policy independence; DDD supplies model language, bounded contexts, invariants and aggregates. Load both only for business software where both forces are visible, and do not add both vocabularies of layers and boundaries to every feature. |
| `ddd-implementing` | Overlap (conflict 46%, overlap 66%) | Both govern application services, repositories, DTOs, adapters and the tests around them. Choose one as the primary implementation guide: this plugin when dependency direction and replaceable details are the risk, the DDD plugin when the system is deliberately DDD and contexts, aggregates and events dominate. |
| `enterprise-patterns` | Overlap (conflict 44%, overlap 64%) | Both are enterprise architecture guides, and the pattern book accepts choices (transaction script, active record) that this plugin pushes against. Keep this plugin primary and use the pattern plugin narrowly for a concrete persistence, transaction, remoting or session-state decision. |
| `philosophy-of-design` | Complementary (conflict 28%, overlap 44%) | Use this plugin to set the policy and detail boundaries, then use the design plugin to reject any port, adapter, service or layer that is only pass-through complexity. Together they are the brake on this plugin's most common failure, ceremony. |
| `legacy-code` and `refactoring` | Complementary (conflict 12%, overlap 38%) | For existing code. Characterize behavior and create the smallest seam first (`legacy-code`), sequence the safe steps (`refactoring`), and then use this plugin to decide the target shape. Prefer them whenever observable behavior must stay exactly the same. |

The remaining books are complementary when their trigger is actually present: `clean-code` (local readability, names and function shape), `code-complete` (construction-level defects and defensive checks), `data-intensive-apps` (source of truth, consistency and schema evolution), `release-it` (timeouts, retries, isolation and observability), `refactoring-guru` (smell-driven treatment), `ddd-distilled` (selective DDD) and `pragmatic-programmer` (general habits). The usual tension is boundary cost: this plugin may add ports and adapters where the other would prefer a smaller local change, unless policy independence is really at risk.

**Recommended pairing.** Keep Clean Architecture as the one always-on rule set (`inject_rules` on) for architecture-heavy services, and bring in `clean-code` for local readability, `legacy-code` or `refactoring` for existing code, or `philosophy-of-design` as the check on ceremony, on demand per task. **Avoid loading together:** `ddd-implementing` or `enterprise-patterns` at equal weight alongside this plugin with `inject_rules` on in all of them, because they compete for the same architecture layer and invite stacked ports, repositories, mappers and application services. Do not run several books' `lead` agents at once; choose one router.

## Limitations

- **Rule-based guidance is not measured quality.** The upstream project says plainly that it has no benchmarks or before-and-after data showing these rules improve outcomes. This plugin structures the advice; it does not prove it works. Treat findings as informed review comments, not as a score.
- **Context cost.** Twenty model-invocable skills put their descriptions in context on every turn. The hub's loading order (compact rules first, full rules only on demand) and the opt-in hook exist to keep this small; disable skills you do not use, and do not load many book plugins at once.
- **The model may ignore rules, or comply on the surface.** More rules can mean more ambiguity and instruction fatigue, and an agent can produce code that looks architecturally proper while missing the actual task. Layers, ports and presenters are easy to imitate. The reviewers, gate and output styles add structure; they cannot guarantee obedience.
- **Overengineering is the main risk of this book.** Applied mechanically, the rules produce an interface for every class, a use case that only forwards a call, mappers between identical types, and four layers for a three-endpoint tool. The cost rule (`boundary-economics`, the `boundary-budget` style, `boundary-cost-reviewer`) is the built-in brake, and the skills tell you when to build nothing, but you still need to judge.
- **Book-derived, not incident-derived.** The rules come from a book, not from your team's failures. Add a short, project-specific rules file for the architecture mistakes your agents actually make; it will usually matter more than any generic rule.
- **Contested advice.** How many layers a service needs, whether the ORM entity may double as the domain model in a simple application, whether duplication across use cases is better than sharing, and how far to push polymorphism are debated. Where the source says "prefer", the skills say "prefer"; text labeled "Added judgment" is this plugin's own heuristic, not a rule of the source.
- **The component chapters are thin in the vendored rules.** The upstream rule set states the component rules in three lines (group by cohesion and release pressure, avoid cycles, balance stability and abstraction). The instability and abstractness formulas and the three cohesion principles in `component-grouping` and `component-coupling` come from the book itself and are marked "Added judgment"; their numbers are search aids, never thresholds.
- **What it cannot detect.** The reviewers work by reading diffs and files with search. They do not build the project, resolve path aliases, follow reflection, generated code or dynamic imports, or execute tests, so they can miss a dependency that only exists at run time, and they cannot find performance problems, security flaws or a test that passes for the wrong reason. That is why `enforce-boundaries` exists: a check in the build is stronger evidence than any review.
- **Language and repository idiom win.** Where a language or a repository convention conflicts with a rule (a framework that dictates a controllers folder, an ORM that requires base classes, a function-oriented language with no classes), the priority order is your instruction, then the repository, then the book. The source permits a documented compromise at the outermost layer; the skills ask for the note.
- **The model may already know the book.** The value here is a short, decision-changing reminder plus structure, not secret knowledge.

## Attribution and license

This plugin is released under the MIT license; see [LICENSE](LICENSE). It is built on the MIT-licensed Clean Architecture rule sets published in [ciembor/agent-rules-books](https://github.com/ciembor/agent-rules-books) by Maciej Ciemborowicz, vendored unmodified under `skills/principles/references/`. The upstream notice is in [NOTICE.md](NOTICE.md).

It is **unofficial**. *Clean Architecture* is by Robert C. Martin. This plugin is not affiliated with, endorsed by or approved by the book's author, its publisher or the upstream rule-set maintainer. The skills, subagents and output styles are original work that paraphrase working rules and add original examples; they do not reproduce the book's text and are not a substitute for reading it.
