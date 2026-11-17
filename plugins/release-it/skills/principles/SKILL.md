---
name: principles
description: "Applies the Release It! production-survival rules to services, APIs, jobs, queues, deployment paths and control tooling. Use for any task that adds or changes code crossing a process boundary, holding a scarce resource, buffering work, or shipping to production. Routes to the specialist components."
---

# Release It! principles

A feature that passes its tests has only proven the happy path. Deliver the behavior, and decide the failure semantics, demand limits, isolation, recovery path and diagnosis surface of every boundary the change touches before production decides them for you.

## When the rules apply

- You add or change an outbound call, a wait, a queue, a worker pool, a cache, a scheduled or background job, or an endpoint that accepts work.
- You change how software is deployed, configured, started, migrated, health-checked or operated, including scripts and admin tooling.
- You review a change, an incident, a capacity problem or a launch for production readiness.
- A user asks why a timeout, retry, breaker or limit is (or is not) needed.
- Not for: readability and local code shape (a Clean Code plugin), dependency direction between layers (a Clean Architecture plugin), data consistency, replication and schema evolution semantics (a data-systems plugin), or reshaping untested code before you can change it safely (a legacy-code plugin). Pure in-process logic with no boundary, no shared resource and no deployment effect does not need these defenses; adding them there is the cost the compatibility notes warn about.

## The bias this rule set corrects

An agent writes the call, sees the test pass, and stops. The HTTP client keeps the library's wait, the retry loop sits at three layers, the queue has no ceiling, the health endpoint returns 200 without touching anything, the deploy script has to start over after a partial failure, and the only diagnostic is a stack trace. In production a dependency is rarely cleanly down; it is slow, partly wrong, or recovering, and a slow dependency is worse than a dead one because it holds threads, connections and callers while it fails. This rule set asks you to assume the mess: every dependency can be slow, unavailable or wrong, every queue can fill, every cache can miss at once, every timeout can cascade, every caller can retry badly, and every temporary degraded state can last for hours. Then prefer the design that fails visibly, limits blast radius, sheds load, keeps the core service alive, and can be diagnosed.

## Loading the rules

1. For every design or code decision, Read `${CLAUDE_SKILL_DIR}/references/mini.md` first.
2. Read `${CLAUDE_SKILL_DIR}/references/full.md` only when the mini rules do not settle a trade-off. Name the section you need.
3. `${CLAUDE_SKILL_DIR}/references/nano.md` is the compact always-on form; the optional SessionStart hook injects it.

Modal convention: the source says `MUST` is binding, `SHOULD` is a strong default and `MUST NOT` is forbidden. An unqualified statement is a MUST, `Prefer` is a SHOULD, `Do not`, `Avoid`, `Never` and the anti-pattern lists are MUST NOT, and qualifiers such as "where practical" or "when appropriate" stay attached. Rules in this plugin's skills carry a tag: `[MUST]`, `[SHOULD]`, `[MUST NOT]` follow the source; `[Added judgment]` is this plugin's own heuristic or number (the source gives no timeout values, retry counts or pool sizes); `[Compact checklist]` is phrasing found only in `mini.md` or `nano.md`.

## Routing table

| Situation | Use |
| --- | --- |
| Not sure which specialist applies to a task or diff | `release-it:lead` (delegate) |
| Review the working diff or named paths | `/release-it:review` |
| Rate each failure domain across a tree | `/release-it:audit`, raw hit counts from `release-it:hazard-scanner` |
| Enumerate what happens when each boundary of one flow fails | `/release-it:failure-mode-scan` |
| Compute worst-case time and attempt multiplication along a request path | `/release-it:call-chain-budget` |
| Plan a change that crosses a boundary | `/release-it:plan` |
| Resolve specific findings | `/release-it:fix` |
| Understand one rule or its exceptions | `/release-it:explain-rule` |
| Walk the final checklist while working | `/release-it:checklist` |
| Strict pass or fail before commit or pull request | `release-it:final-gate` (delegate) |
| Analyze an incident, outage or capacity problem | `/release-it:incident-review` |
| Plan a fault-injection experiment or game day | `/release-it:game-day-plan` |
| Go or no-go before a service goes live | `/release-it:launch-check` |
| An outbound call or wait with no deliberate limit | `/release-it:timeouts`, `release-it:timeout-reviewer`, `release-it:call-hardener` |
| Retry loops, backoff, retries at several layers | `/release-it:retries`, `release-it:retry-reviewer`, `release-it:call-hardener` |
| Stop calling a failing dependency, fallback, degraded mode | `/release-it:circuit-breakers`, `release-it:isolation-reviewer` |
| One shared pool, one slow integration starving the rest, single points of failure | `/release-it:bulkheads`, `release-it:isolation-reviewer` |
| Steady state, fail fast on a precondition, let-it-crash, middleware, governors | `/release-it:stability-patterns` |
| Accepting work with no plan for overload, hostile or abusive traffic | `/release-it:back-pressure`, `release-it:overload-reviewer`, `release-it:overload-hardener` |
| Queues, buffers, dead letters, poison messages | `/release-it:queues`, `release-it:overload-reviewer`, `release-it:overload-hardener` |
| Threads, connections, sockets, memory, large payloads, locks held across calls | `/release-it:resource-budgets`, `release-it:resource-reviewer` |
| External input or a dependency response used without checks | `/release-it:data-boundaries`, `release-it:data-boundary-reviewer` |
| Log lines, swallowed errors, correlation | `/release-it:logging`, `release-it:observability-reviewer` |
| Metrics, saturation signals, alert inputs | `/release-it:metrics`, `release-it:observability-reviewer` |
| Process startup, configuration validation, health endpoints, load balancer readiness | `/release-it:startup-and-health`, `release-it:startup-reviewer` |
| Rollout, rollback, compatibility between versions, configuration changes | `/release-it:release-risk`, `release-it:deployment-reviewer` |
| Deployment scripts, migrations, one-time jobs that may be rerun | `/release-it:restartable-automation`, `release-it:deployment-reviewer`, `release-it:automation-hardener` |
| Admin endpoints, control planes, delivery tooling, secrets, permissions | `/release-it:operational-controls`, `release-it:control-plane-reviewer` |
| API or integration contract: failure modes, retryable outcomes, versions | `/release-it:api-contracts`, `release-it:contract-reviewer` |
| Cache misses, stampedes, stale data, cache outage | `/release-it:caching`, `release-it:cache-reviewer` |
| Cron, periodic or long-running background jobs | `/release-it:scheduled-work`, `release-it:schedule-reviewer` |
| Tests for timeouts, retries, degraded dependencies, saturation | `/release-it:resilience-testing`, `release-it:resilience-test-reviewer`, `release-it:resilience-test-writer` |
| Session-long behavior: teach the reasoning | `/output-style release-it:mentor` |
| Session-long behavior: ranked findings only | `/output-style release-it:strict-reviewer` |
| Session-long behavior: small narrated steps | `/output-style release-it:pair` |
| Session-long behavior: result first, few lines | `/output-style release-it:terse` |
| Session-long behavior: failure ledger before every edit | `/output-style release-it:failure-first` |
| Session-long behavior: operations note after every change | `/output-style release-it:operator` |

## Priority

1. Explicit user instruction. If a request conflicts with a rule, follow the request and say which rule it conflicts with.
2. The repository's existing conventions and service-level targets, unless they are the problem being fixed.
3. This book's rules.

Keep the change proportionate. A timeout, a limit or a rejection changes behavior: say what callers see when it triggers, derive numbers from existing configuration or measurements where they exist, and flag a guessed number as needing confirmation instead of presenting it as settled.

## Final checklist

- [ ] Does every remote call have an explicit timeout?
- [ ] Are retries bounded and safe?
- [ ] Are deployment and operational scripts restartable or idempotent where practical?
- [ ] Is there an overload strategy?
- [ ] Are queues and resource pools bounded?
- [ ] Is failure isolated from unrelated work?
- [ ] Are there enough diagnostics to investigate issues?
- [ ] Are health signals meaningful?
- [ ] Are scheduled and background workloads bounded and paced safely?
- [ ] Did we preserve the core service under likely failure scenarios?

If any answer is no, revise before shipping. When you report the work, say which boundaries the change touched, what happens at each when the other side is slow, down or wrong, and which checks or tests you ran.

<!-- project-settings:start -->
## Project settings

If the repository has a `.guided-plugins.json` file at its root, read it before you review, audit, plan or check anything, and apply it. If it is missing or unreadable, use the defaults and say nothing about it.

- `ignore` (globs): do not review or edit files that match, and say how many were left out. A pattern without a slash matches at any depth; a trailing slash means a folder.
- `strictness`: `relaxed` reports blockers and majors only; `normal` (the default) adds minors; `strict` adds nits.
- `maxFindings` (default 15): report at most this many, most serious first, and say how many were left out.
- `primary` and `secondary`: if Release It! is not the `primary` book, apply it as a secondary book. Where its advice contradicts the primary book, report that as a note ("Release It! would ..., the primary book decides: ..."), not as a finding.
- `failOn` is for CI and git hooks; ignore it here.

The user's instruction and the repository's established conventions still outrank all of this.
<!-- project-settings:end -->

## Source

- `Purpose`
- `Primary Directive`
- `Stability Mindset Rules`
- `Code Generation Rules`
- `Review Checklist`
- `Final Instruction`
