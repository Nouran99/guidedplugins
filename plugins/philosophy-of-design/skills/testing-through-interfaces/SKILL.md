---
name: testing-through-interfaces
description: "Use when writing or reviewing tests for modules with hidden complexity: test public behavior and contracts, add focused tests for isolated special cases, and avoid tests that need implementation details or force leaky interfaces."
---

# Testing through interfaces

Tests call an interface and protect structural change. This skill keeps them on the contract and keeps test convenience from bending the design. The repository's own conventions decide the framework and layout; only the design pressure on tests is covered here.

## When to use

- You write tests for a module whose implementation is intricate.
- A test reaches into private state, internal collaborators or call order.
- A refactor that preserved behavior broke many tests.
- Someone proposes making a member public, or adding a seam, only so a test can reach it.

## Rules

1. **Test public behavior and interface contracts.** Check: each test name states an outcome a caller can observe.
2. **Test hidden complexity through stable public APIs where possible.** Check: the test exercises the intricate logic by calling the public operation with inputs that reach it.
3. **Add focused tests around isolated special cases.** Check: each case isolated by `/philosophy-of-design:generality-and-special-cases` has its own test.
4. **Avoid tests that force callers to know implementation details if the abstraction promises otherwise.** Check: the test does not assert on private fields, internal call order or collaborator interactions the contract does not mention.
5. **Use tests to preserve behavior while changing structure.** Check: the tests run unchanged before and after a behavior-preserving refactor.
6. **Do not let test convenience force shallow or leaky interfaces.** Check: no member was made public, no getter added and no layer introduced only for a test.
7. **Treat a long, awkward test setup as feedback on the interface.** Added judgment: tests are the first caller; if setup needs many collaborators or ordered calls, the interface requires too much context. Check: the arrange step fits in a few lines.
8. **Test an intricate internal unit directly only when it is an independently understandable unit with its own contract.** Added judgment: extract it because it is a real abstraction, not for test access. Check: the unit passes the two-sided test of `/philosophy-of-design:split-or-merge`.
9. **Added judgment: when a test must break, expect the break to match a contract change.** Check: each failing test after a refactor points at a behavior that really changed.

## Procedure

1. List the contract of the module under test, from its interface comment.
2. For each guarantee, write one test through the public API; name it for the outcome.
3. For each isolated special case, add one focused test with the smallest input that triggers it.
4. Search the tests for private-state access, mocks of collaborators the contract hides, and assertions on call order; rewrite each to assert an observable result.
5. If a test cannot be written without exposing internals, take that to the interface (`/philosophy-of-design:interface-design`) before adding a seam.
6. Run the tests before and after any structural change; they should not need edits.

## Example

```ts
// Before: asserts on internal structure, so any change to storage breaks it
test("evicts", () => {
  const cache = new LruCache<string, number>(2);
  cache.put("a", 1); cache.put("b", 2); cache.put("c", 3);
  expect(cache._map.size).toBe(2);
  expect(cache._map.has("a")).toBe(false);
});

// After: asserts the contract (least recently used entry leaves at capacity)
test("least recently used entry is dropped when capacity is exceeded", () => {
  const cache = new LruCache<string, number>(2);
  cache.put("a", 1);
  cache.put("b", 2);
  cache.get("a");            // "a" is now more recent than "b"
  cache.put("c", 3);         // evicts "b"
  expect(cache.get("b")).toBeUndefined();
  expect(cache.get("a")).toBe(1);
  expect(cache.get("c")).toBe(3);
});
```

The second test survives a switch from a `Map` to a linked list; the first would not.

## Anti-patterns

- **Private-state assertion.** Tests read underscore fields or friend accessors. Detect: names like `_map`, `internal`, `__dict__` in test files.
- **Interaction lock-in.** Mocks verify the exact sequence of collaborator calls. Detect: `toHaveBeenCalledWith` chains describing the implementation.
- **Test-only seam.** A public method or layer that exists only for tests. Detect: a member used only from test directories.
- **Giant setup.** Many lines before the first call. Detect: arrange sections longer than act and assert together.
- **Over-specified output.** Asserting incidental formatting the contract does not promise. Detect: whole-string equality on text the contract describes loosely.

## Trade-offs and exceptions

- Tests for a deliberately exposed internal contract (a plugin hook, a published wire format) belong at that interface, because it is part of the public surface.
- Interaction tests are right when the interaction is the contract (a function whose job is to notify a collaborator); the rule targets interactions the contract hides.
- Characterization tests of legacy code may pin incidental behavior on purpose; use a legacy-code plugin for that discipline and tighten them to contracts as the code improves.
- A seam justified by a real second implementation is a different case from a seam added only for a test (Added judgment).

## Verification

- [ ] Every new test name states an outcome observable by a caller.
- [ ] No test touches private state or depends on collaborator call order that the contract hides.
- [ ] Each isolated special case has a focused test.
- [ ] No member was made public or added only for tests.
- [ ] Tests passed unchanged across the last behavior-preserving refactor.

## Related

`/philosophy-of-design:generality-and-special-cases`; `/philosophy-of-design:interface-design`; `/philosophy-of-design:split-or-merge`; `philosophy-of-design:test-contract-reviewer` to review; `philosophy-of-design:test-writer` to write.

## Source

- `Testing Rules`
- `Performance, Trends, and Tests`: only the rule on using tests to preserve behavior without forcing shallow or leaky interfaces.
