---
name: "legacy-code-seams"
description: "Use when deciding where a seam goes and what it is for: smallest seam, sensing versus separation, explicit over magical. Where to observe an effect is `legacy-code-test-points`; techniques live in the barrier skills and `legacy-code-substitution-seams`; subclass and build-level kinds are `legacy-code-last-resort-seams`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Seams

A seam is a place where behavior can be changed without editing the surrounding code directly. This skill chooses and classifies seams. The techniques that create them live in the barrier skills: `legacy-code-hidden-inputs`, `legacy-code-hard-outputs`, `legacy-code-construction-barriers`, `legacy-code-static-and-global`, `legacy-code-substitution-seams`, and `legacy-code-last-resort-seams` for the tolerated-only-when-forced kinds.

## When to use

- A test cannot call, instantiate or observe the code you must change, and you have not yet chosen how to fix that.
- Two ways of getting the code under test are on the table (inject a parameter, subclass in the test, patch by name) and you need a tie-breaker.
- You are reviewing a seam someone added and want to know whether it is the right size and the right kind.
- You are writing the seam line of a plan or of a pull request description.

## Rules

1. **Find or create a seam.** [MUST] Without one, the only way to test is through the whole system. Check: you can point to the place in the code where a test chooses a different behavior than production does.
2. **Use seams to inject doubles, isolate dependencies and observe behavior.** [MUST] Check: the seam has a stated job from that list.
3. **Use the smallest seam that unlocks the change.** [MUST] Check: removing any part of the seam (a method, an interface, a layer) would stop the test from working.
4. **Prefer explicit seams over magical test hooks.** [SHOULD] A constructor or method parameter can be read; a global flag, reflection call or patch-by-name has to be discovered. Check: a new reader finds the seam from the signature or the wiring, not from the test.
5. **Prefer seams that remain useful after the current task.** [SHOULD] Check: you can state a production reason for the seam besides "the test needs it".
6. **Create seams near the hard dependency, not randomly in the code.** [MUST] Check: the seam sits at the first call or construction that touches the dependency.
7. **Separate sensing from separation: decide whether the seam observes behavior, substitutes a dependency, or both.** [MUST] Sensing is for seeing what the code computed or did; separation is for getting the code into a test at all. Check: the plan labels each seam sensing, separation or both.
8. **Use link seams and preprocessing seams carefully; they can unlock tests but do not usually improve design by themselves.** [MUST] Check: such a seam carries a cleanup obligation (see `legacy-code-last-resort-seams`).
9. **Judge a candidate by what it allows: substitution, observation or interception.** [Added judgment] The source lists these as useful seams: constructor injection, parameter injection, an extracted method, a wrapper around a static call, an adapter around a framework object, factory indirection, a module boundary, a link, import or preprocessing seam where the language or build supports it, and a subclass seam when forced by language constraints. Check: for the candidate you can say which of the three it allows, and which list entry it is or is equivalent to.
10. **Do not mistake a test-only seam, wrapper, subclass trick or build trick for a design improvement by itself.** [Compact checklist] Check: the report does not claim the design improved because a seam exists.
11. **Name the enabling point.** [Added judgment] The enabling point is the place where the choice between real and substitute behavior is made: a constructor call, an argument at the call site, a wiring module, a build setting. Check: you can point at one line where the test selects its behavior.
12. **Default preference order.** [Added judgment] Parameter or constructor injection first, an extracted method or wrapper next, an adapter around a framework object after that, subclass or build-level seams last. The order follows "smallest", "explicit" and "prefer composition" in the source. Check: if you skipped a higher option, the plan says why.

## Procedure

1. Write the first line of the test you wish you had: the call and the assertion. Run it or reason to the first thing that fails to compile, instantiate or run. That is the barrier.
2. List the seams from rule 9 that sit at that barrier. Cross out any that would force edits far from it.
3. Label each remaining seam sensing, separation or both. If the test needs to see a result the code never returns, you need a sensing seam as well as a separating one.
4. Pick by rules 3, 4, 5 and 12. State the enabling point.
5. Create the seam with the barrier skill that owns the technique. Run the tests before and after.
6. Record the cleanup path for anything that exists only for the test.

## Example

The barrier: `print` creates its renderer inside, so no test can run it without the PDF library.

```java
// Before
public class InvoicePrinter {
    public byte[] print(Invoice invoice) {
        PdfRenderer renderer = new PdfRenderer(Config.fontDir());
        renderer.addTitle("Invoice " + invoice.number());
        for (Line line : invoice.lines()) {
            renderer.addRow(line.description(), line.cents());
        }
        return renderer.toBytes();
    }
}
```

```text
Candidates at the barrier
1. Parameter injection of a Renderer          separation + sensing   enabling point: the argument at the call site
2. Extract and override a createRenderer()     separation + sensing   enabling point: a test subclass; last-resort tier
3. Patch PdfRenderer by name in the test       separation + sensing   enabling point: hidden in the test setup; magical
Choice: 1. Smallest, explicit, and the production wiring can keep passing a PDF renderer.
```

```java
// After
public interface Renderer {
    void addTitle(String text);
    void addRow(String description, long cents);
    byte[] toBytes();
}

public class InvoicePrinter {
    public byte[] print(Invoice invoice, Renderer renderer) {
        renderer.addTitle("Invoice " + invoice.number());
        for (Line line : invoice.lines()) {
            renderer.addRow(line.description(), line.cents());
        }
        return renderer.toBytes();
    }

    // Legacy callers are unchanged.
    public byte[] print(Invoice invoice) {
        return print(invoice, new PdfRenderer(Config.fontDir()));
    }
}
// PdfRenderer gains "implements Renderer"; a RecordingRenderer in the test collects the rows to assert on.
```

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Seam in the wrong place | The seam is far from the dependency it isolates | Move it to the first touch |
| Magical hook | A public flag, reflection call or global setter only tests use | Replace with a parameter |
| Wide seam | An interface that mirrors the whole concrete class | Reduce to what the code uses |
| Unlabeled seam | No statement of sensing or separation | Label it; add a sensing seam if results are invisible |
| Seam as redesign claim | "Now testable, so the design is fixed" | Report only what changed |
| Seam with no exit | A test-only seam with no cleanup note | Add the note or choose a seam that stays useful |

## Trade-offs and exceptions

- Where the language or build leaves no ordinary object seam, subclass, link and preprocessing seams are allowed, as the source says; the cost is a cleanup obligation (`legacy-code-last-resort-seams`).
- The preference for seams that stay useful is a "prefer"; a purely temporary seam is acceptable when nothing better exists and the exit is written down.
- Added judgment: if no seam is small enough to be safe, a broader characterization test through the public entry point is a legitimate first step (`legacy-code-test-points`).

## Verification

- [ ] The seam is near the hard dependency.
- [ ] It is labeled sensing, separation or both.
- [ ] It is explicit: a reader finds it from the signature or the wiring.
- [ ] You can name its enabling point.
- [ ] It has a production reason, or a written cleanup path.
- [ ] Tests ran before and after creating it.

## Related

`/legacy-code:find-seam` to produce a proposal for one target; `legacy-code-substitution-seams`, `legacy-code-construction-barriers`, `legacy-code-static-and-global`, `legacy-code-hidden-inputs`, `legacy-code-hard-outputs` for the techniques; `legacy-code-last-resort-seams` for forced kinds; `legacy-code-seam-reviewer` to review a diff; `/legacy-code:seam-ledger` for existing structure.

## Source

- `Seam Rules`
- `What Counts as a Useful Seam`
- `Required Behavior`
- `Non-Negotiable Rules`: only the rules to find or create a seam and to leave the code more changeable.
