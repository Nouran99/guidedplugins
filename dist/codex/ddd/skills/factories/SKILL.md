---
name: "factories"
description: "Use when creating a domain object takes several collaborating values or business rules, when endpoints or mappers assemble objects field by field, or when invalid or partly built objects can exist. Creation of new objects; for loading stored ones use $ddd:repositories."
---

# Factories

Owns the birth of new domain objects: creation is valid by construction, the rules of creation belong to the model, and reconstitution from storage is a separate path. Retrieval and storage of existing objects is `$ddd:repositories`; a single value that validates itself is `$ddd:value-objects`.

## When to use

- Creating an object needs several inputs and business checks (age, term, eligibility, a derived price).
- A controller or mapper builds an aggregate by calling a default constructor and then setters.
- An object can exist half-built, and later code is expected to finish it.
- Loading a stored object and creating a new one share the same construction path.
- You are unsure whether a plain constructor is enough.

## Rules

1. **Factories must create valid objects.** The object never exists in an invalid state. Check: no code path returns an object that still needs setup.
2. **Factories must encode domain creation rules, not technical object assembly.** Check: the rules named in the factory are business rules an expert would recognize.
3. **Clients and mappers must not contain business construction logic.** Check: controllers and persistence mappers contain no creation conditions.
4. **Choose the factory site where creation ownership fits the model.** A factory method on the root, a separate factory object, or a method on another aggregate can each fit. Check: you can say why the creation belongs there.
5. **Use constructors directly when creation is simple, intention-revealing and does not expose complex invariants.** Check: a factory exists only where a constructor would carry business rules or hide meaning.
6. **Treat reconstitution from storage separately from new-object creation.** Check: loading a stored record does not re-run creation rules, and creating does not use the loading path (`$ddd:repositories`).
7. **Use factories when creation is complex, has business rules, needs multiple collaborating values, or has domain meaning itself.** Check: at least one of those holds for each factory.
8. **Do not build invalid objects first and fix them later, do not let endpoints stitch together aggregates directly, and do not use a factory only to hide a trivial constructor.** Check: no `new X()` followed by a series of setters in controllers.
9. **Do not leave partially initialized aggregates, public state changes that bypass invariants, or impossible states "because later code will fix them" (Invalid Construction).** Check: the type system or constructor makes the impossible state unrepresentable.
10. **Prevent partially formed objects from escaping the creation path (compact checklist).** Check: the first moment a caller can hold the object is after it is valid.

## Procedure

1. Find every place the type is created: controllers, tests, mappers, migrations.
2. Separate new creation from loading. List the rules that apply only to new objects.
3. Decide the site: a static or instance method on the root when the creator is the type itself; a separate factory when creation needs collaborators or knowledge from other objects.
4. Move the creation rules into it, make the constructor private or package-level, and give loading its own entry (`reconstitute`).
5. Replace the creation call sites; delete the setters used only for assembly.
6. Test valid creation, each rejected creation and the reconstitution path (`$ddd:domain-tests`).

## Example

```ts
// Before: the endpoint assembles a policy and forgets a rule
const policy = new Policy();
policy.applicantId = applicant.id;
policy.termMonths = req.termMonths;
policy.premiumCents = req.sumInsuredCents * 0.002;

// After: creation rules in one place; loading is a separate door
interface Applicant { id: string; ageYears: number }
interface CoverageOptions { sumInsuredCents: number; termMonths: number }
interface PolicyRecord {
  id: string;
  applicantId: string;
  sumInsuredCents: number;
  termMonths: number;
  premiumCents: number;
}

class Policy {
  readonly id: string;
  readonly applicantId: string;
  readonly sumInsuredCents: number;
  readonly termMonths: number;
  readonly premiumCents: number;

  private constructor(record: PolicyRecord) {
    this.id = record.id;
    this.applicantId = record.applicantId;
    this.sumInsuredCents = record.sumInsuredCents;
    this.termMonths = record.termMonths;
    this.premiumCents = record.premiumCents;
  }

  // new policy: the creation rules run here and nowhere else
  static issue(id: string, applicant: Applicant, options: CoverageOptions): Policy {
    if (applicant.ageYears < 18) throw new Error("an applicant must be an adult");
    if (options.termMonths < 1 || options.termMonths > 60) throw new Error("term must be 1 to 60 months");
    if (options.sumInsuredCents <= 0) throw new Error("the sum insured must be positive");
    const premiumCents = Math.ceil(options.sumInsuredCents * 0.002 * (options.termMonths / 12));
    return new Policy({
      id,
      applicantId: applicant.id,
      sumInsuredCents: options.sumInsuredCents,
      termMonths: options.termMonths,
      premiumCents,
    });
  }

  // stored policy: used by the repository; the creation rules are not re-run
  static reconstitute(record: PolicyRecord): Policy {
    return new Policy(record);
  }
}
```

The 0.2 percent rate and the 18-to-60 limits are placeholders for the example's rules, not advice.

## Anti-patterns

- **Construct-then-configure.** Detect: a default constructor followed by setters in client code.
- **Endpoint-built aggregate.** Detect: a controller or mapper computing derived fields or checking creation rules.
- **Factory theater.** Detect: a factory class whose method is `return new X(a, b)` with no rule behind it.
- **Shared door.** Detect: one function both builds new objects and loads stored ones.
- **Half-built object.** Detect: nullable required fields that a later step populates.

## Trade-offs and exceptions

- A plain constructor is right when creation is simple and intention-revealing; adding a factory there is ceremony (`$ddd:right-sizing`).
- Reconstitution trusts stored data. Records written under older rules may violate today's creation rules, so decide deliberately whether loading validates, and keep that decision out of the creation path. Added judgment.
- Added judgment: a factory may need collaborators (an id generator, a price list). Pass them in; keep them out of the objects being created.

## Verification

- [ ] No client or mapper contains a creation rule.
- [ ] No code path yields an object that still needs setup.
- [ ] Creation and reconstitution are separate entry points.
- [ ] Each rejected creation has a test.
- [ ] Setters that existed only for assembly are gone.

## Related

`$ddd:repositories` for retrieval; `$ddd:aggregates` for what must be valid together; `$ddd:value-objects` for self-validating values; `ddd-lifecycle-reviewer` to review a diff.

## Source

- `Factories`
- `Forbidden Patterns`: only the Invalid Construction family.
