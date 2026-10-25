---
name: "ddd-distilled-ubiquitous-language"
description: "Use when naming or renaming concepts inside one context, when one concept has several names or one name two meanings there, or when names are placeholders such as Data, Info or Manager. Words: hidden decisions ddd-distilled-explicit-concepts; cross-context drift ddd-distilled-bounded-contexts."
license: "MIT"
metadata:
  plugin: "ddd-distilled"
  book: "Domain-Driven Design Distilled"
  invocation: "auto"
---

# Ubiquitous language

The words of one bounded context, used the same way in conversation, code, tests, commands and events. This skill governs vocabulary. When a vague word hides a decision (a flag, a status code, a helper), the structural fix is `ddd-distilled-explicit-concepts`; scanning a whole tree for drift is `/ddd-distilled:glossary`. The same word carrying different rules in different modules is a context question, `ddd-distilled-bounded-contexts`.

## When to use

- You name a type, method, event, command, test or module for a business concept.
- A conversation with the business uses one word and the code uses another, or the code has three words for one thing.
- A name is `Data`, `Info`, `Manager`, `Handler`, `Processor`, `Helper` or `Util` and it stands for a business idea.
- A term from another team's API has appeared in your domain code.

## Rules

1. **Use the domain terms of the current bounded context in code, tests, commands, events and conversations.** The model is only shared if the words are shared. Check: take five nouns and five verbs from a conversation with the business; each appears in code, tests or events under the same name.
2. **Give one concept one term.** Synonyms make readers wonder whether two things differ. Check: grep for the synonym set (`reservation`, `booking`, `order`); each concept resolves to one word.
3. **Do not let one term carry several meanings inside one context.** Check: all uses of the word share one definition; if two definitions exist, split the word.
4. **Rename code when understanding improves.** Stale names preserve the old, wrong model. Check: when a conversation corrects a term, code, tests and event names change in the same piece of work, or a recorded debt item says why not (`/ddd-distilled:modeling-debt`).
5. **Prefer domain names over technical placeholders.** Check: no `Data`, `Info`, `Item`, `Record`, `Manager`, `Processor` or `Handler` stands for a business concept that has its own name.
6. **Avoid technical placeholders that conceal a business concept.** `processData()` hides which business act occurs. Check: each method name reads as a business act or query.
7. **Avoid names imported from another bounded context without translation.** Check: a foreign DTO or schema term appears in domain code only after translation (`ddd-distilled-context-translation`).
8. **Avoid generic helper or utility names that end up carrying domain decisions.** Check: a `Utils`, `Helper` or `Common` class contains no business rule.
9. **Keep names close to real business terms, and make domain assumptions explicit in names, tests and events.** Check: a domain expert reading the test names would recognize their own sentences.
10. **When language is fuzzy, generic, overloaded or imported, pause coding and sharpen the terms first.** (Compact checklist) Check: open questions are listed, and either a person who knows the business has answered or the term is marked provisional.
11. **Keep one glossary per context, next to its code.** (Added judgment) Each entry: term, definition, "not this" (the neighbor's meaning), example. Check: the glossary exists and its terms appear in code.
12. **Do not invent a business term.** (Added judgment) An agent that guesses a name teaches the team a word nobody uses. Check: every new term in the change came from the user, the existing code, or is marked provisional.

## Procedure

1. Collect the terms in the change: types, methods, fields, events, commands, test names.
2. For each, decide the context it lives in and whether it matches the business word.
3. Search the repository for synonyms (same concept, other word) and homonyms (same word, other meaning).
4. Agree the preferred term with someone who knows the business; mark it provisional if nobody is available.
5. Rename in one pass across code, tests, event names and documentation. Treat public API, wire formats and database columns as decisions, not as casual renames.
6. Update the context's glossary.

## Example

```python
# Glossary, Reservations context
#   reservation  a room held for a guest for dates      not "booking" (Sales), not "order" (Finance)
#   confirm      we agree to hold the room               not "approve"
#   stay         the dates and room type requested

# Before: three words for one concept, one placeholder, a foreign word
class BookingManager:
    def process(self, reservation_data: dict) -> None: ...
    def cancel_order(self, order_id: str) -> None: ...

# After: one word per concept, verbs are business acts
class Reservations:
    def request(self, stay: Stay) -> ReservationId: ...
    def confirm(self, reservation_id: ReservationId) -> None: ...
    def cancel(self, reservation_id: ReservationId, reason: CancellationReason) -> None: ...
```

The tests and event names follow: `ReservationConfirmed`, not `BookingApproved`. `Stay`, `ReservationId` and `CancellationReason` are assumed types.

## Anti-patterns

- **Synonym drift.** Detect: two or more words for one concept in the same context.
- **Homonym.** Detect: one word with two rules, such as "active" meaning paid in one method and not archived in another.
- **Placeholder names.** Detect: `Data`, `Info`, `Manager`, `Processor`, `Handler` for business concepts.
- **Imported vocabulary.** Detect: terms that match another team's schema but not your conversations.
- **Frozen names.** Detect: the business renamed a concept a year ago and the code did not.

## Trade-offs and exceptions

- Technical code (adapters, serializers, schedulers) rightly uses technical words, in its own place; the placeholder rule is about domain concepts.
- A word may mean different things in two contexts. That is allowed; what is not allowed is carrying it across without translation.
- Renaming published API, wire names and database columns has consumers you cannot grep. Propose those renames; do not slip them into a feature change.
- Framework-mandated names are not findings.

## Verification

- [ ] Business nouns and verbs from the conversation appear in code, tests or events.
- [ ] No concept has two terms; no term has two meanings within the context.
- [ ] No technical placeholder stands for a business concept.
- [ ] No foreign term appears in domain code untranslated.
- [ ] The context glossary is current, and provisional terms are marked.

## Related

`ddd-distilled-explicit-concepts`; `/ddd-distilled:glossary`; `ddd-distilled-bounded-contexts`; `ddd-distilled-language-reviewer` to review a diff; `ddd-distilled-term-renamer` to apply a decided rename.

## Source

- `Ubiquitous Language Rules`
- `Collaboration Rules`: only the rules to keep names close to business terms and to make domain assumptions explicit in names, tests and events.
- `Testing Rules`: only the rule that domain tests read in the ubiquitous language.
- `Code Generation Rules`: only the step to write names in the local ubiquitous language.
