---
name: "enterprise-patterns-principles"
description: "Applies the Patterns of Enterprise Application Architecture rule set to enterprise code. Use for any task that places business logic, persistence, transactions, locking, presentation, integration, session state or remote boundaries, or that reviews such code."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Patterns of Enterprise Application Architecture principles

Make responsibilities explicit first, then pick the smallest well-understood pattern whose forces actually fit. Do not invent architecture per feature, and do not let the framework, the ORM, the schema or the transport choose the design.

## When the rules apply

- You add or change a use case that crosses a request handler, application logic, domain rules, a database and possibly another system.
- You choose between Transaction Script, Table Module and Domain Model, or between Repository, Data Mapper, a gateway and Active Record.
- You decide who opens and commits a transaction, how concurrent edits are detected, or how session data is kept.
- You review code for domain logic in controllers or views, SQL scattered through business code, chatty remote calls, or layers that only forward calls.
- A user asks why a pattern was chosen or whether a simpler one would do.
- Not for: whether a rich domain model is justified at all, aggregates, bounded contexts and ubiquitous language (use `ddd`, `ddd-distilled` or `ddd-implementing`); dependency-direction enforcement as the main concern (use `clean-architecture`); consistency, replication and schema evolution semantics (use `data-intensive-apps`); timeouts, retries and stability patterns (use `release-it`); sequencing a behavior-preserving change (use `refactoring` or `legacy-code`).

## The bias this rule set corrects

An agent asked to build an enterprise feature reaches for whatever the framework makes easy. The controller opens the connection, the ORM entity doubles as request body, domain object and table row, a generic repository gets one method per table, and a call to another service looks like a method call. The opposite habit also appears: five layers and an interface for every class, each forwarding to the next. This rule set asks for the middle path. Name who owns presentation, workflow, domain decisions, data access, the transaction, concurrency control and integration; choose the lightest pattern that gives each an owner; escalate only when the code shows duplication, lifecycle or invariant complexity.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/enterprise-patterns/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention: an unqualified rule is a MUST, `should` and `Prefer` are SHOULD, `Do not`, `Avoid`, `must not` and `Never` are MUST NOT, unless the user explicitly overrides it. The "USE X when ..." entries in the pattern indexes are selection conditions, not duties. Skills in this plugin keep that strength. Text marked "Added judgment" is this plugin's own heuristic, and text marked "compact checklist" comes from `mini.md` or `nano.md` only; neither is a rule of the full source.

## Subagent roles

Names such as `enterprise-patterns-lead`, `enterprise-patterns-final-gate` and the `...-reviewer` roles in the routing table are subagents. The OpenCode, Gemini CLI, Cursor and Copilot builds ship them as subagents, the MCP server serves them with get_guide, and in Codex they are installed separately; the plain Agent Skills build does not include them. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `enterprise-patterns-lead` (delegate) |
| Review the working diff or named paths | `/enterprise-patterns:review` |
| Health picture of a directory, one rating per pattern family | `/enterprise-patterns:audit` |
| Hunt only the six forbidden patterns over a tree | `/enterprise-patterns:blocker-scan` |
| Who owns presentation, workflow, domain, data, transaction, concurrency and integration for a use case | `/enterprise-patterns:responsibility-map` |
| Which pattern fits this situation | `/enterprise-patterns:choose-pattern` |
| Plan a non-trivial change before editing | `/enterprise-patterns:plan` |
| Implement a new use case in the book's generation order | `/enterprise-patterns:build-feature` |
| Resolve specific findings | `/enterprise-patterns:fix` |
| Transaction Script has outgrown itself | `/enterprise-patterns:escalate-pattern`, `enterprise-patterns-logic-mover` |
| Design a coarse remote operation and its DTOs | `/enterprise-patterns:remote-contract`, `enterprise-patterns-facade-builder` |
| Understand one rule or its exceptions | `/enterprise-patterns:explain-rule` |
| Walk the review checklist while working | `/enterprise-patterns:checklist` |
| Strict pass or fail before commit or pull request | `enterprise-patterns-final-gate` (delegate) |
| Layers, dependency direction, forwarding layers | `enterprise-patterns-layering`, `enterprise-patterns-layering-reviewer` |
| Where a business decision lives; Transaction Script, Table Module, Domain Model | `enterprise-patterns-business-logic-patterns`, `enterprise-patterns-logic-placement-reviewer` |
| Application operations and orchestration | `enterprise-patterns-service-layer`, `enterprise-patterns-service-layer-reviewer` |
| Repository interface, Data Mapper, gateways, Active Record | `enterprise-patterns-repository`, `enterprise-patterns-data-mapper`, `enterprise-patterns-gateways-and-active-record`, `enterprise-patterns-persistence-reviewer`, `enterprise-patterns-persistence-extractor` |
| Who commits, one logical commit, ad hoc saves | `enterprise-patterns-transactions-and-unit-of-work`, `enterprise-patterns-transaction-reviewer` |
| Lazy loading, N+1, duplicate instances of one row | `enterprise-patterns-loading-behavior`, `enterprise-patterns-loading-reviewer` |
| Tables for associations, values, children | `enterprise-patterns-relational-mapping-structure`, `enterprise-patterns-mapping-reviewer` |
| A class hierarchy must be persisted | `enterprise-patterns-inheritance-mapping` |
| Scattered SQL strings, mapping configuration | `enterprise-patterns-query-and-metadata-mapping` |
| Two users edit the same data across requests | `enterprise-patterns-offline-locking`, `enterprise-patterns-lock-reviewer`, `enterprise-patterns-lock-adder` |
| Business rules or SQL in handlers, views, templates | `enterprise-patterns-presentation-layer`, `enterprise-patterns-presentation-reviewer` |
| Choosing a controller and view pattern | `enterprise-patterns-web-presentation-patterns` |
| Partner or vendor payloads inside the app | `enterprise-patterns-integration-boundaries`, `enterprise-patterns-integration-reviewer` |
| Chatty or object-shaped remote API | `enterprise-patterns-remote-boundaries`, `enterprise-patterns-remote-api-reviewer` |
| Cookies, server sessions, session tables | `enterprise-patterns-session-state`, `enterprise-patterns-session-state-reviewer` |
| Money, repeated null checks, registries, supertypes | `enterprise-patterns-base-patterns`, `enterprise-patterns-base-pattern-reviewer` |
| Where each behavior should be tested | `enterprise-patterns-testing-by-responsibility`, `enterprise-patterns-test-alignment-reviewer`, `enterprise-patterns-test-writer` |
| Session-long behavior: teach the reasoning | `/enterprise-patterns:mode-mentor` |
| Session-long behavior: ranked findings only | `/enterprise-patterns:mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `/enterprise-patterns:mode-pair` |
| Session-long behavior: result first, few lines | `/enterprise-patterns:mode-terse` |
| Session-long behavior: forces and smallest pattern before any design | `/enterprise-patterns:mode-force-first` |
| Session-long behavior: request path across layers before any change | `/enterprise-patterns:mode-request-path` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep cleanup within the task. Do not widen scope to satisfy the rules. If the project is committed to a domain-driven design, that plugin arbitrates domain-model decisions and this one is limited to a single infrastructure decision at a time.

## Final checklist

- [ ] The business logic pattern matches the actual complexity, not habit or framework shape.
- [ ] Presentation, workflow, domain logic and persistence have distinct owners.
- [ ] Transaction ownership is explicit and sits in the application workflow.
- [ ] Repositories and gateways are shaped by use cases or aggregates, not raw tables, and none is a generic gateway for everything.
- [ ] Mapping is isolated from domain logic.
- [ ] Remote boundaries are coarse-grained and translated explicitly.
- [ ] The design is not controller-centric and has no layer that only forwards calls.
- [ ] Concurrency and loading assumptions are visible to a maintainer.

If any answer is no, revise before shipping. When you report the work, say which pattern you chose, which you rejected and why, and which tests ran.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Patterns of Enterprise Application Architecture is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Patterns of Enterprise Application Architecture would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Purpose`
- `Primary Directive`
- `Architectural Baseline`
- `Code Generation Rules`
- `Review Rules`
- `Forbidden Patterns`
- `Review Checklist`
- `Final Instruction`
