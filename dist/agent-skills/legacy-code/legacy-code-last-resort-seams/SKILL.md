---
name: "legacy-code-last-resort-seams"
description: "Use only when ordinary object seams are impractical and you consider subclass-and-override, extract-and-override, link, preprocessing, import, template or text redefinition seams. Covers when they are allowed and their cleanup debt; the default choice of seam is `seams`."
license: "MIT"
metadata:
  plugin: "legacy-code"
  book: "Working Effectively with Legacy Code"
  invocation: "auto"
---

# Seams of last resort

Some code cannot be reached through a parameter, a constructor or an interface: the language forbids it, the build will not allow it, or the edit would be far larger than the test is worth. The source tolerates a short list of seams in that situation and asks for care. This skill states when each is allowed and what it costs you afterwards. Choosing among all seams is `legacy-code-seams`; the ordinary object techniques are `legacy-code-substitution-seams`, `legacy-code-construction-barriers` and `legacy-code-static-and-global`.

## When to use

- You are about to subclass a production class in a test, or to add an overridable method just so a test can override it.
- The build offers a link, import or preprocessing substitution and a parameter is not possible.
- A language feature (templates, generics, runtime method redefinition) is the only substitution mechanism available.
- A test-only seam already exists and you must decide whether it may stay.

## Rules

1. **Use Extract and Override Call only when language constraints leave few better options.** [MUST NOT] outside that condition. Check: the plan says which constraint ruled out a parameter, interface or wrapper.
2. **Prefer composition once a cleaner route appears.** [SHOULD] Check: when a parameter or interface becomes possible, the override is replaced by it, not kept.
3. **Use Subclass and Override Method only when safer composition seams are not available.** [MUST NOT] outside that condition. Check: you tried or ruled out injection and wrapping in writing.
4. **Use Template Redefinition, Text Redefinition, link seams or preprocessing seams only when language or build constraints make ordinary object seams impractical.** [MUST NOT] outside that condition. Check: the plan names the constraint.
5. **Use link seams and preprocessing seams carefully; they can unlock tests but do not usually improve design by themselves.** [MUST] Check: the report does not describe such a seam as a design improvement.
6. **Use Definition Completion when missing definitions block tests in languages that allow completion in test code.** [SHOULD] Check: the completed definitions live in test code only.
7. **Use sensing variables or temporary probes only to confirm that a test reaches the intended path, and remove them after use.** [MUST] This rule belongs to `legacy-code-characterization-tests`; it is repeated here because probes are seams with a cleanup date. Check: none remains.
8. **Do not mistake a test-only seam, wrapper, subclass trick or build trick for a design improvement by itself.** [Compact checklist] Check: the summary of the change says what was done, not that the design is better.
9. **Give every magical, temporary, public-for-test, subclass-only, link-based, preprocessor-based or probe-based seam a cleanup obligation, and remove it once safer structure exists.** [Compact checklist] Check: each such seam has a stated exit (see rule 11).
10. **Fold temporary structure into better design when tests support it.** [Compact checklist] Check: once a test protects the behavior, the follow-up step replaces the seam with composition.
11. **Write the exit where the seam is.** [Added judgment] A one-line marker at the override point or build setting names the replacement ("exit: inject a RateSource"). Check: a reader who finds the seam learns how it is meant to go away.
12. **Keep the override point narrow.** [Added judgment] One call per extracted method, the least visibility the language allows, no logic inside. Check: the overridable method is a single call.
13. **Check your language before you override a call made during construction.** [Added judgment] In Java and C# an overridden method called from a superclass constructor does run, but before the subclass is fully initialized, so it must not read subclass fields; in C++ the base version runs and the override is never reached. Extract and Override Factory Method relies on exactly this dispatch: the constructor's `new` becomes a call to an overridable factory method, and the test override returns a fresh object. That use is allowed where the language dispatches to the override and the override reads no subclass state. In C++, or for an override that reads subclass fields, use another seam such as Parameterize Constructor. Check: an override reached from a constructor returns a fresh object, reads no subclass fields, and is not relied on in C++.
14. **Import and module-substitution seams hide the dependency from the signature.** [Added judgment] Where module lookup happens at run time, substituting what a name resolves to is an import seam. It is magical in the sense of rule 9: scope it to one test, restore it automatically, and give it an exit. Check: the substitution cannot leak into other tests.

## Procedure

1. Write down why a parameter, constructor argument, interface or wrapper is not possible here. If you cannot, use one of those instead (`legacy-code-seams`).
2. Choose the least intrusive last-resort kind the language offers; prefer subclass over build-level if both work, since the subclass is visible in code.
3. Create the seam as narrowly as rule 12 says and add the exit marker.
4. Write the test through it and run all tests.
5. Record the seam in the report with its exit; `legacy-code-seam-ledger` will list it later.
6. When a cleaner route appears, retire the seam (`legacy-code-seam-cleaner`).

## Example

```java
// Before: a static call to a remote service blocks every test of convertCents
public class RateSheet {
    public long convertCents(long cents, String from, String to) {
        double rate = RateServiceClient.lookup(from, to);
        return Math.round(cents * rate);
    }
}
```

```java
// After: Extract and Override Call. The constraint here is a static client the team cannot change yet.
public class RateSheet {
    public long convertCents(long cents, String from, String to) {
        double rate = fetchRate(from, to);
        return Math.round(cents * rate);
    }

    // SEAM-DEBT: override point for tests. Exit: inject a RateSource when callers can pass one.
    protected double fetchRate(String from, String to) {
        return RateServiceClient.lookup(from, to);
    }
}
```

```java
@Test
void convertsUsingTheRate() {
    RateSheet sheet = new RateSheet() {
        @Override protected double fetchRate(String from, String to) { return 1.5; }
    };
    assertEquals(1500, sheet.convertCents(1000, "EUR", "USD"));
}
```

The exit, once callers can pass a collaborator: a `RateSource` interface with one method, a `RateSheet(RateSource)` constructor, the override deleted and the test rewritten with a lambda. The marker above is what lets the next person find that step.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Override first | A test subclass where a parameter would have worked | Use the parameter |
| Seam with no exit | An overridable method or build flag with no cleanup note | Add the marker or remove the seam |
| Public for test | Visibility widened only for tests | Narrow; or use a parameter |
| Logic in the override point | The overridable method has branches | Reduce to one call |
| Constructor dispatch | An override reached from a constructor that reads subclass fields, or any such override in C++ | Return a fresh object with no subclass state, or use a different seam |
| Leaky patch | An import patch that stays active across tests | Scope and restore automatically |
| Design claim | "Fixed testability" cited as a design improvement | Report only what changed |

## Trade-offs and exceptions

- The source permits these seams when forced; it does not ask for their immediate removal. Added judgment: in code bases where the language offers nothing else, a long-lived seam is fine if its exit is recorded and re-checked.
- Prefer a subclass seam over a build-level seam when both work: the subclass is visible in the code and in the debugger.
- Added judgment: Definition Completion is grouped in this skill because it is a build-level substitution, not because the source restricts it. The source lists it as a plain "USE ... when" entry with no "only when", which is why rule 6 is a [SHOULD] while the other kinds here are [MUST NOT] outside their condition.
- A last-resort seam does not excuse a missing characterization test; pin behavior first (`legacy-code-characterization-tests`).
- Pull Up Feature and Push Down Dependency, which also produce a test subclass, are covered by `legacy-code-policy-vs-mechanism`; the cleanup obligation here applies to the subclass they leave.

## Verification

- [ ] The constraint that ruled out ordinary seams is written down.
- [ ] The seam is as narrow as the language allows.
- [ ] It carries an exit marker.
- [ ] Any override point reached from a constructor returns a fresh object, reads no subclass state and is not relied on in C++.
- [ ] Probes and sensing variables are removed.
- [ ] The report does not call the seam a design improvement.

## Related

`legacy-code-seams` for the default order; `legacy-code-construction-barriers` for the factory-method technique; `legacy-code-seam-reviewer` to review a diff; `legacy-code-seam-ledger` and `legacy-code-seam-cleaner` for existing seams; `legacy-code-characterization-tests` for probes.

## Source

- `Extract and Override Call`
- `Seam Rules`: only the rule on link and preprocessing seams, and the list entries for link, import, preprocessing and subclass seams.
- `Dependency-Breaking Technique Index`: only Definition Completion, Subclass and Override Method, Template Redefinition, Text Redefinition, link seams and preprocessing seams, and the entry on Extract and Override Factory Method (the exemption in rule 13).
- `Preferred Legacy Techniques`: only the preference for composition.
- `Characterization Tests`: only the rule that sensing variables and probes are removed after use.
