---
name: "ddd-principles"
description: "Applies the Domain-Driven Design rule set (Evans) to design and code decisions. Use for any task that models a business domain, reviews domain code, names things in the language of the business, or integrates with another model, system or team."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Domain-Driven Design principles

The code is the model. Business rules, the words the business uses and the boundaries between models belong in the code that runs, not in the schema, the controller or a document that drifted away from it.

## When the rules apply

- You add or change behavior in an area with real rules, lifecycle or invariants (pricing, claims, scheduling, eligibility, fulfilment).
- Names in the code differ from the names domain people use, or one word means two things in different modules.
- Controllers, services, jobs or SQL decide business outcomes while the entities only hold fields.
- A change integrates with another team's model, a legacy system or a vendor schema.
- You must decide where the most modeling effort goes, or whether a part of the system deserves a rich model at all.
- Not for: dependency direction between layers in general (`clean-architecture`), selective low-ceremony DDD for a small team or subdomain-first workshops (`ddd-distilled`), implementation depth that this rule set does not contain such as domain events, projections and integration styles (`ddd-implementing`), choosing enterprise patterns by force (`enterprise-patterns`), reshaping code that has no tests (`legacy-code`: characterize first, then return). For plain CRUD, build it plainly: see `ddd-right-sizing`.

## The bias this rule set corrects

An agent asked for a feature in a business-heavy codebase starts from what already has a shape: tables, DTOs, endpoints. It writes a service method that loads rows, branches on a status string and saves. The names come from the schema, a word like "customer" quietly means three things, the same rule is copied into two handlers, and "DDD" arrives, if at all, as renamed folders and a repository per table. The opposite failure is just as common: after reading about DDD the agent wraps a CRUD screen in aggregates, factories and domain services. This rule set breaks both habits with one question asked before code is written: what does the business call this, what rule does it express, and does this part of the system deserve a rich model? Clarity of the domain model is the tie-breaker. Ceremony is never a goal.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need (for example `Aggregates` or `Model Integrity Patterns`).
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/ddd/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention: the upstream file is a binding policy in which MUST is binding, SHOULD is a strong default and MUST NOT is forbidden. In its rule lists an unqualified rule is a MUST, `should` and `prefer` are SHOULD, and `do not`, `avoid`, `never` and `must not` are MUST NOT. Skills in this plugin keep that strength: where a rule says "Prefer", the skill says "Prefer". Everything in `mini.md` traces back to sections of `full.md`; text marked "Added judgment" is this plugin's own heuristic (thresholds, the right-sizing tiers, extra design advice), not a rule of the source, and a line starting with "Check:" is a detection aid written by this plugin to test a rule, not a rule itself.

## Subagent roles

Names such as `ddd-lead`, `ddd-final-gate` and the `...-reviewer` roles in the routing table are subagents. The OpenCode, Gemini CLI, Cursor and Copilot builds ship them as subagents, the MCP server serves them with get_guide, and in Codex they are installed separately; the plain Agent Skills build does not include them. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `ddd-lead` (delegate) |
| Review the working diff or named paths | `/ddd:review` |
| Health picture of a directory or repository | `/ddd:audit` |
| List forbidden patterns and map each to its treatment | `/ddd:smell-hunt` |
| Plan a feature or model change before editing | `/ddd:plan` |
| Resolve specific findings in the session | `/ddd:fix` |
| Understand one rule, pattern or exception | `/ddd:explain-rule` |
| Walk the review checklist while working | `/ddd:checklist` |
| Strict pass or fail before commit or pull request | `ddd-final-gate` (delegate) |
| The model feels shallow, table-shaped, contradictory; a breakthrough may be due | `ddd-deep-models`, `/ddd:scenario-walkthrough`, `/ddd:mode-model-explorer` |
| Code, tests, wiki and diagrams use different words or drift apart | `ddd-model-driven-design`, `ddd-ubiquitous-language`, `ddd-language-reviewer`, `/ddd:language-audit` |
| A flag, status field, repeated condition or rule in a comment hides a concept | `ddd-explicit-concepts`, `ddd-concept-reviewer` |
| Business decisions in controllers, jobs, application services; is Smart UI enough | `ddd-layers`, `ddd-layer-reviewer` |
| ORM, serializer, framework or table shapes, and table-derived class or field names, leak into the model | `ddd-infrastructure`, `ddd-infrastructure-reviewer` |
| Where does a model start and stop; terms that mean different things in different places; domain types shared by several contexts | `ddd-bounded-contexts`, `ddd-context-boundary-reviewer` |
| Choosing how two models relate; foreign or legacy model pressure | `ddd-context-relationships`, `/ddd:map-contexts`, `ddd-translation-builder` |
| Where to spend modeling effort; core buried under generic mechanisms or generic shared code | `ddd-distillation`, `ddd-strategy-reviewer` |
| An overall guiding structure for a large model | `/ddd:choose-structure` |
| Entity design, setters, transitions | `ddd-entities`, `ddd-entity-reviewer`, `ddd-behavior-mover` |
| Raw strings and numbers for domain quantities | `ddd-value-objects`, `ddd-value-object-reviewer`, `ddd-value-object-introducer` |
| Consistency boundaries, transactions across objects, references between aggregates | `ddd-aggregates`, `ddd-aggregate-reviewer`, `ddd-aggregate-reshaper` |
| Creating objects, loading and saving them | `ddd-factories`, `ddd-repositories`, `ddd-lifecycle-reviewer` |
| An operation that fits no entity or value; `*Service` classes growing | `ddd-domain-services`, `ddd-service-reviewer` |
| Package layout, associations, `models`/`services`/`utils` folders | `ddd-modules-and-associations`, `ddd-module-reviewer` |
| How the API reads; side effects in queries; combinable rules | `ddd-supple-design`, `ddd-supple-design-reviewer` |
| Importing an analysis pattern, design pattern or formalism | `/ddd:pattern-fit` |
| Writing or judging tests of the model | `ddd-domain-tests`, `ddd-domain-test-reviewer`, `ddd-domain-test-writer` |
| The change feels like too much DDD, or fake DDD | `ddd-right-sizing`, `ddd-ceremony-reviewer` |
| Session-long: declare context, terms and concept kind before code | `/ddd:mode-context-first` |
| Session-long: explore options and ask domain questions before code | `/ddd:mode-model-explorer` |
| Session-long: teach the rule behind each choice | `/ddd:mode-mentor` |
| Session-long: ranked findings only | `/ddd:mode-strict-reviewer` |
| Session-long: small narrated steps | `/ddd:mode-pair` |
| Session-long: result first, few lines | `/ddd:mode-terse` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep changes proportionate. Prefer an incremental move toward the better model; do not rewrite everything at once unless explicitly asked. When uncertain, choose the option that sharpens the domain language, protects invariants inside the model, keeps bounded contexts explicit, reduces primitive obsession and keeps infrastructure subordinate to domain meaning.

## Final checklist

- [ ] Is domain behavior explicit in the model rather than hidden in delivery, persistence or integration code?
- [ ] Do code, tests, documents and conversations use one language inside each bounded context?
- [ ] Do tactical patterns protect identity, value semantics, lifecycle, invariants and responsibility instead of adding ceremony?
- [ ] Does every cross-context integration have an explicit relationship, a translation strategy and a boundary test?
- [ ] Do tests read like executable examples of the model and cover invalid transitions and invalid construction?
- [ ] Is the core domain visible and protected from supporting complexity, generic mechanisms, infrastructure and frameworks?

When you report the work: say which context and domain terms you used, what became explicit that was implicit before, which tests ran, and any unresolved assumption about the domain.

## Source

- `Purpose`
- `Primary Directive`
- `What DDD Means in This Repository`
- `Code Generation Rules`
- `Output Expectations`
- `Review Checklist`
- `Final Instruction`
