---
name: principles
description: "Applies the Clean Architecture rule set to design and code decisions. Use for any task that creates, reviews or changes code where dependency direction, business policy independence, boundaries, use cases or replaceable frameworks and databases matter."
---

# Clean Architecture principles

Business policy is the center of the system. Frameworks, databases, delivery mechanisms, services, devices and vendors are details that plug into it. Source dependencies point inward, boundaries are explicit and sized by what they cost, and the structure says what the application does.

## When the rules apply

- You add or change code that carries business rules which should survive a change of framework, database, UI, message broker, device or vendor.
- You review a diff or a repository for import direction, misplaced business rules, framework or database leakage, god services and layer bypass.
- You are deciding whether a port, a layer, a package split or a separate service is worth its cost.
- You reorganize folders, split a class that does too much, or move logic out of a controller, job or gateway.
- A user asks why a rule exists, where a piece of code belongs, or whether a shortcut under deadline is acceptable.
- Not for: local readability, naming and function shape (a `clean-code` plugin); module depth and interface simplicity (`philosophy-of-design`); domain language, bounded contexts and aggregates (the `ddd` plugins); timeouts, retries and overload (`release-it`); reshaping code that has no tests (characterize first with `legacy-code`, then come back).

## The bias this rule set corrects

Left alone, an agent builds around the grain of the tooling it can see. The web framework's request object travels into the service, the ORM entity doubles as the domain model, validation lives in the controller because that is where the input arrives, and a class named `OrderService` collects every operation on orders. The code works, the tests pass, and the design now mirrors the framework: replacing the database or the transport means rewriting business rules. This rule set reverses the picture. The rules and use cases sit in the middle and own the interfaces they need, the outer code implements them, and the frameworks are the replaceable part. It also guards against the opposite failure: ceremony. Boundaries are chosen by volatility, policy importance, substitution value, testability and cost, and one whose cost exceeds the option value it preserves must not be built.

## Loading the rules

1. For every design or code decision, Read `${CLAUDE_SKILL_DIR}/references/mini.md` first.
2. Read `${CLAUDE_SKILL_DIR}/references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `${CLAUDE_SKILL_DIR}/references/nano.md` is the compact always-on form; the optional SessionStart hook injects it.

Modal convention. The source says: `MUST` is binding, `SHOULD` is a strong default, `MUST NOT` is forbidden. Skills in this plugin tag each rule that way. Unqualified imperatives and "must" are `MUST`; "should" and "prefer" are `SHOULD`; "do not", "avoid" and "never" are `MUST NOT`, except where the source softens them ("where possible", "when avoidable", "when in doubt"), which the skill keeps as `SHOULD`. Text tagged "Added judgment" is this plugin's own heuristic, or a concept of the book that the vendored rule set does not state; it is not a rule of the source. "Compact rules" marks wording that exists only in `mini.md` or `nano.md`.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `clean-architecture:lead` (delegate) |
| Review the working diff or named paths | `/clean-architecture:review` |
| Health picture of a directory or repository | `/clean-architecture:audit` |
| What layers does this repository really have, and which imports point outward | `/clean-architecture:layer-map`, raw import census from `clean-architecture:import-scanner` |
| Plan a non-trivial change before editing | `/clean-architecture:plan` |
| Resolve specific findings | `/clean-architecture:fix` |
| Build a new feature from a requirement | `/clean-architecture:new-feature`, `clean-architecture:feature-builder` (delegate) |
| A handler, controller, job or service method holds the business logic | `/clean-architecture:extract-use-case`, `clean-architecture:use-case-extractor` (delegate) |
| Core code calls or constructs a database, mailer, clock or client directly | `/clean-architecture:introduce-port`, `clean-architecture:port-introducer` (delegate) |
| Where does this piece of code belong | `/clean-architecture:place-code` |
| Make the layer rules fail a build or a test | `/clean-architecture:enforce-boundaries`, `clean-architecture:architecture-test-writer` (delegate) |
| Understand one rule or its exceptions | `/clean-architecture:explain-rule` |
| Walk the review checklist while working | `/clean-architecture:checklist` |
| Strict pass or fail before commit or pull request | `clean-architecture:final-gate` (delegate) |
| An import, a package dependency or an interface's home layer | `/clean-architecture:dependency-rule`, `clean-architecture:import-direction-reviewer` |
| Business rules in the wrong place, invalid entity states, I/O in the domain | `/clean-architecture:entities-and-invariants`, `clean-architecture:domain-purity-reviewer` |
| Writing or reshaping one application action | `/clean-architecture:use-cases`, `clean-architecture:use-case-reviewer` |
| Requests, rows or framework objects in core signatures | `/clean-architecture:boundary-models`, `clean-architecture:boundary-model-reviewer` |
| Core code uses a database, mailer, payment provider, clock or ID generator directly | `/clean-architecture:ports-and-gateways`, `clean-architecture:port-ownership-reviewer` |
| Controllers, presenters, view models, mappers, gateway implementations | `/clean-architecture:interface-adapters`, `clean-architecture:adapter-humility-reviewer` |
| Framework annotations, base classes or context objects inside core code | `/clean-architecture:framework-independence`, reviewed by `clean-architecture:import-direction-reviewer` |
| Domain shaped by tables, SQL or ORM mappings carrying rules | `/clean-architecture:persistence-independence`; ORM and driver imports and markers go to `clean-architecture:import-direction-reviewer`, rules inside gateways and queries to `clean-architecture:adapter-humility-reviewer` |
| Where objects are constructed and wired | `/clean-architecture:composition-root`, `clean-architecture:wiring-reviewer` |
| Folders and names that show controllers and services instead of use cases | `/clean-architecture:screaming-structure`, `clean-architecture:structure-reviewer` |
| A Service, Manager or Helper class keeps growing | `/clean-architecture:service-sprawl`, `clean-architecture:sprawl-reviewer` |
| Removing duplication, or a common, shared or utils module | `/clean-architecture:shared-code-coupling`, `clean-architecture:sprawl-reviewer` |
| Fat interfaces, substitutability, extension without edits, inverting with polymorphism | `/clean-architecture:solid-design`, `clean-architecture:interface-contract-reviewer` |
| Which classes belong in one package or deployable | `/clean-architecture:component-grouping`, `clean-architecture:structure-reviewer` |
| Packages that depend on each other, stable code depending on volatile code | `/clean-architecture:component-coupling`, `clean-architecture:component-coupling-reviewer` |
| Is this boundary worth its cost, which kind, how to record a compromise | `/clean-architecture:boundary-economics`, `clean-architecture:boundary-cost-reviewer` |
| Message consumers, remote calls, services, firmware and device code | `/clean-architecture:service-and-device-edges`, `clean-architecture:service-edge-reviewer` |
| Where tests sit, tests that need a framework or database | `/clean-architecture:testing-seams`, `clean-architecture:test-seam-reviewer`, `clean-architecture:seam-test-writer` (delegate) |
| Reshaping existing code toward these rules without a rewrite | `/clean-architecture:inward-refactoring`, then `/clean-architecture:fix` |
| Session-long behavior: teach the reasoning | `/output-style clean-architecture:mentor` |
| Session-long behavior: ranked findings only | `/output-style clean-architecture:strict-reviewer` |
| Session-long behavior: small narrated steps | `/output-style clean-architecture:pair` |
| Session-long behavior: result first, few lines | `/output-style clean-architecture:terse` |
| Session-long behavior: state the use case, placement and arrows before code | `/output-style clean-architecture:architect` |
| Session-long behavior: justify every new boundary by cost | `/output-style clean-architecture:boundary-budget` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request, say which rule it conflicts with, and treat the result as a compromise (`/clean-architecture:boundary-economics`: outermost, documented, not normalized). Added judgment: the source says to reject a conflicting change; this plugin lets the person who owns the code decide.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep cleanup proportionate to the task. Do not widen scope to satisfy the rules, and do not add a boundary the task gives no reason for. When uncertain, choose the option that keeps business rules independent, points dependencies inward, isolates details behind boundaries, improves testability, and makes replacing frameworks, databases and delivery mechanisms easier.

## Final checklist

- [ ] Business rules are independent of frameworks.
- [ ] Use cases are independent of delivery and persistence details.
- [ ] Source dependencies point inward.
- [ ] Controllers are thin.
- [ ] Gateways are only persistence adapters.
- [ ] Entities guard the domain invariants.
- [ ] Ports are owned by the inner layers.
- [ ] Composition happens at the edge.
- [ ] Core tests run without the web framework and the database.
- [ ] The structure reflects the domain and its use cases.
- [ ] No generic utility dumping ground was added.
- [ ] No new god service was created.
- [ ] Details remain replaceable.
- [ ] Any unavoidable compromise is at the outermost layer, documented, and leaves a path to separation.

When you report the work: say briefly what changed, which tests or checks ran, which architectural debt remains and why it was not fixed now.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Clean Architecture is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Clean Architecture would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Purpose`
- `Non-Negotiable Rules`
- `Review Checklist`
- `Output Expectations`
- `Final Instruction`
- `When Tradeoffs Are Necessary`: only the compromise conditions in the last checklist item.
