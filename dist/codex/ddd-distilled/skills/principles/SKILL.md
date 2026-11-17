---
name: "principles"
description: "Applies the Domain-Driven Design Distilled rule set to design and coding decisions in business software. Use for any task that creates, reviews or changes domain code where subdomain importance, bounded contexts, ubiquitous language or the cost of tactical patterns matters."
---

# Domain-Driven Design Distilled principles

Use DDD where it clarifies complex business software, and do not turn it into ritual. Start from the business capability, its importance, the bounded context and the local language; add a tactical pattern only when it earns its cost.

## When the rules apply

- You design or change code where business rules, vocabulary or integration with other systems shape the result, and the question is how much modeling the work deserves.
- You review a diff for model quality: language drift, shared models, primitives carrying rules, oversized aggregates, services that hold every decision, ceremony in simple code.
- You start a feature or module and must decide the subdomain, the context, the names and the smallest pattern that fits.
- A user asks whether to use DDD for an area, which context relationship fits, or how to run a modeling session under delivery pressure.
- Not for: the original DDD vocabulary and large-scale structure in depth (use the `ddd` plugin), implementation depth for work already committed to DDD (use `ddd-implementing`), choosing among enterprise persistence and transaction patterns (use `enterprise-patterns`), or dependency direction between layers (use `clean-architecture`). This plugin is the gate and the default; those are for after the gate says yes.

## The bias this rule set corrects

An agent asked to build a feature in a business system drifts to one of two failures. Either it models nothing: a controller, a service with every decision inside it, a table-shaped class, a status integer, and a vocabulary borrowed from whichever API it touched last. Or it overcorrects: an aggregate, a repository, three events and a mapper for a lookup table that three people edit. This rule set asks for the middle path, which the rule set sums up as using DDD selectively, but seriously. The order matters: business capability and subdomain importance first, then the bounded context that owns the model, then the words of that context, and only then the smallest tactical pattern that protects meaning or an invariant.

## Loading the rules

1. For every design or code decision, read `references/mini.md` first.
2. Read `references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `references/nano.md` is the compact always-on form; the same text ships as dist/rules/ddd-distilled/AGENTS.nano.md in the guided-plugins repository, for an AGENTS.md file.

Modal convention. The source file says MUST is binding, SHOULD is a strong default and MUST NOT is forbidden. Inside its lists, an unqualified rule is a MUST; wording such as "prefer", "default to", "should" and "usually" is a SHOULD; "Do not", "Avoid" and the anti-pattern lists are MUST NOT. Skills in this plugin keep that strength. A user instruction can override a rule.

Provenance labels. A numbered rule with no label comes from `references/full.md`. `(Compact checklist)` marks a rule that exists only in `mini.md` or `nano.md`. `(Added judgment)` marks this plugin's own heuristic, threshold or procedure detail, not a rule of the source. This rule set gives no repository rules and no step-by-step event storming method, so components that touch those say so.

## Subagent roles

Names such as `ddd-distilled-lead`, `ddd-distilled-final-gate` and the `...-reviewer` roles in the routing table are subagents. In Codex they are custom roles, which a plugin cannot switch on by itself: run `$ddd-distilled:install-roles` once, restart Codex, then ask for one by name. When your agent has no role of that name, do that step yourself: follow the skill named beside it, or the rules in this skill.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `ddd-distilled-lead` (delegate) |
| Review the working diff or named paths | `$ddd-distilled:review` |
| Health picture of a directory or repository | `$ddd-distilled:audit` |
| Plan a change to existing code in increments | `$ddd-distilled:plan` |
| Write new domain behavior and need the model brief first | `$ddd-distilled:model-first` |
| Resolve specific findings | `$ddd-distilled:fix` |
| Understand one rule, its strength or its exception | `$ddd-distilled:explain-rule` |
| Walk the nine final questions while working | `$ddd-distilled:checklist` |
| Strict pass or fail before commit or pull request | `ddd-distilled-final-gate` (delegate) |
| Should this area use DDD at all, how much | `$ddd-distilled:adoption-fit` |
| Rank areas as core, supporting, generic | `$ddd-distilled:subdomains`, `$ddd-distilled:classify-subdomains` for a codebase scan, `ddd-distilled-subdomain-reviewer` to review a diff |
| Which tactical pattern for this concept (value object or entity?), or too much ceremony | `$ddd-distilled:pattern-economy`, `ddd-distilled-ceremony-reviewer` |
| One model shared across concerns, same word with different rules in different modules | `$ddd-distilled:bounded-contexts`, `ddd-distilled-context-boundary-reviewer` |
| How two contexts relate, which of the nine relationships | `$ddd-distilled:context-mapping`, `$ddd-distilled:map-contexts` for the as-found map of a whole tree, `ddd-distilled-relationship-reviewer` for a diff |
| Foreign model, upstream payload or schema entering local code | `$ddd-distilled:context-translation`, `ddd-distilled-translation-builder` to build the translator |
| RPC, REST or messaging between contexts | `$ddd-distilled:integration-styles`, `ddd-distilled-integration-reviewer` |
| Names, synonyms, one word with two meanings inside one context | `$ddd-distilled:ubiquitous-language`, `$ddd-distilled:glossary` for a tree, `ddd-distilled-language-reviewer`, `ddd-distilled-term-renamer` to apply a decided rename |
| Flag, status code, enum, boolean or helper carries a decision | `$ddd-distilled:explicit-concepts`, `ddd-distilled-concept-reviewer` |
| Identity, lifecycle, setters, anemic classes | `$ddd-distilled:entities`, `ddd-distilled-entity-reviewer` |
| Primitive pair or group repeated with rules | `$ddd-distilled:value-objects`, `ddd-distilled-value-object-introducer` |
| Aggregate size, root, invariants, references | `$ddd-distilled:aggregates`, `ddd-distilled-aggregate-reviewer` |
| One request changes several aggregates, graph loading, a second effect must follow | `$ddd-distilled:cross-aggregate-consistency`, `ddd-distilled-consistency-reviewer` |
| Domain events: names, noise, payload | `$ddd-distilled:domain-events`, `ddd-distilled-event-reviewer` |
| Service or controller with business decisions | `$ddd-distilled:application-services`, `ddd-distilled-service-reviewer`, `ddd-distilled-behavior-mover` to relocate decisions |
| Framework, ORM or transport types in the model | `$ddd-distilled:infrastructure-isolation`, `ddd-distilled-infrastructure-reviewer` |
| Tests of the model | `$ddd-distilled:domain-tests`, `ddd-distilled-domain-test-reviewer`, `ddd-distilled-domain-test-writer` |
| Workflow, events or language unclear; delivery pressure | `$ddd-distilled:accelerated-modeling`, `$ddd-distilled:event-storm` |
| Size DDD work, record known modeling imperfections | `$ddd-distilled:estimate-work`, `$ddd-distilled:modeling-debt` |
| Session-long behavior: teach the reasoning | `$ddd-distilled:mode-mentor` |
| Session-long behavior: ranked findings only | `$ddd-distilled:mode-strict-reviewer` |
| Session-long behavior: small narrated steps | `$ddd-distilled:mode-pair` |
| Session-long behavior: result first, few lines | `$ddd-distilled:mode-terse` |
| Session-long behavior: context card before every design answer | `$ddd-distilled:mode-context-first` |
| Session-long behavior: every pattern tagged with why it earns its cost | `$ddd-distilled:mode-earned-pattern` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions, unless they are the problem being fixed.
3. This book's rules.

Keep modeling proportionate to the task. Prefer incremental improvement over a design overhaul, and do not widen scope to satisfy the rules.

## Final checklist

- [ ] The subdomain and its importance are understood.
- [ ] The bounded context is explicit.
- [ ] The ubiquitous language is visible in the code.
- [ ] Only the tactical patterns that genuinely help were used.
- [ ] Aggregates are small and focused on invariants.
- [ ] Value objects are used where they clarify meaning.
- [ ] Application services coordinate rather than own the domain logic.
- [ ] Infrastructure stayed out of the model.
- [ ] The change avoids DDD theater and over-modeling.
- [ ] (Compact checklist) Translation is tested where a foreign model crosses a boundary.
- [ ] (Compact checklist) Modeling discoveries, acceptance scenarios, expert input and known modeling debt are captured.

If any answer is no, revise before shipping. When you report the work, say what was modeled and what was deliberately kept simple, which tests ran, and any assumption you could not confirm with a domain expert.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Domain-Driven Design Distilled is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Domain-Driven Design Distilled would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Purpose`
- `Primary Directive`
- `Code Generation Rules`
- `Review Checklist`
- `Final Instruction`
