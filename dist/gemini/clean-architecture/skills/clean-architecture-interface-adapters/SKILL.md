---
name: "clean-architecture-interface-adapters"
description: "Use when writing or judging controllers, presenters, mappers or gateway implementations, including one that skips a use case or branches on business fields. Rule destination: entities-and-invariants or use-cases. Signature types: boundary-models; consumers, devices: service-and-device-edges."
license: "MIT"
metadata:
  plugin: "clean-architecture"
  book: "Clean Architecture"
  invocation: "auto"
---

# Interface adapters

Owns the layer that translates between the outside world and the use cases: controllers and endpoints on the way in, presenters and response mappers on the way out, gateway adapters toward storage. Message consumers, remote clients and device code are `clean-architecture-service-and-device-edges`; the shape of the models being translated is `clean-architecture-boundary-models`; where the logic should go instead is `clean-architecture-entities-and-invariants` or `clean-architecture-use-cases`.

## When to use

- A controller, route handler, job or view contains `if` statements about business meaning.
- A controller calls a repository or gateway directly and skips the use case.
- A presenter or serializer runs a query.
- You are designing how a use case's outcome becomes a status code, a page or a message.
- A mapper does more than copy and rename fields.

## Rules

1. **Translate delivery input into input models for use cases in the controller or endpoint.** `[MUST]` Check: the controller's body builds a request model and calls one use case.
2. **Translate use-case output for the delivery mechanism in a presenter or response mapper.** `[MUST]` Check: status codes, headers, templates and display strings appear only in adapters.
3. **Convert between external formats and internal models, depend only inward on application and domain code, and contain framework and vendor details.** `[MUST]` Check: no adapter is imported by a use case or entity.
4. **Do not let business policy migrate from the use case or domain layer into an adapter.** `[MUST NOT]` Check: for each conditional in an adapter, ask whether a domain expert would call it a rule.
5. **Do not let controllers contain branching business rules or validation that belongs to business policy.** `[MUST NOT]` unless explicitly required and justified. Check: the controller has no comparison against limits, tiers, states or dates that carry business meaning.
6. **Do not let controllers call gateways directly instead of use cases, and do not bypass use cases from adapters.** `[MUST NOT]` unless explicitly justified by the architecture. Check: a controller's constructor receives use cases, not gateways.
7. **Do not let presenters read directly from databases.** `[MUST NOT]` Check: a presenter receives an output model and has no store parameter.
8. **Keep gateways to persistence.** `[MUST]` A gateway adapter loads and saves; it does not decide. Check: its methods are lookups and writes expressed in domain terms.
9. **Name an adapter by the external detail or delivery mechanism it adapts.** `[MUST]` Check: `RenewalHttpController`, `PostgresLoanGateway`; not `LoanManager`.
10. **Map outcomes to transport results in one place per delivery mechanism.** Added judgment: a single table or `switch` from use-case outcomes to status codes (or screens) keeps the translation reviewable and keeps use cases free of HTTP vocabulary. Check: you can list every outcome and its status without reading the use case.
11. **Keep structural validation in the adapter and name it as such.** Added judgment: "the body is valid JSON with a numeric `points` field" is translation; "gold members redeem at most 5000 points per redemption" is policy. Check: moving the adapter to another delivery mechanism would require rewriting only the first kind.

## Procedure

1. List the statements in the controller, presenter or gateway under review. Classify each as translation, orchestration, business policy or infrastructure (`/clean-architecture:place-code`).
2. Move policy statements into an entity or the use case; leave translation behind.
3. If the controller skips the use case, introduce or call the use case that represents the action (`/clean-architecture:extract-use-case`).
4. Make the use case return an outcome type the presenter can switch over; remove transport concepts from the use case.
5. Put the outcome-to-transport mapping in the presenter or a mapper function.
6. Run the tests; add a controller test that uses a fake use case, and a presenter test that feeds each outcome.

## Example

```ts
// Before: the route handler decides
app.post("/loyalty/redeem", async (req, res) => {
  const member = await db.members.findOne({ id: req.body.memberId });
  if (member.tier === "gold" && req.body.points > 5000) {
    return res.status(422).json({ error: "gold members redeem at most 5000 points per redemption" });
  }
  if (member.points < req.body.points) {
    return res.status(409).json({ error: "not enough points" });
  }
  member.points -= req.body.points;
  await db.members.save(member);
  res.json({ remaining: member.points });
});
```

```ts
// After. application/redeemPoints.ts defines the outcome the use case returns:
// type RedeemOutcome =
//   | { kind: "redeemed"; remaining: number }
//   | { kind: "per-redemption-limit"; limit: number }
//   | { kind: "insufficient" };
// The tier limit now lives in Member.redeem; the use case loads, calls it and saves.

// adapters/web/redeemPointsController.ts: translation only
export const redeemPointsController =
  (useCase: RedeemPoints, present: (outcome: RedeemOutcome) => Presented) =>
  async (req: Request, res: Response) => {
    const points = Number(req.body.points);
    if (!Number.isInteger(points)) {
      return res.status(400).json({ error: "points must be an integer" });
    }
    const outcome = await useCase.execute({ memberId: String(req.body.memberId), points });
    const { status, body } = present(outcome);
    res.status(status).json(body);
  };

// adapters/web/presentRedemption.ts: output translation only
export type Presented = { status: number; body: Record<string, unknown> };

export const presentRedemption = (outcome: RedeemOutcome): Presented => {
  switch (outcome.kind) {
    case "redeemed":
      return { status: 200, body: { remaining: outcome.remaining } };
    case "per-redemption-limit":
      return { status: 422, body: { error: `limit is ${outcome.limit} points per redemption` } };
    case "insufficient":
      return { status: 409, body: { error: "not enough points" } };
  }
};
```

The 5000-point limit is no longer in the route; replacing Express with another transport rewrites two small adapter files and nothing else.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Fat controller | Branching on business fields, loops over domain data, several gateway calls | Extract a use case; keep the controller to translate and call |
| Layer bypass | A controller holding a repository or gateway | Inject the use case instead |
| Querying presenter | A presenter with a database handle or an ORM import | Pass an output model that already holds the data |
| Smart mapper | A mapper with conditionals about eligibility or pricing | Move the decision to the domain |
| Status codes inward | A use case that returns `404` or throws an HTTP exception | Return an outcome; map it in the presenter |
| Active-record adapter | A gateway class that also validates and computes | Move the rules out; leave load and save |

## Trade-offs and exceptions

- The source allows adapters to bypass use cases only when the architecture explicitly justifies it. If your project deliberately serves read-only screens from a query gateway, write that decision down (`clean-architecture-boundary-economics`) rather than drifting into it.
- Validation is not all-or-nothing: rejecting a malformed request is the adapter's job; a rule about the business is not.
- A thin framework that forces a controller shape (a base class, an annotation) is a detail at the outermost layer; keep the forced shape there and keep the body thin.
- Do not create presenters and view models for a response that is a single value; a mapper function is enough.

## Verification

- [ ] The controller builds a request model and calls exactly one use case.
- [ ] No business threshold, tier or state comparison remains in an adapter.
- [ ] No presenter or controller holds a gateway or a database handle.
- [ ] Every use-case outcome maps to a delivery result in one place.
- [ ] Gateway methods load and save in domain terms and decide nothing.
- [ ] Adapter tests cover translation with fakes, and the core tests did not change.

## Related

`clean-architecture-boundary-models` for request and response models; `clean-architecture-service-and-device-edges` for listeners and device adapters; `/clean-architecture:extract-use-case` to empty a fat controller; `clean-architecture-adapter-humility-reviewer` to review a diff.

## Source

- `Interface Adapters Layer`
- `Non-Negotiable Rules`: rule 5, treating the web as a detail with controllers and presenters translating.
- `Controller-Centric Logic`
- `Layer Bypass`: only controllers bypassing use cases and presenters reading from databases.
- `Naming Rules`: only the rule naming adapters by the detail or delivery mechanism they adapt.
- `Review Checklist`: only the items on thin controllers and gateways as persistence adapters.
- `Refactoring Rules`: only the rule to separate translation from policy.
