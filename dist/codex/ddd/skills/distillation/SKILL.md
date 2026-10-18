---
name: "distillation"
description: "Use when deciding where modeling effort belongs, when generic mechanisms outweigh and hide the distinctive logic, or when picking refactoring targets by strategic value. Finding the core; types shared across contexts: $ddd:bounded-contexts; refusing ceremony in one change: $ddd:right-sizing."
---

# Distillation

Owns where the effort goes: identify the core domain, keep supporting and generic subdomains simpler, and separate mechanisms from policy so the core is easy to find and cleanly designed. Whether a particular change earns tactical machinery is `$ddd:right-sizing`; guiding structures across a large model are `$ddd:choose-structure`. A package whose problem is who owns its domain types, not what buries the core, is `$ddd:bounded-contexts`; folder naming is `$ddd:modules-and-associations`.

## When to use

- A pricing, matching, scheduling or risk module that sets the business apart is hard to find among utilities and framework code.
- Authentication, notification or reporting code is modeled more richly than the rule engine the business competes on.
- Refactoring effort is going to whichever file is messiest rather than to what matters strategically.
- A generic shared package holds both commodity mechanisms and the distinctive rules.
- A request arrives to "model everything properly" with no priorities.

## Rules

1. **Identify the part of the model that creates strategic advantage.** This is the core domain. Check: someone who knows the business has named it; it is not inferred from file size or churn (Added judgment).
2. **Invest the most care in the core domain.** Put the strongest modeling effort and the cleanest design there. Check: the core has the best names, tests and review attention in the repository.
3. **Protect the core domain from foreign models, vendor schemas and generic abstractions; do not bury it under generic mechanisms, infrastructure or broad shared abstractions.** Check: the core's imports are domain types and a few narrow interfaces.
4. **Keep the core expressive even if supporting areas are simpler.** Check: the core is not flattened to match the style of its surroundings.
5. **Do not over-model commodity concerns, use simpler models where business complexity is low, and save the richest effort for what matters strategically.** Check: supporting and generic areas use the simplest design that works (`$ddd:right-sizing`).
6. **Make the core domain easy to find in code.** Check: a newcomer reaches it from the top-level layout in under a minute.
7. **Keep supporting and generic subdomains simpler unless their complexity is real.** Check: any elaborate supporting design points to a concrete rule that justifies it.
8. **Choose refactoring targets by strategic importance, not just local messiness.** Check: the plan explains why this module and not a messier peripheral one.
9. **Use distillation patterns when they clarify priority and investment.** Write a Domain Vision Statement for the core's purpose; mark the Highlighted Core inside a larger model; treat a Generic Subdomain as commodity; separate a Cohesive Mechanism from domain policy; use a Segregated Core when the core is tangled with supporting concerns; use an Abstract Core when related specialized models need a stable conceptual foundation. Check: each pattern used answers a named problem.
10. **Keep context relationships and distillation choices visible in code when they affect it.** Check: package names, a short note or tests make the core and its boundaries discoverable.
11. **Do not spend equal modeling effort on every subsystem, let technical mechanisms dominate the core model, hide the core behind generic shared packages, or refactor the periphery while the core stays unclear.** Check: effort in the diff matches the strategic value of the area.

## Procedure

1. Ask who knows what differentiates the business; write one paragraph naming the core in their words (a draft Domain Vision Statement). If nobody can say, report that as the blocker.
2. Classify the areas in scope: core, supporting, generic. Mark uncertain ones as such.
3. For the core, find what hides it: generic helpers, vendor types, shared packages, plumbing in the same files. List each tangle.
4. Choose the treatment: extract a Cohesive Mechanism for technical machinery, create a Segregated Core when the tangle is pervasive, mark a Highlighted Core when the model is big and only a part matters.
5. Move incrementally behind tests (`$ddd:plan`). Keep behavior unchanged.
6. For supporting and generic areas, decide the simplest acceptable design and say so, so effort does not drift back.

## Example

```ts
// Before: the distinctive rule is buried between retries and cache plumbing
async function quote(req: QuoteRequest): Promise<number> {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const rates = (await cache.get("rates")) ?? (await http.get("/rates"));
      return rates.base * seatClassFactor(req.seatClass) * (1 + surgeFor(req.demand));
    } catch {
      /* retry */
    }
  }
  throw new Error("failed");
}

// After: the core is a pure function in a findable place; the mechanism is separate
type SeatClass = "economy" | "business";

// pricing/quote-policy.ts (core domain, no I/O)
function quote(baseFare: number, seatClass: SeatClass, demand: number): number {
  return Math.round(baseFare * seatClassFactor(seatClass) * (1 + surgeFor(demand)) * 100) / 100;
}

// mechanisms/retry.ts (cohesive mechanism, knows nothing about pricing)
async function withRetry<T>(attempts: number, work: () => Promise<T>): Promise<T> {
  let lastError: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      return await work();
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError;
}

async function quoteRoute(source: RateSource, route: string, seatClass: SeatClass, demand: number): Promise<number> {
  const baseFare = await withRetry(3, () => source.fetchBaseFare(route));
  return quote(baseFare, seatClass, demand);
}
```

## Anti-patterns

- **Equal effort everywhere.** Detect: rich models for notification preferences and a procedural pricing script.
- **Core behind `common`.** Detect: the distinctive rules live in a package named `utils`, `common` or `shared`.
- **Mechanism-led core.** Detect: the core's types are shaped by caches, retries or vendor SDK types.
- **Peripheral refactoring.** Detect: a refactor plan whose targets are chosen by lint count or file size.
- **Legacy vocabulary in the core.** Detect: legacy system terms dominating the core's type names.

## Trade-offs and exceptions

- The rule set limits supporting areas' modeling effort unless their complexity is real. Complexity that is real (regulation, safety) earns real modeling even if it is not the core.
- The core can move as the business changes; strategic decisions stay revisable (`$ddd:choose-structure`).
- Segregating a core is a larger move than extracting one mechanism; use the smaller pattern that resolves the tangle. Added judgment: do the smaller extraction first and re-assess.

## Verification

- [ ] The core domain is named by someone who knows the business, in a sentence.
- [ ] The core is reachable from the top-level layout and its imports are narrow.
- [ ] Supporting and generic areas use deliberately simpler designs.
- [ ] Refactoring targets in the plan are justified by strategic value.
- [ ] Mechanisms are separated from policy and contain no domain rules.

## Related

`$ddd:right-sizing` for the per-change brake; `$ddd:choose-structure` for overall guiding structure; `$ddd:context-relationships` for foreign models around the core; `ddd-strategy-reviewer` to review a diff or tree.

## Source

- `Strategic Design`: only the core domain and supporting and generic subdomain rules.
- `Distillation`
- `Code Generation Rules`: only the rule to preserve strategic priorities.
- `Strategic Decision Making`: only the rule that strategic decisions remain revisable as understanding changes.
