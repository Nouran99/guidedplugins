---
name: "legacy-code-substitution-seams"
description: "Use when a concrete or oversized dependency blocks compiling or substituting it: narrow interfaces, adapters for framework objects, extracted implementers, parameterized methods, primitive parameters. Constructors are `legacy-code-construction-barriers`; choosing any seam is `legacy-code-seams`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Substitution seams

Make a concrete, large or hard-to-create type replaceable at the place a method uses it. The techniques here work on the types and parameters a method receives. Where objects are created and constructed is `legacy-code-construction-barriers`; static and global access is `legacy-code-static-and-global`; subclass-based substitution is `legacy-code-last-resort-seams`.

## When to use

- A method takes a framework object, a driver handle or a god object, and building one in a test needs a running system.
- The code under test uses two methods of a class with forty.
- A concrete dependency makes the module hard to compile in a test harness.
- A method creates a collaborator inside its body, and a parameter would be enough.
- A rich domain type is too expensive to build, while the logic only needs a few plain values.

## Rules

1. **Make dependencies explicit.** [MUST] Check: every collaborator the code under test uses is visible in its signature or in the signature of its constructor.
2. **Use Adapt Parameter when a method needs only a narrow view of a hard-to-create parameter.** [SHOULD] Define a small interface with what the method uses, and give the method that type. Check: the new interface has only the operations the method calls.
3. **Use Extract Implementer or Extract Interface when concrete dependencies make compilation or substitution hard.** [SHOULD] Both leave the code under test depending on an interface that a fake can implement. Check: a test supplies a fake without linking the concrete dependency.
4. **Use Parameterize Method when hidden collaborators should become explicit inputs.** [SHOULD] Add a parameter for the object the method creates, and keep the old signature delegating with the default. Check: tests pass their own collaborator; legacy callers are unchanged.
5. **Use Primitivize Parameter only when the real type is too costly to bring into a harness and primitive data is enough for the new logic.** [MUST NOT] outside that condition. Check: the new logic takes plain values, and the old method converts its rich parameter and calls it.
6. **Use the smallest seam that unlocks the change.** [MUST] Check: a parameter or a narrow interface is not replaced by a hierarchy.
7. **Prefer seams that remain useful after the current task.** [SHOULD] Check: the interface has a production reader, not only a test.
8. **Prefer improving untestable structure to mocking around it.** [SHOULD] Check: the double implements your narrow interface; it does not stub methods of a large concrete class.
9. **Keep the interface in the caller's vocabulary.** [Added judgment] Name operations for what the code under test needs (`line`, `finish`), not for what the vendor class calls them. Check: a change of vendor would not change the interface.
10. **Write the adapter once, in one place.** [Added judgment] The adapter around the framework object is the only code that knows the vendor type, and it stays thin. Check: the adapter has no branching a domain expert would call a rule.
11. **Choose between the techniques by the barrier.** [Added judgment] A parameter that is hard to create and mostly unused: Adapt Parameter. A class that cannot be linked into a harness: Extract Interface or Implementer. A collaborator created inside a method: Parameterize Method. Check: the plan names the barrier before the technique.
12. **Keep the old signature while callers migrate.** [Added judgment] An overload that builds the default and delegates keeps existing callers compiling. Check: no legacy call site changed in the same step.

## Procedure

1. Write down which operations the code under test calls on the dependency, and which it ignores.
2. Pick the technique by barrier (rule 11).
3. Define the interface or parameter in the caller's vocabulary with only those operations.
4. Make the existing type or a small adapter satisfy it. Keep the old entry point delegating.
5. Write the test with a fake that records or returns canned data.
6. Run all tests; list call sites still using the old shape.

## Example

```ts
// Before: the method needs a vendor session that requires a device handle
import { LabelSession } from "labelkit";

export function printShippingLabel(session: LabelSession, order: Order): void {
  session.setFont("mono", 10);
  session.writeLine(order.customerName);
  session.writeLine(`${order.street}, ${order.city}`);
  session.cut();
}
```

```ts
// After: Adapt Parameter. The function sees a two-method view; the adapter knows the vendor.
export interface LabelSink {
  line(text: string): void;
  finish(): void;
}

export function printShippingLabel(sink: LabelSink, order: Order): void {
  sink.line(order.customerName);
  sink.line(`${order.street}, ${order.city}`);
  sink.finish();
}

export function labelkitSink(session: LabelSession): LabelSink {
  session.setFont("mono", 10);
  return { line: (text) => session.writeLine(text), finish: () => session.cut() };
}

// production call site: printShippingLabel(labelkitSink(session), order)
```

```ts
it("prints name, address and finishes", () => {
  const lines: string[] = [];
  let finished = false;
  const sink: LabelSink = { line: (t) => lines.push(t), finish: () => { finished = true; } };
  printShippingLabel(sink, { customerName: "Ana Ruiz", street: "4 Mill Rd", city: "Leeds" } as Order);
  expect(lines).toEqual(["Ana Ruiz", "4 Mill Rd, Leeds"]);
  expect(finished).toBe(true);
});
```

The font is set when the adapter is created, immediately before the call, so the sequence of vendor calls is the same as before.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Mirror interface | Same methods as the concrete class | Reduce to the used operations |
| Stubbed god object | A test stubs ten methods of a large class | Adapt Parameter |
| Primitives everywhere | Rich types replaced without need | Reserve for the stated condition |
| Fat adapter | Rules inside the adapter | Move rules to the caller side |
| Vendor-shaped names | `writeLine`, `cut` in the interface | Rename to the need |
| Mock framework as seam | Reflection used to bypass construction | Parameter or interface |

## Trade-offs and exceptions

- Primitivize Parameter is the exception, not the default: the source allows it only when the real type is too costly to bring into a harness.
- A narrow interface can be a second name for an existing one; do not duplicate a type that already has a small interface.
- Added judgment: in languages with structural typing, the narrow interface may be a local type alias with no adapter.
- Where an interface would have one implementation and no production reader, prefer a function-typed parameter.

## Verification

- [ ] The interface has only the operations the code under test calls.
- [ ] The fake satisfies the interface without the vendor library.
- [ ] The adapter is thin and in one place.
- [ ] Old call shapes still work or are listed for migration.
- [ ] The technique was chosen for a named barrier.
- [ ] Tests ran before and after.

## Related

`legacy-code-seams` for classification; `legacy-code-construction-barriers` for constructors; `legacy-code-collaborator-injector` to make the change; `legacy-code-policy-vs-mechanism` when the framework object is a handler's request or response; `legacy-code-seam-reviewer` to review the seam.

## Source

- `Dependency-Breaking Technique Index`: only Adapt Parameter, Extract Implementer or Extract Interface, Parameterize Method and Primitivize Parameter.
- `Testability Improvements`: only the rules to make dependencies explicit and to remove hard-coded collaborators.
- `Seam Rules`: only the rules on the smallest seam, seams that stay useful, and the adapter around a framework object as a seam kind.
- `Code Generation Rules`: only the preferred avoidance of mocking untestable structure instead of improving it.
