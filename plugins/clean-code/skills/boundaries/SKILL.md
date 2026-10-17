---
name: boundaries
description: "Use when core logic calls a third-party library, SDK or service directly, when upgrading one, or when coding against an API that does not exist yet. Decides which vendor types and exceptions the core may see; wiring is /clean-code:system-construction, failure design /clean-code:error-handling."
---

# Boundaries and external dependencies

Keeps code you do not own from shaping code you do. Who constructs objects and wires them is `/clean-code:system-construction`; the failure model inside your own code is `/clean-code:error-handling`.

## When to use

- Business logic imports types from an SDK, ORM, HTTP client or framework.
- A vendor upgrade would force edits in many files.
- You are about to use a library whose behavior you have not verified.
- Another team's service, or a module not yet written, is a dependency and you are guessing its interface.

## Rules

1. **Isolate third-party libraries behind local adapters or wrappers when practical.** Check: a search for the vendor's package name in the core logic finds nothing; imports sit in the adapter.
2. **Avoid coupling core logic directly to unstable external APIs.** The less stable the dependency, the thicker the boundary should be. Check: a breaking release of the dependency changes one adapter, not the use cases.
3. **Create narrow interfaces around dependencies.** Expose only what the application uses, in the application's vocabulary. Check: the interface has the methods your code calls today and no more.
4. **Add learning tests or focused integration tests for tricky external behavior.** Write small tests that call the real library the way you use it and record what it does. Check: for each surprising behavior you rely on, a test pins it, and it runs on upgrade.
5. **When a dependency does not exist yet, define the interface from local needs, not guesses about future implementations.** Write the interface your code wants, and let the real implementation adapt to it. Check: the interface contains only operations a current caller needs.
6. **Prefer to translate at the edge.** Added judgment, following from rules 2 and 3: convert vendor types, errors, nulls and units into your own at the adapter instead of letting them travel inward. Check: no vendor exception type appears in a `catch` in core code.
7. **Prefer adapters that hold no business rules.** Added judgment, following from keeping third-party details out of business behavior: an adapter translates and forwards, and a rule hidden in integration code is hard to find and to test. Check: the adapter has no branching that a domain expert would recognize as a rule.
8. **Prefer not to wrap what is stable and universal.** Added judgment, following from the source's "when practical" in rule 1: the language's standard types and the repository's own utilities rarely need an adapter, and a wrapper that adds nothing is indirection. Check: you can name the change this wrapper protects against.
9. **Keep vendor configuration and bootstrapping out of business behavior.** Added judgment, extending the construction rule that bootstrapping stays out of ordinary business behavior to credentials and client setup. Check: core code never reads credentials or builds clients; see `/clean-code:system-construction`.

## Procedure

1. Find the vendor imports: grep for the package name outside the intended adapter directory.
2. For each use, write down the operation in your vocabulary (not the vendor's): "send a message to a customer", not "post to the messages endpoint".
3. Define the narrow interface with those operations, in a core-owned location.
4. Write learning tests for any behavior you rely on that the documentation does not make obvious (pagination edge, timezone handling, encoding, nulls).
5. Implement the adapter to satisfy the interface and pass the learning tests.
6. Move callers to the interface one at a time. Run the tests after each.
7. Add or note a test that exercises the adapter against the real dependency, as far as the project's setup allows without network access in unit tests.

## Example

```go
// Shared by both versions: Customer.Phone is a PhoneNumber and reminderText a string constant.
// The twilio.* call shape is schematic; a real vendor client differs in detail.
type PhoneNumber string

// Before: core logic uses the vendor client and its types directly
func (s *Reminder) Send(ctx context.Context, c Customer) error {
	phone := string(c.Phone)
	body := reminderText
	_, err := s.twilio.Messages.Create(ctx, &twilio.CreateMessageParams{
		To:   &phone,
		Body: &body,
	})
	return err
}

// After: the core owns a narrow interface in its own vocabulary
type TextSender interface {
	SendText(ctx context.Context, to PhoneNumber, body string) error
}

func (s *Reminder) Send(ctx context.Context, c Customer) error {
	return s.texts.SendText(ctx, c.Phone, reminderText)
}

// adapter package: the only place that knows the vendor
type twilioTexts struct{ client *twilio.Client }

func (t twilioTexts) SendText(ctx context.Context, to PhoneNumber, body string) error {
	phone := string(to)
	_, err := t.client.Messages.Create(ctx, &twilio.CreateMessageParams{To: &phone, Body: &body})
	if err != nil {
		return fmt.Errorf("send text: %w", err)
	}
	return nil
}
```

A fake `TextSender` makes the reminder logic testable with no network, and a vendor upgrade touches one file.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Vendor type in the core | Imports of the SDK in business packages | Adapter plus core-owned interface |
| Wide interface | Mirror of the vendor API with dozens of methods | Reduce to the operations used |
| Guessed future interface | Methods for hypothetical implementations | Remove; define from current callers |
| Exception leakage | Core catches vendor exception classes | Translate in the adapter |
| Unpinned behavior | Code depends on an undocumented quirk with no test | Learning test |
| Pointless wrapper | Adapter that forwards one call and changes nothing | Remove it |
| Business logic in adapter | Pricing or eligibility rules inside integration code | Move to core |

## Trade-offs and exceptions

- Isolation is "when practical". For a one-file script, a stable standard-library call or a framework the whole project is built on, a thick boundary costs more than it saves.
- Adapters add indirection. Add one when the dependency is unstable, awkward, hard to test, or used from many places; not by reflex.
- Learning tests must not call live services from unit tests. Use a local, in-process or recorded setup the project already has, or ask before adding one.
- Do not install packages to write a learning test; use dependencies the project already declares.

## Verification

- [ ] No vendor import appears in the core logic you touched.
- [ ] The interface exposes only what current callers use.
- [ ] Vendor errors and types are translated inside the adapter.
- [ ] A test pins each tricky behavior the code relies on.
- [ ] The core can be tested with a fake of the interface.
- [ ] The tests pass after each caller migration.

## Related

`/clean-code:learning-tests` for the exploratory test workflow; `/clean-code:system-construction` for wiring the adapter in; `/clean-code:error-handling` for failure design; `clean-code:boundary-reviewer` to review a diff; `clean-code:adapter-builder` to delegate the build.

## Source

- `Boundaries and external dependencies`
- `Objects, modules, and data structures`: only the rule that persistence, framework and third-party details must not obscure business behavior.
- `System construction rules`: only the rule to keep framework bootstrapping out of ordinary business behavior.
