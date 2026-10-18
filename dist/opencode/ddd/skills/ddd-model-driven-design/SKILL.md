---
name: "ddd-model-driven-design"
description: "Use when design documents, diagrams, tickets and code describe different models, when a model exists only on a whiteboard, or when tests and docs should explain the domain. Alignment of model, code and artifacts; for word choice use ddd-ubiquitous-language."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Model-driven design

Owns the link between the model people discuss and the code that runs: the implementation must reflect the discussed model, and every written artifact must stay short and tied to code. Word-level naming is `ddd-ubiquitous-language`; hunting for hidden concepts is `ddd-explicit-concepts`.

## When to use

- A wiki page, ADR or diagram uses nouns that do not exist in the code.
- An analyst's model cannot be implemented as drawn, or a developer's implementation ignores it.
- Code follows framework conventions while the domain concepts are invisible in classes and packages.
- You are asked to document a domain rule, or to decide whether a rule deserves a test, a comment or a diagram.
- A diagram is described as authoritative although the code changed after it was drawn.

## Rules

1. **The implemented design must reflect the model used in discussion.** If the two diverge, the discussion is about something that does not exist. Check: pick three nouns from the latest design discussion and find each in the code.
2. **If the model cannot guide code, refine the model or the code until they align.** Check: a developer can say which class or function carries each rule of the model.
3. **Domain objects must represent behavior and meaning, not just persistence state.** Check: the central types have operations named for business actions.
4. **Keep modelers close to implementation.** Analysis separated from coding turns the model theoretical. Check: whoever proposes a model change can point to the code it affects, and the person changing the code takes part in the modeling.
5. **Make important model concepts visible in classes, functions, modules, tests and interfaces.** Check: a newcomer can find the concept by name from the directory listing or a test name.
6. **Prefer executable examples and tests over disconnected documentation.** A scenario test cannot drift silently. Check: each important rule has a test whose name is a sentence in domain words.
7. **Keep diagrams and documents lightweight, current and tied to code.** Written design material must be short enough to stay maintained. Check: each document names the bounded context it describes and has changed in the same period as the code it describes.
8. **Use explanatory models only to teach or reason.** Do not confuse them with the implementation model unless they are meant to drive code. Check: each diagram says whether it is explanatory or implemented.
9. **Documents and diagrams must support the ubiquitous language.** Diagrams should emphasize boundaries, relationships, invariants and lifecycle over a class inventory. Check: no diagram introduces a term that code and tests do not use.
10. **Keep glossary-like explanations close to the bounded context they describe, and update documents when terminology or context boundaries change.** Check: the glossary sits in or beside the context's package, not in a company-wide page.

## Procedure

1. List the nouns and verbs in the design material (ticket, ADR, diagram, wiki) for the area you touch.
2. Find each in the code. Mark those missing, those present under another name, and those present with a different meaning.
3. Decide per mismatch whether the model or the code is wrong; ask the person who owns the model when you cannot tell. Do not decide by which artifact is newer.
4. Change the code toward the model, or update the document toward the code, in the same change.
5. Convert any rule that exists only in prose into a scenario test; delete prose the test now says better.
6. Mark remaining diagrams explanatory or implemented, and trim to boundaries, relationships, invariants and lifecycle.

## Example

```ts
// Before: the wiki says "a policyholder renews a coverage"; the code says otherwise
function updateRecord(id: string, data: Record<string, unknown>): void { /* ... */ }

// After: the wiki sentence is the operation and the test name
class Coverage {
  readonly policyholderId: string;
  readonly endsOn: Date;

  constructor(policyholderId: string, endsOn: Date) {
    this.policyholderId = policyholderId;
    this.endsOn = endsOn;
  }

  renewFor(months: number): Coverage {
    const target = this.endsOn.getUTCMonth() + months;
    const year = this.endsOn.getUTCFullYear();
    const lastDay = new Date(Date.UTC(year, target + 1, 0)).getUTCDate();
    const day = Math.min(this.endsOn.getUTCDate(), lastDay);
    return new Coverage(this.policyholderId, new Date(Date.UTC(year, target, day)));
  }
}

const utc = (y: number, m: number, d: number) => new Date(Date.UTC(y, m - 1, d));

test("a policyholder renews a coverage for twelve months", () => {
  const renewed = new Coverage("ph-17", utc(2026, 3, 31)).renewFor(12);
  expect(renewed.endsOn).toEqual(utc(2027, 3, 31));
});

test("a coverage ending on the 31st renews to the last day of a shorter month", () => {
  const renewed = new Coverage("ph-17", utc(2026, 1, 31)).renewFor(1);
  expect(renewed.endsOn).toEqual(utc(2026, 2, 28));
});
```

Plain `setUTCMonth` would roll 31 January into March, so the method clamps to the last day of the target month. Clamping is itself an assumption about the policy; the second test records it as a question to confirm with the policy expert.

## Anti-patterns

- **Document with different names than the code.** Detect: nouns in the design page that grep cannot find.
- **Analyst model nobody implements.** Detect: boxes in a diagram with no counterpart type and no ticket.
- **Framework-shaped code.** Detect: packages named after framework roles (`controllers`, `repositories`, `dto`) with no domain concept visible at the top level.
- **Authoritative stale diagram.** Detect: the diagram's last change predates the last several changes to the code it shows.
- **Class-inventory diagram.** Detect: every class is drawn and no boundary or invariant is stated.

## Trade-offs and exceptions

- An explanatory model that is deliberately different from the implementation is allowed when it teaches or reasons; label it so.
- Added judgment: short-lived sketches for a single discussion do not need maintenance; do not file them as documentation.
- Added judgment: where a rule cannot be verified by a test (a policy decision, an external agreement), a short written statement next to the code is the fallback.

## Verification

- [ ] Every noun used in the design discussion appears in the code or is recorded as a gap.
- [ ] Each important rule has an executable example with a domain-language name.
- [ ] Each document or diagram names its bounded context and is marked explanatory or implemented.
- [ ] No diagram or document introduces vocabulary absent from code and tests.
- [ ] Documents touched by renamed terms were updated in the same change.

## Related

`ddd-ubiquitous-language` for the vocabulary itself; `ddd-domain-tests` for rule-level tests; `ddd-language-audit` for a tree-wide term table; `ddd-language-reviewer` to review a diff.

## Source

- `Model-Driven Design`
- `Communication Artifacts`
