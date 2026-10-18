---
name: "ddd-implementing-principles"
description: "Applies the Implementing Domain-Driven Design rule set to code that models a business domain. Use for any task on bounded contexts, aggregates, repositories, domain events, application services or cross-context integration, and to find the right specialist."
license: "MIT"
metadata:
  plugin: "ddd-implementing"
  book: "Implementing Domain-Driven Design"
  invocation: "auto"
---

# Implementing Domain-Driven Design principles

DDD is implemented, not decorated. Put the code in a named bounded context, speak that context's language, keep each aggregate small and tied to an invariant, refer to other aggregates by identity, and translate at every boundary.

## When the rules apply

- You add or change code that models business behavior: an aggregate, entity, value object, domain service, repository, domain event, application service or module layout.
- You integrate with another bounded context, a legacy system, a partner API or a client (UI, REST resource, report).
- You review a diff or a design for context leakage, oversized aggregates, anemic models, generic repositories, command-like events or fat application services.
- A user asks whether a part of the system deserves DDD at all.
- Not for: choosing between DDD and a simpler enterprise pattern for a system that has not committed to DDD, discovering the model with domain experts, or classifying subdomains (the sibling plugins `ddd` and `ddd-distilled` cover those). Not for dependency direction between layers in general (use a Clean Architecture plugin) or reliability policy for production calls (use a Release It plugin).

## The bias this rule set corrects

Asked to "implement DDD", an agent produces renamed CRUD: classes shaped like tables with getters and setters, one service per entity that holds every rule, repository interfaces that mirror the ORM, a transaction wrapped around whatever the use case happens to touch, and a `models` or `shared` package every module imports. The vocabulary of DDD appears and the design does not change. The opposite failure also happens: a settings screen gets aggregates, repositories and events because the project "does DDD". This rule set asks for tactical patterns that change the design where complexity is real, a named context and local language before any class, effort that follows complexity, and explicit translation wherever a model meets another model, a database, a transport or a client.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/ddd-implementing/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

When uncertain, the source orders its choices: identify the bounded context, use its language, draw the aggregate boundary conservatively, reference other aggregates by identity, keep infrastructure outside the model, integrate across contexts through explicit translation.

Modal convention. The upstream file says `MUST` is binding, `SHOULD` is a strong default and `MUST NOT` is forbidden. The skills in this plugin tag each rule with its strength:

- `[MUST]` and `[MUST NOT]`: unqualified rules and explicit prohibitions of the full rule set.
- `[SHOULD]` and `[SHOULD NOT]`: "prefer", "should usually", "unless there is a compelling reason", "avoid by default". A justified exception is allowed; say what justifies it.
- `[MUST NOT by default]`: a prohibition the source qualifies with "by default" ("do not share model classes across contexts by default"). It stays a prohibition; leaving it needs a stated, recorded reason.
- `[MAY]`: permissions ("application services may own transaction boundaries").
- `[Compact checklist]`: a rule or trigger that is stated only in `mini.md` or `nano.md`.
- `[Added judgment]`: this plugin's own heuristic, detection recipe or numeric search aid. It is not a rule of the source and loses to the user's instruction and the repository's conventions.

## Subagent roles

Names such as `ddd-implementing-lead`, `ddd-implementing-final-gate` and the `...-reviewer` roles in the routing table are subagents. The OpenCode, Gemini CLI, Cursor and Copilot builds ship them as subagents, the MCP server serves them with get_guide, and in Codex they are installed separately; the plain Agent Skills build does not include them. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `ddd-implementing-lead` (delegate) |
| Review the working diff or named paths | `ddd-implementing-review` |
| Health picture of a directory or repository | `ddd-implementing-audit` |
| Plan a change to existing code | `ddd-implementing-plan` |
| Design a new concept before any code | `ddd-implementing-model-walk` |
| Resolve specific findings in the session | `ddd-implementing-fix` |
| Understand one rule, its strength or its exceptions | `ddd-implementing-explain-rule` |
| Walk the review checklist while working | `ddd-implementing-checklist` |
| Strict pass or fail before commit or pull request | `ddd-implementing-final-gate` (delegate) |
| Which context owns a class, or a model is shared across contexts | `ddd-implementing-bounded-context`, `ddd-implementing-context-boundary-reviewer`; a whole tree: `ddd-implementing-context-map` |
| Folder and package layout, `shared` or `common` packages | `ddd-implementing-module-structure`, `ddd-implementing-context-boundary-reviewer` |
| How two contexts relate, who is upstream, who translates | `ddd-implementing-context-mapping` |
| A legacy, vendor or partner model is entering local code | `ddd-implementing-anticorruption-layer`, `ddd-implementing-translation-reviewer`, `ddd-implementing-acl-builder` |
| A message, event or identifier leaves the context | `ddd-implementing-integration-contracts`, `ddd-implementing-translation-reviewer` |
| One term with two meanings, two terms for one concept, technical placeholders | `ddd-implementing-ubiquitous-language`, `ddd-implementing-language-reviewer` |
| How much DDD an area deserves, CRUD versus real complexity | `ddd-implementing-core-domain-focus`, `ddd-implementing-ceremony-check`, `ddd-implementing-modeling-effort-reviewer` |
| What belongs inside an aggregate, aggregate too big | `ddd-implementing-aggregate-boundaries`, `ddd-implementing-invariant-inventory`, `ddd-implementing-aggregate-design-reviewer` |
| Outside code mutates aggregate internals, setters, exposed child collections | `ddd-implementing-aggregate-root-discipline`, `ddd-implementing-root-discipline-reviewer`, `ddd-implementing-root-encapsulator` |
| An aggregate holds another aggregate, or one use case saves several aggregates | `ddd-implementing-cross-aggregate-coordination`, `ddd-implementing-transaction-reviewer`, `ddd-implementing-identity-reference-converter`, `ddd-implementing-transaction-splitter` |
| A class with identity and a life cycle, state transitions | `ddd-implementing-entities` |
| Primitives that carry meaning, a value type to design or review | `ddd-implementing-value-objects`, `ddd-implementing-value-object-reviewer` |
| An operation that fits no entity or value object | `ddd-implementing-domain-services`, `ddd-implementing-rule-placement-reviewer` |
| Use-case code, controllers that orchestrate, services that branch on business rules | `ddd-implementing-application-services`, `ddd-implementing-rule-placement-reviewer` |
| A repository interface or implementation | `ddd-implementing-repositories`, `ddd-implementing-repository-reviewer` |
| Naming, payload or timing of a domain event | `ddd-implementing-domain-events`, `ddd-implementing-event-reviewer` |
| Persisting an aggregate as its events | `ddd-implementing-event-sourcing`, `ddd-implementing-event-sourcing-reviewer` |
| What a UI, REST client or report receives, read models, scope identifiers | `ddd-implementing-client-representations`, `ddd-implementing-representation-reviewer` |
| Writing or judging tests of the domain | `ddd-implementing-domain-tests`, `ddd-implementing-test-coverage-reviewer`, `ddd-implementing-domain-test-writer` |
| Session-long behavior: teach the reasoning | `ddd-implementing-mode-mentor` |
| Session-long behavior: ranked findings only | `ddd-implementing-mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `ddd-implementing-mode-pair` |
| Session-long behavior: result first, few lines | `ddd-implementing-mode-terse` |
| Session-long behavior: open every answer with the context and its terms | `ddd-implementing-mode-context-first` |
| Session-long behavior: state invariants and transaction scope before every model change | `ddd-implementing-mode-invariant-first` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with and at what strength.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep changes proportionate to the task. Do not restructure a context to satisfy the rules when the request touched one method, and do not add tactical machinery to an area that is plain CRUD.

## Final checklist

The ten questions of the source's own review checklist. If any answer is no, revise before shipping.

- [ ] Is the bounded context explicit?
- [ ] Is the local ubiquitous language used consistently?
- [ ] Are aggregates small and centered on immediate invariants?
- [ ] Are cross-aggregate references by identity?
- [ ] Does one transaction usually modify one aggregate?
- [ ] Are repository interfaces aggregate-oriented?
- [ ] Are domain events facts rather than commands?
- [ ] Are application services orchestrating rather than owning the model?
- [ ] Are foreign models translated explicitly?
- [ ] Did we avoid shared-model shortcuts across contexts?

`[Compact checklist]` additions from `mini.md`, each restating a rule of the full file that its checklist leaves out:

- [ ] Is core-domain effort protected while supporting and CRUD areas stay simpler?
- [ ] Are context relationships, translation responsibilities and upstream and downstream pressures visible?
- [ ] Are entities behavior-bearing, and value objects immutable, validated and equal by value?
- [ ] Is event sourcing used only where event history is the right persistence model (or not at all)?
- [ ] Are client, foreign, persistence and infrastructure representations kept outside the domain model?

When you report the work: say which context it belongs to, what changed, which tests ran, and any rule that was bent and why.

## Source

- `Purpose`
- `Primary Directive`
- `Code Generation Rules`
- `Review Checklist`
- `Final Instruction`
