---
name: "ddd-deep-models"
description: "Use when a model feels shallow, table-shaped or contradictory, when requirements keep adding special cases, or when one concept could simplify many rules. Whole-model judgment and breakthrough refactoring; for a single hidden flag or condition use ddd-explicit-concepts."
license: "MIT"
metadata:
  plugin: "ddd"
  book: "Domain-Driven Design"
  invocation: "auto"
---

# Deep models

Owns the stance toward the whole model: it is discovered with domain experts and refined through code, and a shallow model that merely stores data is a defect to work on. It does not name individual hidden concepts (that is `ddd-explicit-concepts`) and it does not test a model with a story (that is `ddd-scenario-walkthrough`).

## When to use

- The "model" is the database schema with classes on top, and every feature is a new column and a new branch.
- Two people describe the same rule differently, or the requirements contradict each other and each fix adds a special case.
- A conditional on `type`, `status` or `metadata` keeps growing, or the same conditional appears in several places.
- Someone proposes a different way to cut the concepts, and the answer so far is "the current one works".
- You are asked to build on a model whose names you cannot explain in business words.

## Rules

1. **Treat the model as discovered, not invented from technical structure.** A model derived from tables or screens encodes storage and UI, not the business. Check: for each central class, you can quote the phrase an expert uses for it.
2. **Before adding an abstraction, identify what domain experts call the concept.** A technical name invites technical growth. Check: the new type's name appears in a conversation, ticket, regulation or policy, or you have a written question to ask.
3. **When requirements are ambiguous, look for the missing domain distinction instead of forcing a generic name.** `Item`, `Entry` and `Data` usually cover two concepts the business keeps apart. Check: write down what differs between two cases that share a generic name.
4. **Let awkward code, contradictory language and repeated conditionals trigger deeper modeling.** They are the cheapest evidence that the model is shallow. Check: list each awkward spot with the sentence the expert would use instead.
5. **Ask which rule, policy, lifecycle or invariant the code is expressing**, and write it as one sentence in domain words before changing it. Check: the sentence exists in the pull request, a test name or a comment next to the type.
6. **Prefer a deeper model that clarifies behavior over a shallow one that stores data.** Behavior is where the business value is. Check: the type answers questions and refuses invalid operations rather than exposing fields.
7. **Capture each newly discovered concept in names, tests, APIs and modules**, not only in a document. Check: grep finds the new term in code and tests.
8. **Update names and boundaries when new insight appears.** Do not keep a vague name after a sharper one is known. Check: no old name survives next to its replacement without a note on why.
9. **Treat refactoring as part of model discovery, and the first model as provisional.** Check: the plan states which assumptions will be tested by the next iteration.
10. **Expect useful models to change after deeper insight, and treat a breakthrough as a candidate for deliberate refactoring, not churn.** Look for a concept that makes many special cases disappear at once. Check: you can name the special cases it removes.
11. **When a better model appears, compare its explanatory power against the migration cost, and move in safe steps that preserve working behavior.** Do not reject it only because the current one works, and do not rewrite in one big bang when incremental migration is possible. Check: each step leaves the tests green and the old and new words never share one meaning.
12. **When a model becomes too elaborate, return to the basics.** Abstractions that add no domain insight are cost. Check: each abstraction explains something an expert said.

## Procedure

1. Collect the evidence of shallowness: awkward signatures, repeated conditionals, contradictory statements, names nobody uses in conversation.
2. Write the rule each awkward spot is trying to express, in a sentence of business words. If you cannot, list the questions for a domain expert and stop guessing.
3. Propose two or three candidate cuts of the concepts. For each, list which special cases disappear and which new ones appear. `ddd-scenario-walkthrough` tests them against real situations.
4. Choose by explanatory power against migration cost. Added judgment: if the best candidate removes fewer than two existing special cases, keep the current model and record the idea.
5. Plan the migration as behavior-preserving steps (`ddd-plan`), rename as you go, and keep tests green after each step.
6. Record the new term and what it replaced where the team keeps its language (`ddd-ubiquitous-language`).

## Example

```python
# Before: one string carries three unrelated facts
class Claim:
    def __init__(self, amount):
        self.amount = amount
        self.status = "OPEN"  # OPEN | DOCS_MISSING | ESCALATED | CLOSED

def may_pay(claim, adjuster):
    if claim.status == "ESCALATED":
        return True
    return claim.status == "OPEN" and claim.amount <= adjuster.limit

# After: lifecycle, outstanding requirements and approval authority are separate concepts
from dataclasses import dataclass
from decimal import Decimal

@dataclass(frozen=True)
class Authority:
    limit: Decimal

    def covers(self, amount: Decimal) -> bool:
        return amount <= self.limit

class Claim:
    def __init__(self, amount: Decimal):
        self.amount = amount
        self._missing_documents: set[str] = set()
        self._closed = False

    def request_document(self, name: str) -> None:
        self._missing_documents.add(name)

    def receive_document(self, name: str) -> None:
        self._missing_documents.discard(name)

    def close(self) -> None:
        self._closed = True

    def payable_under(self, authority: Authority) -> bool:
        return not self._closed and not self._missing_documents and authority.covers(self.amount)
```

"Escalated" stopped being a state: it was an approver with a larger authority. The question for the expert is whether that is what the business means.

## Anti-patterns

- **Tables as the domain.** Classes mirror tables one to one. Detect: every entity has a matching table and the names come from column prefixes.
- **Status soup.** `type`, `status` or `metadata` fields hide separate concepts. Detect: a string or enum whose values mix lifecycle, ownership and permissions.
- **Vague name kept after better language exists.** Detect: tickets or conversations use a word the code does not contain.
- **First model treated as final.** Detect: the same concept has been patched with a special case three or more times (Added judgment: a detection aid, not a rule of the source).
- **Abstraction without insight.** Detect: a generic base type that no expert would recognize and that removes no special case.

## Trade-offs and exceptions

- A better model is not automatically worth its migration cost; the rule set asks for the comparison, not for the move.
- Keep focus on the basics when the model becomes elaborate; a smaller model that experts accept beats a clever one.
- In a supporting or generic area, do not over-model; use the simpler model unless its complexity is real (`ddd-distillation`, `ddd-right-sizing`).

## Verification

- [ ] Each central type has a name an expert recognizes, or an open question is recorded.
- [ ] The rule behind each changed behavior is stated in one sentence of domain words.
- [ ] Any restructuring is a sequence of steps that keep behavior and tests intact.
- [ ] New concepts appear in code and tests, not only in notes.
- [ ] Old and new terms are not both in use for the same thing.

## Related

`ddd-explicit-concepts` for naming one hidden concept; `ddd-scenario-walkthrough` to test candidate models; `ddd-mode-model-explorer` for a discovery conversation; `ddd-concept-reviewer` to review a diff; `ddd-plan` for the migration.

## Source

- `Knowledge Crunching and Deep Models`
- `Breakthrough and Deeper Insight`
- `Strategic Design`: only the rule not to over-model supporting and generic areas.
- `Distillation`: only the rule to keep supporting and generic subdomains simpler unless their complexity is real.
