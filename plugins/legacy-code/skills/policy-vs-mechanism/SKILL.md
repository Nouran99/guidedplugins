---
name: policy-vs-mechanism
description: "Use when business decisions are trapped in framework entry points, UI handlers, callbacks or database-heavy code: separate policy from query, mapping and runtime, keep adapters thin. One long body is `large-methods`; effects behind collaborators are `hard-outputs`."
---

# Policy versus mechanism

Decisions are cheap to test when they are plain functions of plain data, and expensive when they live inside a request handler, a UI callback or a query loop. This skill moves the decision out and leaves the entry point thin. Carving apart one long body is `/legacy-code:large-methods`; putting an effect behind a collaborator is `/legacy-code:hard-outputs`; reading values from the environment is `/legacy-code:hidden-inputs`.

## When to use

- A route handler, controller, event callback or UI listener contains the rules that decide what happens.
- A function mixes query building, row mapping and business rules, and can only be tested with a database.
- Testing a rule requires starting a framework, a server or a UI toolkit.
- A class hierarchy puts the testable behavior below, or above, the dependency that prevents testing it.

## Rules

1. **Separate query and mapping concerns from policy.** [MUST] Check: the rule that decides something takes loaded data as input and does not issue queries.
2. **Test policy without a real database where possible.** [MUST] The qualifier is part of the rule. Check: the policy has a test with in-memory data and no connection.
3. **Keep integration tests for actual persistence behavior.** [MUST] Check: each query and mapping you moved or left has a test against the real store somewhere in the suite.
4. **Move decision logic out of handlers and callbacks.** [MUST] Check: the handler contains parsing, one call to the decision, and translation of its result, nothing that branches on business rules.
5. **Test the moved logic independently.** [MUST] Check: the extracted decision has direct tests that do not construct the framework object.
6. **Keep adapters thin.** [MUST] Check: the entry point and the persistence adapter contain no rule a domain expert would recognize as a rule.
7. **If code is impossible to invoke without full runtime setup, isolate the policy from the runtime.** [MUST] Check: the policy can be called from a plain test.
8. **If code depends on many details, separate policy from mechanism.** [MUST] Check: the list of details (framework types, drivers, formats) does not appear in the policy's signature.
9. **Break apart mixed responsibilities that force expensive setup.** [MUST] Check: each piece can be constructed without the setup that its sibling needs.
10. **Use Pull Up Feature or Push Down Dependency to move behavior or dependencies to a more testable level in a hierarchy.** [SHOULD] Check: the behavior you want to test no longer sits below the dependency that blocks it. See the Added judgment on mechanics below.
11. **Treat business logic trapped in a framework entry point as a legacy-change risk when you review.** [MUST] Check: the review lists each entry point that decides something.
12. **Give the policy plain data in and a plain decision out.** [Added judgment] No framework request, response, entity manager or UI widget in its signature; a time value is a parameter. Check: the policy can be called from a script with literals.
13. **Let the entry point do five things in order: parse, call policy, translate the decision, perform effects, respond.** [Added judgment] Check: the handler reads top to bottom as those five steps.
14. **Keep status codes, exit codes and screen states in the adapter.** [Added judgment] The policy returns a reason; the adapter chooses the status. Check: the policy imports no HTTP or UI vocabulary.
15. **Hierarchy mechanics.** [Added judgment] Push Down Dependency leaves the policy in the base class and moves the troublesome dependency into a subclass; Pull Up Feature moves a feature into a new superclass so it can be exercised through a test subclass. Either leaves a subclass that exists for tests: record it as a last-resort seam (`/legacy-code:last-resort-seams`). Check: such a subclass has an exit marker.

## Procedure

1. List what the entry point decides, in plain sentences ("refund only if paid, under the age limit, within the total").
2. Pin the current responses through the entry point if possible (`/legacy-code:characterize`).
3. Extract each decision as a function of plain data; pass time and other ambient values in.
4. Make the entry point call the function and translate its result. Keep response bodies and status codes unchanged.
5. Test the decision directly; keep one test through the entry point.
6. For database-heavy code, split loading and mapping from the rule the same way, and keep a real-store test for the queries.

## Example

```ts
// Before: the refund rules live inside the route handler
app.post("/orders/:id/refund", async (req, res) => {
  const order = await db.orders.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "not found" });
  const ageDays = (Date.now() - order.paidAt.getTime()) / 86_400_000;
  if (order.status !== "paid" || ageDays > 30 || req.body.amountCents > order.totalCents) {
    return res.status(422).json({ error: "not refundable" });
  }
  await payments.refund(order.chargeId, req.body.amountCents);
  await db.orders.update(order.id, { status: "refunded" });
  res.json({ ok: true });
});
```

```ts
// After: policy is a plain function; the handler parses, calls, translates, acts, responds
export type RefundDecision =
  | { ok: true }
  | { ok: false; reason: "not-paid" | "too-old" | "too-much" };

export function decideRefund(
  order: { status: string; paidAt: Date; totalCents: number },
  amountCents: number,
  now: Date,
): RefundDecision {
  if (order.status !== "paid") return { ok: false, reason: "not-paid" };
  const ageDays = (now.getTime() - order.paidAt.getTime()) / 86_400_000;
  if (ageDays > 30) return { ok: false, reason: "too-old" };
  if (amountCents > order.totalCents) return { ok: false, reason: "too-much" };
  return { ok: true };
}

app.post("/orders/:id/refund", async (req, res) => {
  const order = await db.orders.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "not found" });
  const decision = decideRefund(order, req.body.amountCents, new Date());
  if (!decision.ok) return res.status(422).json({ error: "not refundable" });
  await payments.refund(order.chargeId, req.body.amountCents);
  await db.orders.update(order.id, { status: "refunded" });
  res.json({ ok: true });
});
```

```ts
it("refuses a refund older than the limit", () => {
  const order = { status: "paid", paidAt: new Date("2025-01-01"), totalCents: 5000 };
  expect(decideRefund(order, 1000, new Date("2025-03-01"))).toEqual({ ok: false, reason: "too-old" });
});
it("allows a partial refund inside the limit", () => {
  const order = { status: "paid", paidAt: new Date("2025-02-20"), totalCents: 5000 };
  expect(decideRefund(order, 1000, new Date("2025-03-01"))).toEqual({ ok: true });
});
```

The response codes and bodies are unchanged, and the rule is now testable without a server.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Fat handler | Rules and effects in the same function as parsing | Extract the decision |
| Framework type in policy | Request, session or entity-manager parameters in a rule | Plain data in, plain decision out |
| Query-shaped rules | Rules written as conditions inside SQL strings or ORM filters | Load, then decide in code; keep a store test |
| Thick adapter | Mapping code containing pricing or eligibility | Move the rule |
| Mocked framework | A test builds a fake request just to test a rule | Test the decision directly |
| Persistent test subclass | A hierarchy fix left a test-only subclass without an exit | Add the marker |

## Trade-offs and exceptions

- Added judgment: rules that are truly set-based and live best in the database are a different decision; keep them there, but keep a real-store test and name the rule. The source separates query and mapping from policy and keeps integration tests for persistence; it does not say which rules belong in the database.
- Added judgment: for a handler with one trivial condition, extraction is overhead; extract when a change or a test needs the rule.
- The source calls for thin adapters; it does not ask for a new layer. Do not create a service layer to hold one function.
- Real-boundary tests are kept: moving a decision never removes the integration test of the query or the route.

## Verification

- [ ] The decision is a function of plain data and runs in a plain test.
- [ ] The entry point's responses are unchanged, with a test through it.
- [ ] The adapter contains no business rule.
- [ ] A real-store test covers the queries you touched.
- [ ] Time and other ambient values are parameters.
- [ ] Test-only subclasses have exit markers.

## Related

`legacy-code:policy-mechanism-reviewer` to review a diff; `legacy-code:method-extractor` to make the extraction; `/legacy-code:large-methods` for the carving order; `/legacy-code:hard-outputs` for effects; `/legacy-code:focused-tests` for test levels.

## Source

- `Database-Heavy Code`
- `UI or Framework Code`
- `Legacy Refactoring Heuristics`: only the heuristics on code that cannot be invoked without full runtime setup and on separating policy from mechanism.
- `Testability Improvements`: only the rule to break apart mixed responsibilities that force expensive setup.
- `Dependency-Breaking Technique Index`: only Pull Up Feature and Push Down Dependency.
- `Review Rules`: only the item on business logic trapped in framework entry points.
- `Testing Rules`: only the rule to keep integration tests for real boundaries.
- `Code Generation Rules`: only the preferred first move of moving logic out of framework entry points.
- `Handling Risky Areas`: only the subsections on database-heavy code and on UI or framework code.
