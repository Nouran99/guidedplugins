---
name: "ubiquitous-language"
description: "Use when naming or renaming a class, method, event, test or package, when one concept has several names, or when one term carries two meanings inside the same context. Keeps one local term per concept. Which context owns a term is bounded-context."
---

# Ubiquitous language

Owns the words inside one bounded context: the business term for each concept, used identically in classes, methods, events, commands, repositories, services, tests and packages. Where a model is valid at all is `$ddd-implementing:bounded-context`; clean-code style naming of variables and functions is outside this rule set.

## When to use

- You name a new class, event, command, repository method or package.
- Three names (`Booking`, `Reservation`, `Appointment`) are used for what the business calls one thing.
- A single word (`Account`, `Order`, `Status`) is used with two meanings in the same context.
- A name like `OrderManager`, `DataHandler`, `process()` or `updateStatus()` hides a business operation.
- A domain expert reads the code or a test name and does not recognize their own vocabulary.

## Rules

1. **[MUST] Use business terms exactly as they are understood in the current bounded context.** The code is where the language is kept honest. Check: a domain expert shown the class and method names recognizes them as their own words.
2. **[MUST] Give one concept one term inside the context.** Synonyms create two models that drift apart. Check: for each concept in the touched code, one name appears in classes, methods, events and tests.
3. **[MUST NOT] Let one term carry multiple meanings inside the same context.** A word with two meanings makes every sentence ambiguous. Check: each term in the glossary has one definition; if you need two, you have found two concepts (or two contexts).
4. **[MUST] Rename code when understanding improves.** The first name was a guess. Check: a changed understanding produces a rename in the same change or a tracked follow-up, not a comment explaining the old name.
5. **[MUST] Make tests, events, commands, repositories and application services speak the same language as the model.** Check: test names, event names, command names and repository methods use the same terms as the aggregate they serve.
6. **[MUST] Use local domain terms in class, method, event and package names.** Check: `grep` the touched package for the old, technical or foreign word and find nothing outside a deliberate mapping.
7. **[MUST] Remove technical placeholders when a real domain term exists.** `Manager`, `Handler`, `Processor`, `Helper`, `Data`, `Info`, and verbs such as `process`, `handle`, `update` and `execute` stand in for a concept someone has not named yet. Check: each one is replaced by the business verb or noun, or is genuinely technical (an HTTP handler). The word list is Added judgment.
8. **[Compact checklist] When a term is ambiguous, generic or reused across contexts, qualify, split or rename it before coding further.** Check: the decision is written in the glossary entry before the next class uses the term.
9. **[Added judgment] Keep a short glossary per context** in its README: term, one-sentence meaning, words that must not be used for it. Check: a rename pull request edits the glossary in the same change.
10. **[Added judgment] Rename completely.** A rename covers the class and file, the factory and repository methods, event names, test names and fixtures, documentation and comments. Published names (wire fields, table columns, URLs) are contracts: keep them behind a mapping and rename them on their own schedule.

## Procedure

1. List the concepts in the changed code and the words used for each: classes, methods, events, commands, tests, packages.
2. Find the context's existing term for each (glossary, README, nearest model). Prefer the existing term over a new one.
3. Where two words name one concept, pick the one the business uses; where one word names two concepts, split them and name each.
4. Replace technical placeholders with the business verb ("reschedule", "approve", "write off") that the user story or domain expert uses.
5. Rename with the language tooling or an exact whole-word search; check strings, serialized names, SQL, configuration and docs for the old word.
6. Update the glossary and run the tests after each batch.

## Example

```go
// Before: three words for one concept, a placeholder verb, a generic event
type Reservation struct {
	ID       string
	SlotTime time.Time
	Status   int
}

func (m *BookingManager) Process(r *Reservation, newTime time.Time) error {
	r.SlotTime = newTime
	r.Status = 2
	return m.repo.Update(r) // publishes "BookingUpdated"
}

// After: one term, a business verb, an event that states the fact
var ErrNotScheduled = errors.New("appointment is not scheduled")

type Appointment struct {
	id    AppointmentID
	slot  Slot
	state AppointmentState
}

type AppointmentRescheduled struct {
	AppointmentID AppointmentID
	From, To      Slot
}

func (a *Appointment) Reschedule(to Slot) (AppointmentRescheduled, error) {
	if a.state != Scheduled {
		return AppointmentRescheduled{}, ErrNotScheduled
	}
	from := a.slot
	a.slot = to
	return AppointmentRescheduled{AppointmentID: a.id, From: from, To: to}, nil
}
```

The test is named `TestAppointment_Reschedule_rejects_a_cancelled_appointment`, so the same words appear in the model, the event and the test.

## Anti-patterns

- **Synonym drift.** `booking`, `reservation` and `appointment` in one context. Detect: a case-insensitive search for each candidate word returns hits in the same package.
- **Homonym.** `Account` meaning a login in one class and a ledger in another, same context. Detect: two classes or fields with the same name and unrelated fields.
- **Placeholder names.** `*Manager`, `*Service` holding one business operation, `process`, `handle`. Detect: a verb that would not appear in the domain expert's sentence.
- **Foreign vocabulary.** Column names, status codes or partner terms used as local names. Detect: abbreviations such as `cust_stat` in domain code (see `$ddd-implementing:anticorruption-layer`).
- **Translated tests.** Test names that describe mechanics ("sets status to 2"). Detect: a test name without a domain term.

## Trade-offs and exceptions

- A technical class may keep a technical name; the rule is against technical names for domain concepts. An `HttpAppointmentController` is allowed.
- A context may not yet know the right word. Use the best current term, mark it in the glossary as provisional, and rename when understanding improves (rule 4).
- Established abbreviations in the domain (`VAT`, `ISBN`) are domain terms, not placeholders.
- Renaming published contracts has consumers outside the repository; do it as a separate, announced change.

## Verification

- [ ] Each touched concept has exactly one name in classes, methods, events and tests.
- [ ] No term in the touched code means two different things.
- [ ] No technical placeholder stands in for a business verb or noun.
- [ ] Test, event and command names use the model's terms.
- [ ] A search for the old name finds only deliberate mappings.
- [ ] The context's glossary was updated with the change.

## Related

`$ddd-implementing:bounded-context` for where a model is valid; `$ddd-implementing:domain-events` for event naming rules; `$ddd-implementing:domain-tests` for tests in the model's words; `ddd-implementing-language-reviewer` to review a diff.

## Source

- `Ubiquitous Language Rules`
- `Review Rules`: only the item on foreign vocabularies polluting the local context.
