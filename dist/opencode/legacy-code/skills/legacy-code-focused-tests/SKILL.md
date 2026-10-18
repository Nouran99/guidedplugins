---
name: "legacy-code-focused-tests"
description: "Use when choosing test level and speed or writing tests for the requested behavior through a new seam: fast focused tests, old versus new behavior tests, real-boundary integration tests. Pinning unknown behavior is `legacy-code-characterization-tests`; finding where to look is `legacy-code-test-points`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Focused tests for a legacy change

Fast tests around the behavior you are changing, written at the highest level that still isolates the change, separated into "what the code did" and "what the request adds". Pinning behavior nobody has confirmed is `legacy-code-characterization-tests`; finding the place where effects can be seen is `legacy-code-test-points`.

## When to use

- A seam now exists and you are deciding what to test through it.
- You are writing the tests for the new requirement in a module that also has pinned legacy behavior.
- The only available test is slow, broad or needs real infrastructure, and you must decide what to do about it.
- A diff mixes tests for old and new behavior in one block.

## Rules

1. **Prefer fast tests around the behavior you are changing.** [SHOULD] A test you run after every small step is the feedback the loop needs. Check: you can run the tests for the touched slice in a single command and wait only seconds, not minutes.
2. **Prefer tests at the highest level that still isolate the change safely.** [SHOULD] A higher-level test protects more per line; it stops being useful when you cannot tell which change broke it. Check: when the test fails, you can name the change that caused it.
3. **Once a seam exists, test through the seam.** [MUST] Check: the new test substitutes or observes at the seam you built, and does not patch internals around it.
4. **Keep integration tests for real boundaries, but do not depend on them alone.** [MUST] Check: persistence, network and framework behavior each have at least one real-boundary test, and the policy above them also has a test that needs none of them.
5. **Add focused tests for the requested change.** [MUST] Check: the behavior in the delta list has at least one test that fails before the change and passes after.
6. **Keep old behavior tests unless the behavior change is intentional.** [MUST] Check: every deleted or edited expectation is listed in the report as an intended change.
7. **Separate tests that describe legacy behavior from tests that describe the new requirement, when useful.** [MUST] The qualifier narrows when to apply it. Check: a reader can tell from the file or block name which expectations existed before the request.
8. **Prefer improving untestable structure to mocking around it.** [SHOULD] A deep mock of internals tests the mock. Check: every test double replaces a boundary you created or already owned, not a collaborator buried inside the code under change.
9. **Treat a broad test as a first step.** [Added judgment] If the only test point is broad, write it, then name the narrower test that will replace it and the seam that narrower test needs (see `legacy-code-test-points`). Check: the report lists the follow-up.
10. **Run the narrowest relevant slice after each step and the wider suite before handing over.** [Added judgment] The source gives no thresholds; fast is relative to your loop. Check: the report names both commands and results.
11. **Make a red test fail for the right reason.** [Added judgment] Before the change, confirm the new test fails because the behavior is missing, not because of setup. Check: the failure message names the missing behavior.
12. **Do not change a legacy expectation inside a structural step.** [Added judgment] Check: refactoring steps leave every existing assertion untouched.

## Procedure

1. List the delta and preserve lists (`legacy-code-legacy-loop`). Map each preserve item to an existing test or a pin.
2. For each delta item, pick the highest level that isolates it: unit through the seam, then component, then end to end only for real boundaries.
3. Write the new tests first and watch them fail for the right reason.
4. Put them in a block or file named for the new requirement, apart from the legacy pins.
5. Make the change. Run the slice, then the wider suite.
6. Check that real-boundary integration tests still exist for what you touched; add one if the change moved logic away from a boundary.

## Example

```ts
// shipping.test.ts
import { shippingCents } from "./shipping";

// Test double at the seam the change introduced: the rate table is an input, not a lookup inside the function.
const fixedRates = { standardCents: () => 499 };

// Legacy behavior, pinned before the change. Do not edit in this request.
describe("shippingCents: legacy behavior", () => {
  it("charges the flat rate below the threshold", () => {
    expect(shippingCents({ subtotalCents: 4000, member: true }, fixedRates)).toBe(499);
  });
  it("charges non-members the flat rate at any subtotal", () => {
    expect(shippingCents({ subtotalCents: 9000, member: false }, fixedRates)).toBe(499);
  });
});

// New requirement: members at or above 5000 pay nothing for standard shipping.
describe("shippingCents: member free shipping", () => {
  it("is free at the threshold", () => {
    expect(shippingCents({ subtotalCents: 5000, member: true }, fixedRates)).toBe(0);
  });
  it("is not free one cent below", () => {
    expect(shippingCents({ subtotalCents: 4999, member: true }, fixedRates)).toBe(499);
  });
});
```

The two blocks make the request reviewable: nothing in the first block changes, everything in the second is new, and the double sits at the seam instead of patching internals.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Only end-to-end | The one test needs a database and a browser | Add a fast test through a seam; keep the end-to-end |
| Integration-only protection | Policy is untested without real infrastructure | Test policy without it, keep the boundary test |
| Mock of the thing under change | Doubles replace methods of the class being edited | Move the seam to a real boundary |
| Mixed block | Old and new expectations interleaved | Split by origin |
| Edited expectation in a refactor | An assertion changed in a structure-only step | Revert; make the behavior change its own step |
| Green by deletion | A failing legacy test removed | Restore; ask whether the change is intended |

## Trade-offs and exceptions

- "Highest level that still isolates the change safely" is a judgment: if isolation is lost, go lower.
- Where no narrow test point exists yet, a broad harness is acceptable as temporary first coverage; the source calls it a first step toward narrower tests.
- Separation of old and new tests is "when useful"; in a small file a comment may be enough.
- Real boundaries (persistence, network, framework) keep integration tests; do not replace them with doubles.

## Verification

- [ ] The new behavior has a test that failed before and passes after.
- [ ] Legacy expectations are unchanged, or each change is listed as intended.
- [ ] The test goes through the seam, not around it.
- [ ] A real-boundary test exists for each boundary touched.
- [ ] The narrow slice runs fast enough to run after every step.
- [ ] Doubles replace boundaries, not the code under change.

## Related

`legacy-code-characterization-tests` for pinning; `legacy-code-seams` for the seam you test through; `legacy-code-test-points` for choosing where; `legacy-code-test-level-reviewer` to review a diff; `legacy-code-policy-vs-mechanism` when policy cannot be tested without its runtime.

## Source

- `New Behavior Tests`
- `Testing Rules`
- `Testing Strategy Rules`: only the sub-rules on new behavior tests.
- `Code Generation Rules`: only the preferred avoidance of mocking untestable structure instead of improving it.
- `Test Selection and Understanding Rules`: only the rule that a broad test at an interception point is a first step toward narrower tests.
