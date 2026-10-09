---
name: domain-tests
description: "Use when writing or reviewing tests of domain code: value objects, entity and aggregate transitions, application service orchestration, translators. Tests should read in the ubiquitous language. To build a translator itself use /ddd-distilled:context-translation."
---

# Domain tests

Tests are where the ubiquitous language is checked against behavior. This skill says what each kind of domain test contains and how it reads. It does not teach test tooling. Building the translator is `/ddd-distilled:context-translation`; the rules the tests protect are in the pattern skills.

## When to use

- You add or change a value object, an entity transition, an aggregate rule, an application service or a translator, and need to test it.
- A test is named after a method, mocks the object it tests, or asserts on private fields.
- A service test re-checks every business rule.
- An expert-confirmed scenario needs to become an automated check.

## Rules

1. **Make domain tests read in the ubiquitous language.** A test the business cannot recognize does not validate the model. Check: test names are sentences a domain expert would accept, and arrange and assert use domain terms.
2. **Test value objects for validation and behavior.** Check: each invalid-input class and each operation has a test (`/ddd-distilled:value-objects`).
3. **Test entities and aggregates for valid and invalid transitions.** Check: every allowed transition and at least one forbidden one per state has a test; every aggregate invariant has a test that tries to break it through the root.
4. **Test application services for orchestration, not for all domain rules.** The rules have their own tests. Check: a service test asserts load, domain call, save and publish; it does not re-assert pricing or eligibility.
5. **Test context translation wherever an external or foreign model exists.** Check: each mapping rule and the unknown-value case has an example test (`/ddd-distilled:context-translation`).
6. **Use scenarios and acceptance tests to validate that the model expresses real business behavior.** Check: each scenario the expert accepted exists as a test with the same wording.
7. **Assert on outcomes the domain exposes.** (Added judgment) State queries and returned events, not private fields. Check: no reflection or getter added only for the test.
8. **Name the rule in the test name.** (Added judgment) "cannot be confirmed after it was cancelled" beats `testConfirm2`. Check: the failure message alone tells a reader which rule broke.
9. **Build objects through the domain's own constructors and named transitions.** (Added judgment) Check: no setter or reflection is used to reach a state the model cannot reach itself.
10. **If testing a rule needs many infrastructure mocks, the rule is in the wrong place.** (Added judgment) Check: rule tests run without a database, framework or network.

## Procedure

1. List the behaviors changed, by pattern: values, transitions, invariants, orchestration, translation.
2. For each behavior, write the business sentence first; use it as the test name.
3. Write the arrange step with domain constructors and transitions, the act step as one domain call, the assert step on a domain-visible outcome.
4. Add the forbidden case for each rule.
5. For services, assert the sequence at the boundary only.
6. Run the suite; if a rule test needs infrastructure, move the rule to the model.

## Example

```ts
// Before: named after a method, mocks the object under test, goes around the model
it("test confirm 2", () => {
  const r = new Reservation({ id: "1", status: "x", ...mockStuff });
  jest.spyOn(r, "validate").mockReturnValue(true);
  r.setStatus("confirmed");
  expect(r.getStatus()).toBe("confirmed");
});

// After: business sentences, real transitions, domain-visible outcomes
describe("Reservation", () => {
  it("can be confirmed while it is only requested", () => {
    const reservation = aRequestedReservation();
    reservation.confirm();
    expect(reservation.isConfirmed()).toBe(true);
  });

  it("cannot be confirmed after it was cancelled", () => {
    const reservation = aRequestedReservation();
    reservation.cancel(CancellationReason.GuestChangedPlans);
    expect(() => reservation.confirm()).toThrow(InvalidTransition);
  });
});

describe("ReservationService.confirm", () => {
  it("loads the reservation, confirms it, saves it and publishes the fact", async () => {
    const { service, reservations, publisher } = aServiceWith(aRequestedReservation());
    await service.confirm({ reservationId: someReservationId });
    expect(reservations.saved(someReservationId).isConfirmed()).toBe(true);
    expect(publisher.published()).toEqual([expect.objectContaining({ type: "ReservationConfirmed" })]);
  });
});
```

`aRequestedReservation`, `aServiceWith` and `someReservationId` are small test builders using the domain's own constructors. The service test does not repeat the transition rules.

## Anti-patterns

- **Method-named tests.** Detect: `testConfirm`, `test2`, `shouldWork`.
- **Mocking the subject.** Detect: spies on the class under test.
- **Rule re-test in services.** Detect: service tests that cover every branch of a business rule.
- **Back-door setup.** Detect: setters or reflection used to reach a state.
- **Infrastructure-bound rule tests.** Detect: a rule test that needs a database container.

## Trade-offs and exceptions

- Added judgment: simple areas may be covered by a few example-based tests of the plain services; the full set above applies to modeled areas.
- A test builder may use a raw constructor on a value object; the rule is against reaching states the model forbids.
- Translation tests can be table-style; keep each row readable as a mapping rule.
- This rule set gives test content rules, not tooling or coverage targets.

## Verification

- [ ] Test names state a business rule.
- [ ] Value objects, transitions and invariants have valid and invalid cases.
- [ ] Application service tests check orchestration only.
- [ ] Translators have example and unknown-value tests.
- [ ] No test sets state through a back door.

## Related

`/ddd-distilled:value-objects`; `/ddd-distilled:entities`; `/ddd-distilled:context-translation`; `/ddd-distilled:accelerated-modeling`; `ddd-distilled:domain-test-reviewer` to review tests; `ddd-distilled:domain-test-writer` to write them.

## Source

- `Testing Rules`
- `Adoption Fit and Modeling Investment`: only the rule to use scenarios and acceptance tests to validate the model.
