---
name: "clean-code-class-design"
description: "Use when a class or module is growing, changes for several unrelated reasons, has fields used by only some methods, or is named Manager, Helper or Util. Judges one class's responsibilities; exposed surface is clean-code-data-and-objects, change spread across files is clean-code-smells-coupling."
license: "MIT"
metadata:
  plugin: "clean-code"
  book: "Clean Code"
  invocation: "auto"
---

# Class and module design

Judges the size and responsibility of a class or module. What its public surface exposes is `clean-code-data-and-objects`; dependencies that spread change across classes are `clean-code-smells-coupling`.

## When to use

- A class has more than one reason you might open it to edit.
- Some fields are used by one group of methods and other fields by a different group.
- A name needs `And`, `Manager`, `Processor`, `Helper` or `Util` to be accurate.
- A constructor does real work, or setup code outweighs the behavior of the class.
- A change to one feature needs edits in many classes.

## Rules

1. **Keep each class and module small.** Size is measured in responsibilities, not lines alone. Check: you can list what the class is responsible for in one short sentence.
2. **Give each class or module a single main responsibility.** Added judgment: if the description needs "and", "or", "if" or "but", the class probably has several. Check: ask who would request each kind of change; one answer per class.
3. **Favor high cohesion: methods that work on the same data.** Methods should use most of the fields. Check: draw the method-to-field usage; two disjoint clusters mean two classes in one.
4. **Split a class that has gathered unrelated behavior.** Utility dumping grounds grow because they have no owner. Check: the module's functions share only a vague noun (`Utils`, `Helpers`, `Common`).
5. **Arrange code so that the changes you expect stay local.** Think of the two or three changes the product will plausibly ask for next; each should touch one class, or one new class. Check: for each, list the files you would edit; more than a few is a finding.
6. **Make public APIs minimal, self-evident and hard to misuse.** Fewer public methods, names that tell the use, and a required call order enforced by the types (the order clause is compact checklist, `mini.md` only). Check: a caller cannot reach an invalid state through the public methods alone.
7. **Prefer composition to elaborate inheritance, unless inheritance is plainly the simpler and steadier model.** Check: no subclass overrides a method only to disable it; no hierarchy deeper than the domain needs.
8. **Keep constructors and setup code from crowding out domain behavior.** A constructor assigns collaborators and validates; it does not call services, read files or start threads. Check: constructing the object in a test needs no environment.
9. **Keep persistence, framework and vendor concerns from clouding the business logic.** Mixed concerns are the most common reason a class grows. Check: removing the framework annotations and calls leaves a class that still reads as the business rule.
10. **Prefer naming a missing concept to hiding it in a flag or a string.** Added judgment, following from the source's boolean-control-flag and polymorphic-conditional smells: several methods that branch on the same field are a class waiting to be named. Check: grep for repeated `if (this.kind == ...)` in one class.

## Procedure

1. Write the responsibility sentence for the class. If you struggle, write one per cluster of methods.
2. Mark fields by the methods that use them. Group methods that share fields.
3. Pick the cluster with the clearest name and extract it as a class that the original holds or receives. Move fields, then methods, one at a time.
4. After each move, run the tests and keep the original public API working through delegation until callers are migrated.
5. Rename the original so its name matches what it still owns.
6. Stop when each class has one sentence and the next plausible change touches one of them.

## Example

```java
// Before: one class prices, formats and persists
class InvoiceService {
    Money computeTotal(Invoice i) { /* tax, discounts */ }
    String renderPdfText(Invoice i) { /* layout, currency formatting */ }
    void save(Invoice i) { /* SQL */ }
}

// After: each reason to change has a home; the use case coordinates
class InvoicePricing   { Money total(Invoice invoice) { /* tax, discounts */ } }
class InvoiceRenderer  { String render(Invoice invoice, Money total) { /* layout */ } }
class InvoiceRepository { void save(Invoice invoice) { /* SQL */ } }

class IssueInvoice {
    private final InvoicePricing pricing;
    private final InvoiceRepository repository;
    IssueInvoice(InvoicePricing pricing, InvoiceRepository repository) {
        this.pricing = pricing;
        this.repository = repository;
    }
    void issue(Invoice invoice) {
        invoice.stamp(pricing.total(invoice));
        repository.save(invoice);
    }
}
```

A tax rule change now edits `InvoicePricing` only; a layout change edits `InvoiceRenderer` only.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| God class | Many fields, many methods, many imports from unrelated areas | Extract by field cluster |
| Utility dumping ground | `Utils`, `Helpers`, `Common` with unrelated static functions | Move each function to the type it serves, or a named module |
| Split-personality class | Two method groups with disjoint fields | Split into two classes |
| Subclass that disables | Override that throws or does nothing | Prefer composition, or remove the inheritance |
| Heavy constructor | Constructor opens connections, reads config, starts work | Pass collaborators in; move work to an explicit method |
| Shotgun change | One requirement edits many classes | Move the scattered rule into one owner; see `clean-code-smells-coupling` |

## Trade-offs and exceptions

- Do not split a class so far that no single class explains a concept. Small means focused, not fragmentary; extractions that carry no name worth having are indirection (`clean-code-smells-redundancy`).
- Inheritance is acceptable when it is clearly the simpler and more stable model, for example a framework base class you must extend.
- A small facade or coordinator that only sequences collaborators is fine; its one responsibility is the sequence.
- A function-based module is as valid as a class in languages where that is idiomatic; the rules apply to modules too.
- A repository that favors fewer, deeper modules for API simplicity may arbitrate the split; keep the split meaningful.

## Verification

- [ ] Each touched class has a one-sentence responsibility without "and".
- [ ] No cluster of fields is used by only a subset of the methods.
- [ ] The next plausible change touches one class or adds one.
- [ ] Constructors do no real work and the class can be built in a test without the environment.
- [ ] The public API did not grow without a caller needing it.
- [ ] The tests pass after each move.

## Related

`clean-code-data-and-objects` for the surface; `clean-code-smells-coupling` for scattered change; `clean-code-system-construction` for who builds the objects; `clean-code-class-design-reviewer` to review a diff.

## Source

- `Class and module design`
- `Smells to detect and eliminate`: only the oversized class or module, boolean control flag and excessive conditionals smells.
- `Objects, modules, and data structures`: only the rule to keep persistence, framework and third-party details from obscuring business behavior.
